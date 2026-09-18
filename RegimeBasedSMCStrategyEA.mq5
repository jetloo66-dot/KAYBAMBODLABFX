//+------------------------------------------------------------------+
//| RegimeBasedSMCStrategyEA.mq5                                      |
//| Purpose: Regime-based SMC strategy EA for MT5                     |
//| Based on the specification supplied by the user                   |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//====================================================================
//  Global / input configuration
//====================================================================
input group "=== GENERAL ==="
input int    InpMagicNumber = 20260918;              // unique magic number (today's date)
input bool   InpAllowTrading = true;                 // master allow trading
input bool   InpScanOnTick = false;                  // scan each tick or bar-close only
input bool   InpRegime_UpdateOnTick = false;         // update regime on ticks too
input bool   InpUsePendingOrders = true;             // arm pending limit orders instead of instant market entries
input int    InpMaxConcurrentPositions = 1;          // max simultaneous positions
input int    InpMaxPendingOrders = 3;                // max pending orders

input group "=== TIMEFRAME CASCADE ==="
input ENUM_TIMEFRAMES InpTF_D1_Enabled = PERIOD_D1;      // D1 enabled if same as timeframe or positive bool pattern is impossible; use per-TF flags below
input ENUM_TIMEFRAMES InpTF_H4_Enabled = PERIOD_H4;
input ENUM_TIMEFRAMES InpTF_H1_Enabled = PERIOD_H1;
input ENUM_TIMEFRAMES InpTF_M30_Enabled = PERIOD_M30;
input ENUM_TIMEFRAMES InpTF_M15_Enabled = PERIOD_M15;
input ENUM_TIMEFRAMES InpTF_M5_Enabled = PERIOD_M5;
input ENUM_TIMEFRAMES InpTF_M1_Enabled = PERIOD_M1;

input bool InpUseTF_D1 = true;
input bool InpUseTF_H4 = true;
input bool InpUseTF_H1 = true;
input bool InpUseTF_M30 = true;
input bool InpUseTF_M15 = true;
input bool InpUseTF_M5 = true;
input bool InpUseTF_M1 = true;

input ENUM_TIMEFRAMES InpRegimeSource_TF = PERIOD_D1;    // master bias TF
input int InpConcurrentEntry_MinTF = 0;                   // 0 = disabled, else minimum TF index to allow immediate concurrent entries
input bool InpAllowConcurrentTFEntries = true;

// NOTE: The cascade is configured by the enabled booleans above. The actual array is kept deterministic.
input int InpTF_CascadeSize = 7;                           // optimization-friendly component count

input group "=== REGIME CLASSIFIER ==="
input int    InpRegime_SwingCount = 3;                    // confirmed swings to inspect
input int    InpSwingLookback = 2;                       // standard 5-bar fractal
input int    InpADX_Period = 14;
input int    InpATR_Period = 14;
input int    InpATR_AvgBars = 50;
input int    InpConsolidation_Lookback = 20;
input int    InpConsolidation_MinBars = 10;
input double InpADX_TrendThreshold = 23.0;
input double InpADX_RangeThreshold = 18.0;
input double InpVolatilityCompressionRatio = 0.7;
input bool   InpRegime_UseHysteresis = true;
input bool   InpUseWickForBreak = false;
input double InpZoneBufferPoints = 0.0;
input int    InpVP_BucketPoints = 20;

input group "=== ENGINE R: REVERSAL ==="
input bool   InpEngineR_Enabled = true;
input bool   InpEngineR_GateSourceBias = true;
input string InpRetracePriority1 = "VolumeNode";
input string InpRetracePriority2 = "EngulfedCandle";
input string InpRetracePriority3 = "LastBullBeforeBreak";
input string InpRetracePriority4 = "FibLevel";
input int    InpRetraceMode = 0; // 0=VolumeNode,1=EngulfedCandle,2=LastBullBeforeBreak,3=FibLevel,4=PriorityCascade,5=AllConfluence
input double InpFibLevel = 0.618;
input double InpConfluenceZoneTolerancePoints = 5.0;
input bool   InpEngineR_UsePendingOnly = false;

input group "=== ENGINE T: TREND CONTINUATION ==="
input bool   InpEngineT_Enabled = true;
input bool   InpEngineT_GateSourceBias = true;
input int    InpContinuationZoneMode = 0; // 0=OrderBlock, 1=Breaker, 2=FibLevel, 3=PriorityCascade, 4=AllConfluence
input int    InpContinuation_EntryTiming = 0; // 0=PostBOSOnly, 1=AllowPreConfirmation
input double InpContinuationFibLevel = 0.618;
input double InpMinConfluenceScore_PreConfirm = 90.0;

input group "=== ENGINE C / STAY OUT ==="
input bool   InpConsolidation_StayOut = true;
input bool   InpConsolidation_AllowRangeFade = false;
input double InpRangeFade_RiskMultiplier = 0.5;
input int    InpRangeFade_MaxBars = 50;

input group "=== RISK / EXECUTION ==="
input bool   InpUseRiskPercentSizing = true;
input double InpRiskPercentPerTrade = 0.5; // %
input double InpDefaultLotSize = 0.01;
input double InpMinRR = 3.0;
input double InpMinConfluenceScore = 75.0;
input double InpSL_BufferPoints = 10.0;
input bool   InpUseBreakEven = true;
input double InpBreakEvenPoints = 0.0;
input bool   InpUseTrailingStop = true;
input double InpTrailStartPoints = 20.0;
input double InpTrailStepPoints = 10.0;
input bool   InpAllowMultiplePositions = false;
input int    InpPartialTP_Ratio = 50;
input double InpTP1Ratio = 1.0;
input double InpTP2Ratio = 1.5;
input double InpTP3Ratio = 2.0;
input double InpTP4Ratio = 2.5;
input double InpTP5Ratio = 3.0;
input int    InpProfitTargetMode = 0; // 0=disabled 1=per minute 2=per hour 3=per session 4=per day
input double InpProfitTargetPercent = 100.0;
input int    InpLossLimitMode = 0;
input double InpLossLimitPercent = 5.0;

input group "=== FILTERS ==="
input bool   InpUseNewsBlackout = false;
input int    InpNewsBlackoutMinutesBefore = 30;
input int    InpNewsBlackoutMinutesAfter = 30;
input bool   InpUseSessionFilter = false;
input int    InpSessionStartHour = 0;
input int    InpSessionEndHour = 23;
input bool   InpUseTickLevelScan = false;

