//+------------------------------------------------------------------+
//|                                        ModularTradingBot.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Include standard libraries
#include <Trade\Trade.mqh>

// Include custom manager modules
#include "Structs_Version1.mqh"
#include "ConfigurationManager.mqh"
#include "GlobalVarsManager.mqh"
#include "LogManager_Version1.mqh"
#include "MultiSymbolScanner.mqh"
#include "NewsFilterManager.mqh"
#include "PriceActionManager.mqh"
#include "TelegramManager.mqh"
#include "RiskManager.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input group "=== TIMEFRAME SETTINGS ==="
input ENUM_TIMEFRAMES AnalysisTimeframe1 = PERIOD_H1;        // Primary Analysis Timeframe
input ENUM_TIMEFRAMES AnalysisTimeframe2 = PERIOD_H4;        // Secondary Analysis Timeframe  
input ENUM_TIMEFRAMES AnalysisTimeframe3 = PERIOD_D1;        // Tertiary Analysis Timeframe
input ENUM_TIMEFRAMES ExecutionTimeframe = PERIOD_M5;        // Execution Timeframe

input group "=== SCAN SETTINGS ==="
input int CandlesToScan = 100;                               // Candles to scan for levels
input int PatternScanCandles = 20;                          // Candles to scan for patterns
input int ScanIntervalMinutes = 5;                          // Chart scan interval (minutes)

input group "=== LEVEL DETECTION ==="
input int MaxLevelsToStore = 10;                            // Maximum levels to store per type
input double LevelProximityPips = 5.0;                      // Proximity to levels (pips)
input int SwingStrength = 5;                                // Swing detection strength

input group "=== TRADE SETTINGS ==="
input double LotSize = 0.01;                                // Lot Size
input double StopLossPips = 15.0;                           // Stop Loss (pips)
input double TakeProfitPips = 50.0;                         // Take Profit (pips)
input bool UseTrailingStop = true;                          // Use Trailing Stop
input double TrailingStopPips = 10.0;                       // Trailing Stop Distance (pips)
input double TrailingStepPips = 5.0;                        // Trailing Step (pips)

input group "=== PATTERN SETTINGS ==="
input double PinBarRatio = 0.6;                             // Pin Bar Body Ratio
input double DojiBodyRatio = 0.1;                           // Doji Body Ratio
input double EngulfingRatio = 1.0;                          // Engulfing Ratio

input group "=== RISK MANAGEMENT ==="
input double MaxRiskPercent = 2.0;                          // Max Risk Per Trade (%)
input int MaxPositions = 1;                                 // Max Open Positions
input double MaxDailyLoss = 10.0;                           // Max Daily Loss (%)

input group "=== NEWS FILTER ==="
input bool UseNewsFilter = true;                            // Enable News Filter
input int NewsFilterMinutes = 30;                           // Minutes to avoid trading before/after news

input group "=== TELEGRAM SETTINGS ==="
input string TelegramBotToken = "";                         // Telegram Bot Token
input string TelegramChatID = "";                           // Telegram Chat ID
input bool SendTelegramNotifications = false;               // Enable Telegram Notifications

input group "=== VISUALIZATION ==="
input bool ShowLevels = true;                               // Show Support/Resistance Levels
input bool ShowFibonacci = true;                            // Show Fibonacci Retracement
input bool ShowZones = true;                                // Show Buy/Sell Zones
input color SupportColor = clrBlue;                         // Support Level Color
input color ResistanceColor = clrRed;                       // Resistance Level Color
input color BuyZoneColor = clrLime;                         // Buy Zone Color
input color SellZoneColor = clrOrange;                      // Sell Zone Color

input group "=== SYSTEM ==="
input int MagicNumber = 123456;                             // Magic Number

