//+------------------------------------------------------------------+
//|  SMC_DemandZone_EA_20260804.mq5                                  |
//|  Smart Money Concept – Demand/Supply Zone EA                     |
//|  Magic Number : 20260804                                         |
//|  Copyright 2026, KAYBAMBODLABFX                                  |
//|  Version      : 1.0                                              |
//+------------------------------------------------------------------+
//
//  ─── STRATEGY SUMMARY ─────────────────────────────────────────────
//  Detects SMC demand/supply zones using two patterns:
//    Pattern A: LL2→LH2→LL1 + CHOCH/BOS + no-FVG retracement +
//               bullish rejection candle entry
//    Pattern B: same structure + allows 50%/61.8% Fib retracement;
//               entry fires immediately on retracement (no rejection
//               candle needed)
//  Multi-timeframe confluence: D1 bias, H4/H1 structure, M15/M5 entry.
//  Full risk management, dashboard, alerts, and adaptive learning.
//
//  ─── TELEGRAM SETUP ───────────────────────────────────────────────
//  To enable Telegram alerts:
//    1. Create a bot via @BotFather and copy the token.
//    2. Find your Chat ID (e.g. via @userinfobot).
//    3. In MT5: Tools → Options → Expert Advisors → Allow WebRequests
//       → add "https://api.telegram.org" to the whitelist.
//    4. Enter InpTelegramBotToken and InpTelegramChatID in EA inputs.
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX 2026"
#property link      "https://github.com/jetloo66-dot/KAYBAMBODLABFX"
#property version   "1.00"
#property description "SMC Demand/Supply Zone EA – Pattern A & B, MTF confluence"
#property strict

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| ENUMS                                                            |
//+------------------------------------------------------------------+
enum ENUM_LOSS_PERIOD { LOSS_MINUTES=0, LOSS_HOUR=1, LOSS_SESSION=2, LOSS_DAILY=3 };

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

// ── General ──────────────────────────────────────────────────────
input group "=== General ==="
input long   InpMagicNumber          = 20260804;    // Magic number
input string InpEAName               = "SMC_DemandZone_EA_20260804"; // EA display name
input int    InpSwingLookback        = 5;           // Swing detection lookback bars

// ── Timeframes ───────────────────────────────────────────────────
input group "=== Timeframes ==="
input ENUM_TIMEFRAMES InpTF_Trend    = PERIOD_D1;   // Trend/bias timeframe
input ENUM_TIMEFRAMES InpTF_H4       = PERIOD_H4;   // H4 structure timeframe
input ENUM_TIMEFRAMES InpTF_H1       = PERIOD_H1;   // H1 structure timeframe
input ENUM_TIMEFRAMES InpTF_M15      = PERIOD_M15;  // M15 entry timeframe
input ENUM_TIMEFRAMES InpTF_M5       = PERIOD_M5;   // M5 entry timeframe

// ── Confluence toggles ────────────────────────────────────────────
input group "=== Confluence ==="
input bool   InpUseDailyConfluence   = true;        // Require D1 bias confluence
input bool   InpUseH4Confluence      = true;        // Require H4 confluence
input bool   InpUseH1Confluence      = true;        // Require H1 confluence

// ── Lot sizing ───────────────────────────────────────────────────
input group "=== Lot Sizing ==="
input double InpLotSize              = 0.01;        // Fixed lot size
input bool   InpUseRiskPercentLotSizing = false;    // Use risk-% lot sizing
input double InpRiskPercent          = 1.0;         // Risk per trade (%)

// ── Risk / Trade management ───────────────────────────────────────
input group "=== Risk Management ==="
input double InpSLBufferPoints       = 10.0;        // SL buffer beyond zone (pts/pips)
input double InpRiskRewardRatio      = 3.0;         // Risk:Reward ratio
input double InpPartialTPRatio       = 1.0;         // Partial TP ratio (default 1:1)
input double InpPartialClosePercent  = 50.0;        // % of position to close at partial TP
input int    InpMaxOpenPositions     = 1;           // Max open positions per symbol
input string InpVolatileSymbols      = "XAUUSD,BTCUSD,ETHUSD,XAGUSD,US30,NAS100"; // Volatile symbols list

// ── Trailing stop ─────────────────────────────────────────────────
input group "=== Trailing Stop ==="
input bool   InpUseTrailingStop      = true;        // Use trailing stop
input double InpTrailingStartPoints  = 20.0;        // Points profit before trailing starts
input double InpTrailingStepPoints   = 5.0;         // Trailing step in points

// ── Break-even ───────────────────────────────────────────────────
input group "=== Break-Even ==="
input bool   InpUseBreakEven         = true;        // Use break-even
input double InpBreakEvenTriggerPoints = 15.0;      // Points profit to trigger BE
input double InpBreakEvenOffsetPoints  = 2.0;       // BE offset above entry (points)

// ── Daily profit target ───────────────────────────────────────────
input group "=== Daily Profit Target ==="
input bool   InpUseDailyProfitTarget = true;        // Enable daily profit target
input double InpDailyProfitTargetPercent = 60.0;    // Daily profit target (% of start balance)

// ── Loss limit ────────────────────────────────────────────────────
input group "=== Loss Limit ==="
input double InpLossLimitPercent     = 5.0;         // Loss limit (%)
input ENUM_LOSS_PERIOD InpLossLimitPeriod = LOSS_DAILY; // Loss limit period

// ── News filter ───────────────────────────────────────────────────
input group "=== News Filter ==="
input bool   InpAvoidNews            = true;        // Avoid trading during news
input int    InpNewsBufferMinutes    = 30;          // Minutes before/after news to block
input string InpManualNoTradeWindows = "";          // Manual no-trade windows (HH:MM-HH:MM,...)

// ── Alerts ───────────────────────────────────────────────────────
input group "=== Alerts ==="
input string InpTelegramBotToken     = "";          // Telegram bot token (blank = disabled)
input string InpTelegramChatID       = "";          // Telegram chat ID

// ── Adaptive learning ─────────────────────────────────────────────
input group "=== Adaptive Learning ==="
input bool   InpAdaptiveLearningEnabled  = false;   // Enable adaptive learning
input bool   InpAdaptiveLotScalingEnabled = false;  // Enable adaptive lot scaling
input double InpAdaptiveLotMinMultiplier = 0.5;     // Minimum lot multiplier
input double InpAdaptiveLotMaxMultiplier = 2.0;     // Maximum lot multiplier
input double InpAdaptiveMinWinRateFilter = 40.0;    // Min win-rate % to allow setup

