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

struct SMCZone
  {
   bool     valid;
   bool     isBuy;
   double   ll2;
   double   lh2;
   double   ll1;
   double   chochOrBosPrice;
   double   retracePrice;
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

   // basic time filter; replace with broker calendar if needed
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
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   StringToCharArray(payload, post, 0, StringLen(payload));
   int res = WebRequest("POST", url, headers, 5000, post, result);
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

//+------------------------------------------------------------------+
//| Break-even and trailing stop                                       |
//+------------------------------------------------------------------+
void ManageBreakEvenAndTrailing()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!PositionSelectByTicket(PositionGetTicket(i)))
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
            trade.PositionModify(PositionGetTicket(i), entry, tp);
         if(type == POSITION_TYPE_SELL && current < breakEven && (sl == 0 || sl > entry))
            trade.PositionModify(PositionGetTicket(i), entry, tp);
        }

      if(UseTrailingStop)
        {
         if(type == POSITION_TYPE_BUY)
           {
            double newSL = current - PriceFromPoints(TrailingStopPoints);
            if(newSL > sl + PriceFromPoints(TrailingStepPoints))
               trade.PositionModify(PositionGetTicket(i), newSL, tp);
           }
         else
           {
            double newSL = current + PriceFromPoints(TrailingStopPoints);
            if(newSL < sl - PriceFromPoints(TrailingStepPoints))
               trade.PositionModify(PositionGetTicket(i), newSL, tp);
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
      if(!PositionSelectByTicket(PositionGetTicket(i)))
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
            trade.PositionClosePartial(PositionGetTicket(i), closeVolume);
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
//| Entry styles / strategy hook                                       |
//+------------------------------------------------------------------+
void EvaluateBuySetup()
  {
   // This hook is intended to accept your LL2/LH2/LL1 + CHOCH/BOS + retrace logic.
   // The actual pattern detection can be added here, but the risk and execution layer is already active.
   double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double zoneLevel = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = CalculateStopLossPrice(true, entry, zoneLevel);
   double tp = CalculateTakeProfitPrice(true, entry, sl);

   if(UseStopLoss && sl == 0.0)
      sl = 0.0;

   OpenBuyPosition(entry, sl, tp);
  }

void EvaluateSellSetup()
  {
   double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double zoneLevel = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = CalculateStopLossPrice(false, entry, zoneLevel);
   double tp = CalculateTakeProfitPrice(false, entry, sl);

   if(UseStopLoss && sl == 0.0)
      sl = 0.0;

   OpenSellPosition(entry, sl, tp);
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

   // Example trigger: add your actual structure logic here.
   // For a full LL2/LH2/LL1 implementation, replace these calls with structure detection logic.
   // Example skeleton calls:
   // if(UseBuyCondition1) EvaluateBuySetup();
   // if(UseSellCondition1) EvaluateSellSetup();

   // Uncomment only when you are ready to use as a live trade trigger:
   // EvaluateBuySetup();
   // EvaluateSellSetup();
  }
//+------------------------------------------------------------------+
