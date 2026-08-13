#property copyright "Custom"
#property version   "1.00"
#property strict
#property description "SMC structure EA that mirrors SMC_StructureAlert logic and executes real trades"

#include <Trade/Trade.mqh>

input group "=== Structure Detection ==="
input int    SwingLeftBars      = 3;
input int    SwingRightBars     = 3;
input int    MaxSwingsStored    = 200;
input int    LookbackForZones   = 300;
input int    ConsecutiveCount   = 3;
input int    CooldownMinutes    = 30;
input string ObjPrefix          = "SMC_";
input bool   UseIndicatorObjectsIfAvailable = true;

enum ENUM_LOT_SIZING_MODE
  {
   LOT_FIXED = 0,
   LOT_RISK_PERCENT = 1
  };

input group "=== Trade Execution ==="
input ulong  MagicNumber        = 506613;
input ENUM_LOT_SIZING_MODE LotSizingMode = LOT_FIXED;
input double FixedLotSize       = 0.10;
input double RiskPercent        = 1.0;
input int    MaxSlippagePoints  = 20;

input group "=== Risk Management ==="
input double RiskRewardRatio    = 2.0;
input double SL_BufferPips      = 5.0;

input group "=== Partial Take-Profit Levels ==="
input bool   EnablePartialTPs   = true;
input double TP1_RR             = 1.0;
input double TP2_RR             = 2.0;
input double TP3_RR             = 3.0;
input double TP1_ClosePercent   = 33.0;
input double TP2_ClosePercent   = 50.0;

input group "=== Trailing Stop ==="
input bool   EnableTrailingSL   = true;
input double TrailStartRR       = 1.0;
input double TrailStepRR        = 0.5;

input group "=== Multi-Timeframe Confirmation ==="
input bool   EnableHTFConfirm   = true;
input ENUM_TIMEFRAMES HTF_Timeframe = PERIOD_H4;
input int    HTF_MA_Period      = 50;
input ENUM_MA_METHOD HTF_MA_Method = MODE_EMA;

input group "=== Alerts / Telegram ==="
input bool   EnablePush         = true;
input bool   EnableTelegram     = true;
input string TelegramToken      = "YOUR_BOT_TOKEN_HERE";
input string TelegramChatID     = "YOUR_CHAT_ID_HERE";

struct SwingPoint
  {
   datetime time;
   double   price;
   int      barIndex;
   bool     isHigh;
  };

struct SignalInfo
  {
   bool     valid;
   bool     isBuy;
   string   breakTag;
   double   entryPrice;
   double   structureSwingPrice;
   datetime signalBarTime;
   int      retraceIndex;
  };

struct TradeLevels
  {
   double sl;
   double tp1;
   double tp2;
   double tp3;
   double orderTp;
   double rDistance;
   bool   usedIndicatorObjects;
  };

struct PositionState
  {
   ulong    ticket;
   bool     tp1Done;
   bool     tp2Done;
   double   initialRisk;
   double   tp1Price;
   double   tp2Price;
   double   tp3Price;
   double   lastTrailAlertPrice;
   datetime lastTrailAlertTime;
   string   breakTag;
  };

enum BullState {B_NONE, B_LL2, B_LH2, B_LL1, B_BREAK, B_RETRACE_DONE};
enum BearState {S_NONE, S_HH2, S_HL2, S_HH1, S_BREAK, S_RETRACE_DONE};
enum TrendState {TREND_NONE, TREND_BULLISH, TREND_BEARISH};

CTrade trade;
SwingPoint swings[];
PositionState positionStates[];

BullState  bullState = B_NONE;
BearState  bearState = S_NONE;
TrendState currentTrend = TREND_NONE;

SwingPoint bLL2, bLH2, bLL1;
SwingPoint sHH2, sHL2, sHH1;

string bullBreakTag = "";
string bearBreakTag = "";

datetime lastProcessedBarTime = 0;
datetime lastBuyAlertTime = 0;
datetime lastSellAlertTime = 0;
datetime lastBuySignalBarTime = 0;
datetime lastSellSignalBarTime = 0;

int htfMAHandle = INVALID_HANDLE;

const int TRAIL_ALERT_THROTTLE_SECONDS = 30;

int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(MaxSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   ArrayResize(swings, 0);
   ArrayResize(positionStates, 0);

   if(EnableHTFConfirm)
     {
      htfMAHandle = iMA(_Symbol, HTF_Timeframe, HTF_MA_Period, 0, HTF_MA_Method, PRICE_CLOSE);
      if(htfMAHandle == INVALID_HANDLE)
         Print("Warning: Failed to create HTF MA handle. Multi-timeframe confirmation will be skipped.");
     }

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(htfMAHandle != INVALID_HANDLE)
      IndicatorRelease(htfMAHandle);
  }

void OnTick()
  {
   ManageOpenPositions();

   if(!IsNewBar())
      return;

   EvaluateNewBarSignals();
  }

bool IsNewBar()
  {
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == 0)
      return false;

   if(currentBarTime == lastProcessedBarTime)
      return false;

   lastProcessedBarTime = currentBarTime;
   return true;
  }

