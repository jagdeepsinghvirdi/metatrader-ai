//+------------------------------------------------------------------+
//|                                                        tools.mqh |
//|                                      Copyright 2026,JBlanked LLC |
//|                                         https://www.jblanked.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked LLC"
#property link      "https://www.jblanked.com"
#property strict
#include "constants.mqh"
#include "mt5.mqh"
#include "compile.mqh"
#include "tool.mqh"

#define BOOL_TO_STRING(value) ((value) ? "true" : "false")

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES StringToTimeframe(string tf)
{
   if (tf == "PERIOD_M1")  return PERIOD_M1;
   if (tf == "PERIOD_M2")  return PERIOD_M2;
   if (tf == "PERIOD_M3")  return PERIOD_M3;
   if (tf == "PERIOD_M4")  return PERIOD_M4;
   if (tf == "PERIOD_M5")  return PERIOD_M5;
   if (tf == "PERIOD_M6")  return PERIOD_M6;
   if (tf == "PERIOD_M10") return PERIOD_M10;
   if (tf == "PERIOD_M15") return PERIOD_M15;
   if (tf == "PERIOD_M20") return PERIOD_M20;
   if (tf == "PERIOD_M30") return PERIOD_M30;
   if (tf == "PERIOD_H1")  return PERIOD_H1;
   if (tf == "PERIOD_H2")  return PERIOD_H2;
   if (tf == "PERIOD_H4")  return PERIOD_H4;
   if (tf == "PERIOD_H8")  return PERIOD_H8;
   if (tf == "PERIOD_H12") return PERIOD_H12;
   if (tf == "PERIOD_D1")  return PERIOD_D1;
   if (tf == "PERIOD_W1")  return PERIOD_W1;
   if (tf == "PERIOD_MN1") return PERIOD_MN1;
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
class ToolGetAccountInfo : public Tool
{
public:
   ToolGetAccountInfo() : Tool("get_account_info", "Get account information such as balance, equity, margin, etc.", NULL) {}
   virtual string execute(CJAVal &json) override
   {
      return getAccountInfo();
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetBars : public Tool
{
public:
   ToolGetBars() : Tool("get_bars", "Get rates for a specific symbol, timeframe, and range.", toolGetBarsParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getBars(
                json["symbol"].ToStr(),
                StringToTimeframe(json["timeframe"].ToStr()),
                (datetime)StringToTime(json["from_date"].ToStr()),
                (datetime)StringToTime(json["to_date"].ToStr())
             );
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetHistoryPosition : public Tool
{
public:
   ToolGetHistoryPosition() : Tool("get_history_position", "Get all deals related to the ticket number of a closed position.", toolHistoryPositionParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getHistoryPosition((ulong)json["ticket"].ToInt());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetHistoryPositions : public Tool
{
public:
   ToolGetHistoryPositions() : Tool("get_history_positions", "Get historical positions, optionally filtered.", toolHistoryPositionsParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getHistoryPositions(
                json["symbol"].ToStr(),
                json["magic"].ToInt(),
                (datetime)StringToTime(json["from_date"].ToStr()),
                (datetime)StringToTime(json["to_date"].ToStr())
             );
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetOrder : public Tool
{
public:
   ToolGetOrder() : Tool("get_order", "Get a specific pending order by ticket number.", toolGetOrderParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getOrder((ulong)json["ticket"].ToInt());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetOrders : public Tool
{
public:
   ToolGetOrders() : Tool("get_orders", "Get all pending orders, optionally filtered by symbol.", toolGetOrdersParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getOrders(json["symbol"].ToStr());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetPipValue : public Tool
{
public:
   ToolGetPipValue() : Tool("get_pip_value", "Get the pip value for a specific symbol.", toolGetPipValueParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return DoubleToString(getPipValue(json["symbol"].ToStr()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetPosition : public Tool
{
public:
   ToolGetPosition() : Tool("get_position", "Get a specific open position by ticket number.", toolGetPositionParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getPosition((ulong)json["ticket"].ToInt());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetPositions : public Tool
{
public:
   ToolGetPositions() : Tool("get_positions", "Get all open positions, optionally filtered by symbol.", toolGetPositionsParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getPositions(json["symbol"].ToStr());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetRecentBars : public Tool
{
public:
   ToolGetRecentBars() : Tool("get_recent_bars", "Get recent OHLCV bars for a specific symbol and timeframe.", toolGetRecentBarsParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getRecentBars(
                json["symbol"].ToStr(),
                StringToTimeframe(json["timeframe"].ToStr()),
                (int)json["number_of_bars"].ToInt(),
                (int)json["shift"].ToInt()
             );
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetRisk : public Tool
{
public:
   ToolGetRisk() : Tool("get_risk", "Calculate the lot size based on a percentage risk and stop loss in pips.", toolGetRiskParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return DoubleToString(getRisk(json["symbol"].ToStr(), json["percent_risk"].ToDbl(), json["stop_loss_pips"].ToDbl()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetScreenshot : public Tool
{
public:
   ToolGetScreenshot() : Tool("get_screenshot", "Screenshot a chart, optionally switch to symbol/timeframe first.", toolGetScreenshotParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getScreenshot(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolGetSymbolInfo : public Tool
{
public:
   ToolGetSymbolInfo() : Tool("get_symbol_info", "Get symbol information such as bid, ask, spread, etc.", toolGetSymbolInfoParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return getSymbolInfo(json["symbol"].ToStr());
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolIClose : public Tool
{
public:
   ToolIClose() : Tool("iClose", "Get the close price of a specific historical bar.", toolIBarParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return DoubleToString(iClose(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolIDate : public Tool
{
public:
   ToolIDate() : Tool("iDate", "Get the date and time of a specific historical bar.", toolIBarParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return TimeToString(iTime(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolIHigh : public Tool
{
public:
   ToolIHigh() : Tool("iHigh", "Get the high price of a specific historical bar.", toolIBarParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return DoubleToString(iHigh(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolILow : public Tool
{
public:
   ToolILow() : Tool("iLow", "Get the low price of a specific historical bar.", toolIBarParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return DoubleToString(iLow(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolIOpen : public Tool
{
public:
   ToolIOpen() : Tool("iOpen", "Get the open price of a specific historical bar.", toolIBarParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return DoubleToString(iOpen(json["symbol"].ToStr(), StringToTimeframe(json["timeframe"].ToStr()), (int)json["shift"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolIsOrderOpened : public Tool
{
public:
   ToolIsOrderOpened() : Tool("is_order_opened", "Check whether any pending orders are open.", toolIsOrderOpenedParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(isOrderOpened(json["symbol"].ToStr(), json["magic"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolIsPositionOpened : public Tool
{
public:
   ToolIsPositionOpened() : Tool("is_position_opened", "Check whether any positions are currently open.", toolIsPositionOpenedParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(isPositionOpened(json["symbol"].ToStr(), json["magic"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolOrderDelete : public Tool
{
public:
   ToolOrderDelete() : Tool("order_delete", "Delete a pending order by ticket number.", toolOrderDeleteParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(orderDelete((ulong)json["ticket"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolOrderSend : public Tool
{
public:
   ToolOrderSend() : Tool("order_send", "Send an order using absolute entry, stop loss, and take profit.", toolOrderSendParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(orderSend(
                               json["symbol"].ToStr(),
                               StringToOrderType(json["type"].ToStr()),
                               json["volume"].ToDbl(),
                               json["price"].ToDbl(),
                               (int)json["slippage"].ToInt(),
                               json["stoploss"].ToDbl(),
                               json["takeprofit"].ToDbl(),
                               json["comment"].ToStr(),
                               json["magic"].ToInt()
                            ));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolOrderSendPips : public Tool
{
public:
   ToolOrderSendPips() : Tool("order_send_pips", "Send an order using stop loss and take profit distances in pips.", toolOrderSendPipsParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(orderSendPips(
                               json["symbol"].ToStr(),
                               StringToOrderType(json["type"].ToStr()),
                               json["volume"].ToDbl(),
                               json["price"].ToDbl(),
                               (int)json["slippage"].ToInt(),
                               json["stoploss_pips"].ToDbl(),
                               json["takeprofit_pips"].ToDbl(),
                               json["comment"].ToStr(),
                               json["magic"].ToInt()
                            ));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolOrderModify : public Tool
{
public:
   ToolOrderModify() : Tool("order_modify", "Modify the price, stop loss, and take profit of a pending order.", toolOrderModifyParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(orderModify((ulong)json["ticket"].ToInt(), json["price"].ToDbl(), json["stop_loss"].ToDbl(), json["take_profit"].ToDbl()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolPositionClose : public Tool
{
public:
   ToolPositionClose() : Tool("position_close", "Close an open position by ticket number.", toolPositionCloseParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(positionClose((ulong)json["ticket"].ToInt()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolPositionModify : public Tool
{
public:
   ToolPositionModify() : Tool("position_modify", "Modify the stop loss and take profit of an open position.", toolPositionModifyParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(positionModify(json["symbol"].ToStr(), (ulong)json["ticket"].ToInt(), json["stop_loss"].ToDbl(), json["take_profit"].ToDbl()));
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolSelectSymbol : public Tool
{
public:
   ToolSelectSymbol() : Tool("select_symbol", "Enable or disable a symbol in the Market Watch.", toolSelectSymbolParams()) {}
   virtual string execute(CJAVal &json) override
   {
      return BOOL_TO_STRING(selectSymbol(json["symbol"].ToStr(), (bool)json["enable"].ToInt()));
   }
};
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ToolCompileMql5 : public Tool
{
public:
   ToolCompileMql5() : Tool("compile_mql5", "Compile an MQL5 file and return any compilation errors.", toolCompileMql5Params()) {}
   virtual string execute(CJAVal &json) override
   {      
       return compileMql(json["mq5_path"].ToStr());
   }
};