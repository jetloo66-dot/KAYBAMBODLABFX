//+------------------------------------------------------------------+
//|                                                    SMC_Structure_EA.mq5 |
//|   Smart Money Structure EA with configurable SL/TP + alerts       |
//|   Multi-timeframe structure framework + trade execution controls    |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                            |
//+------------------------------------------------------------------+
input group "=== TIMEFRAME SETTINGS ==="
input bool   EnableD1   = true;
input bool   EnableH4   = true;
input bool   EnableH1   = true;
input bool   EnableM30  = true;
input bool   EnableM15  = true;
input bool   EnableM5   = true;
input bool   EnableM1   = true;

input group "=== STRUCTURE SETTINGS ==="
input int    SwingLookback = 3;
input int    StructureBars = 300;
input bool   UseBuyCondition1 = true;
input bool   UseBuyCondition2 = true;
input bool   UseBuyCondition3 = true;
input bool   UseBuyCondition4 = true;
input bool   UseSellCondition1 = true;
input bool   UseSellCondition2 = true;
input bool   UseSellCondition3 = true;
input bool   UseSellCondition4 = true;

input group "=== TRADE SETTINGS ==="
input double LotSize = 0.01;
input bool   UseStopLoss = true;
input bool   UseTakeProfit = true;
input bool   UseFixedStopLoss = true;
input bool   UseFixedTakeProfit = false;
input double StopLossPoints = 10.0;
input double TakeProfitPoints = 30.0;
input bool   UseRiskRewardTP = true;
input double RiskRewardRatio = 3.0;
input double StopLossBufferPoints = 0.0;
input bool   UseTrailingStop = true;
input double TrailingStopPoints = 20.0;
input double TrailingStepPoints = 5.0;
input bool   UseBreakEven = true;
input double BreakEvenPoints = 10.0;
input bool   PartialCloseEnabled = true;
input double PartialClosePercent = 50.0;
input double PartialCloseRR = 1.0;
input int    MaxOpenPositions = 1;

input group "=== TAKE PROFIT LEVELS ==="
input int    NumberOfTakeProfits = 3;
input double TP1_RR = 1.0;
input double TP2_RR = 2.0;
input double TP3_RR = 3.0;
input double TP4_RR = 4.0;
input double TP5_RR = 5.0;

input group "=== HIGH VOLATILITY PAIRS ==="
input bool   UseHighVolatilityAdjustments = true;
input double HighVolStopLossPoints = 100.0;
input double HighVolTakeProfitPoints = 300.0;

input group "=== NEWS FILTER ==="
input bool   AvoidNews = true;
input int    NewsBufferMinutesBefore = 30;
input int    NewsBufferMinutesAfter = 30;

input group "=== ALERTS ==="
input bool   SendTelegramAlerts = false;
input string TelegramBotToken = "";
input string TelegramChatID = "";
input bool   SendPushAlerts = true;
input bool   SendPopupAlerts = true;

input group "=== DASHBOARD ==="
input bool   ShowDashboard = true;
input int    DashboardFontSize = 10;

input int    MagicNumber = 20260922;

//+------------------------------------------------------------------+
//| Enums / structs                                                    |
//+------------------------------------------------------------------+
enum ENUM_TARGET_PERIOD
  {
   TARGET_PERIOD_MIN,
   TARGET_PERIOD_HOUR,
   TARGET_PERIOD_SESSION,
   TARGET_PERIOD_DAILY
  };

struct SMCSetup
  {
   bool     valid;
   bool     isBuy;
   double   ll2;
   double   lh2;
   double   ll1;
   double   chochOrBosPrice;
   double   retracePrice;
   double   zoneLow;
   double   zoneHigh;
   int      ll2Idx;
   int      lh2Idx;
   int      ll1Idx;
   int      chochBosIdx;
   int      retraceIdx;
   bool     isChoch;
   datetime ll2Time;
   datetime lh2Time;
   datetime ll1Time;
   datetime chochTime;
   datetime retraceTime;
  };