//+------------------------------------------------------------------+
//| Global Manager Instances                                         |
//+------------------------------------------------------------------+
CConfigurationManager *configManager;
CGlobalVarsManager *globalVars;
CLogManager *logManager;
CMultiSymbolScanner *marketScanner;
CNewsFilterManager *newsFilter;
CPriceActionManager *priceAction;
CTelegramManager *telegram;
CRiskManager *riskManager;
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize managers
    configManager = new CConfigurationManager();
    globalVars = new CGlobalVarsManager();
    logManager = new CLogManager();
    marketScanner = new CMultiSymbolScanner();
    newsFilter = new CNewsFilterManager();
    priceAction = new CPriceActionManager();
    telegram = new CTelegramManager();
    riskManager = new CRiskManager();
    
    // Configure trade object
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(_Symbol);
    
    // Load configuration from inputs
    if(!configManager.LoadFromInputs(
        AnalysisTimeframe1, AnalysisTimeframe2, AnalysisTimeframe3, ExecutionTimeframe,
        CandlesToScan, PatternScanCandles, ScanIntervalMinutes,
        MaxLevelsToStore, LevelProximityPips, SwingStrength,
        LotSize, StopLossPips, TakeProfitPips,
        UseTrailingStop, TrailingStopPips, TrailingStepPips,
        PinBarRatio, DojiBodyRatio, EngulfingRatio,
        MaxRiskPercent, MaxPositions, MaxDailyLoss,
        UseNewsFilter, NewsFilterMinutes,
        TelegramBotToken, TelegramChatID, SendTelegramNotifications,
        ShowLevels, ShowFibonacci, ShowZones,
        SupportColor, ResistanceColor, BuyZoneColor, SellZoneColor,
        MagicNumber
    )) {
        Print("Failed to load configuration");
        return INIT_FAILED;
    }
    
    // Validate settings
    if(!configManager.ValidateSettings()) {
        Print("Configuration validation failed:");
        Print(configManager.GetValidationErrors());
        return INIT_FAILED;
    }
    
    // Initialize global variables manager
    if(!globalVars.Initialize()) {
        Print("Failed to initialize global variables manager");
        return INIT_FAILED;
    }
    
    // Initialize log manager
    if(!logManager.Initialize(LOG_LEVEL_INFO, true, true)) {
        Print("Failed to initialize log manager");
        return INIT_FAILED;
    }
    
    logManager.LogInfo("KAYBAMBODLABFX Modular Trading Bot Starting...", "MAIN");
    
    // Initialize market scanner
    if(!marketScanner.Initialize(ScanIntervalMinutes)) {
        logManager.LogError("Failed to initialize market scanner", "MAIN");
        return INIT_FAILED;
    }
    
    // Add additional symbols if needed (for multi-symbol trading)
    // marketScanner.AddSymbol("EURUSD");
    // marketScanner.AddSymbol("GBPUSD");
    
    // Initialize news filter
    if(!newsFilter.Initialize(NewsFilterMinutes, 2)) {
        logManager.LogWarning("Failed to initialize news filter", "MAIN");
    }
    
    // Initialize price action manager
    if(!priceAction.Initialize(_Symbol, _Period)) {
        logManager.LogError("Failed to initialize price action manager", "MAIN");
        return INIT_FAILED;
    }
    
    priceAction.SetPatternSettings(PinBarRatio, DojiBodyRatio, EngulfingRatio);
    priceAction.SetLevelSettings(LevelProximityPips, SwingStrength);
    
    // Initialize Telegram manager
    if(!telegram.Initialize(TelegramBotToken, TelegramChatID, SendTelegramNotifications)) {
        logManager.LogWarning("Telegram notifications disabled or failed to initialize", "MAIN");
    }
    
    // Initialize risk manager
    if(!riskManager.Initialize(MaxRiskPercent, MaxDailyLoss, 20.0)) {
        logManager.LogError("Failed to initialize risk manager", "MAIN");
        return INIT_FAILED;
    }
    
    riskManager.SetMaxPositions(MaxPositions);
    
    // Log initialization success
    logManager.LogInfo("All managers initialized successfully", "MAIN");
    configManager.PrintSettings();
    
    // Send startup notification
    if(telegram.IsEnabled()) {
        telegram.SendMessage("🤖 *KAYBAMBODLABFX EA Started*\n" +
                           "Symbol: `" + _Symbol + "`\n" +
                           "Timeframe: `" + EnumToString(_Period) + "`\n" +
                           "━━━━━━━━━━━━━━━━");
    }
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Log shutdown
    if(logManager != NULL) {
        logManager.LogInfo("KAYBAMBODLABFX EA Shutting Down. Reason: " + IntegerToString(reason), "MAIN");
        logManager.PrintLogStatistics();
    }
    
    // Send shutdown notification
    if(telegram != NULL && telegram.IsEnabled()) {
        telegram.SendMessage("🛑 *KAYBAMBODLABFX EA Stopped*\n" +
                           "Symbol: `" + _Symbol + "`\n" +
                           "Reason: `" + IntegerToString(reason) + "`\n" +
                           "━━━━━━━━━━━━━━━━");
    }
    
    // Clean up chart objects
    ObjectsDeleteAll(0, "KAYB_");
    
    // Delete manager instances
    if(configManager != NULL) delete configManager;
    if(globalVars != NULL) delete globalVars;
    if(logManager != NULL) delete logManager;
    if(marketScanner != NULL) delete marketScanner;
    if(newsFilter != NULL) delete newsFilter;
    if(priceAction != NULL) delete priceAction;
    if(telegram != NULL) delete telegram;
    if(riskManager != NULL) delete riskManager;
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    // Update global state
    globalVars.UpdateMarketData();
    
    // Check for new bar
    if(globalVars.IsNewBar()) {
        // Perform market analysis on new bar
        PerformMarketAnalysis();
    }
    
    // Manage trailing stops
    if(configManager.GetUseTrailingStop()) {
        ManageTrailingStops();
    }
    
    // Check for trade opportunities
    CheckTradeConditions();
    
    // Process Telegram queue
    if(telegram != NULL && telegram.IsEnabled()) {
        telegram.ProcessQueue();
    }
}

