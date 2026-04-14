//+------------------------------------------------------------------+
//|                                                 SMC_Engine.mqh  |
//|                         Smart Money Concepts Engine Module      |
//|                         DualEngine Architecture — v1.00         |
//|                                                                  |
//|  Implements pure SMC concepts:                                  |
//|    — Market Structure (BOS / CHoCH)                             |
//|    — AMD Cycle State Machine (Accumulation → Manipulation →     |
//|        Distribution) with adaptive accumulation detection       |
//|    — Order Blocks (bullish / bearish)                           |
//|    — Breaker Blocks (failed OBs that flip to S/R)              |
//|    — Liquidity Sweep / Manipulation detection                   |
//|    — SMC Confluence Scoring (0-100)                             |
//|                                                                  |
//|  Adaptive accumulation: rolling average range comparison with   |
//|  AdaptiveRangeRatio + body-to-range ratio MaxBodyToRangeRatio   |
//|  (XAUUSD-compatible fix from v2.30)                             |
//|                                                                  |
//|  Prefix: SMC_  (all public functions)                           |
//+------------------------------------------------------------------+
#ifndef SMC_ENGINE_MQH
#define SMC_ENGINE_MQH

#include "MarketRegime.mqh"   // SignalResult struct and ENUM definitions

//+------------------------------------------------------------------+
//|  AMD Cycle State                                                 |
//+------------------------------------------------------------------+
enum ENUM_AMD_STATE
{
   SMC_STATE_IDLE,
   SMC_STATE_ACCUMULATION,
   SMC_STATE_MANIPULATION,
   SMC_STATE_DISTRIBUTION
};

//+------------------------------------------------------------------+
//|  SMC module persistent state (one instance per EA)              |
//+------------------------------------------------------------------+
struct SMC_State
{
   ENUM_AMD_STATE amdState;
   int            direction;        // 1=bullish, -1=bearish, 0=none
   double         rangeHigh;
   double         rangeLow;
   double         manipLevel;
   datetime       stateStartTime;
   int            barsInState;

   // BOS / CHoCH tracking
   double         lastSwingHigh;
   double         lastSwingLow;
   bool           bosDetected;
   bool           chochDetected;

   // Order Block
   double         obHigh;
   double         obLow;
   bool           obBullish;        // true=bullish OB, false=bearish OB
   bool           obValid;

   // Breaker Block
   double         bbHigh;
   double         bbLow;
   bool           bbBullish;
   bool           bbValid;
};

//+------------------------------------------------------------------+
//|  SMC_InitState  — reset persistent state to defaults            |
//+------------------------------------------------------------------+
void SMC_InitState(SMC_State &s)
{
   s.amdState      = SMC_STATE_IDLE;
   s.direction     = 0;
   s.rangeHigh     = 0.0;
   s.rangeLow      = 0.0;
   s.manipLevel    = 0.0;
   s.stateStartTime = 0;
   s.barsInState   = 0;
   s.lastSwingHigh = 0.0;
   s.lastSwingLow  = 0.0;
   s.bosDetected   = false;
   s.chochDetected = false;
   s.obHigh        = 0.0;
   s.obLow         = 0.0;
   s.obBullish     = false;
   s.obValid       = false;
   s.bbHigh        = 0.0;
   s.bbLow         = 0.0;
   s.bbBullish     = false;
   s.bbValid       = false;
}

//+------------------------------------------------------------------+
//|  SMC_DetectSwings                                               |
//|  Detect most recent swing high and swing low within lookback.   |
//+------------------------------------------------------------------+
bool SMC_DetectSwings(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             lookback,
   const int             radius,
   double               &swingHigh,
   double               &swingLow
)
{
   swingHigh = 0.0;
   swingLow  = 0.0;

   int need = lookback + radius + 1;
   double highArr[], lowArr[];
   ArraySetAsSeries(highArr, true);
   ArraySetAsSeries(lowArr,  true);
   if(CopyHigh(symbol, tf, 1, need, highArr) < need) return false;
   if(CopyLow(symbol,  tf, 1, need, lowArr)  < need) return false;

   for(int i = radius; i < lookback; i++)
   {
      if(swingHigh == 0.0)
      {
         bool isHigh = true;
         for(int j = 1; j <= radius && isHigh; j++)
            if(highArr[i] <= highArr[i - j] || highArr[i] <= highArr[i + j]) isHigh = false;
         if(isHigh) swingHigh = highArr[i];
      }
      if(swingLow == 0.0)
      {
         bool isLow = true;
         for(int j = 1; j <= radius && isLow; j++)
            if(lowArr[i] >= lowArr[i - j] || lowArr[i] >= lowArr[i + j]) isLow = false;
         if(isLow) swingLow = lowArr[i];
      }
      if(swingHigh != 0.0 && swingLow != 0.0) break;
   }
   return (swingHigh > 0.0 && swingLow > 0.0);
}

