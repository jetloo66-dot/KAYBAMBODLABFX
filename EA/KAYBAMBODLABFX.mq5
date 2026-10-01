#property copyright "KAYBAMBODLABFX"
#property version   "1.00"
#property strict

#include "Core\Types.mqh"
#include "Core\MarketData.mqh"
#include "Market\StructureEngine.mqh"
#include "Strategy\SignalEngine.mqh"
#include "Filters\TradingFilters.mqh"
#include "Risk\RiskManager.mqh"
#include "Execution\TradeExecutor.mqh"
#include "Management\PositionManager.mqh"
#include "Alerts\AlertEngine.mqh"
#include "UI\Dashboard.mqh"
#include "Analytics\TradeMemory.mqh"

input group "=== GENERAL ==="
input bool InpAllowTrading = true;
input long InpMagicNumber = 316316316;
input int InpScanSeconds = 5;

input group "=== SYMBOLS ==="
input string InpSymbols = "";
input bool InpTradeChartSymbol = true;

input group "=== TIMEFRAMES ==="
input ENUM_TIMEFRAMES InpPrimaryTF = PERIOD_H1;
input ENUM_TIMEFRAMES InpConfirmTF = PERIOD_M15;
input ENUM_TIMEFRAMES InpConfirmTF2 = PERIOD_CURRENT;
input ENUM_TIMEFRAMES InpConfirmTF3 = PERIOD_CURRENT;

input group "=== DATA ==="
input int InpHistoryBars = 500;
input int InpMaxCacheAgeSeconds = 5;

input group "=== SWING ==="
input int InpSwingStrength = 2;
input int InpSwingLookback = 200;
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
input KBLXBreakConfirmation InpBreakConfirmation = KBLX_CLOSE_ONLY;
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

input group "=== RETRACEMENT COMBINATION ==="
input KBLXRetracementMode InpRetraceMode = KBLX_RETRACE_ANY;
input int InpRequiredRetracements = 1;

input group "=== PRIMARY TIMEFRAME GATE ==="
input bool InpRequirePrimaryGate = false;
input KBLXPrimaryGateMode InpPrimaryGateMode = KBLX_PRIMARY_GATE_ANY;

input group "=== ZONES ==="
input double InpZoneBufferPoints = 5.0;
input int InpZoneExpiryBars = 100;

input group "=== FIBONACCI ==="
input double InpSecondaryFibRatio = 0.5;

input group "=== TRENDLINE ==="
input bool InpTrendlineEnabled = false;
input double InpTrendlineWidthPoints = 10.0;

input group "=== CONFLUENCE ==="
input double InpMinimumConfluenceScore = 0.0;

input group "=== MTF MAPPING ==="
input KBLXMTFMode InpMTFMode = KBLX_MTF_SINGLE;
input int InpMinimumConfirmations = 1;
input double InpConfirmationWeight = 1.0;
input double InpConfirmationWeight2 = 1.0;
input double InpConfirmationWeight3 = 1.0;

input group "=== EXECUTION ==="
input KBLXExecutionMode InpExecutionMode = KBLX_MARKET_ONLY;
input ulong InpDeviationPoints = 10;

input group "=== DUPLICATE PREVENTION ==="
input bool InpPreventDuplicateSetups = true;

input group "=== RISK SIZING ==="
input KBLXSizingMode InpSizingMode = KBLX_RISK_PERCENT;
input double InpFixedLots = 0.01;
input double InpRiskPercent = 0.5;
input double InpRiskMoney = 50.0;

input group "=== POSITION LIMITS ==="
input int InpMaxPositionsTotal = 3;
input int InpMaxPositionsPerSymbol = 3;
input int InpMaxPendingOrders = 3;

input group "=== STOP LOSS ==="
input KBLXStopMode InpStopMode = KBLX_SL_ZONE_BASED;
input double InpStopDistancePoints = 100.0;
input double InpStopBufferPoints = 10.0;
input double InpManualStopPrice = 0.0;
input int InpStopATRPeriod = 14;
input double InpStopATRMultiplier = 2.0;