void EvaluateNewBarSignals()
  {
   MqlRates rates[];
   int barsToCopy = MathMax(MathMax(LookbackForZones + SwingLeftBars + SwingRightBars + 100, MaxSwingsStored * 4), 500);
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, barsToCopy, rates);
   if(copied <= SwingLeftBars + SwingRightBars + 5)
     {
      Print("Signal evaluation skipped: insufficient bar history loaded.");
      return;
     }

   ArraySetAsSeries(rates, false);

   SignalInfo buySignal;
   SignalInfo sellSignal;
   ResetSignal(buySignal);
   ResetSignal(sellSignal);

   ReplayStructureLogic(rates, copied, buySignal, sellSignal);

   if(buySignal.valid && sellSignal.valid)
     {
      Print("Signal evaluation suppressed: simultaneous BUY and SELL signals detected on the same bar.");
      return;
     }

   if(buySignal.valid)
      ExecuteSignal(buySignal);
   else if(sellSignal.valid)
      ExecuteSignal(sellSignal);
  }

void ResetSignal(SignalInfo &signal)
  {
   signal.valid = false;
   signal.isBuy = false;
   signal.breakTag = "";
   signal.entryPrice = 0.0;
   signal.structureSwingPrice = 0.0;
   signal.signalBarTime = 0;
   signal.retraceIndex = -1;
  }

void ResetStructureReplayState()
  {
   ArrayResize(swings, 0);
   bullState = B_NONE;
   bearState = S_NONE;
   currentTrend = TREND_NONE;
   bullBreakTag = "";
   bearBreakTag = "";
   bLL2.time = 0;
   bLH2.time = 0;
   bLL1.time = 0;
   sHH2.time = 0;
   sHL2.time = 0;
   sHH1.time = 0;
  }

// The indicator is stateful and only confirms swings once the right-side bars exist.
// To avoid logic drift when the EA starts mid-chart, the EA replays the same state
// machine over recent history on every new bar, then only allows a live trade signal
// on the final replay step.
void ReplayStructureLogic(const MqlRates &rates[], int totalBars, SignalInfo &buySignal, SignalInfo &sellSignal)
  {
   ResetStructureReplayState();

   int minimumBars = SwingLeftBars + SwingRightBars + 5;
   for(int barsAvailable = minimumBars; barsAvailable <= totalBars; barsAvailable++)
     {
      DetectSwings(rates, barsAvailable);

      bool allowSignal = (barsAvailable == totalBars);
      RunBullishStateMachine(rates, barsAvailable, allowSignal, buySignal);
      RunBearishStateMachine(rates, barsAvailable, allowSignal, sellSignal);
     }
  }

void DetectSwings(const MqlRates &rates[], int ratesTotal)
  {
   int checkIndex = ratesTotal - SwingRightBars - 1;
   if(checkIndex - SwingLeftBars < 0 || checkIndex + SwingRightBars >= ratesTotal)
      return;

   int n = ArraySize(swings);
   if(n > 0 && swings[n-1].time == rates[checkIndex].time)
      return;

   bool isHigh = true;
   bool isLow = true;
   double h = rates[checkIndex].high;
   double l = rates[checkIndex].low;

   for(int i = 1; i <= SwingLeftBars; i++)
     {
      if(rates[checkIndex - i].high > h)
         isHigh = false;
      if(rates[checkIndex - i].low < l)
         isLow = false;
     }

   for(int i = 1; i <= SwingRightBars; i++)
     {
      if(rates[checkIndex + i].high > h)
         isHigh = false;
      if(rates[checkIndex + i].low < l)
         isLow = false;
     }

   if(isHigh)
      AddSwing(rates[checkIndex].time, h, checkIndex, true);
   if(isLow)
      AddSwing(rates[checkIndex].time, l, checkIndex, false);
  }

void AddSwing(datetime t, double price, int idx, bool isHigh)
  {
   int n = ArraySize(swings);
   ArrayResize(swings, n + 1);
   swings[n].time = t;
   swings[n].price = price;
   swings[n].barIndex = idx;
   swings[n].isHigh = isHigh;

   if(ArraySize(swings) > MaxSwingsStored)
     {
      for(int i = 0; i < ArraySize(swings) - 1; i++)
         swings[i] = swings[i + 1];
      ArrayResize(swings, ArraySize(swings) - 1);
     }
  }

int GetLastSwings(bool wantHigh, SwingPoint &outArr[], int count)
  {
   int found = 0;
   ArrayResize(outArr, 0);
   SwingPoint tmp[];

   for(int i = ArraySize(swings) - 1; i >= 0 && found < count; i--)
     {
      if(swings[i].isHigh == wantHigh)
        {
         int sz = ArraySize(tmp);
         ArrayResize(tmp, sz + 1);
         tmp[sz] = swings[i];
         found++;
        }
     }

   int sz = ArraySize(tmp);
   ArrayResize(outArr, sz);
   for(int i = 0; i < sz; i++)
      outArr[i] = tmp[sz - 1 - i];
   return sz;
  }

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
   if(htfClose == 0.0)
      return true;

   bool htfBullish = htfClose > maBuf[1];
   bool htfBearish = htfClose < maBuf[1];
   return wantBullish ? htfBullish : htfBearish;
  }

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