//+------------------------------------------------------------------+
//| Utility functions                                                   |
//+------------------------------------------------------------------+
bool IsHighVolatilityPair()
  {
   string s = _Symbol;
   return StringFind(s,"XAU") >= 0 || StringFind(s,"BTC") >= 0 || StringFind(s,"XAG") >= 0 || StringFind(s,"ETH") >= 0;
  }

double PriceFromPoints(double points)
  {
   return points * _Point;
  }

double GetStopLossPointsForSymbol()
  {
   if(UseHighVolatilityAdjustments && IsHighVolatilityPair())
      return HighVolStopLossPoints;
   return StopLossPoints;
  }

double GetTakeProfitPointsForSymbol()
  {
   if(UseHighVolatilityAdjustments && IsHighVolatilityPair())
      return HighVolTakeProfitPoints;
   return TakeProfitPoints;
  }

bool IsNewsBlocked()
  {
   if(!AvoidNews)
      return false;

   datetime t = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(t, dt);

   if((dt.hour >= 7 && dt.hour <= 9) || (dt.hour >= 12 && dt.hour <= 14) || (dt.hour >= 18 && dt.hour <= 20))
      return true;

   return false;
  }

void SendTelegramAlert(string msg)
  {
   if(!SendTelegramAlerts || TelegramBotToken == "" || TelegramChatID == "")
      return;

   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
   string payload = "chat_id=" + TelegramChatID + "&text=" + msg;
   char post[];
   char result[];
   string requestHeaders = "Content-Type: application/x-www-form-urlencoded\r\n";
   string responseHeaders;
   StringToCharArray(payload, post, 0, StringLen(payload));
   int res = WebRequest("POST", url, requestHeaders, 5000, post, result, responseHeaders);
   if(res == -1)
      Print("Telegram alert failed: ", GetLastError());
  }

void FireAlert(string msg)
  {
   if(SendPopupAlerts)
      Alert(msg);
   if(SendPushAlerts)
      SendNotification(msg);
   SendTelegramAlert(msg);
  }

//+------------------------------------------------------------------+
//| Structure detection logic                                          |
//+------------------------------------------------------------------+
bool IsSwingLow(ENUM_TIMEFRAMES tf, int idx, int lookback)
  {
   if(idx <= lookback || idx >= iBars(_Symbol, tf) - lookback)
      return false;

   double val = iLow(_Symbol, tf, idx);
   for(int i = 1; i <= lookback; i++)
     {
      if(iLow(_Symbol, tf, idx - i) <= val || iLow(_Symbol, tf, idx + i) <= val)
         return false;
     }
   return true;
  }

bool IsSwingHigh(ENUM_TIMEFRAMES tf, int idx, int lookback)
  {
   if(idx <= lookback || idx >= iBars(_Symbol, tf) - lookback)
      return false;

   double val = iHigh(_Symbol, tf, idx);
   for(int i = 1; i <= lookback; i++)
     {
      if(iHigh(_Symbol, tf, idx - i) >= val || iHigh(_Symbol, tf, idx + i) >= val)
         return false;
     }
   return true;
  }

