#property copyright "KAYBAMBODLABFX"
#property version   "1.00"
#property strict

#include "Core\Types.mqh"
#include "Core\MarketData.mqh"
#include "Market\StructureEngine.mqh"
#include "Market\ContextEngine.mqh"
#include "Strategy\SignalEngine.mqh"
#include "Filters\TradingFilters.mqh"
#include "Risk\RiskManager.mqh"
#include "Execution\TradeExecutor.mqh"
#include "Management\PositionManager.mqh"
#include "Alerts\AlertEngine.mqh"
#include "UI\Dashboard.mqh"
#include "Analytics\TradeMemory.mqh"

#define KBLX_MAX_SYMBOLS 32
#define KBLX_FRAME_COUNT 7

input group "=== GENERAL ==="
input bool InpAllowTrading = true;
input long InpMagicNumber = 316316316;
input int InpScanSeconds = 5;

input group "=== SYMBOLS ==="
input string InpSymbols = "";
input bool InpTradeChartSymbol = true;

input group "=== TIMEFRAMES ==="
input ENUM_TIMEFRAMES InpTF_D1 = PERIOD_D1;
input ENUM_TIMEFRAMES InpTF_H4 = PERIOD_H4;
input ENUM_TIMEFRAMES InpTF_H1 = PERIOD_H1;
input ENUM_TIMEFRAMES InpTF_M30 = PERIOD_M30;
input ENUM_TIMEFRAMES InpTF_M15 = PERIOD_M15;
input ENUM_TIMEFRAMES InpTF_M5 = PERIOD_M5;
input ENUM_TIMEFRAMES InpTF_M1 = PERIOD_M1;
input bool InpScanEveryTick = true;
input bool InpAllowConcurrentSignals = true;

input group "=== TIMEFRAME CONTEXT AND ENTRIES ==="
input bool InpScanD1 = true;
input bool InpScanH4 = true;
input bool InpScanH1 = true;
input bool InpScanM30 = true;
input bool InpScanM15 = true;
input bool InpScanM5 = true;
input bool InpScanM1 = true;
input bool InpTradeD1 = false;
input bool InpTradeH4 = true;
input bool InpTradeH1 = true;
input bool InpTradeM30 = true;
input bool InpTradeM15 = true;
input bool InpTradeM5 = true;
input bool InpTradeM1 = true;
input bool InpIndependentH4 = false;
input bool InpIndependentH1 = true;
input bool InpIndependentM30 = true;
input bool InpIndependentM15 = true;
input bool InpIndependentM5 = true;
input bool InpIndependentM1 = true;
input bool InpRequireHigherDemandH4 = true;
input bool InpRequireHigherDemandH1 = false;
input bool InpRequireHigherDemandM30 = false;
input bool InpRequireHigherDemandM15 = false;
input bool InpRequireHigherDemandM5 = false;
input bool InpRequireHigherDemandM1 = false;
input bool InpRequireHigherTrendConfirmation = false;
input bool InpUseMTFTrendFilter = false;
input double InpMTFWeightD1 = 1.0;
input double InpMTFWeightH4 = 1.0;
input double InpMTFWeightH1 = 1.0;
input double InpMTFWeightM30 = 1.0;
input double InpMTFWeightM15 = 1.0;
input double InpMTFWeightM5 = 1.0;
input double InpMTFWeightM1 = 1.0;
input double InpMTFMinimumWeight = 1.0;
input int InpContextLookbackBars = 100;
input int InpVolumeBinPoints = 50;
input bool InpRequireVolumeConfluence = false;

input group "=== DATA ==="
input int InpHistoryBars = 500;
input int InpMaxCacheAgeSeconds = 5;

input group "=== SWING ==="
input int InpSwingStrength = 2;
input int InpSwingLookback = 200;
input KBLXDistanceUnitMode InpMarketDistanceUnits = KBLX_UNITS_AUTO;
input double InpMinimumSwingDistancePoints = 0.0;
input int InpMaximumSwingAgeBars = 100;
input double InpEqualSwingTolerancePoints = 0.0;

input group "=== STRUCTURE ==="
input int InpStructureSwings = 3;

input group "=== TREND ==="
input bool InpUseStructureTrend = true;

input group "=== LIQUIDITY ==="
input bool InpRequireLiquiditySweep = false;
input double InpLiquiditySweepTolerancePoints = 0.0;

input group "=== REVERSAL ==="
input bool InpEnableReversals = true;
input int InpSetupMaximumAgeBars = 50;

input group "=== BOS/CHOCH ==="
input KBLXBreakSelection InpBreakSelection = KBLX_CHOCH_OR_BOS;

input group "=== RETRACEMENT A ==="
input bool InpEnableRetraceA = true;
input double InpRetraceATolerancePoints = 5.0;

input group "=== RETRACEMENT B ==="
input bool InpEnableRetraceB = true;
input bool InpEngulfBodyOnly = true;

input group "=== RETRACEMENT C ==="
input bool InpEnableRetraceC = true;

