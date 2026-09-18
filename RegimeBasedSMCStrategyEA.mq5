//+------------------------------------------------------------------+
//| RegimeBasedSMCStrategyEA.mq5                                     |
//| Single-file regime-based SMC Expert Advisor for MT5              |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.10"
#property strict

#include <Trade/Trade.mqh>

//====================================================================
// Inputs
//====================================================================
input group "=== GENERAL ==="
input int    InpMagicNumber = 20260918;
input bool   InpAllowTrading = true;
input bool   InpScanOnTick = false;
input bool   InpRegime_UpdateOnTick = false;
input bool   InpUsePendingOrders = true;
input int    InpMaxConcurrentPositions = 1;
input int    InpMaxPendingOrders = 3;
input int    InpMaxSlippagePoints = 20;

input group "=== TIMEFRAME CASCADE ==="
input bool   InpUseTF_D1 = true;
input bool   InpUseTF_H4 = true;
input bool   InpUseTF_H1 = true;
input bool   InpUseTF_M30 = true;
input bool   InpUseTF_M15 = true;
input bool   InpUseTF_M5 = true;
input bool   InpUseTF_M1 = true;
input bool   InpTF_D1_RequireHTFZone = false;
input bool   InpTF_H4_RequireHTFZone = false;
input bool   InpTF_H1_RequireHTFZone = false;
input bool   InpTF_M30_RequireHTFZone = false;
input bool   InpTF_M15_RequireHTFZone = false;
input bool   InpTF_M5_RequireHTFZone = false;
input bool   InpTF_M1_RequireHTFZone = false;
input ENUM_TIMEFRAMES InpRegimeSource_TF = PERIOD_D1;
input ENUM_TIMEFRAMES InpConcurrentEntry_MinTF = PERIOD_H1;
input bool   InpAllowConcurrentTFEntries = true;
input bool   InpMasterConsolidationOverridesLocal = true;

input group "=== REGIME CLASSIFIER ==="
input int    InpRegime_SwingCount = 3;
input int    InpSwingLookback = 2;
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
input int    InpRetraceMode = 4; // 0=VolumeNode,1=EngulfedCandle,2=LastBullBeforeBreak,3=FibLevel,4=PriorityCascade,5=AllConfluence
input double InpFibLevel = 0.618;
input double InpConfluenceZoneTolerancePoints = 5.0;
input bool   InpEngineR_UsePendingOnly = false;

input group "=== ENGINE T: TREND CONTINUATION ==="
input bool   InpEngineT_Enabled = true;
input bool   InpEngineT_GateSourceBias = true;
input int    InpContinuationZoneMode = 3; // 0=OrderBlock,1=Breaker,2=FibLevel,3=PriorityCascade,4=AllConfluence
input int    InpContinuation_EntryTiming = 0; // 0=PostBOSOnly,1=AllowPreConfirmation
input double InpContinuationFibLevel = 0.618;
input double InpMinConfluenceScore_PreConfirm = 90.0;

input group "=== ENGINE C / STAY OUT ==="
input bool   InpConsolidation_StayOut = true;
input bool   InpConsolidation_AllowRangeFade = false;
input double InpRangeFade_RiskMultiplier = 0.5;
input int    InpRangeFade_MaxBars = 50;

input group "=== RISK / EXECUTION ==="
input bool   InpUseRiskPercentSizing = true;
input double InpRiskPercentPerTrade = 0.5;
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
input int    InpPartialTP_Ratio = 50; // legacy TP1 partial-close percent alias
input double InpTP1Ratio = 1.0;
input double InpTP2Ratio = 1.5;
input double InpTP3Ratio = 2.0;
input double InpTP4Ratio = 2.5;
input double InpTP5Ratio = 3.0;
input double InpTP1ClosePercent = 50.0;
input double InpTP2ClosePercent = 15.0;
input double InpTP3ClosePercent = 15.0;
input double InpTP4ClosePercent = 10.0;
input double InpTP5ClosePercent = 10.0;
input int    InpProfitTargetMode = 0; // 0=disabled 1=minute 2=hour 3=session 4=day
input double InpProfitTargetPercent = 100.0;
input int    InpLossLimitMode = 0;    // 0=disabled 1=minute 2=hour 3=session 4=day
input double InpLossLimitPercent = 5.0;

input group "=== FILTERS ==="
input bool   InpUseNewsBlackout = false;
input int    InpNewsBlackoutMinutesBefore = 30;
input int    InpNewsBlackoutMinutesAfter = 30;
input string InpManualNewsTimesUTC = "";
input bool   InpUseSessionFilter = false;
input int    InpSessionStartHour = 0;
input int    InpSessionEndHour = 23;
input bool   InpUseTickLevelScan = false;

input group "=== UI / ALERTS ==="
input bool   InpEnableDashboard = true;
input bool   InpEnableAlerts = true;
input bool   InpDrawSetupLabels = true;
input bool   InpDrawSetupLines = true;
input bool   InpDrawSetupZones = true;
input bool   InpSendPushNotifications = false;
input string InpTelegramBotToken = "";
input string InpTelegramChatID = "";

input group "=== ADAPTIVE LEARNING ==="
input bool   InpAdaptiveLearning_Enabled = false;
input int    InpAdaptiveLearning_Window = 50;
input double InpAdaptiveLearning_ThresholdShift = 5.0;

//====================================================================
// Enums / structs
//====================================================================
enum RegimeState
{
   REGIME_TRENDING_UP = 0,
   REGIME_TRENDING_DOWN,
   REGIME_REVERSAL_FORMING_BULL,
   REGIME_REVERSAL_FORMING_BEAR,
   REGIME_CONSOLIDATING,
   REGIME_UNKNOWN
};

enum EngineType
{
   ENGINE_NONE = 0,
   ENGINE_REVERSAL,
   ENGINE_TREND,
   ENGINE_CONSOLIDATION
};

enum RetraceMode
{
   RETRACE_VOLUME_NODE = 0,
   RETRACE_ENGULFED_CANDLE,
   RETRACE_LAST_BULL_BEFORE_BREAK,
   RETRACE_FIB_LEVEL,
   RETRACE_PRIORITY_CASCADE,
   RETRACE_ALL_CONFLUENCE
};

enum ContinuationZoneMode
{
   CONT_ZONE_ORDER_BLOCK = 0,
   CONT_ZONE_BREAKER,
   CONT_ZONE_FIB_LEVEL,
   CONT_ZONE_PRIORITY_CASCADE,
   CONT_ZONE_ALL_CONFLUENCE
};

enum ContinuationEntryTiming
{
   CONT_ENTRY_POST_BOS_ONLY = 0,
   CONT_ENTRY_ALLOW_PRECONFIRM
};

struct SwingPoint
{
   int      index;
   double   price;
   datetime time;
   bool     isHigh;
   bool     valid;
};

struct PriceZone
{
   double   low;
   double   high;
   datetime time;
   string   label;
   bool     valid;
};

struct VolumeProfileResult
{
   double node;
   double vah;
   double val;
   double totalVolume;
   bool   valid;
};

struct RegimeSnapshot
{
   RegimeState state;
   datetime    barTime;
   double      adx;
   double      atr;
   double      atrAvg;
   double      rollingHigh;
   double      rollingLow;
   double      vah;
   double      val;
   PriceZone   biasZone;
   bool        valid;
};

struct ReversalStructure
{
   bool       valid;
   bool       isLong;
   SwingPoint ll2;
   SwingPoint lh2;
   SwingPoint ll1;
   SwingPoint confirmation;
   PriceZone  originZone;
   PriceZone  retraceZone;
   bool       confirmed;
   int        retraceModeUsed;
};

struct TrendStructure
{
   bool       valid;
   bool       isLong;
   SwingPoint priorSwing;
   SwingPoint hh1;
   SwingPoint hl1;
   SwingPoint confirmation;
   SwingPoint hh2;
   PriceZone  orderBlockZone;
   PriceZone  breakerZone;
   PriceZone  chosenZone;
   bool       confirmed;
   int        zoneModeUsed;
};

struct SetupSignal
{
   bool            valid;
   bool            isLong;
   bool            pendingPreferred;
   bool            confirmed;
   EngineType      engine;
   ENUM_TIMEFRAMES tf;
   double          entryPrice;
   double          sl;
   double          tp1;
   double          tp2;
   double          tp3;
   double          tp4;
   double          tp5;
   double          finalTp;
   double          zoneLow;
   double          zoneHigh;
   double          confluenceScore;
   double          rr;
   double          riskMultiplier;
   datetime        signalTime;
   string          signature;
   string          comment;
   string          reason;
   string          zoneLabel;
   datetime        aTime1;
   datetime        aTime2;
   datetime        aTime3;
   datetime        aTime4;
   datetime        aTime5;
   double          aPrice1;
   double          aPrice2;
   double          aPrice3;
   double          aPrice4;
   double          aPrice5;
   string          aLabel1;
   string          aLabel2;
   string          aLabel3;
   string          aLabel4;
   string          aLabel5;
};

struct ManagedPositionState
{
   ulong  ticket;
   ulong  positionId;
   int    engineCode;
   double realizedProfit;
   double initialRiskDistance;
   bool   tp1Done;
   bool   tp2Done;
   bool   tp3Done;
   bool   tp4Done;
   bool   tp5Done;
   bool   active;
};

struct AdaptiveStats
{
   int wins;
   int losses;
};

//====================================================================
// Globals
//====================================================================
CTrade g_trade;
ENUM_TIMEFRAMES g_tfList[7];
RegimeSnapshot  g_regimes[7];
RegimeState     g_prevRegime[7];
datetime        g_lastTFBarTime[7];
string          g_lastSignalSignature[7];
datetime        g_lastSignalStamp[7];
ManagedPositionState g_positionStates[];
AdaptiveStats   g_adaptiveStats[3];
int             g_adaptiveOutcomesR[];
int             g_adaptiveOutcomesT[];
int             g_adaptiveOutcomesC[];
int             g_tfCount = 0;
int             g_magic = 0;
string          g_objectPrefix = "";
string          g_dashboardName = "";
datetime        g_lastChartBarTime = 0;
datetime        g_profitGovernanceStart = 0;
datetime        g_lossGovernanceStart = 0;
double          g_profitGovernanceBaseEquity = 0.0;
double          g_lossGovernanceBaseEquity = 0.0;
int             g_atrHandles[7];
int             g_adxHandles[7];

//====================================================================
// Forward declarations
//====================================================================
void BuildTFList();
void ResetRuntimeState();
bool UpdateSingleRegime(const int idx, const bool force);
void UpdateRegimes(const bool force);
void EvaluateSignals();
void ManageOpenPositions();
void DrawDashboard();
void ClearChartObjects();
void SendAlertMessage(const string msg);
double NormalizePrice(const double price);
double NormalizeVolume(const double volume);
double CalcLotFromRisk(const SetupSignal &sig);
int CountManagedPositions();
int CountManagedPendingOrders();
bool SubmitSignal(const SetupSignal &sig);
bool LoadRates(const ENUM_TIMEFRAMES tf, const int bars, MqlRates &rates[]);
bool CollectSwings(MqlRates &rates[], SwingPoint &highs[], int &highCount, SwingPoint &lows[], int &lowCount, SwingPoint &allSwings[], int &swingCount);
double GetATRValue(const ENUM_TIMEFRAMES tf, const int period, const int shift);
double GetATRAverage(const ENUM_TIMEFRAMES tf, const int period, const int bars);
double GetADXValue(const ENUM_TIMEFRAMES tf, const int period, const int shift);
bool CalcVolumeProfile(MqlRates &rates[], const int olderIndex, const int newerIndex, const double rangeLow, const double rangeHigh, VolumeProfileResult &vp);
RegimeState ClassifyRegime(const ENUM_TIMEFRAMES tf, RegimeSnapshot &snapshot);
ReversalStructure DetectReversalStructure(const ENUM_TIMEFRAMES tf, const bool isLong);
TrendStructure DetectTrendStructure(const ENUM_TIMEFRAMES tf, const bool isLong);
SetupSignal BuildReversalSignal(const ENUM_TIMEFRAMES tf, const bool isLong);
SetupSignal BuildTrendSignal(const ENUM_TIMEFRAMES tf, const bool isLong);
SetupSignal BuildRangeFadeSignal(const ENUM_TIMEFRAMES tf);
double GetAdaptiveThreshold(const EngineType engine, const double baseThreshold);
void DrawSetup(const SetupSignal &sig);
bool RequiresHigherTFZone(const int idx);
bool PassesHigherTFZoneRequirement(const int idx);
bool IsTradingSuppressed();
bool IsSessionOpen();
bool IsNewsBlackoutActive();
bool IsGovernanceTripped();
void ResetGovernanceWindowIfNeeded();
void UpdateAdaptiveStatsFromDeal(const ulong dealTicket);
int GetPositionStateIndex(const ulong ticket);
RegimeState ResolveMasterState(const RegimeState fallbackState);
void CancelManagedPendingOrders();
bool HasOpenManagedPositionId(const ulong positionId);
datetime SessionAnchorTime(const datetime sourceTime);
void RecordAdaptiveOutcome(const int idx, const bool win);
void InitializeIndicatorHandles();
void ReleaseIndicatorHandles();
datetime ParseUtcInputTimestamp(const string rawValue);