bool FindBuySMCSetup(ENUM_TIMEFRAMES tf, SMCSetup &setup)
  {
   setup.valid = false;
   int bars = MathMin(StructureBars, iBars(_Symbol, tf));
   if(bars < 80)
      return false;

   int ll1Idx = -1;
   int lh2Idx = -1;
   int ll2Idx = -1;

   for(int i = 1; i < bars - 1; i++)
     {
      if(IsSwingLow(tf, i, SwingLookback))
        {
         ll1Idx = i;
         break;
        }
     }

   if(ll1Idx < 0)
      return false;

   double lh2Price = -DBL_MAX;
   for(int i = ll1Idx + 1; i < bars - 1; i++)
     {
      if(IsSwingHigh(tf, i, SwingLookback))
        {
         double price = iHigh(_Symbol, tf, i);
         if(price > lh2Price)
           {
            lh2Price = price;
            lh2Idx = i;
           }
        }
     }

   if(lh2Idx < 0)
      return false;

   double ll2Price = DBL_MAX;
   for(int i = lh2Idx + 1; i < bars - 1; i++)
     {
      if(IsSwingLow(tf, i, SwingLookback))
        {
         double price = iLow(_Symbol, tf, i);
         if(price < ll2Price)
           {
            ll2Price = price;
            ll2Idx = i;
           }
        }
     }

   if(ll2Idx < 0)
      return false;

   double LL2 = iLow(_Symbol, tf, ll2Idx);
   double LH2 = iHigh(_Symbol, tf, lh2Idx);
   double LL1 = iLow(_Symbol, tf, ll1Idx);

   if(!(LL2 < LH2 && LL1 < LL2))
      return false;

   int chochBosIdx = -1;
   bool isChoch = false;
   for(int i = ll1Idx - 1; i >= 0; i--)
     {
      if(iClose(_Symbol, tf, i) > LH2)
        {
         chochBosIdx = i;
         isChoch = true;
         break;
        }
     }

   if(chochBosIdx < 0)
      return false;

   setup.valid = true;
   setup.isBuy = true;
   setup.ll2 = LL2;
   setup.lh2 = LH2;
   setup.ll1 = LL1;
   setup.ll2Idx = ll2Idx;
   setup.lh2Idx = lh2Idx;
   setup.ll1Idx = ll1Idx;
   setup.chochBosIdx = chochBosIdx;
   setup.chochOrBosPrice = iClose(_Symbol, tf, chochBosIdx);
   setup.isChoch = isChoch;
   setup.zoneLow = MathMin(LL2, LL1);
   setup.zoneHigh = LH2;
   setup.ll2Time = iTime(_Symbol, tf, ll2Idx);
   setup.lh2Time = iTime(_Symbol, tf, lh2Idx);
   setup.ll1Time = iTime(_Symbol, tf, ll1Idx);
   setup.chochTime = iTime(_Symbol, tf, chochBosIdx);

   // Condition 1: volume retrace between LL1 and LH2 before BOS/CHOCH
   if(UseBuyCondition1)
     {
      long maxVol = -1;
      int maxVolIdx = -1;
      for(int i = MathMin(ll1Idx, lh2Idx); i <= MathMax(ll1Idx, lh2Idx); i++)
        {
         long v = iVolume(_Symbol, tf, i);
         if(v > maxVol)
           {
            maxVol = v;
            maxVolIdx = i;
           }
        }
      if(maxVolIdx >= 0)
        {
         setup.retraceIdx = maxVolIdx;
         setup.retracePrice = iClose(_Symbol, tf, maxVolIdx);
         setup.retraceTime = iTime(_Symbol, tf, maxVolIdx);
         return true;
        }
     }

   // Condition 2: bearish engulf of bullish candle between LH2 and LL1 after BOS/CHOCH
   if(UseBuyCondition2)
     {
      for(int i = MathMin(ll1Idx, lh2Idx); i <= MathMax(ll1Idx, lh2Idx); i++)
        {
         if(iOpen(_Symbol, tf, i) < iClose(_Symbol, tf, i) && i > 0)
           {
            double prevOpen = iOpen(_Symbol, tf, i - 1);
            double prevClose = iClose(_Symbol, tf, i - 1);
            if(prevOpen > prevClose && prevOpen >= iClose(_Symbol, tf, i) && prevClose <= iOpen(_Symbol, tf, i))
              {
               setup.retraceIdx = i;
               setup.retracePrice = iClose(_Symbol, tf, i);
               setup.retraceTime = iTime(_Symbol, tf, i);
               return true;
              }
           }
        }
     }

   // Condition 3: last bullish candle before LL2 low break
   if(UseBuyCondition3)
     {
      int breakIdx = -1;
      for(int i = chochBosIdx; i >= 0; i--)
        {
         if(iLow(_Symbol, tf, i) < LL2)
           {
            breakIdx = i;
            break;
           }
        }
      if(breakIdx >= 0)
        {
         for(int i = breakIdx + 1; i <= MathMax(ll1Idx, lh2Idx); i++)
           {
            if(iOpen(_Symbol, tf, i) < iClose(_Symbol, tf, i))
              {
               setup.retraceIdx = i;
               setup.retracePrice = iClose(_Symbol, tf, i);
               setup.retraceTime = iTime(_Symbol, tf, i);
               return true;
              }
           }
        }
     }

   // Condition 4: fib 50% or 61.8% retrace between LL1 and CHOCH/BOS
   if(UseBuyCondition4)
     {
      double range = setup.chochOrBosPrice - LL1;
      double fib50 = LL1 + range * 0.50;
      double fib618 = LL1 + range * 0.618;
      for(int i = chochBosIdx; i >= 0; i--)
        {
         double price = iClose(_Symbol, tf, i);
         if(price >= LL1 && price <= fib618)
           {
            if(MathAbs(price - fib50) < 0.0001 || MathAbs(price - fib618) < 0.0001)
              {
               setup.retraceIdx = i;
               setup.retracePrice = price;
               setup.retraceTime = iTime(_Symbol, tf, i);
               return true;
              }
           }
        }
     }

   return false;
  }