//+------------------------------------------------------------------+
//| STRUCTS                                                          |
//+------------------------------------------------------------------+
struct SZoneStructure
{
   bool        detected;       // Valid structure detected
   int         patternType;    // 0=none,1=A,2=B
   bool        isBuySide;      // true=demand(buy), false=supply(sell)
   double      zoneLow;        // Zone lower boundary (LL1 for buy / HH1 for sell)
   double      zoneHigh;       // Zone upper boundary (LH2 for buy / HL2 for sell)
   double      ll2;            // LL2 price
   double      lh2;            // LH2 price
   double      ll1;            // LL1 price
   int         ll2Bar;         // Bar index of LL2
   int         lh2Bar;         // Bar index of LH2
   int         ll1Bar;         // Bar index of LL1
   bool        chochDetected;  // CHOCH detected (vs BOS)
   double      breakLevel;     // Close of CHOCH/BOS candle
   int         breakBar;       // Bar index of CHOCH/BOS candle
   double      retraceLevel;   // Retracement price level
   int         retraceBar;     // Bar index of retracement
   bool        confirmed;      // Entry confirmation met
   datetime    zoneTime;       // Time of zone formation
};

struct SAdaptiveStats
{
   int    tradesA;
   int    winsA;
   int    tradesB;
   int    winsB;
   double winRateA;
   double winRateB;
};

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade         g_trade;
SZoneStructure g_buyD1, g_buyH4, g_buyH1, g_buyM15, g_buyM5;
SZoneStructure g_selD1, g_selH4, g_selH1, g_selM15, g_selM5;
SAdaptiveStats g_adaptStats;

double  g_dailyStartBalance  = 0.0;
double  g_lossLimitStart     = 0.0;
datetime g_lossLimitStartTime = 0;
datetime g_sessionDate        = 0;

// New-bar timestamps per timeframe
datetime g_lastBarD1  = 0, g_lastBarH4 = 0, g_lastBarH1 = 0;
datetime g_lastBarM15 = 0, g_lastBarM5 = 0;

bool     g_tradingPaused     = false;  // Paused by daily target / loss limit
bool     g_partialDoneTicket[]; // track partial closes (dynamic per open position)

string   g_logFile = "SMC_DemandZone_TradeLog.csv";

//+------------------------------------------------------------------+
//| UTILITY: pip/point value aware of symbol type                   |
//+------------------------------------------------------------------+
double GetPipPointValue(const string sym)
{
   // Returns the monetary value of one pip/point in account currency per lot
   double pointSize = SymbolInfoDouble(sym, SYMBOL_POINT);
   int    digits    = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);

   // Volatile / crypto / metals – work in raw points
   if(IsVolatileSymbol(sym))
      return pointSize;

   // Standard forex: 5-digit broker → 1 pip = 10 points
   if(digits == 5 || digits == 3)
      return pointSize * 10.0;

   return pointSize;
}

bool IsVolatileSymbol(const string sym)
{
   string upper = sym;
   StringToUpper(upper);
   string list = InpVolatileSymbols;
   StringToUpper(list);
   string arr[];
   int n = StringSplit(list, ',', arr);
   for(int i = 0; i < n; i++)
   {
      StringTrimRight(arr[i]);
      StringTrimLeft(arr[i]);
      if(StringFind(upper, arr[i]) >= 0) return true;
   }
   return false;
}