//====================================================================
// Lifecycle
//====================================================================
int OnInit()
{
   g_magic = InpMagicNumber;
   g_objectPrefix = StringFormat("RBSMC_%d_", g_magic);
   g_dashboardName = g_objectPrefix + "DASH";
   g_trade.SetExpertMagicNumber(g_magic);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   BuildTFList();
   ResetRuntimeState();
   InitializeIndicatorHandles();
   ResetGovernanceWindowIfNeeded();
   EventSetTimer(1);
   UpdateRegimes(true);
   DrawDashboard();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ReleaseIndicatorHandles();
   ClearChartObjects();
}

void OnTick()
{
   UpdateRegimes(false);
   ManageOpenPositions();
   if(IsTradingSuppressed())
      CancelManagedPendingOrders();

   bool shouldScan = InpScanOnTick || InpUseTickLevelScan;
   datetime currentBar = iTime(_Symbol, _Period, 0);
   if(currentBar != g_lastChartBarTime)
   {
      shouldScan = true;
      g_lastChartBarTime = currentBar;
   }

   if(shouldScan && !IsTradingSuppressed())
      EvaluateSignals();

   DrawDashboard();
}

void OnTimer()
{
   UpdateRegimes(false);
   ManageOpenPositions();
   if(IsTradingSuppressed())
      CancelManagedPendingOrders();
   else
      EvaluateSignals();
   DrawDashboard();
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   if(trans.deal == 0)
      return;
   UpdateAdaptiveStatsFromDeal(trans.deal);
}

//====================================================================
// General helpers
//====================================================================
void BuildTFList()
{
   g_tfCount = 0;
   if(InpUseTF_D1)  g_tfList[g_tfCount++] = PERIOD_D1;
   if(InpUseTF_H4)  g_tfList[g_tfCount++] = PERIOD_H4;
   if(InpUseTF_H1)  g_tfList[g_tfCount++] = PERIOD_H1;
   if(InpUseTF_M30) g_tfList[g_tfCount++] = PERIOD_M30;
   if(InpUseTF_M15) g_tfList[g_tfCount++] = PERIOD_M15;
   if(InpUseTF_M5)  g_tfList[g_tfCount++] = PERIOD_M5;
   if(InpUseTF_M1)  g_tfList[g_tfCount++] = PERIOD_M1;

   while(g_tfCount < 7)
   {
      g_tfList[g_tfCount] = PERIOD_CURRENT;
      g_tfCount++;
   }
}

bool HasOpenManagedPositionId(const ulong positionId)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != g_magic)
         continue;
      if((ulong)PositionGetInteger(POSITION_IDENTIFIER) == positionId)
         return true;
   }
   return false;
}

void RecordAdaptiveOutcome(const int idx, const bool win)
{
   int outcome = win ? 1 : -1;
   int size = 0;
   if(idx == 1)
   {
      size = ArraySize(g_adaptiveOutcomesT);
      ArrayResize(g_adaptiveOutcomesT, size + 1);
      g_adaptiveOutcomesT[size] = outcome;
      if(ArraySize(g_adaptiveOutcomesT) > InpAdaptiveLearning_Window)
      {
         for(int i = 1; i < ArraySize(g_adaptiveOutcomesT); i++)
            g_adaptiveOutcomesT[i - 1] = g_adaptiveOutcomesT[i];
         ArrayResize(g_adaptiveOutcomesT, ArraySize(g_adaptiveOutcomesT) - 1);
      }
      g_adaptiveStats[idx].wins = 0;
      g_adaptiveStats[idx].losses = 0;
      for(int i = 0; i < ArraySize(g_adaptiveOutcomesT); i++)
         if(g_adaptiveOutcomesT[i] > 0) g_adaptiveStats[idx].wins++; else g_adaptiveStats[idx].losses++;
      return;
   }
   if(idx == 2)
   {
      size = ArraySize(g_adaptiveOutcomesC);
      ArrayResize(g_adaptiveOutcomesC, size + 1);
      g_adaptiveOutcomesC[size] = outcome;
      if(ArraySize(g_adaptiveOutcomesC) > InpAdaptiveLearning_Window)
      {
         for(int i = 1; i < ArraySize(g_adaptiveOutcomesC); i++)
            g_adaptiveOutcomesC[i - 1] = g_adaptiveOutcomesC[i];
         ArrayResize(g_adaptiveOutcomesC, ArraySize(g_adaptiveOutcomesC) - 1);
      }
      g_adaptiveStats[idx].wins = 0;
      g_adaptiveStats[idx].losses = 0;
      for(int i = 0; i < ArraySize(g_adaptiveOutcomesC); i++)
         if(g_adaptiveOutcomesC[i] > 0) g_adaptiveStats[idx].wins++; else g_adaptiveStats[idx].losses++;
      return;
   }

   size = ArraySize(g_adaptiveOutcomesR);
   ArrayResize(g_adaptiveOutcomesR, size + 1);
   g_adaptiveOutcomesR[size] = outcome;
   if(ArraySize(g_adaptiveOutcomesR) > InpAdaptiveLearning_Window)
   {
      for(int i = 1; i < ArraySize(g_adaptiveOutcomesR); i++)
         g_adaptiveOutcomesR[i - 1] = g_adaptiveOutcomesR[i];
      ArrayResize(g_adaptiveOutcomesR, ArraySize(g_adaptiveOutcomesR) - 1);
   }
   g_adaptiveStats[idx].wins = 0;
   g_adaptiveStats[idx].losses = 0;
   for(int i = 0; i < ArraySize(g_adaptiveOutcomesR); i++)
      if(g_adaptiveOutcomesR[i] > 0) g_adaptiveStats[idx].wins++; else g_adaptiveStats[idx].losses++;
}

void ResetRuntimeState()
{
   for(int i = 0; i < 7; i++)
   {
      g_prevRegime[i] = REGIME_UNKNOWN;
      g_regimes[i].state = REGIME_UNKNOWN;
      g_regimes[i].valid = false;
      g_lastTFBarTime[i] = 0;
      g_lastSignalSignature[i] = "";
      g_lastSignalStamp[i] = 0;
      g_atrHandles[i] = INVALID_HANDLE;
      g_adxHandles[i] = INVALID_HANDLE;
   }
   ArrayResize(g_positionStates, 0);
   for(int e = 0; e < 3; e++)
   {
      g_adaptiveStats[e].wins = 0;
      g_adaptiveStats[e].losses = 0;
   }
   ArrayResize(g_adaptiveOutcomesR, 0);
   ArrayResize(g_adaptiveOutcomesT, 0);
   ArrayResize(g_adaptiveOutcomesC, 0);
}

int TFIndex(const ENUM_TIMEFRAMES tf)
{
   for(int i = 0; i < 7; i++)
      if(g_tfList[i] == tf)
         return i;
   return -1;
}

string TimeframeToString(const ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      default:         return "CUR";
   }
}

string RegimeToString(const RegimeState state)
{
   switch(state)
   {
      case REGIME_TRENDING_UP:           return "TREND_UP";
      case REGIME_TRENDING_DOWN:         return "TREND_DOWN";
      case REGIME_REVERSAL_FORMING_BULL: return "REV_BULL";
      case REGIME_REVERSAL_FORMING_BEAR: return "REV_BEAR";
      case REGIME_CONSOLIDATING:         return "CONSOL";
      default:                           return "UNKNOWN";
   }
}

string EngineToString(const EngineType engine)
{
   switch(engine)
   {
      case ENGINE_REVERSAL:      return "R";
      case ENGINE_TREND:         return "T";
      case ENGINE_CONSOLIDATION: return "C";
      default:                   return "N";
   }
}

double NormalizePrice(const double price)
{
   return NormalizeDouble(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
}

int VolumeDigitsFromStep(const double step)
{
   if(step <= 0.0)
      return 2;
   int digits = 0;
   double work = step;
   while(digits < 8 && MathAbs(work - MathRound(work)) > 1e-8)
   {
      work *= 10.0;
      digits++;
   }
   return digits;
}

double NormalizeVolume(const double volume)
{
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0 || maxVol <= 0.0)
      return 0.0;

   double clipped = MathMax(minVol, MathMin(maxVol, volume));
   double steps   = MathFloor((clipped - minVol) / step + 0.5);
   double result  = minVol + steps * step;
   return NormalizeDouble(result, VolumeDigitsFromStep(step));
}

double CurrentMidPrice()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0.0 || ask <= 0.0)
      return 0.0;
   return (bid + ask) * 0.5;
}

bool IsPriceInsideZone(const double price, const PriceZone &zone)
{
   if(!zone.valid)
      return false;
   return (price >= zone.low && price <= zone.high);
}

bool LoadRates(const ENUM_TIMEFRAMES tf, const int bars, MqlRates &rates[])
{
   int need = MathMax(bars, InpSwingLookback * 2 + 20);
   ArrayResize(rates, 0);
   int copied = CopyRates(_Symbol, tf, 0, need, rates);
   if(copied < need)
      return false;
   ArraySetAsSeries(rates, true);
   return true;
}

bool BreaksLevel(const MqlRates &bar, const double level, const bool breakUp)
{
   if(InpUseWickForBreak)
      return breakUp ? (bar.high > level) : (bar.low < level);
   return breakUp ? (bar.close > level) : (bar.close < level);
}

bool IsSwingHigh(MqlRates &rates[], const int bars, const int idx, const int lookback)
{
   if(idx < lookback || idx + lookback >= bars)
      return false;
   double value = rates[idx].high;
   for(int i = idx - lookback; i <= idx + lookback; i++)
   {
      if(i == idx)
         continue;
      if(rates[i].high >= value)
         return false;
   }
   return true;
}

bool IsSwingLow(MqlRates &rates[], const int bars, const int idx, const int lookback)
{
   if(idx < lookback || idx + lookback >= bars)
      return false;
   double value = rates[idx].low;
   for(int i = idx - lookback; i <= idx + lookback; i++)
   {
      if(i == idx)
         continue;
      if(rates[i].low <= value)
         return false;
   }
   return true;
}

void PushSwing(SwingPoint &arr[], int &count, const int idx, const double price, const datetime time, const bool isHigh)
{
   ArrayResize(arr, count + 1);
   arr[count].index = idx;
   arr[count].price = price;
   arr[count].time = time;
   arr[count].isHigh = isHigh;
   arr[count].valid = true;
   count++;
}

bool CollectSwings(MqlRates &rates[], SwingPoint &highs[], int &highCount, SwingPoint &lows[], int &lowCount, SwingPoint &allSwings[], int &swingCount)
{
   highCount = 0;
   lowCount = 0;
   swingCount = 0;
   ArrayResize(highs, 0);
   ArrayResize(lows, 0);
   ArrayResize(allSwings, 0);

   int bars = ArraySize(rates);
   int look = MathMax(1, InpSwingLookback);
   if(bars <= look * 2 + 5)
      return false;

   for(int idx = bars - look - 1; idx >= look + 1; idx--)
   {
      if(IsSwingHigh(rates, bars, idx, look))
      {
         PushSwing(highs, highCount, idx, rates[idx].high, rates[idx].time, true);
         PushSwing(allSwings, swingCount, idx, rates[idx].high, rates[idx].time, true);
      }
      if(IsSwingLow(rates, bars, idx, look))
      {
         PushSwing(lows, lowCount, idx, rates[idx].low, rates[idx].time, false);
         PushSwing(allSwings, swingCount, idx, rates[idx].low, rates[idx].time, false);
      }
   }

   for(int i = 0; i < swingCount - 1; i++)
   {
      for(int j = i + 1; j < swingCount; j++)
      {
         if(allSwings[i].index < allSwings[j].index)
         {
            SwingPoint tmp = allSwings[i];
            allSwings[i] = allSwings[j];
            allSwings[j] = tmp;
         }
      }
   }
   return (highCount > 0 || lowCount > 0);
}

void InitializeIndicatorHandles()
{
   for(int i = 0; i < 7; i++)
   {
      if(g_tfList[i] == PERIOD_CURRENT)
         continue;
      g_atrHandles[i] = iATR(_Symbol, g_tfList[i], InpATR_Period);
      g_adxHandles[i] = iADX(_Symbol, g_tfList[i], InpADX_Period);
   }
}

void ReleaseIndicatorHandles()
{
   for(int i = 0; i < 7; i++)
   {
      if(g_atrHandles[i] != INVALID_HANDLE)
      {
         IndicatorRelease(g_atrHandles[i]);
         g_atrHandles[i] = INVALID_HANDLE;
      }
      if(g_adxHandles[i] != INVALID_HANDLE)
      {
         IndicatorRelease(g_adxHandles[i]);
         g_adxHandles[i] = INVALID_HANDLE;
      }
   }
}

double GetATRValue(const ENUM_TIMEFRAMES tf, const int period, const int shift)
{
   int idx = TFIndex(tf);
   int handle = (idx >= 0) ? g_atrHandles[idx] : INVALID_HANDLE;
   if(handle == INVALID_HANDLE)
      handle = iATR(_Symbol, tf, period);
   if(handle == INVALID_HANDLE)
      return 0.0;
   double buffer[];
   ArrayResize(buffer, 1);
   int copied = CopyBuffer(handle, 0, shift, 1, buffer);
   if(idx < 0)
      IndicatorRelease(handle);
   if(copied != 1)
      return 0.0;
   return buffer[0];
}