bool FindSellSMCSetup(ENUM_TIMEFRAMES tf, SMCSetup &setup)
  {
   setup.valid = false;
   int bars = MathMin(StructureBars, iBars(_Symbol, tf));
   if(bars < 80)
      return false;

   int hh1Idx = -1;
   int hl2Idx = -1;
   int hh2Idx = -1;

   for(int i = 1; i < bars - 1; i++)
     {
      if(IsSwingHigh(tf, i, SwingLookback))
        {
         hh1Idx = i;
         break;
        }
     }

   if(hh1Idx < 0)
      return false;

   double hl2Price = DBL_MAX;
   for(int i = hh1Idx + 1; i < bars - 1; i++)
     {
      if(IsSwingLow(tf, i, SwingLookback))
        {
         double price = iLow(_Symbol, tf, i);
         if(price < hl2Price)
           {
            hl2Price = price;
            hl2Idx = i;
           }
        }
     }

   if(hl2Idx < 0)
      return false;

   double hh2Price = -DBL_MAX;
   for(int i = hl2Idx + 1; i < bars - 1; i++)
     {
      if(IsSwingHigh(tf, i, SwingLookback))
        {
         double price = iHigh(_Symbol, tf, i);
         if(price > hh2Price)
           {
            hh2Price = price;
            hh2Idx = i;
           }
        }
     }

   if(hh2Idx < 0)
      return false;

   double HH2 = iHigh(_Symbol, tf, hh2Idx);
   double HL2 = iLow(_Symbol, tf, hl2Idx);
   double HH1 = iHigh(_Symbol, tf, hh1Idx);

   if(!(HH2 > HL2 && HH1 > HH2))
      return false;

   int chochBosIdx = -1;
   bool isChoch = false;
   for(int i = hh1Idx - 1; i >= 0; i--)
     {
      if(iClose(_Symbol, tf, i) < HL2)
        {
         chochBosIdx = i;
         isChoch = true;
         break;
        }
     }

   if(chochBosIdx < 0)
      return false;

   setup.valid = true;
   setup.isBuy = false;
   setup.ll2 = HH2;
   setup.lh2 = HL2;
   setup.ll1 = HH1;
   setup.ll2Idx = hh2Idx;
   setup.lh2Idx = hl2Idx;
   setup.ll1Idx = hh1Idx;
   setup.chochBosIdx = chochBosIdx;
   setup.chochOrBosPrice = iClose(_Symbol, tf, chochBosIdx);
   setup.isChoch = isChoch;
   setup.zoneLow = HL2;
   setup.zoneHigh = MathMax(HH2, HH1);
   setup.ll2Time = iTime(_Symbol, tf, hh2Idx);
   setup.lh2Time = iTime(_Symbol, tf, hl2Idx);
   setup.ll1Time = iTime(_Symbol, tf, hh1Idx);
   setup.chochTime = iTime(_Symbol, tf, chochBosIdx);

   if(UseSellCondition1)
     {
      long maxVol = -1;
      int maxVolIdx = -1;
      for(int i = MathMin(hh1Idx, hl2Idx); i <= MathMax(hh1Idx, hl2Idx); i++)
        {
         long v = iVolume(_Symbol, tf, i);
         if(v > maxVol)
           {
            maxVol = v;
            maxVolIdx = i;
           }
        }
      if(maxVolIdx >= 0)
        {
         setup.retraceIdx = maxVolIdx;
         setup.retracePrice = iClose(_Symbol, tf, maxVolIdx);
         setup.retraceTime = iTime(_Symbol, tf, maxVolIdx);
         return true;
        }
     }

   if(UseSellCondition2)
     {
      for(int i = MathMin(hh1Idx, hl2Idx); i <= MathMax(hh1Idx, hl2Idx); i++)
        {
         if(iOpen(_Symbol, tf, i) > iClose(_Symbol, tf, i) && i > 0)
           {
            double prevOpen = iOpen(_Symbol, tf, i - 1);
            double prevClose = iClose(_Symbol, tf, i - 1);
            if(prevOpen < prevClose && prevOpen <= iClose(_Symbol, tf, i) && prevClose >= iOpen(_Symbol, tf, i))
              {
               setup.retraceIdx = i;
               setup.retracePrice = iClose(_Symbol, tf, i);
               setup.retraceTime = iTime(_Symbol, tf, i);
               return true;
              }
           }
        }
     }

   if(UseSellCondition3)
     {
      int breakIdx = -1;
      for(int i = chochBosIdx; i >= 0; i--)
        {
         if(iHigh(_Symbol, tf, i) > HH2)
           {
            breakIdx = i;
            break;
           }
        }
      if(breakIdx >= 0)
        {
         for(int i = breakIdx + 1; i <= MathMax(hh1Idx, hl2Idx); i++)
           {
            if(iOpen(_Symbol, tf, i) > iClose(_Symbol, tf, i))
              {
               setup.retraceIdx = i;
               setup.retracePrice = iClose(_Symbol, tf, i);
               setup.retraceTime = iTime(_Symbol, tf, i);
               return true;
              }
           }
        }
     }

   if(UseSellCondition4)
     {
      double range = HH1 - setup.chochOrBosPrice;
      double fib50 = HH1 - range * 0.50;
      double fib618 = HH1 - range * 0.618;
      for(int i = chochBosIdx; i >= 0; i--)
        {
         double price = iClose(_Symbol, tf, i);
         if(price <= HH1 && price >= fib618)
           {
            if(MathAbs(price - fib50) < 0.0001 || MathAbs(price - fib618) < 0.0001)
              {
               setup.retraceIdx = i;
               setup.retracePrice = price;
               setup.retraceTime = iTime(_Symbol, tf, i);
               return true;
              }
           }
        }
     }

   return false;
  }

