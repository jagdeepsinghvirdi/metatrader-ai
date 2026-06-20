//+------------------------------------------------------------------+
//|                                                  backtesting.mqh |
//|                                      Copyright 2026,JBlanked LLC |
//|                                         https://www.jblanked.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked LLC"
#property link      "https://www.jblanked.com"
#property strict

#include "JSON.mqh"
#include "JB-Backtest.mqh"

// forwards (in mql4 is shows import warning)
#ifdef __MQL5__
string backtestSingle(CJAVal &testInputs, CJAVal &expertParams);
#endif

/*
- Test Inputs
  - name
  - symbol
  - timeframe
  - to_date
  - from_date
  - deposit
- Expert Params (array)
  - key
  - value
  - type (string, bool, double, int)
*/

//+------------------------------------------------------------------+
//| Run a single test in the strategy tester                         |
//+------------------------------------------------------------------+
string backtestSingle(CJAVal &testInputs, CJAVal &expertParams)
{
   testerInputs inputs;
   inputs.expertName            = testInputs["name"].ToStr();                       // my-expert.ex5 (expert advisor name)
   inputs.symbol                = testInputs["symbol"].ToStr();                     // EURUSD.PRO (currency pair)
   inputs.currency              = AccountInfoString(ACCOUNT_CURRENCY);              // Account currency
   inputs.timeFrame             = (ENUM_TIMEFRAMES)testInputs["timeframe"].ToInt(); // timeframe to test (PERIOD_xxx);
   inputs.toDate                = (datetime)testInputs["to_date"].ToStr();          // start date
   inputs.fromDate              = (datetime)testInputs["from_date"].ToStr();        // end date
   inputs.leverage              = AccountInfoInteger(ACCOUNT_LEVERAGE);             // leverage
   inputs.executionMode         = 27;                                               // execution mode
   inputs.visual                = false;                                            // visual
   inputs.optimization          = false;                                            // optimization off
   inputs.model                 = 0;                                                // every tick (0 — "Every tick", 1 — "1 minute OHLC", 2 — "Open price only", 3 — "Math calculations", 4 — "Every tick based on real ticks")
   inputs.forwardMode           = false;                                            // forward mode off
   inputs.profitInPips          = false;                                            // use profit in dollars
   inputs.deposit               = testInputs["deposit"].ToDbl();                    // starting balance to test
   inputs.optimizationCriterion = 3;                                                // criterion

   CBacktest test(inputs);
   const int listSize = ArraySize(expertParams.m_e);
   string paramType = "";
   for (int i = 0; i < listSize; i++)
   {
      paramType = expertParams[i]["type"].ToStr();
      if(paramType == "string")
      {
         test.addSetting(expertParams[i]["key"].ToStr(), expertParams[i]["value"].ToStr());
      }
      else if(paramType == "int")
      {
         test.addSetting(expertParams[i]["key"].ToStr(), IntegerToString(expertParams[i]["value"].ToInt()));
      }
      else if(paramType == "double")
      {
         test.addSetting(expertParams[i]["key"].ToStr(), test.doubleToString(expertParams[i]["value"].ToDbl()));
      }
      else if(paramType == "bool")
      {
         test.addSetting(expertParams[i]["key"].ToStr(), (string)expertParams[i]["value"].ToBool());
      }
      else
      {
         test.addSetting(expertParams[i]["key"].ToStr(), expertParams[i]["value"].ToStr());
      }
   }

   return test.run();
}
//+------------------------------------------------------------------+
