//+------------------------------------------------------------------+
//|                                                  SMC_AMD_EA.mq5 |
//|                         Smart Money Concepts — AMD Cycle EA     |
//|                         Author: jetloo66-dot / KAYBAMBODLABFX   |
//|                                                                  |
//|  Strategy: Accumulation → Manipulation → Distribution           |
//|  Entries via Fair Value Gap (FVG) or Order Block (OB)           |
//|  Trend filter via HTF swing-structure (HH/HL or LH/LL)          |
//+------------------------------------------------------------------+
#property copyright "jetloo66-dot / KAYBAMBODLABFX"
#property link      "https://github.com/jetloo66-dot/KAYBAMBODLABFX"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>          // CTrade class for order management

//+------------------------------------------------------------------+
//|  AMD Cycle State Machine                                         |
//+------------------------------------------------------------------+
enum ENUM_AMD_STATE
{
   STATE_IDLE,             // Waiting — no qualified trend yet
   STATE_TREND_CONFIRMED,  // HTF trend detected; looking for accumulation
   STATE_ACCUMULATION,     // Consolidation range identified; looking for manipulation
   STATE_MANIPULATION,     // Liquidity sweep detected; looking for FVG / OB entry
   STATE_ENTRY_READY,      // FVG or OB found; waiting for price to reach entry zone
   STATE_IN_TRADE          // Trade is active; managing position
};

//+------------------------------------------------------------------+
//|  Input Parameters                                                |
//+------------------------------------------------------------------+

// --- Timeframe Settings ---
input ENUM_TIMEFRAMES HTF_Timeframe         = PERIOD_H4;   // Higher timeframe for trend
input ENUM_TIMEFRAMES EntryTimeframe        = PERIOD_M15;  // Entry timeframe

// --- Accumulation Detection ---
input int    AccumulationBars              = 20;           // Bars to analyse for consolidation
input double AccumulationATRMultiplier     = 0.5;          // Range must be < ATR × this value
input int    ATR_Period                    = 14;           // ATR period

// --- Manipulation Detection ---
input double ManipulationPips              = 10.0;         // Min pip sweep beyond range
input int    ManipulationBars              = 5;            // Max bars for manipulation phase

// --- Entry Trigger Settings ---
input bool   UseFVG                        = true;         // Use Fair Value Gap entries
input bool   UseOrderBlock                 = true;         // Use Order Block entries
input int    FVG_LookbackBars              = 10;           // Bars to look back for FVG
input int    OB_LookbackBars               = 10;           // Bars to look back for Order Block

// --- Risk Management ---
input double RiskPercent                   = 1.0;          // Risk per trade (% of balance)
input double MinRiskReward                 = 2.0;          // Minimum Risk:Reward ratio
input double MaxSpreadPoints               = 30;           // Maximum allowed spread (points)
input int    MagicNumber                   = 123456;       // EA Magic Number
input int    MaxOpenTrades                 = 1;            // Max concurrent trades for this EA

// --- Stop Loss / Take Profit ---
input double SL_BufferPips                 = 5.0;          // SL buffer beyond manipulation level
input bool   UseTrailingSL                 = true;         // Enable trailing stop
input double TrailingSLPips                = 15.0;         // Trailing SL distance (pips)
input int    SlippagePoints                = 20;           // Slippage tolerance (points)

// --- Order Block Settings ---
input double OB_ImpulseATRMultiplier       = 0.8;          // Min impulse body as multiple of ATR for OB

// --- Session Filter ---
input bool   UseSessionFilter              = true;         // Enable session filter
input int    SessionStartHour              = 2;            // Session open (server time)
input int    SessionEndHour                = 17;           // Session close (server time)

// --- State Reset Safety ---
input int    MaxBarsInState                = 100;          // Max bars per state before reset

//+------------------------------------------------------------------+
//|  Global Variables                                                |
//+------------------------------------------------------------------+
CTrade        g_trade;                    // CTrade instance for order execution