double GetATRAverage(const ENUM_TIMEFRAMES tf, const int period, const int bars)
{
   int idx = TFIndex(tf);
   int handle = (idx >= 0) ? g_atrHandles[idx] : INVALID_HANDLE;
   if(handle == INVALID_HANDLE)
      handle = iATR(_Symbol, tf, period);
   if(handle == INVALID_HANDLE)
      return 0.0;
   double buffer[];
   ArrayResize(buffer, bars);
   int copied = CopyBuffer(handle, 0, 1, bars, buffer);
   if(idx < 0)
      IndicatorRelease(handle);
   if(copied <= 0)
      return 0.0;
   double sum = 0.0;
   for(int i = 0; i < copied; i++)
      sum += buffer[i];
   return sum / copied;
}

double GetADXValue(const ENUM_TIMEFRAMES tf, const int period, const int shift)
{
   int idx = TFIndex(tf);
   int handle = (idx >= 0) ? g_adxHandles[idx] : INVALID_HANDLE;
   if(handle == INVALID_HANDLE)
      handle = iADX(_Symbol, tf, period);
   if(handle == INVALID_HANDLE)
      return 0.0;
   double buffer[];
   ArrayResize(buffer, 1);
   int copied = CopyBuffer(handle, 0, shift, 1, buffer);
   if(idx < 0)
      IndicatorRelease(handle);
   if(copied != 1)
      return 0.0;
   return buffer[0];
}

bool CalcVolumeProfile(MqlRates &rates[], const int olderIndex, const int newerIndex, const double rangeLow, const double rangeHigh, VolumeProfileResult &vp)
{
   vp.valid = false;
   vp.node = 0.0;
   vp.vah = 0.0;
   vp.val = 0.0;
   vp.totalVolume = 0.0;

   if(rangeHigh <= rangeLow)
      return false;

   double bucketSize = MathMax(_Point, InpVP_BucketPoints * _Point);
   int bucketCount = (int)MathFloor((rangeHigh - rangeLow) / bucketSize) + 1;
   if(bucketCount < 1)
      bucketCount = 1;

   double buckets[];
   ArrayResize(buckets, bucketCount);
   ArrayInitialize(buckets, 0.0);

   int startIndex = MathMax(olderIndex, newerIndex);
   int endIndex = MathMin(olderIndex, newerIndex);
   int bars = ArraySize(rates);
   if(startIndex >= bars)
      startIndex = bars - 1;
   if(endIndex < 1)
      endIndex = 1;

   for(int i = startIndex; i >= endIndex; i--)
   {
      double vol = (double)rates[i].tick_volume;
      if(vol <= 0.0)
         vol = 1.0;
      double barLow = MathMax(rangeLow, rates[i].low);
      double barHigh = MathMin(rangeHigh, rates[i].high);
      if(barHigh < barLow)
         continue;

      int lowBucket = (int)MathFloor((barLow - rangeLow) / bucketSize);
      int highBucket = (int)MathFloor((barHigh - rangeLow) / bucketSize);
      lowBucket = MathMax(0, MathMin(bucketCount - 1, lowBucket));
      highBucket = MathMax(0, MathMin(bucketCount - 1, highBucket));
      int covered = MathMax(1, highBucket - lowBucket + 1);
      double share = vol / covered;

      for(int b = lowBucket; b <= highBucket; b++)
      {
         buckets[b] += share;
         vp.totalVolume += share;
      }
   }

   if(vp.totalVolume <= 0.0)
      return false;

   int poc = 0;
   for(int i = 1; i < bucketCount; i++)
      if(buckets[i] > buckets[poc])
         poc = i;

   int left = poc;
   int right = poc;
   double valueArea = buckets[poc];
   double targetArea = vp.totalVolume * 0.70;

   while(valueArea < targetArea && (left > 0 || right < bucketCount - 1))
   {
      double leftVol = (left > 0) ? buckets[left - 1] : -1.0;
      double rightVol = (right < bucketCount - 1) ? buckets[right + 1] : -1.0;
      if(rightVol > leftVol)
      {
         right++;
         valueArea += buckets[right];
      }
      else if(left > 0)
      {
         left--;
         valueArea += buckets[left];
      }
      else
      {
         right++;
         valueArea += buckets[right];
      }
   }

   vp.node = NormalizePrice(rangeLow + (poc + 0.5) * bucketSize);
   vp.val = NormalizePrice(rangeLow + left * bucketSize);
   vp.vah = NormalizePrice(rangeLow + (right + 1) * bucketSize);
   vp.valid = true;
   return true;
}

PriceZone MakeZone(const double low, const double high, const datetime time, const string label)
{
   PriceZone zone;
   zone.low = NormalizePrice(MathMin(low, high));
   zone.high = NormalizePrice(MathMax(low, high));
   zone.time = time;
   zone.label = label;
   zone.valid = (zone.high > zone.low);
   return zone;
}

bool IntersectZones(const PriceZone &a, const PriceZone &b, const double tolerancePoints, PriceZone &outZone)
{
   outZone.valid = false;
   if(!a.valid || !b.valid)
      return false;
   double low = MathMax(a.low, b.low) - tolerancePoints * _Point;
   double high = MathMin(a.high, b.high) + tolerancePoints * _Point;
   if(high <= low)
      return false;
   outZone = MakeZone(low, high, MathMax(a.time, b.time), a.label + "+" + b.label);
   return outZone.valid;
}

PriceZone FindOriginZone(MqlRates &rates[], const int olderIndex, const int newerIndex, const bool bullish)
{
   int startIndex = MathMax(olderIndex, newerIndex);
   int endIndex = MathMin(olderIndex, newerIndex);
   int found = -1;

   for(int i = startIndex; i >= endIndex; i--)
   {
      bool bearishCandle = (rates[i].close < rates[i].open);
      bool bullishCandle = (rates[i].close > rates[i].open);
      if((bullish && bearishCandle) || (!bullish && bullishCandle))
      {
         found = i;
         break;
      }
   }
   if(found < 0)
      found = startIndex;

   return MakeZone(rates[found].low - InpZoneBufferPoints * _Point,
                   rates[found].high + InpZoneBufferPoints * _Point,
                   rates[found].time,
                   bullish ? "Demand" : "Supply");
}

PriceZone CandleZone(MqlRates &rates[], const int idx, const string label)
{
   if(idx < 0 || idx >= ArraySize(rates))
   {
      PriceZone z;
      z.valid = false;
      return z;
   }
   return MakeZone(rates[idx].low - InpZoneBufferPoints * _Point,
                   rates[idx].high + InpZoneBufferPoints * _Point,
                   rates[idx].time,
                   label);
}

int FindBreakIndex(MqlRates &rates[], const int afterIndex, const double level, const bool breakUp)
{
   for(int i = afterIndex - 1; i >= 1; i--)
      if(BreaksLevel(rates[i], level, breakUp))
         return i;
   return -1;
}

double PriceAtZoneEntry(const PriceZone &zone)
{
   return NormalizePrice((zone.low + zone.high) * 0.5);
}

double ZoneWidthPoints(const PriceZone &zone)
{
   if(!zone.valid)
      return 0.0;
   return (zone.high - zone.low) / _Point;
}

double ComputeRR(const bool isLong, const double entry, const double sl, const double tp)
{
   double risk = MathAbs(entry - sl);
   if(risk <= 0.0)
      return 0.0;
   double reward = isLong ? (tp - entry) : (entry - tp);
   return reward / risk;
}

bool RecentHighsHigher(SwingPoint &highs[], const int count, const int required)
{
   if(count < required)
      return false;
   int start = count - required;
   for(int i = start + 1; i < count; i++)
      if(highs[i].price <= highs[i - 1].price)
         return false;
   return true;
}

bool RecentLowsHigher(SwingPoint &lows[], const int count, const int required)
{
   if(count < required)
      return false;
   int start = count - required;
   for(int i = start + 1; i < count; i++)
      if(lows[i].price <= lows[i - 1].price)
         return false;
   return true;
}

bool RecentHighsLower(SwingPoint &highs[], const int count, const int required)
{
   if(count < required)
      return false;
   int start = count - required;
   for(int i = start + 1; i < count; i++)
      if(highs[i].price >= highs[i - 1].price)
         return false;
   return true;
}

bool RecentLowsLower(SwingPoint &lows[], const int count, const int required)
{
   if(count < required)
      return false;
   int start = count - required;
   for(int i = start + 1; i < count; i++)
      if(lows[i].price >= lows[i - 1].price)
         return false;
   return true;
}

//====================================================================
// Regime analysis
//====================================================================
ReversalStructure DetectReversalStructure(const ENUM_TIMEFRAMES tf, const bool isLong)
{
   ReversalStructure structure;
   structure.valid = false;
   structure.isLong = isLong;
   structure.confirmed = false;
   structure.retraceModeUsed = RETRACE_VOLUME_NODE;

   MqlRates rates[];
   if(!LoadRates(tf, 400, rates))
      return structure;

   SwingPoint highs[], lows[], allSwings[];
   int highCount = 0, lowCount = 0, swingCount = 0;
   if(!CollectSwings(rates, highs, highCount, lows, lowCount, allSwings, swingCount))
      return structure;
   if(swingCount < 3)
      return structure;

   for(int i = swingCount - 1; i >= 2; i--)
   {
      SwingPoint a = allSwings[i - 2];
      SwingPoint b = allSwings[i - 1];
      SwingPoint c = allSwings[i];

      if(isLong)
      {
         if(a.isHigh || !b.isHigh || c.isHigh)
            continue;
         if(!(a.price < b.price && c.price < a.price))
            continue;

         int breakIndex = FindBreakIndex(rates, c.index, b.price, true);
         PriceZone origin = FindOriginZone(rates, a.index, b.index, true);

         structure.ll2 = a;
         structure.lh2 = b;
         structure.ll1 = c;
         structure.originZone = origin;
         structure.confirmed = (breakIndex > 0);
         if(structure.confirmed)
         {
            structure.confirmation.index = breakIndex;
            structure.confirmation.price = InpUseWickForBreak ? rates[breakIndex].high : rates[breakIndex].close;
            structure.confirmation.time = rates[breakIndex].time;
            structure.confirmation.isHigh = true;
            structure.confirmation.valid = true;
         }
         structure.valid = true;
         return structure;
      }
      else
      {
         if(!a.isHigh || b.isHigh || !c.isHigh)
            continue;
         if(!(a.price > b.price && c.price > a.price))
            continue;

         int breakIndex = FindBreakIndex(rates, c.index, b.price, false);
         PriceZone origin = FindOriginZone(rates, a.index, b.index, false);

         structure.ll2 = a;
         structure.lh2 = b;
         structure.ll1 = c;
         structure.originZone = origin;
         structure.confirmed = (breakIndex > 0);
         if(structure.confirmed)
         {
            structure.confirmation.index = breakIndex;
            structure.confirmation.price = InpUseWickForBreak ? rates[breakIndex].low : rates[breakIndex].close;
            structure.confirmation.time = rates[breakIndex].time;
            structure.confirmation.isHigh = false;
            structure.confirmation.valid = true;
         }
         structure.valid = true;
         return structure;
      }
   }

   return structure;
}

TrendStructure DetectTrendStructure(const ENUM_TIMEFRAMES tf, const bool isLong)
{
   TrendStructure structure;
   structure.valid = false;
   structure.isLong = isLong;
   structure.confirmed = false;
   structure.zoneModeUsed = CONT_ZONE_ORDER_BLOCK;

   MqlRates rates[];
   if(!LoadRates(tf, 400, rates))
      return structure;

   SwingPoint highs[], lows[], allSwings[];
   int highCount = 0, lowCount = 0, swingCount = 0;
   if(!CollectSwings(rates, highs, highCount, lows, lowCount, allSwings, swingCount))
      return structure;
   if(swingCount < 3)
      return structure;

   for(int i = swingCount - 1; i >= 2; i--)
   {
      SwingPoint a = allSwings[i - 2];
      SwingPoint b = allSwings[i - 1];
      SwingPoint c = allSwings[i];

      if(isLong)
      {
         if(a.isHigh || !b.isHigh || c.isHigh)
            continue;
         if(!(c.price > a.price))
            continue;

         int breakIndex = FindBreakIndex(rates, c.index, b.price, true);
         structure.priorSwing = a;
         structure.hh1 = b;
         structure.hl1 = c;
         structure.orderBlockZone = FindOriginZone(rates, a.index, b.index, true);
         structure.breakerZone = CandleZone(rates, a.index, "Breaker");
         structure.confirmed = (breakIndex > 0);
         if(structure.confirmed)
         {
            structure.confirmation.index = breakIndex;
            structure.confirmation.price = InpUseWickForBreak ? rates[breakIndex].high : rates[breakIndex].close;
            structure.confirmation.time = rates[breakIndex].time;
            structure.confirmation.valid = true;
            structure.confirmation.isHigh = true;
            int hh2Index = -1;
            for(int j = breakIndex - 1; j >= MathMax(2, InpSwingLookback + 1); j--)
            {
               if(IsSwingHigh(rates, ArraySize(rates), j, MathMax(1, InpSwingLookback)))
               {
                  hh2Index = j;
                  break;
               }
            }
            if(hh2Index > 0)
            {
               structure.hh2.index = hh2Index;
               structure.hh2.price = rates[hh2Index].high;
               structure.hh2.time = rates[hh2Index].time;
               structure.hh2.isHigh = true;
               structure.hh2.valid = true;
            }
         }
         structure.valid = true;
         return structure;
      }
      else
      {
         if(!a.isHigh || b.isHigh || !c.isHigh)
            continue;
         if(!(c.price < a.price))
            continue;

         int breakIndex = FindBreakIndex(rates, c.index, b.price, false);
         structure.priorSwing = a;
         structure.hh1 = b;
         structure.hl1 = c;
         structure.orderBlockZone = FindOriginZone(rates, a.index, b.index, false);
         structure.breakerZone = CandleZone(rates, a.index, "Breaker");
         structure.confirmed = (breakIndex > 0);
         if(structure.confirmed)
         {
            structure.confirmation.index = breakIndex;
            structure.confirmation.price = InpUseWickForBreak ? rates[breakIndex].low : rates[breakIndex].close;
            structure.confirmation.time = rates[breakIndex].time;
            structure.confirmation.valid = true;
            structure.confirmation.isHigh = false;
            int hh2Index = -1;
            for(int j = breakIndex - 1; j >= MathMax(2, InpSwingLookback + 1); j--)
            {
               if(IsSwingLow(rates, ArraySize(rates), j, MathMax(1, InpSwingLookback)))
               {
                  hh2Index = j;
                  break;
               }
            }
            if(hh2Index > 0)
            {
               structure.hh2.index = hh2Index;
               structure.hh2.price = rates[hh2Index].low;
               structure.hh2.time = rates[hh2Index].time;
               structure.hh2.isHigh = false;
               structure.hh2.valid = true;
            }
         }
         structure.valid = true;
         return structure;
      }
   }

   return structure;
}

