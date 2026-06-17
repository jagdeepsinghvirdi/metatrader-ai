//+------------------------------------------------------------------+
//|                                                          llm.mqh |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property strict

enum ENUM_LLM_PROVIDER
{
   LLM_PROVIDER_OPENAI = 0,  // OpenAI
   LLM_PROVIDER_DEEPSEEK = 1 // DeepSeek
};

enum ENUM_OPENAI_MODEL
{
   OPENAI_MODEL_GPT_5_4_NANO = 0, // gpt-5.4-nano
   OPENAI_MODEL_GPT_5_4_MINI = 1, // gpt-5.4-mini
   OPENAI_MODEL_GPT_5_4      = 2, // gpt-5.4
   OPENAI_MODEL_GPT_5_5      = 3, // gpt-5.5
};

enum ENUM_DEEPSEEK_MODEL
{
   DEEPSEEK_MODEL_V4_FLASH = 0, // deepseek-v4-flash
   DEEPSEEK_MODEL_V4_PRO   = 1, // deepseek-v4-pro
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class LLM
{
public:
   string id;
   string label;
   string model;
   string url;

   LLM(const ENUM_LLM_PROVIDER providerId = LLM_PROVIDER_DEEPSEEK, const int providerModel = DEEPSEEK_MODEL_V4_FLASH);
};
//+------------------------------------------------------------------+
LLM::LLM(const ENUM_LLM_PROVIDER providerId, const int providerModel)
{
   if(providerId == LLM_PROVIDER_OPENAI)
   {
      id    = "openai";
      label = "OpenAI";
      switch(providerModel)
      {
      case OPENAI_MODEL_GPT_5_4_NANO:
         model = "gpt-5.4-nano";
         break;
      case OPENAI_MODEL_GPT_5_4_MINI:
         model = "gpt-5.4-mini";
         break;
      case OPENAI_MODEL_GPT_5_4:
         model = "gpt-5.4";
         break;
      case OPENAI_MODEL_GPT_5_5:
         model = "gpt-5.5";
         break;
      default:
         model = "gpt-5.4-mini";
         break;
      };
      url   = "https://api.openai.com/v1/chat/completions";
   }
   else if(providerId == LLM_PROVIDER_DEEPSEEK)
   {
      id    = "deepseek";
      label = "DeepSeek";
      model = providerModel == DEEPSEEK_MODEL_V4_PRO ? "deepseek-v4-pro" : "deepseek-v4-flash";
      url   = "https://api.deepseek.com/chat/completions";
   }
   else
   {
      Alert("Invalid provider_id. Must be 0 (OpenAI) or 1 (DeepSeek).");
   }
}
//+------------------------------------------------------------------+