void RunBullishStateMachine(const MqlRates &rates[], int ratesTotal, bool allowSignal, SignalInfo &signalOut)
  {
   SwingPoint lows[], highs[];
   int nl = GetLastSwings(false, lows, 3);
   int nh = GetLastSwings(true, highs, 2);
   if(nl < 3 || nh < 1)
      return;

   SwingPoint candLL2 = lows[0];
   SwingPoint candLL1 = lows[nl - 1];
   SwingPoint candLH2;
   bool foundLH2 = false;

   for(int i = ArraySize(swings) - 1; i >= 0; i--)
     {
      if(swings[i].isHigh && swings[i].time > candLL2.time && swings[i].time < candLL1.time)
        {
         candLH2 = swings[i];
         foundLH2 = true;
         break;
        }
     }

   if(!foundLH2)
      return;

   bool structureValid = (candLL2.price < candLH2.price) && (candLL1.price < candLL2.price);

   if(structureValid && bullState == B_NONE)
     {
      bLL2 = candLL2;
      bLH2 = candLH2;
      bLL1 = candLL1;
      bullState = B_LL1;
     }

   if(bullState == B_LL1)
     {
      int lastClosed = ratesTotal - 2;
      if(lastClosed >= 0 && rates[lastClosed].time > bLL1.time && rates[lastClosed].close > bLH2.price)
        {
         bullBreakTag = (currentTrend == TREND_BULLISH) ? "BOS" : "CHOCH";
         currentTrend = TREND_BULLISH;
         bullState = B_BREAK;
        }
     }

   if(bullState == B_BREAK)
     {
      int retraceIdx = FindBullishRetraceCandle(rates, ratesTotal, bLH2.time, bLL1.time);
      if(retraceIdx >= 0)
        {
         if(!allowSignal)
           {
            bullState = B_RETRACE_DONE;
           }
         else
           {
            bool htfOk = HTF_TrendAgrees(true);
            bool cooldownOk = CooldownPassed(true);
            datetime currentBarTime = rates[ratesTotal - 1].time;

            if(lastBuySignalBarTime != currentBarTime && htfOk && cooldownOk)
              {
               signalOut.valid = true;
               signalOut.isBuy = true;
               signalOut.breakTag = bullBreakTag;
               signalOut.entryPrice = rates[ratesTotal - 2].close;
               signalOut.structureSwingPrice = MathMin(bLL1.price, rates[retraceIdx].low);
               signalOut.signalBarTime = currentBarTime;
               signalOut.retraceIndex = retraceIdx;
               bullState = B_RETRACE_DONE;
              }
            else if(lastBuySignalBarTime != currentBarTime && (!htfOk || !cooldownOk))
              {
               if(!htfOk)
                  Print("BUY signal suppressed: HTF trend does not confirm bullish bias.");
               if(!cooldownOk)
                  Print("BUY signal suppressed: cooldown period active.");
               bullState = B_RETRACE_DONE;
              }
           }
        }
     }

   if(bullState == B_RETRACE_DONE || bullState == B_LL1 || bullState == B_BREAK)
     {
      if(candLL2.time > bLL2.time)
         bullState = B_NONE;
     }
  }

int FindBullishRetraceCandle(const MqlRates &rates[], int ratesTotal, datetime fromTime, datetime toTime)
  {
   int startIdx = -1;
   int endIdx = -1;
   for(int i = 0; i < ratesTotal; i++)
     {
      if(rates[i].time == fromTime)
         startIdx = i;
      if(rates[i].time == toTime)
         endIdx = i;
     }

   if(startIdx < 0 || endIdx < 0 || endIdx <= startIdx)
      return -1;

   int engulfedIdx = -1;
   for(int i = endIdx - 1; i > startIdx; i--)
     {
      bool bullish = rates[i].close > rates[i].open;
      if(bullish && i + 1 <= endIdx)
        {
         bool nextBearish = rates[i + 1].close < rates[i + 1].open;
         bool engulf = nextBearish && rates[i + 1].open >= rates[i].close && rates[i + 1].close <= rates[i].open;
         if(nextBearish && engulf)
           {
            engulfedIdx = i;
            break;
           }
        }
     }

   if(engulfedIdx >= 0)
      return engulfedIdx;

   for(int i = endIdx - 1; i > startIdx; i--)
     {
      if(rates[i].close > rates[i].open)
         return i;
     }

   return -1;
  }

