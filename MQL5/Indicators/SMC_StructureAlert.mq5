//+------------------------------------------------------------------+
//|                                         SMC_StructureAlert.mq5    |
//|  LL2-LH2-LL1 / HH2-HL2-HH1 structure, CHOCH/BOS, Retrace, Alerts  |
//|  + SL/TP auto-draw, cooldown, multi-TF confirm, trailing stop,    |
//|  partial TP levels, on-chart dashboard panel                     |
//+------------------------------------------------------------------+
#property copyright "Custom"
#property version   "3.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//---------------- INPUTS ---------------------------------------------------
input int    SwingLeftBars      = 3;      // Bars to the left for fractal swing
input int    SwingRightBars     = 3;      // Bars to the right for fractal swing (confirmation delay)
input int    MaxSwingsStored    = 200;    // Max swing points kept in memory
input int    LookbackForZones   = 300;    // Bars scanned for supply/demand trendlines
input int    ConsecutiveCount   = 3;      // Number of consecutive highs/lows to draw supply/demand line
input color  BullColor          = clrLime;
input color  BearColor          = clrRed;
input color  ChochColor         = clrDeepSkyBlue;
input color  BosColor           = clrOrange;
input color  RetraceColor       = clrMagenta;
input color  SupplyColor        = clrTomato;
input color  DemandColor        = clrLimeGreen;
input bool   EnablePush         = true;
input bool   EnableTelegram     = true;
input string TelegramToken      = "YOUR_BOT_TOKEN_HERE";
input string TelegramChatID     = "YOUR_CHAT_ID_HERE";
input string ObjPrefix          = "SMC_";

input group "=== Risk Management (SL/TP Auto-Draw) ==="
input bool   EnableSLTP         = true;      // Draw SL/TP lines on signal
input double RiskRewardRatio    = 2.0;       // Legacy single-TP RR (used if partial TPs disabled)
input double SL_BufferPips      = 5;         // Extra buffer beyond swing point (in points)
input color  SLColor            = clrRed;
input color  TPColor            = clrLimeGreen;

input group "=== Partial Take-Profit Levels ==="
input bool   EnablePartialTPs   = true;      // Draw TP1/TP2/TP3 instead of single TP
input double TP1_RR             = 1.0;       // TP1 reward multiple (x SL distance)
input double TP2_RR             = 2.0;       // TP2 reward multiple
input double TP3_RR             = 3.0;       // TP3 reward multiple
input color  TP1Color           = clrYellow;
input color  TP2Color           = clrLimeGreen;
input color  TP3Color           = clrAqua;

input group "=== Trailing Stop (Visual) ==="
input bool   EnableTrailingSL   = true;      // Recalculate/move SL line as price advances favorably
input double TrailStartRR       = 1.0;       // Start trailing once price reaches this multiple of R
input double TrailStepRR        = 0.5;       // Trail SL to lock in this multiple of R once triggered

input group "=== Alert Cooldown ==="
input int    CooldownMinutes    = 30;        // Minimum minutes between alerts per symbol+timeframe

input group "=== Multi-Timeframe Confirmation ==="
input bool   EnableHTFConfirm    = true;                 // Require higher timeframe trend agreement
input ENUM_TIMEFRAMES HTF_Timeframe = PERIOD_H4;         // Higher timeframe used for confirmation
input int    HTF_MA_Period       = 50;                   // MA period on HTF used to define trend
input ENUM_MA_METHOD HTF_MA_Method = MODE_EMA;           // MA method

input group "=== Dashboard Panel ==="
input bool   ShowDashboard       = true;
input int    DashboardX          = 10;
input int    DashboardY          = 20;
input color  DashboardTextColor  = clrWhite;
input color  DashboardBgColor    = clrDarkSlateGray;

//---------------- STRUCTS ---------------------------------------------------
struct SwingPoint
  {
   datetime time;
   double   price;
   int      barIndex;
   bool     isHigh;
  };

SwingPoint swings[];

enum BullState {B_NONE, B_LL2, B_LH2, B_LL1, B_BREAK, B_RETRACE_DONE};
enum BearState {S_NONE, S_HH2, S_HL2, S_HH1, S_BREAK, S_RETRACE_DONE};
enum TrendState {TREND_NONE, TREND_BULLISH, TREND_BEARISH};

BullState  bullState  = B_NONE;
BearState  bearState  = S_NONE;
TrendState currentTrend = TREND_NONE;