// Convert points input to price distance
double PointsToPrice(const string sym, double pts)
{
   return pts * SymbolInfoDouble(sym, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| SWING DETECTION helpers                                          |
//+------------------------------------------------------------------+
bool IsSwingLow(const double &low[], int bar, int lookback)
{
   if(bar < lookback || bar >= ArraySize(low) - lookback) return false;
   for(int i = bar - lookback; i <= bar + lookback; i++)
   {
      if(i == bar) continue;
      if(i < 0 || i >= ArraySize(low)) return false;
      if(low[i] <= low[bar]) return false;
   }
   return true;
}

bool IsSwingHigh(const double &high[], int bar, int lookback)
{
   if(bar < lookback || bar >= ArraySize(high) - lookback) return false;
   for(int i = bar - lookback; i <= bar + lookback; i++)
   {
      if(i == bar) continue;
      if(i < 0 || i >= ArraySize(high)) return false;
      if(high[i] >= high[bar]) return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| FVG detection between two bars (buy side)                        |
//| Returns true if a bullish FVG exists in that range               |
//+------------------------------------------------------------------+
bool HasFVGInRange(const double &high[], const double &low[], int barFrom, int barTo)
{
   // barFrom > barTo in series-indexed arrays (series = bar 0 is latest)
   // FVG: candle[i-1].low > candle[i+1].high  (bullish gap)
   int start = MathMin(barFrom, barTo);
   int end   = MathMax(barFrom, barTo);
   if(end >= ArraySize(low) - 1) return false;
   for(int i = start + 1; i < end; i++)
   {
      if(i + 1 >= ArraySize(low)) break;
      if(low[i-1] > high[i+1]) return true; // bullish FVG
   }
   return false;
}

//+------------------------------------------------------------------+
//| Detect bullish rejection candle (pin bar or engulfing)           |
//+------------------------------------------------------------------+
bool IsBullishRejection(const double &open[], const double &high[],
                        const double &low[],  const double &close[], int bar)
{
   if(bar < 0 || bar >= ArraySize(open)) return false;
   double body  = MathAbs(close[bar] - open[bar]);
   double range = high[bar] - low[bar];
   if(range <= 0) return false;

   // Pin bar: lower wick >= 2/3 of total range, close > open (bullish)
   double lowerWick = open[bar] > close[bar] ? (close[bar] - low[bar]) : (open[bar] - low[bar]);
   if(lowerWick >= range * 0.6 && close[bar] > open[bar]) return true;

   // Bullish engulfing vs previous bar
   if(bar + 1 < ArraySize(open))
   {
      if(close[bar] > open[bar] &&           // current is bullish
         open[bar+1] > close[bar+1] &&        // previous is bearish
         close[bar] > open[bar+1] &&
         open[bar] <= close[bar+1])
         return true;
   }
   return false;
}

bool IsBearishRejection(const double &open[], const double &high[],
                         const double &low[],  const double &close[], int bar)
{
   if(bar < 0 || bar >= ArraySize(open)) return false;
   double range = high[bar] - low[bar];
   if(range <= 0) return false;

   double upperWick = close[bar] > open[bar] ? (high[bar] - close[bar]) : (high[bar] - open[bar]);
   if(upperWick >= range * 0.6 && close[bar] < open[bar]) return true;

   if(bar + 1 < ArraySize(open))
   {
      if(close[bar] < open[bar] &&
         open[bar+1] < close[bar+1] &&
         close[bar] < open[bar+1] &&
         open[bar] >= close[bar+1])
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| CORE: DetectStructure                                            |
//| Returns a populated SZoneStructure for the given symbol/TF/side  |
//+------------------------------------------------------------------+
SZoneStructure DetectStructure(const string sym, ENUM_TIMEFRAMES tf, bool isBuySide)
{
   SZoneStructure result = {};
   result.detected   = false;
   result.patternType = 0;
   result.isBuySide  = isBuySide;

   int lookback = InpSwingLookback;
   int barsNeeded = 200;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(sym, tf, 0, barsNeeded, rates);
   if(copied < lookback * 4 + 10) return result;

   double open[], high[], low[], close[];
   ArraySetAsSeries(open,  true);
   ArraySetAsSeries(high,  true);
   ArraySetAsSeries(low,   true);
   ArraySetAsSeries(close, true);

   // Fill arrays from rates
   int sz = copied;
   ArrayResize(open,  sz);
   ArrayResize(high,  sz);
   ArrayResize(low,   sz);
   ArrayResize(close, sz);
   for(int i = 0; i < sz; i++)
   {
      open[i]  = rates[i].open;
      high[i]  = rates[i].high;
      low[i]   = rates[i].low;
      close[i] = rates[i].close;
   }

   // ── Scan for structure sequence (newest first) ─────────────────
   // We search from bar 1 (last closed) outward; skip bar 0 (forming)
   // We need: LL2→LH2→LL1 for buy,  HH2→HL2→HH1 for sell
   // Arrays are series (bar 0 = newest), so LL1 is at a lower index than LL2

   // Find swing points
   int swingLows[];  int swingHighs[];
   ArrayResize(swingLows,  0);
   ArrayResize(swingHighs, 0);

   for(int i = lookback; i < sz - lookback; i++)
   {
      if(IsSwingLow(low, i, lookback))
      {
         int n = ArraySize(swingLows);
         ArrayResize(swingLows, n+1);
         swingLows[n] = i;
      }
      if(IsSwingHigh(high, i, lookback))
      {
         int n = ArraySize(swingHighs);
         ArrayResize(swingHighs, n+1);
         swingHighs[n] = i;
      }
   }

   int nSL = ArraySize(swingLows);
   int nSH = ArraySize(swingHighs);

   if(isBuySide)
   {
      // Need LL1 (most recent swing low) → LH2 (swing high between LL1 and LL2) → LL2 (older swing low)
      // In series index: LL1 at smaller index, LH2 in middle, LL2 at larger index
      // Iterate: for each pair of swing lows where lowIndex_LL1 < lowIndex_LL2
      for(int a = 0; a < nSL - 1 && !result.detected; a++)
      {
         int idxLL1 = swingLows[a];   // more recent
         int idxLL2 = swingLows[a+1]; // older
         double vLL1 = low[idxLL1];
         double vLL2 = low[idxLL2];
         if(vLL1 >= vLL2) continue;   // LL1 < LL2 required

         // Find LH2: a swing high between LL1 and LL2 (idxLL1 < idxLH2 < idxLL2)
         // and LH2 > LL2
         for(int b = 0; b < nSH; b++)
         {
            int idxLH2 = swingHighs[b];
            if(idxLH2 <= idxLL1 || idxLH2 >= idxLL2) continue;
            double vLH2 = high[idxLH2];
            if(vLH2 <= vLL2) continue; // LH2 > LL2 required (spec: LL2 < LH2)

            // Pattern found: LL2 → LH2 → LL1
            // STEP 2: Look for CHOCH/BOS — candle close above LH2, must be after LL1 (idxLL1 > index of break)
            int breakBar = -1;
            for(int k = idxLL1 - 1; k >= 1; k--) // more recent than LL1
            {
               if(close[k] > vLH2) { breakBar = k; break; }
            }
            if(breakBar < 0) continue;

            // STEP 3: Retracement into zone [vLL1, vLH2] after CHOCH/BOS
            // Find retracement bar after breakBar (closer to present, lower index)
            int retraceBar  = -1;
            double retraceLevel = 0.0;
            int patType = 0;

            for(int k = breakBar - 1; k >= 1; k--)
            {
               double midPrice = (low[k] + high[k]) / 2.0;
               bool inZone = (low[k] <= vLH2 && high[k] >= vLL1);

               if(inZone)
               {
                  // Pattern A: check for no-FVG retracement
                  // Simplified: find last bullish candle in [idxLL1..idxLH2] range
                  // engulfed by bearish candle — check candle k is within zone
                  // and there's no FVG from breakBar to k
                  bool noFVG = !HasFVGInRange(high, low, breakBar, k);
                  if(noFVG)
                  {
                     retraceBar   = k;
                     retraceLevel = close[k];
                     patType      = 1; // Pattern A candidate
                     break;
                  }

                  // Pattern B: 50% or 61.8% Fib retracement
                  double range50  = vLH2 - (vLH2 - vLL1) * 0.500;
                  double range618 = vLH2 - (vLH2 - vLL1) * 0.618;
                  if(low[k] <= range50 && high[k] >= range618)
                  {
                     retraceBar   = k;
                     retraceLevel = close[k];
                     patType      = 2; // Pattern B
                     break;
                  }
               }
            }

            if(retraceBar < 0 || patType == 0) continue;

            // STEP 4: Confirmation
            bool confirmed = false;
            if(patType == 1)
            {
               // Pattern A: need bullish rejection candle at/after retraceBar
               for(int k = retraceBar; k >= 1; k--)
               {
                  if(IsBullishRejection(open, high, low, close, k))
                  {
                     confirmed = true;
                     retraceBar = k;
                     retraceLevel = close[k];
                     break;
                  }
                  if(k < retraceBar - 5) break; // only look 5 bars ahead
               }
            }
            else
            {
               // Pattern B: immediate entry on retracement
               confirmed = true;
            }

            if(!confirmed) continue;

            result.detected    = true;
            result.patternType = patType;
            result.isBuySide   = true;
            result.zoneLow     = vLL1;
            result.zoneHigh    = vLH2;
            result.ll2         = vLL2;
            result.lh2         = vLH2;
            result.ll1         = vLL1;
            result.ll2Bar      = idxLL2;
            result.lh2Bar      = idxLH2;
            result.ll1Bar      = idxLL1;
            result.chochDetected = true; // simplified – treat as CHOCH
            result.breakLevel  = close[breakBar];
            result.breakBar    = breakBar;
            result.retraceLevel = retraceLevel;
            result.retraceBar  = retraceBar;
            result.confirmed   = confirmed;
            result.zoneTime    = rates[idxLL1].time;
            break;
         }
      }
   }
   else // Sell side (supply zone): mirror with HH2→HL2→HH1
   {
      for(int a = 0; a < nSH - 1 && !result.detected; a++)
      {
         int idxHH1 = swingHighs[a];   // more recent
         int idxHH2 = swingHighs[a+1]; // older
         double vHH1 = high[idxHH1];
         double vHH2 = high[idxHH2];
         if(vHH1 <= vHH2) continue; // HH1 > HH2 required

         for(int b = 0; b < nSL; b++)
         {
            int idxHL2 = swingLows[b];
            if(idxHL2 <= idxHH1 || idxHL2 >= idxHH2) continue;
            double vHL2 = low[idxHL2];
            if(vHL2 >= vHH2) continue; // HL2 < HH2 required

            // STEP 2: close below HL2
            int breakBar = -1;
            for(int k = idxHH1 - 1; k >= 1; k--)
            {
               if(close[k] < vHL2) { breakBar = k; break; }
            }
            if(breakBar < 0) continue;

            // STEP 3: retracement into zone [vHL2, vHH1]
            int retraceBar  = -1;
            double retraceLevel = 0.0;
            int patType = 0;

            for(int k = breakBar - 1; k >= 1; k--)
            {
               bool inZone = (high[k] >= vHL2 && low[k] <= vHH1);
               if(inZone)
               {
                  bool noFVG = !HasFVGInRange(high, low, breakBar, k);
                  if(noFVG)
                  {
                     retraceBar   = k;
                     retraceLevel = close[k];
                     patType      = 1;
                     break;
                  }

                  double range50  = vHL2 + (vHH1 - vHL2) * 0.500;
                  double range618 = vHL2 + (vHH1 - vHL2) * 0.618;
                  if(high[k] >= range50 && low[k] <= range618)
                  {
                     retraceBar   = k;
                     retraceLevel = close[k];
                     patType      = 2;
                     break;
                  }
               }
            }

            if(retraceBar < 0 || patType == 0) continue;

            bool confirmed = false;
            if(patType == 1)
            {
               for(int k = retraceBar; k >= 1; k--)
               {
                  if(IsBearishRejection(open, high, low, close, k))
                  {
                     confirmed    = true;
                     retraceBar   = k;
                     retraceLevel = close[k];
                     break;
                  }
                  if(k < retraceBar - 5) break;
               }
            }
            else confirmed = true;

            if(!confirmed) continue;

            result.detected    = true;
            result.patternType = patType;
            result.isBuySide   = false;
            result.zoneLow     = vHL2;
            result.zoneHigh    = vHH1;
            result.ll2         = vHH2; // reused fields: ll2=HH2, lh2=HL2, ll1=HH1
            result.lh2         = vHL2;
            result.ll1         = vHH1;
            result.ll2Bar      = idxHH2;
            result.lh2Bar      = idxHL2;
            result.ll1Bar      = idxHH1;
            result.chochDetected = true;
            result.breakLevel  = close[breakBar];
            result.breakBar    = breakBar;
            result.retraceLevel = retraceLevel;
            result.retraceBar  = retraceBar;
            result.confirmed   = confirmed;
            result.zoneTime    = rates[idxHH1].time;
            break;
         }
      }
   }

   return result;
}

//+------------------------------------------------------------------+
//| CHART DRAWING                                                    |
//+------------------------------------------------------------------+
void DrawZoneStructure(const string sym, ENUM_TIMEFRAMES tf,
                       const SZoneStructure &s, bool isBuy)
{
   if(!s.detected) return;

   string prefix = isBuy ? "SMC_B_" : "SMC_S_";
   prefix += EnumToString(tf) + "_";

   color zoneColor  = isBuy ? clrDodgerBlue : clrTomato;
   color lineColor  = isBuy ? clrDodgerBlue : clrOrangeRed;
   color labelColor = clrWhite;

   // Get bar times from the relevant timeframe
   datetime t2 = iTime(sym, tf, s.ll2Bar);
   datetime tH = iTime(sym, tf, s.lh2Bar);
   datetime t1 = iTime(sym, tf, s.ll1Bar);
   datetime tB = iTime(sym, tf, s.breakBar);
   datetime tR = iTime(sym, tf, s.retraceBar);
   datetime tNow = TimeCurrent() + PeriodSeconds(tf) * 3;

   // ── Zone rectangle ────────────────────────────────────────────
   string rectName = prefix + "Zone";
   ObjectDelete(0, rectName);
   ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, t1, s.zoneLow, tNow, s.zoneHigh);
   ObjectSetInteger(0, rectName, OBJPROP_COLOR,   zoneColor);
   ObjectSetInteger(0, rectName, OBJPROP_STYLE,   STYLE_DOT);
   ObjectSetInteger(0, rectName, OBJPROP_WIDTH,   1);
   ObjectSetInteger(0, rectName, OBJPROP_FILL,    true);
   ObjectSetInteger(0, rectName, OBJPROP_BACK,    true);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);

   // ── Zigzag lines: LL2→LH2→LL1→CHOCH/BOS→Retrace ─────────────
   string zz1 = prefix + "ZZ1";
   ObjectDelete(0, zz1);
   ObjectCreate(0, zz1, OBJ_TREND, 0, t2, (isBuy ? s.ll2 : s.ll2), tH, (isBuy ? s.lh2 : s.lh2));
   ObjectSetInteger(0, zz1, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, zz1, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, zz1, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, zz1, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, zz1, OBJPROP_SELECTABLE, false);

   string zz2 = prefix + "ZZ2";
   ObjectDelete(0, zz2);
   ObjectCreate(0, zz2, OBJ_TREND, 0, tH, (isBuy ? s.lh2 : s.lh2), t1, (isBuy ? s.ll1 : s.ll1));
   ObjectSetInteger(0, zz2, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, zz2, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, zz2, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, zz2, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, zz2, OBJPROP_SELECTABLE, false);

   string zz3 = prefix + "ZZ3";
   ObjectDelete(0, zz3);
   ObjectCreate(0, zz3, OBJ_TREND, 0, t1, (isBuy ? s.ll1 : s.ll1), tB, s.breakLevel);
   ObjectSetInteger(0, zz3, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, zz3, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, zz3, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, zz3, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, zz3, OBJPROP_SELECTABLE, false);

   if(tR != tB)
   {
      string zz4 = prefix + "ZZ4";
      ObjectDelete(0, zz4);
      ObjectCreate(0, zz4, OBJ_TREND, 0, tB, s.breakLevel, tR, s.retraceLevel);
      ObjectSetInteger(0, zz4, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, zz4, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, zz4, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, zz4, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, zz4, OBJPROP_SELECTABLE, false);
   }

   // ── Labels ────────────────────────────────────────────────────
   double lbl2Price = isBuy ? s.ll2  - SymbolInfoDouble(sym, SYMBOL_POINT) * 50 : s.ll2 + SymbolInfoDouble(sym, SYMBOL_POINT) * 50;
   double lblHPrice = isBuy ? s.lh2  + SymbolInfoDouble(sym, SYMBOL_POINT) * 50 : s.lh2 - SymbolInfoDouble(sym, SYMBOL_POINT) * 50;
   double lbl1Price = isBuy ? s.ll1  - SymbolInfoDouble(sym, SYMBOL_POINT) * 50 : s.ll1 + SymbolInfoDouble(sym, SYMBOL_POINT) * 50;

   CreateTextLabel(prefix + "Lbl2",  t2, lbl2Price, isBuy ? "1-LL2" : "1-HH2", labelColor);
   CreateTextLabel(prefix + "LblH",  tH, lblHPrice, isBuy ? "2-LH2" : "2-HL2", labelColor);
   CreateTextLabel(prefix + "Lbl1",  t1, lbl1Price, isBuy ? "3-LL1" : "3-HH1", labelColor);
   CreateTextLabel(prefix + "LblBOS",tB, s.breakLevel, s.chochDetected ? "CHOCH" : "BOS", clrYellow);
   CreateTextLabel(prefix + "LblRet",tR, s.retraceLevel, "Retrace", clrLime);
}

void CreateTextLabel(const string name, datetime t, double price,
                     const string txt, color clr)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetString(0,  name, OBJPROP_TEXT,      txt);
   ObjectSetInteger(0, name, OBJPROP_COLOR,     clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  8);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void DrawSLTP(const string sym, ulong ticket, double sl, double tp)
{
   string slName = "SMC_SL_" + IntegerToString((int)ticket);
   string tpName = "SMC_TP_" + IntegerToString((int)ticket);
   ObjectDelete(0, slName);
   ObjectDelete(0, tpName);

   datetime t1 = TimeCurrent();
   datetime t2 = t1 + 3600 * 24;

   ObjectCreate(0, slName, OBJ_TREND, 0, t1, sl, t2, sl);
   ObjectSetInteger(0, slName, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, slName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, slName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, slName, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, slName, OBJPROP_SELECTABLE, false);

   ObjectCreate(0, tpName, OBJ_TREND, 0, t1, tp, t2, tp);
   ObjectSetInteger(0, tpName, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, tpName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, tpName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, tpName, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, tpName, OBJPROP_SELECTABLE, false);
}

void RemoveSLTPLines(ulong ticket)
{
   ObjectDelete(0, "SMC_SL_" + IntegerToString((int)ticket));
   ObjectDelete(0, "SMC_TP_" + IntegerToString((int)ticket));
}

//+------------------------------------------------------------------+
//| DASHBOARD                                                        |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   string dName = "SMC_Dashboard";
   int x = 10, y = 20;
   int lineH = 16;
   int row = 0;

   double bal    = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double dailyPnlPct = (g_dailyStartBalance > 0) ?
                        (equity - g_dailyStartBalance) / g_dailyStartBalance * 100.0 : 0.0;

   int openPos = CountOpenPositions(_Symbol);

   string lines[];
   ArrayResize(lines, 12);
   lines[0]  = "═══ " + InpEAName + " ═══";
   lines[1]  = "Symbol  : " + _Symbol;
   lines[2]  = "Spread  : " + DoubleToString(spread / SymbolInfoDouble(_Symbol, SYMBOL_POINT), 1) + " pts";
   lines[3]  = "Pattern D1 : " + PatternStr(g_buyD1, g_selD1);
   lines[4]  = "Pattern H4 : " + PatternStr(g_buyH4, g_selH4);
   lines[5]  = "Pattern H1 : " + PatternStr(g_buyH1, g_selH1);
   lines[6]  = "Open Pos: " + IntegerToString(openPos);
   lines[7]  = "Daily P/L: " + DoubleToString(dailyPnlPct, 2) + "%";
   lines[8]  = "Target  : " + DoubleToString(InpDailyProfitTargetPercent, 1) + "%";
   lines[9]  = "Loss Lim: " + DoubleToString(InpLossLimitPercent, 1) + "%";
   lines[10] = "Trading : " + (g_tradingPaused ? "PAUSED" : "ACTIVE");
   lines[11] = "News    : " + (IsNewsTime() ? "BLOCKED" : "OK");

   for(int i = 0; i < ArraySize(lines); i++)
   {
      string nm = dName + IntegerToString(i);
      ObjectDelete(0, nm);
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, nm, OBJPROP_CORNER,  CORNER_LEFT_UPPER);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y + i * lineH);
      ObjectSetString(0,  nm, OBJPROP_TEXT,    lines[i]);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,   (i == 0) ? clrGold : clrWhite);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0,  nm, OBJPROP_FONT,    "Courier New");
      ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, nm, OBJPROP_BACK,    false);
   }
}