PriceZone VolumeNodeZone(MqlRates &rates[], const int olderIndex, const int newerIndex, const double lowPrice, const double highPrice, const string label)
{
   VolumeProfileResult vp;
   PriceZone zone;
   zone.valid = false;
   if(!CalcVolumeProfile(rates, olderIndex, newerIndex, lowPrice, highPrice, vp))
      return zone;
   double half = MathMax(_Point, InpVP_BucketPoints * _Point * 0.5);
   return MakeZone(vp.node - half, vp.node + half, rates[newerIndex].time, label);
}

PriceZone FibZone(const double fromPrice, const double toPrice, const datetime t, const double fib, const string label)
{
   double price = fromPrice + (toPrice - fromPrice) * fib;
   double half = MathMax(_Point, InpConfluenceZoneTolerancePoints * _Point);
   return MakeZone(price - half, price + half, t, label);
}

PriceZone FindLastDirectionalCandleZone(MqlRates &rates[], const int olderIndex, const int newerIndex, const bool bullishCandle, const string label)
{
   int startIndex = MathMax(olderIndex, newerIndex);
   int endIndex = MathMin(olderIndex, newerIndex);
   for(int i = startIndex; i >= endIndex; i--)
   {
      if(bullishCandle && rates[i].close > rates[i].open)
         return CandleZone(rates, i, label);
      if(!bullishCandle && rates[i].close < rates[i].open)
         return CandleZone(rates, i, label);
   }
   PriceZone zone;
   zone.valid = false;
   return zone;
}

PriceZone SelectReversalRetraceZone(MqlRates &rates[], ReversalStructure &s)
{
   PriceZone candidates[4];
   candidates[0] = VolumeNodeZone(rates, s.lh2.index, s.ll1.index, MathMin(s.ll1.price, s.lh2.price), MathMax(s.ll1.price, s.lh2.price), "VolumeNode");
   candidates[1] = FindLastDirectionalCandleZone(rates, s.lh2.index, s.ll1.index, s.isLong, s.isLong ? "EngulfedBull" : "EngulfedBear");
   candidates[2] = FindLastDirectionalCandleZone(rates, s.lh2.index, s.ll1.index, s.isLong, s.isLong ? "LastBullBeforeBreak" : "LastBearBeforeBreak");
   candidates[3] = FibZone(s.ll1.price, s.confirmation.price, s.confirmation.time, InpFibLevel, "Fib");

   RetraceMode mode = (RetraceMode)InpRetraceMode;
   if(mode == RETRACE_VOLUME_NODE || mode == RETRACE_ENGULFED_CANDLE || mode == RETRACE_LAST_BULL_BEFORE_BREAK || mode == RETRACE_FIB_LEVEL)
   {
      s.retraceModeUsed = (int)mode;
      return candidates[(int)mode];
   }

   if(mode == RETRACE_PRIORITY_CASCADE)
   {
      string prefs[4] = {InpRetracePriority1, InpRetracePriority2, InpRetracePriority3, InpRetracePriority4};
      for(int i = 0; i < 4; i++)
      {
         if(prefs[i] == "VolumeNode" && candidates[0].valid) { s.retraceModeUsed = 0; return candidates[0]; }
         if(prefs[i] == "EngulfedCandle" && candidates[1].valid) { s.retraceModeUsed = 1; return candidates[1]; }
         if(prefs[i] == "LastBullBeforeBreak" && candidates[2].valid) { s.retraceModeUsed = 2; return candidates[2]; }
         if(prefs[i] == "FibLevel" && candidates[3].valid) { s.retraceModeUsed = 3; return candidates[3]; }
      }
   }

   PriceZone intersection = candidates[0];
   bool have = candidates[0].valid;
   for(int i = 1; i < 4; i++)
   {
      if(!candidates[i].valid)
         continue;
      if(!have)
      {
         intersection = candidates[i];
         have = true;
      }
      else
      {
         PriceZone next;
         if(!IntersectZones(intersection, candidates[i], InpConfluenceZoneTolerancePoints, next))
         {
            have = false;
            break;
         }
         intersection = next;
      }
   }
   if(have)
      s.retraceModeUsed = RETRACE_ALL_CONFLUENCE;
   return intersection;
}

PriceZone SelectTrendEntryZone(MqlRates &rates[], TrendStructure &s)
{
   PriceZone candidates[3];
   candidates[0] = s.orderBlockZone;
   candidates[0].label = "OB";
   candidates[1] = s.breakerZone;
   candidates[1].label = "Breaker";
   double fibTo = s.confirmed ? s.confirmation.price : s.hh1.price;
   candidates[2] = FibZone(s.hl1.price, fibTo, s.hl1.time, InpContinuationFibLevel, "Fib");

   ContinuationZoneMode mode = (ContinuationZoneMode)InpContinuationZoneMode;
   if(mode == CONT_ZONE_ORDER_BLOCK || mode == CONT_ZONE_BREAKER || mode == CONT_ZONE_FIB_LEVEL)
   {
      s.zoneModeUsed = (int)mode;
      return candidates[(int)mode];
   }

   if(mode == CONT_ZONE_PRIORITY_CASCADE)
   {
      if(candidates[0].valid) { s.zoneModeUsed = CONT_ZONE_ORDER_BLOCK; return candidates[0]; }
      if(candidates[1].valid) { s.zoneModeUsed = CONT_ZONE_BREAKER; return candidates[1]; }
      if(candidates[2].valid) { s.zoneModeUsed = CONT_ZONE_FIB_LEVEL; return candidates[2]; }
   }

   PriceZone intersection;
   if(IntersectZones(candidates[0], candidates[1], InpConfluenceZoneTolerancePoints, intersection))
   {
      PriceZone finalZone;
      if(IntersectZones(intersection, candidates[2], InpConfluenceZoneTolerancePoints, finalZone))
      {
         s.zoneModeUsed = CONT_ZONE_ALL_CONFLUENCE;
         return finalZone;
      }
   }

   PriceZone invalidZone;
   invalidZone.valid = false;
   return invalidZone;
}

double ScoreSetup(const bool htfAligned,
                  const bool confirmed,
                  const bool volumeAware,
                  const PriceZone &zone,
                  const double rr,
                  const double atr)
{
   double score = 0.0;
   if(confirmed)  score += 35.0;
   else           score += 20.0;
   if(htfAligned) score += 25.0;
   if(volumeAware) score += 15.0;
   if(zone.valid) score += 15.0;
   if(rr >= InpMinRR) score += 10.0;
   else if(InpMinRR > 0.0) score += MathMax(0.0, MathMin(10.0, rr / InpMinRR * 10.0));
   if(atr > 0.0 && zone.valid && ZoneWidthPoints(zone) <= (atr / _Point) * 1.5)
      score += 10.0;
   return MathMin(100.0, score);
}

RegimeState ClassifyRegime(const ENUM_TIMEFRAMES tf, RegimeSnapshot &snapshot)
{
   snapshot.state = REGIME_UNKNOWN;
   snapshot.barTime = iTime(_Symbol, tf, 0);
   snapshot.adx = GetADXValue(tf, InpADX_Period, 1);
   snapshot.atr = GetATRValue(tf, InpATR_Period, 1);
   snapshot.atrAvg = GetATRAverage(tf, InpATR_Period, InpATR_AvgBars);
   snapshot.valid = false;
   snapshot.biasZone.valid = false;

   MqlRates rates[];
   if(!LoadRates(tf, MathMax(300, InpConsolidation_Lookback * 3), rates))
      return REGIME_UNKNOWN;

   SwingPoint highs[], lows[], allSwings[];
   int highCount = 0, lowCount = 0, swingCount = 0;
   if(!CollectSwings(rates, highs, highCount, lows, lowCount, allSwings, swingCount))
      return REGIME_UNKNOWN;

   int lookback = MathMin(InpConsolidation_Lookback, ArraySize(rates) - 2);
   snapshot.rollingHigh = -DBL_MAX;
   snapshot.rollingLow = DBL_MAX;
   double prevHigh = -DBL_MAX;
   double prevLow = DBL_MAX;

   for(int i = 1; i <= lookback; i++)
   {
      snapshot.rollingHigh = MathMax(snapshot.rollingHigh, rates[i].high);
      snapshot.rollingLow = MathMin(snapshot.rollingLow, rates[i].low);
   }
   for(int i = lookback + 1; i <= MathMin(ArraySize(rates) - 1, lookback * 2); i++)
   {
      prevHigh = MathMax(prevHigh, rates[i].high);
      prevLow = MathMin(prevLow, rates[i].low);
   }

   VolumeProfileResult vp;
   if(CalcVolumeProfile(rates, lookback, 1, snapshot.rollingLow, snapshot.rollingHigh, vp))
   {
      snapshot.vah = vp.vah;
      snapshot.val = vp.val;
   }
   else
   {
      snapshot.vah = snapshot.rollingHigh;
      snapshot.val = snapshot.rollingLow;
   }

   ReversalStructure bullRev = DetectReversalStructure(tf, true);
   double tfReferencePrice = rates[1].close;
   if(bullRev.valid && bullRev.originZone.valid && IsPriceInsideZone(tfReferencePrice, bullRev.originZone))
   {
      snapshot.state = REGIME_REVERSAL_FORMING_BULL;
      snapshot.biasZone = bullRev.originZone;
      snapshot.valid = true;
      return snapshot.state;
   }

   ReversalStructure bearRev = DetectReversalStructure(tf, false);
   if(bearRev.valid && bearRev.originZone.valid && IsPriceInsideZone(tfReferencePrice, bearRev.originZone))
   {
      snapshot.state = REGIME_REVERSAL_FORMING_BEAR;
      snapshot.biasZone = bearRev.originZone;
      snapshot.valid = true;
      return snapshot.state;
   }

   if(snapshot.adx >= InpADX_TrendThreshold &&
      RecentHighsHigher(highs, highCount, InpRegime_SwingCount) &&
      RecentLowsHigher(lows, lowCount, InpRegime_SwingCount))
   {
      snapshot.state = REGIME_TRENDING_UP;
      TrendStructure trend = DetectTrendStructure(tf, true);
      snapshot.biasZone = trend.orderBlockZone;
      snapshot.valid = true;
      return snapshot.state;
   }

   if(snapshot.adx >= InpADX_TrendThreshold &&
      RecentHighsLower(highs, highCount, InpRegime_SwingCount) &&
      RecentLowsLower(lows, lowCount, InpRegime_SwingCount))
   {
      snapshot.state = REGIME_TRENDING_DOWN;
      TrendStructure trend = DetectTrendStructure(tf, false);
      snapshot.biasZone = trend.orderBlockZone;
      snapshot.valid = true;
      return snapshot.state;
   }

   bool noExtension = (prevHigh > -DBL_MAX && prevLow < DBL_MAX && snapshot.rollingHigh <= prevHigh && snapshot.rollingLow >= prevLow);
   bool compressed = (snapshot.atrAvg > 0.0 && snapshot.atr / snapshot.atrAvg <= InpVolatilityCompressionRatio);
   int barsInVA = 0;
   for(int i = 1; i <= MathMin(lookback, InpConsolidation_MinBars); i++)
      if(rates[i].close >= snapshot.val && rates[i].close <= snapshot.vah)
         barsInVA++;

   if(snapshot.adx <= InpADX_RangeThreshold || noExtension || (compressed && barsInVA >= InpConsolidation_MinBars))
   {
      snapshot.state = REGIME_CONSOLIDATING;
      snapshot.biasZone = MakeZone(snapshot.val, snapshot.vah, rates[1].time, "Range");
      snapshot.valid = true;
      return snapshot.state;
   }

   int idx = TFIndex(tf);
   if(InpRegime_UseHysteresis && idx >= 0 && g_prevRegime[idx] != REGIME_UNKNOWN)
   {
      snapshot.state = g_prevRegime[idx];
      snapshot.valid = true;
      return snapshot.state;
   }

   snapshot.valid = true;
   return REGIME_UNKNOWN;
}

