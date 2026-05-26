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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
{
   Agent *agent = new Agent();

// get a response
   string response = agent.run("What is today's daily high of ETHUSD?");
   Print("[Agent] ", response);

   delete agent; // clean up the agent
}
//+------------------------------------------------------------------+