string PatternStr(const SZoneStructure &buy, const SZoneStructure &sel)
{
   string b = buy.detected ? (buy.patternType == 1 ? "BuyA" : "BuyB") : "-";
   string s = sel.detected ? (sel.patternType == 1 ? "SelA" : "SelB") : "-";
   return b + "/" + s;
}

//+------------------------------------------------------------------+
//| NEWS FILTER                                                      |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   if(!InpAvoidNews) return false;

   // 1) MQL5 economic calendar
   datetime now = TimeCurrent();
   datetime from = now - InpNewsBufferMinutes * 60;
   datetime to   = now + InpNewsBufferMinutes * 60;

   MqlCalendarValue calValues[];
   if(CalendarValueHistory(calValues, from, to, NULL, _Symbol) > 0)
   {
      for(int i = 0; i < ArraySize(calValues); i++)
      {
         if(calValues[i].impact_type == CALENDAR_IMPACT_HIGH)
            return true;
      }
   }

   // 2) Manual windows
   if(StringLen(InpManualNoTradeWindows) > 0)
   {
      string windows[];
      StringSplit(InpManualNoTradeWindows, ',', windows);
      MqlDateTime dt;
      TimeToStruct(now, dt);
      int nowMins = dt.hour * 60 + dt.min;

      for(int i = 0; i < ArraySize(windows); i++)
      {
         string parts[];
         StringTrimLeft(windows[i]);
         StringTrimRight(windows[i]);
         if(StringSplit(windows[i], '-', parts) == 2)
         {
            int startMins = ParseHHMM(parts[0]);
            int endMins   = ParseHHMM(parts[1]);
            if(nowMins >= startMins - InpNewsBufferMinutes &&
               nowMins <= endMins   + InpNewsBufferMinutes)
               return true;
         }
      }
   }
   return false;
}

