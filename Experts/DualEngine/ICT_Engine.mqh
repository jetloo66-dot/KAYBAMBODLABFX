//+------------------------------------------------------------------+
//|                                                 ICT_Engine.mqh  |
//|                         ICT Concepts Engine Module              |
//|                         DualEngine Architecture — v1.00         |
//|                                                                  |
//|  Implements pure ICT (Inner Circle Trader) concepts:            |
//|    — Killzones (London, NY AM, NY PM, Asian)                    |
//|    — Fair Value Gaps (FVG) with ATR size filter                 |
//|    — Optimal Trade Entry (OTE) 62-79% Fibonacci zone           |
//|    — Premium / Discount Zones                                   |
//|    — Displacement Detection (institutional candle)              |
//|    — Liquidity Pools (BSL / SSL equal highs/lows)              |
//|    — ICT Confluence Scoring (0-100)                             |
//|                                                                  |
//|  Prefix: ICT_  (all public functions)                           |
//+------------------------------------------------------------------+
#ifndef ICT_ENGINE_MQH
#define ICT_ENGINE_MQH

#include "MarketRegime.mqh"   // for SignalResult struct and ENUM defs (shared header)

//+------------------------------------------------------------------+
//|  ICT Killzone windows (server-time hours, inclusive)            |
//+------------------------------------------------------------------+
struct ICT_KillzoneWindow
{
   int startHour;
   int endHour;
   string name;
};

//+------------------------------------------------------------------+
//|  ICT_IsInKillzone                                               |
//|  Returns true if current server time falls in any active        |
//|  killzone window. GMT offset adjusts all windows.               |
//+------------------------------------------------------------------+
bool ICT_IsInKillzone(const int gmtOffset = 0)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = (dt.hour + gmtOffset + 24) % 24;

   // Asian session:   00:00 — 03:59
   if(h >= 0  && h < 4)   return true;
   // London open:     02:00 — 05:00
   if(h >= 2  && h < 5)   return true;
   // NY AM (overlap): 07:00 — 10:00
   if(h >= 7  && h < 10)  return true;
   // NY PM:           13:00 — 16:00
   if(h >= 13 && h < 16)  return true;

   return false;
}

//+------------------------------------------------------------------+
//|  ICT_GetKillzoneName                                            |
//+------------------------------------------------------------------+
string ICT_GetKillzoneName(const int gmtOffset = 0)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int h = (dt.hour + gmtOffset + 24) % 24;

   if(h >= 2  && h < 5)   return "LondonOpen";
   if(h >= 7  && h < 10)  return "NY_AM";
   if(h >= 13 && h < 16)  return "NY_PM";
   if(h >= 0  && h < 4)   return "Asian";
   return "OffSession";
}