input group "=== RETRACEMENT D ==="
input bool InpEnableRetraceD = true;
input double InpFibRatio = 0.618;
input bool InpFibUseWicks = true;
input double InpSecondaryFibRatio = 0.5;

input group "=== RETRACEMENT COMBINATION ==="
input KBLXRetracementMode InpRetraceMode = KBLX_RETRACE_ANY;
input int InpRequiredRetracements = 1;

input group "=== PRIMARY TIMEFRAME GATE ==="
input bool InpRequirePrimaryGate = false;
input KBLXPrimaryGateMode InpPrimaryGateMode = KBLX_PRIMARY_GATE_ANY;

input group "=== ZONES ==="
input double InpZoneBufferPoints = 5.0;
input int InpZoneExpiryBars = 100;

input group "=== TRENDLINE ==="
input bool InpTrendlineEnabled = false;
input double InpTrendlineWidthPoints = 10.0;

input group "=== CONFLUENCE ==="
input double InpMinimumConfluenceScore = 0.0;

input group "=== MTF MAPPING ==="
input KBLXMTFMode InpMTFMode = KBLX_MTF_SINGLE;
input int InpMinimumConfirmations = 1;

input group "=== EXECUTION ==="
input KBLXExecutionMode InpExecutionMode = KBLX_MARKET_ONLY;
input ulong InpDeviationPoints = 10;

input group "=== DUPLICATE PREVENTION ==="
input bool InpPreventDuplicateSetups = true;

input group "=== RISK SIZING ==="
input KBLXSizingMode InpSizingMode = KBLX_FIXED_LOT;
input double InpFixedLots = 0.01;
input double InpRiskPercent = 0.5;
input double InpRiskMoney = 50.0;

input group "=== POSITION LIMITS ==="
input int InpMaxPositionsTotal = 1;
input int InpMaxPositionsPerSymbol = 1;
input int InpMaxPendingOrders = 3;

input group "=== STOP LOSS ==="
input KBLXStopMode InpStopMode = KBLX_SL_ZONE_BASED;
input double InpStopDistancePoints = 100.0;
input double InpStopBufferPoints = 10.0;
input double InpManualStopPrice = 0.0;
input int InpStopATRPeriod = 14;
input double InpStopATRMultiplier = 2.0;
input KBLXDistanceUnitMode InpStopDistanceUnits = KBLX_UNITS_AUTO;
input KBLXDistanceUnitMode InpManagementDistanceUnits = KBLX_UNITS_AUTO;

input group "=== TAKE PROFIT ==="
input KBLXTakeProfitMode InpTakeProfitMode = KBLX_TP_RR;
input int InpTakeProfitCount = 3;
input double InpManualTakeProfitPrice = 0.0;
input double InpFibonacciExtension = 1.618;
input double InpTP_R1 = 0.5;
input double InpTP_R2 = 1.0;
input double InpTP_R3 = 3.0;
input double InpTP_R4 = 4.0;
input double InpTP_R5 = 5.0;

input group "=== PARTIAL PROFITS ==="
input double InpTP_Partial1Percent = 25.0;
input double InpTP_Partial2Percent = 25.0;
input double InpTP_Partial3Percent = 0.0;
input double InpTP_Partial4Percent = 0.0;
input double InpTP_Partial5Percent = 0.0;

input group "=== BREAK EVEN / TRAILING ==="
input bool InpBreakEvenEnabled = true;
input double InpBreakEvenTriggerR = 1.0;
input double InpBreakEvenOffsetPoints = 0.0;
input bool InpTrailingEnabled = false;
input double InpTrailingStartPoints = 100.0;
input double InpTrailingDistancePoints = 50.0;
input double InpTrailingStepPoints = 10.0;

input group "=== PROFIT / LOSS LIMITS ==="
input bool InpProfitTargetEnabled = true;
input double InpProfitTargetPercent = 100.0;
input bool InpLossLimitEnabled = true;
input double InpLossLimitPercent = 5.0;
input KBLXLimitPeriod InpLimitPeriod = KBLX_LIMIT_DAY;
input int InpLimitMinutes = 60;
input int InpLimitHours = 1;
input double InpSessionProfitLimitMoney = 0.0;
input double InpSessionLossLimitMoney = 0.0;

input group "=== NEWS / SESSION / SPREAD ==="
input bool InpNewsFilterEnabled = true;
input int InpNewsMinutesBefore = 30;
input int InpNewsMinutesAfter = 30;
input int InpNewsMinimumImportance = 3;
input bool InpSessionFilterEnabled = false;
input int InpSessionStartHour = 0;
input int InpSessionEndHour = 23;
input double InpMaximumSpreadPoints = 0.0;
input bool InpTradeMonday = true;
input bool InpTradeTuesday = true;
input bool InpTradeWednesday = true;
input bool InpTradeThursday = true;
input bool InpTradeFriday = true;
input bool InpTradeSaturday = false;
input bool InpTradeSunday = false;

input group "=== ALERTS / TELEGRAM ==="
input bool InpAlertsEnabled = true;
input bool InpPushNotificationsEnabled = false;
input bool InpTelegramEnabled = false;
input string InpTelegramBotToken = "";
input string InpTelegramChatId = "";

