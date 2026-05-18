//+------------------------------------------------------------------+
//|                                                    constants.mqh |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property strict

#include <metatrader-ai/mql/tools/tool.mqh>

//+------------------------------------------------------------------+
//| Account info tool                                                |
//+------------------------------------------------------------------+
Tool TOOL_ACCOUNT_INFO(
   "get_account_info",
   "Get account information such as balance, equity, margin, etc.",
   NULL
);
//+------------------------------------------------------------------+
//| Parameters for get_history_position                              |
//+------------------------------------------------------------------+
Parameters *toolHistoryPositionParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("ticket", "integer", "The ticket number of the closed position", true));
   return p;
}
//+------------------------------------------------------------------+
//| Get history position tool                                        |
//+------------------------------------------------------------------+
Tool TOOL_HISTORY_POSITION(
   "get_history_position",
   "Get all deals related to the ticket number of a closed position.",
   toolHistoryPositionParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_history_positions                             |
//+------------------------------------------------------------------+
Parameters *toolHistoryPositionsParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol",    "string",  "Filter by symbol (optional)"));
   p.add(new Property("magic",     "integer", "Filter by magic number (optional)"));
   p.add(new Property("from_date", "string",  "Filter from this date (optional)"));
   p.add(new Property("to_date",   "string",  "Filter to this date (optional)"));
   return p;
}