//+------------------------------------------------------------------+
//| Perform comprehensive market analysis                             |
//+------------------------------------------------------------------+
void PerformMarketAnalysis() {
    logManager.LogDebug("Performing market analysis", "ANALYSIS");
    
    // Detect price levels
    priceAction.DetectSupportResistance(configManager.GetCandlesToScan());
    priceAction.DetectSwingPoints(configManager.GetCandlesToScan());
    
    // Analyze market structure
    priceAction.AnalyzeMarketStructure(100);
    
    // Update global trend state
    ENUM_TREND_DIRECTION trend = priceAction.GetTrendDirection();
    globalVars.SetCurrentTrend(trend, 0.8);
    
    // Log analysis results
    logManager.LogDebug("Market structure analyzed. Trend: " + EnumToString(trend), "ANALYSIS");
}

//+------------------------------------------------------------------+
//| Check for trade conditions and execute trades                     |
//+------------------------------------------------------------------+
void CheckTradeConditions() {
    // Check if trading is enabled
    if(!globalVars.IsTradingEnabled()) {
        return;
    }
    
    // Check news filter
    if(configManager.GetUseNewsFilter() && newsFilter.IsNewsTime(_Symbol)) {
        logManager.LogDebug("Trading blocked due to news event", "TRADE");
        return;
    }
    
    // Check risk limits
    if(!riskManager.CanOpenPosition(_Symbol)) {
        logManager.LogDebug("Trading blocked due to risk limits", "TRADE");
        return;
    }
    
    // Get current trend
    ENUM_TREND_DIRECTION trend = globalVars.GetCurrentTrend();
    
    // Analyze patterns
    PatternAnalysis patterns = priceAction.AnalyzePattern(0);
    
    // Check buy conditions in uptrend
    if(trend == TREND_UP && patterns.isValid && patterns.isBullish) {
        if(CheckBuySequence(patterns)) {
            ExecuteBuyTrade(patterns);
        }
    }
    
    // Check sell conditions in downtrend
    if(trend == TREND_DOWN && patterns.isValid && !patterns.isBullish) {
        if(CheckSellSequence(patterns)) {
            ExecuteSellTrade(patterns);
        }
    }
}