input group "=== DASHBOARD / MEMORY / ANALYTICS ==="
input bool InpDashboardEnabled = true;
input bool InpDrawSwings = true;
input bool InpTradeMemoryEnabled = true;
input bool InpPerformanceFilterEnabled = false;
input int InpPerformanceMinimumSample = 30;
input double InpPerformanceMinimumWinRate = 50.0;

input group "=== DEBUG ==="
input bool InpDebug = false;

CKBLXMarketData g_market_data;
CKBLXStructureEngine g_structure_engines[];
CKBLXContextEngine g_context_engine;
CKBLXSignalEngine g_signal_engine;
CKBLXTradingFilters g_filters;
CKBLXRiskManager g_risk_manager;
CKBLXTradeExecutor g_executor;
CKBLXPositionManager g_position_manager;
CKBLXAlertEngine g_alerts;
CKBLXDashboard g_dashboard;
CKBLXTradeMemory g_trade_memory;
KBLXStructure g_chart_structure;
KBLXStructure g_frame_structures[KBLX_MAX_SYMBOLS][KBLX_FRAME_COUNT];
KBLXMarketContext g_frame_contexts[KBLX_MAX_SYMBOLS][KBLX_FRAME_COUNT];
datetime g_frame_bar_time[KBLX_MAX_SYMBOLS][KBLX_FRAME_COUNT];
datetime g_frame_retry_time[KBLX_MAX_SYMBOLS][KBLX_FRAME_COUNT];
string g_cached_symbols[KBLX_MAX_SYMBOLS];
int g_cached_symbol_count = 0;
datetime g_last_scan = 0;
string g_status = "Initializing";