input group "=== UI / ALERTS ==="
input bool   InpEnableDashboard = true;
input bool   InpEnableAlerts = true;
input string InpTelegramBotToken = "";
input string InpTelegramChatID = "";
input bool   InpSendPushNotifications = false;

input group "=== ADAPTIVE LEARNING ==="
input bool   InpAdaptiveLearning_Enabled = false;
input int    InpAdaptiveLearning_Window = 50;
input double InpAdaptiveLearning_ThresholdShift = 5.0;

//====================================================================
//  Enums
//====================================================================
enum RegimeState
{
   REGIME_TRENDING_UP,
   REGIME_TRENDING_DOWN,
   REGIME_REVERSAL_FORMING_BULL,
   REGIME_REVERSAL_FORMING_BEAR,
   REGIME_CONSOLIDATING,
   REGIME_UNKNOWN
};

enum EngineType
{
   ENGINE_NONE,
   ENGINE_REVERSAL,
   ENGINE_TREND,
   ENGINE_CONSOLIDATION
};

enum RetraceMode
{
   RETRACE_VOLUME_NODE,
   RETRACE_ENGULFED_CANDLE,
   RETRACE_LAST_BULL_BEFORE_BREAK,
   RETRACE_FIB_LEVEL,
   RETRACE_PRIORITY_CASCADE,
   RETRACE_ALL_CONFLUENCE
};

enum ContinuationZoneMode
{
   CONT_ZONE_ORDER_BLOCK,
   CONT_ZONE_BREAKER,
   CONT_ZONE_FIB_LEVEL,
   CONT_ZONE_PRIORITY_CASCADE,
   CONT_ZONE_ALL_CONFLUENCE
};

enum ContinuationEntryTiming
{
   CONT_ENTRY_POST_BOS_ONLY,
   CONT_ENTRY_ALLOW_PRECONFIRM
};

struct SwingPoint
{
   double high;
   double low;
   datetime time;
   int index;
   bool valid;
};

struct Zone
{
   double top;
   double bottom;
   datetime time;
   string label;
   bool valid;
};

struct VolumeNodeResult
{
   double price;
   double volume;
   double rangeLow;
   double rangeHigh;
   bool valid;
};

struct RegimeSnapshot
{
   RegimeState state;
   datetime time;
   double atr;
   double atrAvg;
   double adx;
   double vah;
   double val;
   double rollingHigh;
   double rollingLow;
   bool valid;
};

struct SetupSignal
{
   bool valid;
   bool isLong;
   double entryPrice;
   double sl;
   double tp;
   double zoneTop;
   double zoneBottom;
   double confluenceScore;
   double rr;
   int tf;
   string label;
   string reason;
   datetime time;
};

//====================================================================
//  Global state
//====================================================================
CTrade g_trade;
CPositionInfo g_position;
CAccountInfo g_account;

int g_tfList[7];
RegimeSnapshot g_regimeSnapshot[7];
RegimeState g_prevRegime[7];
bool g_newBarAllowed[7];
string g_dashboardName = "SMC_Regime_Dashboard";
int g_magic = 0;

double g_adxValue[7];

//====================================================================
//  Expert initialization / deinit / tick
//====================================================================
int OnInit()
{
   g_magic = InpMagicNumber;
   g_trade.SetExpertMagicNumber(g_magic);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetMarginMode();

   BuildTFList();
   InitializeRegimeHistory();
   EventSetTimer(1);
   DrawDashboard();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ClearChartObjects();
}

void OnTick()
{
   if(!InpAllowTrading)
      return;

   if(InpScanOnTick || IsNewBar(_Period))
      UpdateRegimes();

   ManageOpenPositions();
   EvaluateSignals();
   DrawDashboard();
}

void OnTimer()
{
   UpdateRegimes();
   ManageOpenPositions();
   EvaluateSignals();
   DrawDashboard();
}

//====================================================================
//  Utility: TF list
//====================================================================
void BuildTFList()
{
   int idx = 0;
   if(InpUseTF_D1){ g_tfList[idx++] = PERIOD_D1; }
   if(InpUseTF_H4){ g_tfList[idx++] = PERIOD_H4; }
   if(InpUseTF_H1){ g_tfList[idx++] = PERIOD_H1; }
   if(InpUseTF_M30){ g_tfList[idx++] = PERIOD_M30; }
   if(InpUseTF_M15){ g_tfList[idx++] = PERIOD_M15; }
   if(InpUseTF_M5){ g_tfList[idx++] = PERIOD_M5; }
   if(InpUseTF_M1){ g_tfList[idx++] = PERIOD_M1; }
   if(idx < 7)
   {
      for(int i=idx; i<7; i++) g_tfList[i] = PERIOD_CURRENT;
   }
}

void InitializeRegimeHistory()
{
   for(int i=0;i<7;i++)
   {
      g_prevRegime[i] = REGIME_UNKNOWN;
      g_regimeSnapshot[i].state = REGIME_UNKNOWN;
      g_regimeSnapshot[i].valid = false;
      g_newBarAllowed[i] = true;
   }
}

//====================================================================
//  Market snapshot / new bar detection
//====================================================================
bool IsNewBar(ENUM_TIMEFRAMES tf)
{
   static datetime lastTime[7];
   datetime cur = iTime(_Symbol, tf, 0);
   int idx = TFIndex(tf);
   if(idx < 0) return false;
   bool result = (cur != lastTime[idx]);
   lastTime[idx] = cur;
   return result;
}

int TFIndex(ENUM_TIMEFRAMES tf)
{
   for(int i=0;i<7;i++)
   {
      if(g_tfList[i] == tf)
         return i;
   }
   return -1;
}

//====================================================================
//  Generic data access
//====================================================================
bool EnsureRateArray(const string symbol, ENUM_TIMEFRAMES tf, int bars, double &open[], double &high[], double &low[], double &close[], double &volume[])
{
   if(CopyRates(symbol, tf, 0, bars, open) < bars) return false;
   if(CopyRates(symbol, tf, 0, bars, high) < bars) return false;
   if(CopyRates(symbol, tf, 0, bars, low) < bars) return false;
   if(CopyRates(symbol, tf, 0, bars, close) < bars) return false;
   if(CopyTickVolume(symbol, tf, 0, bars, volume) < bars)
   {
      ArrayResize(volume, bars);
      for(int i=0;i<bars;i++) volume[i] = 1.0;
   }
   ArraySetAsSeries(open,true); ArraySetAsSeries(high,true); ArraySetAsSeries(low,true); ArraySetAsSeries(close,true); ArraySetAsSeries(volume,true);
   return true;
}