void RunBearishStateMachine(const MqlRates &rates[], int ratesTotal, bool allowSignal, SignalInfo &signalOut)
  {
   SwingPoint highs[], lows[];
   int nh = GetLastSwings(true, highs, 3);
   int nl = GetLastSwings(false, lows, 1);
   if(nh < 3 || nl < 1)
      return;

   SwingPoint candHH2 = highs[0];
   SwingPoint candHH1 = highs[nh - 1];
   SwingPoint candHL2;
   bool foundHL2 = false;

   for(int i = ArraySize(swings) - 1; i >= 0; i--)
     {
      if(!swings[i].isHigh && swings[i].time > candHH2.time && swings[i].time < candHH1.time)
        {
         candHL2 = swings[i];
         foundHL2 = true;
         break;
        }
     }

   if(!foundHL2)
      return;

   bool structureValid = (candHH2.price > candHL2.price) && (candHH1.price > candHH2.price);

   if(structureValid && bearState == S_NONE)
     {
      sHH2 = candHH2;
      sHL2 = candHL2;
      sHH1 = candHH1;
      bearState = S_HH1;
     }

   if(bearState == S_HH1)
     {
      int lastClosed = ratesTotal - 2;
      if(lastClosed >= 0 && rates[lastClosed].time > sHH1.time && rates[lastClosed].close < sHL2.price)
        {
         bearBreakTag = (currentTrend == TREND_BEARISH) ? "BOS" : "CHOCH";
         currentTrend = TREND_BEARISH;
         bearState = S_BREAK;
        }
     }

   if(bearState == S_BREAK)
     {
      int retraceIdx = FindBearishRetraceCandle(rates, ratesTotal, sHL2.time, sHH1.time);
      if(retraceIdx >= 0)
        {
         if(!allowSignal)
           {
            bearState = S_RETRACE_DONE;
           }
         else
           {
            bool htfOk = HTF_TrendAgrees(false);
            bool cooldownOk = CooldownPassed(false);
            datetime currentBarTime = rates[ratesTotal - 1].time;

            if(lastSellSignalBarTime != currentBarTime && htfOk && cooldownOk)
              {
               signalOut.valid = true;
               signalOut.isBuy = false;
               signalOut.breakTag = bearBreakTag;
               signalOut.entryPrice = rates[ratesTotal - 2].close;
               signalOut.structureSwingPrice = MathMax(sHH1.price, rates[retraceIdx].high);
               signalOut.signalBarTime = currentBarTime;
               signalOut.retraceIndex = retraceIdx;
               bearState = S_RETRACE_DONE;
              }
            else if(lastSellSignalBarTime != currentBarTime && (!htfOk || !cooldownOk))
              {
               if(!htfOk)
                  Print("SELL signal suppressed: HTF trend does not confirm bearish bias.");
               if(!cooldownOk)
                  Print("SELL signal suppressed: cooldown period active.");
               bearState = S_RETRACE_DONE;
              }
           }
        }
     }

   if(bearState == S_RETRACE_DONE || bearState == S_HH1 || bearState == S_BREAK)
     {
      if(candHH2.time > sHH2.time)
         bearState = S_NONE;
     }
  }

int FindBearishRetraceCandle(const MqlRates &rates[], int ratesTotal, datetime fromTime, datetime toTime)
  {
   int startIdx = -1;
   int endIdx = -1;
   for(int i = 0; i < ratesTotal; i++)
     {
      if(rates[i].time == fromTime)
         startIdx = i;
      if(rates[i].time == toTime)
         endIdx = i;
     }

   if(startIdx < 0 || endIdx < 0 || endIdx <= startIdx)
      return -1;

   int engulfedIdx = -1;
   for(int i = endIdx - 1; i > startIdx; i--)
     {
      bool bearish = rates[i].close < rates[i].open;
      if(bearish && i + 1 <= endIdx)
        {
         bool nextBullish = rates[i + 1].close > rates[i + 1].open;
         bool engulf = nextBullish && rates[i + 1].open <= rates[i].close && rates[i + 1].close >= rates[i].open;
         if(nextBullish && engulf)
           {
            engulfedIdx = i;
            break;
           }
        }
     }

   if(engulfedIdx >= 0)
      return engulfedIdx;

   for(int i = endIdx - 1; i > startIdx; i--)
     {
      if(rates[i].close < rates[i].open)
         return i;
     }

   return -1;
  }