//+------------------------------------------------------------------+
//| Get history positions tool                                       |
//+------------------------------------------------------------------+
Tool TOOL_HISTORY_POSITIONS(
   "get_history_positions",
   "Get historical positions, optionally filtered by symbol, magic number, and date range.",
   toolHistoryPositionsParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_order                                         |
//+------------------------------------------------------------------+
Parameters *toolGetOrderParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("ticket", "integer", "The ticket number of the pending order", true));
   return p;
}
//+------------------------------------------------------------------+
//| Get order tool                                                   |
//+------------------------------------------------------------------+
Tool TOOL_GET_ORDER(
   "get_order",
   "Get a specific pending order by ticket number.",
   toolGetOrderParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_orders                                        |
//+------------------------------------------------------------------+
Parameters *toolGetOrdersParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol", "string", "Filter by symbol (optional)"));
   return p;
}
//+------------------------------------------------------------------+
//| Get orders tool                                                  |
//+------------------------------------------------------------------+
Tool TOOL_GET_ORDERS(
   "get_orders",
   "Get all pending orders, optionally filtered by symbol.",
   toolGetOrdersParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_pip_value                                     |
//+------------------------------------------------------------------+
Parameters *toolGetPipValueParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol", "string", "The trading symbol to get the pip value for", true));
   return p;
}
//+------------------------------------------------------------------+
//| Get pip value tool                                               |
//+------------------------------------------------------------------+
Tool TOOL_GET_PIP_VALUE(
   "get_pip_value",
   "Get the pip value for a specific symbol.",
   toolGetPipValueParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_position                                      |
//+------------------------------------------------------------------+
Parameters *toolGetPositionParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("ticket", "integer", "The ticket number of the open position", true));
   return p;
}
//+------------------------------------------------------------------+
//| Get position tool                                                |
//+------------------------------------------------------------------+
Tool TOOL_GET_POSITION(
   "get_position",
   "Get a specific open position by ticket number.",
   toolGetPositionParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_positions                                     |
//+------------------------------------------------------------------+
Parameters *toolGetPositionsParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol", "string", "Filter by symbol (optional)"));
   return p;
}
//+------------------------------------------------------------------+
//| Get positions tool                                               |
//+------------------------------------------------------------------+
Tool TOOL_GET_POSITIONS(
   "get_positions",
   "Get all open positions, optionally filtered by symbol.",
   toolGetPositionsParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_recent_bars                                   |
//+------------------------------------------------------------------+
Parameters *toolGetRecentBarsParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol",         "string",  "The trading symbol",                             true));
   p.add(new Property("timeframe",      "string",  "The timeframe (e.g. 1 for 1-Minute, 5 for 5-Minute, 15 for 15-Minute, 30 for 30-Minute, 16385 for 1-Hour, 16388 for 4-Hour, 16408 for Daily, 32769 for Weekly, 49153 for Monthly)", true));
   p.add(new Property("number_of_bars", "integer", "The number of bars to retrieve",                 true));
   p.add(new Property("shift",          "integer", "The bar index to start from (optional, default 0)"));
   return p;
}
//+------------------------------------------------------------------+
//| Get recent bars tool                                             |
//+------------------------------------------------------------------+
Tool TOOL_GET_RECENT_BARS(
   "get_recent_bars",
   "Get recent OHLCV bars for a specific symbol and timeframe.",
   toolGetRecentBarsParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_risk                                          |
//+------------------------------------------------------------------+
Parameters *toolGetRiskParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol",          "string", "The trading symbol",                                true));
   p.add(new Property("percent_risk",    "number", "The percentage of account equity to risk",          true));
   p.add(new Property("stop_loss_pips",  "number", "The stop loss distance in pips",                   true));
   return p;
}
//+------------------------------------------------------------------+
//| Get risk tool                                                    |
//+------------------------------------------------------------------+
Tool TOOL_GET_RISK(
   "get_risk",
   "Calculate the lot size based on a percentage risk and stop loss in pips.",
   toolGetRiskParams()
);
//+------------------------------------------------------------------+
//| Parameters for get_symbol_info                                   |
//+------------------------------------------------------------------+
Parameters *toolGetSymbolInfoParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol", "string", "The trading symbol to retrieve information for", true));
   return p;
}
//+------------------------------------------------------------------+
//| Get symbol info tool                                             |
//+------------------------------------------------------------------+
Tool TOOL_GET_SYMBOL_INFO(
   "get_symbol_info",
   "Get symbol information such as bid, ask, spread, digits, and lot limits.",
   toolGetSymbolInfoParams()
);
//+------------------------------------------------------------------+
//| Parameters for iClose/iDate/iHigh/iLow/iOpen                    |
//+------------------------------------------------------------------+
Parameters *toolIBarParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol",    "string",  "The trading symbol",                                                             true));
   p.add(new Property("timeframe", "string",  "The timeframe (e.g. PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1)", true));
   p.add(new Property("shift",     "integer", "The bar index where 0 is the current bar",                                      true));
   return p;
}
//+------------------------------------------------------------------+
//| iClose tool                                                      |
//+------------------------------------------------------------------+
Tool TOOL_ICLOSE(
   "iClose",
   "Get the close price of a specific historical bar.",
   toolIBarParams()
);
//+------------------------------------------------------------------+
//| iDate tool                                                       |
//+------------------------------------------------------------------+
Tool TOOL_IDATE(
   "iDate",
   "Get the date and time of a specific historical bar.",
   toolIBarParams()
);
//+------------------------------------------------------------------+
//| iHigh tool                                                       |
//+------------------------------------------------------------------+
Tool TOOL_IHIGH(
   "iHigh",
   "Get the high price of a specific historical bar.",
   toolIBarParams()
);
//+------------------------------------------------------------------+
//| iLow tool                                                        |
//+------------------------------------------------------------------+
Tool TOOL_ILOW(
   "iLow",
   "Get the low price of a specific historical bar.",
   toolIBarParams()
);
//+------------------------------------------------------------------+
//| iOpen tool                                                       |
//+------------------------------------------------------------------+
Tool TOOL_IOPEN(
   "iOpen",
   "Get the open price of a specific historical bar.",
   toolIBarParams()
);
//+------------------------------------------------------------------+
//| Parameters for is_order_opened                                   |
//+------------------------------------------------------------------+
Parameters *toolIsOrderOpenedParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol", "string",  "Filter by symbol (optional)"));
   p.add(new Property("magic",  "integer", "Filter by magic number (optional)"));
   return p;
}
//+------------------------------------------------------------------+
//| Is order opened tool                                             |
//+------------------------------------------------------------------+
Tool TOOL_IS_ORDER_OPENED(
   "is_order_opened",
   "Check whether any pending orders are currently open, optionally filtered by symbol and magic number.",
   toolIsOrderOpenedParams()
);
//+------------------------------------------------------------------+
//| Parameters for is_position_opened                                |
//+------------------------------------------------------------------+
Parameters *toolIsPositionOpenedParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol", "string",  "Filter by symbol (optional)"));
   p.add(new Property("magic",  "integer", "Filter by magic number (optional)"));
   return p;
}
//+------------------------------------------------------------------+
//| Is position opened tool                                          |
//+------------------------------------------------------------------+
Tool TOOL_IS_POSITION_OPENED(
   "is_position_opened",
   "Check whether any positions are currently open, optionally filtered by symbol and magic number.",
   toolIsPositionOpenedParams()
);
//+------------------------------------------------------------------+
//| Parameters for order_delete                                      |
//+------------------------------------------------------------------+
Parameters *toolOrderDeleteParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("ticket", "integer", "The ticket number of the pending order to delete", true));
   return p;
}
//+------------------------------------------------------------------+
//| Order delete tool                                                |
//+------------------------------------------------------------------+
Tool TOOL_ORDER_DELETE(
   "order_delete",
   "Delete a pending order by ticket number.",
   toolOrderDeleteParams()
);
//+------------------------------------------------------------------+
//| Parameters for order_send                                        |
//+------------------------------------------------------------------+
Parameters *toolOrderSendParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol",      "string",  "The trading symbol",                              true));
   p.add(new Property("type",        "string",  "The order type (e.g. ORDER_TYPE_BUY)",            true));
   p.add(new Property("volume",      "number",  "The lot size",                                    true));
   p.add(new Property("price",       "number",  "The entry price (0 for market order)",            true));
   p.add(new Property("slippage",    "integer", "Maximum allowed slippage in points",              true));
   p.add(new Property("stoploss",    "number",  "Absolute stop loss price (0 to disable)",         true));
   p.add(new Property("takeprofit",  "number",  "Absolute take profit price (0 to disable)",       true));
   p.add(new Property("comment",     "string",  "Order comment (optional)"));
   p.add(new Property("magic",       "integer", "Magic number (optional)"));
   return p;
}
//+------------------------------------------------------------------+
//| Order send tool                                                  |
//+------------------------------------------------------------------+
Tool TOOL_ORDER_SEND(
   "order_send",
   "Send an order using absolute entry, stop loss, and take profit prices.",
   toolOrderSendParams()
);
//+------------------------------------------------------------------+
//| Parameters for order_send_pips                                   |
//+------------------------------------------------------------------+
Parameters *toolOrderSendPipsParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol",          "string",  "The trading symbol",                              true));
   p.add(new Property("type",            "string",  "The order type (e.g. ORDER_TYPE_BUY)",            true));
   p.add(new Property("volume",          "number",  "The lot size",                                    true));
   p.add(new Property("price",           "number",  "The entry price (0 for market order)",            true));
   p.add(new Property("slippage",        "integer", "Maximum allowed slippage in points",              true));
   p.add(new Property("stoploss_pips",   "number",  "Stop loss distance in pips",                      true));
   p.add(new Property("takeprofit_pips", "number",  "Take profit distance in pips",                    true));
   p.add(new Property("comment",         "string",  "Order comment (optional)"));
   p.add(new Property("magic",           "integer", "Magic number (optional)"));
   return p;
}
//+------------------------------------------------------------------+
//| Order send pips tool                                             |
//+------------------------------------------------------------------+
Tool TOOL_ORDER_SEND_PIPS(
   "order_send_pips",
   "Send an order using entry price, stop loss, and take profit distances in pips.",
   toolOrderSendPipsParams()
);
//+------------------------------------------------------------------+
//| Parameters for order_modify                                      |
//+------------------------------------------------------------------+
Parameters *toolOrderModifyParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("ticket",      "integer", "The ticket number of the pending order to modify", true));
   p.add(new Property("price",       "number",  "New entry price",                                  true));
   p.add(new Property("stop_loss",   "number",  "New stop loss price",                              true));
   p.add(new Property("take_profit", "number",  "New take profit price",                            true));
   return p;
}
//+------------------------------------------------------------------+
//| Order modify tool                                                |
//+------------------------------------------------------------------+
Tool TOOL_ORDER_MODIFY(
   "order_modify",
   "Modify the price, stop loss, and take profit of an existing pending order.",
   toolOrderModifyParams()
);
//+------------------------------------------------------------------+
//| Parameters for position_close                                    |
//+------------------------------------------------------------------+
Parameters *toolPositionCloseParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("ticket", "integer", "The ticket number of the open position to close", true));
   return p;
}
//+------------------------------------------------------------------+
//| Position close tool                                              |
//+------------------------------------------------------------------+
Tool TOOL_POSITION_CLOSE(
   "position_close",
   "Close an open position by ticket number.",
   toolPositionCloseParams()
);
//+------------------------------------------------------------------+
//| Parameters for position_modify                                   |
//+------------------------------------------------------------------+
Parameters *toolPositionModifyParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol",      "string",  "The trading symbol of the position",              true));
   p.add(new Property("ticket",      "integer", "The ticket number of the position to modify",     true));
   p.add(new Property("stop_loss",   "number",  "New stop loss price",                             true));
   p.add(new Property("take_profit", "number",  "New take profit price",                           true));
   return p;
}
//+------------------------------------------------------------------+
//| Position modify tool                                             |
//+------------------------------------------------------------------+
Tool TOOL_POSITION_MODIFY(
   "position_modify",
   "Modify the stop loss and take profit of an existing open position.",
   toolPositionModifyParams()
);
//+------------------------------------------------------------------+
//| Parameters for select_symbol                                     |
//+------------------------------------------------------------------+
Parameters *toolSelectSymbolParams(void)
{
   Parameters *p = new Parameters();
   p.add(new Property("symbol", "string",  "The trading symbol to enable or disable in Market Watch", true));
   p.add(new Property("enable", "boolean", "True to enable, false to disable (optional, default true)"));
   return p;
}
//+------------------------------------------------------------------+
//| Select symbol tool                                               |
//+------------------------------------------------------------------+
Tool TOOL_SELECT_SYMBOL(
   "select_symbol",
   "Enable or disable a symbol in the Market Watch.",
   toolSelectSymbolParams()
);
//+------------------------------------------------------------------+