//+------------------------------------------------------------------+
//|  SMC_DetectBOS                                                  |
//|  Break of Structure: price closes beyond the most recent swing  |
//|  in the direction of the trend bias.                            |
//|  Returns: 1=bullish BOS, -1=bearish BOS, 0=none                |
//+------------------------------------------------------------------+
int SMC_DetectBOS(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             swingRadius,
   const int             lookback
)
{
   double sh = 0.0, sl = 0.0;
   if(!SMC_DetectSwings(symbol, tf, lookback, swingRadius, sh, sl)) return 0;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, 1, 3, rates) < 3) return 0;

   double latestClose = rates[0].close;

   if(latestClose > sh) return  1;   // Bullish BOS
   if(latestClose < sl) return -1;   // Bearish BOS
   return 0;
}

//+------------------------------------------------------------------+
//|  SMC_DetectCHoCH                                                |
//|  Change of Character: BOS counter to established trend.         |
//|  direction: expected trend direction (1=up, -1=down)            |
//|  Returns true if CHoCH is detected (reversal signal)            |
//+------------------------------------------------------------------+
bool SMC_DetectCHoCH(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             swingRadius,
   const int             lookback,
   const int             trendDirection
)
{
   int bos = SMC_DetectBOS(symbol, tf, swingRadius, lookback);
   // CHoCH = BOS opposite to current trend
   return (trendDirection == 1 && bos == -1) || (trendDirection == -1 && bos == 1);
}