//====================================================================
//  Fractal and swing detection
//====================================================================
bool IsSwingHigh(const double &high[], int idx, int lookback)
{
   for(int i=idx-lookback; i<=idx+lookback; i++)
   {
      if(i == idx) continue;
      if(high[i] >= high[idx]) return false;
   }
   return true;
}

bool IsSwingLow(const double &low[], int idx, int lookback)
{
   for(int i=idx-lookback; i<=idx+lookback; i++)
   {
      if(i == idx) continue;
      if(low[i] <= low[idx]) return false;
   }
   return true;
}

void GetLastSwingPoints(ENUM_TIMEFRAMES tf, double &lastHighs[], double &lastLows[], int &count)
{
   count = 0;
   int bars = 200;
   double high[]; double low[]; double open[]; double close[]; double vol[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, vol)) return;

   int look = InpSwingLookback;
   ArrayResize(lastHighs, 0);
   ArrayResize(lastLows, 0);

   for(int i=look; i<bars-look; i++)
   {
      if(IsSwingHigh(high,i,look))
      {
         ArrayResize(lastHighs, count + 1);
         lastHighs[count] = high[i];
         count++;
      }
      if(IsSwingLow(low,i,look))
      {
         ArrayResize(lastLows, count + 1);
         lastLows[count] = low[i];
         count++;
      }
   }

   // Keep symmetrical counts for the last highs and lows (use arrays separately, not combined)
   // This function is intentionally simple and used by regime classification wrappers.
}

void GetLatestFractalSets(ENUM_TIMEFRAMES tf, double &swingHighs[], double &swingLows[], int maxCount)
{
   int bars = 300;
   double open[]; double high[]; double low[]; double close[]; double vol[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, vol)) return;

   int look = MathMax(1, InpSwingLookback);
   int cHigh = 0;
   int cLow = 0;
   ArrayResize(swingHighs, maxCount);
   ArrayResize(swingLows, maxCount);
   for(int i=0;i<maxCount;i++) { swingHighs[i] = 0.0; swingLows[i] = 0.0; }

   for(int i=look; i<bars-look; i++)
   {
      if(IsSwingHigh(high, i, look))
      {
         if(cHigh < maxCount)
         {
            swingHighs[cHigh++] = high[i];
         }
      }
      if(IsSwingLow(low, i, look))
      {
         if(cLow < maxCount)
         {
            swingLows[cLow++] = low[i];
         }
      }
   }
}

//====================================================================
//  ATR / ADX approximations
//====================================================================
double CalcATR(ENUM_TIMEFRAMES tf, int period)
{
   double high[], low[], close[];
   double vol[];
   int bars = MathMax(100, period + 30);
   if(!EnsureRateArray(_Symbol, tf, bars, high, high, low, close, vol)) return 0.0;
   // ensure no duplicate variable bug - use separate arrays for open/close but not necessary.
   double atr = 0.0;
   for(int i=1;i<bars && i<=period;i++)
   {
      double tr = MathMax(high[i]-low[i], MathAbs(high[i]-close[i-1]));
      tr = MathMax(tr, MathAbs(low[i]-close[i-1]));
      atr += tr;
   }
   if(period <= 0) return 0.0;
   return atr / period;
}

double CalcAverageATR(ENUM_TIMEFRAMES tf, int period, int avgBars)
{
   double high[], low[], close[], open[], volume[];
   int bars = MathMax(100, avgBars + 10);
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume) == false) return 0.0;
   double sum = 0.0;
   int count = 0;
   for(int i=1;i<bars && i<avgBars;i++)
   {
      double tr = MathMax(high[i]-low[i], MathAbs(high[i]-close[i-1]));
      tr = MathMax(tr, MathAbs(low[i]-close[i-1]));
      sum += tr;
      count++;
   }
   if(count == 0) return 0.0;
   return sum / count;
}

double CalcADX(ENUM_TIMEFRAMES tf, int period)
{
   int bars = 200;
   double open[]; double high[]; double low[]; double close[]; double volume[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume) == false) return 0.0;

   double dmPlus[], dmMinus[], tr[], diPlus[], diMinus[];
   ArrayResize(dmPlus, bars);
   ArrayResize(dmMinus, bars);
   ArrayResize(tr, bars);
   ArrayResize(diPlus, bars);
   ArrayResize(diMinus, bars);
   ArrayInitialize(dmPlus, 0.0); ArrayInitialize(dmMinus, 0.0); ArrayInitialize(tr, 0.0); ArrayInitialize(diPlus, 0.0); ArrayInitialize(diMinus, 0.0);

   for(int i=1;i<bars;i++)
   {
      double upMove = high[i] - high[i-1];
      double downMove = low[i-1] - low[i];
      if(upMove > downMove && upMove > 0.0) dmPlus[i] = upMove; else dmPlus[i] = 0.0;
      if(downMove > upMove && downMove > 0.0) dmMinus[i] = downMove; else dmMinus[i] = 0.0;
      tr[i] = MathMax(high[i]-low[i], MathAbs(high[i]-close[i-1]));
      tr[i] = MathMax(tr[i], MathAbs(low[i]-close[i-1]));
   }

   double smoothedPlus = 0.0;
   double smoothedMinus = 0.0;
   double smoothedTR = 0.0;
   for(int i=1;i<bars;i++)
   {
      smoothedPlus += dmPlus[i];
      smoothedMinus += dmMinus[i];
      smoothedTR += tr[i];
      if(i == period)
      {
         break;
      }
   }

   if(smoothedTR <= 0.0) return 0.0;
   double diPlusValue = 100.0 * (smoothedPlus / smoothedTR);
   double diMinusValue = 100.0 * (smoothedMinus / smoothedTR);
   double dx = 100.0 * MathAbs(diPlusValue - diMinusValue) / (diPlusValue + diMinusValue + 1e-10);
   return dx;
}

