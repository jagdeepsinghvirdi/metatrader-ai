//+------------------------------------------------------------------+
//|                                                          app.mq5 |
//|                                      Copyright 2026,JBlanked LLC |
//|                                         https://www.jblanked.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked LLC"
#property link      "https://www.jblanked.com"
#property version   "1.02"
#property strict

#include "agent.mqh"
#include "tools/Panel-Draw.mqh"

input string inpApiKey                     = "sk--";                                 // Your API Key
input ENUM_LLM_PROVIDER inpProvider        = LLM_PROVIDER_DEEPSEEK;                  // LLM Provider
input ENUM_DEEPSEEK_MODEL inpDeepSeekModel = DEEPSEEK_MODEL_V4_FLASH;                // DeepSeek Model
input ENUM_OPENAI_MODEL inpOpenAIModel     = OPENAI_MODEL_GPT_5_4_NANO;              // OpenAI Model
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   bool timerSet = EventSetTimer(1);
   while(!timerSet)
   {
      timerSet = EventSetTimer(1);
      Sleep(1);
   }

   agent = new Agent(inpApiKey, inpProvider, inpProvider == LLM_PROVIDER_OPENAI ? (int)inpOpenAIModel : (int)inpDeepSeekModel);

   int panelW = (int)(ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) / 2.5);
   int panelH = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS) - 40;
   panel = new AIPanel("MetaTrader-AI", 0, 0, panelW, panelH, 0);
   if(CheckPointer(panel) != POINTER_DYNAMIC)
   {
      delete agent;
      return INIT_FAILED;
   }
   panel.SetAgent(agent);

   if(!panel.CreatePanel())
   {
      delete agent;
      return INIT_FAILED;
   }

   panel.AddMessage("assistant", "Hello! I'm your AI trading assistant. Ask me anything about your positions, market analysis, or trading strategies.");

   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   if(CheckPointer(panel) == POINTER_DYNAMIC)
   {
      panel.Destroy(reason);
      delete panel;
   }

   if(CheckPointer(agent) == POINTER_DYNAMIC)
      delete agent;
}
//+------------------------------------------------------------------+
//| Expert on-event function                                         |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   panel.PanelChartEvent(id, lparam, dparam, sparam);
}
//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
{
   panel.OnTickUpdate();

   if(panel.IsRequestPending())
   {
      string userMsg = panel.GetPendingMessage();
      string response = agent.run(userMsg);
      panel.CompletePending(response);
   }
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Chat message structure                                           |
//+------------------------------------------------------------------+
struct ChatMessage
{
   string role;    // "user" or "assistant"
   string content; // message text
   string time;    // timestamp string
};

//+------------------------------------------------------------------+
//| AIPanel — A beautiful two-tab AI chat + info panel               |
//+------------------------------------------------------------------+
class AIPanel : public CPanelDraw
{
private:
   //--- Tab state
   bool            m_isChatTab;
   bool            m_initialized;

   //--- Tab buttons
   CButton         m_btnChat;
   CButton         m_btnInfo;

   //--- Chat components
   CLabel          *m_msgLabels[];     // array of message label pointers
   int             m_msgLabelCount;    // number of allocated message labels
   ChatMessage     m_messages[];       // message storage
   int             m_messageCount;     // number of stored messages
   int             m_scrollOffset;     // pixel scroll offset for chat area

   //--- Info tab labels
   CLabel          *m_infoLabels[];    // info display labels
   int             m_infoLabelCount;   // number of info labels

   //--- Input components
   CEdit           m_txtInput;
   CButton         m_btnSend;
   CButton         m_btnScrollUp;
   CButton         m_btnScrollDown;

   //--- Agent
   Agent           *m_agent;

   //--- Layout constants (relative to panel size)
   int             m_tabHeight;
   int             m_inputAreaHeight;
   int             m_margin;
   int             m_msgSpacing;
   int             m_chatTop;
   int             m_chatBottom;
   int             m_chatHeight;

   //--- Colors
   color           m_clrBg;
   color           m_clrUserBubble;
   color           m_clrAiBubble;
   color           m_clrUserText;
   color           m_clrAiText;
   color           m_clrTabActive;
   color           m_clrTabInactive;
   color           m_clrTabText;
   color           m_clrInputBg;
   color           m_clrSendBtn;
   color           m_clrSendText;
   color           m_clrAccent;
   color           m_clrBorder;

   //--- DPI
   int             m_dpi;
   double          m_dpiScale;

   //--- Internal
   string          m_panelName;
   int             m_tickCounter;      // tick counter for info refresh
   bool            m_requestPending;   // waiting for AI response
   string          m_pendingMsg;       // last sent message (for display)
   int             m_chatTotalHeight;  // total rendered height of chat messages
   int             m_infoScrollOffset; // scroll offset for info tab
   int             m_infoTotalHeight;  // total content height of info tab

   //--- Private helpers
   void            DestroyMessageLabels();
   void            UpdateChatVisibility(bool show);
   void            UpdateInfoVisibility(bool show);
   void            SwitchToChat();
   void            SwitchToInfo();
   void            RenderMessages();
   void            ClearInfoLabels();
   void            PopulateInfoTab();
   void            SendCurrentMessage();
   string          FormatTimestamp();
   int             MaxCharsPerLine();
   void            WrapText(string text, int maxChars, string &lines[], int &lineCount);
   void            AddInfoRow(int &yPos, int col1X, int col1W, int col2X, int col2W, int labelH, bool isHeader, string key, string val);

public:
   //--- Constructor / Destructor
   AIPanel(
      const string name,
      const int x1 = 0,
      const int y1 = 0,
      const int x2 = NULL,
      const int y2 = NULL,
      const int subWindow = 0
   );
   ~AIPanel();

   //--- Overrides
   bool            CreatePanel();
   virtual bool    OnResize(void);
   void            PanelChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void            OnTickUpdate();

   //--- Public methods
   void            AddMessage(string role, string content);
   void            RefreshInfo();
   void            SetAgent(Agent *ag)
   {
      m_agent = ag;
   }
   bool            IsRequestPending()
   {
      return m_requestPending;
   }
   string          GetPendingMessage()
   {
      return m_pendingMsg;
   }
   void            CompletePending(const string response);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
AIPanel::AIPanel(
   const string name,
   const int x1 = 0,
   const int y1 = 0,
   const int x2 = NULL,
   const int y2 = NULL,
   const int subWindow = 0
) : CPanelDraw(name, x1, y1, x2, y2, subWindow)
{
   m_isChatTab       = true;
   m_initialized     = false;
   m_messageCount    = 0;
   m_msgLabelCount   = 0;
   m_infoLabelCount  = 0;
   m_scrollOffset    = 0;
   m_agent           = NULL;
   m_requestPending  = false;
   m_pendingMsg      = "";
   m_tickCounter     = 0;
   m_chatTotalHeight = 0;
   m_infoScrollOffset = 0;
   m_infoTotalHeight = 0;

//--- DPI scaling
   m_dpi             = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(m_dpi < 96) m_dpi = 96;
   m_dpiScale        = (double)m_dpi / 96.0;

//--- Layout constants (DPI-aware)
   m_tabHeight       = (int)(28 * m_dpiScale);
   m_inputAreaHeight = (int)(40 * m_dpiScale);
   m_margin          = (int)(4 * m_dpiScale);
   m_msgSpacing      = (int)(6 * m_dpiScale);

//--- Color scheme (
   m_clrBg           = C'30,30,30';        // Dark background
   m_clrUserBubble   = C'10,132,255';      // Blue bubble (user)
   m_clrAiBubble     = C'55,55,60';        // Dark gray bubble (AI)
   m_clrUserText     = clrWhite;
   m_clrAiText       = C'220,220,220';
   m_clrTabActive    = C'50,50,55';        // Active tab
   m_clrTabInactive  = C'35,35,40';        // Inactive tab
   m_clrTabText      = C'200,200,200';
   m_clrInputBg      = C'45,45,50';        // Input area bg
   m_clrSendBtn      = C'10,132,255';      // Send button (blue accent)
   m_clrSendText     = clrWhite;
   m_clrAccent       = C'10,132,255';      // Blue accent
   m_clrBorder       = C'60,60,65';        // Border color
   m_panelName       = name;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
AIPanel::~AIPanel()
{
   DestroyMessageLabels();
   ClearInfoLabels();
}

//+------------------------------------------------------------------+
//| Destroy all message labels                                       |
//+------------------------------------------------------------------+
void AIPanel::DestroyMessageLabels()
{
   for(int i = 0; i < m_msgLabelCount; i++)
   {
      if(CheckPointer(m_msgLabels[i]) == POINTER_DYNAMIC)
      {
         delete m_msgLabels[i];
         m_msgLabels[i] = NULL;
      }
   }
   ArrayResize(m_msgLabels, 0);
   m_msgLabelCount = 0;
}

//+------------------------------------------------------------------+
//| Clear all info labels                                            |
//+------------------------------------------------------------------+
void AIPanel::ClearInfoLabels()
{
   for(int i = 0; i < m_infoLabelCount; i++)
   {
      if(CheckPointer(m_infoLabels[i]) == POINTER_DYNAMIC)
      {
         delete m_infoLabels[i];
         m_infoLabels[i] = NULL;
      }
   }
   ArrayResize(m_infoLabels, 0);
   m_infoLabelCount = 0;
}

//+------------------------------------------------------------------+
//| Create the panel and all child controls                          |
//+------------------------------------------------------------------+
bool AIPanel::CreatePanel()
{
//--- Calculate layout
   int panelW = Width();
   int panelH = Height();

   if(panelW < 200) panelW = 300;
   if(panelH < 200) panelH = 400;

   m_chatTop    = m_tabHeight + m_margin;
   m_chatBottom = panelH - m_inputAreaHeight - m_margin;
   m_chatHeight = m_chatBottom - m_chatTop;

   if(m_chatHeight < (int)(50 * m_dpiScale)) m_chatHeight = (int)(50 * m_dpiScale);

//--- DPI-scaled sizes
   int tabBtnW    = (int)(80 * m_dpiScale);
   int tabBtnGap  = 2;
   int tabBtnX2   = tabBtnW + tabBtnGap;
   int sendW      = (int)(65 * m_dpiScale);
   int sendH      = (int)(30 * m_dpiScale);
   int inputH     = (int)(30 * m_dpiScale);
   int scrlSize   = (int)(20 * m_dpiScale);
   int tabFontSz  = 11;
   int inputFontSz = 11;
   int scrlFontSz = 9;

//--- Create tab buttons
   m_btnChat.Create(NULL, m_panelName + "_TabChat", 0, 0, 0, tabBtnW, m_tabHeight);
   m_btnChat.Text("Chat");
   m_btnChat.FontSize(tabFontSz);
   m_btnChat.Font("Consolas");
   m_btnChat.Color(m_clrTabText);
   m_btnChat.ColorBackground(m_clrTabActive);
   CDialog::Add(m_btnChat);

   m_btnInfo.Create(NULL, m_panelName + "_TabInfo", 0, tabBtnX2 + tabBtnW, 0, tabBtnX2 + tabBtnW * 2, m_tabHeight);
   m_btnInfo.Text("Info");
   m_btnInfo.FontSize(tabFontSz);
   m_btnInfo.Font("Consolas");
   m_btnInfo.Color(m_clrTabText);
   m_btnInfo.ColorBackground(m_clrTabInactive);
   CDialog::Add(m_btnInfo);

//--- Input area
   int inputY    = panelH - m_inputAreaHeight;
   int sendX     = panelW - sendW - m_margin;
   int inputX    = m_margin;
   int inputY_C  = inputY + (m_inputAreaHeight - inputH) / 2;

   m_txtInput.Create(NULL, m_panelName + "_Input", 0, inputX, inputY_C, sendX - m_margin, inputY_C + inputH);
   m_txtInput.FontSize(inputFontSz);
   m_txtInput.Font("Consolas");
   m_txtInput.Color(m_clrAiText);
   m_txtInput.ColorBackground(m_clrInputBg);
   m_txtInput.ReadOnly(false);
   m_txtInput.Text("");
   m_txtInput.Alignment(WND_ALIGN_WIDTH, m_margin, 0, sendW + m_margin, 0);
   CDialog::Add(m_txtInput);

   m_btnSend.Create(NULL, m_panelName + "_Send", 0, sendX, inputY_C, sendX + sendW, inputY_C + sendH);
   m_btnSend.Text("Send");
   m_btnSend.FontSize(inputFontSz);
   m_btnSend.Font("Consolas");
   m_btnSend.Color(m_clrSendText);
   m_btnSend.ColorBackground(m_clrSendBtn);
   m_btnSend.Alignment(WND_ALIGN_RIGHT, 0, 0, m_margin, 0);
   CDialog::Add(m_btnSend);

//--- Scroll buttons
   int scrollY = m_chatTop + (int)(2 * m_dpiScale);
   int scrollX = panelW - scrlSize - m_margin;

   m_btnScrollUp.Create(NULL, m_panelName + "_ScrlUp", 0, scrollX, scrollY, scrollX + scrlSize, scrollY + scrlSize);
   m_btnScrollUp.Text("▲");
   m_btnScrollUp.FontSize(scrlFontSz);
   m_btnScrollUp.Font("Consolas");
   m_btnScrollUp.Color(m_clrTabText);
   m_btnScrollUp.ColorBackground(m_clrTabInactive);
   m_btnScrollUp.Alignment(WND_ALIGN_RIGHT, 0, 0, m_margin, 0);
   CDialog::Add(m_btnScrollUp);

   m_btnScrollDown.Create(NULL, m_panelName + "_ScrlDn", 0, scrollX, scrollY + scrlSize + (int)(2 * m_dpiScale), scrollX + scrlSize, scrollY + scrlSize * 2 + (int)(2 * m_dpiScale));
   m_btnScrollDown.Text("▼");
   m_btnScrollDown.FontSize(scrlFontSz);
   m_btnScrollDown.Font("Consolas");
   m_btnScrollDown.Color(m_clrTabText);
   m_btnScrollDown.ColorBackground(m_clrTabInactive);
   m_btnScrollDown.Alignment(WND_ALIGN_RIGHT, 0, 0, m_margin, 0);
   CDialog::Add(m_btnScrollDown);

//--- Run the dialog first (creates the background window)
   if(!this.Run())
   {
      Print("Failed to run panel");
      return false;
   }

   this.Maximize();

//--- Show initial tab
   SwitchToChat();

   m_initialized = true;
   return true;
}

//+------------------------------------------------------------------+
//| Switch to Chat tab                                               |
//+------------------------------------------------------------------+
void AIPanel::SwitchToChat()
{
   m_isChatTab = true;
   UpdateChatVisibility(true);
   UpdateInfoVisibility(false);

   m_btnChat.ColorBackground(m_clrTabActive);
   m_btnInfo.ColorBackground(m_clrTabInactive);

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Switch to Info tab                                               |
//+------------------------------------------------------------------+
void AIPanel::SwitchToInfo()
{
   m_isChatTab = false;
   UpdateChatVisibility(false);
   UpdateInfoVisibility(true);

   m_btnChat.ColorBackground(m_clrTabInactive);
   m_btnInfo.ColorBackground(m_clrTabActive);

   m_infoScrollOffset = 0;
   PopulateInfoTab();

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Show/hide chat-related controls                                  |
//+------------------------------------------------------------------+
void AIPanel::UpdateChatVisibility(bool show)
{
   if(show)
   {
      m_txtInput.Show();
   }
   else
   {
      m_txtInput.Hide();
   }
   if(show)
   {
      m_btnSend.Show();
   }
   else
   {
      m_btnSend.Hide();
   }

   m_btnScrollUp.Show();
   m_btnScrollDown.Show();

   for(int i = 0; i < m_msgLabelCount; i++)
   {
      if(CheckPointer(m_msgLabels[i]) == POINTER_DYNAMIC)
      {
         if(show) m_msgLabels[i].Show();
         else m_msgLabels[i].Hide();
      }
   }
}

//+------------------------------------------------------------------+
//| Show/hide info-related controls                                  |
//+------------------------------------------------------------------+
void AIPanel::UpdateInfoVisibility(bool show)
{
   for(int i = 0; i < m_infoLabelCount; i++)
   {
      if(CheckPointer(m_infoLabels[i]) == POINTER_DYNAMIC)
      {
         if(show) m_infoLabels[i].Show();
         else m_infoLabels[i].Hide();
      }
   }
}

//+------------------------------------------------------------------+
//| Max characters per line based on font size, DPI, and panel width |
//+------------------------------------------------------------------+
int AIPanel::MaxCharsPerLine()
{
   int panelW = Width();
   int pad    = (int)(4 * m_dpiScale);
   int labelW = panelW - (m_margin + pad) * 2;
// For Consolas 10pt: char height = pts * dpi / 72 (px).
// Monospace char width ≈ 0.60 × height (slightly conservative).
   double charWidth = (10.0 * m_dpi / 72.0) * 0.60;
   return MathMax(10, (int)(labelW / charWidth));
}

//+------------------------------------------------------------------+
//| Word-wrap a string into an array of lines                        |
//+------------------------------------------------------------------+
void AIPanel::WrapText(string text, int maxChars, string &lines[], int &lineCount)
{
   lineCount = 0;
   ArrayResize(lines, 0);
   if(StringLen(text) == 0) return;

// If short enough, keep as single line
   if(StringLen(text) <= maxChars)
   {
      lineCount = 1;
      ArrayResize(lines, 1);
      lines[0] = text;
      return;
   }

   string remaining = text;
   while(StringLen(remaining) > 0)
   {
      int len = StringLen(remaining);
      if(len <= maxChars)
      {
         ArrayResize(lines, lineCount + 1);
         lines[lineCount] = remaining;
         lineCount++;
         break;
      }

      // Check for newline within maxChars — forced break
      int nlPos = -1;
      for(int c = 0; c < maxChars && c < StringLen(remaining); c++)
      {
         if(StringSubstr(remaining, c, 1) == "\n")
         {
            nlPos = c;
            break;
         }
      }

      int breakPos;
      if(nlPos >= 0)
      {
         // Newline found — break right before it
         breakPos = nlPos;
      }
      else
      {
         // Find a good word-break point within maxChars — manual reverse scan
         breakPos = maxChars;
         for(int c = maxChars - 1; c >= 0; c--)
         {
            if(StringSubstr(remaining, c, 1) == " " && c > 0)
            {
               breakPos = c;
               break;
            }
         }
      }

      // Ensure breakPos >= 1 so we never emit an empty line
      if(breakPos < 1)
         breakPos = 1;

      string line = StringSubstr(remaining, 0, breakPos);
      StringTrimRight(line);
      if(StringLen(line) > 0)
      {
         ArrayResize(lines, lineCount + 1);
         lines[lineCount] = line;
         lineCount++;
      }
      else if(nlPos == 0)
      {
         // Empty line from leading newline — emit a blank line
         ArrayResize(lines, lineCount + 1);
         lines[lineCount] = "";
         lineCount++;
      }

      // Move past the break point (skip the newline if that's what we broke at)
      int skip = (nlPos >= 0) ? nlPos + 1 : breakPos;
      remaining = StringSubstr(remaining, skip);
      StringTrimLeft(remaining);
   }
}

//+------------------------------------------------------------------+
//| Add a message to the chat                                        |
//+------------------------------------------------------------------+
void AIPanel::AddMessage(string role, string content)
{
   int idx = m_messageCount;
   ArrayResize(m_messages, m_messageCount + 1);
   m_messages[idx].role    = role;
   m_messages[idx].content = content;
   m_messages[idx].time    = FormatTimestamp();
   m_messageCount++;

// Calculate total height considering newlines and word wrapping
   int maxChars = MaxCharsPerLine();
   int totalLines = 0;
   for(int m = 0; m < m_messageCount; m++)
   {
      string text = (m_messages[m].role == "user" ? "You: " : "AI: ") + m_messages[m].content;
      // Split by newlines — each segment is an independent wrapping block
      string seg = text;
      while(StringLen(seg) > 0)
      {
         int nlAt = StringFind(seg, "\n");
         string segment;
         if(nlAt >= 0)
         {
            segment = StringSubstr(seg, 0, nlAt);
            seg = StringSubstr(seg, nlAt + 1);
         }
         else
         {
            segment = seg;
            seg = "";
         }
         // Lines needed for this segment (word-wrap estimate)
         int segLen = StringLen(segment);
         if(segLen == 0)
         {
            totalLines++;  // blank line from consecutive newlines
         }
         else
         {
            totalLines += (segLen + maxChars - 1) / MathMax(1, maxChars);
         }
      }
   }
   const int LINE_H = (int)(18 * m_dpiScale);
   m_chatTotalHeight = totalLines * LINE_H + m_messageCount * m_msgSpacing + 10;

// Auto-scroll to bottom
   int maxScroll = MathMax(0, m_chatTotalHeight - m_chatHeight);
   m_scrollOffset = maxScroll;

   RenderMessages();
}

//+------------------------------------------------------------------+
//| Render chat message labels with word wrapping                    |
//+------------------------------------------------------------------+
void AIPanel::RenderMessages()
{
   DestroyMessageLabels();

   if(m_messageCount == 0) return;

   int panelW = Width();
   int maxChars = MaxCharsPerLine();
   const int LINE_H = (int)(18 * m_dpiScale);
   int labelX = m_margin + (int)(4 * m_dpiScale);
   int labelW = panelW - (m_margin + (int)(4 * m_dpiScale)) * 2;
   int msgFontSz = 10;

   int yPos = m_chatTop + 10 - m_scrollOffset;

   for(int i = 0; i < m_messageCount; i++)
   {
      string prefix = (m_messages[i].role == "user" ? "You: " : "AI: ");
      string fullText = prefix + m_messages[i].content;

      // Word-wrap this message
      string wrapped[];
      int lineCount;
      WrapText(fullText, maxChars, wrapped, lineCount);

      for(int l = 0; l < lineCount; l++)
      {
         int yEnd = yPos + LINE_H;

         // Only create labels whose top edge is within the chat area
         if(yEnd > m_chatTop && yPos < m_chatBottom)
         {
            int n = m_msgLabelCount;
            ArrayResize(m_msgLabels, n + 1);
            m_msgLabelCount = n + 1;
            m_msgLabels[n] = new CLabel();

            string labelName = m_panelName + "_Msg" + IntegerToString(i) + "_L" + IntegerToString(l);

            if(m_messages[i].role == "user")
            {
               m_msgLabels[n].Create(NULL, labelName, 0, labelX, yPos, labelX + labelW, yPos + LINE_H);
               m_msgLabels[n].Text(wrapped[l]);
               m_msgLabels[n].Color(m_clrUserText);
               m_msgLabels[n].ColorBackground(m_clrUserBubble);
               m_msgLabels[n].FontSize(msgFontSz);
               m_msgLabels[n].Font("Consolas");
            }
            else
            {
               m_msgLabels[n].Create(NULL, labelName, 0, labelX, yPos, labelX + labelW, yPos + LINE_H);
               m_msgLabels[n].Text(wrapped[l]);
               m_msgLabels[n].Color(m_clrAiText);
               m_msgLabels[n].ColorBackground(m_clrAiBubble);
               m_msgLabels[n].FontSize(msgFontSz);
               m_msgLabels[n].Font("Consolas");
            }

            if(m_isChatTab) m_msgLabels[n].Show();
            else m_msgLabels[n].Hide();
            CDialog::Add(m_msgLabels[n]);
         }

         yPos += LINE_H;
      }

      yPos += m_msgSpacing;
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Add a single info row (helper for PopulateInfoTab)               |
//+------------------------------------------------------------------+
void AIPanel::AddInfoRow(int &yPos, int col1X, int col1W, int col2X, int col2W, int labelH, bool isHeader, string key, string val)
{
   int n = m_infoLabelCount;

   ArrayResize(m_infoLabels, n + 2);
   m_infoLabelCount = n + 2;

   m_infoLabels[n] = new CLabel();
   string keyName = m_panelName + "_InfoK" + IntegerToString(n);
   m_infoLabels[n].Create(NULL, keyName, 0, col1X, yPos, col1X + col1W, yPos + labelH);
   m_infoLabels[n].Text(key);
   m_infoLabels[n].Color(isHeader ? m_clrAccent : C'160,160,160');
   m_infoLabels[n].ColorBackground(m_clrBg);
   int keyFontSz = isHeader ? 11 : 9;
   int valFontSz = 9;
   m_infoLabels[n].FontSize(keyFontSz);
   m_infoLabels[n].Font("Consolas");
   m_infoLabels[n].Hide();
   CDialog::Add(m_infoLabels[n]);

   m_infoLabels[n + 1] = new CLabel();
   string valName = m_panelName + "_InfoV" + IntegerToString(n);
   m_infoLabels[n + 1].Create(NULL, valName, 0, col2X, yPos, col2X + col2W, yPos + labelH);
// Truncate values wider than the label column using character count estimate
// Approx char width: fontSize_pt * dpi / 72 * 0.60
   double cw = (9.0 * m_dpi / 72.0) * 0.60;
   int maxValChars = (int)((col2W - 4) / cw) - 1; // -1 for "…"
   if(maxValChars > 3 && StringLen(val) > maxValChars)
      val = StringSubstr(val, 0, maxValChars - 1) + "…";
   m_infoLabels[n + 1].Text(val);
   m_infoLabels[n + 1].Color(m_clrAiText);
   m_infoLabels[n + 1].ColorBackground(m_clrBg);
   m_infoLabels[n + 1].FontSize(valFontSz);
   m_infoLabels[n + 1].Font("Consolas");
   m_infoLabels[n + 1].Hide();
   CDialog::Add(m_infoLabels[n + 1]);

   yPos += labelH;
}

//+------------------------------------------------------------------+
//| Populate Info tab with terminal, symbol, and account info        |
//+------------------------------------------------------------------+
void AIPanel::PopulateInfoTab()
{
   ClearInfoLabels();

   int panelW = Width();
   int labelH = (int)(16 * m_dpiScale);
   int headerH = (int)(18 * m_dpiScale);
   int sectionGap = (int)(4 * m_dpiScale);
   int col1X = m_margin + (int)(4 * m_dpiScale);
   int col1W = (int)(130 * m_dpiScale);
   int col2X = col1X + col1W;
   int col2W = panelW - col2X - m_margin - (int)(4 * m_dpiScale);
   int infoFontSz = (int)(9 * m_dpiScale);
   int headerFontSz = (int)(11 * m_dpiScale);

//--- Two-pass: first measure total height, then render visible portion
   struct InfoRow
   {
      string key;
      string val;
      bool isHdr;
   };
   InfoRow rows[99] = {};
   int rowCount = 0;

   rows[rowCount].key = "── Terminal Info ──";
   rows[rowCount].val = "";
   rows[rowCount].isHdr = true;
   rowCount++;
   rows[rowCount].key = "Name";
   rows[rowCount].val = TerminalInfoString(TERMINAL_NAME);
   rowCount++;
   rows[rowCount].key = "Data Path";
   rows[rowCount].val = TerminalInfoString(TERMINAL_DATA_PATH);
   rowCount++;
   rows[rowCount].key = "Build";
   rows[rowCount].val = IntegerToString((int)TerminalInfoInteger(TERMINAL_BUILD));
   rowCount++;
   rows[rowCount].key = "OS";
   rows[rowCount].val = TerminalInfoString(TERMINAL_OS_VERSION);
   rowCount++;
   rows[rowCount].key = "CPU";
   rows[rowCount].val = TerminalInfoString(TERMINAL_CPU_NAME);
   rowCount++;
   rows[rowCount].key = "Cores";
   rows[rowCount].val = IntegerToString((int)TerminalInfoInteger(TERMINAL_CPU_CORES));
   rowCount++;
   rows[rowCount].key = "X64";
   rows[rowCount].val = TerminalInfoInteger(TERMINAL_X64) ? "Yes" : "No";
   rowCount++;
   rows[rowCount].key = "Connected";
   rows[rowCount].val = TerminalInfoInteger(TERMINAL_CONNECTED) ? "Yes" : "No";
   rowCount++;
   rows[rowCount].key = "Ping (us)";
   rows[rowCount].val = IntegerToString((int)TerminalInfoInteger(TERMINAL_PING_LAST));
   rowCount++;
   rows[rowCount].key = "Width";
   rows[rowCount].val = IntegerToString((int)TerminalInfoInteger(TERMINAL_SCREEN_WIDTH));
   rowCount++;
   rows[rowCount].key = "Height";
   rows[rowCount].val = IntegerToString((int)TerminalInfoInteger(TERMINAL_SCREEN_HEIGHT));
   rowCount++;
   rows[rowCount].key = "Disk Space";
   rows[rowCount].val = IntegerToString((int)TerminalInfoInteger(TERMINAL_DISK_SPACE)) + " MB";
   rowCount++;
   rows[rowCount].key = "Memory Avail";
   rows[rowCount].val = IntegerToString((int)TerminalInfoInteger(TERMINAL_MEMORY_AVAILABLE)) + " MB";
   rowCount++;

   string symbol = _Symbol;
   int digits    = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   rows[rowCount].key = "── Symbol Info ──";
   rows[rowCount].val = "";
   rows[rowCount].isHdr = true;
   rowCount++;
   rows[rowCount].key = "Symbol";
   rows[rowCount].val = symbol;
   rowCount++;
   rows[rowCount].key = "Bid";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_BID), digits);
   rowCount++;
   rows[rowCount].key = "Ask";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_ASK), digits);
   rowCount++;
   rows[rowCount].key = "Spread";
   rows[rowCount].val = DoubleToString((SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID)) * MathPow(10, digits), 1);
   rowCount++;
   rows[rowCount].key = "Digits";
   rows[rowCount].val = IntegerToString(digits);
   rowCount++;
   rows[rowCount].key = "Point";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_POINT), digits + 2);
   rowCount++;
   rows[rowCount].key = "Tick Value";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE), 2);
   rowCount++;
   rows[rowCount].key = "Tick Size";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE), digits + 2);
   rowCount++;
   rows[rowCount].key = "Max Lot";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX), 2);
   rowCount++;
   rows[rowCount].key = "Min Lot";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN), 2);
   rowCount++;
   rows[rowCount].key = "Lot Step";
   rows[rowCount].val = DoubleToString(SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP), 2);
   rowCount++;
   rows[rowCount].key = "Stops Lev";
   rows[rowCount].val = IntegerToString((int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL));
   rowCount++;
   rows[rowCount].key = "Freeze Lev";
   rows[rowCount].val = IntegerToString((int)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL));
   rowCount++;
   rows[rowCount].key = "Exec Mode";
   rows[rowCount].val = EnumToString((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(symbol, SYMBOL_TRADE_EXEMODE));
   rowCount++;

   rows[rowCount].key = "── Account Info ──";
   rows[rowCount].val = "";
   rows[rowCount].isHdr = true;
   rowCount++;
   rows[rowCount].key = "Login";
   rows[rowCount].val = IntegerToString((int)AccountInfoInteger(ACCOUNT_LOGIN));
   rowCount++;
   rows[rowCount].key = "Name";
   rows[rowCount].val = AccountInfoString(ACCOUNT_NAME);
   rowCount++;
   rows[rowCount].key = "Company";
   rows[rowCount].val = AccountInfoString(ACCOUNT_COMPANY);
   rowCount++;
   rows[rowCount].key = "Currency";
   rows[rowCount].val = AccountInfoString(ACCOUNT_CURRENCY);
   rowCount++;
   rows[rowCount].key = "Balance";
   rows[rowCount].val = DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2);
   rowCount++;
   rows[rowCount].key = "Equity";
   rows[rowCount].val = DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2);
   rowCount++;
   rows[rowCount].key = "Margin";
   rows[rowCount].val = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN), 2);
   rowCount++;
   rows[rowCount].key = "Free Margin";
   rows[rowCount].val = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2);
   rowCount++;
   rows[rowCount].key = "Margin Lvl";
   rows[rowCount].val = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), 2);
   rowCount++;
   rows[rowCount].key = "Profit";
   rows[rowCount].val = DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT), 2);
   rowCount++;
   rows[rowCount].key = "Leverage";
   rows[rowCount].val = IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE));
   rowCount++;
   rows[rowCount].key = "Trade Allow";
   rows[rowCount].val = AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ? "Yes" : "No";
   rowCount++;