bool UpdateSingleRegime(const int idx, const bool force)
{
   if(idx < 0 || idx >= 7)
      return false;
   if(g_tfList[idx] == PERIOD_CURRENT)
      return false;

   datetime nowBar = iTime(_Symbol, g_tfList[idx], 0);
   if(!force && !InpRegime_UpdateOnTick && nowBar == g_lastTFBarTime[idx])
      return false;

   RegimeSnapshot snap;
   RegimeState state = ClassifyRegime(g_tfList[idx], snap);
   snap.state = state;
   g_regimes[idx] = snap;
   g_prevRegime[idx] = state;
   g_lastTFBarTime[idx] = nowBar;
   return true;
}

void UpdateRegimes(const bool force)
{
   ResetGovernanceWindowIfNeeded();
   for(int i = 0; i < 7; i++)
      UpdateSingleRegime(i, force);
}

//====================================================================
// Filters and governance
//====================================================================
bool IsSessionOpen()
{
   if(!InpUseSessionFilter)
      return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour;

   if(InpSessionStartHour <= InpSessionEndHour)
      return (hour >= InpSessionStartHour && hour <= InpSessionEndHour);

   return (hour >= InpSessionStartHour || hour <= InpSessionEndHour);
}

bool IsNewsBlackoutActive()
{
   if(!InpUseNewsBlackout)
      return false;
   if(StringLen(InpManualNewsTimesUTC) == 0)
      return false;

   // Approximation: standalone MT5 EAs do not have a native historical news API,
   // so blackout handling is driven by user-supplied UTC timestamps in InpManualNewsTimesUTC.
   string tokens[];
   int count = StringSplit(InpManualNewsTimesUTC, ';', tokens);
   datetime nowTime = TimeCurrent();
   int beforeSec = InpNewsBlackoutMinutesBefore * 60;
   int afterSec = InpNewsBlackoutMinutesAfter * 60;

   for(int i = 0; i < count; i++)
   {
      string item = tokens[i];
      StringReplace(item, " ", "");
      StringReplace(item, "\t", "");
      if(StringLen(item) == 0)
         continue;
      datetime eventTime = ParseUtcInputTimestamp(item);
      if(eventTime <= 0)
         continue;
      if(nowTime >= eventTime - beforeSec && nowTime <= eventTime + afterSec)
         return true;
   }
   return false;
}

bool HasGovernanceWindowRolled(const int mode, const datetime startTime, const datetime nowTime)
{
   if(mode <= 0 || startTime <= 0)
      return false;

   MqlDateTime nowDt, baseDt;
   TimeToStruct(nowTime, nowDt);
   TimeToStruct(startTime, baseDt);

   if(mode == 1)
      return (nowDt.min != baseDt.min || nowDt.hour != baseDt.hour || nowDt.day != baseDt.day || nowDt.mon != baseDt.mon || nowDt.year != baseDt.year);
   if(mode == 2)
      return (nowDt.hour != baseDt.hour || nowDt.day != baseDt.day || nowDt.mon != baseDt.mon || nowDt.year != baseDt.year);
   if(mode == 3)
      return SessionAnchorTime(nowTime) != SessionAnchorTime(startTime);
   if(mode == 4)
      return (nowDt.day != baseDt.day || nowDt.mon != baseDt.mon || nowDt.year != baseDt.year);

   return false;
}

void ResetGovernanceWindowIfNeeded()
{
   datetime nowTime = TimeCurrent();
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(g_profitGovernanceBaseEquity <= 0.0)
   {
      g_profitGovernanceBaseEquity = equity;
      g_profitGovernanceStart = nowTime;
   }
   if(g_lossGovernanceBaseEquity <= 0.0)
   {
      g_lossGovernanceBaseEquity = equity;
      g_lossGovernanceStart = nowTime;
   }

   if(HasGovernanceWindowRolled(InpProfitTargetMode, g_profitGovernanceStart, nowTime))
   {
      g_profitGovernanceBaseEquity = equity;
      g_profitGovernanceStart = nowTime;
   }
   if(HasGovernanceWindowRolled(InpLossLimitMode, g_lossGovernanceStart, nowTime))
   {
      g_lossGovernanceBaseEquity = equity;
      g_lossGovernanceStart = nowTime;
   }
}

bool IsGovernanceTripped()
{
   if(g_profitGovernanceBaseEquity <= 0.0 || g_lossGovernanceBaseEquity <= 0.0)
      return false;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double profitPnlPct = (equity - g_profitGovernanceBaseEquity) / g_profitGovernanceBaseEquity * 100.0;
   double lossPnlPct = (equity - g_lossGovernanceBaseEquity) / g_lossGovernanceBaseEquity * 100.0;

   if((InpProfitTargetMode > 0) && profitPnlPct >= InpProfitTargetPercent)
      return true;
   if((InpLossLimitMode > 0) && lossPnlPct <= -MathAbs(InpLossLimitPercent))
      return true;
   return false;
}

bool IsTradingSuppressed()
{
   if(!InpAllowTrading)
      return true;
   if(!IsSessionOpen())
      return true;
   if(IsNewsBlackoutActive())
      return true;
   if(IsGovernanceTripped())
      return true;
   return false;
}

RegimeState ResolveMasterState(const RegimeState fallbackState)
{
   int masterIdx = TFIndex(InpRegimeSource_TF);
   if(masterIdx >= 0 && g_regimes[masterIdx].valid)
      return g_regimes[masterIdx].state;
   return fallbackState;
}

//====================================================================
// Signal builders
//====================================================================
double GetAdaptiveThreshold(const EngineType engine, const double baseThreshold)
{
   if(!InpAdaptiveLearning_Enabled)
      return baseThreshold;

   int idx = 0;
   if(engine == ENGINE_TREND) idx = 1;
   if(engine == ENGINE_CONSOLIDATION) idx = 2;

   int total = g_adaptiveStats[idx].wins + g_adaptiveStats[idx].losses;
   if(total < MathMax(5, InpAdaptiveLearning_Window / 4))
      return baseThreshold;

   double winRate = (double)g_adaptiveStats[idx].wins / total;
   if(winRate < 0.40)
      return MathMin(100.0, baseThreshold + InpAdaptiveLearning_ThresholdShift);
   if(winRate > 0.60)
      return MathMax(0.0, baseThreshold - InpAdaptiveLearning_ThresholdShift);
   return baseThreshold;
}

datetime ParseUtcInputTimestamp(const string rawValue)
{
   string normalized = rawValue;
   StringReplace(normalized, "-", ".");
   StringReplace(normalized, "T", " ");
   string parts[];
   if(StringSplit(normalized, ' ', parts) < 2)
      return 0;

   string dateParts[];
   string timeParts[];
   if(StringSplit(parts[0], '.', dateParts) < 3)
      return 0;
   if(StringSplit(parts[1], ':', timeParts) < 2)
      return 0;

   MqlDateTime dt;
   dt.year = (int)StringToInteger(dateParts[0]);
   dt.mon  = (int)StringToInteger(dateParts[1]);
   dt.day  = (int)StringToInteger(dateParts[2]);
   dt.hour = (int)StringToInteger(timeParts[0]);
   dt.min  = (int)StringToInteger(timeParts[1]);
   dt.sec  = (ArraySize(timeParts) > 2) ? (int)StringToInteger(timeParts[2]) : 0;

   datetime asServerSemantic = StructToTime(dt);
   datetime serverNow = TimeTradeServer();
   if(serverNow <= 0)
      serverNow = TimeCurrent();
   int serverUtcOffset = (int)(serverNow - TimeGMT());
   return asServerSemantic + serverUtcOffset;
}

SetupSignal BlankSignal(const ENUM_TIMEFRAMES tf, const EngineType engine, const bool isLong)
{
   SetupSignal sig;
   sig.valid = false;
   sig.isLong = isLong;
   sig.pendingPreferred = InpUsePendingOrders;
   sig.confirmed = false;
   sig.engine = engine;
   sig.tf = tf;
   sig.entryPrice = 0.0;
   sig.sl = 0.0;
   sig.tp1 = 0.0;
   sig.tp2 = 0.0;
   sig.tp3 = 0.0;
   sig.tp4 = 0.0;
   sig.tp5 = 0.0;
   sig.finalTp = 0.0;
   sig.zoneLow = 0.0;
   sig.zoneHigh = 0.0;
   sig.confluenceScore = 0.0;
   sig.rr = 0.0;
   sig.riskMultiplier = 1.0;
   sig.signalTime = 0;
   sig.signature = "";
   sig.comment = "";
   sig.reason = "";
   sig.zoneLabel = "";
   sig.aTime1 = 0; sig.aTime2 = 0; sig.aTime3 = 0; sig.aTime4 = 0; sig.aTime5 = 0;
   sig.aPrice1 = 0.0; sig.aPrice2 = 0.0; sig.aPrice3 = 0.0; sig.aPrice4 = 0.0; sig.aPrice5 = 0.0;
   sig.aLabel1 = ""; sig.aLabel2 = ""; sig.aLabel3 = ""; sig.aLabel4 = ""; sig.aLabel5 = "";
   return sig;
}

SetupSignal BuildReversalSignal(const ENUM_TIMEFRAMES tf, const bool isLong)
{
   SetupSignal sig = BlankSignal(tf, ENGINE_REVERSAL, isLong);
   ReversalStructure s = DetectReversalStructure(tf, isLong);
   if(!s.valid || !s.confirmed)
      return sig;

   MqlRates rates[];
   if(!LoadRates(tf, 400, rates))
      return sig;

   s.retraceZone = SelectReversalRetraceZone(rates, s);
   if(!s.retraceZone.valid)
      return sig;

   double entry = PriceAtZoneEntry(s.retraceZone);
   double invalidation = isLong ? MathMin(s.originZone.low, s.ll1.price) : MathMax(s.originZone.high, s.ll1.price);
   double sl = isLong ? invalidation - InpSL_BufferPoints * _Point : invalidation + InpSL_BufferPoints * _Point;
   double risk = MathAbs(entry - sl);
   if(risk <= SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE))
      return sig;

   double tp1 = isLong ? entry + risk * InpTP1Ratio : entry - risk * InpTP1Ratio;
   double tp2 = isLong ? entry + risk * InpTP2Ratio : entry - risk * InpTP2Ratio;
   double tp3 = isLong ? entry + risk * InpTP3Ratio : entry - risk * InpTP3Ratio;
   double tp4 = isLong ? entry + risk * InpTP4Ratio : entry - risk * InpTP4Ratio;
   double tp5 = isLong ? entry + risk * InpTP5Ratio : entry - risk * InpTP5Ratio;
   double rr = ComputeRR(isLong, entry, sl, tp5);

   int idx = TFIndex(tf);
   RegimeState biasState = (idx >= 0) ? g_regimes[idx].state : REGIME_UNKNOWN;
   RegimeState masterState = ResolveMasterState(biasState);

   bool htfAligned = (masterState == (isLong ? REGIME_REVERSAL_FORMING_BULL : REGIME_REVERSAL_FORMING_BEAR)) ||
                     (biasState == (isLong ? REGIME_REVERSAL_FORMING_BULL : REGIME_REVERSAL_FORMING_BEAR));
   double score = ScoreSetup(htfAligned, true, (s.retraceModeUsed == RETRACE_VOLUME_NODE || s.retraceModeUsed == RETRACE_ALL_CONFLUENCE), s.retraceZone, rr, GetATRValue(tf, InpATR_Period, 1));

   sig.valid = true;
   sig.confirmed = true;
   sig.pendingPreferred = InpUsePendingOrders;
   sig.entryPrice = NormalizePrice(entry);
   sig.sl = NormalizePrice(sl);
   sig.tp1 = NormalizePrice(tp1);
   sig.tp2 = NormalizePrice(tp2);
   sig.tp3 = NormalizePrice(tp3);
   sig.tp4 = NormalizePrice(tp4);
   sig.tp5 = NormalizePrice(tp5);
   sig.finalTp = sig.tp5;
   sig.zoneLow = s.retraceZone.low;
   sig.zoneHigh = s.retraceZone.high;
   sig.confluenceScore = score;
   sig.rr = rr;
   sig.signalTime = s.confirmation.time;
   sig.zoneLabel = s.retraceZone.label;
   sig.reason = isLong ? "Reversal long" : "Reversal short";
   sig.signature = StringFormat("%s%s%s%I64d_%.5f_%.5f",
                                EngineToString(sig.engine),
                                TimeframeToString(tf),
                                isLong ? "B" : "S",
                                (long)s.confirmation.time,
                                sig.zoneLow,
                                sig.zoneHigh);
   sig.comment = sig.signature;

   sig.aTime1 = s.ll2.time; sig.aPrice1 = s.ll2.price; sig.aLabel1 = "1";
   sig.aTime2 = s.lh2.time; sig.aPrice2 = s.lh2.price; sig.aLabel2 = "2";
   sig.aTime3 = s.ll1.time; sig.aPrice3 = s.ll1.price; sig.aLabel3 = "3";
   sig.aTime4 = s.confirmation.time; sig.aPrice4 = s.confirmation.price; sig.aLabel4 = InpUseWickForBreak ? "BOS/CHOCH Wick" : "BOS/CHOCH";
   sig.aTime5 = s.retraceZone.time; sig.aPrice5 = entry; sig.aLabel5 = "Retrace";
   return sig;
}

