//+------------------------------------------------------------------+
//|                                                          mt5.mqh |
//|                                          Copyright 2026,JBlanked |
//|                                        https://www.jblanked.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026,JBlanked"
#property link      "https://www.jblanked.com/"
#property strict

#include "JSON.mqh"

#ifdef __MQL5__
#include <Trade\Trade.mqh>
static CTrade trade;
static CPositionInfo posi;
#else
#define POSITION_TYPE_BUY  0 // OP_BUY
#define POSITION_TYPE_SELL 1 // OP_SELL
#endif

#define CONTAINS(symbol, match) (StringFind(symbol, match) != -1)
#define DIVISION(numerator, denominator) (denominator == 0 ? 0 : numerator / denominator)

#define SCREENSHOT_FILENAME "metatrader-ai"
#define SCREENSHOT_HEIGHT 800
#define SCREENSHOT_WIDTH 600

// forwards (in mql4 is shows import warning)
#ifdef __MQL5__
string getAccountInfo();
string getHistoryPosition(ulong ticket);
string getHistoryPositions(string symbol = "", long magic = 0, datetime fromDate = 0, datetime toDate = 0);
string getOrder(ulong ticket);
string getOrders(string symbol = "");
double getPipValue(string symbol);
string getPosition(ulong ticket);
string getPositions(string symbol = "");
string getRecentBars(string symbol, ENUM_TIMEFRAMES timeframe, int numberOfBars, int shift = 0);
double getRisk(string symbol, double percentRisk, double stopLossPips);
string getScreenshot(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
string getSymbolInfo(string symbol);
bool isOrderOpened(string symbol = "", long magic = 0);
bool isPositionOpened(string symbol = "", long magic = 0);
bool orderDelete(ulong ticket);
bool orderSend(string symbol, ENUM_ORDER_TYPE type, double volume, double price, int slippage, double stoploss, double takeprofit, string comment = "", long magic = 0);
bool orderSendPips(string symbol, ENUM_ORDER_TYPE type, double volume, double price, int slippage, double stoplossPips, double takeprofitPips, string comment = "", long magic = 0);
bool orderModify(ulong ticket, double price, double stopLoss, double takeProfit);
bool positionClose(ulong ticket);
bool positionModify(string symbol, ulong ticket, double stopLoss, double takeProfit);
bool selectSymbol(string symbol, bool enable = true);
#endif
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get account information as a dictionary                          |
//+------------------------------------------------------------------+
string getAccountInfo(void)
{
   CJAVal result;
   result["number"]       = AccountInfoInteger(ACCOUNT_LOGIN);
   result["name"]         = AccountInfoString(ACCOUNT_NAME);
   result["balance"]      = AccountInfoDouble(ACCOUNT_BALANCE);
   result["equity"]       = AccountInfoDouble(ACCOUNT_EQUITY);
   result["margin"]       = AccountInfoDouble(ACCOUNT_MARGIN);
   result["free_margin"]  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   result["margin_level"] = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   result["currency"]     = AccountInfoString(ACCOUNT_CURRENCY);
   result["company"]      = AccountInfoString(ACCOUNT_COMPANY);
   result["profit"]       = AccountInfoDouble(ACCOUNT_PROFIT);
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Get all deals related to the ticket number of a closed position  |
//+------------------------------------------------------------------+
string getHistoryPosition(ulong ticket)
{
   CJAVal result;
#ifdef __MQL5__
   if(HistoryDealSelect(ticket))
   {
      result["ticket"]     = (long)ticket;
      result["order"]      = (long)HistoryDealGetInteger(ticket, DEAL_ORDER);
      result["time"]       = TimeToString((datetime)HistoryDealGetInteger(ticket, DEAL_TIME));
      result["type"]       = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);
      result["entry"]      = (int)HistoryDealGetInteger(ticket, DEAL_ENTRY);
      result["magic"]      = HistoryDealGetInteger(ticket, DEAL_MAGIC);
      result["volume"]     = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      result["price"]      = HistoryDealGetDouble(ticket, DEAL_PRICE);
      result["commission"] = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      result["swap"]       = HistoryDealGetDouble(ticket, DEAL_SWAP);
      result["profit"]     = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      result["fee"]        = HistoryDealGetDouble(ticket, DEAL_FEE);
      result["symbol"]     = HistoryDealGetString(ticket, DEAL_SYMBOL);
      result["comment"]    = HistoryDealGetString(ticket, DEAL_COMMENT);
   }
   else
   {
      PrintFormat("HistoryDealSelect(%I64u) failed. Error %d", ticket, GetLastError());
   }
#else
   if(OrderSelect((int)ticket, SELECT_BY_TICKET))
   {
      result["ticket"]     = OrderTicket();
      result["time"]       = TimeToString((datetime)OrderOpenTime());
      result["type"]       = OrderType();
      result["magic"]      = OrderMagicNumber();
      result["volume"]     = OrderLots();
      result["price"]      = OrderOpenPrice();
      result["commission"] = OrderCommission();
      result["swap"]       = OrderSwap();
      result["profit"]     = OrderProfit();
      result["symbol"]     = OrderSymbol();
      result["comment"]    = OrderComment();
   }
#endif
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Get historical positions, optionally filtered                    |
//+------------------------------------------------------------------+
string getHistoryPositions(string symbol = "", long magic = 0, datetime fromDate = 0, datetime toDate = 0)
{
   CJAVal result;
   int count = 0;
   datetime _fromDate = fromDate == 0 ? (datetime)0 : fromDate;
   datetime _toDate   = toDate == 0 ? TimeCurrent() : toDate;
#ifdef __MQL5__
   if(HistorySelect(_fromDate, _toDate))
   {
      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong dealTicket = HistoryDealGetTicket(i);
         string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
         long   dealMagic  = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
         if(symbol != "" && dealSymbol != symbol) continue;
         if(magic  != 0  && dealMagic  != magic)  continue;
         result["positions"][count]["ticket"]      = (long)dealTicket;
         result["positions"][count]["time"]        = TimeToString((datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME));
         result["positions"][count]["type"]        = (int)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
         result["positions"][count]["entry"]       = (int)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         result["positions"][count]["magic_number"] = dealMagic;
         result["positions"][count]["lot_size"]    = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
         result["positions"][count]["price"]       = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         result["positions"][count]["commission"]  = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         result["positions"][count]["swap"]        = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
         result["positions"][count]["profit"]      = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         result["positions"][count]["fee"]         = HistoryDealGetDouble(dealTicket, DEAL_FEE);
         result["positions"][count]["symbol"]      = dealSymbol;
         result["positions"][count]["comment"]     = HistoryDealGetString(dealTicket, DEAL_COMMENT);
         count++;
      }
   }
#else
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
      {
         if(symbol != "" && OrderSymbol() != symbol) continue;
         if(magic  != 0  && OrderMagicNumber() != (int)magic) continue;
         datetime orderTime = (datetime)OrderOpenTime();
         if(orderTime < _fromDate || orderTime > _toDate) continue;
         result["positions"][count]["ticket"]       = OrderTicket();
         result["positions"][count]["time"]         = TimeToString(orderTime);
         result["positions"][count]["type"]         = OrderType();
         result["positions"][count]["magic_number"] = OrderMagicNumber();
         result["positions"][count]["lot_size"]     = OrderLots();
         result["positions"][count]["price"]        = OrderOpenPrice();
         result["positions"][count]["commission"]   = OrderCommission();
         result["positions"][count]["swap"]         = OrderSwap();
         result["positions"][count]["profit"]       = OrderProfit();
         result["positions"][count]["symbol"]       = OrderSymbol();
         result["positions"][count]["comment"]      = OrderComment();
         count++;
      }
   }
#endif
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Get a specific pending order by ticket number                    |
//+------------------------------------------------------------------+
string getOrder(ulong ticket)
{
   CJAVal result;
#ifdef __MQL5__
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      const ulong orderTicket = OrderGetTicket(i);
      if(OrderSelect(orderTicket) && orderTicket == ticket)
      {
         result["magic"]         = OrderGetInteger(ORDER_MAGIC);
         result["symbol"]        = OrderGetString(ORDER_SYMBOL);
         result["type"]          = OrderGetInteger(ORDER_TYPE);
         result["comment"]       = OrderGetString(ORDER_COMMENT);
         result["stop_loss"]     = OrderGetDouble(ORDER_SL);
         result["take_profit"]   = OrderGetDouble(ORDER_TP);
         result["lot_size"]      = OrderGetDouble(ORDER_VOLUME_CURRENT);
         result["price_open"]    = OrderGetDouble(ORDER_PRICE_OPEN);
         result["price_current"] = OrderGetDouble(ORDER_PRICE_CURRENT);
         result["time_open"]     = TimeToString((datetime)OrderGetInteger(ORDER_TIME_SETUP));
         result["time_expire"]   = TimeToString((datetime)OrderGetInteger(ORDER_TIME_EXPIRATION));
         break;
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         if((OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP || OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT) &&
               OrderTicket() == ticket)
         {
            result["magic"]         = OrderMagicNumber();
            result["symbol"]        = OrderSymbol();
            result["type"]          = OrderType();
            result["comment"]       = OrderComment();
            result["stop_loss"]     = OrderStopLoss();
            result["take_profit"]   = OrderTakeProfit();
            result["lot_size"]      = OrderLots();
            result["price_open"]    = OrderOpenPrice();
            result["price_current"] = OrderClosePrice();
            result["time_open"]     = TimeToString((datetime)OrderOpenTime());
            result["time_expire"]   = TimeToString((datetime)OrderExpiration());
            break;
         }
      }
   }
#endif
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Get all pending orders, optionally filtered by symbol            |
//+------------------------------------------------------------------+
string getOrders(string symbol = "")
{
   CJAVal result;
   int count = 0;
#ifdef __MQL5__
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      string orderSymbol = OrderGetString(ORDER_SYMBOL);
      if(symbol != "" && orderSymbol != symbol) continue;
      result["orders"][count]["ticket"]          = (long)ticket;
      result["orders"][count]["magic_number"]    = OrderGetInteger(ORDER_MAGIC);
      result["orders"][count]["symbol"]          = orderSymbol;
      result["orders"][count]["type"]            = (int)OrderGetInteger(ORDER_TYPE);
      result["orders"][count]["comment"]         = OrderGetString(ORDER_COMMENT);
      result["orders"][count]["stop_loss"]       = OrderGetDouble(ORDER_SL);
      result["orders"][count]["take_profit"]     = OrderGetDouble(ORDER_TP);
      result["orders"][count]["lot_size"]        = OrderGetDouble(ORDER_VOLUME_CURRENT);
      result["orders"][count]["open_price"]      = OrderGetDouble(ORDER_PRICE_OPEN);
      result["orders"][count]["current_price"]   = OrderGetDouble(ORDER_PRICE_CURRENT);
      result["orders"][count]["time_setup"]      = TimeToString((datetime)OrderGetInteger(ORDER_TIME_SETUP));
      result["orders"][count]["time_expiration"] = TimeToString((datetime)OrderGetInteger(ORDER_TIME_EXPIRATION));
      count++;
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderType() != OP_BUYSTOP && OrderType() != OP_SELLSTOP &&
            OrderType() != OP_BUYLIMIT && OrderType() != OP_SELLLIMIT) continue;
      if(symbol != "" && OrderSymbol() != symbol) continue;
      result["orders"][count]["ticket"]          = OrderTicket();
      result["orders"][count]["magic_number"]    = OrderMagicNumber();
      result["orders"][count]["symbol"]          = OrderSymbol();
      result["orders"][count]["type"]            = OrderType();
      result["orders"][count]["comment"]         = OrderComment();
      result["orders"][count]["stop_loss"]       = OrderStopLoss();
      result["orders"][count]["take_profit"]     = OrderTakeProfit();
      result["orders"][count]["lot_size"]        = OrderLots();
      result["orders"][count]["open_price"]      = OrderOpenPrice();
      result["orders"][count]["current_price"]   = OrderClosePrice();
      result["orders"][count]["time_setup"]      = TimeToString((datetime)OrderOpenTime());
      result["orders"][count]["time_expiration"] = TimeToString((datetime)OrderExpiration());
      count++;
   }