void ExecuteSignal(const SignalInfo &signal)
  {
   if(!CanTradeNow())
      return;

   if(CountManagedPositions() > 0)
     {
      Print((signal.isBuy ? "BUY" : "SELL"), " signal suppressed: an existing EA-managed position is already open on this symbol.");
      return;
     }

   TradeLevels levels;
   if(!BuildTradeLevels(signal, levels))
      return;

   double volume = CalculateTradeVolume(signal.entryPrice, levels.sl);
   if(volume <= 0.0)
     {
      Print("Trade execution suppressed: calculated volume is invalid.");
      return;
     }

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(freeMargin <= 0.0)
     {
      Print("Trade execution suppressed: free margin is invalid.");
      return;
     }

   double marginRequired = 0.0;
   ENUM_ORDER_TYPE orderType = signal.isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcMargin(orderType, _Symbol, volume, signal.entryPrice, marginRequired))
     {
      Print("Trade execution suppressed: OrderCalcMargin failed. Error: ", GetLastError());
      return;
     }
   if(marginRequired > freeMargin)
     {
      Print("Trade execution suppressed: insufficient free margin. Required=", DoubleToString(marginRequired, 2),
            " Free=", DoubleToString(freeMargin, 2));
      return;
     }

   string orderComment = StringFormat("SMC_%s_%s", signal.isBuy ? "BUY" : "SELL", signal.breakTag);
   double brokerTp = EnablePartialTPs ? levels.tp3 : levels.orderTp;
   bool opened = signal.isBuy ?
                 trade.Buy(volume, _Symbol, 0.0, levels.sl, brokerTp, orderComment) :
                 trade.Sell(volume, _Symbol, 0.0, levels.sl, brokerTp, orderComment);

   if(!opened)
     {
      Print("Trade execution failed. Retcode=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      return;
     }

   // The EA intentionally opens one position per symbol/magic and scales out with
   // PositionClosePartial rather than placing three separate entries. That keeps a
   // single broker-side SL/trailing stop to manage while still honoring TP1/TP2 scale-outs.
   ulong ticket = FindManagedPositionTicket(signal.isBuy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
   if(ticket == 0)
     {
      Print("Trade opened but position ticket lookup failed; partial TP tracking will not be available until the ticket is visible.");
     }
   else
     {
      RegisterPositionState(ticket, signal.breakTag, levels);
     }

   if(signal.isBuy)
      lastBuySignalBarTime = signal.signalBarTime;
   else
      lastSellSignalBarTime = signal.signalBarTime;

   UpdateCooldown(signal.isBuy);

   string msg = StringFormat("%s trade opened (%s)\nSymbol: %s  TF: %s\nEntry: %s\nSL: %s\nTP1: %s\nTP2: %s\nTP3/TP: %s\nVolume: %s\nLevel source: %s",
                             signal.isBuy ? "BUY" : "SELL",
                             signal.breakTag,
                             _Symbol,
                             EnumToString((ENUM_TIMEFRAMES)Period()),
                             DoubleToString(signal.entryPrice, _Digits),
                             DoubleToString(levels.sl, _Digits),
                             DoubleToString(levels.tp1, _Digits),
                             DoubleToString(levels.tp2, _Digits),
                             DoubleToString(EnablePartialTPs ? levels.tp3 : levels.orderTp, _Digits),
                             DoubleToString(volume, 2),
                             levels.usedIndicatorObjects ? "indicator objects" : "EA computed");
   SendAlert(msg);
  }

bool BuildTradeLevels(const SignalInfo &signal, TradeLevels &levels)
  {
   double buffer = SL_BufferPips * _Point;
   levels.usedIndicatorObjects = false;
   levels.sl = signal.isBuy ? signal.structureSwingPrice - buffer : signal.structureSwingPrice + buffer;
   levels.sl = NormalizePrice(levels.sl);
   RecalculateTargetsFromRisk(signal.isBuy, signal.entryPrice, levels);

   if(UseIndicatorObjectsIfAvailable)
      ApplyIndicatorObjectLevels(signal.isBuy, signal.entryPrice, levels);

   levels.rDistance = signal.isBuy ? signal.entryPrice - levels.sl : levels.sl - signal.entryPrice;
   if(levels.rDistance <= 0.0)
     {
      Print("Trade execution suppressed: indicator objects produced an invalid SL distance.");
      return false;
     }

   if(!ValidateDirectionalLevel(signal.isBuy, signal.entryPrice, levels.sl, false))
     {
      Print("Trade execution suppressed: stop loss is on the wrong side of entry.");
      return false;
     }

   double finalTarget = EnablePartialTPs ? levels.tp3 : levels.orderTp;
   if(!ValidateDirectionalLevel(signal.isBuy, signal.entryPrice, finalTarget, true))
     {
      Print("Trade execution suppressed: take-profit is on the wrong side of entry.");
      return false;
     }

   return true;
  }

void ApplyIndicatorObjectLevels(bool isBuy, double entryPrice, TradeLevels &levels)
  {
   string side = isBuy ? "BUY_" : "SELL_";
   double price = 0.0;

   if(TryGetIndicatorLinePrice(ObjPrefix + side + "SL", price) && ValidateDirectionalLevel(isBuy, entryPrice, price, false))
     {
      levels.sl = NormalizePrice(price);
      RecalculateTargetsFromRisk(isBuy, entryPrice, levels);
      levels.usedIndicatorObjects = true;
     }

   if(EnablePartialTPs)
     {
      if(TryGetIndicatorLinePrice(ObjPrefix + side + "TP1", price) && ValidateDirectionalLevel(isBuy, entryPrice, price, true))
        {
         levels.tp1 = NormalizePrice(price);
         levels.usedIndicatorObjects = true;
        }
      if(TryGetIndicatorLinePrice(ObjPrefix + side + "TP2", price) && ValidateDirectionalLevel(isBuy, entryPrice, price, true))
        {
         levels.tp2 = NormalizePrice(price);
         levels.usedIndicatorObjects = true;
        }
      if(TryGetIndicatorLinePrice(ObjPrefix + side + "TP3", price) && ValidateDirectionalLevel(isBuy, entryPrice, price, true))
        {
         levels.tp3 = NormalizePrice(price);
         levels.usedIndicatorObjects = true;
        }
     }
   else if(TryGetIndicatorLinePrice(ObjPrefix + side + "TP", price) && ValidateDirectionalLevel(isBuy, entryPrice, price, true))
     {
      levels.orderTp = NormalizePrice(price);
      levels.usedIndicatorObjects = true;
     }
  }

void RecalculateTargetsFromRisk(bool isBuy, double entryPrice, TradeLevels &levels)
  {
   levels.rDistance = isBuy ? entryPrice - levels.sl : levels.sl - entryPrice;

   levels.tp1 = isBuy ? entryPrice + levels.rDistance * TP1_RR : entryPrice - levels.rDistance * TP1_RR;
   levels.tp2 = isBuy ? entryPrice + levels.rDistance * TP2_RR : entryPrice - levels.rDistance * TP2_RR;
   levels.tp3 = isBuy ? entryPrice + levels.rDistance * TP3_RR : entryPrice - levels.rDistance * TP3_RR;
   levels.orderTp = isBuy ? entryPrice + levels.rDistance * RiskRewardRatio : entryPrice - levels.rDistance * RiskRewardRatio;

   levels.tp1 = NormalizePrice(levels.tp1);
   levels.tp2 = NormalizePrice(levels.tp2);
   levels.tp3 = NormalizePrice(levels.tp3);
   levels.orderTp = NormalizePrice(levels.orderTp);
  }

bool TryGetIndicatorLinePrice(const string objectName, double &price)
  {
   if(ObjectFind(0, objectName) < 0)
      return false;

   price = ObjectGetDouble(0, objectName, OBJPROP_PRICE);
   return (price > 0.0);
  }

bool ValidateDirectionalLevel(bool isBuy, double entryPrice, double levelPrice, bool wantProfitTarget)
  {
   if(levelPrice <= 0.0 || entryPrice <= 0.0)
      return false;

   if(isBuy)
      return wantProfitTarget ? (levelPrice > entryPrice) : (levelPrice < entryPrice);

   return wantProfitTarget ? (levelPrice < entryPrice) : (levelPrice > entryPrice);
  }

bool CanTradeNow()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Print("Trade execution suppressed: terminal trading is not allowed.");
      return false;
     }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      Print("Trade execution suppressed: Expert Advisor live trading is disabled.");
      return false;
     }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0.0 || bid <= 0.0)
     {
      Print("Trade execution suppressed: symbol pricing is unavailable.");
      return false;
     }

   return true;
  }