//+------------------------------------------------------------------+
//| Check buy sequence patterns                                       |
//+------------------------------------------------------------------+
bool CheckBuySequence(PatternAnalysis &patterns) {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Check if price is near support or swing low
    double nearestSupport = priceAction.FindNearestSupport(currentPrice);
    
    if(nearestSupport > 0) {
        bool nearSupport = priceAction.IsPriceNearLevel(currentPrice, nearestSupport, 
                                                        configManager.GetLevelProximityPips());
        if(nearSupport && patterns.isBullish) {
            logManager.LogInfo("Buy sequence confirmed: Pattern near support", "SIGNAL");
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check sell sequence patterns                                      |
//+------------------------------------------------------------------+
bool CheckSellSequence(PatternAnalysis &patterns) {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Check if price is near resistance or swing high
    double nearestResistance = priceAction.FindNearestResistance(currentPrice);
    
    if(nearestResistance > 0) {
        bool nearResistance = priceAction.IsPriceNearLevel(currentPrice, nearestResistance,
                                                           configManager.GetLevelProximityPips());
        if(nearResistance && !patterns.isBullish) {
            logManager.LogInfo("Sell sequence confirmed: Pattern near resistance", "SIGNAL");
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Execute buy trade                                                 |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(PatternAnalysis &patterns) {
    if(PositionsTotal() >= configManager.GetMaxPositions()) {
        return;
    }
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = price - configManager.GetStopLossPips() * _Point;
    double tp = price + configManager.GetTakeProfitPips() * _Point;
    
    // Calculate lot size based on risk
    double lotSize = riskManager.CalculateLotSize(_Symbol, configManager.GetStopLossPips(), 
                                                   configManager.GetMaxRiskPercent());
    
    if(trade.Buy(lotSize, _Symbol, price, sl, tp, "KAYB Buy Signal")) {
        globalVars.IncrementExecutedTrades();
        
        logManager.LogTrade("BUY", _Symbol, price, lotSize, 
                           "Pattern: " + EnumToString(patterns.pattern));
        
        // Send Telegram notification
        if(telegram.IsEnabled()) {
            telegram.SendTradeNotification("BUY", _Symbol, price, sl, tp, lotSize);
        }
    } else {
        int error = GetLastError();
        logManager.LogError("Failed to open BUY order", "TRADE", error);
    }
}

//+------------------------------------------------------------------+
//| Execute sell trade                                                |
//+------------------------------------------------------------------+
void ExecuteSellTrade(PatternAnalysis &patterns) {
    if(PositionsTotal() >= configManager.GetMaxPositions()) {
        return;
    }
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = price + configManager.GetStopLossPips() * _Point;
    double tp = price - configManager.GetTakeProfitPips() * _Point;
    
    // Calculate lot size based on risk
    double lotSize = riskManager.CalculateLotSize(_Symbol, configManager.GetStopLossPips(),
                                                   configManager.GetMaxRiskPercent());
    
    if(trade.Sell(lotSize, _Symbol, price, sl, tp, "KAYB Sell Signal")) {
        globalVars.IncrementExecutedTrades();
        
        logManager.LogTrade("SELL", _Symbol, price, lotSize,
                           "Pattern: " + EnumToString(patterns.pattern));
        
        // Send Telegram notification
        if(telegram.IsEnabled()) {
            telegram.SendTradeNotification("SELL", _Symbol, price, sl, tp, lotSize);
        }
    } else {
        int error = GetLastError();
        logManager.LogError("Failed to open SELL order", "TRADE", error);
    }
}

//+------------------------------------------------------------------+
//| Manage trailing stops                                             |
//+------------------------------------------------------------------+
void ManageTrailingStops() {
    double trailingStop = configManager.GetTrailingStopPips() * _Point;
    double trailingStep = configManager.GetTrailingStepPips() * _Point;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == configManager.GetMagicNumber()) {
                double currentSL = PositionGetDouble(POSITION_SL);
                double currentPrice;
                double newSL;
                
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                    currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                    newSL = currentPrice - trailingStop;
                    
                    if(newSL > currentSL + trailingStep) {
                        trade.PositionModify(PositionGetTicket(i), newSL, PositionGetDouble(POSITION_TP));
                        logManager.LogDebug("Trailing stop updated for BUY position", "TRADE");
                    }
                } else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                    currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                    newSL = currentPrice + trailingStop;
                    
                    if(newSL < currentSL - trailingStep || currentSL == 0) {
                        trade.PositionModify(PositionGetTicket(i), newSL, PositionGetDouble(POSITION_TP));
                        logManager.LogDebug("Trailing stop updated for SELL position", "TRADE");
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
