//+------------------------------------------------------------------+
//|                                                        agent.mqh |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property strict

#include "tools/mt5.mqh"
#include "tools/dispatch.mqh"
#include "tools/requests.mqh"

#ifndef OPENAI_API_KEY
#include "secrets.mqh"
#endif

#define MODEL "gpt-5-nano"
#define URL   "https://api.openai.com/v1/chat/completions"
#define ROOT_URL "https://api.openai.com/"

const string CONTEXT_FILES[] =
{
   "context\\mql.md",
   "context\\trade.md",
   "workflows\\response.md",
};

#import "shell32.dll"
int ShellExecuteW(int hWnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import

#define FILE_COPY(src, dest) (ShellExecuteW(0, "open", "cmd.exe", ("/C copy /Y \"" + src + "\" \"" + dest + "\""), NULL, 0))
#define COMMON_FOLDER TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\" + "Files" + "\\"

//+------------------------------------------------------------------+
//| Agent — wraps multi-turn conversation state and OpenAI API calls |
//+------------------------------------------------------------------+
class Agent
{
private:
   CJAVal    m_messages;    // persistent conversation history (jtARRAY)
   Dispatch *m_dispatch;    // tool dispatcher
   CRequests m_requests;    // HTTP client
   string    m_headers;     // Content-Type + Authorization headers
   bool      m_initialized;

   //--- Read a text file
   string readFile(string path)
   {
      const string ogPath = ::TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Include\\metatrader-ai\\" + path;
      const string commonPath = COMMON_FOLDER + "metatrader-ai\\" + path;
      FILE_COPY(ogPath, commonPath);
      int handle = ::FileOpen("metatrader-ai\\" + path, FILE_READ | FILE_COMMON | FILE_TXT | FILE_ANSI);
      if (handle == INVALID_HANDLE)
      {
         ::Print("[Agent] Error '" + (string)GetLastError() + "', could not open file: " + commonPath);
         return "";
      }
      string content = "";
      while (!::FileIsEnding(handle))
         content += ::FileReadString(handle) + "\n";
      ::FileClose(handle);
      return content;
   }

   //--- Read and concatenate all CONTEXT_FILES
   string loadContextFiles()
   {
      string combined = "";
      int n = ArraySize(CONTEXT_FILES);
      for (int i = 0; i < n; i++)
         combined += "\n\n--- " + CONTEXT_FILES[i] + " ---\n" + readFile(CONTEXT_FILES[i]);
      return combined;
   }

   //--- Append a standard role/content message
   void pushMessage(string role, string content)
   {
      CJAVal msg;
      msg["role"]    = role;
      msg["content"] = content;
      m_messages.Add(msg);
   }

   //--- Append a pre-serialized JSON object (used for assistant messages with tool_calls)
   void pushRaw(string serialized)
   {
      CJAVal msg;
      msg.Deserialize(serialized);
      m_messages.Add(msg);
   }

   //--- Append a tool result message
   void pushToolResult(string toolCallId, string content)
   {
      CJAVal msg;
      msg["role"]         = "tool";
      msg["tool_call_id"] = toolCallId;
      msg["content"]      = content;
      m_messages.Add(msg);
   }

public:
   Agent()
   {
      m_messages.m_type = jtARRAY;
      m_dispatch        = new Dispatch();
      m_requests.url    = URL;
      m_headers         = "Content-Type: application/json\r\nAuthorization: Bearer " + OPENAI_API_KEY;
      m_initialized     = false;

      if(!FolderCreate("metatrader-ai", FILE_COMMON)) Print("Failed to create metatrader-ai folder");
      if(!FolderCreate("metatrader-ai\\context", FILE_COMMON)) Print("Failed to create metatrader-ai\\context folder");
      if(!FolderCreate("metatrader-ai\\workflows", FILE_COMMON)) Print("Failed to create metatrader-ai\\workflows folder");
   }

   ~Agent()
   {
      if (CheckPointer(m_dispatch) == POINTER_DYNAMIC)
      {
         delete m_dispatch;
         m_dispatch = NULL;
      }
   }

   //--- Load system prompt + context files into history
   bool initialize()
   {
      string systemContent = readFile("context\\prompt.md") + loadContextFiles();
      pushMessage("system", systemContent);
      m_initialized = true;
      return true;
   }

   //--- Process one user turn and return the assistant's final text response
   string run(string prompt)
   {
      if (!m_initialized)
         initialize();

      pushMessage("user", prompt);

      string toolsJson = m_dispatch.toolList(false); // false = OpenAI format

      while (true)
      {
         // Build payload as raw JSON string to safely embed the messages array
         string payloadStr = "{\"model\":\"" + MODEL + "\","
                             + "\"tool_choice\":\"auto\","
                             + "\"messages\":" + m_messages.Serialize() + ","
                             + "\"tools\":" + toolsJson + "}";

         CJAVal payload;
         payload.Deserialize(payloadStr);

         bool ok = m_requests.POST(payload, 60000, m_headers, ROOT_URL);
         if (!ok)
            return "HTTP request failed.";

         // After POST, payload is replaced with the parsed response
         if (payload["error"]["message"].ToStr() != "")
            return "API error: " + payload["error"]["message"].ToStr();

         if (payload["choices"].m_type != jtARRAY || ArraySize(payload["choices"].m_e) == 0)
            return "Unexpected API response: " + m_requests.result;

         string msgSerialized = payload["choices"][0]["message"].Serialize();

         CJAVal message;
         message.Deserialize(msgSerialized);

         bool hasToolCalls = (message["tool_calls"].m_type == jtARRAY)
                             && (ArraySize(message["tool_calls"].m_e) > 0);

         if (!hasToolCalls)
         {
            string content = message["content"].ToStr();
            pushMessage("assistant", content);
            return content;
         }

         // Persist the full assistant message (including tool_calls) into history
         pushRaw(msgSerialized);

         // Execute each tool call and append its result
         int n = ArraySize(message["tool_calls"].m_e);
         for (int i = 0; i < n; i++)
         {
            CJAVal toolCall;
            toolCall.Deserialize(message["tool_calls"][i].Serialize());

            string callId  = toolCall["id"].ToStr();
            string name    = toolCall["function"]["name"].ToStr();
            string rawArgs = toolCall["function"]["arguments"].ToStr();

            CJAVal args;
            if (StringLen(rawArgs) > 0)
               args.Deserialize(rawArgs);

            Print("[Agent] Executing tool: ", name, " args: ", rawArgs);
            string result = m_dispatch.execute(name, args);
            Print("[Agent] Tool ", name, " returned: ", result);

            pushToolResult(callId, result);
         }
      }

      return ""; // unreachable
   }

   //--- Clear conversation history while preserving the system message
   void reset()
   {
      string systemMsgStr = "";
      if (ArraySize(m_messages.m_e) > 0)
         systemMsgStr = m_messages[0].Serialize();

      m_messages.Clear();
      m_messages.m_type = jtARRAY;

      if (systemMsgStr != "")
      {
         CJAVal systemMsg;
         systemMsg.Deserialize(systemMsgStr);
         m_messages.Add(systemMsg);
      }
   }
};

//--- Global agent instance
Agent *g_agent = NULL;

//+------------------------------------------------------------------+
//| Run a prompt through the agent; returns the assistant's response |
//| Call this from OnTick, OnTimer, or any Expert Advisor handler    |
//+------------------------------------------------------------------+
string agentRun(string prompt)
{
   if (g_agent == NULL)
   {
      g_agent = new Agent();
      g_agent.initialize();
   }
   return g_agent.run(prompt);
}

//+------------------------------------------------------------------+
//| Initialize the global agent — call from OnInit                   |
//+------------------------------------------------------------------+
void agentInit()
{
   if (g_agent != NULL)
      delete g_agent;

   g_agent = new Agent();
   g_agent.initialize();
}

//+------------------------------------------------------------------+
//| De-initialize the global agent — call from OnDeinit/when done    |
//+------------------------------------------------------------------+
void agentDeinit()
{
   if (g_agent != NULL)
   {
      delete g_agent;
      g_agent = NULL;
   }
}
//+------------------------------------------------------------------+