double CalculateTradeVolume(double entryPrice, double slPrice)
  {
   double volume = FixedLotSize;

   if(LotSizingMode == LOT_RISK_PERCENT)
     {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity <= 0.0)
        {
         Print("Risk-based volume calculation failed: account equity is invalid.");
         return 0.0;
        }

      double riskAmount = equity * RiskPercent / 100.0;
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double distance = MathAbs(entryPrice - slPrice);
      if(riskAmount <= 0.0 || tickSize <= 0.0 || tickValue <= 0.0 || distance <= 0.0)
        {
         Print("Risk-based volume calculation failed: invalid risk inputs or symbol trade properties.");
         return 0.0;
        }

      double lossPerLot = (distance / tickSize) * tickValue;
      if(lossPerLot <= 0.0)
        {
         Print("Risk-based volume calculation failed: loss per lot is invalid.");
         return 0.0;
        }

      volume = riskAmount / lossPerLot;
     }

   return NormalizeVolume(volume);
  }

double NormalizeVolume(double volume)
  {
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(minVolume <= 0.0 || maxVolume <= 0.0 || step <= 0.0)
      return 0.0;

   volume = MathMax(minVolume, MathMin(maxVolume, volume));
   volume = MathFloor(volume / step) * step;
   if(volume < minVolume)
      return 0.0;

   return NormalizeDouble(volume, VolumeDigits(step));
  }

int VolumeDigits(double step)
  {
   int digits = 0;
   while(digits < 8 && MathRound(step * MathPow(10.0, digits)) != step * MathPow(10.0, digits))
      digits++;
   return digits;
  }

double NormalizePrice(double price)
  {
   return NormalizeDouble(price, _Digits);
  }

int CountManagedPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         count++;
     }
   return count;
  }

ulong FindManagedPositionTicket(ENUM_POSITION_TYPE wantType)
  {
   ulong foundTicket = 0;
   datetime newestTime = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != wantType)
         continue;

      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      if(foundTicket == 0 || openTime >= newestTime)
        {
         newestTime = openTime;
         foundTicket = ticket;
        }
     }

   return foundTicket;
  }

