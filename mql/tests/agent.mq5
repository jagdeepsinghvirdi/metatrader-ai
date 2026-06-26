//+------------------------------------------------------------------+
//|                                                        agent.mq5 |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property version   "1.03"
#property strict

#include <metatrader-ai/mql/agent.mqh>

input string inpApiKey                     = "sk-";                                  // Your API Key
input string inpPrompt                     = "What do you see on my current chart?"; // Prompt
input ENUM_LLM_PROVIDER inpProvider        = LLM_PROVIDER_DEEPSEEK;                  // LLM Provider
input ENUM_DEEPSEEK_MODEL inpDeepSeekModel = DEEPSEEK_MODEL_V4_FLASH;                // DeepSeek Model
input ENUM_OPENAI_MODEL inpOpenAIModel     = OPENAI_MODEL_GPT_5_4_NANO;              // OpenAI Model
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   if(StringLen(inpApiKey) <= 3)
   {
      if(inpProvider == LLM_PROVIDER_OPENAI)
      {
      Alert("Wrong API Key! Grab one from \"platform.openai.com/api-keys\"");
      }
      else if(inpProvider == LLM_PROVIDER_DEEPSEEK)
      {
      Alert("Wrong API Key! Grab one from \"platform.deepseek.com/api-keys\"");
      }
      return INIT_FAILED;
   }

   Agent *agent = new Agent(inpApiKey, inpProvider, inpProvider == LLM_PROVIDER_OPENAI ? (int)inpOpenAIModel : (int)inpDeepSeekModel);

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