bool ValidateInputs()
{
   if(InpMagicNumber <= 0 || InpScanSeconds < 1 ||
      InpHistoryBars < 50 || InpHistoryBars > 10000 ||
      InpSwingStrength < 1 || InpSwingLookback < InpSwingStrength * 2 + 2 ||
      InpMaximumSwingAgeBars < 0 || InpSetupMaximumAgeBars < 1 ||
      (InpMaximumSwingAgeBars > 0 && InpMaximumSwingAgeBars <= InpSwingStrength) ||
      InpStructureSwings < 3 || InpStructureSwings > 5 ||
      InpRequiredRetracements < 1 || InpRequiredRetracements > 4 ||
      InpMinimumConfirmations < 1 || InpMinimumConfirmations > 7 ||
      InpMaxPositionsTotal < 1 ||
      InpMaxPositionsPerSymbol < 1 || InpMaxPendingOrders < 0 ||
      InpTakeProfitCount < 1 || InpTakeProfitCount > 5 ||
      InpStopATRPeriod < 1 || InpStopATRMultiplier <= 0.0 ||
      InpFibonacciExtension <= 0.0 ||
      InpMaxCacheAgeSeconds < 0 || InpZoneExpiryBars < 1 ||
      InpFibRatio <= 0.0 || InpFibRatio >= 1.0 ||
      InpSecondaryFibRatio <= 0.0 || InpSecondaryFibRatio >= 1.0 ||
      InpRiskPercent < 0.0 || InpRiskMoney < 0.0 ||
      InpRiskPercent > 100.0 ||
      InpFixedLots <= 0.0 || InpMinimumConfluenceScore < 0.0 ||
      InpRetraceATolerancePoints < 0.0 || InpZoneBufferPoints < 0.0 ||
      InpMinimumSwingDistancePoints < 0.0 || InpEqualSwingTolerancePoints < 0.0 ||
      InpLiquiditySweepTolerancePoints < 0.0 || InpStopDistancePoints < 0.0 ||
      InpStopBufferPoints < 0.0 || InpMaximumSpreadPoints < 0.0 ||
      InpNewsMinutesBefore < 0 || InpNewsMinutesAfter < 0 ||
      InpNewsMinimumImportance < 1 || InpNewsMinimumImportance > 3 ||
      InpContextLookbackBars < 10 || InpContextLookbackBars > InpHistoryBars ||
      InpVolumeBinPoints < 1 || InpLimitMinutes < 1 || InpLimitHours < 1 ||
      InpProfitTargetPercent < 0.0 || InpLossLimitPercent < 0.0 ||
      InpSessionStartHour < 0 || InpSessionStartHour > 23 ||
      InpSessionEndHour < 0 || InpSessionEndHour > 23 ||
      InpSessionProfitLimitMoney < 0.0 || InpSessionLossLimitMoney < 0.0 ||
      InpBreakSelection < KBLX_CHOCH_ONLY ||
      InpBreakSelection > KBLX_CHOCH_AND_BOS ||
      InpMTFMode < KBLX_MTF_SINGLE || InpMTFMode > KBLX_MTF_ALL ||
      InpExecutionMode < KBLX_MARKET_ONLY ||
      InpExecutionMode > KBLX_AUTO_EXECUTION ||
      InpStopDistanceUnits < KBLX_UNITS_AUTO ||
      InpStopDistanceUnits > KBLX_UNITS_PIPS ||
      InpMarketDistanceUnits < KBLX_UNITS_AUTO ||
      InpMarketDistanceUnits > KBLX_UNITS_PIPS ||
      InpManagementDistanceUnits < KBLX_UNITS_AUTO ||
      InpManagementDistanceUnits > KBLX_UNITS_PIPS ||
      InpSizingMode < KBLX_FIXED_LOT || InpSizingMode > KBLX_DYNAMIC_RISK ||
      InpStopMode < KBLX_SL_FIXED_DISTANCE || InpStopMode > KBLX_SL_HYBRID ||
      InpTakeProfitMode < KBLX_TP_RR || InpTakeProfitMode > KBLX_TP_MANUAL ||
      InpRetraceMode < KBLX_RETRACE_ANY ||
      InpRetraceMode > KBLX_RETRACE_CONFLUENCE_REQUIRED ||
      InpPrimaryGateMode < KBLX_PRIMARY_GATE_ANY ||
      InpPrimaryGateMode > KBLX_PRIMARY_GATE_ALL ||
      InpLimitPeriod < KBLX_LIMIT_MINUTES || InpLimitPeriod > KBLX_LIMIT_DAY)
      return false;
   ENUM_TIMEFRAMES frames[KBLX_FRAME_COUNT];
   frames[0] = InpTF_D1; frames[1] = InpTF_H4; frames[2] = InpTF_H1;
   frames[3] = InpTF_M30; frames[4] = InpTF_M15; frames[5] = InpTF_M5;
   frames[6] = InpTF_M1;
   bool scans[KBLX_FRAME_COUNT];
   bool trades[KBLX_FRAME_COUNT];
   scans[0] = InpScanD1; scans[1] = InpScanH4; scans[2] = InpScanH1;
   scans[3] = InpScanM30; scans[4] = InpScanM15; scans[5] = InpScanM5;
   scans[6] = InpScanM1;
   trades[0] = InpTradeD1; trades[1] = InpTradeH4; trades[2] = InpTradeH1;
   trades[3] = InpTradeM30; trades[4] = InpTradeM15; trades[5] = InpTradeM5;
   trades[6] = InpTradeM1;
   bool any_scan = false;
   int scanned_frames = 0;
   for(int i = 0; i < KBLX_FRAME_COUNT; i++)
   {
      if(PeriodSeconds(frames[i]) <= 0)
         return false;
      if(i > 0 && PeriodSeconds(frames[i - 1]) <= PeriodSeconds(frames[i]))
         return false;
      if(scans[i])
      {
         any_scan = true;
         scanned_frames++;
      }
      if(trades[i] && !scans[i])
         return false;
      for(int j = 0; j < i; j++)
         if(frames[i] == frames[j])
            return false;
   }
   if(!any_scan || !InpEnableRetraceA ||
      InpBreakSelection == KBLX_CHOCH_AND_BOS)
      return false;
   if((InpMTFMode != KBLX_MTF_SINGLE || InpUseMTFTrendFilter ||
       InpRequireHigherTrendConfirmation) &&
      InpMinimumConfirmations > scanned_frames - 1)
      return false;
   int enabled_retracements = (InpEnableRetraceA ? 1 : 0) +
                              (InpEnableRetraceB ? 1 : 0) +
                              (InpEnableRetraceC ? 1 : 0) +
                              (InpEnableRetraceD ? 1 : 0);
   if(enabled_retracements == 0 ||
      InpRequiredRetracements > enabled_retracements)
      return false;
   if(InpMTFWeightD1 < 0.0 || InpMTFWeightH4 < 0.0 ||
      InpMTFWeightH1 < 0.0 || InpMTFWeightM30 < 0.0 ||
      InpMTFWeightM15 < 0.0 || InpMTFWeightM5 < 0.0 ||
      InpMTFWeightM1 < 0.0 ||
      InpMTFMinimumWeight < 0.0 ||
      (InpPerformanceFilterEnabled &&
      (InpPerformanceMinimumSample < 1 || InpPerformanceMinimumWinRate < 0.0 ||
       InpPerformanceMinimumWinRate > 100.0)))
      return false;
   double targets[5];
   targets[0] = InpTP_R1; targets[1] = InpTP_R2; targets[2] = InpTP_R3;
   targets[3] = InpTP_R4; targets[4] = InpTP_R5;
   double partials[5];
   partials[0] = InpTP_Partial1Percent; partials[1] = InpTP_Partial2Percent;
   partials[2] = InpTP_Partial3Percent; partials[3] = InpTP_Partial4Percent;
   partials[4] = InpTP_Partial5Percent;
   double partial_total = 0.0;
   for(int i = 0; i < InpTakeProfitCount; i++)
   {
      if(targets[i] <= 0.0 || (i > 0 && targets[i] <= targets[i - 1]) ||
         partials[i] < 0.0 || partials[i] > 100.0)
         return false;
      if(i < InpTakeProfitCount - 1)
         partial_total += partials[i];
   }
   if(partial_total > 100.0 ||
      (InpRequireHigherTrendConfirmation && !InpUseMTFTrendFilter))
      return false;
   return true;
}