// --- Pre-calculate total content height ---
   m_infoTotalHeight = 0;
   for(int r = 0; r < rowCount; r++)
   {
      m_infoTotalHeight += (rows[r].isHdr ? headerH : labelH);
      if(r + 1 < rowCount && rows[r + 1].isHdr)
         m_infoTotalHeight += sectionGap;
   }

// --- Render visible rows ---
   int yPos = m_chatTop + (int)(4 * m_dpiScale) - m_infoScrollOffset;

   for(int r = 0; r < rowCount; r++)
   {
      int rowH = rows[r].isHdr ? headerH : labelH;
      int yEnd = yPos + rowH;

      // Only render rows fully visible or partially visible at top/bottom
      bool partiallyVisible = (yEnd > m_chatTop && yPos < m_chatBottom);
      if(partiallyVisible)
      {
         if(rows[r].isHdr)
            AddInfoRow(yPos, col1X, col1W, col2X, col2W, headerH, true, rows[r].key, rows[r].val);
         else
            AddInfoRow(yPos, col1X, col1W, col2X, col2W, labelH, false, rows[r].key, rows[r].val);
      }

      yPos += rowH;
      if(r + 1 < rowCount && rows[r + 1].isHdr)
         yPos += sectionGap;
   }

   if(!m_isChatTab)
      UpdateInfoVisibility(true);

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Send the current message from input                              |
//+------------------------------------------------------------------+
void AIPanel::SendCurrentMessage()
{
   if(m_requestPending) return;

   string inputText = m_txtInput.Text();
   if(StringLen(inputText) == 0) return;

   StringTrimLeft(inputText);
   StringTrimRight(inputText);
   if(StringLen(inputText) == 0) return;

   m_txtInput.Text("");

   AddMessage("user", inputText);

   if(CheckPointer(m_agent) == POINTER_DYNAMIC)
   {
      m_requestPending = true;
      m_pendingMsg = inputText;
      AddMessage("assistant", "Thinking...");
   }
}