#endif
   return result.Serialize();
}
//+------------------------------------------------------------------+
//| Get the pip value for a specific symbol                          |
//+------------------------------------------------------------------+
double getPipValue(string symbol)
{
   const double _pips = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;
   const double digits = int(SymbolInfoInteger(symbol, SYMBOL_DIGITS));

   if(symbol == "" || digits == 0)
   {
      return _pips;
   }

   if(digits >= 4) return 0.0001;
   if(digits == 3) return 0.01;

   if(CONTAINS(symbol, "XAU"))
   {
      return 0.10; // gold
   }

   if(CONTAINS(symbol, "US30") || CONTAINS(symbol, "NAS100") || CONTAINS(symbol, "SPX500") || CONTAINS(symbol, "UK100") || CONTAINS(symbol, "JPY225") || CONTAINS(symbol, "FRA40"))
   {
      return 1.0; // indices
   }

   if(CONTAINS(symbol, "ETHUSD") || CONTAINS(symbol, "BTCUSD"))
   {
      return 1.0; // crypto
   }

   return _pips;
}

//+------------------------------------------------------------------+
//| Get a specific open position by ticket number                    |
//+------------------------------------------------------------------+
string getPosition(ulong ticket)
{
   CJAVal result;
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--) //count backwards
   {
      if(posi.SelectByIndex(i) && posi.Ticket() == ticket) // select the order
      {
         result["magic"]         = posi.Magic();
         result["symbol"]        = posi.Symbol();
         result["type"]          = (int)posi.PositionType();
         result["comment"]       = posi.Comment();
         result["stop_loss"]     = posi.StopLoss();
         result["take_profit"]   = posi.TakeProfit();
         result["lot_size"]      = posi.Volume();
         result["price_open"]    = posi.PriceOpen();
         result["price_current"] = posi.PriceCurrent();
         result["time_open"]     = TimeToString(posi.Time());
         break;
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         if(OrderTicket() == ticket && (OrderType() == OP_BUY || OrderType() == OP_SELL))
         {
            result["magic"]         = OrderMagicNumber();
            result["symbol"]        = OrderSymbol();
            result["type"]          = OrderType();
            result["comment"]       = OrderComment();
            result["stop_loss"]     = OrderStopLoss();
            result["take_profit"]   = OrderTakeProfit();
            result["lot_size"]      = OrderLots();
            result["price_open"]    = OrderOpenPrice();
            result["price_current"] = OrderClosePrice();
            result["time_open"]     = TimeToString((datetime)OrderOpenTime());
            break;
         }
      }
   }