void DrawSMCObjects(ENUM_TIMEFRAMES tf, SMCSetup &setup)
  {
   string prefix = "SMC_" + IntegerToString(tf) + "_" + IntegerToString(setup.ll2Idx);
   ObjectDelete(0, prefix + "_1");
   ObjectDelete(0, prefix + "_2");
   ObjectDelete(0, prefix + "_3");
   ObjectDelete(0, prefix + "_CHOCH");
   ObjectDelete(0, prefix + "_RETRACE");

   ObjectCreate(0, prefix + "_1", OBJ_TEXT, 0, setup.ll2Time, setup.ll2);
   ObjectSetString(0, prefix + "_1", OBJPROP_TEXT, "1");
   ObjectSetInteger(0, prefix + "_1", OBJPROP_COLOR, clrYellow);

   ObjectCreate(0, prefix + "_2", OBJ_TEXT, 0, setup.lh2Time, setup.lh2);
   ObjectSetString(0, prefix + "_2", OBJPROP_TEXT, "2");
   ObjectSetInteger(0, prefix + "_2", OBJPROP_COLOR, clrOrange);

   ObjectCreate(0, prefix + "_3", OBJ_TEXT, 0, setup.ll1Time, setup.ll1);
   ObjectSetString(0, prefix + "_3", OBJPROP_TEXT, "3");
   ObjectSetInteger(0, prefix + "_3", OBJPROP_COLOR, clrLime);

   ObjectCreate(0, prefix + "_CHOCH", OBJ_TEXT, 0, setup.chochTime, setup.chochOrBosPrice);
   ObjectSetString(0, prefix + "_CHOCH", OBJPROP_TEXT, setup.isChoch ? "CHOCH" : "BOS");
   ObjectSetInteger(0, prefix + "_CHOCH", OBJPROP_COLOR, clrDodgerBlue);

   ObjectCreate(0, prefix + "_RETRACE", OBJ_TEXT, 0, setup.retraceTime, setup.retracePrice);
   ObjectSetString(0, prefix + "_RETRACE", OBJPROP_TEXT, "Retrace");
   ObjectSetInteger(0, prefix + "_RETRACE", OBJPROP_COLOR, clrRed);

   ObjectCreate(0, prefix + "_LINE", OBJ_TREND, 0, setup.ll2Time, setup.ll2, setup.retraceTime, setup.retracePrice);
   ObjectSetInteger(0, prefix + "_LINE", OBJPROP_COLOR, setup.isBuy ? clrLime : clrRed);
   ObjectSetInteger(0, prefix + "_LINE", OBJPROP_RAY_RIGHT, true);
  }