SetupSignal BuildTrendSignal(const ENUM_TIMEFRAMES tf, const bool isLong)
{
   SetupSignal sig = BlankSignal(tf, ENGINE_TREND, isLong);
   TrendStructure s = DetectTrendStructure(tf, isLong);
   if(!s.valid)
      return sig;

   MqlRates rates[];
   if(!LoadRates(tf, 400, rates))
      return sig;

   s.chosenZone = SelectTrendEntryZone(rates, s);
   if(!s.chosenZone.valid)
      return sig;

   bool allowPreConfirm = ((ContinuationEntryTiming)InpContinuation_EntryTiming == CONT_ENTRY_ALLOW_PRECONFIRM);
   if(!s.confirmed && !allowPreConfirm)
      return sig;

   double entry = PriceAtZoneEntry(s.chosenZone);
   double baseInvalidation = isLong ? MathMin(s.hl1.price, s.chosenZone.low) : MathMax(s.hl1.price, s.chosenZone.high);
   double sl = isLong ? baseInvalidation - InpSL_BufferPoints * _Point : baseInvalidation + InpSL_BufferPoints * _Point;
   double risk = MathAbs(entry - sl);
   if(risk <= SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE))
      return sig;

   double tp1 = isLong ? entry + risk * InpTP1Ratio : entry - risk * InpTP1Ratio;
   double tp2 = isLong ? entry + risk * InpTP2Ratio : entry - risk * InpTP2Ratio;
   double tp3 = isLong ? entry + risk * InpTP3Ratio : entry - risk * InpTP3Ratio;
   double tp4 = isLong ? entry + risk * InpTP4Ratio : entry - risk * InpTP4Ratio;
   double tp5 = isLong ? entry + risk * InpTP5Ratio : entry - risk * InpTP5Ratio;
   double rr = ComputeRR(isLong, entry, sl, tp5);

   int idx = TFIndex(tf);
   RegimeState biasState = (idx >= 0) ? g_regimes[idx].state : REGIME_UNKNOWN;
   RegimeState masterState = ResolveMasterState(biasState);
   bool htfAligned = (masterState == (isLong ? REGIME_TRENDING_UP : REGIME_TRENDING_DOWN)) ||
                     (biasState == (isLong ? REGIME_TRENDING_UP : REGIME_TRENDING_DOWN));
   double score = ScoreSetup(htfAligned, s.confirmed, (s.zoneModeUsed != CONT_ZONE_BREAKER), s.chosenZone, rr, GetATRValue(tf, InpATR_Period, 1));

   if(!s.confirmed)
   {
      double threshold = GetAdaptiveThreshold(ENGINE_TREND, MathMax(InpMinConfluenceScore_PreConfirm, InpMinConfluenceScore));
      if(score < threshold || !IsPriceInsideZone(CurrentMidPrice(), s.chosenZone))
         return sig;
   }

   sig.valid = true;
   sig.confirmed = s.confirmed;
   sig.pendingPreferred = InpUsePendingOrders && s.confirmed;
   sig.entryPrice = NormalizePrice(entry);
   sig.sl = NormalizePrice(sl);
   sig.tp1 = NormalizePrice(tp1);
   sig.tp2 = NormalizePrice(tp2);
   sig.tp3 = NormalizePrice(tp3);
   sig.tp4 = NormalizePrice(tp4);
   sig.tp5 = NormalizePrice(tp5);
   sig.finalTp = sig.tp5;
   sig.zoneLow = s.chosenZone.low;
   sig.zoneHigh = s.chosenZone.high;
   sig.confluenceScore = score;
   sig.rr = rr;
   sig.signalTime = s.confirmed ? s.confirmation.time : s.hl1.time;
   sig.zoneLabel = s.chosenZone.label;
   sig.reason = s.confirmed ? (isLong ? "Trend long post-BOS" : "Trend short post-BOS")
                            : (isLong ? "Trend long pre-confirm" : "Trend short pre-confirm");
   sig.signature = StringFormat("%s%s%s%I64d_%.5f_%.5f",
                                EngineToString(sig.engine),
                                TimeframeToString(tf),
                                isLong ? "B" : "S",
                                (long)sig.signalTime,
                                sig.zoneLow,
                                sig.zoneHigh);
   sig.comment = sig.signature;

   sig.aTime1 = s.hh1.time; sig.aPrice1 = s.hh1.price; sig.aLabel1 = "HH1";
   sig.aTime2 = s.hl1.time; sig.aPrice2 = s.hl1.price; sig.aLabel2 = "HL1";
   sig.aTime3 = s.chosenZone.time; sig.aPrice3 = entry; sig.aLabel3 = s.chosenZone.label;
   sig.aTime4 = s.confirmed ? s.confirmation.time : s.hl1.time; sig.aPrice4 = s.confirmed ? s.confirmation.price : s.hl1.price; sig.aLabel4 = s.confirmed ? "BOS" : "PreConfirm";
   sig.aTime5 = s.hh2.valid ? s.hh2.time : sig.aTime4; sig.aPrice5 = s.hh2.valid ? s.hh2.price : sig.aPrice4; sig.aLabel5 = s.hh2.valid ? "HH2" : "";
   return sig;
}

bool HasEqualBoundary(MqlRates &rates[], const bool upperSide, double &level)
{
   SwingPoint highs[], lows[], allSwings[];
   int highCount = 0, lowCount = 0, swingCount = 0;
   if(!CollectSwings(rates, highs, highCount, lows, lowCount, allSwings, swingCount))
      return false;

   double tolerance = MathMax(2.0, InpConfluenceZoneTolerancePoints) * _Point;
   if(upperSide && highCount >= 2)
   {
      double a = highs[highCount - 1].price;
      double b = highs[highCount - 2].price;
      if(MathAbs(a - b) <= tolerance)
      {
         level = (a + b) * 0.5;
         return true;
      }
   }
   if(!upperSide && lowCount >= 2)
   {
      double a = lows[lowCount - 1].price;
      double b = lows[lowCount - 2].price;
      if(MathAbs(a - b) <= tolerance)
      {
         level = (a + b) * 0.5;
         return true;
      }
   }
   return false;
}

SetupSignal BuildRangeFadeSignal(const ENUM_TIMEFRAMES tf)
{
   SetupSignal longSig = BlankSignal(tf, ENGINE_CONSOLIDATION, true);
   if(!InpConsolidation_AllowRangeFade)
      return longSig;

   int idx = TFIndex(tf);
   bool masterConsolidating = (ResolveMasterState(REGIME_UNKNOWN) == REGIME_CONSOLIDATING);
   if(idx < 0 || (!masterConsolidating && g_regimes[idx].state != REGIME_CONSOLIDATING))
      return longSig;

   MqlRates rates[];
   if(!LoadRates(tf, MathMax(120, InpConsolidation_Lookback * 3), rates))
      return longSig;

   double price = CurrentMidPrice();
   double vah = g_regimes[idx].vah;
   double val = g_regimes[idx].val;
   double tolerance = MathMax(2.0, InpConfluenceZoneTolerancePoints) * _Point;
   double equalHigh = 0.0;
   double equalLow = 0.0;
   bool nearVAH = (MathAbs(price - vah) <= tolerance);
   bool nearVAL = (MathAbs(price - val) <= tolerance);
   bool nearEQH = HasEqualBoundary(rates, true, equalHigh) && MathAbs(price - equalHigh) <= tolerance;
   bool nearEQL = HasEqualBoundary(rates, false, equalLow) && MathAbs(price - equalLow) <= tolerance;

   bool doLong = (nearVAL || nearEQL);
   bool doShort = (nearVAH || nearEQH);
   if(!doLong && !doShort)
      return longSig;

   bool isLong = doLong;
   if(doLong && doShort)
   {
      double distToLong = MathAbs(price - val);
      double distToShort = MathAbs(price - vah);
      if(MathAbs(distToLong - distToShort) <= _Point)
         return longSig;
      isLong = (distToLong < distToShort);
   }
   SetupSignal sig = BlankSignal(tf, ENGINE_CONSOLIDATION, isLong);
   double zoneLow = isLong ? MathMin(val, equalLow > 0.0 ? equalLow : val) - tolerance : MathMin(vah, equalHigh > 0.0 ? equalHigh : vah) - tolerance;
   double zoneHigh = isLong ? MathMax(val, equalLow > 0.0 ? equalLow : val) + tolerance : MathMax(vah, equalHigh > 0.0 ? equalHigh : vah) + tolerance;
   double entry = price;
   double sl = isLong ? zoneLow - InpSL_BufferPoints * _Point : zoneHigh + InpSL_BufferPoints * _Point;
   double tp5 = isLong ? entry + MathAbs(entry - sl) * InpMinRR : entry - MathAbs(entry - sl) * InpMinRR;
   double rr = ComputeRR(isLong, entry, sl, tp5);
   PriceZone zone = MakeZone(zoneLow, zoneHigh, rates[1].time, isLong ? "VALFade" : "VAHFade");
   double score = ScoreSetup(true, true, true, zone, rr, GetATRValue(tf, InpATR_Period, 1));

   if(rr < InpMinRR)
      return sig;

   sig.valid = true;
   sig.confirmed = true;
   sig.pendingPreferred = false;
   sig.entryPrice = NormalizePrice(entry);
   sig.sl = NormalizePrice(sl);
   sig.tp1 = NormalizePrice(isLong ? entry + MathAbs(entry - sl) * InpTP1Ratio : entry - MathAbs(entry - sl) * InpTP1Ratio);
   sig.tp2 = NormalizePrice(isLong ? entry + MathAbs(entry - sl) * InpTP2Ratio : entry - MathAbs(entry - sl) * InpTP2Ratio);
   sig.tp3 = NormalizePrice(isLong ? entry + MathAbs(entry - sl) * InpTP3Ratio : entry - MathAbs(entry - sl) * InpTP3Ratio);
   sig.tp4 = NormalizePrice(isLong ? entry + MathAbs(entry - sl) * InpTP4Ratio : entry - MathAbs(entry - sl) * InpTP4Ratio);
   sig.tp5 = NormalizePrice(isLong ? entry + MathAbs(entry - sl) * InpTP5Ratio : entry - MathAbs(entry - sl) * InpTP5Ratio);
   sig.finalTp = sig.tp5;
   sig.zoneLow = zone.low;
   sig.zoneHigh = zone.high;
   sig.confluenceScore = score;
   sig.rr = rr;
   sig.riskMultiplier = InpRangeFade_RiskMultiplier;
   sig.signalTime = rates[1].time;
   sig.zoneLabel = zone.label;
   sig.reason = isLong ? "Range fade long" : "Range fade short";
   sig.signature = StringFormat("%s%s%s%I64d_%.5f_%.5f",
                                EngineToString(sig.engine),
                                TimeframeToString(tf),
                                isLong ? "B" : "S",
                                (long)sig.signalTime,
                                sig.zoneLow,
                                sig.zoneHigh);
   sig.comment = sig.signature;

   sig.aTime1 = rates[1].time; sig.aPrice1 = isLong ? val : vah; sig.aLabel1 = isLong ? "VAL" : "VAH";
   sig.aTime2 = rates[1].time; sig.aPrice2 = entry; sig.aLabel2 = "Fade";
   return sig;
}

bool RequiresHigherTFZone(const int idx)
{
   switch(g_tfList[idx])
   {
      case PERIOD_D1:  return InpTF_D1_RequireHTFZone;
      case PERIOD_H4:  return InpTF_H4_RequireHTFZone;
      case PERIOD_H1:  return InpTF_H1_RequireHTFZone;
      case PERIOD_M30: return InpTF_M30_RequireHTFZone;
      case PERIOD_M15: return InpTF_M15_RequireHTFZone;
      case PERIOD_M5:  return InpTF_M5_RequireHTFZone;
      case PERIOD_M1:  return InpTF_M1_RequireHTFZone;
      default:         return false;
   }
}

bool PassesHigherTFZoneRequirement(const int idx)
{
   if(idx <= 0 || !RequiresHigherTFZone(idx))
      return true;
   for(int i = idx - 1; i >= 0; i--)
   {
      if(g_tfList[i] == PERIOD_CURRENT || !g_regimes[i].biasZone.valid)
         continue;
      return IsPriceInsideZone(CurrentMidPrice(), g_regimes[i].biasZone);
   }
   return true;
}

bool SignalAllowedForCurrentConcurrency(const SetupSignal &sig)
{
   // Lower-or-equal timeframes (for example H1 and below when H1 is selected)
   // are the intended concurrent-entry subset from the original specification.
   if(InpAllowConcurrentTFEntries && PeriodSeconds(sig.tf) <= PeriodSeconds(InpConcurrentEntry_MinTF))
      return true;
   return false;
}