//====================================================================
//  Volume profile / VAH / VAL / volume node
//====================================================================
double GetVisibleVAH(ENUM_TIMEFRAMES tf, int lookback)
{
   double high[], low[], close[], open[], volume[];
   int bars = MathMax(50, lookback + 20);
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return 0.0;

   double rangeLow = high[0];
   double rangeHigh = low[0];
   for(int i=0;i<bars;i++)
   {
      if(high[i] > rangeHigh) rangeHigh = high[i];
      if(low[i] < rangeLow) rangeLow = low[i];
   }

   // lightweight volume profile histogram over the visible range
   int bucketCount = (int)MathMax(1, (rangeHigh - rangeLow) / (InpVP_BucketPoints * _Point));
   if(bucketCount <= 0) return rangeHigh;
   double buckets[];
   ArrayResize(buckets, bucketCount + 1);
   ArrayInitialize(buckets, 0.0);

   for(int i=0;i<bars;i++)
   {
      double h = high[i];
      double l = low[i];
      double v = volume[i] > 0 ? volume[i] : 1.0;
      int idx1 = (int)((h - rangeLow) / (InpVP_BucketPoints * _Point));
      int idx2 = (int)((l - rangeLow) / (InpVP_BucketPoints * _Point));
      if(idx1 < 0) idx1 = 0;
      if(idx2 < 0) idx2 = 0;
      if(idx1 >= bucketCount) idx1 = bucketCount - 1;
      if(idx2 >= bucketCount) idx2 = bucketCount - 1;
      for(int b=MathMin(idx1, idx2); b<=MathMax(idx1, idx2); b++)
      {
         if(b >= 0 && b < bucketCount)
            buckets[b] += v;
      }
   }

   int vaMax = 0;
   for(int i=1;i<bucketCount;i++)
   {
      if(buckets[i] > buckets[vaMax]) vaMax = i;
   }
   return rangeLow + (vaMax + 0.5) * (InpVP_BucketPoints * _Point);
}

double GetVisibleVAL(ENUM_TIMEFRAMES tf, int lookback)
{
   double high[], low[], close[], open[], volume[];
   int bars = MathMax(50, lookback + 20);
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return 0.0;

   double rangeLow = high[0];
   double rangeHigh = low[0];
   for(int i=0;i<bars;i++)
   {
      if(high[i] > rangeHigh) rangeHigh = high[i];
      if(low[i] < rangeLow) rangeLow = low[i];
   }

   int bucketCount = (int)MathMax(1, (rangeHigh - rangeLow) / (InpVP_BucketPoints * _Point));
   double buckets[];
   ArrayResize(buckets, bucketCount + 1);
   ArrayInitialize(buckets, 0.0);

   for(int i=0;i<bars;i++)
   {
      double h = high[i]; double l = low[i]; double v = volume[i] > 0 ? volume[i] : 1.0;
      int idx1 = (int)((h - rangeLow) / (InpVP_BucketPoints * _Point));
      int idx2 = (int)((l - rangeLow) / (InpVP_BucketPoints * _Point));
      if(idx1 < 0) idx1 = 0; if(idx2 < 0) idx2 = 0; if(idx1 >= bucketCount) idx1 = bucketCount-1; if(idx2 >= bucketCount) idx2 = bucketCount-1;
      for(int b=MathMin(idx1, idx2); b<=MathMax(idx1, idx2); b++)
      {
         if(b >= 0 && b < bucketCount)
            buckets[b] += v;
      }
   }

   int vaMin = 0;
   for(int i=1;i<bucketCount;i++)
   {
      if(buckets[i] < buckets[vaMin]) vaMin = i;
   }
   return rangeLow + (vaMin + 0.5) * (InpVP_BucketPoints * _Point);
}

VolumeNodeResult CalcVolumeNode(ENUM_TIMEFRAMES tf, double startPrice, double endPrice, int lookback)
{
   VolumeNodeResult result;
   result.valid = false;
   result.price = 0.0;
   result.volume = 0.0;
   result.rangeLow = MathMin(startPrice, endPrice);
   result.rangeHigh = MathMax(startPrice, endPrice);

   double open[]; double high[]; double low[]; double close[]; double volume[];
   int bars = 300;
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return result;

   double bucketSize = MathMax(_Point, InpVP_BucketPoints * _Point);
   int bucketCount = (int)MathMax(1, (result.rangeHigh - result.rangeLow) / bucketSize) + 2;
   double buckets[];
   ArrayResize(buckets, bucketCount);
   ArrayInitialize(buckets, 0.0);

   for(int i=0;i<bars && i<lookback;i++)
   {
      double v = volume[i] > 0 ? volume[i] : 1.0;
      double h = high[i];
      double l = low[i];
      int idx1 = (int)((h - result.rangeLow) / bucketSize);
      int idx2 = (int)((l - result.rangeLow) / bucketSize);
      if(idx1 < 0) idx1 = 0; if(idx2 < 0) idx2 = 0; if(idx1 >= bucketCount) idx1 = bucketCount-1; if(idx2 >= bucketCount) idx2 = bucketCount-1;
      for(int b=MathMin(idx1, idx2); b<=MathMax(idx1, idx2); b++)
      {
         if(b >= 0 && b < bucketCount)
            buckets[b] += v;
      }
   }

   int bestBucket = 0;
   for(int i=1;i<bucketCount;i++)
   {
      if(buckets[i] > buckets[bestBucket]) bestBucket = i;
   }
   if(bucketCount <= 0) return result;
   result.price = result.rangeLow + bestBucket * bucketSize + (bucketSize * 0.5);
   result.volume = buckets[bestBucket];
   result.valid = true;
   return result;
}

//====================================================================
//  Regime classification
//====================================================================
bool IsReversalBullPattern(ENUM_TIMEFRAMES tf)
{
   int bars = 400;
   double open[]; double high[]; double low[]; double close[]; double volume[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return false;

   // Find last 3 confirmed swings: LL2, LH2, LL1
   // Pattern: LL2 < LH2 and LL1 < LL2
   double L2 = 999999999.0, H2 = -999999999.0, L1 = 999999999.0;
   for(int i=InpSwingLookback; i<bars-InpSwingLookback; i++)
   {
      if(IsSwingLow(low, i, InpSwingLookback))
      {
         if(L2 == 999999999.0)
         {
            L2 = low[i];
         }
         else if(H2 == -999999999.0)
         {
            H2 = high[i];
         }
         else if(L1 == 999999999.0)
         {
            L1 = low[i];
         }
      }
   }
   if(L2 == 999999999.0 || H2 == -999999999.0 || L1 == 999999999.0) return false;
   if(L2 < H2 && L1 < L2)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double zoneLow = L2 - InpZoneBufferPoints * _Point;
      double zoneHigh = H2 + InpZoneBufferPoints * _Point;
      return (bid >= zoneLow && bid <= zoneHigh);
   }
   return false;
}