#endif
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Get all open positions, optionally filtered by symbol            |
//+------------------------------------------------------------------+
string getPositions(string symbol = "")
{
   CJAVal result;
   int count = 0;
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!posi.SelectByIndex(i)) continue;
      if(symbol != "" && posi.Symbol() != symbol) continue;
      result["positions"][count]["ticket"]        = (long)posi.Ticket();
      result["positions"][count]["magic_number"]  = posi.Magic();
      result["positions"][count]["symbol"]        = posi.Symbol();
      result["positions"][count]["type"]          = (int)posi.PositionType();
      result["positions"][count]["comment"]       = posi.Comment();
      result["positions"][count]["stop_loss"]     = posi.StopLoss();
      result["positions"][count]["take_profit"]   = posi.TakeProfit();
      result["positions"][count]["lot_size"]      = posi.Volume();
      result["positions"][count]["open_price"]    = posi.PriceOpen();
      result["positions"][count]["current_price"] = posi.PriceCurrent();
      result["positions"][count]["profit"]        = posi.Profit();
      result["positions"][count]["swap"]          = posi.Swap();
      result["positions"][count]["time_open"]     = TimeToString(posi.Time());
      count++;
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS)) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      if(symbol != "" && OrderSymbol() != symbol) continue;
      result["positions"][count]["ticket"]        = OrderTicket();
      result["positions"][count]["magic_number"]  = OrderMagicNumber();
      result["positions"][count]["symbol"]        = OrderSymbol();
      result["positions"][count]["type"]          = OrderType();
      result["positions"][count]["comment"]       = OrderComment();
      result["positions"][count]["stop_loss"]     = OrderStopLoss();
      result["positions"][count]["take_profit"]   = OrderTakeProfit();
      result["positions"][count]["lot_size"]      = OrderLots();
      result["positions"][count]["open_price"]    = OrderOpenPrice();
      result["positions"][count]["current_price"] = OrderClosePrice();
      result["positions"][count]["profit"]        = OrderProfit();
      result["positions"][count]["swap"]          = OrderSwap();
      result["positions"][count]["time_open"]     = TimeToString((datetime)OrderOpenTime());
      count++;
   }
