//+------------------------------------------------------------------+
//|                                               MarketRegime.mqh  |
//|                         Market Regime Analyzer                  |
//|                         DualEngine Architecture — v1.00         |
//|                                                                  |
//|  Classifies current market as TRENDING / RANGING /              |
//|  VOLATILE / CHOPPY and selects which engine to use.             |
//|                                                                  |
//|  Prefix: MR_  (all public functions)                            |
//+------------------------------------------------------------------+
#ifndef MARKET_REGIME_MQH
#define MARKET_REGIME_MQH

//+------------------------------------------------------------------+
//|  Shared Signal Result Struct                                     |
//|  Returned by ICT_Analyze and SMC_Analyze                        |
//+------------------------------------------------------------------+
struct SignalResult
{
   int       direction;       // 1=buy, -1=sell, 0=none
   int       confidence;      // 0-100
   double    entryHigh;
   double    entryLow;
   double    entryPrice;
   double    stopLoss;
   double    takeProfit;
   string    entryType;       // "FVG", "OB", "BRK", "OTE", etc.
   string    engineName;      // "ICT" or "SMC"
   double    riskReward;
};

//+------------------------------------------------------------------+
//|  Enumerations                                                    |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
{
   REGIME_TRENDING,    // Clear directional trend (HH/HL or LH/LL + high ADX)
   REGIME_RANGING,     // Price oscillating between S/R levels (low ADX)
   REGIME_VOLATILE,    // ATR expansion / breakout environment
   REGIME_CHOPPY       // Low volatility, no clear structure — avoid trading
};

enum ENUM_ENGINE_SELECT
{
   ENGINE_ICT  = 0,    // Use ICT engine only
   ENGINE_SMC  = 1,    // Use SMC engine only
   ENGINE_BOTH = 2,    // Use both engines, take highest-confidence signal
   ENGINE_NONE = 3     // No trading (choppy/undefined)
};

//+------------------------------------------------------------------+
//|  MR_GetMarketRegime                                              |
//|  Returns the classified market regime based on ADX and ATR.      |
//|                                                                  |
//|  Parameters:                                                     |
//|    symbol          — trading symbol                              |
//|    tf              — timeframe for analysis                      |
//|    adxHandle       — handle of ADX indicator (created in OnInit) |
//|    atrHandle       — handle of ATR indicator (created in OnInit) |
//|    adxPeriod       — ADX period (for reference only)            |
//|    atrPeriod       — ATR period                                  |
//|    atrAvgBars      — bars used to compute average ATR            |
//|    swingRadius     — bars left/right for swing-point detection   |
//|    adxTrendLevel   — ADX threshold above which market is trending|
//|    adxRangeLevel   — ADX threshold below which market is ranging |
//|    atrVolatileMult — ATR multiplier to flag volatile regime      |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME MR_GetMarketRegime(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             adxHandle,
   const int             atrHandle,
   const int             adxPeriod,
   const int             atrPeriod,
   const int             atrAvgBars     = 50,
   const int             swingRadius    = 3,
   const double          adxTrendLevel  = 25.0,
   const double          adxRangeLevel  = 20.0,
   const double          atrVolatileMult = 1.5
)
{
   // ---- Retrieve ADX value ----
   double adxBuf[];
   ArraySetAsSeries(adxBuf, true);
   if(CopyBuffer(adxHandle, 0, 1, 3, adxBuf) < 3)
      return REGIME_CHOPPY;   // Cannot read data — treat as choppy / unknown

   double adx = adxBuf[0];

   // ---- Retrieve ATR values ----
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   int atrCopy = atrAvgBars + 5;
   if(CopyBuffer(atrHandle, 0, 1, atrCopy, atrBuf) < atrCopy)
      return REGIME_CHOPPY;

   double currentATR = atrBuf[0];

   // Compute rolling average ATR (skip bar 0 = current ATR)
   double sumATR = 0.0;
   int    validBars = 0;
   for(int i = 1; i <= atrAvgBars && i < ArraySize(atrBuf); i++)
   {
      if(atrBuf[i] > 0.0) { sumATR += atrBuf[i]; validBars++; }
   }
   if(validBars == 0) return REGIME_CHOPPY;
   double avgATR = sumATR / validBars;

   // ---- Swing-structure analysis ----
   // Detect recent higher-highs/higher-lows or lower-highs/lower-lows
   int lookback = MathMax(swingRadius * 6, 30);
   double highArr[], lowArr[];
   ArraySetAsSeries(highArr, true);
   ArraySetAsSeries(lowArr,  true);
   if(CopyHigh(symbol, tf, 1, lookback, highArr) < lookback ||
      CopyLow(symbol,  tf, 1, lookback, lowArr)  < lookback)
      return REGIME_CHOPPY;

   // Identify swing highs and swing lows
   double swingHighs[];
   double swingLows[];
   ArrayResize(swingHighs, 0);
   ArrayResize(swingLows,  0);

   int r = swingRadius;
   for(int i = r; i < lookback - r; i++)
   {
      bool isSwingHigh = true;
      bool isSwingLow  = true;
      for(int j = 1; j <= r; j++)
      {
         if(highArr[i] <= highArr[i - j] || highArr[i] <= highArr[i + j]) isSwingHigh = false;
         if(lowArr[i]  >= lowArr[i - j]  || lowArr[i]  >= lowArr[i + j])  isSwingLow  = false;
      }
      if(isSwingHigh) { int sz = ArraySize(swingHighs); ArrayResize(swingHighs, sz + 1); swingHighs[sz] = highArr[i]; }
      if(isSwingLow)  { int sz = ArraySize(swingLows);  ArrayResize(swingLows,  sz + 1); swingLows[sz]  = lowArr[i];  }
   }

   // Assess structure: check if last 2 swing highs and lows are ascending (uptrend) or descending (downtrend)
   bool structureTrending = false;
   if(ArraySize(swingHighs) >= 2 && ArraySize(swingLows) >= 2)
   {
      bool hhhl = (swingHighs[0] > swingHighs[1]) && (swingLows[0] > swingLows[1]);  // uptrend structure
      bool lhll = (swingHighs[0] < swingHighs[1]) && (swingLows[0] < swingLows[1]);  // downtrend structure
      structureTrending = hhhl || lhll;
   }

   // ---- Classification logic ----
   // 1. Choppy: very low ATR AND no trend structure AND low ADX
   if(currentATR < avgATR * 0.7 && adx < adxRangeLevel && !structureTrending)
      return REGIME_CHOPPY;

   // 2. Volatile / Breakout: ATR significantly above average
   if(currentATR > avgATR * atrVolatileMult)
      return REGIME_VOLATILE;

   // 3. Trending: high ADX with confirmed swing structure
   if(adx >= adxTrendLevel && structureTrending)
      return REGIME_TRENDING;

   // 4. Ranging: low ADX
   if(adx < adxRangeLevel)
      return REGIME_RANGING;

   // 5. Borderline trending (ADX between range and trend threshold)
   if(structureTrending)
      return REGIME_TRENDING;

   return REGIME_RANGING;
}