bool IsReversalBearPattern(ENUM_TIMEFRAMES tf)
{
   int bars = 400;
   double open[]; double high[]; double low[]; double close[]; double volume[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return false;

   double H2 = -999999999.0, L2 = 999999999.0, H1 = -999999999.0;
   for(int i=InpSwingLookback; i<bars-InpSwingLookback; i++)
   {
      if(IsSwingHigh(high, i, InpSwingLookback))
      {
         if(H2 == -999999999.0)
         {
            H2 = high[i];
         }
         else if(L2 == 999999999.0)
         {
            L2 = low[i];
         }
         else if(H1 == -999999999.0)
         {
            H1 = high[i];
         }
      }
   }
   if(H2 == -999999999.0 || L2 == 999999999.0 || H1 == -999999999.0) return false;
   if(H2 > L2 && H1 > H2)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double zoneLow = L2 - InpZoneBufferPoints * _Point;
      double zoneHigh = H2 + InpZoneBufferPoints * _Point;
      return (ask >= zoneLow && ask <= zoneHigh);
   }
   return false;
}

bool IsTrendingUp(ENUM_TIMEFRAMES tf)
{
   double highs[], lows[];
   GetLatestFractalSets(tf, highs, lows, InpRegime_SwingCount);
   if(ArraySize(highs) < InpRegime_SwingCount || ArraySize(lows) < InpRegime_SwingCount) return false;

   double adx = CalcADX(tf, InpADX_Period);
   g_adxValue[TFIndex(tf)] = adx;
   if(adx < InpADX_TrendThreshold) return false;

   bool allHighsHigher = true;
   bool allLowsHigher = true;
   for(int i=1;i<MathMin(ArraySize(highs), InpRegime_SwingCount);i++)
   {
      if(highs[i] <= highs[i-1]) allHighsHigher = false;
      if(lows[i] <= lows[i-1]) allLowsHigher = false;
   }
   return (allHighsHigher && allLowsHigher);
}

bool IsTrendingDown(ENUM_TIMEFRAMES tf)
{
   double highs[], lows[];
   GetLatestFractalSets(tf, highs, lows, InpRegime_SwingCount);
   if(ArraySize(highs) < InpRegime_SwingCount || ArraySize(lows) < InpRegime_SwingCount) return false;

   double adx = CalcADX(tf, InpADX_Period);
   g_adxValue[TFIndex(tf)] = adx;
   if(adx < InpADX_TrendThreshold) return false;

   bool allHighsLower = true;
   bool allLowsLower = true;
   for(int i=1;i<MathMin(ArraySize(highs), InpRegime_SwingCount);i++)
   {
      if(highs[i] >= highs[i-1]) allHighsLower = false;
      if(lows[i] >= lows[i-1]) allLowsLower = false;
   }
   return (allHighsLower && allLowsLower);
}

bool IsConsolidating(ENUM_TIMEFRAMES tf)
{
   int idx = TFIndex(tf);
   if(idx < 0) return false;

   double high[], low[], close[], open[], volume[];
   int bars = 300;
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return false;

   double adx = CalcADX(tf, InpADX_Period);
   if(adx <= InpADX_RangeThreshold) return true;

   double rollingHigh = high[0];
   double rollingLow = low[0];
   double oldHigh = high[InpConsolidation_Lookback];
   double oldLow = low[InpConsolidation_Lookback];
   for(int i=0;i<MathMin(InpConsolidation_Lookback, bars);i++)
   {
      if(high[i] > rollingHigh) rollingHigh = high[i];
      if(low[i] < rollingLow) rollingLow = low[i];
   }
   if(rollingHigh <= oldHigh && rollingLow >= oldLow)
      return true;

   double atr = CalcATR(tf, InpATR_Period);
   double atrAvg = CalcAverageATR(tf, InpATR_Period, InpATR_AvgBars);
   if(atrAvg > 0.0 && atr / atrAvg <= InpVolatilityCompressionRatio)
   {
      double vah = GetVisibleVAH(tf, InpConsolidation_Lookback);
      double val = GetVisibleVAL(tf, InpConsolidation_Lookback);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      int barsInBand = 0;
      for(int i=0;i<MathMin(InpConsolidation_MinBars, bars);i++)
      {
         double c = close[i];
         if(c >= val && c <= vah)
            barsInBand++;
      }
      if(barsInBand >= InpConsolidation_MinBars)
         return true;
   }

   return false;
}

RegimeState ClassifyRegimeForTF(ENUM_TIMEFRAMES tf)
{
   int idx = TFIndex(tf);
   if(idx < 0) return REGIME_UNKNOWN;

   if(IsReversalBullPattern(tf))
      return REGIME_REVERSAL_FORMING_BULL;
   if(IsReversalBearPattern(tf))
      return REGIME_REVERSAL_FORMING_BEAR;
   if(IsTrendingUp(tf))
      return REGIME_TRENDING_UP;
   if(IsTrendingDown(tf))
      return REGIME_TRENDING_DOWN;
   if(IsConsolidating(tf))
      return REGIME_CONSOLIDATING;

   if(InpRegime_UseHysteresis && g_prevRegime[idx] != REGIME_UNKNOWN)
      return g_prevRegime[idx];

   return REGIME_UNKNOWN;
}

void UpdateRegimes()
{
   for(int i=0;i<7;i++)
   {
      if(g_tfList[i] == PERIOD_CURRENT)
         continue;
      RegimeState state = ClassifyRegimeForTF(g_tfList[i]);
      g_regimeSnapshot[i].state = state;
      g_regimeSnapshot[i].valid = true;
      g_regimeSnapshot[i].time = iTime(_Symbol, g_tfList[i], 0);
      g_prevRegime[i] = state;
   }
}

//====================================================================
//  Engine R / Reversal detection
//====================================================================
struct ReversalSet
{
   bool valid;
   bool isLong;
   double ll2;
   double lh2;
   double ll1;
   double demandLow;
   double demandHigh;
   double confirmationClose;
   datetime timeLL2;
};