SwingPoint bLL2, bLH2, bLL1;
SwingPoint sHH2, sHL2, sHH1;

datetime lastAlertBarTime_Buy  = 0;
datetime lastAlertBarTime_Sell = 0;
datetime lastBarProcessed      = 0;

datetime lastBuyAlertTime  = 0;
datetime lastSellAlertTime = 0;

int htfMAHandle = INVALID_HANDLE;

// Active trade tracking (visual only) for trailing stop management
bool   activeTradeIsBuy   = false;
bool   activeTradeExists  = false;
double activeEntryPrice   = 0;
double activeInitialSL    = 0;
double activeCurrentSL    = 0;
double activeRDistance    = 0; // 1R distance in price
string lastSignalText     = "None";

//+------------------------------------------------------------------+
int OnInit()
  {
   ArrayResize(swings, 0);
   EventSetTimer(1);

   if(EnableHTFConfirm)
     {
      htfMAHandle = iMA(_Symbol, HTF_Timeframe, HTF_MA_Period, 0, HTF_MA_Method, PRICE_CLOSE);
      if(htfMAHandle == INVALID_HANDLE)
         Print("Warning: Failed to create HTF MA handle. Multi-timeframe confirmation will be skipped.");
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(htfMAHandle != INVALID_HANDLE)
      IndicatorRelease(htfMAHandle);
   ObjectsDeleteAll(0, ObjPrefix + "DASH_");
  }
//+------------------------------------------------------------------+
void OnTimer()
  {
   // Update trailing SL and dashboard every second regardless of new bar
   if(EnableTrailingSL && activeTradeExists)
      UpdateTrailingStop();
   if(ShowDashboard)
      UpdateDashboard();
  }

//+------------------------------------------------------------------+
//| Main calculation                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < SwingLeftBars + SwingRightBars + 5)
      return(rates_total);

   if(time[rates_total-1] == lastBarProcessed)
     {
      if(ShowDashboard)
         UpdateDashboard();
      return(rates_total);
     }
   lastBarProcessed = time[rates_total-1];

   DetectSwings(rates_total, time, high, low);
   DrawSupplyDemandZones(rates_total, time, high, low);
   RunBullishStateMachine(rates_total, time, open, high, low, close);
   RunBearishStateMachine(rates_total, time, open, high, low, close);

   if(EnableTrailingSL && activeTradeExists)
      UpdateTrailingStop();

   if(ShowDashboard)
      UpdateDashboard();

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Fractal-based swing detection (confirmed swings only)             |
//+------------------------------------------------------------------+
void DetectSwings(int rates_total, const datetime &time[], const double &high[], const double &low[])
  {
   int checkIndex = rates_total - SwingRightBars - 1;
   if(checkIndex - SwingLeftBars < 0)
      return;

   int n = ArraySize(swings);
   if(n>0 && swings[n-1].time == time[checkIndex])
      return;

   bool isHigh = true;
   bool isLow  = true;
   double h = high[checkIndex];
   double l = low[checkIndex];

   for(int i=1;i<=SwingLeftBars;i++)
     {
      if(high[checkIndex-i] > h) isHigh=false;
      if(low[checkIndex-i]  < l) isLow=false;
     }
   for(int i=1;i<=SwingRightBars;i++)
     {
      if(high[checkIndex+i] > h) isHigh=false;
      if(low[checkIndex+i]  < l) isLow=false;
     }

   if(isHigh)
      AddSwing(time[checkIndex], h, checkIndex, true);
   if(isLow)
      AddSwing(time[checkIndex], l, checkIndex, false);
  }

void AddSwing(datetime t, double price, int idx, bool isHigh)
  {
   int n = ArraySize(swings);
   ArrayResize(swings, n+1);
   swings[n].time = t;
   swings[n].price = price;
   swings[n].barIndex = idx;
   swings[n].isHigh = isHigh;

   if(ArraySize(swings) > MaxSwingsStored)
     {
      for(int i=0;i<ArraySize(swings)-1;i++)
         swings[i]=swings[i+1];
      ArrayResize(swings, ArraySize(swings)-1);
     }
  }

int GetLastSwings(bool wantHigh, SwingPoint &outArr[], int count)
  {
   int found=0;
   int n = ArraySize(swings);
   ArrayResize(outArr,0);
   SwingPoint tmp[];
   for(int i=n-1;i>=0 && found<count;i--)
     {
      if(swings[i].isHigh==wantHigh)
        {
         int sz=ArraySize(tmp);
         ArrayResize(tmp, sz+1);
         tmp[sz]=swings[i];
         found++;
        }
     }
   int sz=ArraySize(tmp);
   ArrayResize(outArr, sz);
   for(int i=0;i<sz;i++)
      outArr[i]=tmp[sz-1-i];
   return sz;
  }

//+------------------------------------------------------------------+
//| Multi-timeframe confirmation                                      |
//+------------------------------------------------------------------+
bool HTF_TrendAgrees(bool wantBullish)
  {
   if(!EnableHTFConfirm)
      return true;

   if(htfMAHandle == INVALID_HANDLE)
      return true;

   double maBuf[];
   ArraySetAsSeries(maBuf, true);
   if(CopyBuffer(htfMAHandle, 0, 0, 3, maBuf) < 3)
      return true;

   double htfClose = iClose(_Symbol, HTF_Timeframe, 1);
   if(htfClose == 0)
      return true;

   bool htfBullish = htfClose > maBuf[1];
   bool htfBearish = htfClose < maBuf[1];

   return wantBullish ? htfBullish : htfBearish;
  }

//+------------------------------------------------------------------+
//| Alert cooldown check                                               |
//+------------------------------------------------------------------+
bool CooldownPassed(bool isBuy)
  {
   datetime lastTime = isBuy ? lastBuyAlertTime : lastSellAlertTime;
   if(lastTime == 0)
      return true;
   int elapsedMinutes = (int)((TimeCurrent() - lastTime) / 60);
   return elapsedMinutes >= CooldownMinutes;
  }

void UpdateCooldown(bool isBuy)
  {
   if(isBuy)
      lastBuyAlertTime = TimeCurrent();
   else
      lastSellAlertTime = TimeCurrent();
  }

//+------------------------------------------------------------------+
//| SL/TP auto-draw (with optional partial TP levels)                  |
//+------------------------------------------------------------------+
void DrawSLTP(bool isBuy, datetime signalTime, double entryPrice, double structureSwingPrice)
  {
   if(!EnableSLTP)
      return;

   double buffer = SL_BufferPips * _Point;
   double slPrice;
   double rDist;

   if(isBuy)
     {
      slPrice = structureSwingPrice - buffer;
      rDist   = entryPrice - slPrice;
     }
   else
     {
      slPrice = structureSwingPrice + buffer;
      rDist   = slPrice - entryPrice;
     }

   if(rDist <= 0)
      return; // invalid risk distance, skip drawing

   string slName = ObjPrefix + (isBuy ? "BUY_SL" : "SELL_SL");
   DrawHLine(slName, slPrice, SLColor, "SL " + DoubleToString(slPrice, _Digits));

   if(EnablePartialTPs)
     {
      double tp1 = isBuy ? entryPrice + rDist*TP1_RR : entryPrice - rDist*TP1_RR;
      double tp2 = isBuy ? entryPrice + rDist*TP2_RR : entryPrice - rDist*TP2_RR;
      double tp3 = isBuy ? entryPrice + rDist*TP3_RR : entryPrice - rDist*TP3_RR;

      string tp1Name = ObjPrefix + (isBuy ? "BUY_TP1" : "SELL_TP1");
      string tp2Name = ObjPrefix + (isBuy ? "BUY_TP2" : "SELL_TP2");
      string tp3Name = ObjPrefix + (isBuy ? "BUY_TP3" : "SELL_TP3");

      DrawHLine(tp1Name, tp1, TP1Color, "TP1 (" + DoubleToString(TP1_RR,1) + "R) " + DoubleToString(tp1, _Digits));
      DrawHLine(tp2Name, tp2, TP2Color, "TP2 (" + DoubleToString(TP2_RR,1) + "R) " + DoubleToString(tp2, _Digits));
      DrawHLine(tp3Name, tp3, TP3Color, "TP3 (" + DoubleToString(TP3_RR,1) + "R) " + DoubleToString(tp3, _Digits));
     }
   else
     {
      double tp = isBuy ? entryPrice + rDist*RiskRewardRatio : entryPrice - rDist*RiskRewardRatio;
      string tpName = ObjPrefix + (isBuy ? "BUY_TP" : "SELL_TP");
      DrawHLine(tpName, tp, TPColor, "TP " + DoubleToString(tp, _Digits));
     }

   // Register active trade for visual trailing stop tracking
   activeTradeIsBuy  = isBuy;
   activeTradeExists = true;
   activeEntryPrice  = entryPrice;
   activeInitialSL   = slPrice;
   activeCurrentSL   = slPrice;
   activeRDistance   = rDist;
  }

void DrawHLine(string name, double price, color clr, string label)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   else
      ObjectMove(0, name, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetString(0, name, OBJPROP_TEXT, label);
  }

//+------------------------------------------------------------------+
//| Visual trailing stop management                                    |
//| Moves the SL line forward once price has moved TrailStartRR in     |
//| favor, locking in TrailStepRR increments. This is VISUAL ONLY —    |
//| an indicator cannot modify live broker orders. A companion EA      |
//| would need to read this SL object's price to manage real trades.  |
//+------------------------------------------------------------------+
void UpdateTrailingStop()
  {
   if(!activeTradeExists || activeRDistance <= 0)
      return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentPrice = activeTradeIsBuy ? bid : ask;

   double favorableMove = activeTradeIsBuy ? (currentPrice - activeEntryPrice) : (activeEntryPrice - currentPrice);
   double favorableR = favorableMove / activeRDistance;

   if(favorableR >= TrailStartRR)
     {
      // Lock in profit in TrailStepRR increments as price advances
      int steps = (int)MathFloor(favorableR / TrailStepRR);
      double lockedR = steps * TrailStepRR - TrailStartRR; // keep some room; adjust as desired
      if(lockedR < 0) lockedR = 0;

      double newSL = activeTradeIsBuy ?
                     activeEntryPrice + lockedR * activeRDistance :
                     activeEntryPrice - lockedR * activeRDistance;

      bool improves = activeTradeIsBuy ? (newSL > activeCurrentSL) : (newSL < activeCurrentSL);
      if(improves)
        {
         activeCurrentSL = newSL;
         string slName = ObjPrefix + (activeTradeIsBuy ? "BUY_SL" : "SELL_SL");
         DrawHLine(slName, activeCurrentSL, SLColor, "SL (Trailing) " + DoubleToString(activeCurrentSL, _Digits));
        }
     }

   // If price returns to stop level, consider the visual trade closed
   bool stoppedOut = activeTradeIsBuy ? (bid <= activeCurrentSL) : (ask >= activeCurrentSL);
   if(stoppedOut)
      activeTradeExists = false;
  }

//+------------------------------------------------------------------+
//| BULLISH SEQUENCE: LL2 -> LH2 -> LL1 -> CHOCH/BOS -> Retrace -> Buy|
//+------------------------------------------------------------------+
void RunBullishStateMachine(int rates_total, const datetime &time[], const double &open[],
                             const double &high[], const double &low[], const double &close[])
  {
   SwingPoint lows[], highs[];
   int nl = GetLastSwings(false, lows, 3);
   int nh = GetLastSwings(true,  highs, 2);
   if(nl<3 || nh<1)
      return;

   SwingPoint candLL2 = lows[0];
   SwingPoint candLL1 = lows[nl-1];
   SwingPoint candLH2;
   bool foundLH2=false;
   for(int i=ArraySize(swings)-1;i>=0;i--)
     {
      if(swings[i].isHigh && swings[i].time>candLL2.time && swings[i].time<candLL1.time)
        {
         candLH2 = swings[i];
         foundLH2 = true;
         break;
        }
     }
   if(!foundLH2)
      return;

   bool structureValid = (candLL2.price < candLH2.price) && (candLL1.price < candLL2.price);

   if(structureValid && bullState==B_NONE)
     {
      bLL2=candLL2; bLH2=candLH2; bLL1=candLL1;
      bullState = B_LL1;
      DrawLabel("BULL_1", bLL2.time, bLL2.price, "1", BullColor, -1);
      DrawLabel("BULL_2", bLH2.time, bLH2.price, "2", BearColor, 1);
      DrawLabel("BULL_3", bLL1.time, bLL1.price, "3", BullColor, -1);
      DrawTrendLine("BULL_L1", bLL2.time, bLL2.price, bLH2.time, bLH2.price, BullColor);
      DrawTrendLine("BULL_L2", bLH2.time, bLH2.price, bLL1.time, bLL1.price, BullColor);
     }

   if(bullState==B_LL1)
     {
      int lastClosed = rates_total-2;
      if(time[lastClosed] > bLL1.time && close[lastClosed] > bLH2.price)
        {
         string tag = (currentTrend==TREND_BULLISH) ? "BOS" : "CHOCH";
         color tagColor = (tag=="BOS") ? BosColor : ChochColor;

         DrawLabel("BULL_CHOCH", time[lastClosed], high[lastClosed], tag, tagColor, 1);
         DrawTrendLine("BULL_L3", bLL1.time, bLL1.price, time[lastClosed], close[lastClosed], tagColor);

         currentTrend = TREND_BULLISH;
         bullState = B_BREAK;
        }
     }

   if(bullState==B_BREAK)
     {
      int retraceIdx = FindBullishRetraceCandle(time, open, high, low, close, rates_total, bLH2.time, bLL1.time);
      if(retraceIdx>=0)
        {
         DrawLabel("BULL_RETRACE", time[retraceIdx], low[retraceIdx], "Retrace", RetraceColor, -1);
         DrawTrendLine("BULL_L4", time[retraceIdx], low[retraceIdx], time[rates_total-2], close[rates_total-2], RetraceColor);

         bool htfOk = HTF_TrendAgrees(true);
         bool cooldownOk = CooldownPassed(true);

         if(lastAlertBarTime_Buy != time[rates_total-1] && htfOk && cooldownOk)
           {
            double entryPrice = close[rates_total-2];
            string tagUsed = (currentTrend==TREND_BULLISH?"BOS":"CHOCH");

            DrawSLTP(true, time[rates_total-2], entryPrice, MathMin(bLL1.price, low[retraceIdx]));

            string msg = StringFormat("BUY Signal (%s)\nStructure: LL2->LH2->LL1->%s->Retrace\nSymbol: %s  TF: %s\nPrice: %.5f  Time: %s\nHTF Confirmed: %s",
                                       ObjPrefix, tagUsed, _Symbol, EnumToString((ENUM_TIMEFRAMES)Period()),
                                       entryPrice, TimeToString(time[rates_total-2]), (EnableHTFConfirm?"Yes":"N/A"));
            SendAlert(msg);
            lastAlertBarTime_Buy = time[rates_total-1];
            UpdateCooldown(true);
            lastSignalText = "BUY @ " + DoubleToString(entryPrice, _Digits) + " (" + tagUsed + ")";
            bullState = B_RETRACE_DONE;
           }
         else if(lastAlertBarTime_Buy != time[rates_total-1] && (!htfOk || !cooldownOk))
           {
            if(!htfOk)
               Print("BUY signal suppressed: HTF trend does not confirm bullish bias.");
            if(!cooldownOk)
               Print("BUY signal suppressed: cooldown period active.");
            bullState = B_RETRACE_DONE;
           }
        }
     }

   if(bullState==B_RETRACE_DONE || bullState==B_LL1 || bullState==B_BREAK)
     {
      if(candLL2.time > bLL2.time)
         bullState = B_NONE;
     }
  }

int FindBullishRetraceCandle(const datetime &time[], const double &open[], const double &high[],
                              const double &low[], const double &close[], int rates_total,
                              datetime fromTime, datetime toTime)
  {
   int startIdx=-1, endIdx=-1;
   for(int i=0;i<rates_total;i++)
     {
      if(time[i]==fromTime) startIdx=i;
      if(time[i]==toTime)   endIdx=i;
     }
   if(startIdx<0 || endIdx<0 || endIdx<=startIdx)
      return -1;

   int engulfedIdx=-1;
   for(int i=endIdx-1;i>startIdx;i--)
     {
      bool bullish = close[i]>open[i];
      if(bullish && i+1<=endIdx)
        {
         bool nextBearish = close[i+1]<open[i+1];
         bool engulf = nextBearish && open[i+1]>=close[i] && close[i+1]<=open[i];
         if(nextBearish && engulf)
           {
            engulfedIdx = i;
            break;
           }
        }
     }
   if(engulfedIdx>=0)
      return engulfedIdx;

   for(int i=endIdx-1;i>startIdx;i--)
     {
      if(close[i]>open[i])
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| BEARISH SEQUENCE (mirror): HH2 -> HL2 -> HH1 -> CHOCH/BOS -> Retr |
//+------------------------------------------------------------------+
void RunBearishStateMachine(int rates_total, const datetime &time[], const double &open[],
                             const double &high[], const double &low[], const double &close[])
  {
   SwingPoint highs[], lows[];
   int nh = GetLastSwings(true, highs, 3);
   int nl = GetLastSwings(false, lows, 1);
   if(nh<3 || nl<1)
      return;

   SwingPoint candHH2 = highs[0];
   SwingPoint candHH1 = highs[nh-1];
   SwingPoint candHL2;
   bool foundHL2=false;
   for(int i=ArraySize(swings)-1;i>=0;i--)
     {
      if(!swings[i].isHigh && swings[i].time>candHH2.time && swings[i].time<candHH1.time)
        {
         candHL2 = swings[i];
         foundHL2=true;
         break;
        }
     }
   if(!foundHL2)
      return;

   bool structureValid = (candHH2.price > candHL2.price) && (candHH1.price > candHH2.price);

   if(structureValid && bearState==S_NONE)
     {
      sHH2=candHH2; sHL2=candHL2; sHH1=candHH1;
      bearState = S_HH1;
      DrawLabel("BEAR_1", sHH2.time, sHH2.price, "1", BearColor, 1);
      DrawLabel("BEAR_2", sHL2.time, sHL2.price, "2", BullColor, -1);
      DrawLabel("BEAR_3", sHH1.time, sHH1.price, "3", BearColor, 1);
      DrawTrendLine("BEAR_L1", sHH2.time, sHH2.price, sHL2.time, sHL2.price, BearColor);
      DrawTrendLine("BEAR_L2", sHL2.time, sHL2.price, sHH1.time, sHH1.price, BearColor);
     }

   if(bearState==S_HH1)
     {
      int lastClosed = rates_total-2;
      if(time[lastClosed] > sHH1.time && close[lastClosed] < sHL2.price)
        {
         string tag = (currentTrend==TREND_BEARISH) ? "BOS" : "CHOCH";
         color tagColor = (tag=="BOS") ? BosColor : ChochColor;

         DrawLabel("BEAR_CHOCH", time[lastClosed], low[lastClosed], tag, tagColor, -1);
         DrawTrendLine("BEAR_L3", sHH1.time, sHH1.price, time[lastClosed], close[lastClosed], tagColor);

         currentTrend = TREND_BEARISH;
         bearState = S_BREAK;
        }
     }

   if(bearState==S_BREAK)
     {
      int retraceIdx = FindBearishRetraceCandle(time, open, high, low, close, rates_total, sHL2.time, sHH1.time);
      if(retraceIdx>=0)
        {
         DrawLabel("BEAR_RETRACE", time[retraceIdx], high[retraceIdx], "Retrace", RetraceColor, 1);
         DrawTrendLine("BEAR_L4", time[retraceIdx], high[retraceIdx], time[rates_total-2], close[rates_total-2], RetraceColor);

         bool htfOk = HTF_TrendAgrees(false);
         bool cooldownOk = CooldownPassed(false);

         if(lastAlertBarTime_Sell != time[rates_total-1] && htfOk && cooldownOk)
           {
            double entryPrice = close[rates_total-2];
            string tagUsed = (currentTrend==TREND_BEARISH?"BOS":"CHOCH");

            DrawSLTP(false, time[rates_total-2], entryPrice, MathMax(sHH1.price, high[retraceIdx]));

            string msg = StringFormat("SELL Signal (%s)\nStructure: HH2->HL2->HH1->%s->Retrace\nSymbol: %s  TF: %s\nPrice: %.5f  Time: %s\nHTF Confirmed: %s",
                                       ObjPrefix, tagUsed, _Symbol, EnumToString((ENUM_TIMEFRAMES)Period()),
                                       entryPrice, TimeToString(time[rates_total-2]), (EnableHTFConfirm?"Yes":"N/A"));
            SendAlert(msg);
            lastAlertBarTime_Sell = time[rates_total-1];
            UpdateCooldown(false);
            lastSignalText = "SELL @ " + DoubleToString(entryPrice, _Digits) + " (" + tagUsed + ")";
            bearState = S_RETRACE_DONE;
           }
         else if(lastAlertBarTime_Sell != time[rates_total-1] && (!htfOk || !cooldownOk))
           {
            if(!htfOk)
               Print("SELL signal suppressed: HTF trend does not confirm bearish bias.");
            if(!cooldownOk)
               Print("SELL signal suppressed: cooldown period active.");
            bearState = S_RETRACE_DONE;
           }
        }
     }

   if(bearState==S_RETRACE_DONE || bearState==S_HH1 || bearState==S_BREAK)
     {
      if(candHH2.time > sHH2.time)
         bearState = S_NONE;
     }
  }

int FindBearishRetraceCandle(const datetime &time[], const double &open[], const double &high[],
                              const double &low[], const double &close[], int rates_total,
                              datetime fromTime, datetime toTime)
  {
   int startIdx=-1, endIdx=-1;
   for(int i=0;i<rates_total;i++)
     {
      if(time[i]==fromTime) startIdx=i;
      if(time[i]==toTime)   endIdx=i;
     }
   if(startIdx<0 || endIdx<0 || endIdx<=startIdx)
      return -1;

   int engulfedIdx=-1;
   for(int i=endIdx-1;i>startIdx;i--)
     {
      bool bearish = close[i]<open[i];
      if(bearish && i+1<=endIdx)
        {
         bool nextBullish = close[i+1]>open[i+1];
         bool engulf = nextBullish && open[i+1]<=close[i] && close[i+1]>=open[i];
         if(nextBullish && engulf)
           {
            engulfedIdx = i;
            break;
           }
        }
     }
   if(engulfedIdx>=0)
      return engulfedIdx;

   for(int i=endIdx-1;i>startIdx;i--)
     {
      if(close[i]<open[i])
         return i;
     }
   return -1;
  }

//+------------------------------------------------------------------+
//| PART 2: Supply / Demand zones from consecutive highs/lows          |
//+------------------------------------------------------------------+
void DrawSupplyDemandZones(int rates_total, const datetime &time[], const double &high[], const double &low[])
  {
   SwingPoint lows[], highs[];
   int nl = GetLastSwings(false, lows, ConsecutiveCount);
   int nh = GetLastSwings(true,  highs, ConsecutiveCount);

   if(nl>=2)
     {
      bool consecutiveRising=true;
      for(int i=1;i<nl;i++)
         if(lows[i].price <= lows[i-1].price) consecutiveRising=false;
      if(consecutiveRising)
        {
         DrawTrendLine("DEMAND_ZONE", lows[0].time, lows[0].price, lows[nl-1].time, lows[nl-1].price, DemandColor);
        }
     }

   if(nh>=2)
     {
      bool consecutiveFalling=true;
      for(int i=1;i<nh;i++)
         if(highs[i].price >= highs[i-1].price) consecutiveFalling=false;
      if(consecutiveFalling)
        {
         DrawTrendLine("SUPPLY_ZONE", highs[0].time, highs[0].price, highs[nh-1].time, highs[nh-1].price, SupplyColor);
        }
     }
  }

//+------------------------------------------------------------------+
//| Drawing helpers                                                    |
//+------------------------------------------------------------------+
void DrawLabel(string key, datetime t, double price, string txt, color clr, int arrowDir)
  {
   string name = ObjPrefix + key;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   else
      ObjectMove(0, name, 0, t, price + (arrowDir>0? 10*_Point : -10*_Point));
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, arrowDir>0? ANCHOR_BOTTOM: ANCHOR_TOP);
  }

void DrawTrendLine(string key, datetime t1, double p1, datetime t2, double p2, color clr)
  {
   string name = ObjPrefix + key;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   else
     {
      ObjectMove(0, name, 0, t1, p1);
      ObjectMove(0, name, 1, t2, p2);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
  }

//+------------------------------------------------------------------+
//| Dashboard panel                                                    |
//+------------------------------------------------------------------+
void DashLabel(string key, int x, int y, string text, color clr, int fontSize=9)
  {
   string name = ObjPrefix + "DASH_" + key;
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
     }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
  }

void DashBackground(int x, int y, int width, int height)
  {
   string name = ObjPrefix + "DASH_BG";
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
     }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x-5);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y-5);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, DashboardBgColor);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
  }