ENUM_AMD_STATE g_state       = STATE_IDLE;
int            g_direction   = 0;         // 1 = long setup, -1 = short setup

// Accumulation range
double g_rangeHigh  = 0.0;
double g_rangeLow   = 0.0;

// Manipulation reference level
double g_manipLevel = 0.0;

// Entry zone (FVG or OB)
double g_entryHigh  = 0.0;               // Top of entry zone
double g_entryLow   = 0.0;               // Bottom of entry zone
double g_entryPrice = 0.0;               // Preferred entry (mid of zone)
double g_stopLoss   = 0.0;               // Calculated SL price
double g_takeProfit = 0.0;               // Calculated TP price

// Bar tracking (prevents multiple signals per bar)
datetime g_lastBarTime = 0;
datetime g_stateStartTime = 0;           // Time state was entered (for bar counting)

// Object name prefix for visual elements
const string OBJ_PREFIX = "SMC_";

//+------------------------------------------------------------------+
//|  OnInit — EA Initialisation                                      |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("SMC AMD EA initialised | Symbol: ", Symbol(),
         " | HTF: ", EnumToString(HTF_Timeframe),
         " | Entry TF: ", EnumToString(EntryTimeframe));

   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(SlippagePoints);

   // Use broker-supported filling mode (prefer IOC → FOK → Return)
   ENUM_ORDER_TYPE_FILLING fillMode = ORDER_FILLING_RETURN;
   long fillingModes = SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE);
   if((fillingModes & SYMBOL_FILLING_IOC) != 0)
      fillMode = ORDER_FILLING_IOC;
   if((fillingModes & SYMBOL_FILLING_FOK) != 0)
      fillMode = ORDER_FILLING_FOK;
   g_trade.SetTypeFilling(fillMode);

   // Reset state
   ResetState();
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|  OnDeinit — Clean up chart objects                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Remove all objects drawn by this EA
   ObjectsDeleteAll(0, OBJ_PREFIX);
   Print("SMC AMD EA removed. Reason code: ", reason);
}

//+------------------------------------------------------------------+
//|  OnTick — Main execution entry point                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Only run on new confirmed (closed) bar on the entry timeframe
   datetime currentBarTime = iTime(Symbol(), EntryTimeframe, 1);
   if(currentBarTime == g_lastBarTime) return;   // Same bar — skip
   g_lastBarTime = currentBarTime;

   // ---- Pre-checks ----
   if(!IsSessionActive()) return;         // Session filter
   if(IsSpreadTooHigh())  return;         // Spread filter

   // ---- State-machine timeout guard ----
   // Count how many entry-TF bars have elapsed since entering this state
   int barsInState = Bars(Symbol(), EntryTimeframe, g_stateStartTime, TimeCurrent());
   if(barsInState > MaxBarsInState && g_state != STATE_IN_TRADE)
   {
      Print("State timeout — resetting to IDLE (", EnumToString(g_state), ")");
      ResetState();
   }

   // ---- Run state machine ----
   switch(g_state)
   {
      case STATE_IDLE:
         RunStateIdle();
         break;
      case STATE_TREND_CONFIRMED:
         RunStateTrendConfirmed();
         break;
      case STATE_ACCUMULATION:
         RunStateAccumulation();
         break;
      case STATE_MANIPULATION:
         RunStateManipulation();
         break;
      case STATE_ENTRY_READY:
         RunStateEntryReady();
         break;
      case STATE_IN_TRADE:
         ManageOpenTrades();
         break;
   }
}

//+------------------------------------------------------------------+
//|  STATE: IDLE — look for a qualified HTF trend                    |
//+------------------------------------------------------------------+
void RunStateIdle()
{
   int trend = DetectTrend();
   if(trend != 0)
   {
      g_direction = trend;
      Print("Trend confirmed: ", (trend == 1 ? "UPTREND (BUY bias)" : "DOWNTREND (SELL bias)"));
      ChangeState(STATE_TREND_CONFIRMED);
   }
}