void RegisterPositionState(ulong ticket, const string breakTag, const TradeLevels &levels)
  {
   int idx = FindPositionStateIndex(ticket);
   if(idx < 0)
     {
      idx = ArraySize(positionStates);
      ArrayResize(positionStates, idx + 1);
     }

   positionStates[idx].ticket = ticket;
   positionStates[idx].tp1Done = false;
   positionStates[idx].tp2Done = false;
   positionStates[idx].initialRisk = levels.rDistance;
   positionStates[idx].tp1Price = levels.tp1;
   positionStates[idx].tp2Price = levels.tp2;
   positionStates[idx].tp3Price = EnablePartialTPs ? levels.tp3 : levels.orderTp;
   positionStates[idx].lastTrailAlertPrice = 0.0;
   positionStates[idx].lastTrailAlertTime = 0;
   positionStates[idx].breakTag = breakTag;

   if(PositionSelectByTicket(ticket))
     {
      double liveOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      double liveSL = PositionGetDouble(POSITION_SL);
      if(liveOpen > 0.0 && liveSL > 0.0)
         positionStates[idx].initialRisk = MathAbs(liveOpen - liveSL);
     }
  }

int FindPositionStateIndex(ulong ticket)
  {
   for(int i = 0; i < ArraySize(positionStates); i++)
      if(positionStates[i].ticket == ticket)
         return i;
   return -1;
  }

void RemovePositionStateByIndex(int index)
  {
   int size = ArraySize(positionStates);
   if(index < 0 || index >= size)
      return;

   for(int i = index; i < size - 1; i++)
      positionStates[i] = positionStates[i + 1];
   ArrayResize(positionStates, size - 1);
  }

void SyncPositionStates()
  {
   for(int i = ArraySize(positionStates) - 1; i >= 0; i--)
     {
      if(positionStates[i].ticket == 0 || !PositionSelectByTicket(positionStates[i].ticket))
         RemovePositionStateByIndex(i);
     }
  }

void ManageOpenPositions()
  {
   SyncPositionStates();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      int stateIndex = FindPositionStateIndex(ticket);
      if(stateIndex < 0)
        {
         // TP milestone state is tracked in memory by position ticket during the EA
         // runtime so duplicate partial closes are prevented without polluting order comments.
         Print("Managed position found without in-memory TP state. Ticket=", ticket,
               ". Partial TP and trailing calculations require runtime state and will be skipped for this position.");
         continue;
        }

      HandlePartialTakeProfits(ticket, positionStates[stateIndex]);
      HandleTrailingStop(ticket, positionStates[stateIndex]);
     }
  }