#endif
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Get recent bars for a specific symbol, timeframe, and shift      |
//+------------------------------------------------------------------+
string getRecentBars(string symbol, ENUM_TIMEFRAMES timeframe, int numberOfBars, int shift = 0)
{
   CJAVal result;
   MqlRates rates[];
   if(CopyRates(symbol, timeframe, shift, numberOfBars, rates) == -1)
   {
      Print("Failed to fetch rates for " + symbol);
      return "";
   }
   for(int i = 0; i < ArraySize(rates); i++)
   {
      result["bars"][i]["close"]       = rates[i].close;
      result["bars"][i]["open"]        = rates[i].open;
      result["bars"][i]["high"]        = rates[i].high;
      result["bars"][i]["low"]         = rates[i].low;
      result["bars"][i]["spread"]      = rates[i].spread;
      result["bars"][i]["tick_volume"] = rates[i].tick_volume;
      result["bars"][i]["real_volume"] = rates[i].real_volume;
   }
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Get the lot size based on the percentage risk + stop loss in pips|
//+------------------------------------------------------------------+
double getRisk(string symbol, double percentRisk, double stopLossPips)
{
   const double decimalRisk = percentRisk / 100;   // turn user input into risk %
   const double accountRisk = AccountInfoDouble(ACCOUNT_EQUITY) * decimalRisk; // define total risk
   const double pipValue    = getPipValue(symbol);
   const double maxLotSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE); // contract size

   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   if(CONTAINS(symbol, ".mini") || AccountInfoString(ACCOUNT_COMPANY) == "FTMO S.R.O.")
   {
      tickValue *= 100;
   }

   const double maxLossInQuoteCurr = accountRisk / tickValue;
   const double quoteDivision      = DIVISION(maxLossInQuoteCurr, (stopLossPips * pipValue));
   const double startingRisk       = DIVISION(quoteDivision, maxLotSize);
   const double riskCurrent        = startingRisk * tickValue;

   return CONTAINS(symbol, "US30") || CONTAINS(symbol, "NAS100") ||
          CONTAINS(symbol, "SPX500") || CONTAINS(symbol, "JPY225") ||
          CONTAINS(symbol, "UK100") || CONTAINS(symbol, "FRA40") ||
          CONTAINS(symbol, "BTCUSD") || CONTAINS(symbol, "ETHUSD") ||
          CONTAINS(symbol, "LTCUSD") || CONTAINS(symbol, "BNBUSD")
          ?
          NormalizeDouble((riskCurrent * tickValue), 2)
          :
          CONTAINS(symbol, "USDJPY") || CONTAINS(symbol, "CADJPY") ||
          CONTAINS(symbol, "EURJPY") || CONTAINS(symbol, "AUDJPY") ||
          CONTAINS(symbol, "NZDJPY") || CONTAINS(symbol, "CHFJPY") ||
          CONTAINS(symbol, "GBPJPY")
          ?
          NormalizeDouble(((riskCurrent * 100) / tickValue), 2)
          :
          NormalizeDouble((riskCurrent), 2);

}