ReversalSet DetectReversalLong(ENUM_TIMEFRAMES tf)
{
   ReversalSet s;
   s.valid = false;
   s.isLong = true;
   s.ll2 = 0.0; s.lh2 = 0.0; s.ll1 = 0.0;

   int bars = 300;
   double open[]; double high[]; double low[]; double close[]; double volume[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return s;

   // find the latest sequence LL2, LH2, LL1 in a valid down-then-up structure
   int foundLL2 = -1, foundLH2 = -1, foundLL1 = -1;
   for(int i=InpSwingLookback; i<bars-InpSwingLookback; i++)
   {
      if(IsSwingLow(low, i, InpSwingLookback))
      {
         if(foundLL2 == -1)
         {
            foundLL2 = i;
         }
         else if(foundLH2 == -1)
         {
            foundLH2 = i;
         }
         else if(foundLL1 == -1)
         {
            foundLL1 = i;
         }
      }
   }

   if(foundLL2 < 0 || foundLH2 < 0 || foundLL1 < 0)
      return s;

   s.ll2 = low[foundLL2];
   s.lh2 = high[foundLH2];
   s.ll1 = low[foundLL1];
   s.timeLL2 = iTime(_Symbol, tf, foundLL2);
   s.demandLow = s.ll2 - InpZoneBufferPoints * _Point;
   s.demandHigh = s.lh2 + InpZoneBufferPoints * _Point;
   s.confirmationClose = close[0];

   if(s.ll2 < s.lh2 && s.ll1 < s.ll2)
   {
      // valid state if the price is in the demand zone and close above LH2
      s.valid = (SymbolInfoDouble(_Symbol, SYMBOL_BID) >= s.demandLow && SymbolInfoDouble(_Symbol, SYMBOL_BID) <= s.demandHigh && close[0] > s.lh2);
   }
   return s;
}

ReversalSet DetectReversalShort(ENUM_TIMEFRAMES tf)
{
   ReversalSet s;
   s.valid = false;
   s.isLong = false;
   s.ll2 = 0.0; s.lh2 = 0.0; s.ll1 = 0.0;

   int bars = 300;
   double open[]; double high[]; double low[]; double close[]; double volume[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return s;

   int foundHH2 = -1, foundHL2 = -1, foundHH1 = -1;
   for(int i=InpSwingLookback; i<bars-InpSwingLookback; i++)
   {
      if(IsSwingHigh(high, i, InpSwingLookback))
      {
         if(foundHH2 == -1)
         {
            foundHH2 = i;
         }
         else if(foundHL2 == -1)
         {
            foundHL2 = i;
         }
         else if(foundHH1 == -1)
         {
            foundHH1 = i;
         }
      }
   }

   if(foundHH2 < 0 || foundHL2 < 0 || foundHH1 < 0)
      return s;

   s.ll2 = low[foundHH2];
   s.lh2 = high[foundHL2];
   s.ll1 = low[foundHH1];
   s.timeLL2 = iTime(_Symbol, tf, foundHH2);
   s.demandLow = low[foundHH2] - InpZoneBufferPoints * _Point;
   s.demandHigh = high[foundHL2] + InpZoneBufferPoints * _Point;
   s.confirmationClose = close[0];

   if(high[foundHH2] > low[foundHL2] && high[foundHH1] > high[foundHH2])
   {
      s.valid = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) >= s.demandLow && SymbolInfoDouble(_Symbol, SYMBOL_ASK) <= s.demandHigh && close[0] < s.lh2);
   }
   return s;
}

SetupSignal BuildReversalSignal(ENUM_TIMEFRAMES tf, bool longBias)
{
   SetupSignal sig;
   sig.valid = false;
   sig.isLong = longBias;
   sig.tf = (int)tf;
   sig.entryPrice = 0.0;
   sig.sl = 0.0; sig.tp = 0.0;
   sig.zoneTop = 0.0; sig.zoneBottom = 0.0;
   sig.confluenceScore = 0.0;
   sig.rr = 0.0;
   sig.label = "R";
   sig.reason = "reversal";

   ReversalSet set;
   if(longBias)
      set = DetectReversalLong(tf);
   else
      set = DetectReversalShort(tf);

   if(!set.valid)
      return sig;

   double entry = longBias ? (set.ll2 + set.lh2) * 0.5 : (set.lh2 + set.ll2) * 0.5;
   double zoneLow = MathMin(set.demandLow, set.ll1);
   double zoneHigh = MathMax(set.demandHigh, set.lh2);
   double sl = longBias ? (zoneLow - InpSL_BufferPoints * _Point) : (zoneHigh + InpSL_BufferPoints * _Point);
   double tp = longBias ? (entry + MathAbs(entry - sl) * (InpMinRR + 0.5)) : (entry - MathAbs(sl - entry) * (InpMinRR + 0.5));

   sig.valid = true;
   sig.entryPrice = entry;
   sig.sl = sl;
   sig.tp = tp;
   sig.zoneTop = zoneHigh;
   sig.zoneBottom = zoneLow;
   sig.confluenceScore = 85.0;
   sig.rr = MathAbs((tp - entry) / (entry - sl));
   return sig;
}

//====================================================================
//  Engine T / trend continuation
//====================================================================
struct TrendStructure
{
   bool valid;
   bool isLong;
   double hh1;
   double hl1;
   double orderBlockLow;
   double orderBlockHigh;
   double breakerLow;
   double breakerHigh;
   double bosClose;
   datetime timeHH1;
};