void HandlePartialTakeProfits(ulong ticket, PositionState &state)
  {
   if(!EnablePartialTPs)
      return;

   if(!PositionSelectByTicket(ticket))
      return;

   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentVolume = PositionGetDouble(POSITION_VOLUME);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(currentVolume <= 0.0 || bid <= 0.0 || ask <= 0.0)
      return;

   if(!state.tp1Done && PriceReachedTarget(type, bid, ask, state.tp1Price))
     {
      double closeVolume = CalculatePartialCloseVolume(currentVolume, TP1_ClosePercent);
      if(closeVolume > 0.0 && trade.PositionClosePartial(ticket, closeVolume))
        {
         state.tp1Done = true;
         SendAlert(StringFormat("%s TP1 partial close\nSymbol: %s\nTicket: %I64u\nClosed volume: %s\nTarget: %s",
                                type == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                _Symbol,
                                ticket,
                                DoubleToString(closeVolume, 2),
                                DoubleToString(state.tp1Price, _Digits)));
        }
      else if(closeVolume <= 0.0)
        {
         Print("TP1 partial close skipped: calculated close volume is below broker minimum.");
         state.tp1Done = true;
        }
      else
        {
         Print("TP1 partial close failed. Retcode=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
        }
     }

   if(!PositionSelectByTicket(ticket))
      return;

   currentVolume = PositionGetDouble(POSITION_VOLUME);
   if(!state.tp2Done && state.tp1Done && PriceReachedTarget(type, bid, ask, state.tp2Price))
     {
      double closeVolume = CalculatePartialCloseVolume(currentVolume, TP2_ClosePercent);
      if(closeVolume > 0.0 && trade.PositionClosePartial(ticket, closeVolume))
        {
         state.tp2Done = true;
         SendAlert(StringFormat("%s TP2 partial close\nSymbol: %s\nTicket: %I64u\nClosed volume: %s\nTarget: %s",
                                type == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                _Symbol,
                                ticket,
                                DoubleToString(closeVolume, 2),
                                DoubleToString(state.tp2Price, _Digits)));
        }
      else if(closeVolume <= 0.0)
        {
         Print("TP2 partial close skipped: calculated close volume is below broker minimum.");
         state.tp2Done = true;
        }
      else
        {
         Print("TP2 partial close failed. Retcode=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
        }
     }
  }

double CalculatePartialCloseVolume(double currentVolume, double percentToClose)
  {
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(currentVolume <= 0.0 || percentToClose <= 0.0 || minVolume <= 0.0 || step <= 0.0)
      return 0.0;

   double closeVolume = currentVolume * percentToClose / 100.0;
   closeVolume = MathFloor(closeVolume / step) * step;
   closeVolume = NormalizeDouble(closeVolume, VolumeDigits(step));

   if(closeVolume < minVolume)
      return 0.0;

   double remaining = currentVolume - closeVolume;
   if(remaining > 0.0 && remaining < minVolume)
     {
      closeVolume = currentVolume - minVolume;
      closeVolume = MathFloor(closeVolume / step) * step;
      closeVolume = NormalizeDouble(closeVolume, VolumeDigits(step));
     }

   if(closeVolume <= 0.0 || closeVolume >= currentVolume)
      return 0.0;

   return closeVolume;
  }

bool PriceReachedTarget(ENUM_POSITION_TYPE type, double bid, double ask, double targetPrice)
  {
   if(targetPrice <= 0.0)
      return false;

   if(type == POSITION_TYPE_BUY)
      return bid >= targetPrice;

   return ask <= targetPrice;
  }

void HandleTrailingStop(ulong ticket, PositionState &state)
  {
   if(!EnableTrailingSL || state.initialRisk <= 0.0 || !PositionSelectByTicket(ticket))
      return;

   ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentPrice = (type == POSITION_TYPE_BUY) ? bid : ask;

   if(openPrice <= 0.0 || currentPrice <= 0.0)
      return;

   double favorableMove = (type == POSITION_TYPE_BUY) ? (currentPrice - openPrice) : (openPrice - currentPrice);
   double favorableR = favorableMove / state.initialRisk;
   if(favorableR < TrailStartRR || TrailStepRR <= 0.0)
      return;

   int steps = (int)MathFloor(favorableR / TrailStepRR);
   double lockedR = steps * TrailStepRR - TrailStartRR;
   if(lockedR < 0.0)
      lockedR = 0.0;

   double newSL = (type == POSITION_TYPE_BUY) ?
                  openPrice + lockedR * state.initialRisk :
                  openPrice - lockedR * state.initialRisk;

   if(!ClampStopToBrokerRules(type, bid, ask, newSL))
      return;

   bool improves = (type == POSITION_TYPE_BUY) ? (currentSL == 0.0 || newSL > currentSL) : (currentSL == 0.0 || newSL < currentSL);
   if(!improves)
      return;

   // Unlike the indicator's visual-only SL line, this path modifies the actual broker
   // stop on the live position and never moves the stop backwards.
   if(!trade.PositionModify(ticket, NormalizePrice(newSL), currentTP))
     {
      Print("Trailing stop update failed. Ticket=", ticket, " Retcode=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      return;
     }

   double normalizedSL = NormalizePrice(newSL);
   bool shouldAlert = (state.lastTrailAlertPrice != normalizedSL) &&
                      (state.lastTrailAlertTime == 0 || (TimeCurrent() - state.lastTrailAlertTime) >= TRAIL_ALERT_THROTTLE_SECONDS);
   if(shouldAlert)
     {
      SendAlert(StringFormat("%s trailing SL adjusted\nSymbol: %s\nTicket: %I64u\nNew SL: %s",
                             type == POSITION_TYPE_BUY ? "BUY" : "SELL",
                             _Symbol,
                             ticket,
                             DoubleToString(normalizedSL, _Digits)));
      state.lastTrailAlertPrice = normalizedSL;
      state.lastTrailAlertTime = TimeCurrent();
     }
  }

bool ClampStopToBrokerRules(ENUM_POSITION_TYPE type, double bid, double ask, double &stopPrice)
  {
   long stopLevelPoints = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freezeLevelPoints = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double minDistance = MathMax((double)stopLevelPoints, (double)freezeLevelPoints) * _Point;

   if(type == POSITION_TYPE_BUY)
     {
      if(bid <= 0.0)
         return false;
      double maxAllowed = bid - minDistance;
      if(stopPrice >= maxAllowed)
         stopPrice = maxAllowed;
      if(stopPrice <= 0.0 || stopPrice >= bid)
         return false;
     }
   else
     {
      if(ask <= 0.0)
         return false;
      double minAllowed = ask + minDistance;
      if(stopPrice <= minAllowed)
         stopPrice = minAllowed;
      if(stopPrice <= ask)
         return false;
     }

   stopPrice = NormalizePrice(stopPrice);
   return true;
  }

void SendAlert(const string message)
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
   if(TelegramToken == "" || TelegramChatID == "" ||
      TelegramToken == "YOUR_BOT_TOKEN_HERE" || TelegramChatID == "YOUR_CHAT_ID_HERE")
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
   if(res == -1)
      Print("Telegram WebRequest failed. Error: ", GetLastError(),
            " -- Ensure https://api.telegram.org is whitelisted in Tools->Options->Expert Advisors.");
   else
      Print("Telegram message sent, HTTP code: ", res);
  }

string UrlEncode(string text)
  {
   string result = "";
   int len = StringLen(text);
   for(int i = 0; i < len; i++)
     {
      ushort ch = StringGetCharacter(text, i);
      if((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '-' || ch == '_' || ch == '.' || ch == '~')
         result += ShortToString(ch);
      else if(ch == ' ')
         result += "%20";
      else if(ch == '\n')
         result += "%0A";
      else
         result += StringFormat("%%%02X", ch);
     }
   return result;
  }