int BuildSymbolList(string &symbols[])
{
   ArrayResize(symbols, 0);
   if(StringLen(InpSymbols) == 0)
   {
      if(InpTradeChartSymbol)
      {
         ArrayResize(symbols, 1);
         symbols[0] = _Symbol;
      }
      return ArraySize(symbols);
   }

   string configured[];
   ushort separator = (ushort)StringGetCharacter(",", 0);
   int count = StringSplit(InpSymbols, separator, configured);
   for(int i = 0; i < count && ArraySize(symbols) < KBLX_MAX_SYMBOLS; i++)
   {
      StringTrimLeft(configured[i]);
      StringTrimRight(configured[i]);
      if(configured[i] == "")
         continue;
      bool duplicate = false;
      for(int j = 0; j < ArraySize(symbols); j++)
         if(symbols[j] == configured[i]) duplicate = true;
      if(!duplicate)
      {
         int size = ArraySize(symbols);
         ArrayResize(symbols, size + 1);
         symbols[size] = configured[i];
      }
   }
   if(InpTradeChartSymbol)
   {
      bool found = false;
      for(int i = 0; i < ArraySize(symbols); i++)
         if(symbols[i] == _Symbol) found = true;
      if(!found && ArraySize(symbols) < KBLX_MAX_SYMBOLS)
      {
         int size = ArraySize(symbols);
         ArrayResize(symbols, size + 1);
         symbols[size] = _Symbol;
      }
   }
   return ArraySize(symbols);
}

ENUM_TIMEFRAMES FrameTimeframe(const int frame)
{
   if(frame == 0) return InpTF_D1;
   if(frame == 1) return InpTF_H4;
   if(frame == 2) return InpTF_H1;
   if(frame == 3) return InpTF_M30;
   if(frame == 4) return InpTF_M15;
   if(frame == 5) return InpTF_M5;
   return InpTF_M1;
}

bool FrameScanned(const int frame)
{
   if(frame == 0) return InpScanD1;
   if(frame == 1) return InpScanH4;
   if(frame == 2) return InpScanH1;
   if(frame == 3) return InpScanM30;
   if(frame == 4) return InpScanM15;
   if(frame == 5) return InpScanM5;
   return InpScanM1;
}

bool FrameTrades(const int frame)
{
   if(frame == 0) return InpTradeD1;
   if(frame == 1) return InpTradeH4;
   if(frame == 2) return InpTradeH1;
   if(frame == 3) return InpTradeM30;
   if(frame == 4) return InpTradeM15;
   if(frame == 5) return InpTradeM5;
   return InpTradeM1;
}

bool FrameIndependent(const int frame)
{
   if(frame == 1) return InpIndependentH4;
   if(frame == 2) return InpIndependentH1;
   if(frame == 3) return InpIndependentM30;
   if(frame == 4) return InpIndependentM15;
   if(frame == 5) return InpIndependentM5;
   if(frame == 6) return InpIndependentM1;
   return true;
}

bool FrameNeedsHigherDemand(const int frame)
{
   if(frame == 1) return InpRequireHigherDemandH4;
   if(frame == 2) return InpRequireHigherDemandH1;
   if(frame == 3) return InpRequireHigherDemandM30;
   if(frame == 4) return InpRequireHigherDemandM15;
   if(frame == 5) return InpRequireHigherDemandM5;
   if(frame == 6) return InpRequireHigherDemandM1;
   return false;
}

double FrameWeight(const int frame)
{
   if(frame == 0) return InpMTFWeightD1;
   if(frame == 1) return InpMTFWeightH4;
   if(frame == 2) return InpMTFWeightH1;
   if(frame == 3) return InpMTFWeightM30;
   if(frame == 4) return InpMTFWeightM15;
   if(frame == 5) return InpMTFWeightM5;
   return InpMTFWeightM1;
}

int CachedSymbolSlot(const string symbol)
{
   for(int i = 0; i < g_cached_symbol_count; i++)
      if(g_cached_symbols[i] == symbol)
         return i;
   if(g_cached_symbol_count >= KBLX_MAX_SYMBOLS)
      return -1;
   int slot = g_cached_symbol_count++;
   g_cached_symbols[slot] = symbol;
   return slot;
}

double MarketDistancePoints(const string symbol, const double distance)
{
   double point = g_market_data.PointSize(symbol);
   double price_distance = g_risk_manager.DistancePrice(
      symbol, distance, InpMarketDistanceUnits);
   if(point <= 0.0 || price_distance < 0.0)
      return -1.0;
   return price_distance / point;
}

bool PriceAtHigherZone(const int symbol_slot, const int frame, const double price,
                       const KBLXDirection direction)
{
   for(int higher = 0; higher < frame; higher++)
   {
      if(!FrameScanned(higher))
         continue;
      KBLXZone zone = (direction == KBLX_DIRECTION_BUY
                       ? g_frame_contexts[symbol_slot][higher].demand
                       : g_frame_contexts[symbol_slot][higher].supply);
      if(zone.valid && price >= zone.low && price <= zone.high)
         return true;
   }
   return false;
}