//+------------------------------------------------------------------+
//|  ICT_DetectBullishFVG                                           |
//|  Finds the most recent bullish FVG within lookback bars.        |
//|  Bullish FVG: candle[i+2].high < candle[i].low  (gap up)       |
//|  The gap must be at least minATRSize * ATR wide.                |
//|                                                                  |
//|  Returns true and fills zoneHigh / zoneLow if found.            |
//+------------------------------------------------------------------+
bool ICT_DetectBullishFVG(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             atrHandle,
   const int             lookback,
   const double          minATRSize,
   double               &zoneHigh,
   double               &zoneLow
)
{
   zoneHigh = 0.0;
   zoneLow  = 0.0;

   double highArr[], lowArr[];
   ArraySetAsSeries(highArr, true);
   ArraySetAsSeries(lowArr,  true);
   int need = lookback + 4;
   if(CopyHigh(symbol, tf, 1, need, highArr) < need) return false;
   if(CopyLow(symbol,  tf, 1, need, lowArr)  < need) return false;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, need, atrBuf) < need) return false;

   for(int i = 0; i < lookback; i++)
   {
      double gapSize = lowArr[i] - highArr[i + 2];
      if(gapSize > 0.0 && atrBuf[i] > 0.0 && gapSize >= minATRSize * atrBuf[i])
      {
         zoneLow  = highArr[i + 2];
         zoneHigh = lowArr[i];
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  ICT_DetectBearishFVG                                           |
//|  Bearish FVG: candle[i+2].low > candle[i].high  (gap down)     |
//+------------------------------------------------------------------+
bool ICT_DetectBearishFVG(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             atrHandle,
   const int             lookback,
   const double          minATRSize,
   double               &zoneHigh,
   double               &zoneLow
)
{
   zoneHigh = 0.0;
   zoneLow  = 0.0;

   double highArr[], lowArr[];
   ArraySetAsSeries(highArr, true);
   ArraySetAsSeries(lowArr,  true);
   int need = lookback + 4;
   if(CopyHigh(symbol, tf, 1, need, highArr) < need) return false;
   if(CopyLow(symbol,  tf, 1, need, lowArr)  < need) return false;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, need, atrBuf) < need) return false;

   for(int i = 0; i < lookback; i++)
   {
      double gapSize = lowArr[i + 2] - highArr[i];
      if(gapSize > 0.0 && atrBuf[i] > 0.0 && gapSize >= minATRSize * atrBuf[i])
      {
         zoneLow  = highArr[i];
         zoneHigh = lowArr[i + 2];
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|  ICT_IsInOTEZone                                                |
//|  OTE: price is between 62% and 79% Fibonacci retracement of a  |
//|  recent swing (swingLow to swingHigh for bullish bias).         |
//+------------------------------------------------------------------+
bool ICT_IsInOTEZone(
   const double currentPrice,
   const double swingLow,
   const double swingHigh,
   const int    direction,           // 1=bullish OTE, -1=bearish OTE
   double      &oteHigh,
   double      &oteLow
)
{
   oteHigh = 0.0;
   oteLow  = 0.0;

   double range = swingHigh - swingLow;
   if(range <= 0.0) return false;

   if(direction == 1)   // Bullish OTE: retracement from swing high back down
   {
      // 62% and 79% from high (price should be between these levels on retracement)
      double level79 = swingHigh - 0.79 * range;
      double level62 = swingHigh - 0.62 * range;
      oteLow  = level79;
      oteHigh = level62;
      return (currentPrice >= level79 && currentPrice <= level62);
   }
   else   // Bearish OTE: retracement from swing low back up
   {
      double level62 = swingLow + 0.62 * range;
      double level79 = swingLow + 0.79 * range;
      oteLow  = level62;
      oteHigh = level79;
      return (currentPrice >= level62 && currentPrice <= level79);
   }
}

//+------------------------------------------------------------------+
//|  ICT_GetPremiumDiscountMid                                      |
//|  Returns the equilibrium (50% midpoint) of a swing range.       |
//|  direction==1 → buyer should be below mid (discount zone)      |
//|  direction==-1 → seller should be above mid (premium zone)     |
//+------------------------------------------------------------------+
bool ICT_IsInCorrectZone(
   const double currentPrice,
   const double swingLow,
   const double swingHigh,
   const int    direction
)
{
   if(swingHigh <= swingLow) return false;
   double mid = (swingHigh + swingLow) / 2.0;

   if(direction == 1)   return (currentPrice < mid);   // Buy in discount (below 50%)
   if(direction == -1)  return (currentPrice > mid);   // Sell in premium (above 50%)
   return false;
}

//+------------------------------------------------------------------+
//|  ICT_DetectDisplacement                                         |
//|  Large-body institutional candle:                               |
//|    body > bodyRatio * total range  AND  body > atrMultiplier*ATR|
//|  Returns direction of displacement (1=bull, -1=bear, 0=none)   |
//+------------------------------------------------------------------+
int ICT_DetectDisplacement(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             atrHandle,
   const int             lookback,
   const double          bodyRatio      = 0.70,   // min body/range ratio
   const double          atrMultiplier  = 1.5
)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, 1, lookback + 1, rates) < lookback + 1) return 0;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, lookback + 1, atrBuf) < lookback + 1) return 0;

   for(int i = 0; i < lookback; i++)
   {
      double totalRange = rates[i].high - rates[i].low;
      if(totalRange <= 0.0 || atrBuf[i] <= 0.0) continue;

      double body = MathAbs(rates[i].close - rates[i].open);
      if(body < bodyRatio * totalRange) continue;
      if(body < atrMultiplier * atrBuf[i]) continue;

      return (rates[i].close > rates[i].open) ? 1 : -1;
   }
   return 0;
}