//+------------------------------------------------------------------+
//| Trade risk calculations                                            |
//+------------------------------------------------------------------+
double CalculateStopLossPrice(bool isBuy, double entryPrice, double zoneLevel)
  {
   double slPoints = GetStopLossPointsForSymbol();
   double buffer = PriceFromPoints(StopLossBufferPoints);

   if(!UseStopLoss)
      return 0.0;

   if(isBuy)
      return zoneLevel - buffer - PriceFromPoints(slPoints);
   else
      return zoneLevel + buffer + PriceFromPoints(slPoints);
  }

double CalculateTakeProfitPrice(bool isBuy, double entryPrice, double stopLossPrice)
  {
   if(!UseTakeProfit)
      return 0.0;

   if(UseRiskRewardTP)
     {
      double risk = MathAbs(entryPrice - stopLossPrice);
      if(risk > 0.0)
        {
         if(isBuy)
            return entryPrice + risk * RiskRewardRatio;
         else
            return entryPrice - risk * RiskRewardRatio;
        }
     }

   double tpPoints = GetTakeProfitPointsForSymbol();
   if(isBuy)
      return entryPrice + PriceFromPoints(tpPoints);
   else
      return entryPrice - PriceFromPoints(tpPoints);
  }

//+------------------------------------------------------------------+
//| Trade execution                                                    |
//+------------------------------------------------------------------+
bool OpenBuyPosition(double entryPrice, double stopLoss, double takeProfit)
  {
   if(PositionsTotal() >= MaxOpenPositions)
      return false;

   if(IsNewsBlocked())
      return false;

   bool ok = trade.Buy(LotSize, _Symbol, entryPrice, stopLoss, takeProfit, "SMC_BUY");
   if(ok)
      FireAlert("BUY SIGNAL: " + _Symbol + " Entry=" + DoubleToString(entryPrice,_Digits) + " SL=" + DoubleToString(stopLoss,_Digits) + " TP=" + DoubleToString(takeProfit,_Digits));
   return ok;
  }

bool OpenSellPosition(double entryPrice, double stopLoss, double takeProfit)
  {
   if(PositionsTotal() >= MaxOpenPositions)
      return false;

   if(IsNewsBlocked())
      return false;

   bool ok = trade.Sell(LotSize, _Symbol, entryPrice, stopLoss, takeProfit, "SMC_SELL");
   if(ok)
      FireAlert("SELL SIGNAL: " + _Symbol + " Entry=" + DoubleToString(entryPrice,_Digits) + " SL=" + DoubleToString(stopLoss,_Digits) + " TP=" + DoubleToString(takeProfit,_Digits));
   return ok;
  }