void BuildTradePlan(KBLXTradePlan &plan)
{
   plan.count = InpTakeProfitCount;
   plan.target_r[0] = InpTP_R1; plan.target_r[1] = InpTP_R2;
   plan.target_r[2] = InpTP_R3; plan.target_r[3] = InpTP_R4;
   plan.target_r[4] = InpTP_R5;
   plan.partial_percent[0] = InpTP_Partial1Percent;
   plan.partial_percent[1] = InpTP_Partial2Percent;
   plan.partial_percent[2] = InpTP_Partial3Percent;
   plan.partial_percent[3] = InpTP_Partial4Percent;
   plan.partial_percent[4] = InpTP_Partial5Percent;
}

bool MTFTrendPasses(const int symbol_slot, const int entry_frame,
                   const KBLXDirection direction)
{
   bool use_filter = (InpUseMTFTrendFilter ||
                     InpRequireHigherTrendConfirmation ||
                     InpMTFMode != KBLX_MTF_SINGLE);
   if(!use_filter)
      return true;
   int aligned = 0;
   double weight = 0.0;
   int available = 0;
   for(int frame = 0; frame < KBLX_FRAME_COUNT; frame++)
   {
      if(frame == entry_frame || !FrameScanned(frame) ||
         (InpRequireHigherTrendConfirmation && frame > entry_frame) ||
         !g_frame_structures[symbol_slot][frame].valid)
         continue;
      available++;
      KBLXTrend trend = g_frame_structures[symbol_slot][frame].trend;
      if((direction == KBLX_DIRECTION_BUY && trend == KBLX_TREND_UP) ||
         (direction == KBLX_DIRECTION_SELL && trend == KBLX_TREND_DOWN))
      {
         aligned++;
         weight += FrameWeight(frame);
      }
   }
   if(available == 0)
      return false;
   if(InpMTFMode == KBLX_MTF_ALL && aligned < available)
      return false;
   if((InpUseMTFTrendFilter || InpRequireHigherTrendConfirmation ||
       InpMTFMode == KBLX_MTF_MULTIPLE) &&
      (aligned < InpMinimumConfirmations || weight < InpMTFMinimumWeight))
      return false;
   return true;
}