//+------------------------------------------------------------------+
//|  ICT_DetectLiquidityPool                                        |
//|  Finds clustered equal highs (BSL) or equal lows (SSL).         |
//|  Returns price level if found; 0.0 otherwise.                   |
//|  type: 1=buy-side (BSL from equal highs), -1=sell-side (SSL)   |
//+------------------------------------------------------------------+
double ICT_DetectLiquidityPool(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             lookback,
   const int             type,           // 1=BSL (swing highs), -1=SSL (swing lows)
   const double          toleranceATR,   // equal-high tolerance as ATR fraction
   const int             atrHandle
)
{
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, lookback + 1, atrBuf) < 2) return 0.0;
   double tol = toleranceATR * atrBuf[0];

   double highArr[], lowArr[];
   ArraySetAsSeries(highArr, true);
   ArraySetAsSeries(lowArr,  true);
   if(CopyHigh(symbol, tf, 1, lookback, highArr) < lookback) return 0.0;
   if(CopyLow(symbol,  tf, 1, lookback, lowArr)  < lookback) return 0.0;

   double level = 0.0;
   int    count = 0;

   if(type == 1)   // BSL: look for equal highs
   {
      for(int i = 0; i < lookback - 1; i++)
      {
         for(int j = i + 1; j < lookback; j++)
         {
            if(MathAbs(highArr[i] - highArr[j]) <= tol)
            {
               level += highArr[i];
               count++;
               break;
            }
         }
      }
   }
   else   // SSL: look for equal lows
   {
      for(int i = 0; i < lookback - 1; i++)
      {
         for(int j = i + 1; j < lookback; j++)
         {
            if(MathAbs(lowArr[i] - lowArr[j]) <= tol)
            {
               level += lowArr[i];
               count++;
               break;
            }
         }
      }
   }

   if(count == 0) return 0.0;
   return level / count;
}

//+------------------------------------------------------------------+
//|  ICT_GetRegimeScore                                             |
//|  Returns how suitable current market is for ICT strategies.     |
//|  Higher score = better fit for ICT (range/retracement market)  |
//+------------------------------------------------------------------+
double ICT_GetRegimeScore(
   const ENUM_MARKET_REGIME regime,
   const double             adxValue
)
{
   switch(regime)
   {
      case REGIME_RANGING:   return MathMin(100.0, 60.0 + (20.0 - adxValue) * 2.0);
      case REGIME_TRENDING:  return MathMax(0.0,   40.0 - (adxValue - 25.0) * 1.5);
      case REGIME_VOLATILE:  return 50.0;
      case REGIME_CHOPPY:    return 20.0;
      default:               return 30.0;
   }
}