//+------------------------------------------------------------------+
//|  STATE: TREND CONFIRMED — look for accumulation on entry TF      |
//+------------------------------------------------------------------+
void RunStateTrendConfirmed()
{
   // Re-validate trend — invalidate if trend has reversed
   int trend = DetectTrend();
   if(trend == 0 || trend != g_direction)
   {
      Print("Trend invalidated — returning to IDLE");
      ResetState();
      return;
   }

   if(DetectAccumulation())
   {
      Print("Accumulation detected | Range: ", g_rangeLow, " — ", g_rangeHigh);
      DrawRangeLines();
      ChangeState(STATE_ACCUMULATION);
   }
}

//+------------------------------------------------------------------+
//|  STATE: ACCUMULATION — look for manipulation (liquidity sweep)   |
//+------------------------------------------------------------------+
void RunStateAccumulation()
{
   // Keep range valid — re-check trend
   int trend = DetectTrend();
   if(trend == 0 || trend != g_direction)
   {
      Print("Trend invalidated during accumulation — resetting");
      ResetState();
      return;
   }

   if(DetectManipulation())
   {
      Print("Manipulation detected | Direction: ", (g_direction == 1 ? "Sell-side sweep" : "Buy-side sweep"),
            " | Level: ", g_manipLevel);
      ChangeState(STATE_MANIPULATION);
   }
}

//+------------------------------------------------------------------+
//|  STATE: MANIPULATION — look for FVG or OB entry trigger          |
//+------------------------------------------------------------------+
void RunStateManipulation()
{
   bool entryFound = false;

   if(g_direction == 1)  // BUY setup
   {
      if(UseFVG && DetectBullishFVG())
      {
         Print("Bullish FVG found | Zone: ", g_entryLow, " — ", g_entryHigh);
         entryFound = true;
      }
      else if(UseOrderBlock && DetectBullishOB())
      {
         Print("Bullish OB found | Zone: ", g_entryLow, " — ", g_entryHigh);
         entryFound = true;
      }
   }
   else  // SELL setup
   {
      if(UseFVG && DetectBearishFVG())
      {
         Print("Bearish FVG found | Zone: ", g_entryLow, " — ", g_entryHigh);
         entryFound = true;
      }
      else if(UseOrderBlock && DetectBearishOB())
      {
         Print("Bearish OB found | Zone: ", g_entryLow, " — ", g_entryHigh);
         entryFound = true;
      }
   }

   if(entryFound)
   {
      g_entryPrice = (g_entryHigh + g_entryLow) / 2.0;
      CalculateSLTP();

      // Validate risk:reward after SL/TP calculation
      double rr = CalculateRR();
      if(rr < MinRiskReward)
      {
         Print("RR insufficient: ", DoubleToString(rr, 2), " < ", MinRiskReward, " — resetting state");
         ResetState();
         return;
      }

      ChangeState(STATE_ENTRY_READY);
   }
}

//+------------------------------------------------------------------+
//|  STATE: ENTRY_READY — wait for price to enter the entry zone     |
//+------------------------------------------------------------------+
void RunStateEntryReady()
{
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

   bool priceInZone = false;
   if(g_direction == 1)       // BUY: wait for ask to enter the bullish zone
      priceInZone = (ask >= g_entryLow && ask <= g_entryHigh);
   else                       // SELL: wait for bid to enter the bearish zone
      priceInZone = (bid >= g_entryLow && bid <= g_entryHigh);

   if(priceInZone)
   {
      ExecuteTrade();
   }
}