//+------------------------------------------------------------------+
//| Screenshot a chart, optionally switch to symbol/timeframe        |
//+------------------------------------------------------------------+
string getScreenshot(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT)
{
   ResetLastError();
// switch chart if sym/tf is set but we're not on there
   if((symbol != "" && ChartSymbol() != symbol) || (timeframe != PERIOD_CURRENT && ChartPeriod() != timeframe))
   {
      if(!ChartSetSymbolPeriod(ChartID(), symbol, timeframe))
      {
         PrintFormat("getScreenshot(%s,%d) failed to set symbol/period. Error %d", symbol, timeframe, GetLastError());
         return "";
      }
   }
// take screenshot
   const string currencyPair = symbol != "" ? symbol : _Symbol;
   if(!ChartScreenShot(ChartID(), SCREENSHOT_FILENAME + " " + currencyPair + ".png", SCREENSHOT_HEIGHT, SCREENSHOT_WIDTH))
   {
      PrintFormat("getScreenshot(%s,%d) failed to screenshot. Error %d", currencyPair, timeframe, GetLastError());
      return "";
   }
// load screenshot into array
   int res;
   char file[];
   if (SCREENSHOT_FILENAME + " " + currencyPair + ".png" != NULL && SCREENSHOT_FILENAME + " " + currencyPair + ".png" != "")
   {
      res = FileOpen(SCREENSHOT_FILENAME + " " + currencyPair + ".png", FILE_READ | FILE_BIN);
      if (res < 0)
      {
         PrintFormat("getScreenshot(%s,%d) failed to open screenshot file. Error %d", currencyPair, timeframe, GetLastError());
         return "";
      }

      if (FileReadArray(res, file) != FileSize(res))
      {
         FileClose(res);
         PrintFormat("getScreenshot(%s,%d) failed to read screenshot file. Error %d", currencyPair, timeframe, GetLastError());
         return "";
      }
      FileClose(res);
   }
   return CharArrayToString(file);
}