void EvaluateSignals()
{
   if(IsTradingSuppressed())
      return;

   RegimeState masterState = ResolveMasterState(REGIME_UNKNOWN);

   if(InpMasterConsolidationOverridesLocal &&
      masterState == REGIME_CONSOLIDATING &&
      InpConsolidation_StayOut &&
      !InpConsolidation_AllowRangeFade)
      return;

   SetupSignal bestSig = BlankSignal(_Period, ENGINE_NONE, true);
   SetupSignal concurrentSignals[];
   int concurrentCount = 0;

   for(int i = 0; i < 7; i++)
   {
      ENUM_TIMEFRAMES tf = g_tfList[i];
      if(tf == PERIOD_CURRENT || !g_regimes[i].valid)
         continue;
      if(!PassesHigherTFZoneRequirement(i))
         continue;

      RegimeState localState = g_regimes[i].state;
      RegimeState gateState = masterState;
      if(!InpMasterConsolidationOverridesLocal && masterState == REGIME_CONSOLIDATING)
         gateState = localState;
      SetupSignal sig = BlankSignal(tf, ENGINE_NONE, true);

      bool masterLocksToConsolidation = (InpMasterConsolidationOverridesLocal && masterState == REGIME_CONSOLIDATING);
      if(masterLocksToConsolidation)
      {
         if(localState == REGIME_CONSOLIDATING)
            sig = BuildRangeFadeSignal(tf);
      }
      else if(localState == REGIME_CONSOLIDATING)
      {
         if(InpConsolidation_AllowRangeFade)
            sig = BuildRangeFadeSignal(tf);
      }
      else if((localState == REGIME_REVERSAL_FORMING_BULL || localState == REGIME_REVERSAL_FORMING_BEAR) &&
              InpEngineR_Enabled &&
              (!InpEngineR_GateSourceBias || gateState == localState))
      {
         sig = BuildReversalSignal(tf, localState == REGIME_REVERSAL_FORMING_BULL);
      }
      else if((localState == REGIME_TRENDING_UP || localState == REGIME_TRENDING_DOWN) &&
              InpEngineT_Enabled &&
              (!InpEngineT_GateSourceBias || gateState == localState))
      {
         sig = BuildTrendSignal(tf, localState == REGIME_TRENDING_UP);
      }

      if(!sig.valid)
         continue;

      double required = GetAdaptiveThreshold(sig.engine, InpMinConfluenceScore);
      if(sig.confirmed == false && sig.engine == ENGINE_TREND)
         required = GetAdaptiveThreshold(sig.engine, MathMax(InpMinConfluenceScore, InpMinConfluenceScore_PreConfirm));
      if(sig.confluenceScore < required || sig.rr < InpMinRR)
         continue;

      if(SignalAllowedForCurrentConcurrency(sig))
      {
         ArrayResize(concurrentSignals, concurrentCount + 1);
         concurrentSignals[concurrentCount++] = sig;
      }
      else if(!bestSig.valid || sig.confluenceScore > bestSig.confluenceScore)
      {
         bestSig = sig;
      }
   }

   if(bestSig.valid)
      SubmitSignal(bestSig);

   if(InpAllowConcurrentTFEntries)
      for(int i = 0; i < concurrentCount; i++)
         SubmitSignal(concurrentSignals[i]);
}

//====================================================================
// Order / position helpers
//====================================================================
int CountManagedPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != g_magic)
         continue;
      count++;
   }
   return count;
}

int CountManagedPendingOrders()
{
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != g_magic)
         continue;

      ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_SELL_LIMIT)
         count++;
   }
   return count;
}

bool HasExistingManagedSignal(const SetupSignal &sig)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != g_magic)
         continue;
      if(PositionGetString(POSITION_COMMENT) == sig.comment)
         return true;
   }

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != g_magic)
         continue;
      if(OrderGetString(ORDER_COMMENT) == sig.comment)
         return true;
   }
   return false;
}

ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
   long fill = 0;
   if(!SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE, fill))
      return ORDER_FILLING_FOK;
   if((fill & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   if((fill & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
}

double MinimumStopDistancePrice()
{
   long stops = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freeze = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   return MathMax((double)stops, (double)freeze) * _Point;
}

bool ValidateSignalPrices(const SetupSignal &sig, const bool usePending, string &why)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minDist = MinimumStopDistancePrice();

   if(sig.isLong)
   {
      if(sig.sl >= sig.entryPrice)
      {
         why = "long SL not below entry";
         return false;
      }
      if(sig.finalTp <= sig.entryPrice)
      {
         why = "long TP not above entry";
         return false;
      }
      if(usePending)
      {
         if(sig.entryPrice >= ask - minDist)
         {
            why = "buy limit must be below ask with stop buffer";
            return false;
         }
      }
      else
      {
         if((ask - sig.sl) < minDist)
         {
            why = "market buy SL too close to ask";
            return false;
         }
         if((sig.finalTp - ask) < minDist)
         {
            why = "market buy TP too close to ask";
            return false;
         }
      }
   }
   else
   {
      if(sig.sl <= sig.entryPrice)
      {
         why = "short SL not above entry";
         return false;
      }
      if(sig.finalTp >= sig.entryPrice)
      {
         why = "short TP not below entry";
         return false;
      }
      if(usePending)
      {
         if(sig.entryPrice <= bid + minDist)
         {
            why = "sell limit must be above bid with stop buffer";
            return false;
         }
      }
      else
      {
         if((sig.sl - bid) < minDist)
         {
            why = "market sell SL too close to bid";
            return false;
         }
         if((bid - sig.finalTp) < minDist)
         {
            why = "market sell TP too close to bid";
            return false;
         }
      }
   }

   if(MathAbs(sig.entryPrice - sig.sl) < minDist)
   {
      why = "entry/SL inside minimum stop distance";
      return false;
   }
   if(MathAbs(sig.finalTp - sig.entryPrice) < minDist)
   {
      why = "TP inside minimum stop distance";
      return false;
   }
   return true;
}

double CalcLotFromRisk(const SetupSignal &sig)
{
   double rawLot = InpDefaultLotSize;
   if(InpUseRiskPercentSizing)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double riskMoney = equity * (InpRiskPercentPerTrade / 100.0) * MathMax(0.0, sig.riskMultiplier);
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize <= 0.0 || tickValue <= 0.0)
         return NormalizeVolume(InpDefaultLotSize);

      double priceRisk = MathAbs(sig.entryPrice - sig.sl);
      double moneyPerLot = (priceRisk / tickSize) * tickValue;
      if(moneyPerLot <= 0.0)
         return NormalizeVolume(InpDefaultLotSize);
      rawLot = riskMoney / moneyPerLot;
   }
   return NormalizeVolume(rawLot);
}

bool SendTradeRequest(MqlTradeRequest &request, MqlTradeResult &result)
{
   ZeroMemory(result);
   bool ok = OrderSend(request, result);
   if(!ok)
      Print("OrderSend failed. action=", request.action, " retcode=", result.retcode, " error=", GetLastError());
   else if(result.retcode != TRADE_RETCODE_DONE &&
           result.retcode != TRADE_RETCODE_PLACED &&
           result.retcode != TRADE_RETCODE_DONE_PARTIAL)
      Print("Trade rejected. retcode=", result.retcode, " comment=", result.comment);
   return ok && (result.retcode == TRADE_RETCODE_DONE ||
                 result.retcode == TRADE_RETCODE_PLACED ||
                 result.retcode == TRADE_RETCODE_DONE_PARTIAL);
}

bool SubmitSignal(const SetupSignal &sig)
{
   if(!sig.valid)
      return false;

   int idx = TFIndex(sig.tf);
   if(idx >= 0 && g_lastSignalSignature[idx] == sig.signature && (TimeCurrent() - g_lastSignalStamp[idx]) < MathMax(60, PeriodSeconds(sig.tf)))
      return false;
   if(HasExistingManagedSignal(sig))
      return false;

   int effectiveMaxPositions = InpAllowMultiplePositions ? MathMax(1, InpMaxConcurrentPositions) : 1;
   if(CountManagedPositions() >= effectiveMaxPositions)
      return false;
   if(sig.pendingPreferred && CountManagedPendingOrders() >= InpMaxPendingOrders)
      return false;

   string why = "";
   bool usePending = sig.pendingPreferred;
   if(usePending && !ValidateSignalPrices(sig, true, why))
   {
      if((sig.engine == ENGINE_REVERSAL && InpEngineR_UsePendingOnly) || !sig.confirmed)
      {
         Print("Signal skipped: ", why);
         return false;
      }
      usePending = false;
   }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   SetupSignal execSig = sig;
   if(!usePending)
   {
      execSig.entryPrice = NormalizePrice(sig.isLong ? ask : bid);
      double risk = MathAbs(execSig.entryPrice - sig.sl);
      execSig.tp1 = NormalizePrice(sig.isLong ? execSig.entryPrice + risk * InpTP1Ratio : execSig.entryPrice - risk * InpTP1Ratio);
      execSig.tp2 = NormalizePrice(sig.isLong ? execSig.entryPrice + risk * InpTP2Ratio : execSig.entryPrice - risk * InpTP2Ratio);
      execSig.tp3 = NormalizePrice(sig.isLong ? execSig.entryPrice + risk * InpTP3Ratio : execSig.entryPrice - risk * InpTP3Ratio);
      execSig.tp4 = NormalizePrice(sig.isLong ? execSig.entryPrice + risk * InpTP4Ratio : execSig.entryPrice - risk * InpTP4Ratio);
      execSig.tp5 = NormalizePrice(sig.isLong ? execSig.entryPrice + risk * InpTP5Ratio : execSig.entryPrice - risk * InpTP5Ratio);
      execSig.finalTp = execSig.tp5;
      execSig.rr = ComputeRR(execSig.isLong, execSig.entryPrice, execSig.sl, execSig.finalTp);
      if(!ValidateSignalPrices(execSig, false, why))
      {
         Print("Market signal rejected after fallback: ", why);
         return false;
      }
   }

   double volume = CalcLotFromRisk(execSig);
   if(volume <= 0.0)
      return false;

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);

   request.magic = g_magic;
   request.symbol = _Symbol;
   request.volume = volume;
   request.sl = execSig.sl;
   request.tp = execSig.finalTp;
   request.deviation = InpMaxSlippagePoints;
   request.type_filling = GetFillingMode();
   request.comment = execSig.comment;

   if(usePending)
   {
      request.action = TRADE_ACTION_PENDING;
      request.type = execSig.isLong ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
      request.price = execSig.entryPrice;
      request.type_time = ORDER_TIME_GTC;
   }
   else
   {
      request.action = TRADE_ACTION_DEAL;
      request.type = execSig.isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      request.price = execSig.isLong ? ask : bid;
   }

   if(!SendTradeRequest(request, result))
      return false;

   if(idx >= 0)
   {
      g_lastSignalSignature[idx] = sig.signature;
      g_lastSignalStamp[idx] = TimeCurrent();
   }

   DrawSetup(sig);
   SendAlertMessage(StringFormat("%s %s %s @ %.5f SL %.5f TP %.5f",
                                 usePending ? "Pending" : "Entry",
                                 sig.reason,
                                 TimeframeToString(sig.tf),
                                 execSig.entryPrice,
                                 execSig.sl,
                                 execSig.finalTp));
   return true;
}

//====================================================================
// Position management
//====================================================================
int GetPositionStateIndex(const ulong ticket)
{
   for(int i = 0; i < ArraySize(g_positionStates); i++)
   {
      if(g_positionStates[i].active && g_positionStates[i].ticket == ticket)
         return i;
      if(!g_positionStates[i].active)
      {
         g_positionStates[i].ticket = ticket;
         g_positionStates[i].positionId = 0;
         g_positionStates[i].engineCode = 0;
         g_positionStates[i].realizedProfit = 0.0;
         g_positionStates[i].initialRiskDistance = 0.0;
         g_positionStates[i].tp1Done = false;
         g_positionStates[i].tp2Done = false;
         g_positionStates[i].tp3Done = false;
         g_positionStates[i].tp4Done = false;
         g_positionStates[i].tp5Done = false;
         g_positionStates[i].active = true;
         return i;
      }
   }

   int oldSize = ArraySize(g_positionStates);
   ArrayResize(g_positionStates, oldSize + 1);
   g_positionStates[oldSize].ticket = ticket;
   g_positionStates[oldSize].positionId = 0;
   g_positionStates[oldSize].engineCode = 0;
   g_positionStates[oldSize].realizedProfit = 0.0;
   g_positionStates[oldSize].initialRiskDistance = 0.0;
   g_positionStates[oldSize].tp1Done = false;
   g_positionStates[oldSize].tp2Done = false;
   g_positionStates[oldSize].tp3Done = false;
   g_positionStates[oldSize].tp4Done = false;
   g_positionStates[oldSize].tp5Done = false;
   g_positionStates[oldSize].active = true;
   return oldSize;
}

bool ModifyPositionSLTP(const ulong ticket, const string symbol, const double sl, const double tp)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = symbol;
   request.sl = NormalizePrice(sl);
   request.tp = NormalizePrice(tp);
   request.magic = g_magic;
   return SendTradeRequest(request, result);
}

int TryPartialClose(const ulong ticket, const double currentVolume, const double closePercent, const string symbol)
{
   if(closePercent <= 0.0 || currentVolume <= 0.0)
      return -1;

   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double desiredVolume = currentVolume * closePercent / 100.0;
   int stepDigits = VolumeDigitsFromStep(step);
   double volumeToClose = (step > 0.0) ? MathFloor(desiredVolume / step + 1e-8) * step : desiredVolume;
   volumeToClose = NormalizeDouble(volumeToClose, stepDigits);
   double minVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   if(volumeToClose <= 0.0 || volumeToClose >= currentVolume)
      return -1;

   double remainVolume = NormalizeDouble(currentVolume - volumeToClose, stepDigits);
   if(remainVolume > 0.0 && remainVolume < minVolume)
      return -1;
   if(step > 0.0 && remainVolume > 0.0 && MathAbs(MathRound(remainVolume / step) * step - remainVolume) > 1e-8)
      return -1;

   g_trade.SetExpertMagicNumber(g_magic);
   g_trade.SetTypeFillingBySymbol(symbol);
   if(g_trade.PositionClosePartial(ticket, volumeToClose))
      return 1;
   return 0;
}

void ManageOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC) != g_magic)
         continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double volume = PositionGetDouble(POSITION_VOLUME);
      long type = PositionGetInteger(POSITION_TYPE);
      bool isLong = (type == POSITION_TYPE_BUY);
      int stateIndex = GetPositionStateIndex(ticket);
      g_positionStates[stateIndex].positionId = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
      string posComment = PositionGetString(POSITION_COMMENT);
      if(StringLen(posComment) > 0)
      {
         if(StringGetCharacter(posComment, 0) == 'T')
            g_positionStates[stateIndex].engineCode = (int)ENGINE_TREND;
         else if(StringGetCharacter(posComment, 0) == 'C')
            g_positionStates[stateIndex].engineCode = (int)ENGINE_CONSOLIDATION;
         else
            g_positionStates[stateIndex].engineCode = (int)ENGINE_REVERSAL;
      }
      if(sl > 0.0 && g_positionStates[stateIndex].initialRiskDistance <= 0.0)
         g_positionStates[stateIndex].initialRiskDistance = MathAbs(openPrice - sl);
      double risk = MathAbs(openPrice - sl);
      if(risk <= 0.0)
         risk = g_positionStates[stateIndex].initialRiskDistance;
      if(risk <= 0.0 && tp > 0.0 && InpTP5Ratio > 0.0)
         risk = MathAbs(tp - openPrice) / InpTP5Ratio;
      if(risk <= 0.0)
         continue;
      double progress = isLong ? (currentPrice - openPrice) / risk : (openPrice - currentPrice) / risk;

      if(InpUseBreakEven)
      {
         double beTrigger = (InpBreakEvenPoints > 0.0) ? InpBreakEvenPoints * _Point : risk;
         if(isLong && currentPrice - openPrice >= beTrigger && openPrice > sl)
            ModifyPositionSLTP(ticket, _Symbol, openPrice, tp);
         if(!isLong && openPrice - currentPrice >= beTrigger && openPrice < sl)
            ModifyPositionSLTP(ticket, _Symbol, openPrice, tp);
      }

      if(InpUseTrailingStop)
      {
         double trailStart = MathMax(InpTrailStartPoints * _Point, risk);
         double trailStep = MathMax(_Point, InpTrailStepPoints * _Point);
         if(isLong && currentPrice - openPrice >= trailStart)
         {
            double newSL = NormalizePrice(currentPrice - trailStart);
            if(newSL > sl + trailStep)
               ModifyPositionSLTP(ticket, _Symbol, newSL, tp);
         }
         if(!isLong && openPrice - currentPrice >= trailStart)
         {
            double newSL = NormalizePrice(currentPrice + trailStart);
            if(sl == 0.0 || newSL < sl - trailStep)
               ModifyPositionSLTP(ticket, _Symbol, newSL, tp);
         }
      }

      if(progress >= InpTP1Ratio && !g_positionStates[stateIndex].tp1Done)
      {
         double tp1Close = (InpTP1ClosePercent > 0.0) ? InpTP1ClosePercent : (double)InpPartialTP_Ratio;
         int partialResult = TryPartialClose(ticket, volume, tp1Close, _Symbol);
         if(partialResult == 1)
         {
            g_positionStates[stateIndex].tp1Done = true;
            continue;
         }
         if(partialResult == -1)
            g_positionStates[stateIndex].tp1Done = true;
      }
      if(progress >= InpTP2Ratio && !g_positionStates[stateIndex].tp2Done)
      {
         int partialResult = TryPartialClose(ticket, volume, InpTP2ClosePercent, _Symbol);
         if(partialResult == 1)
         {
            g_positionStates[stateIndex].tp2Done = true;
            continue;
         }
         if(partialResult == -1)
            g_positionStates[stateIndex].tp2Done = true;
      }
      if(progress >= InpTP3Ratio && !g_positionStates[stateIndex].tp3Done)
      {
         int partialResult = TryPartialClose(ticket, volume, InpTP3ClosePercent, _Symbol);
         if(partialResult == 1)
         {
            g_positionStates[stateIndex].tp3Done = true;
            continue;
         }
         if(partialResult == -1)
            g_positionStates[stateIndex].tp3Done = true;
      }
      if(progress >= InpTP4Ratio && !g_positionStates[stateIndex].tp4Done)
      {
         int partialResult = TryPartialClose(ticket, volume, InpTP4ClosePercent, _Symbol);
         if(partialResult == 1)
         {
            g_positionStates[stateIndex].tp4Done = true;
            continue;
         }
         if(partialResult == -1)
            g_positionStates[stateIndex].tp4Done = true;
      }
      if(progress >= InpTP5Ratio && !g_positionStates[stateIndex].tp5Done)
      {
         int partialResult = TryPartialClose(ticket, volume, InpTP5ClosePercent, _Symbol);
         if(partialResult == 1)
         {
            g_positionStates[stateIndex].tp5Done = true;
            continue;
         }
         if(partialResult == -1)
            g_positionStates[stateIndex].tp5Done = true;
      }
   }
}

//====================================================================
// Chart UI
//====================================================================
void DeleteObjectsWithPrefix(const string prefix)
{
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

void DrawTextObject(const string name, const datetime t, const double price, const string text, const color clr)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, t, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
}

void DrawLineObject(const string name, const datetime t1, const double p1, const datetime t2, const double p2, const color clr)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectMove(0, name, 0, t1, p1);
   ObjectMove(0, name, 1, t2, p2);
}

void DrawZoneObject(const string name, const datetime t1, const datetime t2, const double low, const double high, const color clr)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, low, t2, high);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectMove(0, name, 0, t1, low);
   ObjectMove(0, name, 1, t2, high);
}

void DrawSetup(const SetupSignal &sig)
{
   string base = g_objectPrefix + sig.signature + "_";
   color clr = sig.isLong ? clrLime : clrRed;

   if(InpDrawSetupZones)
      DrawZoneObject(base + "ZONE", sig.aTime1, TimeCurrent(), sig.zoneLow, sig.zoneHigh, clr);

   if(InpDrawSetupLabels)
   {
      if(sig.aTime1 > 0) DrawTextObject(base + "A1", sig.aTime1, sig.aPrice1, sig.aLabel1, clr);
      if(sig.aTime2 > 0) DrawTextObject(base + "A2", sig.aTime2, sig.aPrice2, sig.aLabel2, clr);
      if(sig.aTime3 > 0) DrawTextObject(base + "A3", sig.aTime3, sig.aPrice3, sig.aLabel3, clr);
      if(sig.aTime4 > 0) DrawTextObject(base + "A4", sig.aTime4, sig.aPrice4, sig.aLabel4, clr);
      if(sig.aTime5 > 0 && StringLen(sig.aLabel5) > 0) DrawTextObject(base + "A5", sig.aTime5, sig.aPrice5, sig.aLabel5, clr);
   }

   if(InpDrawSetupLines)
   {
      if(sig.aTime1 > 0 && sig.aTime2 > 0) DrawLineObject(base + "L1", sig.aTime1, sig.aPrice1, sig.aTime2, sig.aPrice2, clr);
      if(sig.aTime2 > 0 && sig.aTime3 > 0) DrawLineObject(base + "L2", sig.aTime2, sig.aPrice2, sig.aTime3, sig.aPrice3, clr);
      if(sig.aTime3 > 0 && sig.aTime4 > 0) DrawLineObject(base + "L3", sig.aTime3, sig.aPrice3, sig.aTime4, sig.aPrice4, clr);
      if(sig.aTime4 > 0 && sig.aTime5 > 0) DrawLineObject(base + "L4", sig.aTime4, sig.aPrice4, sig.aTime5, sig.aPrice5, clr);
   }
}

void DrawDashboard()
{
   if(!InpEnableDashboard)
      return;

   if(ObjectFind(0, g_dashboardName) < 0)
      ObjectCreate(0, g_dashboardName, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, g_dashboardName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSetInteger(0, g_dashboardName, OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(0, g_dashboardName, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, g_dashboardName, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, g_dashboardName, OBJPROP_FONT, "Tahoma");

   string text = "Regime EA\n";
   for(int i = 0; i < 7; i++)
   {
      if(g_tfList[i] == PERIOD_CURRENT)
         continue;
      text += TimeframeToString(g_tfList[i]) + ": " + RegimeToString(g_regimes[i].state) + "\n";
   }
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnlPct = (g_profitGovernanceBaseEquity > 0.0) ? ((equity - g_profitGovernanceBaseEquity) / g_profitGovernanceBaseEquity * 100.0) : 0.0;
   text += "Pos: " + IntegerToString(CountManagedPositions()) + " Pend: " + IntegerToString(CountManagedPendingOrders()) + "\n";
   text += "Gov: " + DoubleToString(pnlPct, 2) + "%";
   ObjectSetString(0, g_dashboardName, OBJPROP_TEXT, text);
}

void ClearChartObjects()
{
   DeleteObjectsWithPrefix(g_objectPrefix);
}

//====================================================================
// Alerts / adaptive updates
//====================================================================
string UrlEncode(const string text)
{
   string out = "";
   uchar bytes[];
   int count = StringToCharArray(text, bytes, 0, -1, CP_UTF8);
   if(count <= 0)
      return out;

   for(int i = 0; i < count - 1; i++)
   {
      int c = (int)bytes[i];
      if((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.')
         out += StringFormat("%c", c);
      else if(c == ' ')
         out += "%20";
      else if(c == 10)
         out += "%0A";
      else
         out += StringFormat("%%%02X", c);
   }
   return out;
}

void SendAlertMessage(const string msg)
{
   if(!InpEnableAlerts)
      return;

   Alert(msg);
   if(InpSendPushNotifications)
      SendNotification(msg);

   if(StringLen(InpTelegramBotToken) == 0 || StringLen(InpTelegramChatID) == 0)
      return;

   string url = "https://api.telegram.org/bot" + InpTelegramBotToken + "/sendMessage";
   string body = "chat_id=" + UrlEncode(InpTelegramChatID) + "&text=" + UrlEncode(msg);
   char data[];
   char result[];
   string resultHeaders = "";
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   StringToCharArray(body, data, 0, -1, CP_UTF8);
   ResetLastError();
   int code = WebRequest("POST", url, headers, 5000, data, result, resultHeaders);
   if(code == -1)
      Print("Telegram WebRequest failed: ", GetLastError());
}

void UpdateAdaptiveStatsFromDeal(const ulong dealTicket)
{
   if(!InpAdaptiveLearning_Enabled)
      return;
   if(!HistorySelect(0, TimeCurrent()))
      return;
   if((long)HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != g_magic)
      return;
   if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
      return;

   long entryType = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY)
      return;

   double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT) + HistoryDealGetDouble(dealTicket, DEAL_SWAP) + HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
   ulong dealPositionId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
   int engineCode = 0;
   for(int i = 0; i < ArraySize(g_positionStates); i++)
   {
      if(g_positionStates[i].positionId == dealPositionId && g_positionStates[i].active)
      {
         engineCode = g_positionStates[i].engineCode;
         g_positionStates[i].realizedProfit += profit;
         if(HasOpenManagedPositionId(dealPositionId))
            return;
         profit = g_positionStates[i].realizedProfit;
         g_positionStates[i].active = false;
         break;
      }
   }

   int idx = 0;
   if(engineCode == (int)ENGINE_TREND) idx = 1;
   else if(engineCode == (int)ENGINE_CONSOLIDATION) idx = 2;

   if(profit >= 0.0)
      RecordAdaptiveOutcome(idx, true);
   else
      RecordAdaptiveOutcome(idx, false);
}

void CancelManagedPendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != g_magic)
         continue;

      ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type != ORDER_TYPE_BUY_LIMIT && type != ORDER_TYPE_SELL_LIMIT)
         continue;

      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      request.action = TRADE_ACTION_REMOVE;
      request.order = ticket;
      request.symbol = _Symbol;
      request.magic = g_magic;
      SendTradeRequest(request, result);
   }
}

//====================================================================
// End of file
//====================================================================
datetime SessionAnchorTime(const datetime sourceTime)
{
   MqlDateTime dt;
   TimeToStruct(sourceTime, dt);
   dt.min = 0;
   dt.sec = 0;

   bool overnight = (InpSessionEndHour < InpSessionStartHour);
   if(overnight)
   {
      bool afterMidnightSessionSegment = (dt.hour <= InpSessionEndHour);
      bool beforeEveningSessionStart = (dt.hour < InpSessionStartHour);
      if(afterMidnightSessionSegment || beforeEveningSessionStart)
      {
         datetime priorDay = StructToTime(dt) - 86400;
         TimeToStruct(priorDay, dt);
      }
   }
   else
   {
      if(dt.hour < InpSessionStartHour)
      {
         datetime priorDay = StructToTime(dt) - 86400;
         TimeToStruct(priorDay, dt);
      }
   }

   dt.hour = InpSessionStartHour;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}
