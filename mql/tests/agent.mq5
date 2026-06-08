//+------------------------------------------------------------------+
//|                                                        agent.mq5 |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property version   "1.01"
#property strict

#include <metatrader-ai/mql/agent.mqh>

input string inpApiKey = "sk-";                                  // Your OpenAI Key
input string inpPrompt = "What do you see on my current chart?"; // Prompt
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   if(StringLen(inpApiKey) <= 3)
   {
      Alert("Wrong API Key! Grab one from \"platform.openai.com/api-keys\"");
      return INIT_FAILED;
   }

   OPENAI_API_KEY = inpApiKey;

   Agent *agent = new Agent();

   const string response = agent.run(inpPrompt);
   Print("[Agent] ", response);

   delete agent; // clean up the agent
   ExpertRemove();
   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
{

}
//+------------------------------------------------------------------+