//+------------------------------------------------------------------+
//|  SMC_DetectAccumulation (ADAPTIVE)                              |
//|  Uses rolling average range (adaptive) for XAUUSD compatibility |
//|                                                                  |
//|  Accumulation = current range < avgRange * adaptiveRatio        |
//|                AND average body-to-range ratio < maxBodyRatio   |
//|                                                                  |
//|  Returns true and fills rangeHigh / rangeLow.                   |
//+------------------------------------------------------------------+
bool SMC_DetectAccumulation(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             bars,            // bars to analyse
   const int             atrHandle,
   const double          atrMultiplier,   // range must be < atrMultiplier * ATR (legacy check)
   const double          adaptiveRatio,   // range/avgRange threshold  (e.g. 0.7)
   const double          maxBodyRatio,    // max avg body/range ratio  (e.g. 0.5)
   const bool            enableDiagnostics,
   double               &rangeHigh,
   double               &rangeLow
)
{
   rangeHigh = 0.0;
   rangeLow  = 0.0;

   int need = bars + 5;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, 1, need, rates) < need) return false;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, need, atrBuf) < need) return false;

   // Compute the range of the last `bars` bars
   double high = rates[0].high;
   double low  = rates[0].low;
   double totalRange = 0.0;
   double totalBody  = 0.0;

   for(int i = 0; i < bars; i++)
   {
      if(rates[i].high > high) high = rates[i].high;
      if(rates[i].low  < low)  low  = rates[i].low;
      double barRange = rates[i].high - rates[i].low;
      double barBody  = MathAbs(rates[i].close - rates[i].open);
      totalRange += barRange;
      totalBody  += barBody;
   }

   double currentRange = high - low;
   double avgBarRange  = (bars > 0) ? totalRange / bars : 0.0;
   double avgBodyRatio = (totalRange > 0.0) ? totalBody / totalRange : 1.0;

   // Compute rolling average ATR over a longer window for adaptive baseline
   int avgWindow = bars * 3;
   double sumATR = 0.0;
   int    validATR = 0;
   for(int i = 0; i < avgWindow && i < ArraySize(atrBuf); i++)
   {
      if(atrBuf[i] > 0.0) { sumATR += atrBuf[i]; validATR++; }
   }
   double avgATR = (validATR > 0) ? sumATR / validATR : atrBuf[0];

   // Legacy ATR check: full swing range must be within ATR multiple
   bool atrOK = (currentRange < atrMultiplier * avgATR);
   // Adaptive check: average bar range of this window is small compared to historical ATR baseline
   // i.e., individual bars are not moving much — characteristic of accumulation / consolidation
   bool adaptOK = (avgATR > 0.0 && avgBarRange < adaptiveRatio * avgATR);
   // Body ratio check: mostly small bodies (sideways, not trending)
   bool bodyOK = (avgBodyRatio < maxBodyRatio);

   if(enableDiagnostics)
   {
      static int _diagCount = 0;
      _diagCount++;
      if(_diagCount % 5 == 0)
      {
         PrintFormat("[SMC Accum Diag] Range=%.5f ATR=%.5f atrOK=%s | avgBarRange=%.5f adaptOK=%s | bodyRatio=%.3f bodyOK=%s",
            currentRange, avgATR, (atrOK ? "Y" : "N"),
            avgBarRange,  (adaptOK ? "Y" : "N"),
            avgBodyRatio, (bodyOK ? "Y" : "N"));
      }
   }

   if(!atrOK && !adaptOK) return false;
   if(!bodyOK) return false;

   rangeHigh = NormalizeDouble(high, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   rangeLow  = NormalizeDouble(low,  (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   return true;
}

//+------------------------------------------------------------------+
//|  SMC_DetectManipulation                                         |
//|  False breakout beyond consolidation range that closes back     |
//|  inside — liquidity sweep detection.                            |
//|  direction: 1=looking for sell-side sweep, -1=buy-side sweep   |
//|  Returns true and sets manipLevel.                              |
//+------------------------------------------------------------------+
bool SMC_DetectManipulation(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const double          rangeHigh,
   const double          rangeLow,
   const int             direction,
   const int             maxBars,
   const double          minPips,
   const bool            enableDiagnostics,
   double               &manipLevel
)
{
   manipLevel = 0.0;
   if(rangeHigh <= rangeLow) return false;

   double pipVal = SymbolInfoDouble(symbol, SYMBOL_POINT);
   // Normalise pip value for 5-digit / 3-digit brokers
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 5 || digits == 3) pipVal *= 10.0;
   double minMove = minPips * pipVal;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, 1, maxBars + 1, rates) < maxBars + 1) return false;

   for(int i = 0; i < maxBars; i++)
   {
      if(direction == 1)   // Bullish bias → look for sell-side sweep (spike below rangeLow)
      {
         if(rates[i].low < rangeLow - minMove && rates[i].close > rangeLow)
         {
            manipLevel = rates[i].low;
            if(enableDiagnostics)
               PrintFormat("[SMC Manip] Sell-side sweep bar[%d] low=%.5f rangeLow=%.5f close=%.5f",
                  i, rates[i].low, rangeLow, rates[i].close);
            return true;
         }
      }
      else   // Bearish bias → look for buy-side sweep (spike above rangeHigh)
      {
         if(rates[i].high > rangeHigh + minMove && rates[i].close < rangeHigh)
         {
            manipLevel = rates[i].high;
            if(enableDiagnostics)
               PrintFormat("[SMC Manip] Buy-side sweep bar[%d] high=%.5f rangeHigh=%.5f close=%.5f",
                  i, rates[i].high, rangeHigh, rates[i].close);
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  SMC_DetectBullishOB                                            |
//|  Bullish Order Block: last bearish candle before a strong        |
//|  bullish impulse (body > impulseATRMult * ATR).                 |
//+------------------------------------------------------------------+
bool SMC_DetectBullishOB(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             lookback,
   const int             atrHandle,
   const double          impulseATRMult,
   double               &obHigh,
   double               &obLow
)
{
   obHigh = 0.0;
   obLow  = 0.0;

   int need = lookback + 4;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, 1, need, rates) < need) return false;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, need, atrBuf) < need) return false;

   for(int i = 1; i < lookback; i++)
   {
      // Identify a bullish impulse candle
      bool isBullImpulse = (rates[i - 1].close > rates[i - 1].open) &&
                           ((rates[i - 1].close - rates[i - 1].open) >= impulseATRMult * atrBuf[i - 1]);
      if(!isBullImpulse) continue;

      // The candle just before the impulse should be bearish (the OB)
      if(rates[i].close < rates[i].open)
      {
         obHigh = rates[i].high;
         obLow  = rates[i].low;
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  SMC_DetectBearishOB                                            |
//|  Bearish Order Block: last bullish candle before strong          |
//|  bearish impulse.                                               |
//+------------------------------------------------------------------+
bool SMC_DetectBearishOB(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             lookback,
   const int             atrHandle,
   const double          impulseATRMult,
   double               &obHigh,
   double               &obLow
)
{
   obHigh = 0.0;
   obLow  = 0.0;

   int need = lookback + 4;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, 1, need, rates) < need) return false;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, need, atrBuf) < need) return false;

   for(int i = 1; i < lookback; i++)
   {
      bool isBearImpulse = (rates[i - 1].close < rates[i - 1].open) &&
                           ((rates[i - 1].open - rates[i - 1].close) >= impulseATRMult * atrBuf[i - 1]);
      if(!isBearImpulse) continue;

      if(rates[i].close > rates[i].open)
      {
         obHigh = rates[i].high;
         obLow  = rates[i].low;
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  SMC_DetectBreakerBlock                                         |
//|  A breaker block is a failed OB that was engulfed by price,     |
//|  now acting as opposing support/resistance.                     |
//|  direction: 1=looking for bullish breaker, -1=bearish breaker  |
//+------------------------------------------------------------------+
bool SMC_DetectBreakerBlock(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             lookback,
   const int             atrHandle,
   const double          impulseATRMult,
   const int             direction,
   double               &bbHigh,
   double               &bbLow
)
{
   bbHigh = 0.0;
   bbLow  = 0.0;

   // A bearish OB that was broken by a bullish impulse becomes a bullish breaker
   if(direction == 1)
   {
      double obH = 0.0, obL = 0.0;
      if(!SMC_DetectBearishOB(symbol, tf, lookback, atrHandle, impulseATRMult, obH, obL)) return false;

      // Verify price has traded through the OB (close above obHigh)
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(symbol, tf, 1, 5, rates) < 5) return false;
      for(int i = 0; i < 5; i++)
      {
         if(rates[i].close > obH)
         {
            bbHigh = obH;
            bbLow  = obL;
            return true;
         }
      }
   }
   else   // direction == -1: bullish OB broken becomes bearish breaker
   {
      double obH = 0.0, obL = 0.0;
      if(!SMC_DetectBullishOB(symbol, tf, lookback, atrHandle, impulseATRMult, obH, obL)) return false;

      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(symbol, tf, 1, 5, rates) < 5) return false;
      for(int i = 0; i < 5; i++)
      {
         if(rates[i].close < obL)
         {
            bbHigh = obH;
            bbLow  = obL;
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  SMC_GetRegimeScore                                             |
//|  Returns how suitable current market is for SMC strategies.     |
//|  SMC excels in trending / breakout markets.                     |
//+------------------------------------------------------------------+
double SMC_GetRegimeScore(
   const ENUM_MARKET_REGIME regime,
   const double             adxValue
)
{
   switch(regime)
   {
      case REGIME_TRENDING:  return MathMin(100.0, 60.0 + (adxValue - 25.0) * 2.0);
      case REGIME_VOLATILE:  return 70.0;
      case REGIME_RANGING:   return MathMax(0.0,   40.0 - (20.0 - adxValue) * 1.5);
      case REGIME_CHOPPY:    return 15.0;
      default:               return 30.0;
   }
}

//+------------------------------------------------------------------+
//|  SMC_Analyze                                                    |
//|  Main SMC analysis function. Evaluates AMD cycle state,         |
//|  order blocks, breaker blocks and liquidity sweep, then returns |
//|  a SignalResult with confidence score.                          |
//|                                                                  |
//|  Persistent state (s) must be managed by the caller:            |
//|    — initialise once with SMC_InitState                         |
//|    — pass the same SMC_State reference on every call            |
//+------------------------------------------------------------------+
SignalResult SMC_Analyze(
   SMC_State            &s,
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             atrHandle,
   const int             direction,           // HTF bias: 1=bull, -1=bear, 0=none
   // Accumulation parameters
   const int             accumBars,
   const double          accumATRMult,
   const double          adaptiveRatio,
   const double          maxBodyRatio,
   // Manipulation parameters
   const int             manipBars,
   const double          manipPips,
   // OB parameters
   const int             obLookback,
   const double          obImpulseATRMult,
   // Swing / structure parameters
   const int             swingRadius,
   const int             swingLookback,
   // State machine timeout
   const int             maxBarsPerState,
   // Risk parameters
   const double          slBufferATR,
   const double          minRR,
   // Regime
   const ENUM_MARKET_REGIME regime,
   const double          adxValue,
   const bool            enableDiagnostics
)
{
   SignalResult result;
   result.direction  = 0;
   result.confidence = 0;
   result.engineName = "SMC";
   result.entryType  = "";
   result.entryHigh  = 0.0;
   result.entryLow   = 0.0;
   result.entryPrice = 0.0;
   result.stopLoss   = 0.0;
   result.takeProfit = 0.0;
   result.riskReward = 0.0;

   if(direction == 0) return result;

   // ---- ATR ----
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, 3, atrBuf) < 3) return result;
   double atr = atrBuf[0];
   if(atr <= 0.0) return result;

   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   // ---- State machine timeout guard ----
   s.barsInState++;
   if(s.barsInState > maxBarsPerState && s.amdState != SMC_STATE_DISTRIBUTION)
   {
      if(enableDiagnostics)
         PrintFormat("[SMC] State timeout (%s) after %d bars — resetting",
            EnumToString(s.amdState), s.barsInState);
      SMC_InitState(s);
   }

   // ---- BOS / CHoCH detection (always run for scoring) ----
   int bos = SMC_DetectBOS(symbol, tf, swingRadius, swingLookback);
   s.bosDetected   = (bos == direction);
   s.chochDetected = SMC_DetectCHoCH(symbol, tf, swingRadius, swingLookback, direction);

   // If CHoCH detected (trend reversal signal), reset state
   if(s.chochDetected && s.amdState != SMC_STATE_IDLE)
   {
      if(enableDiagnostics) Print("[SMC] CHoCH detected — resetting AMD state");
      SMC_InitState(s);
   }

   // ---- State machine ----
   switch(s.amdState)
   {
      // ----------------------------------------------------------------
      case SMC_STATE_IDLE:
      {
         double rH = 0.0, rL = 0.0;
         if(SMC_DetectAccumulation(symbol, tf, accumBars, atrHandle,
            accumATRMult, adaptiveRatio, maxBodyRatio, enableDiagnostics, rH, rL))
         {
            s.amdState   = SMC_STATE_ACCUMULATION;
            s.direction  = direction;
            s.rangeHigh  = rH;
            s.rangeLow   = rL;
            s.barsInState = 0;
            s.stateStartTime = TimeCurrent();
            if(enableDiagnostics)
               PrintFormat("[SMC] ACCUMULATION detected | High=%.5f Low=%.5f dir=%d",
                  rH, rL, direction);
         }
         break;
      }

      // ----------------------------------------------------------------
      case SMC_STATE_ACCUMULATION:
      {
         // Re-validate trend direction
         if(direction != s.direction) { SMC_InitState(s); break; }

         double mLevel = 0.0;
         if(SMC_DetectManipulation(symbol, tf, s.rangeHigh, s.rangeLow,
            direction, manipBars, manipPips, enableDiagnostics, mLevel))
         {
            s.amdState   = SMC_STATE_MANIPULATION;
            s.manipLevel = mLevel;
            s.barsInState = 0;
            if(enableDiagnostics)
               PrintFormat("[SMC] MANIPULATION detected | Level=%.5f dir=%d",
                  mLevel, direction);
         }
         break;
      }

      // ----------------------------------------------------------------
      case SMC_STATE_MANIPULATION:
      {
         if(direction != s.direction) { SMC_InitState(s); break; }

         // Look for OB or Breaker Block entry
         double zH = 0.0, zL = 0.0;
         bool   found = false;
         string entType = "";

         if(direction == 1)
         {
            if(SMC_DetectBullishOB(symbol, tf, obLookback, atrHandle, obImpulseATRMult, zH, zL))
            { found = true; entType = "OB"; }
            else if(SMC_DetectBreakerBlock(symbol, tf, obLookback, atrHandle, obImpulseATRMult, 1, zH, zL))
            { found = true; entType = "BRK"; }
         }
         else
         {
            if(SMC_DetectBearishOB(symbol, tf, obLookback, atrHandle, obImpulseATRMult, zH, zL))
            { found = true; entType = "OB"; }
            else if(SMC_DetectBreakerBlock(symbol, tf, obLookback, atrHandle, obImpulseATRMult, -1, zH, zL))
            { found = true; entType = "BRK"; }
         }

         if(found && zH > 0.0 && zL >= 0.0)
         {
            s.obHigh     = zH;
            s.obLow      = zL;
            s.obBullish  = (direction == 1);
            s.obValid    = true;
            s.amdState   = SMC_STATE_DISTRIBUTION;
            s.barsInState = 0;

            if(enableDiagnostics)
               PrintFormat("[SMC] %s found | High=%.5f Low=%.5f dir=%d", entType, zH, zL, direction);

            // ---- Build result ----
            int    score  = 0;
            if(s.bosDetected)  score += 25;    // BOS confirmed
            score += 35;                         // Manipulation sweep confirmed
            score += 30;                         // OB / Breaker found
            if(s.chochDetected) score = MathMax(score - 10, 0); // penalise CHoCH

            result.direction  = direction;
            result.confidence = MathMin(score, 100);
            result.entryType  = entType;
            result.entryHigh  = zH;
            result.entryLow   = zL;
            result.entryPrice = (zH + zL) / 2.0;

            double slBuf  = slBufferATR * atr;
            if(direction == 1)
            {
               result.stopLoss   = NormalizeDouble(zL - slBuf, digits);
               double slDist     = result.entryPrice - result.stopLoss;
               if(slDist <= 0.0) { result.direction = 0; SMC_InitState(s); break; }
               result.takeProfit = NormalizeDouble(result.entryPrice + minRR * slDist, digits);
            }
            else
            {
               result.stopLoss   = NormalizeDouble(zH + slBuf, digits);
               double slDist     = result.stopLoss - result.entryPrice;
               if(slDist <= 0.0) { result.direction = 0; SMC_InitState(s); break; }
               result.takeProfit = NormalizeDouble(result.entryPrice - minRR * slDist, digits);
            }

            double slDist2 = MathAbs(result.entryPrice - result.stopLoss);
            double tpDist2 = MathAbs(result.takeProfit - result.entryPrice);
            result.riskReward = (slDist2 > 0.0) ? tpDist2 / slDist2 : 0.0;

            if(result.riskReward < minRR)
            {
               result.direction = 0;
               SMC_InitState(s);
            }
         }
         break;
      }

      // ----------------------------------------------------------------
      case SMC_STATE_DISTRIBUTION:
         // Reset after signal was consumed (caller should reset via SMC_InitState)
         SMC_InitState(s);
         break;
   }

   // ---- Confluence score for regime evaluation (even if no signal) ----
   if(result.direction == 0)
   {
      // Return a partial score based on what was detected
      int partialScore = 0;
      if(s.bosDetected)                            partialScore += 20;
      if(s.amdState == SMC_STATE_ACCUMULATION)     partialScore += 20;
      if(s.amdState == SMC_STATE_MANIPULATION)     partialScore += 30;
      result.confidence = partialScore;
   }

   return result;
}

#endif // SMC_ENGINE_MQH