TrendStructure DetectTrendContinuationLong(ENUM_TIMEFRAMES tf)
{
   TrendStructure t;
   t.valid = false; t.isLong = true; t.hh1 = 0.0; t.hl1 = 0.0; t.orderBlockLow = 0.0; t.orderBlockHigh = 0.0; t.breakerLow = 0.0; t.breakerHigh = 0.0; t.bosClose = 0.0;

   int bars = 250;
   double open[]; double high[]; double low[]; double close[]; double volume[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return t;

   // find a recent HH1-high and HL1-low where HL1 > prior confirmed low and BOS closes above HH1
   int hh1Index = -1; int hl1Index = -1;
   for(int i=5;i<bars-5;i++)
   {
      if(IsSwingHigh(high, i, InpSwingLookback))
      {
         if(high[i] > high[i-1])
         {
            hh1Index = i;
            break;
         }
      }
   }
   if(hh1Index < 0) return t;
   for(int i=hh1Index+1;i<bars-InpSwingLookback;i++)
   {
      if(IsSwingLow(low, i, InpSwingLookback) && low[i] > low[hh1Index-1])
      {
         hl1Index = i;
         break;
      }
   }
   if(hl1Index < 0) return t;

   t.hh1 = high[hh1Index];
   t.hl1 = low[hl1Index];
   t.orderBlockLow = low[hh1Index-1];
   t.orderBlockHigh = high[hh1Index-1];
   t.breakerLow = low[hl1Index];
   t.breakerHigh = high[hl1Index];
   t.bosClose = close[0];
   t.timeHH1 = iTime(_Symbol, tf, hh1Index);

   if(close[0] > t.hh1)
      t.valid = true;
   return t;
}

TrendStructure DetectTrendContinuationShort(ENUM_TIMEFRAMES tf)
{
   TrendStructure t;
   t.valid = false; t.isLong = false; t.hh1 = 0.0; t.hl1 = 0.0; t.orderBlockLow = 0.0; t.orderBlockHigh = 0.0; t.breakerLow = 0.0; t.breakerHigh = 0.0; t.bosClose = 0.0;

   int bars = 250;
   double open[]; double high[]; double low[]; double close[]; double volume[];
   if(!EnsureRateArray(_Symbol, tf, bars, open, high, low, close, volume)) return t;

   int hh1Index = -1; int hl1Index = -1;
   for(int i=5;i<bars-5;i++)
   {
      if(IsSwingLow(low, i, InpSwingLookback))
      {
         if(low[i] < low[i-1])
         {
            hh1Index = i;
            break;
         }
      }
   }
   if(hh1Index < 0) return t;
   for(int i=hh1Index+1;i<bars-InpSwingLookback;i++)
   {
      if(IsSwingHigh(high, i, InpSwingLookback) && high[i] < high[hh1Index-1])
      {
         hl1Index = i;
         break;
      }
   }
   if(hl1Index < 0) return t;

   t.hh1 = low[hh1Index];
   t.hl1 = high[hl1Index];
   t.orderBlockLow = low[hh1Index-1];
   t.orderBlockHigh = high[hh1Index-1];
   t.breakerLow = low[hl1Index];
   t.breakerHigh = high[hl1Index];
   t.bosClose = close[0];
   t.timeHH1 = iTime(_Symbol, tf, hh1Index);

   if(close[0] < t.hh1)
      t.valid = true;
   return t;
}

SetupSignal BuildTrendSignal(ENUM_TIMEFRAMES tf, bool longBias)
{
   SetupSignal sig;
   sig.valid = false;
   sig.isLong = longBias;
   sig.tf = (int)tf;
   sig.entryPrice = 0.0;
   sig.sl = 0.0; sig.tp = 0.0;
   sig.zoneTop = 0.0; sig.zoneBottom = 0.0;
   sig.confluenceScore = 0.0;
   sig.rr = 0.0;
   sig.label = "T";
   sig.reason = "trend";

   TrendStructure t = longBias ? DetectTrendContinuationLong(tf) : DetectTrendContinuationShort(tf);
   if(!t.valid)
      return sig;

   double entry = longBias ? (t.hl1 + t.hh1) * 0.5 : (t.hl1 + t.hh1) * 0.5;
   double sl = longBias ? (t.hl1 - InpSL_BufferPoints * _Point) : (t.hl1 + InpSL_BufferPoints * _Point);
   double tp = longBias ? (entry + MathAbs(entry - sl) * (InpMinRR + 0.5)) : (entry - MathAbs(sl - entry) * (InpMinRR + 0.5));
   sig.valid = true;
   sig.entryPrice = entry;
   sig.sl = sl;
   sig.tp = tp;
   sig.zoneTop = MathMax(t.orderBlockHigh, t.breakerHigh);
   sig.zoneBottom = MathMin(t.orderBlockLow, t.breakerLow);
   sig.confluenceScore = 80.0;
   sig.rr = MathAbs((tp - entry) / (entry - sl));
   return sig;
}

//====================================================================
//  Consolidation range fade (optional)
//====================================================================
SetupSignal BuildRangeFadeSignal(ENUM_TIMEFRAMES tf)
{
   SetupSignal sig;
   sig.valid = false;
   sig.tf = (int)tf;
   sig.label = "C";
   sig.reason = "range fade";

   if(!InpConsolidation_AllowRangeFade)
      return sig;

   double vah = GetVisibleVAH(tf, InpConsolidation_Lookback);
   double val = GetVisibleVAL(tf, InpConsolidation_Lookback);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(bid <= vah && bid >= val)
   {
      double entry = bid;
      double sl = (entry + (vah - val) * 0.05); // simple structural invalidation beyond range edge
      double tp = entry - (sl - entry) * (InpMinRR);
      sig.valid = true;
      sig.isLong = true;
      sig.entryPrice = entry;
      sig.sl = sl;
      sig.tp = tp;
      sig.zoneTop = vah;
      sig.zoneBottom = val;
      sig.confluenceScore = 78.0;
      sig.rr = MathAbs((tp - entry) / (entry - sl));
      return sig;
   }

   if(ask <= vah && ask >= val)
   {
      double entry = ask;
      double sl = (entry - (vah - val) * 0.05);
      double tp = entry + (entry - sl) * (InpMinRR);
      sig.valid = true;
      sig.isLong = false;
      sig.entryPrice = entry;
      sig.sl = sl;
      sig.tp = tp;
      sig.zoneTop = vah;
      sig.zoneBottom = val;
      sig.confluenceScore = 78.0;
      sig.rr = MathAbs((entry - tp) / (sl - entry));
      return sig;
   }

   return sig;
}

//====================================================================
//  Signal evaluation / entry pipeline
//====================================================================
void EvaluateSignals()
{
   if(!InpAllowTrading)
      return;

   SetupSignal bestSig;
   bestSig.valid = false;

   for(int i=0;i<7;i++)
   {
      if(g_tfList[i] == PERIOD_CURRENT)
         continue;
      RegimeState st = g_regimeSnapshot[i].state;
      if(st == REGIME_UNKNOWN) continue;

      if(st == REGIME_REVERSAL_FORMING_BULL || st == REGIME_REVERSAL_FORMING_BEAR)
      {
         SetupSignal sig = BuildReversalSignal(g_tfList[i], st == REGIME_REVERSAL_FORMING_BULL);
         if(sig.valid && (!bestSig.valid || sig.confluenceScore > bestSig.confluenceScore))
            bestSig = sig;
      }
      else if(st == REGIME_TRENDING_UP || st == REGIME_TRENDING_DOWN)
      {
         SetupSignal sig = BuildTrendSignal(g_tfList[i], st == REGIME_TRENDING_UP);
         if(sig.valid && (!bestSig.valid || sig.confluenceScore > bestSig.confluenceScore))
            bestSig = sig;
      }
      else if(st == REGIME_CONSOLIDATING)
      {
         SetupSignal sig = BuildRangeFadeSignal(g_tfList[i]);
         if(sig.valid && (!bestSig.valid || sig.confluenceScore > bestSig.confluenceScore))
            bestSig = sig;
      }
   }

   if(!bestSig.valid)
      return;

   if(bestSig.rr < InpMinRR)
      return;
   if(bestSig.confluenceScore < InpMinConfluenceScore)
      return;

   if(bestSig.isLong)
      PlaceTrade(bestSig, true);
   else
      PlaceTrade(bestSig, false);
}

void PlaceTrade(SetupSignal &sig, bool buy)
{
   if(PositionsTotal() >= InpMaxConcurrentPositions && !InpAllowMultiplePositions)
      return;

   double lot = InpUseRiskPercentSizing ? CalcLotFromRisk(sig, buy) : InpDefaultLotSize;
   if(lot <= 0.0) lot = InpDefaultLotSize;

   if(InpUsePendingOrders)
   {
      if(buy)
      {
         double price = sig.entryPrice;
         double sl = sig.sl;
         double tp = sig.tp;
         if(g_trade.BuyLimit(lot, price, _Symbol, sl, tp, 0, "SMC_BuyLimit"))
            Print("Pending buy limit placed: ", price, " SL=", sl, " TP=", tp);
      }
      else
      {
         double price = sig.entryPrice;
         double sl = sig.sl;
         double tp = sig.tp;
         if(g_trade.SellLimit(lot, price, _Symbol, sl, tp, 0, "SMC_SellLimit"))
            Print("Pending sell limit placed: ", price, " SL=", sl, " TP=", tp);
      }
      return;
   }

   if(buy)
   {
      if(g_trade.Buy(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_ASK), sig.sl, sig.tp, "SMC_Buy"))
         Print("Buy executed at ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   }
   else
   {
      if(g_trade.Sell(lot, _Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID), sig.sl, sig.tp, "SMC_Sell"))
         Print("Sell executed at ", SymbolInfoDouble(_Symbol, SYMBOL_BID));
   }
}

double CalcLotFromRisk(const SetupSignal &sig, bool buy)
{
   double accountBalance = g_account.Balance();
   if(accountBalance <= 0.0) return InpDefaultLotSize;
   double riskMoney = accountBalance * (InpRiskPercentPerTrade / 100.0);
   double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(pointValue <= 0.0)
      pointValue = 1.0;
   double dist = MathAbs(sig.entryPrice - sig.sl) / _Point;
   if(dist <= 0.0) return InpDefaultLotSize;
   double lot = riskMoney / (pointValue * dist * 0.1);
   if(lot <= 0.0) lot = InpDefaultLotSize;
   return lot;
}

//====================================================================
//  Position management / risk governance / trailing stop
//====================================================================
void ManageOpenPositions()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;

      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double price = PositionGetDouble(POSITION_PRICE_CURRENT);

      if(InpUseBreakEven && PositionGetDouble(POSITION_PROFIT) > 0.0)
      {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            if(price >= (PositionGetDouble(POSITION_PRICE_OPEN) + InpBreakEvenPoints * _Point))
            {
               g_trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN), tp);
            }
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            if(price <= (PositionGetDouble(POSITION_PRICE_OPEN) - InpBreakEvenPoints * _Point))
            {
               g_trade.PositionModify(ticket, PositionGetDouble(POSITION_PRICE_OPEN), tp);
            }
         }
      }

      if(InpUseTrailingStop)
      {
         double trailStart = InpTrailStartPoints * _Point;
         double trailStep = InpTrailStepPoints * _Point;
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            double newSL = price - trailStart;
            if(newSL > sl + trailStep)
               g_trade.PositionModify(ticket, newSL, tp);
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            double newSL = price + trailStart;
            if(newSL < sl - trailStep)
               g_trade.PositionModify(ticket, newSL, tp);
         }
      }
   }
}