//+------------------------------------------------------------------+
//| Complete a pending AI request with the actual response           |
//+------------------------------------------------------------------+
void AIPanel::CompletePending(const string response)
{
   if(!m_requestPending) return;

   m_requestPending = false;

   if(m_messageCount > 0)
   {
      m_messageCount--;
      ArrayResize(m_messages, m_messageCount);
   }

   AddMessage("assistant", response);
}

//+------------------------------------------------------------------+
//| Refresh the info tab data                                        |
//+------------------------------------------------------------------+
void AIPanel::RefreshInfo()
{
   if(!m_isChatTab && m_initialized)
      PopulateInfoTab();
}

//+------------------------------------------------------------------+
//| Format current timestamp as string                               |
//+------------------------------------------------------------------+
string AIPanel::FormatTimestamp()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   return StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);
}

//+------------------------------------------------------------------+
//| Called when the dialog is resized (e.g. chart resize)           |
//+------------------------------------------------------------------+
bool AIPanel::OnResize(void)
{
   if(!CPanelDraw::OnResize())
      return(false);
   int panelW = Width();
   int panelH = Height();
   if(panelW < 200) panelW = 300;
   if(panelH < 200) panelH = 400;
   m_chatTop    = m_tabHeight + m_margin;
   m_chatBottom = panelH - m_inputAreaHeight - m_margin;
   m_chatHeight = m_chatBottom - m_chatTop;
   if(m_chatHeight < (int)(50 * m_dpiScale))
      m_chatHeight = (int)(50 * m_dpiScale);
// Clamp scroll offsets to valid range after resize
   m_scrollOffset    = MathMax(0, MathMin(m_scrollOffset,    m_chatHeight * 10));
   m_infoScrollOffset = MathMax(0, MathMin(m_infoScrollOffset, m_chatHeight * 10));
// Re-render current tab content with new dimensions
   if(m_isChatTab)
      RenderMessages();
   else
      PopulateInfoTab();
   ChartRedraw();
   return(true);
}

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
void AIPanel::PanelChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   CPanelDraw::PanelChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == m_panelName + "_TabChat")
      {
         if(!m_isChatTab) SwitchToChat();
      }
      else if(sparam == m_panelName + "_TabInfo")
      {
         if(m_isChatTab) SwitchToInfo();
      }
      else if(sparam == m_panelName + "_Send")
      {
         SendCurrentMessage();
      }
      else if(sparam == m_panelName + "_ScrlUp")
      {
         if(m_isChatTab)
         {
            m_scrollOffset = MathMax(0, m_scrollOffset - (int)(60 * m_dpiScale));
            RenderMessages();
         }
         else
         {
            m_infoScrollOffset = MathMax(0, m_infoScrollOffset - (int)(60 * m_dpiScale));
            PopulateInfoTab();
         }
      }
      else if(sparam == m_panelName + "_ScrlDn")
      {
         if(m_isChatTab)
         {
            int maxScroll = MathMax(0, m_chatTotalHeight - m_chatHeight);
            m_scrollOffset = MathMin(maxScroll, m_scrollOffset + (int)(60 * m_dpiScale));
            RenderMessages();
         }
         else
         {
            int maxScroll = MathMax(0, m_infoTotalHeight + (int)(4 * m_dpiScale) - m_chatHeight);
            m_infoScrollOffset = MathMin(maxScroll, m_infoScrollOffset + (int)(60 * m_dpiScale));
            PopulateInfoTab();
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Called on every tick to refresh dynamic info                     |
//+------------------------------------------------------------------+
void AIPanel::OnTickUpdate()
{
   if(!m_isChatTab && m_initialized)
   {
      m_tickCounter++;
      if(m_tickCounter >= 10)
      {
         m_tickCounter = 0;
         PopulateInfoTab();
      }
   }
}

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
AIPanel  *panel;
Agent    *agent;
//+------------------------------------------------------------------+