int ParseHHMM(const string s)
{
   string p[];
   if(StringSplit(s, ':', p) == 2)
      return (int)StringToInteger(p[0]) * 60 + (int)StringToInteger(p[1]);
   return 0;
}

//+------------------------------------------------------------------+
//| RISK MANAGEMENT helpers                                          |
//+------------------------------------------------------------------+
int CountOpenPositions(const string sym)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == sym &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            count++;
      }
   }
   return count;
}

double CalcLotSize(const string sym, double slDistance)
{
   if(InpUseRiskPercentLotSizing && slDistance > 0)
   {
      double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskMoney = balance * InpRiskPercent / 100.0;
      double tickVal   = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
      if(tickVal <= 0 || tickSize <= 0) return InpLotSize;
      double lotsRaw   = riskMoney / (slDistance / tickSize * tickVal);
      double lotStep   = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
      double lotMin    = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
      double lotMax    = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
      double lots      = MathFloor(lotsRaw / lotStep) * lotStep;
      lots = MathMax(lotMin, MathMin(lotMax, lots));

      // Apply adaptive multiplier
      if(InpAdaptiveLearningEnabled && InpAdaptiveLotScalingEnabled)
         lots = ApplyAdaptiveMultiplier(lots, sym);

      return lots;
   }

   double lots = InpLotSize;
   if(InpAdaptiveLearningEnabled && InpAdaptiveLotScalingEnabled)
      lots = ApplyAdaptiveMultiplier(lots, sym);
   return lots;
}