string BullStateToString(BullState s)
  {
   switch(s)
     {
      case B_NONE:         return "None";
      case B_LL2:          return "LL2 detected";
      case B_LH2:          return "LH2 detected";
      case B_LL1:          return "LL2-LH2-LL1 formed";
      case B_BREAK:        return "CHOCH/BOS broken";
      case B_RETRACE_DONE: return "Signal fired";
     }
   return "Unknown";
  }

string BearStateToString(BearState s)
  {
   switch(s)
     {
      case S_NONE:         return "None";
      case S_HH2:          return "HH2 detected";
      case S_HL2:          return "HL2 detected";
      case S_HH1:          return "HH2-HL2-HH1 formed";
      case S_BREAK:        return "CHOCH/BOS broken";
      case S_RETRACE_DONE: return "Signal fired";
     }
   return "Unknown";
  }

void UpdateDashboard()
  {
   int x = DashboardX;
   int y = DashboardY;
   int lineH = 16;

   DashBackground(x, y, 260, lineH*8 + 10);

   DashLabel("TITLE", x, y, "=== SMC Structure Panel ===", clrGold, 10);
   y += lineH;

   string trendStr = (currentTrend==TREND_BULLISH) ? "BULLISH" : (currentTrend==TREND_BEARISH) ? "BEARISH" : "NONE";
   color trendClr  = (currentTrend==TREND_BULLISH) ? BullColor : (currentTrend==TREND_BEARISH) ? BearColor : clrSilver;
   DashLabel("TREND", x, y, "Trend Context: " + trendStr, trendClr);
   y += lineH;

   DashLabel("BULLSTATE", x, y, "Bull State: " + BullStateToString(bullState), BullColor);
   y += lineH;

   DashLabel("BEARSTATE", x, y, "Bear State: " + BearStateToString(bearState), BearColor);
   y += lineH;

   DashLabel("LASTSIGNAL", x, y, "Last Signal: " + lastSignalText, DashboardTextColor);
   y += lineH;

   int buyCooldownLeft  = lastBuyAlertTime==0 ? 0 : (int)MathMax(0, CooldownMinutes - (TimeCurrent()-lastBuyAlertTime)/60);
   int sellCooldownLeft = lastSellAlertTime==0 ? 0 : (int)MathMax(0, CooldownMinutes - (TimeCurrent()-lastSellAlertTime)/60);
   DashLabel("COOLDOWN", x, y, StringFormat("Cooldown (min) Buy:%d Sell:%d", buyCooldownLeft, sellCooldownLeft), DashboardTextColor);
   y += lineH;

   string htfStr = EnableHTFConfirm ? EnumToString(HTF_Timeframe) : "Disabled";
   DashLabel("HTF", x, y, "HTF Confirm: " + htfStr, DashboardTextColor);
   y += lineH;

   string tradeStr = activeTradeExists ? StringFormat("%s active | SL:%.5f", activeTradeIsBuy?"BUY":"SELL", activeCurrentSL) : "No active visual trade";
   DashLabel("TRADE", x, y, "Trailing: " + tradeStr, DashboardTextColor);
  }