void ScanMarkets()
{
   string symbols[];
   int symbol_count = BuildSymbolList(symbols);
   if(symbol_count < 1)
   {
      g_status = "No symbols configured";
      return;
   }
   bool any_signal = false;
   KBLXTradePlan trade_plan;
   BuildTradePlan(trade_plan);
   for(int symbol_index = 0; symbol_index < symbol_count; symbol_index++)
   {
      string symbol = symbols[symbol_index];
      if(!SymbolSelect(symbol, true))
         continue;
      int symbol_slot = CachedSymbolSlot(symbol);
      if(symbol_slot < 0)
         continue;
      for(int frame = 0; frame < KBLX_FRAME_COUNT; frame++)
      {
         if(!FrameScanned(frame))
            continue;
         ENUM_TIMEFRAMES timeframe = FrameTimeframe(frame);
         bool new_bar = g_market_data.IsNewBar(symbol, timeframe);
         bool retry_invalid = (!g_frame_structures[symbol_slot][frame].valid &&
            (g_frame_retry_time[symbol_slot][frame] == 0 ||
             TimeCurrent() - g_frame_retry_time[symbol_slot][frame] >= InpScanSeconds));
         if(retry_invalid || new_bar)
         {
            KBLXStructure structure;
            double minimum_swing_points =
              MarketDistancePoints(symbol, InpMinimumSwingDistancePoints);
            double equal_swing_points =
              MarketDistancePoints(symbol, InpEqualSwingTolerancePoints);
            double zone_buffer_points =
              MarketDistancePoints(symbol, InpZoneBufferPoints);
            double volume_bin_points =
              MarketDistancePoints(symbol, InpVolumeBinPoints);
            if(minimum_swing_points < 0.0 || equal_swing_points < 0.0 ||
              zone_buffer_points < 0.0 || volume_bin_points < 0.0)
              continue;
            int engine_index = symbol_slot * KBLX_FRAME_COUNT + frame;
            bool structure_ok = g_structure_engines[engine_index].Update(
              g_market_data, symbol, timeframe,
              MathMin(InpHistoryBars, InpSwingLookback),
              InpSwingStrength, InpMaximumSwingAgeBars,
              minimum_swing_points, equal_swing_points,
              InpStructureSwings, structure);
            if(structure_ok)
            {
              if(!InpUseStructureTrend)
                 structure.trend = KBLX_TREND_NEUTRAL;
              g_frame_structures[symbol_slot][frame] = structure;
            }
            else
            {
              structure.valid = false;
              structure.trend = KBLX_TREND_NEUTRAL;
              structure.hh_count = 0;
              structure.hl_count = 0;
              structure.lh_count = 0;
              structure.ll_count = 0;
              structure.latest_high = 0.0;
              structure.latest_low = 0.0;
              structure.latest_high_time = 0;
              structure.latest_low_time = 0;
              g_frame_structures[symbol_slot][frame] = structure;
            }
            bool context_ok = g_context_engine.Build(g_market_data, symbol, timeframe, structure,
              InpContextLookbackBars, zone_buffer_points, volume_bin_points,
              g_frame_contexts[symbol_slot][frame]);
            if(!context_ok)
            {
              g_frame_contexts[symbol_slot][frame].valid = false;
              g_frame_contexts[symbol_slot][frame].demand.valid = false;
              g_frame_contexts[symbol_slot][frame].supply.valid = false;
              g_frame_contexts[symbol_slot][frame].volume_zone.valid = false;
            }
            g_frame_bar_time[symbol_slot][frame] = iTime(symbol, timeframe, 0);
            g_frame_retry_time[symbol_slot][frame] = TimeCurrent();
         }
      }

      if(symbol == _Symbol)
      {
         for(int frame = 0; frame < KBLX_FRAME_COUNT; frame++)
            g_dashboard.DrawFrameContext(
               InpDashboardEnabled && FrameScanned(frame), symbol,
               FrameTimeframe(frame), frame,
               g_frame_structures[symbol_slot][frame],
               g_frame_contexts[symbol_slot][frame]);
         int chart_frame = 2;
         for(int frame = 0; frame < KBLX_FRAME_COUNT; frame++)
            if(FrameTimeframe(frame) == (ENUM_TIMEFRAMES)_Period &&
              g_frame_structures[symbol_slot][frame].valid)
              chart_frame = frame;
         g_chart_structure = g_frame_structures[symbol_slot][chart_frame];
         KBLXSwingPoint chart_swings[];
         ArrayResize(chart_swings, 32);
         int count = g_structure_engines[symbol_slot * KBLX_FRAME_COUNT + chart_frame].GetSwings(chart_swings, 20);
         g_dashboard.DrawSwings(InpDrawSwings, chart_swings, count);
      }
      if(!InpAllowTrading || !InpEnableReversals)
         continue;

      for(int frame = 0; frame < KBLX_FRAME_COUNT; frame++)
      {
         if(!FrameTrades(frame) || !g_frame_structures[symbol_slot][frame].valid)
            continue;
         ENUM_TIMEFRAMES timeframe = FrameTimeframe(frame);
         KBLXStructure structure = g_frame_structures[symbol_slot][frame];
         KBLXSignal signal;
         signal.valid = false;
         double retrace_tolerance =
            MarketDistancePoints(symbol, InpRetraceATolerancePoints);
         double sweep_tolerance =
            MarketDistancePoints(symbol, InpLiquiditySweepTolerancePoints);
         double trendline_width =
            MarketDistancePoints(symbol, InpTrendlineWidthPoints);
         if(retrace_tolerance < 0.0 || sweep_tolerance < 0.0 ||
            trendline_width < 0.0)
            continue;
         if(!g_signal_engine.Analyze(
              g_market_data, g_structure_engines[symbol_slot * KBLX_FRAME_COUNT + frame],
              symbol, timeframe, structure, InpHistoryBars, InpBreakSelection,
              InpRequireLiquiditySweep, sweep_tolerance,
              InpEnableRetraceB, InpEnableRetraceC, InpEnableRetraceD,
              InpRetraceMode, InpRequiredRetracements,
              retrace_tolerance,
              InpFibRatio, InpFibUseWicks, InpRequirePrimaryGate,
              InpPrimaryGateMode,
              InpSetupMaximumAgeBars, InpZoneExpiryBars, InpEngulfBodyOnly,
              InpSecondaryFibRatio, InpTrendlineEnabled, trendline_width,
              false, structure, false, FrameWeight(frame), signal))
            continue;
         if(FrameNeedsHigherDemand(frame) && !FrameIndependent(frame))
         {
            MqlTick tick;
            double market_price = 0.0;
            if(SymbolInfoTick(symbol, tick))
              market_price = (signal.direction == KBLX_DIRECTION_BUY
                              ? tick.ask : tick.bid);
            if(market_price <= 0.0 ||
              !PriceAtHigherZone(symbol_slot, frame, market_price,
                                 signal.direction))
              continue;
         }
         if(!MTFTrendPasses(symbol_slot, frame, signal.direction) ||
            signal.score < InpMinimumConfluenceScore)
            continue;
         if(InpRequireVolumeConfluence &&
            (!g_frame_contexts[symbol_slot][frame].volume_zone.valid ||
            signal.entry < g_frame_contexts[symbol_slot][frame].volume_zone.low ||
            signal.entry > g_frame_contexts[symbol_slot][frame].volume_zone.high))
            continue;
         if(!g_filters.IsAllowed(
              symbol, InpSessionFilterEnabled, InpSessionStartHour,
              InpSessionEndHour, InpTradeMonday, InpTradeTuesday,
              InpTradeWednesday, InpTradeThursday, InpTradeFriday,
              InpTradeSaturday, InpTradeSunday, InpMaximumSpreadPoints,
              InpNewsFilterEnabled, InpNewsMinutesBefore, InpNewsMinutesAfter,
              InpNewsMinimumImportance))
            continue;
         if(!g_filters.IsProfitLossAllowed(
              InpMagicNumber, InpProfitTargetEnabled, InpProfitTargetPercent,
              InpLossLimitEnabled, InpLossLimitPercent, InpLimitPeriod,
              InpLimitMinutes, InpLimitHours, InpSessionStartHour,
              InpSessionEndHour, InpSessionProfitLimitMoney,
              InpSessionLossLimitMoney))
            continue;
         if(InpPerformanceFilterEnabled &&
            !g_trade_memory.AllowsSetup(
              symbol, InpMagicNumber,
              signal.direction == KBLX_DIRECTION_BUY ? 'B' : 'S',
              (int)timeframe, InpPerformanceMinimumSample,
              InpPerformanceMinimumWinRate))
            continue;
         if(InpPreventDuplicateSetups && g_executor.HasDuplicate(signal.id))
            continue;
         double stop = 0.0, target = 0.0, volume = 0.0;
         bool placed = g_executor.Execute(
            signal, g_market_data, g_risk_manager, InpSizingMode,
            InpFixedLots, InpRiskPercent, InpRiskMoney, InpStopMode,
            InpStopDistancePoints, InpStopBufferPoints,
            trade_plan.target_r[trade_plan.count - 1],
            InpManualStopPrice, InpStopATRPeriod, InpStopATRMultiplier,
            InpTakeProfitMode, InpManualTakeProfitPrice, InpFibonacciExtension,
            InpStopDistanceUnits, InpExecutionMode, InpPreventDuplicateSetups,
            stop, target, volume);
         if(placed)
         {
            any_signal = true;
            g_status = "Order accepted: " + signal.id;
            if(symbol == _Symbol)
              g_dashboard.DrawSignal(signal, g_frame_contexts[symbol_slot][frame],
                                     stop, target);
            if(InpAlertsEnabled)
              g_alerts.NotifySignal(signal, stop, target, volume,
                                    InpPushNotificationsEnabled);
            if(!InpAllowConcurrentSignals)
              break;
         }
         else if(InpDebug)
            PrintFormat("KBLX no executable setup for %s on %s",
                       symbol, EnumToString(timeframe));
      }
      if(!InpAllowConcurrentSignals && any_signal)
         break;
   }
   if(!any_signal)
      g_status = (InpAllowTrading ? "Scanning structure / waiting for confirmation" : "Trading disabled");
   g_dashboard.Draw(InpDashboardEnabled, _Symbol, (ENUM_TIMEFRAMES)_Period,
                   g_chart_structure, g_status);
}

