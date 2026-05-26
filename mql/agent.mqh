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

#resource "\\Include\\metatrader-ai\\context\\mql.md" as string FileMQL
#resource "\\Include\\metatrader-ai\\context\\trade.md" as string FileTrade
#resource "\\Include\\metatrader-ai\\context\\prompt.md" as string FilePrompt
#resource "\\Include\\metatrader-ai\\workflows\\response.md" as string FileResponse

//+------------------------------------------------------------------+
//| Agent — wraps multi-turn conversation state and OpenAI API calls |
//+------------------------------------------------------------------+
class Agent
{
public:
   Agent();                   // Constructor
   ~Agent();                  // Deconstructor
   void reset();              // Clear conversation history while preserving the system message
   string run(string prompt); // Process one user turn and return the assistant's final text response

private:
   CJAVal    m_messages;    // persistent conversation history (jtARRAY)
   Dispatch *m_dispatch;    // tool dispatcher
   CRequests m_requests;    // HTTP client
   string    m_headers;     // Content-Type + Authorization headers

   string loadContextFiles();                              // Read and concatenate all CONTEXT_FILES
   string readFile(string path);                           // Read a text file
   void pushMessage(string role, string content);          // Append a standard role/content message
   void pushRaw(string serialized);                        // Append a pre-serialized JSON object (used for assistant messages with tool_calls)
   void pushToolResult(string toolCallId, string content); // Append a tool result message
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
Agent::Agent()
{
   m_messages.m_type = jtARRAY;
   m_dispatch        = new Dispatch();
   m_requests.url    = URL;
   m_headers         = "Content-Type: application/json\r\nAuthorization: Bearer " + OPENAI_API_KEY;

#ifdef __MQL5__
   string systemContent = readFile("context\\prompt.md") + "\nYou are in a MQL5/MetaTrader 5 environment." + loadContextFiles();
#else
   string systemContent = readFile("context\\prompt.md") + "\nYou are in a MQL4/MetaTrader 4 environment." + loadContextFiles();
#endif
   pushMessage("system", systemContent);
}

//+------------------------------------------------------------------+
//| Deconstructor                                                    |
//+------------------------------------------------------------------+
Agent::~Agent()
{
   if (CheckPointer(m_dispatch) == POINTER_DYNAMIC)
   {
      delete m_dispatch;
      m_dispatch = NULL;
   }
}

//+------------------------------------------------------------------+
//| Read a text file                                                 |
//+------------------------------------------------------------------+
string Agent::readFile(string path)
{
   if(CONTAINS(path, "mql"))      return FileMQL;
   if(CONTAINS(path, "trade"))    return FileTrade;
   if(CONTAINS(path, "prompt"))   return FilePrompt;
   if(CONTAINS(path, "response")) return FileResponse;
   return "";
}

//+------------------------------------------------------------------+
//| Read and concatenate all CONTEXT_FILES                           |
//+------------------------------------------------------------------+
string Agent::loadContextFiles()
{
   string combined = "";
   int n = ArraySize(CONTEXT_FILES);
   for (int i = 0; i < n; i++)
      combined += "\n\n--- " + CONTEXT_FILES[i] + " ---\n" + readFile(CONTEXT_FILES[i]);
   return combined;
}

//+------------------------------------------------------------------+
//| Append a standard role/content message                           |
//+------------------------------------------------------------------+
void Agent::pushMessage(string role, string content)
{
   CJAVal msg;
   msg["role"]    = role;
   msg["content"] = content;
   m_messages.Add(msg);
}

//+------------------------------------------------------------------+
//| Append a pre-serialized JSON object                              |
//+------------------------------------------------------------------+
void Agent::pushRaw(string serialized)
{
   CJAVal msg;
   msg.Deserialize(serialized);
   m_messages.Add(msg);
}

//+------------------------------------------------------------------+
//| Append a tool result message                                     |
//+------------------------------------------------------------------+
void Agent::pushToolResult(string toolCallId, string content)
{
   CJAVal msg;
   msg["role"]         = "tool";
   msg["tool_call_id"] = toolCallId;
   msg["content"]      = content;
   m_messages.Add(msg);
}

//+------------------------------------------------------------------+
//| Process one user turn, return the assistant's final text response|
//+------------------------------------------------------------------+
string Agent::run(string prompt)
{
   pushMessage("user", prompt);

   CJAVal toolList;
   m_dispatch.toolList(toolList, false);

   while (true)
   {
      CJAVal payload;
      payload["model"] = MODEL;
      payload["tool_choice"] = "auto";
      payload["messages"].Set(m_messages);
      payload["tools"].Set(toolList);

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

//+------------------------------------------------------------------+
//| Clear conversation history while preserving the system message   |
//+------------------------------------------------------------------+
void Agent::reset()
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