double ApplyAdaptiveMultiplier(double lots, const string sym)
{
   // Use combined win rate from both patterns
   double totalTrades = g_adaptStats.tradesA + g_adaptStats.tradesB;
   if(totalTrades < 10) return lots; // not enough data

   double winRate = (g_adaptStats.winsA + g_adaptStats.winsB) / totalTrades * 100.0;
   if(winRate < InpAdaptiveMinWinRateFilter) return 0.0; // filter setup

   // Scale: 50% win rate → 1.0x, 70% → max, 30% → min
   double scale = (winRate - 50.0) / 20.0; // -1 to +1 roughly
   scale = MathMax(-1.0, MathMin(1.0, scale));
   double mult;
   if(scale >= 0)
      mult = 1.0 + scale * (InpAdaptiveLotMaxMultiplier - 1.0);
   else
      mult = 1.0 + scale * (1.0 - InpAdaptiveLotMinMultiplier);

   return lots * mult;
}

bool CheckDailyLimits()
{
   if(g_tradingPaused) return false;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   // Daily profit target
   if(InpUseDailyProfitTarget && g_dailyStartBalance > 0)
   {
      double pnlPct = (equity - g_dailyStartBalance) / g_dailyStartBalance * 100.0;
      if(pnlPct >= InpDailyProfitTargetPercent)
      {
         SendAlert("Daily profit target reached (" + DoubleToString(pnlPct, 2) + "%). Trading paused.");
         g_tradingPaused = true;
         return false;
      }
   }

   // Loss limit
   if(g_lossLimitStart > 0)
   {
      double lossPct = (g_lossLimitStart - equity) / g_lossLimitStart * 100.0;
      if(lossPct >= InpLossLimitPercent)
      {
         SendAlert("Loss limit reached (" + DoubleToString(lossPct, 2) + "%). Trading paused.");
         g_tradingPaused = true;
         return false;
      }
   }

   return true;
}

void ResetDailyTracking()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(IntegerToString(dt.year) + "." +
                                 IntegerToString(dt.mon)  + "." +
                                 IntegerToString(dt.day));
   if(today != g_sessionDate)
   {
      g_sessionDate       = today;
      g_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_lossLimitStart    = g_dailyStartBalance;
      g_tradingPaused     = false;
   }
}

//+------------------------------------------------------------------+
//| TRADE EXECUTION                                                  |
//+------------------------------------------------------------------+
void PlaceTrade(const string sym, bool isBuy,
                double entryPrice, double slPrice, double tpPrice,
                double lots, int patType, ENUM_TIMEFRAMES tf)
{
   if(CountOpenPositions(sym) >= InpMaxOpenPositions) return;

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(20);

   bool ok = false;
   if(isBuy)
      ok = g_trade.Buy(lots, sym, entryPrice, slPrice, tpPrice,
                       InpEAName + "_PatA=" + IntegerToString(patType));
   else
      ok = g_trade.Sell(lots, sym, entryPrice, slPrice, tpPrice,
                        InpEAName + "_PatA=" + IntegerToString(patType));

   if(ok)
   {
      ulong ticket = g_trade.ResultDeal();
      string msg = (isBuy ? "BUY" : "SELL") + " opened | " + sym +
                   " | Lots=" + DoubleToString(lots, 2) +
                   " | SL=" + DoubleToString(slPrice, _Digits) +
                   " | TP=" + DoubleToString(tpPrice, _Digits) +
                   " | Pat=" + IntegerToString(patType) +
                   " | TF=" + EnumToString(tf);
      SendAlert(msg);
      DrawSLTP(sym, ticket, slPrice, tpPrice);
   }
   else
   {
      Print("Trade failed: ", g_trade.ResultRetcodeDescription());
   }
}