input group "=== TAKE PROFIT ==="
input KBLXTakeProfitMode InpTakeProfitMode = KBLX_TP_RR;
input double InpRiskReward = 3.0;
input int InpTakeProfitCount = 1;
input double InpManualTakeProfitPrice = 0.0;
input double InpFibonacciExtension = 1.618;

input group "=== PARTIAL PROFITS ==="
input double InpPartialClosePercent = 0.0;

input group "=== BREAK EVEN / TRAILING ==="
input bool InpBreakEvenEnabled = true;
input double InpBreakEvenTriggerR = 1.0;
input double InpBreakEvenOffsetPoints = 0.0;
input bool InpTrailingEnabled = false;
input double InpTrailingStartPoints = 100.0;
input double InpTrailingDistancePoints = 50.0;
input double InpTrailingStepPoints = 10.0;

input group "=== PROFIT / LOSS LIMITS ==="
input double InpSessionProfitLimitMoney = 0.0;
input double InpSessionLossLimitMoney = 0.0;

input group "=== NEWS / SESSION / SPREAD ==="
input bool InpNewsFilterEnabled = false;
input int InpNewsMinutesBefore = 30;
input int InpNewsMinutesAfter = 30;
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
CKBLXStructureEngine g_primary_structure_engine;
CKBLXStructureEngine g_confirm_structure_engine_1;
CKBLXStructureEngine g_confirm_structure_engine_2;
CKBLXStructureEngine g_confirm_structure_engine_3;
CKBLXSignalEngine g_signal_engine;
CKBLXTradingFilters g_filters;
CKBLXRiskManager g_risk_manager;
CKBLXTradeExecutor g_executor;
CKBLXPositionManager g_position_manager;
CKBLXAlertEngine g_alerts;
CKBLXDashboard g_dashboard;
CKBLXTradeMemory g_trade_memory;
KBLXStructure g_chart_structure;
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
      InpPrimaryTF == InpConfirmTF ||
      PeriodSeconds(InpPrimaryTF) <= 0 || PeriodSeconds(InpConfirmTF) <= 0 ||
      InpRequiredRetracements < 1 || InpRequiredRetracements > 4 ||
      InpMinimumConfirmations < 1 || InpMinimumConfirmations > 3 ||
      InpMaxPositionsTotal < 1 ||
      InpMaxPositionsPerSymbol < 1 || InpMaxPendingOrders < 0 ||
      InpRiskReward <= 0.0 || InpTakeProfitCount < 1 || InpTakeProfitCount > 5 ||
      InpStopATRPeriod < 1 || InpStopATRMultiplier <= 0.0 ||
      InpFibonacciExtension <= 0.0 ||
      InpPartialClosePercent < 0.0 || InpPartialClosePercent > 100.0 ||
      InpPartialClosePercent * MathMax(0, InpTakeProfitCount - 1) > 100.0 ||
      InpMaxCacheAgeSeconds < 0 || InpZoneExpiryBars < 1 ||
      InpFibRatio <= 0.0 || InpFibRatio >= 1.0 ||
      InpSecondaryFibRatio <= 0.0 || InpSecondaryFibRatio >= 1.0 ||
      InpRiskPercent < 0.0 || InpRiskMoney < 0.0 ||
      InpFixedLots <= 0.0 || InpMinimumConfluenceScore < 0.0 ||
      InpRetraceATolerancePoints < 0.0 || InpZoneBufferPoints < 0.0 ||
      InpMinimumSwingDistancePoints < 0.0 || InpEqualSwingTolerancePoints < 0.0 ||
      InpLiquiditySweepTolerancePoints < 0.0 || InpStopDistancePoints < 0.0 ||
      InpStopBufferPoints < 0.0 || InpMaximumSpreadPoints < 0.0 ||
      InpNewsMinutesBefore < 0 || InpNewsMinutesAfter < 0 ||
      InpSessionStartHour < 0 || InpSessionStartHour > 23 ||
      InpSessionEndHour < 0 || InpSessionEndHour > 23 ||
      InpSessionProfitLimitMoney < 0.0 || InpSessionLossLimitMoney < 0.0)
      return false;
   int enabled_retracements = (InpEnableRetraceA ? 1 : 0) +
                              (InpEnableRetraceB ? 1 : 0) +
                              (InpEnableRetraceC ? 1 : 0) +
                              (InpEnableRetraceD ? 1 : 0);
   if(enabled_retracements == 0 ||
      InpRequiredRetracements > enabled_retracements)
      return false;
   if(InpConfirmationWeight < 0.0 || InpConfirmationWeight2 < 0.0 ||
      InpConfirmationWeight3 < 0.0 ||
      (InpPerformanceFilterEnabled &&
      (InpPerformanceMinimumSample < 1 || InpPerformanceMinimumWinRate < 0.0 ||
       InpPerformanceMinimumWinRate > 100.0)))
      return false;
   ENUM_TIMEFRAMES confirmation_tfs[3];
   confirmation_tfs[0] = InpConfirmTF;
   confirmation_tfs[1] = InpConfirmTF2;
   confirmation_tfs[2] = InpConfirmTF3;
   int enabled_confirmations = 0;
   for(int i = 0; i < 3; i++)
   {
      if(confirmation_tfs[i] == PERIOD_CURRENT)
         continue;
      if(confirmation_tfs[i] == InpPrimaryTF || PeriodSeconds(confirmation_tfs[i]) <= 0)
         return false;
      for(int j = 0; j < i; j++)
         if(confirmation_tfs[j] == confirmation_tfs[i])
            return false;
      enabled_confirmations++;
   }
   if(InpMTFMode != KBLX_MTF_SINGLE &&
      InpMinimumConfirmations > enabled_confirmations)
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
   for(int i = 0; i < count && ArraySize(symbols) < 32; i++)
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
      if(!found && ArraySize(symbols) < 32)
      {
         int size = ArraySize(symbols);
         ArrayResize(symbols, size + 1);
         symbols[size] = _Symbol;
      }
   }
   return ArraySize(symbols);
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
   for(int i = 0; i < symbol_count; i++)
   {
      string symbol = symbols[i];
      if(!SymbolSelect(symbol, true))
         continue;
      bool primary_bar = g_market_data.IsNewBar(symbol, InpPrimaryTF);
      bool confirm_bar = g_market_data.IsNewBar(symbol, InpConfirmTF);
      if(InpConfirmTF2 != PERIOD_CURRENT)
         confirm_bar = g_market_data.IsNewBar(symbol, InpConfirmTF2) || confirm_bar;
      if(InpConfirmTF3 != PERIOD_CURRENT)
         confirm_bar = g_market_data.IsNewBar(symbol, InpConfirmTF3) || confirm_bar;
      if(!primary_bar && !confirm_bar &&
         InpBreakConfirmation == KBLX_CLOSE_ONLY)
         continue;

      KBLXStructure primary_structure, confirm_structure_1, confirm_structure_2, confirm_structure_3;
      bool primary_ok = g_primary_structure_engine.Update(
         g_market_data, symbol, InpPrimaryTF, InpHistoryBars, InpSwingStrength,
         InpMaximumSwingAgeBars, InpMinimumSwingDistancePoints,
         InpEqualSwingTolerancePoints, InpStructureSwings, primary_structure);
      bool confirm_ok = g_confirm_structure_engine_1.Update(
         g_market_data, symbol, InpConfirmTF, InpHistoryBars, InpSwingStrength,
         InpMaximumSwingAgeBars, InpMinimumSwingDistancePoints,
         InpEqualSwingTolerancePoints, InpStructureSwings, confirm_structure_1);
      bool confirm_ok_2 = (InpConfirmTF2 == PERIOD_CURRENT);
      bool confirm_ok_3 = (InpConfirmTF3 == PERIOD_CURRENT);
      if(InpConfirmTF2 != PERIOD_CURRENT)
         confirm_ok_2 = g_confirm_structure_engine_2.Update(
            g_market_data, symbol, InpConfirmTF2, InpHistoryBars, InpSwingStrength,
            InpMaximumSwingAgeBars, InpMinimumSwingDistancePoints,
            InpEqualSwingTolerancePoints, InpStructureSwings, confirm_structure_2);
      if(InpConfirmTF3 != PERIOD_CURRENT)
         confirm_ok_3 = g_confirm_structure_engine_3.Update(
            g_market_data, symbol, InpConfirmTF3, InpHistoryBars, InpSwingStrength,
            InpMaximumSwingAgeBars, InpMinimumSwingDistancePoints,
            InpEqualSwingTolerancePoints, InpStructureSwings, confirm_structure_3);
      if(!primary_ok || !confirm_ok || !confirm_ok_2 || !confirm_ok_3)
      {
         if(InpDebug)
            PrintFormat("KBLX waiting for sufficient confirmed rate history: %s", symbol);
         continue;
      }
      if(!InpUseStructureTrend)
      {
         primary_structure.trend = KBLX_TREND_NEUTRAL;
         confirm_structure_1.trend = KBLX_TREND_NEUTRAL;
         confirm_structure_2.trend = KBLX_TREND_NEUTRAL;
         confirm_structure_3.trend = KBLX_TREND_NEUTRAL;
      }
      if(symbol == _Symbol)
      {
         g_chart_structure = primary_structure;
         KBLXSwingPoint chart_swings[];
         ArrayResize(chart_swings, 32);
         int chart_swing_count = g_primary_structure_engine.GetSwings(chart_swings, 20);
         g_dashboard.DrawSwings(InpDrawSwings, chart_swings, chart_swing_count);
      }

      if(!InpAllowTrading || !InpEnableReversals)
         continue;
      KBLXSignal signal, candidate;
      int confirmation_passes = 0;
      int enabled_confirmations = 1 + (InpConfirmTF2 != PERIOD_CURRENT ? 1 : 0) +
                                  (InpConfirmTF3 != PERIOD_CURRENT ? 1 : 0);
      signal.valid = false;
      for(int confirmation_index = 0; confirmation_index < 3; confirmation_index++)
      {
         ENUM_TIMEFRAMES confirm_tf = (confirmation_index == 0 ? InpConfirmTF :
                                       confirmation_index == 1 ? InpConfirmTF2 : InpConfirmTF3);
         if(confirm_tf == PERIOD_CURRENT)
            continue;
         KBLXStructure confirm_structure;
         if(confirmation_index == 0) confirm_structure = confirm_structure_1;
         else if(confirmation_index == 1) confirm_structure = confirm_structure_2;
         else confirm_structure = confirm_structure_3;
         double weight = (confirmation_index == 0 ? InpConfirmationWeight :
                          confirmation_index == 1 ? InpConfirmationWeight2 :
                          InpConfirmationWeight3);
         if(!g_signal_engine.Analyze(
               g_market_data, g_primary_structure_engine, symbol, InpPrimaryTF,
               confirm_tf, primary_structure, confirm_structure, InpHistoryBars,
               InpBreakConfirmation, InpBreakSelection, InpEnableRetraceA,
               InpEnableRetraceB, InpEnableRetraceC, InpEnableRetraceD,
               InpRetraceMode, InpRequiredRetracements,
               MathMax(InpRetraceATolerancePoints, InpZoneBufferPoints),
               InpFibRatio,
               InpRequirePrimaryGate, InpPrimaryGateMode, InpSecondaryFibRatio,
               InpRequireLiquiditySweep, InpLiquiditySweepTolerancePoints,
               InpSetupMaximumAgeBars, InpEngulfBodyOnly, InpFibUseWicks,
               InpZoneExpiryBars, InpTrendlineEnabled, InpTrendlineWidthPoints,
               weight, candidate))
            continue;
         if(!signal.valid)
         {
            signal = candidate;
            signal.score = 0.0;
         }
         signal.score += candidate.score;
         confirmation_passes++;
      }
      bool enough_confirmations = (InpMTFMode == KBLX_MTF_SINGLE
                                   ? confirmation_passes >= 1
                                   : InpMTFMode == KBLX_MTF_ALL
                                     ? confirmation_passes == enabled_confirmations
                                     : confirmation_passes >= InpMinimumConfirmations);
      if(!signal.valid || !enough_confirmations)
         continue;
      if(signal.score < InpMinimumConfluenceScore)
         continue;
      if(!g_filters.IsAllowed(
            symbol, InpSessionFilterEnabled, InpSessionStartHour,
            InpSessionEndHour, InpTradeMonday, InpTradeTuesday,
            InpTradeWednesday, InpTradeThursday, InpTradeFriday,
            InpTradeSaturday, InpTradeSunday, InpMaximumSpreadPoints,
            InpNewsFilterEnabled, InpNewsMinutesBefore, InpNewsMinutesAfter))
         continue;
      if(!g_filters.IsDailyPnLAllowed(InpMagicNumber,
                                     InpSessionProfitLimitMoney,
                                     InpSessionLossLimitMoney))
         continue;
      if(InpPerformanceFilterEnabled &&
         !g_trade_memory.AllowsSymbol(symbol, InpMagicNumber,
                                      InpPerformanceMinimumSample,
                                      InpPerformanceMinimumWinRate))
         continue;
      if(InpPreventDuplicateSetups && g_executor.HasDuplicate(signal.id))
         continue;
      double stop = 0.0, target = 0.0, volume = 0.0;
      bool placed = g_executor.Execute(
         signal, g_market_data, g_risk_manager, InpSizingMode,
         InpFixedLots, InpRiskPercent, InpRiskMoney, InpStopMode,
         InpStopDistancePoints, InpStopBufferPoints, InpRiskReward,
         InpManualStopPrice, InpStopATRPeriod, InpStopATRMultiplier,
         InpTakeProfitMode, InpManualTakeProfitPrice, InpFibonacciExtension,
         InpExecutionMode, InpPreventDuplicateSetups,
         stop, target, volume);
      if(placed)
      {
         any_signal = true;
         g_status = "Order accepted: " + signal.id;
         if(InpAlertsEnabled)
            g_alerts.NotifySignal(signal, stop, target, volume,
                                  InpPushNotificationsEnabled);
      }
      else if(InpDebug)
         PrintFormat("KBLX no executable setup for %s on %s",
                     symbol, EnumToString(InpPrimaryTF));
   }
   if(!any_signal)
      g_status = (InpAllowTrading ? "Scanning structure / waiting for confirmation" : "Trading disabled");
   g_dashboard.Draw(InpDashboardEnabled, _Symbol, InpPrimaryTF,
                    g_chart_structure, g_status);
}

int OnInit()
{
   if(!ValidateInputs())
   {
      Print("KBLX initialization rejected invalid or incompatible inputs.");
      return INIT_PARAMETERS_INCORRECT;
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
}

void ManagePositions()
{
   g_position_manager.Manage(
      InpBreakEvenEnabled, InpBreakEvenTriggerR, InpBreakEvenOffsetPoints,
      InpTrailingEnabled, InpTrailingStartPoints, InpTrailingDistancePoints,
      InpTrailingStepPoints, InpTakeProfitCount, InpPartialClosePercent);
}

void OnTick()
{
   ManagePositions();
}

void OnTimer()
{
   ManagePositions();
   datetime now = TimeCurrent();
   if(g_last_scan == 0 || now - g_last_scan >= InpScanSeconds)
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
      g_trade_memory.RecordDeal(transaction.deal, InpTradeMemoryEnabled, InpMagicNumber);
}
