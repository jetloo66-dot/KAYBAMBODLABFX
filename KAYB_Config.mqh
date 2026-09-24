#property strict

input group "=== CORE ==="
input int InpMagicNumber = 24092026;
input bool InpAllowTrading = true;
input bool InpScanEveryTick = true;
input string InpObjectPrefix = "KAYB_MT5";

input group "=== WORKFLOW 1: D1 -> lower ==="
input bool InpWF1Enabled = true;
input ENUM_TIMEFRAMES InpWF1AnalysisTF = PERIOD_D1;
input ENUM_TIMEFRAMES InpWF1ConfirmTF = PERIOD_H4;

input group "=== WORKFLOW 2: H4 -> lower ==="
input bool InpWF2Enabled = true;
input ENUM_TIMEFRAMES InpWF2AnalysisTF = PERIOD_H4;
input ENUM_TIMEFRAMES InpWF2ConfirmTF = PERIOD_H1;

input group "=== WORKFLOW 3: H1 -> lower ==="
input bool InpWF3Enabled = true;
input ENUM_TIMEFRAMES InpWF3AnalysisTF = PERIOD_H1;
input ENUM_TIMEFRAMES InpWF3ConfirmTF = PERIOD_M30;

input group "=== WORKFLOW 4: M30 -> lower ==="
input bool InpWF4Enabled = true;
input ENUM_TIMEFRAMES InpWF4AnalysisTF = PERIOD_M30;
input ENUM_TIMEFRAMES InpWF4ConfirmTF = PERIOD_M15;

input group "=== WORKFLOW 5: M15 -> lower ==="
input bool InpWF5Enabled = true;
input ENUM_TIMEFRAMES InpWF5AnalysisTF = PERIOD_M15;
input ENUM_TIMEFRAMES InpWF5ConfirmTF = PERIOD_M5;

input group "=== WORKFLOW 6: M5 -> M5 ==="
input bool InpWF6Enabled = true;
input ENUM_TIMEFRAMES InpWF6AnalysisTF = PERIOD_M5;
input ENUM_TIMEFRAMES InpWF6ConfirmTF = PERIOD_M5;

input group "=== STRUCTURE / BOS / CHOCH ==="
input int InpSwingLookback = 2;
input int InpStructureLookbackBars = 350;
input bool InpCloseBreakRequired = true;
input double InpSwingToleranceUnits = 1.0;

input group "=== REVERSAL FILTERS ==="
input bool InpFilterA_VolumeNode = true;
input bool InpFilterB_EngulfedBullBear = true;
input bool InpFilterC_LastCandleBeforeBreak = true;
input bool InpFilterD_FibRetracement = true;
input bool InpFilterD_UseFib618 = true;
input ENUM_KAYBFilterMode InpFilterCombinationMode = KAYB_FILTER_ANY;
input int InpSetupExpiryBars = 25;

input group "=== EXECUTION & RISK ==="
input bool InpUsePendingOrders = true;
input bool InpEnableMarketOrders = true;
input bool InpEnablePendingOrders = true;
input double InpLotSize = 0.01;
input bool InpUseRiskPercent = false;
input double InpRiskPercent = 1.0;
input int InpMaxPositions = 1;
input int InpMaxPendingOrders = 1;
input ENUM_KAYBDistanceMode InpDistanceMode = KAYB_DIST_AUTO;
input double InpStopBufferUnits = 10.0;
input double InpRR = 3.0;
input double InpManualSLUnits = 0.0;
input double InpManualTPUnits = 0.0;
input int InpMaxSpreadPoints = 60;
input int InpDeviationPoints = 20;

input group "=== TAKE PROFIT MANAGEMENT ==="
input bool InpTP1Enabled = true;
input double InpTP1_R = 1.0;
input double InpTP1_PartialPercent = 25.0;
input bool InpTP2Enabled = true;
input double InpTP2_R = 1.5;
input double InpTP2_PartialPercent = 25.0;
input bool InpTP3Enabled = true;
input double InpTP3_R = 2.0;
input double InpTP3_PartialPercent = 20.0;
input bool InpTP4Enabled = true;
input double InpTP4_R = 2.5;
input double InpTP4_PartialPercent = 15.0;
input bool InpTP5Enabled = true;
input double InpTP5_R = 3.0;
input double InpTP5_PartialPercent = 15.0;
input ENUM_KAYBPartialTrigger InpPartialTrigger = KAYB_PARTIAL_AT_1R;
input bool InpUseBreakEven = true;
input double InpBreakEvenTriggerR = 1.0;
input bool InpUseTrailing = true;
input double InpTrailActivationR = 1.5;
input double InpTrailDistanceUnits = 12.0;
input double InpTrailStepUnits = 3.0;

input group "=== NEWS & LIMITS ==="
input bool InpUseNewsFilter = false;
input bool InpNewsBlockHigh = true;
input bool InpNewsBlockMedium = true;
input string InpNewsCurrencies = "USD,EUR,GBP,JPY,XAU,BTC";
input int InpNewsPreMinutes = 30;
input int InpNewsPostMinutes = 30;
input bool InpUseSessionFilter = false;
input int InpSessionStartHour = 0;
input int InpSessionEndHour = 23;
input ENUM_KAYBLimitMode InpProfitTargetMode = KAYB_LIMIT_NONE;
input ENUM_KAYBLimitMode InpLossLimitMode = KAYB_LIMIT_DAY;
input ENUM_KAYBValueMode InpLimitValueMode = KAYB_VALUE_PERCENT;
input double InpProfitTargetValue = 100.0;
input double InpLossLimitValue = 5.0;
input bool InpManageExistingWhenBlocked = true;

input group "=== ALERTS / DASHBOARD ==="
input bool InpAlertTerminal = true;
input bool InpAlertPush = false;
input bool InpAlertEmail = false;
input bool InpAlertTelegram = false;
input string InpTelegramBotToken = "";
input string InpTelegramChatId = "";
input int InpAlertMinSeconds = 10;
input bool InpDashboardEnabled = true;

input group "=== TRADE MEMORY / STATS ==="
input bool InpTradeMemoryEnabled = true;
input int InpTradeMemoryMaxRows = 1500;
input bool InpTradeMemoryResetOnInit = false;
input bool InpUseMemoryScoreFilter = false;
input int InpMemoryMinSample = 15;
input double InpMemoryScoreThreshold = 0.52;