void ScanTimeframe(ENUM_TIMEFRAMES tf)
  {
   SMCSetup buySetup;
   SMCSetup sellSetup;

   if(FindBuySMCSetup(tf, buySetup))
     {
      DrawSMCObjects(tf, buySetup);
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double zoneLevel = buySetup.zoneLow;
      double sl = CalculateStopLossPrice(true, entry, zoneLevel);
      double tp = CalculateTakeProfitPrice(true, entry, sl);
      OpenBuyPosition(entry, sl, tp);
     }

   if(FindSellSMCSetup(tf, sellSetup))
     {
      DrawSMCObjects(tf, sellSetup);
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double zoneLevel = sellSetup.zoneHigh;
      double sl = CalculateStopLossPrice(false, entry, zoneLevel);
      double tp = CalculateTakeProfitPrice(false, entry, sl);
      OpenSellPosition(entry, sl, tp);
     }
  }

//+------------------------------------------------------------------+
//| Break-even and trailing stop                                       |
//+------------------------------------------------------------------+
void ManageBreakEvenAndTrailing()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      double entry = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl    = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);
      int type     = (int)PositionGetInteger(POSITION_TYPE);
      double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double current = (type == POSITION_TYPE_BUY) ? bid : ask;

      if(UseBreakEven)
        {
         double breakEven = (type == POSITION_TYPE_BUY) ? entry + PriceFromPoints(BreakEvenPoints) : entry - PriceFromPoints(BreakEvenPoints);
         if(type == POSITION_TYPE_BUY && current > breakEven && (sl == 0 || sl < entry))
            trade.PositionModify(ticket, entry, tp);
         if(type == POSITION_TYPE_SELL && current < breakEven && (sl == 0 || sl > entry))
            trade.PositionModify(ticket, entry, tp);
        }

      if(UseTrailingStop)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double newSL = current - PriceFromPoints(TrailingStopPoints);
            if(newSL > sl + PriceFromPoints(TrailingStepPoints))
               trade.PositionModify(ticket, newSL, tp);
           }
         else
           {
            double newSL = current + PriceFromPoints(TrailingStopPoints);
            if(newSL < sl - PriceFromPoints(TrailingStepPoints))
               trade.PositionModify(ticket, newSL, tp);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Partial close                                                      |
//+------------------------------------------------------------------+
void ManagePartialProfit()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currPrice = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double sl = PositionGetDouble(POSITION_SL);
      double risk = MathAbs(currPrice - sl);
      double rr = 0;
      if(risk > 0)
         rr = MathAbs(currPrice - openPrice) / risk;

      if(PartialCloseEnabled && rr >= PartialCloseRR)
        {
         double closeVolume = PositionGetDouble(POSITION_VOLUME) * (PartialClosePercent / 100.0);
         if(closeVolume > 0.0)
            trade.PositionClosePartial(ticket, closeVolume);
        }
     }
  }

//+------------------------------------------------------------------+
//| Dashboard                                                           |
//+------------------------------------------------------------------+
void DrawDashboard()
  {
   if(!ShowDashboard)
      return;

   string name = "SMC_Dashboard";
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, DashboardFontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
     }

   string text = "SMC EA | Symbol=" + _Symbol + " | Positions=" + IntegerToString(PositionsTotal()) +
                 " | Lot=" + DoubleToString(LotSize,2) +
                 " | SL=" + DoubleToString(GetStopLossPointsForSymbol(),1) + " pts" +
                 " | TP=" + DoubleToString(GetTakeProfitPointsForSymbol(),1) + " pts";

   ObjectSetString(0, name, OBJPROP_TEXT, text);
  }

//+------------------------------------------------------------------+
//| OnInit / OnTick                                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   ObjectDelete(0, "SMC_Dashboard");
  }

void OnTick()
  {
   ManageBreakEvenAndTrailing();
   ManagePartialProfit();
   DrawDashboard();

   if(IsNewsBlocked())
      return;

   if(EnableD1) ScanTimeframe(PERIOD_D1);
   if(EnableH4) ScanTimeframe(PERIOD_H4);
   if(EnableH1) ScanTimeframe(PERIOD_H1);
   if(EnableM30) ScanTimeframe(PERIOD_M30);
   if(EnableM15) ScanTimeframe(PERIOD_M15);
   if(EnableM5) ScanTimeframe(PERIOD_M5);
   if(EnableM1) ScanTimeframe(PERIOD_M1);
  }
//+------------------------------------------------------------------+