//+------------------------------------------------------------------+
//|  DETECT TREND — HTF swing structure analysis                     |
//|  Returns: 1 = uptrend, -1 = downtrend, 0 = unclear              |
//+------------------------------------------------------------------+
int DetectTrend()
{
   // Load recent HTF bars (need at least 50 to find swings)
   int barsNeeded = 50;
   MqlRates htfRates[];
   ArraySetAsSeries(htfRates, true);
   int copied = CopyRates(Symbol(), HTF_Timeframe, 1, barsNeeded, htfRates);
   if(copied < barsNeeded)
   {
      Print("DetectTrend: not enough HTF bars copied (", copied, ")");
      return 0;
   }

   // Find swing highs and swing lows (simple 3-bar pivot)
   double swingHighs[];
   double swingLows[];
   ArrayResize(swingHighs, 0);
   ArrayResize(swingLows, 0);

   for(int i = 2; i < copied - 2; i++)
   {
      // Swing high: bar i has higher high than its two neighbours on each side
      if(htfRates[i].high > htfRates[i-1].high && htfRates[i].high > htfRates[i-2].high &&
         htfRates[i].high > htfRates[i+1].high && htfRates[i].high > htfRates[i+2].high)
      {
         int sz = ArraySize(swingHighs);
         ArrayResize(swingHighs, sz + 1);
         swingHighs[sz] = htfRates[i].high;
      }
      // Swing low
      if(htfRates[i].low < htfRates[i-1].low && htfRates[i].low < htfRates[i-2].low &&
         htfRates[i].low < htfRates[i+1].low && htfRates[i].low < htfRates[i+2].low)
      {
         int sz = ArraySize(swingLows);
         ArrayResize(swingLows, sz + 1);
         swingLows[sz] = htfRates[i].low;
      }
   }

   int highCount = ArraySize(swingHighs);
   int lowCount  = ArraySize(swingLows);

   // Need at least 2 swings of each type to confirm structure
   if(highCount < 2 || lowCount < 2) return 0;

   // Check for uptrend: 2 consecutive Higher Highs and 2 consecutive Higher Lows
   bool hh = swingHighs[0] > swingHighs[1];     // Most recent swing high > previous (array is newest-first)
   bool hl = swingLows[0]  > swingLows[1];

   // Check for downtrend: 2 consecutive Lower Highs and 2 consecutive Lower Lows
   bool lh = swingHighs[0] < swingHighs[1];
   bool ll = swingLows[0]  < swingLows[1];

   if(hh && hl) return  1;   // Uptrend
   if(lh && ll) return -1;   // Downtrend
   return 0;
}