int OnInit()
{
   if(!ValidateInputs())
   {
      Print("KBLX initialization rejected invalid or incompatible inputs.");
      return INIT_PARAMETERS_INCORRECT;
   }
   string symbols[];
   int symbol_count = BuildSymbolList(symbols);
   if(symbol_count < 1 ||
      ArrayResize(g_structure_engines, symbol_count * KBLX_FRAME_COUNT) !=
      symbol_count * KBLX_FRAME_COUNT)
   {
      Print("KBLX initialization failed: no tradable symbols or engine allocation error.");
      return INIT_FAILED;
   }
   g_executor.Configure(InpMagicNumber, InpMaxPositionsTotal,
                        InpMaxPositionsPerSymbol, InpMaxPendingOrders,
                        InpDeviationPoints);
   g_market_data.SetMaximumCacheAge(InpMaxCacheAgeSeconds);
   g_position_manager.Configure(InpMagicNumber);
   g_alerts.Configure(InpTelegramEnabled, InpTelegramBotToken, InpTelegramChatId);
   g_chart_structure.valid = false;
   EventSetTimer(InpScanSeconds);
   g_status = "Ready";
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   g_dashboard.Cleanup();
   ArrayFree(g_structure_engines);
}

void ManagePositions()
{
   KBLXTradePlan plan;
   BuildTradePlan(plan);
   g_position_manager.Manage(
      InpBreakEvenEnabled, InpBreakEvenTriggerR, InpBreakEvenOffsetPoints,
      InpTrailingEnabled, InpTrailingStartPoints, InpTrailingDistancePoints,
      InpTrailingStepPoints, InpManagementDistanceUnits, plan, g_risk_manager);
}

void OnTick()
{
   ManagePositions();
   if(InpScanEveryTick)
   {
      g_last_scan = TimeCurrent();
      ScanMarkets();
   }
}

void OnTimer()
{
   ManagePositions();
   datetime now = TimeCurrent();
   if(!InpScanEveryTick &&
      (g_last_scan == 0 || now - g_last_scan >= InpScanSeconds))
   {
      g_last_scan = now;
      ScanMarkets();
   }
}

void OnTradeTransaction(const MqlTradeTransaction &transaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(transaction.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      g_filters.InvalidatePnL();
      g_trade_memory.RecordDeal(transaction.deal, InpTradeMemoryEnabled, InpMagicNumber);
   }
}