//+------------------------------------------------------------------+
//|  ICT_Analyze                                                    |
//|  Main ICT analysis function. Scores all ICT factors and         |
//|  returns a populated SignalResult.                              |
//|                                                                  |
//|  Parameters (all indicator handles created in OnInit):          |
//|    symbol, tf         — instrument and timeframe                 |
//|    atrHandle          — ATR indicator handle                     |
//|    htfAtrHandle       — ATR handle for HTF (for swing)          |
//|    fvgLookback        — bars to search for FVG                  |
//|    fvgMinATR          — FVG min size as ATR fraction            |
//|    slBufferATR        — SL buffer as ATR fraction               |
//|    minRR              — minimum risk:reward ratio               |
//|    gmtOffset          — server GMT offset for killzones         |
//|    htfSwingHigh       — recent HTF swing high                   |
//|    htfSwingLow        — recent HTF swing low                    |
//|    direction          — bias from higher TF (+1 / -1)           |
//|    regime             — current market regime                   |
//|    adxValue           — current ADX value                       |
//+------------------------------------------------------------------+
SignalResult ICT_Analyze(
   const string          symbol,
   const ENUM_TIMEFRAMES tf,
   const int             atrHandle,
   const int             fvgLookback,
   const double          fvgMinATR,
   const double          slBufferATR,
   const double          minRR,
   const int             gmtOffset,
   const double          htfSwingHigh,
   const double          htfSwingLow,
   const int             direction,
   const ENUM_MARKET_REGIME regime,
   const double          adxValue
)
{
   SignalResult result;
   result.direction  = 0;
   result.confidence = 0;
   result.engineName = "ICT";
   result.entryType  = "";
   result.entryHigh  = 0.0;
   result.entryLow   = 0.0;
   result.entryPrice = 0.0;
   result.stopLoss   = 0.0;
   result.takeProfit = 0.0;
   result.riskReward = 0.0;

   if(direction == 0) return result;

   // ---- Retrieve current ATR ----
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, 3, atrBuf) < 3) return result;
   double atr = atrBuf[0];
   if(atr <= 0.0) return result;

   // ---- Current price ----
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double currentPrice = (direction == 1) ? ask : bid;

   // ---- Confluence scoring ----
   int    score         = 0;
   double zoneHigh      = 0.0;
   double zoneLow       = 0.0;
   bool   hasFVG        = false;
   bool   hasOTE        = false;
   bool   hasKillzone   = false;
   bool   hasDisplace   = false;
   bool   hasCorrectZone = false;

   // 1. Killzone check (weight 15)
   if(ICT_IsInKillzone(gmtOffset))
   {
      score += 15;
      hasKillzone = true;
   }

   // 2. Premium / Discount zone (weight 15)
   if(htfSwingHigh > htfSwingLow)
   {
      if(ICT_IsInCorrectZone(currentPrice, htfSwingLow, htfSwingHigh, direction))
      {
         score += 15;
         hasCorrectZone = true;
      }
   }

   // 3. FVG detection (weight 25)
   if(direction == 1)
   {
      if(ICT_DetectBullishFVG(symbol, tf, atrHandle, fvgLookback, fvgMinATR, zoneHigh, zoneLow))
      {
         score += 25;
         hasFVG = true;
         result.entryType = "FVG";
         result.entryHigh = zoneHigh;
         result.entryLow  = zoneLow;
      }
   }
   else
   {
      if(ICT_DetectBearishFVG(symbol, tf, atrHandle, fvgLookback, fvgMinATR, zoneHigh, zoneLow))
      {
         score += 25;
         hasFVG = true;
         result.entryType = "FVG";
         result.entryHigh = zoneHigh;
         result.entryLow  = zoneLow;
      }
   }

   // 4. OTE check (weight 20)
   if(htfSwingHigh > htfSwingLow)
   {
      double oteH = 0.0, oteL = 0.0;
      if(ICT_IsInOTEZone(currentPrice, htfSwingLow, htfSwingHigh, direction, oteH, oteL))
      {
         score += 20;
         hasOTE = true;
         if(!hasFVG)  // OTE zone as fallback entry
         {
            result.entryType = "OTE";
            result.entryHigh = oteH;
            result.entryLow  = oteL;
         }
      }
   }

   // 5. Displacement detection (weight 25)
   if(ICT_DetectDisplacement(symbol, tf, atrHandle, fvgLookback, 0.70, 1.5) == direction)
   {
      score += 25;
      hasDisplace = true;
   }

   // ---- Require at least an entry zone ----
   if(result.entryHigh <= 0.0 || result.entryLow <= 0.0) return result;

   // ---- Build signal ----
   result.direction  = direction;
   result.confidence = score;
   result.entryPrice = (result.entryHigh + result.entryLow) / 2.0;

   // SL: beyond entry zone + buffer
   double slBuffer = slBufferATR * atr;
   if(direction == 1)
   {
      result.stopLoss   = NormalizeDouble(result.entryLow  - slBuffer, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
      double slDist     = result.entryPrice - result.stopLoss;
      if(slDist <= 0.0) { result.direction = 0; return result; }
      result.takeProfit = NormalizeDouble(result.entryPrice + minRR * slDist, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   }
   else
   {
      result.stopLoss   = NormalizeDouble(result.entryHigh + slBuffer, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
      double slDist     = result.stopLoss - result.entryPrice;
      if(slDist <= 0.0) { result.direction = 0; return result; }
      result.takeProfit = NormalizeDouble(result.entryPrice - minRR * slDist, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
   }

   // ---- Validate RR ----
   double slDist = MathAbs(result.entryPrice - result.stopLoss);
   double tpDist = MathAbs(result.takeProfit - result.entryPrice);
   result.riskReward = (slDist > 0.0) ? tpDist / slDist : 0.0;
   if(result.riskReward < minRR)
   {
      result.direction = 0;
      return result;
   }

   return result;
}

#endif // ICT_ENGINE_MQH
