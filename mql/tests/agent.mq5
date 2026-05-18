//+------------------------------------------------------------------+
//|                                                        agent.mq5 |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property version   "1.00"
#property strict

#include <metatrader-ai/mql/agent.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
{
   agentInit(); // initialize the agent

// get a response
   string response = agentRun("What is today's daily high of ETHUSD?");
   Print("[Agent] ", response);

   agentDeinit(); // clean up the agent
}
//+------------------------------------------------------------------+