void ManageOpenTrades(const string sym)
{
   double point = SymbolInfoDouble(sym, SYMBOL_POINT);
   double bid   = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask   = SymbolInfoDouble(sym, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != sym) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;

      ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice  = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL      = PositionGetDouble(POSITION_SL);
      double curTP      = PositionGetDouble(POSITION_TP);
      double volume     = PositionGetDouble(POSITION_VOLUME);
      double profit     = PositionGetDouble(POSITION_PROFIT);

      double curPrice   = (pType == POSITION_TYPE_BUY) ? bid : ask;
      double priceDiff  = (pType == POSITION_TYPE_BUY) ?
                          (curPrice - openPrice) : (openPrice - curPrice);
      double ptsProfit  = priceDiff / point;

      g_trade.SetExpertMagicNumber(InpMagicNumber);

      // ── Break-even ────────────────────────────────────────────
      if(InpUseBreakEven && ptsProfit >= InpBreakEvenTriggerPoints)
      {
         double beLevel = (pType == POSITION_TYPE_BUY) ?
                          openPrice + InpBreakEvenOffsetPoints * point :
                          openPrice - InpBreakEvenOffsetPoints * point;
         bool needMove = (pType == POSITION_TYPE_BUY && curSL < beLevel) ||
                         (pType == POSITION_TYPE_SELL && curSL > beLevel);
         if(needMove && g_trade.PositionModify(ticket, beLevel, curTP))
         {
            SendAlert("Break-even activated | " + sym + " | T#" + IntegerToString((int)ticket));
            DrawSLTP(sym, ticket, beLevel, curTP);
         }
      }

      // ── Trailing stop ─────────────────────────────────────────
      if(InpUseTrailingStop && ptsProfit >= InpTrailingStartPoints)
      {
         double newSL;
         if(pType == POSITION_TYPE_BUY)
         {
            newSL = curPrice - InpTrailingStepPoints * point;
            if(newSL > curSL)
            {
               if(g_trade.PositionModify(ticket, newSL, curTP))
                  DrawSLTP(sym, ticket, newSL, curTP);
            }
         }
         else
         {
            newSL = curPrice + InpTrailingStepPoints * point;
            if(newSL < curSL || curSL == 0)
            {
               if(g_trade.PositionModify(ticket, newSL, curTP))
                  DrawSLTP(sym, ticket, newSL, curTP);
            }
         }
      }

      // ── Partial TP ───────────────────────────────────────────
      double partialTPDist = (curTP - openPrice) * (InpPartialTPRatio / InpRiskRewardRatio);
      double partialTPLevel = (pType == POSITION_TYPE_BUY) ?
                              openPrice + partialTPDist :
                              openPrice - partialTPDist;
      bool partialHit = (pType == POSITION_TYPE_BUY && curPrice >= partialTPLevel) ||
                        (pType == POSITION_TYPE_SELL && curPrice <= partialTPLevel);

      // Simple partial: check comment for "partial_done" flag
      string comment = PositionGetString(POSITION_COMMENT);
      if(partialHit && StringFind(comment, "partial_done") < 0)
      {
         double closeVol = NormalizeDouble(volume * InpPartialClosePercent / 100.0,
                           (int)MathRound(-MathLog10(SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP))));
         closeVol = MathMax(SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN), closeVol);
         if(closeVol < volume && g_trade.PositionClosePartial(ticket, closeVol))
         {
            SendAlert("Partial TP hit | " + sym + " | T#" + IntegerToString((int)ticket));
            // We can't easily update comment for remaining position in MT5 without
            // using a global variable. Use a global var keyed by ticket:
            GlobalVariableSet("SMC_PARTIAL_" + IntegerToString((int)ticket), 1.0);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| ALERTS                                                           |
//+------------------------------------------------------------------+
void SendAlert(const string msg)
{
   Print(InpEAName, " | ", msg);
   Alert(InpEAName + " | " + msg);

   if(TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
      SendNotification(InpEAName + ": " + msg);

   if(StringLen(InpTelegramBotToken) > 0 && StringLen(InpTelegramChatID) > 0)
      SendTelegram(msg);
}

void SendTelegram(const string msg)
{
   string url = "https://api.telegram.org/bot" + InpTelegramBotToken + "/sendMessage";
   string body = "chat_id=" + InpTelegramChatID +
                 "&text=" + InpEAName + "%3A+" + UrlEncode(msg);

   char   bodyArr[];
   char   respArr[];
   string respHdr;
   StringToCharArray(body, bodyArr, 0, StringLen(body));

   int res = WebRequest("POST", url, "Content-Type: application/x-www-form-urlencoded\r\n",
                        5000, bodyArr, respArr, respHdr);
   if(res < 0)
      Print("Telegram WebRequest failed: ", GetLastError(),
            " — ensure api.telegram.org is whitelisted in MT5 Options → Expert Advisors");
}

string UrlEncode(const string s)
{
   string result = "";
   for(int i = 0; i < StringLen(s); i++)
   {
      ushort c = StringGetCharacter(s, i);
      if((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
         (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~')
         result += ShortToString(c);
      else if(c == ' ')
         result += "+";
      else
         result += "%" + IntegerToString(c, 2, '0');
   }
   return result;
}

//+------------------------------------------------------------------+
//| ADAPTIVE LEARNING – CSV file I/O                                 |
//+------------------------------------------------------------------+
void LogTrade(int patType, ENUM_TIMEFRAMES tf, bool isBuy,
              bool d1Conf, bool h4Conf, bool h1Conf, double rMultiple)
{
   if(!InpAdaptiveLearningEnabled) return;

   int handle = FileOpen(g_logFile, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON | FILE_SHARE_WRITE | FILE_REWRITE);
   if(handle == INVALID_HANDLE) handle = FileOpen(g_logFile, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON);
   if(handle == INVALID_HANDLE) { Print("Cannot open log file"); return; }
   // Append: we reopen to append
   FileClose(handle);

   handle = FileOpen(g_logFile, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON | FILE_SHARE_WRITE);
   if(handle == INVALID_HANDLE) return;
   FileSeek(handle, 0, SEEK_END);
   FileWrite(handle,
             TimeToString(TimeCurrent()),
             IntegerToString(patType),
             EnumToString(tf),
             isBuy ? "BUY" : "SELL",
             d1Conf ? "1" : "0",
             h4Conf ? "1" : "0",
             h1Conf ? "1" : "0",
             DoubleToString(rMultiple, 3));
   FileClose(handle);
}

void LoadAdaptiveStats()
{
   if(!InpAdaptiveLearningEnabled) return;

   g_adaptStats.tradesA = 0; g_adaptStats.winsA = 0;
   g_adaptStats.tradesB = 0; g_adaptStats.winsB = 0;

   int handle = FileOpen(g_logFile, FILE_READ | FILE_CSV | FILE_ANSI | FILE_COMMON | FILE_SHARE_READ);
   if(handle == INVALID_HANDLE) return;

   while(!FileIsEnding(handle))
   {
      string dateStr  = FileReadString(handle);
      string patStr   = FileReadString(handle);
      string tfStr    = FileReadString(handle);
      string dirStr   = FileReadString(handle);
      string d1Str    = FileReadString(handle);
      string h4Str    = FileReadString(handle);
      string h1Str    = FileReadString(handle);
      string rMulStr  = FileReadString(handle);

      int pat     = (int)StringToInteger(patStr);
      double rMul = StringToDouble(rMulStr);
      bool   win  = (rMul > 0);

      if(pat == 1) { g_adaptStats.tradesA++; if(win) g_adaptStats.winsA++; }
      else if(pat == 2) { g_adaptStats.tradesB++; if(win) g_adaptStats.winsB++; }
   }
   FileClose(handle);

   g_adaptStats.winRateA = (g_adaptStats.tradesA > 0) ?
                           (double)g_adaptStats.winsA / g_adaptStats.tradesA * 100.0 : 0.0;
   g_adaptStats.winRateB = (g_adaptStats.tradesB > 0) ?
                           (double)g_adaptStats.winsB / g_adaptStats.tradesB * 100.0 : 0.0;

   Print("Adaptive stats loaded — PatA winRate=", DoubleToString(g_adaptStats.winRateA, 1),
         "% (", g_adaptStats.tradesA, " trades) | PatB winRate=",
         DoubleToString(g_adaptStats.winRateB, 1), "% (", g_adaptStats.tradesB, " trades)");
}

// Call when a trade closes to update the CSV with R-multiple
void OnTradeClose(ulong ticket)
{
   if(!InpAdaptiveLearningEnabled) return;

   if(!HistoryDealSelect(ticket)) return;
   double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
   double vol    = HistoryDealGetDouble(ticket, DEAL_VOLUME);
   if(vol <= 0) return;

   string sym    = HistoryDealGetString(ticket, DEAL_SYMBOL);
   double point  = SymbolInfoDouble(sym, SYMBOL_POINT);

   // Log simplified record – R-multiple sign only (no SL size readily available here)
   LogTrade(1, PERIOD_CURRENT, (HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BUY),
            InpUseDailyConfluence, InpUseH4Confluence, InpUseH1Confluence,
            profit > 0 ? 1.0 : -1.0);
}

//+------------------------------------------------------------------+
//| NEW BAR CHECK                                                    |
//+------------------------------------------------------------------+
bool IsNewBar(ENUM_TIMEFRAMES tf, datetime &lastTime)
{
   datetime t = iTime(_Symbol, tf, 0);
   if(t != lastTime)
   {
      lastTime = t;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| CHECK CONFLUENCE                                                  |
//+------------------------------------------------------------------+
bool CheckConfluence(bool isBuy)
{
   bool ok = true;

   if(InpUseDailyConfluence)
   {
      // D1: require bullish (buy) or bearish (sell) bias from structure
      if(isBuy)  ok = ok && g_buyD1.detected;
      else       ok = ok && g_selD1.detected;
   }
   if(InpUseH4Confluence)
   {
      if(isBuy)  ok = ok && g_buyH4.detected;
      else       ok = ok && g_selH4.detected;
   }
   if(InpUseH1Confluence)
   {
      if(isBuy)  ok = ok && g_buyH1.detected;
      else       ok = ok && g_selH1.detected;
   }
   return ok;
}

//+------------------------------------------------------------------+
//| TRY ENTRY                                                         |
//+------------------------------------------------------------------+
void TryEntry(const string sym, bool isBuy, const SZoneStructure &s, ENUM_TIMEFRAMES tf)
{
   if(!s.detected || !s.confirmed) return;
   if(!CheckConfluence(isBuy)) return;
   if(CountOpenPositions(sym) >= InpMaxOpenPositions) return;
   if(!CheckDailyLimits()) return;
   if(IsNewsTime())
   {
      Print("News block active — no trade");
      return;
   }

   // Adaptive filter
   if(InpAdaptiveLearningEnabled)
   {
      double wr = (s.patternType == 1) ? g_adaptStats.winRateA : g_adaptStats.winRateB;
      double trades = (s.patternType == 1) ? g_adaptStats.tradesA : g_adaptStats.tradesB;
      if(trades >= 10 && wr < InpAdaptiveMinWinRateFilter)
      {
         Print("Adaptive filter: win rate too low (", DoubleToString(wr, 1), "%) — skip");
         return;
      }
   }

   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   double buf = InpSLBufferPoints * pt;

   double sl, tp, entry;

   if(isBuy)
   {
      entry = SymbolInfoDouble(sym, SYMBOL_ASK);
      sl    = s.zoneLow - buf;
      double slDist = entry - sl;
      tp    = entry + slDist * InpRiskRewardRatio;
   }
   else
   {
      entry = SymbolInfoDouble(sym, SYMBOL_BID);
      sl    = s.zoneHigh + buf;
      double slDist = sl - entry;
      tp    = entry - slDist * InpRiskRewardRatio;
   }

   double slDist = MathAbs(entry - sl);
   double lots   = CalcLotSize(sym, slDist);
   if(lots <= 0) return;

   PlaceTrade(sym, isBuy, entry, sl, tp, lots, s.patternType, tf);
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   EventSetTimer(1);
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(20);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);

   g_dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_lossLimitStart    = g_dailyStartBalance;
   g_sessionDate       = 0; // will be reset on first tick

   LoadAdaptiveStats();

   Print(InpEAName, " initialized. Magic=", InpMagicNumber);
   SendAlert("EA started on " + _Symbol);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   // Remove all EA objects
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, "SMC_") == 0)
         ObjectDelete(0, name);
   }
   Comment("");
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   ResetDailyTracking();

   string sym = _Symbol;

   // Throttled structure recalculation per timeframe
   bool newD1  = IsNewBar(InpTF_Trend, g_lastBarD1);
   bool newH4  = IsNewBar(InpTF_H4,   g_lastBarH4);
   bool newH1  = IsNewBar(InpTF_H1,   g_lastBarH1);
   bool newM15 = IsNewBar(InpTF_M15,  g_lastBarM15);
   bool newM5  = IsNewBar(InpTF_M5,   g_lastBarM5);

   if(newD1)
   {
      g_buyD1 = DetectStructure(sym, InpTF_Trend, true);
      g_selD1 = DetectStructure(sym, InpTF_Trend, false);
      if(g_buyD1.detected) { SendAlert("D1 BUY structure detected"); DrawZoneStructure(sym, InpTF_Trend, g_buyD1, true); }
      if(g_selD1.detected) { SendAlert("D1 SELL structure detected"); DrawZoneStructure(sym, InpTF_Trend, g_selD1, false); }
   }
   if(newH4)
   {
      g_buyH4 = DetectStructure(sym, InpTF_H4, true);
      g_selH4 = DetectStructure(sym, InpTF_H4, false);
      if(g_buyH4.detected) { SendAlert("H4 BUY structure detected"); DrawZoneStructure(sym, InpTF_H4, g_buyH4, true); }
      if(g_selH4.detected) { SendAlert("H4 SELL structure detected"); DrawZoneStructure(sym, InpTF_H4, g_selH4, false); }
   }
   if(newH1)
   {
      g_buyH1 = DetectStructure(sym, InpTF_H1, true);
      g_selH1 = DetectStructure(sym, InpTF_H1, false);
      if(g_buyH1.detected) { SendAlert("H1 BUY structure detected"); DrawZoneStructure(sym, InpTF_H1, g_buyH1, true); }
      if(g_selH1.detected) { SendAlert("H1 SELL structure detected"); DrawZoneStructure(sym, InpTF_H1, g_selH1, false); }
   }
   if(newM15)
   {
      g_buyM15 = DetectStructure(sym, InpTF_M15, true);
      g_selM15 = DetectStructure(sym, InpTF_M15, false);
      DrawZoneStructure(sym, InpTF_M15, g_buyM15, true);
      DrawZoneStructure(sym, InpTF_M15, g_selM15, false);
      // Try entry from M15
      TryEntry(sym, true,  g_buyM15, InpTF_M15);
      TryEntry(sym, false, g_selM15, InpTF_M15);
   }
   if(newM5)
   {
      g_buyM5 = DetectStructure(sym, InpTF_M5, true);
      g_selM5 = DetectStructure(sym, InpTF_M5, false);
      DrawZoneStructure(sym, InpTF_M5, g_buyM5, true);
      DrawZoneStructure(sym, InpTF_M5, g_selM5, false);
      // Try entry from M5
      TryEntry(sym, true,  g_buyM5, InpTF_M5);
      TryEntry(sym, false, g_selM5, InpTF_M5);
   }

   // Always manage open trades (trailing/BE/partial) every tick
   ManageOpenTrades(sym);
}

//+------------------------------------------------------------------+
//| OnTimer – update dashboard every second                          |
//+------------------------------------------------------------------+
void OnTimer()
{
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| OnTradeTransaction – detect close events for adaptive learning   |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result_t)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      ulong dealTicket = trans.deal;
      if(HistoryDealSelect(dealTicket))
      {
         long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
         if(magic == InpMagicNumber)
         {
            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
            {
               OnTradeClose(dealTicket);
               ulong posTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
               RemoveSLTPLines(posTicket);
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