//+------------------------------------------------------------------+
//|  DETECT ACCUMULATION — low-volatility consolidation range        |
//|  Populates g_rangeHigh and g_rangeLow on success                 |
//+------------------------------------------------------------------+
bool DetectAccumulation()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), EntryTimeframe, 1, AccumulationBars, rates);
   if(copied < AccumulationBars)
   {
      Print("DetectAccumulation: insufficient bars");
      return false;
   }

   // Calculate ATR on the entry timeframe
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   int atrHandle = iATR(Symbol(), EntryTimeframe, ATR_Period);
   if(atrHandle == INVALID_HANDLE) return false;
   if(CopyBuffer(atrHandle, 0, 1, AccumulationBars, atrBuffer) < AccumulationBars)
   {
      IndicatorRelease(atrHandle);
      return false;
   }
   double currentATR = atrBuffer[0];
   IndicatorRelease(atrHandle);

   // Find range high and low over the accumulation window
   double rangeHigh = rates[0].high;
   double rangeLow  = rates[0].low;
   for(int i = 1; i < AccumulationBars; i++)
   {
      if(rates[i].high > rangeHigh) rangeHigh = rates[i].high;
      if(rates[i].low  < rangeLow)  rangeLow  = rates[i].low;
   }

   double rangeWidth = rangeHigh - rangeLow;

   // Consolidation condition: range width must be less than ATR × multiplier
   if(rangeWidth < currentATR * AccumulationATRMultiplier)
   {
      g_rangeHigh = rangeHigh;
      g_rangeLow  = rangeLow;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//|  DETECT MANIPULATION — false breakout / liquidity sweep          |
//|  For BUY: price sweeps below g_rangeLow then closes back above   |
//|  For SELL: price sweeps above g_rangeHigh then closes back below  |
//+------------------------------------------------------------------+
bool DetectManipulation()
{
   double pipValue = GetPipValue();
   double minSweep = ManipulationPips * pipValue;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int barsToLoad = ManipulationBars + 2;
   int copied = CopyRates(Symbol(), EntryTimeframe, 1, barsToLoad, rates);
   if(copied < 2) return false;

   for(int i = 0; i < MathMin(ManipulationBars, copied - 1); i++)
   {
      if(g_direction == 1)   // BUY setup — looking for sell-side sweep
      {
         // Candle wick went below range low by at least minSweep
         bool swept = (rates[i].low < g_rangeLow - minSweep);
         // Close is back inside or above the range (reversal confirmed)
         bool reversed = (rates[i].close >= g_rangeLow);
         if(swept && reversed)
         {
            g_manipLevel = rates[i].low;  // Lowest point of the sweep
            return true;
         }
      }
      else  // SELL setup — looking for buy-side sweep
      {
         bool swept   = (rates[i].high > g_rangeHigh + minSweep);
         bool reversed = (rates[i].close <= g_rangeHigh);
         if(swept && reversed)
         {
            g_manipLevel = rates[i].high;  // Highest point of the sweep
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  DETECT BULLISH FVG (Fair Value Gap)                             |
//|  Pattern: candle[2].high < candle[0].low (gap on entry TF)       |
//|  Array index 0 = most recent closed bar                         |
//+------------------------------------------------------------------+
bool DetectBullishFVG()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int barsNeeded = FVG_LookbackBars + 2;
   int copied = CopyRates(Symbol(), EntryTimeframe, 1, barsNeeded, rates);
   if(copied < 3) return false;

   for(int i = 0; i <= FVG_LookbackBars && i + 2 < copied; i++)
   {
      // Three consecutive bars: rates[i+2] (oldest), rates[i+1] (middle), rates[i] (newest)
      // Bullish FVG: gap = candle[i+2].high < candle[i].low
      if(rates[i+2].high < rates[i].low)
      {
         // The FVG zone sits between rates[i+2].high and rates[i].low
         g_entryLow  = rates[i+2].high;
         g_entryHigh = rates[i].low;

         // Confirm FVG is above the manipulation level (supports bullish thesis)
         if(g_entryLow > g_manipLevel)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  DETECT BEARISH FVG                                              |
//|  Pattern: candle[2].low > candle[0].high                         |
//+------------------------------------------------------------------+
bool DetectBearishFVG()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int barsNeeded = FVG_LookbackBars + 2;
   int copied = CopyRates(Symbol(), EntryTimeframe, 1, barsNeeded, rates);
   if(copied < 3) return false;

   for(int i = 0; i <= FVG_LookbackBars && i + 2 < copied; i++)
   {
      // Bearish FVG: candle[i+2].low > candle[i].high
      if(rates[i+2].low > rates[i].high)
      {
         g_entryHigh = rates[i+2].low;
         g_entryLow  = rates[i].high;

         // Confirm FVG is below the manipulation level
         if(g_entryHigh < g_manipLevel)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  DETECT BULLISH ORDER BLOCK                                      |
//|  Last bearish candle before a strong bullish impulse move         |
//+------------------------------------------------------------------+
bool DetectBullishOB()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int barsNeeded = OB_LookbackBars + 3;
   int copied = CopyRates(Symbol(), EntryTimeframe, 1, barsNeeded, rates);
   if(copied < 3) return false;

   // ATR to define "strong move"
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   int atrHandle = iATR(Symbol(), EntryTimeframe, ATR_Period);
   if(atrHandle == INVALID_HANDLE) return false;
   if(CopyBuffer(atrHandle, 0, 1, barsNeeded, atrBuffer) < 3)
   {
      IndicatorRelease(atrHandle);
      return false;
   }
   double atrVal = atrBuffer[0];
   IndicatorRelease(atrHandle);

   for(int i = 1; i <= OB_LookbackBars && i + 1 < copied; i++)
   {
      // Check if candle[i] is bearish (close < open)
      if(rates[i].close < rates[i].open)
      {
         // Check if the NEXT candle (rates[i-1], which is newer) is a strong bullish impulse
         double nextBody = rates[i-1].close - rates[i-1].open;
         // Impulse must: (a) exceed ATR threshold and (b) close above the OB candle high
         if(nextBody > atrVal * OB_ImpulseATRMultiplier && rates[i-1].close > rates[i].high)
         {
            // OB zone is the high/low of the bearish candle
            g_entryLow  = rates[i].low;
            g_entryHigh = rates[i].high;

            // Entire OB must sit above the manipulation sweep low (strict)
            if(g_entryLow > g_manipLevel)
               return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  DETECT BEARISH ORDER BLOCK                                      |
//|  Last bullish candle before a strong bearish impulse move         |
//+------------------------------------------------------------------+
bool DetectBearishOB()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int barsNeeded = OB_LookbackBars + 3;
   int copied = CopyRates(Symbol(), EntryTimeframe, 1, barsNeeded, rates);
   if(copied < 3) return false;

   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   int atrHandle = iATR(Symbol(), EntryTimeframe, ATR_Period);
   if(atrHandle == INVALID_HANDLE) return false;
   if(CopyBuffer(atrHandle, 0, 1, barsNeeded, atrBuffer) < 3)
   {
      IndicatorRelease(atrHandle);
      return false;
   }
   double atrVal = atrBuffer[0];
   IndicatorRelease(atrHandle);

   for(int i = 1; i <= OB_LookbackBars && i + 1 < copied; i++)
   {
      // Check if candle[i] is bullish (close > open)
      if(rates[i].close > rates[i].open)
      {
         // Check if the NEXT (newer) candle is a strong bearish impulse
         double nextBody = rates[i-1].open - rates[i-1].close;
         // Impulse must: (a) exceed ATR threshold and (b) close below the OB candle low
         if(nextBody > atrVal * OB_ImpulseATRMultiplier && rates[i-1].close < rates[i].low)
         {
            g_entryHigh = rates[i].high;
            g_entryLow  = rates[i].low;

            // Entire OB must sit below the manipulation sweep high (strict)
            if(g_entryHigh < g_manipLevel)
               return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  CALCULATE STOP LOSS AND TAKE PROFIT                             |
//+------------------------------------------------------------------+
void CalculateSLTP()
{
   double pipValue = GetPipValue();
   double slBuffer = SL_BufferPips * pipValue;

   if(g_direction == 1)   // BUY
   {
      // SL below the manipulation sweep low with buffer
      g_stopLoss   = g_manipLevel - slBuffer;
      // TP = entry + (SL distance × MinRiskReward) — guarantees minimum RR
      double slDist = g_entryPrice - g_stopLoss;
      g_takeProfit  = g_entryPrice + slDist * MinRiskReward;
   }
   else  // SELL
   {
      // SL above the manipulation sweep high with buffer
      g_stopLoss   = g_manipLevel + slBuffer;
      double slDist = g_stopLoss - g_entryPrice;
      g_takeProfit  = g_entryPrice - slDist * MinRiskReward;
   }
}

//+------------------------------------------------------------------+
//|  CALCULATE RISK : REWARD RATIO                                   |
//+------------------------------------------------------------------+
double CalculateRR()
{
   double slDist = MathAbs(g_entryPrice - g_stopLoss);
   double tpDist = MathAbs(g_takeProfit - g_entryPrice);
   if(slDist <= 0) return 0;
   return tpDist / slDist;
}

//+------------------------------------------------------------------+
//|  CALCULATE LOT SIZE based on risk % and SL distance              |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount     = accountBalance * (RiskPercent / 100.0);

   double slPips = MathAbs(g_entryPrice - g_stopLoss) / GetPipValue();
   if(slPips <= 0) return 0.01;

   // Monetary value per pip per standard lot
   double tickSize  = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double pipValuePerLot = (tickValue / tickSize) * GetPipValue();
   if(pipValuePerLot <= 0) return 0.01;

   double lots = riskAmount / (slPips * pipValuePerLot);

   // Round to broker step
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / lotStep) * lotStep;

   // Clamp to broker limits
   double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   lots = MathMax(minLot, MathMin(maxLot, lots));

   return lots;
}

//+------------------------------------------------------------------+
//|  EXECUTE TRADE                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade()
{
   // Check we don't already have open trades for this EA
   if(CountOpenTrades() >= MaxOpenTrades)
   {
      Print("Max open trades reached (", MaxOpenTrades, ") — not entering");
      return;
   }

   double lots = CalculateLotSize();
   if(lots <= 0)
   {
      Print("Lot size calculation failed — skipping trade");
      return;
   }

   bool success = false;
   if(g_direction == 1)
   {
      Print("Executing BUY | Lots: ", lots,
            " | Entry: ", SymbolInfoDouble(Symbol(), SYMBOL_ASK),
            " | SL: ", g_stopLoss, " | TP: ", g_takeProfit);
      success = g_trade.Buy(lots, Symbol(), 0, g_stopLoss, g_takeProfit, "SMC AMD BUY");
   }
   else
   {
      Print("Executing SELL | Lots: ", lots,
            " | Entry: ", SymbolInfoDouble(Symbol(), SYMBOL_BID),
            " | SL: ", g_stopLoss, " | TP: ", g_takeProfit);
      success = g_trade.Sell(lots, Symbol(), 0, g_stopLoss, g_takeProfit, "SMC AMD SELL");
   }

   if(success)
   {
      Print("Trade opened successfully | Ticket: ", g_trade.ResultOrder());
      DrawEntryArrow(g_direction);
      ChangeState(STATE_IN_TRADE);
   }
   else
   {
      Print("Trade execution failed | Error: ", g_trade.ResultRetcode(),
            " — ", g_trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//|  MANAGE OPEN TRADES — trailing stop and break-even               |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   // If no trades open for this EA, reset to IDLE for a new cycle
   if(CountOpenTrades() == 0)
   {
      Print("Trade closed — resetting state machine to IDLE");
      ResetState();
      return;
   }

   if(!UseTrailingSL) return;

   double pipValue      = GetPipValue();
   double trailDistance = TrailingSLPips * pipValue;
   double point         = SymbolInfoDouble(Symbol(), SYMBOL_POINT);  // Constant for this symbol

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol())    continue;

      double currentSL  = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(posType == POSITION_TYPE_BUY)
      {
         double bid      = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double newSL    = bid - trailDistance;
         // Only move SL upwards (never widen it)
         if(newSL > currentSL + point)
         {
            g_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double ask   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double newSL = ask + trailDistance;
         // Only move SL downwards
         if(newSL < currentSL - point || currentSL == 0)
         {
            g_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
         }
      }
   }
}

//+------------------------------------------------------------------+
//|  HELPER: Count open positions belonging to this EA               |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == Symbol())
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//|  HELPER: Get pip value (accounts for 3/5-digit brokers)          |
//+------------------------------------------------------------------+
double GetPipValue()
{
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
   // 5-digit / 3-digit brokers: 1 pip = 10 points
   if(digits == 5 || digits == 3) return point * 10.0;
   return point;
}

//+------------------------------------------------------------------+
//|  HELPER: Session filter                                          |
//+------------------------------------------------------------------+
bool IsSessionActive()
{
   if(!UseSessionFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour;
   return (hour >= SessionStartHour && hour < SessionEndHour);
}

//+------------------------------------------------------------------+
//|  HELPER: Spread filter                                           |
//+------------------------------------------------------------------+
bool IsSpreadTooHigh()
{
   long spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   return (spread > (long)MaxSpreadPoints);
}

//+------------------------------------------------------------------+
//|  HELPER: Change state and record the time                        |
//+------------------------------------------------------------------+
void ChangeState(ENUM_AMD_STATE newState)
{
   Print("State: ", EnumToString(g_state), " → ", EnumToString(newState));
   g_state          = newState;
   g_stateStartTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//|  HELPER: Full state reset                                        |
//+------------------------------------------------------------------+
void ResetState()
{
   g_state       = STATE_IDLE;
   g_direction   = 0;
   g_rangeHigh   = 0.0;
   g_rangeLow    = 0.0;
   g_manipLevel  = 0.0;
   g_entryHigh   = 0.0;
   g_entryLow    = 0.0;
   g_entryPrice  = 0.0;
   g_stopLoss    = 0.0;
   g_takeProfit  = 0.0;
   g_stateStartTime = TimeCurrent();

   // Remove visual elements from previous cycle
   ObjectsDeleteAll(0, OBJ_PREFIX);
}

//+------------------------------------------------------------------+
//|  VISUAL: Draw horizontal lines for the accumulation range        |
//+------------------------------------------------------------------+
void DrawRangeLines()
{
   string highName = OBJ_PREFIX + "RangeHigh_" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
   string lowName  = OBJ_PREFIX + "RangeLow_"  + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   // Range High line (blue)
   if(ObjectFind(0, highName) < 0)
      ObjectCreate(0, highName, OBJ_HLINE, 0, 0, g_rangeHigh);
   ObjectSetInteger(0, highName, OBJPROP_COLOR,  clrDodgerBlue);
   ObjectSetInteger(0, highName, OBJPROP_STYLE,  STYLE_DASH);
   ObjectSetInteger(0, highName, OBJPROP_WIDTH,  1);
   ObjectSetString (0, highName, OBJPROP_TOOLTIP, "SMC Accumulation High");

   // Range Low line (orange)
   if(ObjectFind(0, lowName) < 0)
      ObjectCreate(0, lowName, OBJ_HLINE, 0, 0, g_rangeLow);
   ObjectSetInteger(0, lowName, OBJPROP_COLOR,  clrOrange);
   ObjectSetInteger(0, lowName, OBJPROP_STYLE,  STYLE_DASH);
   ObjectSetInteger(0, lowName, OBJPROP_WIDTH,  1);
   ObjectSetString (0, lowName, OBJPROP_TOOLTIP, "SMC Accumulation Low");
}

//+------------------------------------------------------------------+
//|  VISUAL: Draw an arrow at the entry point                        |
//+------------------------------------------------------------------+
void DrawEntryArrow(int direction)
{
   string arrowName = OBJ_PREFIX + "Entry_" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
   datetime t = iTime(Symbol(), EntryTimeframe, 1);

   if(ObjectFind(0, arrowName) < 0)
      ObjectCreate(0, arrowName, OBJ_ARROW, 0, t, g_entryPrice);

   if(direction == 1)  // BUY arrow (pointing up)
   {
      ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 233);   // Arrow up
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR,     clrLime);
   }
   else  // SELL arrow (pointing down)
   {
      ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 234);   // Arrow down
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR,     clrRed);
   }
   ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);
   ObjectSetString (0, arrowName, OBJPROP_TOOLTIP,
                    (direction == 1 ? "SMC BUY Entry" : "SMC SELL Entry"));
}

//+------------------------------------------------------------------+
//|  End of SMC_AMD_EA.mq5                                           |
//+------------------------------------------------------------------+