//+------------------------------------------------------------------+
//| Get symbol information for a specific symbol                     |
//+------------------------------------------------------------------+
string getSymbolInfo(string symbol)
{
   CJAVal result;
   result["tick_value"]   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   result["spread"]       = SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID);
   result["bid"]          = SymbolInfoDouble(symbol, SYMBOL_BID);
   result["ask"]          = SymbolInfoDouble(symbol, SYMBOL_ASK);
   result["point"]        = SymbolInfoDouble(symbol, SYMBOL_POINT);
   result["front"]        = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   result["end"]          = SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   result["digits"]       = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   result["max_lot_size"] = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   return result.Serialize();
}

//+------------------------------------------------------------------+
//| Check if there are any pending order opened                      |
//+------------------------------------------------------------------+
bool isOrderOpened(string symbol = "", long magic = 0)
{
#ifdef __MQL5__
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(OrderGetTicket(i))) // select the order
      {
         bool isMagic  = magic == 0 || OrderGetInteger(ORDER_MAGIC) == magic;
         bool isSymbol = symbol == "" || OrderGetString(ORDER_SYMBOL) == symbol;
         if(isMagic && isSymbol) return true;
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         if((OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP || OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT) &&
               OrderMagicNumber() == (int)magic && OrderSymbol() == symbol)
         {
            return true;
         }
      }
   }
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Check if there are any open positions                            |
//+------------------------------------------------------------------+
bool isPositionOpened(string symbol = "", long magic = 0)
{
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--) //count backwards
   {
      if(posi.SelectByIndex(i)) // select the order
      {
         bool isSymbol = symbol == "" || posi.Symbol() == symbol;
         bool isMagic  = magic == 0 || posi.Magic() == magic;
         if(isSymbol && isMagic) return true;
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         const int orderType = OrderType();
         if(orderType != OP_BUY && orderType != OP_SELL) continue;
         bool isSymbol = symbol == "" || OrderSymbol() == symbol;
         bool isMagic  = magic == 0 || OrderMagicNumber() == (int)magic;
         if(isSymbol && isMagic) return true;
      }
   }
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Delete a pending order by ticket number                          |
//+------------------------------------------------------------------+
bool orderDelete(ulong ticket)
{
#ifdef __MQL5__
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      ulong orderTicket = OrderGetTicket(i);
      if(OrderSelect(orderTicket)) // select the order
      {
         return trade.OrderDelete(ticket);
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         if(OrderTicket() == (int)ticket && OrderType() != OP_BUY && OrderType() != OP_SELL)
         {
            return OrderDelete(OrderTicket());
         }
      }
   }
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Send an order: absolute entry, stop-loss, and take-profit prices |
//+------------------------------------------------------------------+
bool orderSend(string symbol, ENUM_ORDER_TYPE type, double volume, double price, int slippage, double stoploss, double takeprofit, string comment = "", long magic = 0)
{
   double _price = price;
#ifdef __MQL5__
   trade.SetExpertMagicNumber(magic);
   if(price == 0)
   {
      _price = type == ORDER_TYPE_BUY ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   }
   switch(type)
   {
   case ORDER_TYPE_BUY:
   case ORDER_TYPE_SELL:
      return trade.PositionOpen(symbol, type, volume, _price, stoploss, takeprofit, comment);
   default:
      return trade.OrderOpen(symbol, type, volume, price, price, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
   }
#else
   if(price == 0)
   {
      _price = type == OP_BUY ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   }
   return OrderSend(symbol, type, volume, _price, slippage, stoploss, takeprofit, comment, (int)magic, 0) > 0;
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Send an order: entry, stop-loss, and take-profit  in pips        |
//+------------------------------------------------------------------+
bool orderSendPips(string symbol, ENUM_ORDER_TYPE type, double volume, double price, int slippage, double stoplossPips, double takeprofitPips, string comment = "", long magic = 0)
{
   const double pipValue = getPipValue(symbol);
   double _price = price;
   double stopLoss = 0.0;
   double takeProfit = 0.0;
#ifdef __MQL5__
   if(price == 0)
   {
      _price = type == ORDER_TYPE_BUY ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   }
   trade.SetExpertMagicNumber(magic);
   switch(type)
   {
   case ORDER_TYPE_BUY_LIMIT:
   case ORDER_TYPE_BUY_STOP:
   case ORDER_TYPE_BUY_STOP_LIMIT:
      stopLoss = _price - stoplossPips * pipValue;
      takeProfit = _price + takeprofitPips * pipValue;
      return trade.OrderOpen(symbol, type, volume, _price, _price, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment);
   case ORDER_TYPE_BUY:
      stopLoss = _price - stoplossPips * pipValue;
      takeProfit = _price + takeprofitPips * pipValue;
      return trade.PositionOpen(symbol, type, volume, _price, stopLoss, takeProfit, comment);
   case ORDER_TYPE_SELL_LIMIT:
   case ORDER_TYPE_SELL_STOP:
   case ORDER_TYPE_SELL_STOP_LIMIT:
      stopLoss = _price + stoplossPips * pipValue;
      takeProfit = _price - takeprofitPips * pipValue;
      return trade.OrderOpen(symbol, type, volume, _price, _price, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment);
   case ORDER_TYPE_SELL:
      stopLoss = _price + stoplossPips * pipValue;
      takeProfit = _price - takeprofitPips * pipValue;
      return trade.PositionOpen(symbol, type, volume, _price, stopLoss, takeProfit, comment);
   default:
      break;
   }
#else
   if(price == 0)
   {
      _price = type == OP_BUY ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   }
   switch(type)
   {
   case OP_BUYLIMIT:
   case OP_BUYSTOP:
   case OP_BUY:
      stopLoss = _price - stoplossPips * pipValue;
      takeProfit = _price + takeprofitPips * pipValue;
      break;
   case OP_SELLLIMIT:
   case OP_SELLSTOP:
   case OP_SELL:
      stopLoss = _price + stoplossPips * pipValue;
      takeProfit = _price - takeprofitPips * pipValue;
      break;
   default:
      break;
   };
   return OrderSend(symbol, type, volume, _price, slippage, stopLoss, takeProfit, comment, (int)magic, 0) > 0;
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Modify an existing pending order                                 |
//+------------------------------------------------------------------+
bool orderModify(ulong ticket, double price, double stopLoss, double takeProfit)
{
#ifdef __MQL5__
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      ulong orderTicket = OrderGetTicket(i);
      if(OrderSelect(orderTicket)) // select the order
      {
         return trade.OrderModify(
                   ticket,
                   price,
                   stopLoss,
                   takeProfit,
                   (ENUM_ORDER_TYPE_TIME)OrderGetInteger(ORDER_TYPE_TIME),
                   OrderGetInteger(ORDER_TIME_EXPIRATION)
                );
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         if(OrderTicket() == (int)ticket && OrderType() != OP_BUY && OrderType() != OP_SELL)
         {
            return OrderModify((int)ticket, price, stopLoss, takeProfit, OrderExpiration()) > 0;
         }
      }
   }
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Close an open position by ticket number                          |
//+------------------------------------------------------------------+
bool positionClose(ulong ticket)
{
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--) //count backwards
   {
      if(posi.SelectByIndex(i)) // select the order
      {
         if(posi.Ticket() == ticket)
         {
            return trade.PositionClose(ticket);
         }
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         if(OrderTicket() == (int)ticket && (OrderType() == OP_BUY || OrderType() == OP_SELL))
         {
            return OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 10) > 0 ? true : false;
         }
      }
   }
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Modify an existing open position                                 |
//+------------------------------------------------------------------+
bool positionModify(string symbol, ulong ticket, double stopLoss, double takeProfit)
{
#ifdef __MQL5__
   return trade.PositionModify(ticket, stopLoss, takeProfit);
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--) //count backwards
   {
      if(OrderSelect(i, SELECT_BY_POS)) // select the order
      {
         if(OrderTicket() == (int)ticket && (OrderType() == OP_BUY || OrderType() == OP_SELL))
         {
            return OrderModify((int)ticket, OrderOpenPrice(), stopLoss, takeProfit, OrderExpiration()) > 0;
         }
      }
   }
#endif
   return false;
}

//+------------------------------------------------------------------+
//| Ensure the specified symbol is enabled/disabled in Market Watch  |
//+------------------------------------------------------------------+
bool selectSymbol(string symbol, bool enable = true)
{
   return SymbolSelect(symbol, enable);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