//====================================================================
//  Chart objects and dashboard
//====================================================================
void DrawDashboard()
{
   if(!InpEnableDashboard)
      return;

   string name = g_dashboardName;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
   ObjectSetString(0, name, OBJPROP_TEXT,
      "Regime EA\n"
      + "D1: " + RegimeToString(GetStateForTF(PERIOD_D1)) + "\n"
      + "H4: " + RegimeToString(GetStateForTF(PERIOD_H4)) + "\n"
      + "H1: " + RegimeToString(GetStateForTF(PERIOD_H1)) + "\n"
      + "M30: " + RegimeToString(GetStateForTF(PERIOD_M30)) + "\n"
      + "M15: " + RegimeToString(GetStateForTF(PERIOD_M15)) + "\n"
      + "M5: " + RegimeToString(GetStateForTF(PERIOD_M5)) + "\n"
      + "M1: " + RegimeToString(GetStateForTF(PERIOD_M1)) + "\n"
      + "Open: " + IntegerToString(PositionsTotal()));
   ObjectSetString(0, name, OBJPROP_FONT, "Tahoma");
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
}

void ClearChartObjects()
{
   ObjectsDeleteAll(0, "SMC_");
   ObjectsDeleteAll(0, "R_");
   ObjectsDeleteAll(0, "T_");
   ObjectsDeleteAll(0, "C_");
   if(ObjectFind(0, g_dashboardName) >= 0) ObjectDelete(0, g_dashboardName);
}

string RegimeToString(RegimeState st)
{
   switch(st)
   {
      case REGIME_TRENDING_UP: return "TREND_UP";
      case REGIME_TRENDING_DOWN: return "TREND_DOWN";
      case REGIME_REVERSAL_FORMING_BULL: return "REV_BULL";
      case REGIME_REVERSAL_FORMING_BEAR: return "REV_BEAR";
      case REGIME_CONSOLIDATING: return "CONSOL";
      default: return "UNKNOWN";
   }
}

RegimeState GetStateForTF(ENUM_TIMEFRAMES tf)
{
   int idx = TFIndex(tf);
   if(idx < 0) return REGIME_UNKNOWN;
   return g_regimeSnapshot[idx].state;
}

//====================================================================
//  Alerts / notifications
//====================================================================
void SendAlertMessage(string msg)
{
   if(!InpEnableAlerts)
      return;
   Alert(msg);
   if(InpTelegramBotToken != "" && InpTelegramChatID != "")
   {
      string url = "https://api.telegram.org/bot" + InpTelegramBotToken + "/sendMessage?chat_id=" + InpTelegramChatID + "&text=" + msg;
      char result[];
      string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
      WebRequest("GET", url, headers, 5000, NULL, result, headers);
   }
}

//====================================================================
//  Utility: trend-regime state used from the specification
//====================================================================
string EngineToString(EngineType e)
{
   switch(e)
   {
      case ENGINE_REVERSAL: return "REVERSAL";
      case ENGINE_TREND: return "TREND";
      case ENGINE_CONSOLIDATION: return "CONSOLIDATION";
      default: return "NONE";
   }
}

//====================================================================
//  End of file
//====================================================================