//+------------------------------------------------------------------+
//| Alerts: MT5 push notification + Telegram                          |
//+------------------------------------------------------------------+
void SendAlert(string message)
  {
   Alert(message);
   Print(message);

   if(EnablePush)
      SendNotification(message);

   if(EnableTelegram)
      SendTelegramMessage(message);
  }

void SendTelegramMessage(string message)
  {
   if(TelegramToken=="" || TelegramChatID=="" ||
      TelegramToken=="YOUR_BOT_TOKEN_HERE" || TelegramChatID=="YOUR_CHAT_ID_HERE")
     {
      Print("Telegram not configured - skipping message send.");
      return;
     }

   string url = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage";
   string encodedMsg = UrlEncode(message);
   string params = "chat_id=" + TelegramChatID + "&text=" + encodedMsg;

   char postData[];
   StringToCharArray(params, postData, 0, StringLen(params));
   char result[];
   string resultHeaders;

   int res = WebRequest("POST", url, "Content-Type: application/x-www-form-urlencoded\r\n",
                         5000, postData, result, resultHeaders);
   if(res==-1)
      Print("Telegram WebRequest failed. Error: ", GetLastError(),
            " -- Ensure https://api.telegram.org is whitelisted in Tools->Options->Expert Advisors.");
   else
      Print("Telegram message sent, HTTP code: ", res);
  }

string UrlEncode(string text)
  {
   string result="";
   int len=StringLen(text);
   for(int i=0;i<len;i++)
     {
      ushort ch = StringGetCharacter(text,i);
      if((ch>='A'&&ch<='Z')||(ch>='a'&&ch<='z')||(ch>='0'&&ch<='9')||ch=='-'||ch=='_'||ch=='.'||ch=='~')
         result += ShortToString(ch);
      else if(ch==' ')
         result += "%20";
      else if(ch=='\n')
         result += "%0A";
      else
        {
         result += StringFormat("%%%02X", ch);
        }
     }
   return result;
  }
