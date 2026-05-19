//+------------------------------------------------------------------+
//|                                                     dispatch.mqh |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property strict
#include <metatrader-ai/mql/tools/constants.mqh>
#include <metatrader-ai/mql/tools/mt5.mqh>

#define BOOL_TO_STRING(value) ((value) ? "true" : "false")
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES StringToTimeframe(string tf)
{
   if (tf == "PERIOD_M1")  return PERIOD_M1;
   if (tf == "PERIOD_M5")  return PERIOD_M5;
   if (tf == "PERIOD_M15") return PERIOD_M15;
   if (tf == "PERIOD_H1")  return PERIOD_H1;
   if (tf == "PERIOD_H4")  return PERIOD_H4;
   if (tf == "PERIOD_D1")  return PERIOD_D1;
   return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE StringToOrderType(string t)
{
   if (t == "ORDER_TYPE_BUY")        return ORDER_TYPE_BUY;
   if (t == "ORDER_TYPE_SELL")       return ORDER_TYPE_SELL;
   if (t == "ORDER_TYPE_BUY_LIMIT")  return ORDER_TYPE_BUY_LIMIT;
   if (t == "ORDER_TYPE_SELL_LIMIT") return ORDER_TYPE_SELL_LIMIT;
   if (t == "ORDER_TYPE_BUY_STOP")   return ORDER_TYPE_BUY_STOP;
   return ORDER_TYPE_SELL_STOP;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Dispatch
{
public:
   Tool *tools[];
   int   count;

   Dispatch()
   {
      count = 0;
      ArrayResize(tools, 0);

      // register every tool
      add(new Tool("get_account_info",     "Get account information such as balance, equity, margin, etc.", NULL));
      add(new Tool("get_history_position", "Get all deals related to the ticket number of a closed position.", toolHistoryPositionParams()));
      add(new Tool("get_history_positions", "Get historical positions, optionally filtered.",                   toolHistoryPositionsParams()));
      add(new Tool("get_order",            "Get a specific pending order by ticket number.",                   toolGetOrderParams()));
      add(new Tool("get_orders",           "Get all pending orders, optionally filtered by symbol.",           toolGetOrdersParams()));
      add(new Tool("get_pip_value",        "Get the pip value for a specific symbol.",                        toolGetPipValueParams()));
      add(new Tool("get_position",         "Get a specific open position by ticket number.",                   toolGetPositionParams()));
      add(new Tool("get_positions",        "Get all open positions, optionally filtered by symbol.",           toolGetPositionsParams()));
      add(new Tool("get_recent_bars",      "Get recent OHLCV bars for a specific symbol and timeframe.",       toolGetRecentBarsParams()));
      add(new Tool("get_risk",             "Calculate the lot size based on a percentage risk and stop loss in pips.", toolGetRiskParams()));
      add(new Tool("get_screenshot",        "Screenshot a chart, optionally switch to symbol/timeframe first.", toolGetScreenshotParams()));
      add(new Tool("get_symbol_info",      "Get symbol information such as bid, ask, spread, etc.",           toolGetSymbolInfoParams()));
      add(new Tool("iClose",               "Get the close price of a specific historical bar.",               toolIBarParams()));
      add(new Tool("iDate",                "Get the date and time of a specific historical bar.",             toolIBarParams()));
      add(new Tool("iHigh",                "Get the high price of a specific historical bar.",                toolIBarParams()));
      add(new Tool("iLow",                 "Get the low price of a specific historical bar.",                 toolIBarParams()));
      add(new Tool("iOpen",                "Get the open price of a specific historical bar.",                toolIBarParams()));
      add(new Tool("is_order_opened",      "Check whether any pending orders are open.",                       toolIsOrderOpenedParams()));
      add(new Tool("is_position_opened",   "Check whether any positions are currently open.",                  toolIsPositionOpenedParams()));
      add(new Tool("order_delete",         "Delete a pending order by ticket number.",                         toolOrderDeleteParams()));
      add(new Tool("order_send",           "Send an order using absolute entry, stop loss, and take profit.", toolOrderSendParams()));
      add(new Tool("order_send_pips",      "Send an order using stop loss and take profit distances in pips.", toolOrderSendPipsParams()));
      add(new Tool("order_modify",         "Modify the price, stop loss, and take profit of a pending order.", toolOrderModifyParams()));
      add(new Tool("position_close",       "Close an open position by ticket number.",                         toolPositionCloseParams()));
      add(new Tool("position_modify",      "Modify the stop loss and take profit of an open position.",        toolPositionModifyParams()));
      add(new Tool("select_symbol",        "Enable or disable a symbol in the Market Watch.",                  toolSelectSymbolParams()));
   }

   // get_tool_list equivalent — serializes all tools into a JSON array string
   string toolList(bool isAnthropic = true)
   {
      CJAVal arr;
      arr.m_type = jtARRAY;
      for (int i = 0; i < count; i++)
      {
         CJAVal t;
         if (isAnthropic) tools[i].json_anthropic(t);
         else             tools[i].json_openai(t);
         arr.Add(t);
      }
      return arr.Serialize();
   }

   // execute_tool equivalent — dispatches by name, returns serialized result
   string execute(string name, CJAVal &json)
   {
      if (name == "get_account_info")      return getAccountInfo();
      if (name == "get_history_position")  return getHistoryPosition((ulong)json["ticket"].ToInt());
      if (name == "get_history_positions") return getHistoryPositions(json["symbol"].ToStr(), json["magic"].ToInt(), (datetime)StringToTime(json["from_date"].ToStr()), (datetime)StringToTime(json["to_date"].ToStr()));
      if (name == "get_order")             return getOrder((ulong)json["ticket"].ToInt());
      if (name == "get_orders")            return getOrders(json["symbol"].ToStr());
      if (name == "get_pip_value")         return DoubleToString(getPipValue(json["symbol"].ToStr()));
      if (name == "get_position")          return getPosition((ulong)json["ticket"].ToInt());
      if (name == "get_positions")         return getPositions(json["symbol"].ToStr());
      if (name == "get_recent_bars")       return getRecentBars(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["number_of_bars"].ToInt(), (int)json["shift"].ToInt());
      if (name == "get_risk")              return DoubleToString(getRisk(json["symbol"].ToStr(), json["percent_risk"].ToDbl(), json["stop_loss_pips"].ToDbl()));
      if (name == "get_screenshot")        return getScreenshot(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()));
      if (name == "get_symbol_info")       return getSymbolInfo(json["symbol"].ToStr());
      if (name == "iClose")                return DoubleToString(iClose(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
      if (name == "iDate")                 return TimeToString(iTime(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
      if (name == "iHigh")                 return DoubleToString(iHigh(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
      if (name == "iLow")                  return DoubleToString(iLow(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
      if (name == "iOpen")                 return DoubleToString(iOpen(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
      if (name == "is_order_opened")       return BOOL_TO_STRING(isOrderOpened(json["symbol"].ToStr(), json["magic"].ToInt()));
      if (name == "is_position_opened")    return BOOL_TO_STRING(isPositionOpened(json["symbol"].ToStr(), json["magic"].ToInt()));
      if (name == "order_delete")          return BOOL_TO_STRING(orderDelete((ulong)json["ticket"].ToInt()));
      if (name == "order_send")            return BOOL_TO_STRING(orderSend(json["symbol"].ToStr(), StringToOrderType(json["type"].ToStr()), json["volume"].ToDbl(), json["price"].ToDbl(), (int)json["slippage"].ToInt(), json["stoploss"].ToDbl(), json["takeprofit"].ToDbl(), json["comment"].ToStr(), json["magic"].ToInt()));
      if (name == "order_send_pips")       return BOOL_TO_STRING(orderSendPips(json["symbol"].ToStr(), StringToOrderType(json["type"].ToStr()), json["volume"].ToDbl(), json["price"].ToDbl(), (int)json["slippage"].ToInt(), json["stoploss_pips"].ToDbl(), json["takeprofit_pips"].ToDbl(), json["comment"].ToStr(), json["magic"].ToInt()));
      if (name == "order_modify")          return BOOL_TO_STRING(orderModify((ulong)json["ticket"].ToInt(), json["price"].ToDbl(), json["stop_loss"].ToDbl(), json["take_profit"].ToDbl()));
      if (name == "position_close")        return BOOL_TO_STRING(positionClose((ulong)json["ticket"].ToInt()));
      if (name == "position_modify")       return BOOL_TO_STRING(positionModify(json["symbol"].ToStr(), (ulong)json["ticket"].ToInt(), json["stop_loss"].ToDbl(), json["take_profit"].ToDbl()));
      if (name == "select_symbol")         return BOOL_TO_STRING(selectSymbol(json["symbol"].ToStr(), (bool)json["enable"].ToInt()));

      return "{\"error\":\"unknown tool: " + name + "\"}";
   }

   ~Dispatch()
   {
      for (int i = 0; i < count; i++)
         if (CheckPointer(tools[i]) == POINTER_DYNAMIC) delete tools[i];
      ArrayResize(tools, 0);
   }

private:
   void add(Tool *t)
   {
      ArrayResize(tools, count + 1);
      tools[count++] = t;
   }
};
//+------------------------------------------------------------------+