//+------------------------------------------------------------------+
//|  MR_SelectEngine                                                 |
//|  Given a regime and optional ICT/SMC scores, returns which       |
//|  engine(s) should execute on the current bar.                    |
//|                                                                  |
//|  Selection rules:                                                |
//|    TRENDING  → ENGINE_SMC  (if ictScore > 80 → ENGINE_BOTH)     |
//|    RANGING   → ENGINE_ICT  (if smcScore > 80 → ENGINE_BOTH)     |
//|    VOLATILE  → ENGINE_BOTH (both evaluate, caller picks best)   |
//|    CHOPPY    → ENGINE_NONE                                       |
//+------------------------------------------------------------------+
ENUM_ENGINE_SELECT MR_SelectEngine(
   const ENUM_MARKET_REGIME regime,
   const double             ictScore = 0.0,
   const double             smcScore = 0.0
)
{
   switch(regime)
   {
      case REGIME_TRENDING:
         if(ictScore > 80.0) return ENGINE_BOTH;
         return ENGINE_SMC;

      case REGIME_RANGING:
         if(smcScore > 80.0) return ENGINE_BOTH;
         return ENGINE_ICT;

      case REGIME_VOLATILE:
         return ENGINE_BOTH;

      case REGIME_CHOPPY:
      default:
         return ENGINE_NONE;
   }
}

//+------------------------------------------------------------------+
//|  MR_RegimeToString  (diagnostic helper)                         |
//+------------------------------------------------------------------+
string MR_RegimeToString(const ENUM_MARKET_REGIME regime)
{
   switch(regime)
   {
      case REGIME_TRENDING:  return "TRENDING";
      case REGIME_RANGING:   return "RANGING";
      case REGIME_VOLATILE:  return "VOLATILE";
      case REGIME_CHOPPY:    return "CHOPPY";
      default:               return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//|  MR_EngineToString  (diagnostic helper)                         |
//+------------------------------------------------------------------+
string MR_EngineToString(const ENUM_ENGINE_SELECT eng)
{
   switch(eng)
   {
      case ENGINE_ICT:  return "ICT";
      case ENGINE_SMC:  return "SMC";
      case ENGINE_BOTH: return "BOTH";
      case ENGINE_NONE: return "NONE";
      default:          return "UNKNOWN";
   }
}

#endif // MARKET_REGIME_MQH
