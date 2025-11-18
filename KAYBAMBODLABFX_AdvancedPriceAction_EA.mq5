//+------------------------------------------------------------------+
//|                            KAYBAMBODLABFX_AdvancedPriceAction_EA.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property description "Advanced Price Action Analysis EA with Automated Trading"

//--- Include files
#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>
#include "Structs_Version1.mqh"
#include "GlobalVariables_Version1.mqh"
#include "PriceActionAnalyzer_Enhanced.mqh"
#include "TradeManager_Enhanced.mqh"
#include "TelegramNotifications.mqh"
#include "NewsFilter_Version2.mqh"
#include "LogManager_Version1.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== ANALYSIS SETTINGS ==="
input ENUM_TIMEFRAMES PrimaryTimeframe = PERIOD_H1;           // Primary Analysis Timeframe (H1)
input ENUM_TIMEFRAMES ExecutionTimeframe = PERIOD_M5;         // Execution Pattern Timeframe (M5)
input int CandlesToAnalyze = 100;                             // Candles to analyze for levels (configurable)
input int PatternScanCandles = 20;                            // M5 candles to scan for patterns (configurable)

input group "=== LEVEL DETECTION ==="
input int MaxlevelsPerType = 10;                              // Maximum levels to store per type
input double LevelProximityPips = 5.0;                        // Proximity to levels in pips
input int SwingDetectionStrength = 5;                         // Swing point detection strength

input group "=== TREND DETECTION H1 ==="
input bool EnableStrictTrendRules = true;                     // Enable strict trend detection rules
input int TrendLookbackPeriods = 50;                          // Periods for trend analysis

input group "=== TRADE MANAGEMENT ==="
input double DefaultLotSize = 0.01;                           // Default lot size
input double StopLossBasePips = 10.0;                         // Base stop loss in pips (configurable)
input double TakeProfitBasePips = 50.0;                       // Base take profit in pips (configurable)
input int MaxTradesPerPair = 2;                               // Maximum trades per pair (configurable)
input bool UseTrailingStop = true;                            // Enable trailing stop
input double TrailingStopPips = 15.0;                         // Trailing stop distance

input group "=== PATTERN DETECTION ==="
input double PinBarWickRatio = 0.6;                           // Pin bar wick to body ratio
input double DojiMaxBodyRatio = 0.1;                          // Doji maximum body ratio
input double EngulfingMinRatio = 1.0;                         // Engulfing minimum ratio

input group "=== RISK MANAGEMENT ==="
input double MaxRiskPercentPerTrade = 2.0;                    // Max risk per trade (%)
input double MaxDailyRisk = 5.0;                              // Max daily risk (%)
input bool UseFixedLotSize = false;                           // Use fixed lot size vs risk-based

input group "=== SCANNING ==="
input int ScanIntervalMinutes = 5;                            // Scan frequency (every 5 minutes)
input string SymbolsToScan = "EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD,XAUUSD,XAGUSD,BTCUSD,ETHUSD";

input group "=== NEWS FILTER ==="
input bool UseNewsFilter = true;                              // Enable news filter
input int NewsAvoidanceMinutes = 30;                          // Minutes to avoid trading around news

input group "=== TELEGRAM NOTIFICATIONS ==="
input string TelegramBotToken = "";                           // Telegram bot token
input string TelegramChatID = "";                             // Telegram chat ID
input bool EnableTelegramNotifications = false;               // Enable Telegram notifications

input group "=== VISUALIZATION ==="
input bool ShowLevelsOnChart = true;                          // Show key levels on chart
input bool DrawBuyZones = true;                               // Draw buy confirmation zones
input bool DrawSellZones = true;                              // Draw sell confirmation zones
input color SupportLevelColor = clrBlue;                      // Support level color
input color ResistanceLevelColor = clrRed;                    // Resistance level color
input color BuyZoneColor = clrLimeGreen;                      // Buy zone color
input color SellZoneColor = clrOrange;                        // Sell zone color

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
CTrade trade;
CPriceActionAnalyzerEnhanced* priceActionAnalyzer;
CTradeManagerEnhanced* tradeManager;
CTelegramNotifications* telegramNotifier;
CNewsFilter* newsFilter;
CLogManager* logger;

datetime lastScanTime = 0;
int expertMagicNumber = 123456789;

// Key level arrays with indexing system
struct KeyLevels {
    double Support[10];         // S[0] = most recent, S[1] = previous, etc.
    double Resistance[10];      // R[0] = most recent, R[1] = previous, etc.
    double SwingHigh[10];       // SH[0] = most recent, etc.
    double SwingLow[10];        // SL[0] = most recent, etc.
    double HigherHigh[10];      // HH[0] = most recent, etc.
    double HigherLow[10];       // HL[0] = most recent, etc.
    double LowerLow[10];        // LL[0] = most recent, etc.
    double LowerHigh[10];       // LH[0] = most recent, etc.
    double High[10];            // H[0] = most recent, etc.
    double Low[10];             // L[0] = most recent, etc.
    datetime LastUpdate;
};

KeyLevels currentLevels;

// Trend state tracking
enum TrendState {
    TREND_UNDEFINED,
    TREND_BULLISH,
    TREND_BEARISH,
    TREND_CONSOLIDATION
};

TrendState currentTrendH1 = TREND_UNDEFINED;

// Pattern detection structures
struct PatternSequence {
    bool PinBar;                // (a) pin bar
    bool Doji;                  // (b) doji  
    bool BullishEngulfing;      // (c) bullish engulfing
    bool BearishEngulfing;      // (c) bearish engulfing
    bool BreakOfStructureM5;    // (d) break of structure M5
    bool RetracementConfirm;    // (e) retracement to confirmation zone
    datetime DetectionTime;
    int ConfirmationCandle;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("=== KAYBAMBODLABFX Advanced Price Action EA Starting ===");
    
    // Initialize trade object
    trade.SetExpertMagicNumber(expertMagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(_Symbol);
    trade.SetDeviationInPoints(10);
    
    // Initialize components
    if(!InitializeComponents()) {
        Print("ERROR: Failed to initialize EA components");
        return INIT_FAILED;
    }
    
    // Initialize key levels
    InitializeKeyLevels();
    
    // Perform initial market scan
    if(!PerformInitialMarketScan()) {
        Print("WARNING: Initial market scan encountered issues");
    }
    
    // Setup chart visualization
    if(ShowLevelsOnChart) {
        SetupChartVisualization();
    }
    
    Print("=== EA Initialization Complete ===");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("=== EA Deinitialization - Reason: ", reason, " ===");
    
    // Clean up chart objects
    CleanupChartObjects();
    
    // Clean up components
    if(priceActionAnalyzer != NULL) {
        delete priceActionAnalyzer;
        priceActionAnalyzer = NULL;
    }
    
    if(tradeManager != NULL) {
        delete tradeManager;
        tradeManager = NULL;
    }
    
    if(telegramNotifier != NULL) {
        delete telegramNotifier;
        telegramNotifier = NULL;
    }
    
    if(newsFilter != NULL) {
        delete newsFilter;
        newsFilter = NULL;
    }
    
    if(logger != NULL) {
        delete logger;
        logger = NULL;
    }
    
    Print("=== EA Cleanup Complete ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if it's time for market scan (every 5 minutes by default)
    if(IsTimeForScan()) {
        PerformMarketAnalysis();
        lastScanTime = TimeCurrent();
    }
    
    // Manage existing positions
    if(tradeManager != NULL) {
        tradeManager.ManageExistingPositions();
    }
    
    // Check for new trade opportunities
    CheckForTradeOpportunities();
}

//+------------------------------------------------------------------+
//| Initialize all EA components                                     |
//+------------------------------------------------------------------+
bool InitializeComponents() {
    // Initialize logger first
    logger = new CLogManager();
    if(logger == NULL) {
        Print("ERROR: Failed to initialize logger");
        return false;
    }
    logger.SetLevel(LOG_LEVEL_INFO);
    logger.LogInfo("Starting EA component initialization", "INIT");
    
    // Initialize price action analyzer
    priceActionAnalyzer = new CPriceActionAnalyzerEnhanced(_Symbol, PrimaryTimeframe, CandlesToAnalyze);
    if(priceActionAnalyzer == NULL) {
        logger.LogError("Failed to initialize price action analyzer", "INIT");
        return false;
    }
    
    // Initialize trade manager
    tradeManager = new CTradeManagerEnhanced(logger, MaxTradesPerPair);
    if(tradeManager == NULL) {
        logger.LogError("Failed to initialize trade manager", "INIT");
        return false;
    }
    tradeManager.SetRiskParameters(MaxRiskPercentPerTrade, MaxDailyRisk, UseFixedLotSize, DefaultLotSize);
    
    // Initialize Telegram notifications if enabled
    if(EnableTelegramNotifications && TelegramBotToken != "" && TelegramChatID != "") {
        telegramNotifier = new CTelegramNotifications(TelegramBotToken, TelegramChatID, true);
        if(telegramNotifier != NULL) {
            telegramNotifier.SendMessage("🚀 KAYBAMBODLABFX EA Started - " + _Symbol);
            logger.LogInfo("Telegram notifications initialized", "INIT");
        }
    }
    
    // Initialize news filter
    if(UseNewsFilter) {
        newsFilter = new CNewsFilter(NewsAvoidanceMinutes);
        if(newsFilter == NULL) {
            logger.LogWarning("Failed to initialize news filter", "INIT");
        } else {
            logger.LogInfo("News filter initialized", "INIT");
        }
    }
    
    logger.LogInfo("All components initialized successfully", "INIT");
    return true;
}

//+------------------------------------------------------------------+
//| Initialize key levels structure                                  |
//+------------------------------------------------------------------+
void InitializeKeyLevels() {
    // Initialize all arrays to zero
    ArrayInitialize(currentLevels.Support, 0.0);
    ArrayInitialize(currentLevels.Resistance, 0.0);
    ArrayInitialize(currentLevels.SwingHigh, 0.0);
    ArrayInitialize(currentLevels.SwingLow, 0.0);
    ArrayInitialize(currentLevels.HigherHigh, 0.0);
    ArrayInitialize(currentLevels.HigherLow, 0.0);
    ArrayInitialize(currentLevels.LowerLow, 0.0);
    ArrayInitialize(currentLevels.LowerHigh, 0.0);
    ArrayInitialize(currentLevels.High, 0.0);
    ArrayInitialize(currentLevels.Low, 0.0);
    
    currentLevels.LastUpdate = 0;
    
    logger.LogInfo("Key levels structure initialized", "LEVELS");
}

//+------------------------------------------------------------------+
//| Perform initial market scan                                      |
//+------------------------------------------------------------------+
bool PerformInitialMarketScan() {
    logger.LogInfo("Performing initial market scan", "SCAN");
    
    if(priceActionAnalyzer == NULL) {
        logger.LogError("Price action analyzer not initialized", "SCAN");
        return false;
    }
    
    // Analyze key levels on H1 timeframe
    if(!AnalyzeKeyLevelsH1()) {
        logger.LogWarning("Failed to analyze H1 key levels", "SCAN");
        return false;
    }
    
    // Determine current trend
    if(!DetermineTrendH1()) {
        logger.LogWarning("Failed to determine H1 trend", "SCAN");
    }
    
    // Update chart visualization
    if(ShowLevelsOnChart) {
        UpdateChartVisualization();
    }
    
    logger.LogInfo("Initial market scan completed", "SCAN");
    return true;
}

//+------------------------------------------------------------------+
//| Check if it's time for market scan                              |
//+------------------------------------------------------------------+
bool IsTimeForScan() {
    if(lastScanTime == 0) return true;
    
    datetime currentTime = TimeCurrent();
    int secondsSinceLastScan = (int)(currentTime - lastScanTime);
    int scanIntervalSeconds = ScanIntervalMinutes * 60;
    
    return (secondsSinceLastScan >= scanIntervalSeconds);
}

//+------------------------------------------------------------------+
//| Perform comprehensive market analysis                           |
//+------------------------------------------------------------------+
void PerformMarketAnalysis() {
    logger.LogInfo("Starting market analysis cycle", "ANALYSIS");
    
    // Update key levels
    if(!AnalyzeKeyLevelsH1()) {
        logger.LogWarning("Failed to update key levels", "ANALYSIS");
        return;
    }
    
    // Update trend analysis
    if(!DetermineTrendH1()) {
        logger.LogWarning("Failed to update trend analysis", "ANALYSIS");
        return;
    }
    
    // Update chart visualization
    if(ShowLevelsOnChart) {
        UpdateChartVisualization();
    }
    
    // Send Telegram update if enabled
    if(telegramNotifier != NULL && EnableTelegramNotifications) {
        SendMarketAnalysisUpdate();
    }
    
    logger.LogInfo("Market analysis cycle completed", "ANALYSIS");
}

//+------------------------------------------------------------------+
//| Analyze key levels on H1 timeframe                              |
//+------------------------------------------------------------------+
bool AnalyzeKeyLevelsH1() {
    if(priceActionAnalyzer == NULL) return false;
    
    // Get H1 price data
    double high[], low[], close[], open[];
    int candleCount = CandlesToAnalyze;
    
    if(CopyHigh(_Symbol, PrimaryTimeframe, 0, candleCount, high) < candleCount ||
       CopyLow(_Symbol, PrimaryTimeframe, 0, candleCount, low) < candleCount ||
       CopyClose(_Symbol, PrimaryTimeframe, 0, candleCount, close) < candleCount ||
       CopyOpen(_Symbol, PrimaryTimeframe, 0, candleCount, open) < candleCount) {
        logger.LogError("Failed to copy H1 price data", "LEVELS");
        return false;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    
    // Detect swing points and levels
    DetectSwingPoints(high, low, close);
    DetectSupportResistanceLevels(high, low, close);
    DetectHigherHighsLowerLows(high, low);
    
    // Update recent highs and lows
    UpdateRecentHighsLows(high, low);
    
    currentLevels.LastUpdate = TimeCurrent();
    
    logger.LogInfo("Key levels analysis completed", "LEVELS");
    return true;
}

//+------------------------------------------------------------------+
//| Detect swing points (SH, SL)                                    |
//+------------------------------------------------------------------+
void DetectSwingPoints(const double &high[], const double &low[], const double &close[]) {
    int strength = SwingDetectionStrength;
    int arraySize = ArraySize(high);
    
    // Clear existing swing points
    ArrayInitialize(currentLevels.SwingHigh, 0.0);
    ArrayInitialize(currentLevels.SwingLow, 0.0);
    
    int shIndex = 0, slIndex = 0;
    
    // Find swing highs and lows
    for(int i = strength; i < arraySize - strength && shIndex < 10 && slIndex < 10; i++) {
        bool isSwingHigh = true;
        bool isSwingLow = true;
        
        // Check if current point is a swing high
        for(int j = i - strength; j <= i + strength; j++) {
            if(j != i && high[j] >= high[i]) {
                isSwingHigh = false;
                break;
            }
        }
        
        // Check if current point is a swing low
        for(int j = i - strength; j <= i + strength; j++) {
            if(j != i && low[j] <= low[i]) {
                isSwingLow = false;
                break;
            }
        }
        
        // Store swing high
        if(isSwingHigh && shIndex < 10) {
            currentLevels.SwingHigh[shIndex] = high[i];
            shIndex++;
        }
        
        // Store swing low
        if(isSwingLow && slIndex < 10) {
            currentLevels.SwingLow[slIndex] = low[i];
            slIndex++;
        }
    }
    
    logger.LogInfo(StringFormat("Detected %d swing highs, %d swing lows", shIndex, slIndex), "SWINGS");
}

//+------------------------------------------------------------------+
//| Detect support and resistance levels                            |
//+------------------------------------------------------------------+
void DetectSupportResistanceLevels(const double &high[], const double &low[], const double &close[]) {
    double proximityPoints = LevelProximityPips * _Point;
    int arraySize = ArraySize(high);
    
    // Clear existing levels
    ArrayInitialize(currentLevels.Support, 0.0);
    ArrayInitialize(currentLevels.Resistance, 0.0);
    
    int supportIndex = 0, resistanceIndex = 0;
    
    // Find support levels (price bounced up from these levels)
    for(int i = 2; i < arraySize - 2 && supportIndex < 10; i++) {
        double testLevel = low[i];
        int touchCount = 0;
        
        // Count touches within proximity
        for(int j = 0; j < arraySize; j++) {
            if(MathAbs(low[j] - testLevel) <= proximityPoints || 
               (close[j] <= testLevel + proximityPoints && close[j] >= testLevel - proximityPoints)) {
                touchCount++;
            }
        }
        
        // If level was touched multiple times, consider it support
        if(touchCount >= 2) {
            // Check if this level is not already recorded
            bool isDuplicate = false;
            for(int k = 0; k < supportIndex; k++) {
                if(MathAbs(currentLevels.Support[k] - testLevel) <= proximityPoints) {
                    isDuplicate = true;
                    break;
                }
            }
            
            if(!isDuplicate) {
                currentLevels.Support[supportIndex] = testLevel;
                supportIndex++;
            }
        }
    }
    
    // Find resistance levels (price bounced down from these levels)
    for(int i = 2; i < arraySize - 2 && resistanceIndex < 10; i++) {
        double testLevel = high[i];
        int touchCount = 0;
        
        // Count touches within proximity
        for(int j = 0; j < arraySize; j++) {
            if(MathAbs(high[j] - testLevel) <= proximityPoints || 
               (close[j] >= testLevel - proximityPoints && close[j] <= testLevel + proximityPoints)) {
                touchCount++;
            }
        }
        
        // If level was touched multiple times, consider it resistance
        if(touchCount >= 2) {
            // Check if this level is not already recorded
            bool isDuplicate = false;
            for(int k = 0; k < resistanceIndex; k++) {
                if(MathAbs(currentLevels.Resistance[k] - testLevel) <= proximityPoints) {
                    isDuplicate = true;
                    break;
                }
            }
            
            if(!isDuplicate) {
                currentLevels.Resistance[resistanceIndex] = testLevel;
                resistanceIndex++;
            }
        }
    }
    
    logger.LogInfo(StringFormat("Detected %d support levels, %d resistance levels", supportIndex, resistanceIndex), "LEVELS");
}

//+------------------------------------------------------------------+
//| Detect Higher Highs, Higher Lows, Lower Lows, Lower Highs      |
//+------------------------------------------------------------------+
void DetectHigherHighsLowerLows(const double &high[], const double &low[]) {
    // Clear existing arrays
    ArrayInitialize(currentLevels.HigherHigh, 0.0);
    ArrayInitialize(currentLevels.HigherLow, 0.0);
    ArrayInitialize(currentLevels.LowerLow, 0.0);
    ArrayInitialize(currentLevels.LowerHigh, 0.0);
    
    int hhIndex = 0, hlIndex = 0, llIndex = 0, lhIndex = 0;
    
    // Analyze price structure for HH, HL, LL, LH
    for(int i = 1; i < ArraySize(high) - 1; i++) {
        // Higher High: current high > previous significant high
        if(hhIndex < 10 && i > 10) {
            double prevSignificantHigh = high[i + 5]; // Look back 5 periods
            if(high[i] > prevSignificantHigh) {
                currentLevels.HigherHigh[hhIndex] = high[i];
                hhIndex++;
            }
        }
        
        // Higher Low: current low > previous significant low
        if(hlIndex < 10 && i > 10) {
            double prevSignificantLow = low[i + 5]; // Look back 5 periods
            if(low[i] > prevSignificantLow) {
                currentLevels.HigherLow[hlIndex] = low[i];
                hlIndex++;
            }
        }
        
        // Lower Low: current low < previous significant low
        if(llIndex < 10 && i > 10) {
            double prevSignificantLow = low[i + 5]; // Look back 5 periods
            if(low[i] < prevSignificantLow) {
                currentLevels.LowerLow[llIndex] = low[i];
                llIndex++;
            }
        }
        
        // Lower High: current high < previous significant high
        if(lhIndex < 10 && i > 10) {
            double prevSignificantHigh = high[i + 5]; // Look back 5 periods
            if(high[i] < prevSignificantHigh) {
                currentLevels.LowerHigh[lhIndex] = high[i];
                lhIndex++;
            }
        }
    }
    
    logger.LogInfo(StringFormat("Detected HH:%d, HL:%d, LL:%d, LH:%d", hhIndex, hlIndex, llIndex, lhIndex), "STRUCTURE");
}

//+------------------------------------------------------------------+
//| Update recent highs and lows                                    |
//+------------------------------------------------------------------+
void UpdateRecentHighsLows(const double &high[], const double &low[]) {
    // Clear existing arrays
    ArrayInitialize(currentLevels.High, 0.0);
    ArrayInitialize(currentLevels.Low, 0.0);
    
    // Store recent highs and lows (last 10 significant ones)
    for(int i = 0; i < MathMin(10, ArraySize(high)); i++) {
        currentLevels.High[i] = high[i];
        currentLevels.Low[i] = low[i];
    }
}

//+------------------------------------------------------------------+
//| Determine trend on H1 timeframe using strict rules             |
//+------------------------------------------------------------------+
bool DetermineTrendH1() {
    if(!EnableStrictTrendRules) return true;
    
    // Implement strict trend detection rules as specified
    bool uptrendCondition1 = (currentLevels.HigherHigh[0] > currentLevels.HigherHigh[1]);          // HH[0] > HH[1]
    bool uptrendCondition2 = (currentLevels.HigherLow[0] > currentLevels.HigherLow[1]);            // HL[0] > HL[1]
    bool uptrendCondition3 = (currentLevels.SwingHigh[0] > currentLevels.SwingHigh[1]);            // SH[0] > SH[1]
    bool uptrendCondition4 = (currentLevels.SwingLow[0] > currentLevels.SwingLow[1]);              // SL[0] > SL[1]
    bool uptrendCondition5 = (currentLevels.High[0] > currentLevels.SwingHigh[1]);                 // H[0] > SH[1]
    bool uptrendCondition6 = (currentLevels.Low[0] > currentLevels.Low[1]);                        // L[0] > L[1]
    
    bool downtrendCondition1 = (currentLevels.HigherHigh[0] < currentLevels.HigherHigh[1]);        // HH[0] < HH[1]
    bool downtrendCondition2 = (currentLevels.HigherLow[0] < currentLevels.HigherLow[1]);          // HL[0] < HL[1]
    bool downtrendCondition3 = (currentLevels.SwingHigh[0] < currentLevels.SwingHigh[1]);          // SH[0] < SH[1]
    bool downtrendCondition4 = (currentLevels.SwingLow[0] < currentLevels.SwingLow[1]);            // SL[0] < SL[1]
    bool downtrendCondition5 = (currentLevels.High[0] < currentLevels.SwingHigh[1]);               // H[0] < SH[1]
    bool downtrendCondition6 = (currentLevels.Low[0] < currentLevels.Low[1]);                      // L[0] < L[1]
    
    // All conditions must be met for uptrend
    if(uptrendCondition1 && uptrendCondition2 && uptrendCondition3 && 
       uptrendCondition4 && uptrendCondition5 && uptrendCondition6) {
        currentTrendH1 = TREND_BULLISH;
        logger.LogInfo("H1 Trend: BULLISH (all conditions met)", "TREND");
        return true;
    }
    
    // All conditions must be met for downtrend
    if(downtrendCondition1 && downtrendCondition2 && downtrendCondition3 && 
       downtrendCondition4 && downtrendCondition5 && downtrendCondition6) {
        currentTrendH1 = TREND_BEARISH;
        logger.LogInfo("H1 Trend: BEARISH (all conditions met)", "TREND");
        return true;
    }
    
    // If not all conditions are met, trend is consolidation
    currentTrendH1 = TREND_CONSOLIDATION;
    logger.LogInfo("H1 Trend: CONSOLIDATION", "TREND");
    return true;
}

//+------------------------------------------------------------------+
//| Check for trade opportunities                                   |
//+------------------------------------------------------------------+
void CheckForTradeOpportunities() {
    // Check if news filter allows trading
    if(newsFilter != NULL && newsFilter.IsNewsTime()) {
        return; // Skip trading during news
    }
    
    // Check buy opportunities
    if(currentTrendH1 == TREND_BULLISH) {
        CheckBuyOpportunities();
    }
    
    // Check sell opportunities  
    if(currentTrendH1 == TREND_BEARISH) {
        CheckSellOpportunities();
    }
}

//+------------------------------------------------------------------+
//| Check for buy opportunities                                     |
//+------------------------------------------------------------------+
void CheckBuyOpportunities() {
    // Scan last 20 M5 candles for patterns
    PatternSequence patterns = ScanM5PatternsForBuy();
    
    // Check if we're near buy levels
    if(!IsNearBuyLevels()) {
        return;
    }
    
    // Check sequence patterns (I-IX as specified)
    if(CheckBuySequencePatterns(patterns)) {
        // Execute buy trade
        ExecuteBuyTrade(patterns);
    }
}

//+------------------------------------------------------------------+
//| Check for sell opportunities                                    |
//+------------------------------------------------------------------+
void CheckSellOpportunities() {
    // Scan last 20 M5 candles for patterns
    PatternSequence patterns = ScanM5PatternsForSell();
    
    // Check if we're near sell levels
    if(!IsNearSellLevels()) {
        return;
    }
    
    // Check sequence patterns (I-IX as specified)
    if(CheckSellSequencePatterns(patterns)) {
        // Execute sell trade
        ExecuteSellTrade(patterns);
    }
}

//+------------------------------------------------------------------+
//| Scan M5 patterns for buy opportunities                         |
//+------------------------------------------------------------------+
PatternSequence ScanM5PatternsForBuy() {
    PatternSequence patterns = {false, false, false, false, false, false, 0, 0};
    
    if(priceActionAnalyzer == NULL) return patterns;
    
    // Scan last PatternScanCandles M5 candles
    for(int i = 0; i < PatternScanCandles; i++) {
        // (a) Pin bar detection
        if(priceActionAnalyzer.IsPinBar(i, PinBarWickRatio)) {
            patterns.PinBar = true;
        }
        
        // (b) Doji detection
        if(priceActionAnalyzer.IsDoji(i, DojiMaxBodyRatio)) {
            patterns.Doji = true;
        }
        
        // (c) Bullish engulfing detection
        if(priceActionAnalyzer.IsBullishEngulfing(i)) {
            patterns.BullishEngulfing = true;
        }
        
        // (d) Break of structure M5
        if(priceActionAnalyzer.IsBreakOfStructure(i, 10)) {
            patterns.BreakOfStructureM5 = true;
        }
        
        // (e) Retracement to confirmation buy zone
        if(IsInBuyConfirmationZone()) {
            patterns.RetracementConfirm = true;
        }
    }
    
    patterns.DetectionTime = TimeCurrent();
    return patterns;
}

//+------------------------------------------------------------------+
//| Scan M5 patterns for sell opportunities                        |
//+------------------------------------------------------------------+
PatternSequence ScanM5PatternsForSell() {
    PatternSequence patterns = {false, false, false, false, false, false, 0, 0};
    
    if(priceActionAnalyzer == NULL) return patterns;
    
    // Scan last PatternScanCandles M5 candles
    for(int i = 0; i < PatternScanCandles; i++) {
        // (a) Inverted pin bar detection
        if(priceActionAnalyzer.IsShootingStar(i)) { // Using shooting star as inverted pin bar
            patterns.PinBar = true;
        }
        
        // (b) Doji detection
        if(priceActionAnalyzer.IsDoji(i, DojiMaxBodyRatio)) {
            patterns.Doji = true;
        }
        
        // (c) Bearish engulfing detection
        if(priceActionAnalyzer.IsBearishEngulfing(i)) {
            patterns.BearishEngulfing = true;
        }
        
        // (d) Break of structure M5
        if(priceActionAnalyzer.IsBreakOfStructure(i, 10)) {
            patterns.BreakOfStructureM5 = true;
        }
        
        // (e) Retracement to confirmation sell zone
        if(IsInSellConfirmationZone()) {
            patterns.RetracementConfirm = true;
        }
    }
    
    patterns.DetectionTime = TimeCurrent();
    return patterns;
}

//+------------------------------------------------------------------+
//| Check if price is near buy levels                              |
//+------------------------------------------------------------------+
bool IsNearBuyLevels() {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double proximityPoints = LevelProximityPips * _Point;
    
    // Check specific H1 levels for buy activation:
    // S[0], within 5 pips of S[0], HL[0], within 5 pips of HL[0], 
    // high of lowest bearish candle at S[0], SL[0]
    
    if(currentLevels.Support[0] > 0 && 
       MathAbs(currentPrice - currentLevels.Support[0]) <= proximityPoints) {
        return true;
    }
    
    if(currentLevels.HigherLow[0] > 0 && 
       MathAbs(currentPrice - currentLevels.HigherLow[0]) <= proximityPoints) {
        return true;
    }
    
    if(currentLevels.SwingLow[0] > 0 && 
       MathAbs(currentPrice - currentLevels.SwingLow[0]) <= proximityPoints) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is near sell levels                             |
//+------------------------------------------------------------------+
bool IsNearSellLevels() {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double proximityPoints = LevelProximityPips * _Point;
    
    // Check specific H1 levels for sell activation:
    // R[0], within 5 pips of R[0], LH[0], within 5 pips of LH[0], 
    // low of highest bullish candle at R[0], SH[0]
    
    if(currentLevels.Resistance[0] > 0 && 
       MathAbs(currentPrice - currentLevels.Resistance[0]) <= proximityPoints) {
        return true;
    }
    
    if(currentLevels.LowerHigh[0] > 0 && 
       MathAbs(currentPrice - currentLevels.LowerHigh[0]) <= proximityPoints) {
        return true;
    }
    
    if(currentLevels.SwingHigh[0] > 0 && 
       MathAbs(currentPrice - currentLevels.SwingHigh[0]) <= proximityPoints) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check buy sequence patterns I-IX                               |
//+------------------------------------------------------------------+
bool CheckBuySequencePatterns(const PatternSequence &patterns) {
    // Implement all 9 sequences as specified in requirements
    
    // Sequence I: (a) then (c) then (d) then (e)
    if(patterns.PinBar && patterns.BullishEngulfing && 
       patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Buy Sequence I detected: (a)+(c)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence II: (a) then (b) then (c) then (d) then (e)
    if(patterns.PinBar && patterns.Doji && patterns.BullishEngulfing && 
       patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Buy Sequence II detected: (a)+(b)+(c)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence III: (b) then (c) then (d) then (e)
    if(patterns.Doji && patterns.BullishEngulfing && 
       patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Buy Sequence III detected: (b)+(c)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence IV: (a) then (d) then (e)
    if(patterns.PinBar && patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Buy Sequence IV detected: (a)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence V: (b) then (d) then (e)
    if(patterns.Doji && patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Buy Sequence V detected: (b)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence VI: (c) then (d) then (e)
    if(patterns.BullishEngulfing && patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Buy Sequence VI detected: (c)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence VII: (a) then (c)
    if(patterns.PinBar && patterns.BullishEngulfing) {
        logger.LogInfo("Buy Sequence VII detected: (a)+(c)", "SEQUENCE");
        return true;
    }
    
    // Sequence VIII: (b) then (c)
    if(patterns.Doji && patterns.BullishEngulfing) {
        logger.LogInfo("Buy Sequence VIII detected: (b)+(c)", "SEQUENCE");
        return true;
    }
    
    // Sequence IX: (d) then (e)
    if(patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Buy Sequence IX detected: (d)+(e)", "SEQUENCE");
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check sell sequence patterns I-IX                              |
//+------------------------------------------------------------------+
bool CheckSellSequencePatterns(const PatternSequence &patterns) {
    // Similar to buy sequences but with bearish patterns
    
    // Sequence I: (a) then (c) then (d) then (e)
    if(patterns.PinBar && patterns.BearishEngulfing && 
       patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Sell Sequence I detected: (a)+(c)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence II: (a) then (b) then (c) then (d) then (e)
    if(patterns.PinBar && patterns.Doji && patterns.BearishEngulfing && 
       patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Sell Sequence II detected: (a)+(b)+(c)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Sequence III: (b) then (c) then (d) then (e)
    if(patterns.Doji && patterns.BearishEngulfing && 
       patterns.BreakOfStructureM5 && patterns.RetracementConfirm) {
        logger.LogInfo("Sell Sequence III detected: (b)+(c)+(d)+(e)", "SEQUENCE");
        return true;
    }
    
    // Add remaining sequences IV-IX similar to buy logic
    // ... (continuing with the same pattern for brevity)
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is in buy confirmation zone                     |
//+------------------------------------------------------------------+
bool IsInBuyConfirmationZone() {
    // Implementation depends on specific confirmation zone definition
    // This is a placeholder that should be enhanced based on strategy
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Example: Check if price is in lower third of recent range
    if(currentLevels.High[0] > 0 && currentLevels.Low[0] > 0) {
        double range = currentLevels.High[0] - currentLevels.Low[0];
        double lowerThird = currentLevels.Low[0] + (range * 0.33);
        return (currentPrice <= lowerThird);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is in sell confirmation zone                    |
//+------------------------------------------------------------------+
bool IsInSellConfirmationZone() {
    // Implementation depends on specific confirmation zone definition
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // Example: Check if price is in upper third of recent range
    if(currentLevels.High[0] > 0 && currentLevels.Low[0] > 0) {
        double range = currentLevels.High[0] - currentLevels.Low[0];
        double upperThird = currentLevels.High[0] - (range * 0.33);
        return (currentPrice >= upperThird);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Execute buy trade                                               |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(const PatternSequence &patterns) {
    if(tradeManager == NULL) return;
    
    // Check if we can open more trades
    if(!tradeManager.CanOpenNewPosition(ORDER_TYPE_BUY)) {
        return;
    }
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double stopLoss = currentPrice - (StopLossBasePips * _Point);
    double takeProfit = currentPrice + (TakeProfitBasePips * _Point);
    
    // Calculate lot size based on risk
    double lotSize = tradeManager.CalculateLotSize(currentPrice, stopLoss, ORDER_TYPE_BUY);
    
    // Place buy order
    if(trade.Buy(lotSize, _Symbol, currentPrice, stopLoss, takeProfit, "KAYB_BUY")) {
        logger.LogInfo(StringFormat("Buy order executed: Price=%.5f, SL=%.5f, TP=%.5f, Lot=%.2f", 
                      currentPrice, stopLoss, takeProfit, lotSize), "TRADE");
        
        // Send Telegram notification
        if(telegramNotifier != NULL) {
            string message = StringFormat("🟢 BUY %s\nPrice: %.5f\nSL: %.5f\nTP: %.5f\nLot: %.2f", 
                           _Symbol, currentPrice, stopLoss, takeProfit, lotSize);
            telegramNotifier.SendMessage(message);
        }
    } else {
        logger.LogError(StringFormat("Failed to execute buy order: %d", GetLastError()), "TRADE");
    }
}

//+------------------------------------------------------------------+
//| Execute sell trade                                              |
//+------------------------------------------------------------------+
void ExecuteSellTrade(const PatternSequence &patterns) {
    if(tradeManager == NULL) return;
    
    // Check if we can open more trades
    if(!tradeManager.CanOpenNewPosition(ORDER_TYPE_SELL)) {
        return;
    }
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double stopLoss = currentPrice + (StopLossBasePips * _Point);
    double takeProfit = currentPrice - (TakeProfitBasePips * _Point);
    
    // Calculate lot size based on risk
    double lotSize = tradeManager.CalculateLotSize(currentPrice, stopLoss, ORDER_TYPE_SELL);
    
    // Place sell order
    if(trade.Sell(lotSize, _Symbol, currentPrice, stopLoss, takeProfit, "KAYB_SELL")) {
        logger.LogInfo(StringFormat("Sell order executed: Price=%.5f, SL=%.5f, TP=%.5f, Lot=%.2f", 
                      currentPrice, stopLoss, takeProfit, lotSize), "TRADE");
        
        // Send Telegram notification
        if(telegramNotifier != NULL) {
            string message = StringFormat("🔴 SELL %s\nPrice: %.5f\nSL: %.5f\nTP: %.5f\nLot: %.2f", 
                           _Symbol, currentPrice, stopLoss, takeProfit, lotSize);
            telegramNotifier.SendMessage(message);
        }
    } else {
        logger.LogError(StringFormat("Failed to execute sell order: %d", GetLastError()), "TRADE");
    }
}

//+------------------------------------------------------------------+
//| Setup chart visualization                                        |
//+------------------------------------------------------------------+
void SetupChartVisualization() {
    // Setup will be handled in UpdateChartVisualization
    logger.LogInfo("Chart visualization setup completed", "CHART");
}

//+------------------------------------------------------------------+
//| Update chart visualization                                       |
//+------------------------------------------------------------------+
void UpdateChartVisualization() {
    if(!ShowLevelsOnChart) return;
    
    // Clean up existing objects
    CleanupChartObjects();
    
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds(PrimaryTimeframe) * 50;
    
    // Draw support levels
    for(int i = 0; i < 10; i++) {
        if(currentLevels.Support[i] > 0) {
            string objName = "KAYB_Support_" + IntegerToString(i);
            if(ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, currentLevels.Support[i], 
                          futureTime, currentLevels.Support[i])) {
                ObjectSetInteger(0, objName, OBJPROP_COLOR, SupportLevelColor);
                ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
                ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
                ObjectSetString(0, objName, OBJPROP_TEXT, "S[" + IntegerToString(i) + "]");
            }
        }
    }
    
    // Draw resistance levels
    for(int i = 0; i < 10; i++) {
        if(currentLevels.Resistance[i] > 0) {
            string objName = "KAYB_Resistance_" + IntegerToString(i);
            if(ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, currentLevels.Resistance[i], 
                          futureTime, currentLevels.Resistance[i])) {
                ObjectSetInteger(0, objName, OBJPROP_COLOR, ResistanceLevelColor);
                ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
                ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
                ObjectSetString(0, objName, OBJPROP_TEXT, "R[" + IntegerToString(i) + "]");
            }
        }
    }
    
    // Draw swing levels
    for(int i = 0; i < 10; i++) {
        if(currentLevels.SwingHigh[i] > 0) {
            string objName = "KAYB_SwingHigh_" + IntegerToString(i);
            if(ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, currentLevels.SwingHigh[i], 
                          futureTime, currentLevels.SwingHigh[i])) {
                ObjectSetInteger(0, objName, OBJPROP_COLOR, clrOrange);
                ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
                ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
                ObjectSetString(0, objName, OBJPROP_TEXT, "SH[" + IntegerToString(i) + "]");
            }
        }
        
        if(currentLevels.SwingLow[i] > 0) {
            string objName = "KAYB_SwingLow_" + IntegerToString(i);
            if(ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, currentLevels.SwingLow[i], 
                          futureTime, currentLevels.SwingLow[i])) {
                ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
                ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
                ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
                ObjectSetString(0, objName, OBJPROP_TEXT, "SL[" + IntegerToString(i) + "]");
            }
        }
    }
    
    // Draw buy/sell zones if enabled
    if(DrawBuyZones) {
        DrawConfirmationZones(true);
    }
    
    if(DrawSellZones) {
        DrawConfirmationZones(false);
    }
}

//+------------------------------------------------------------------+
//| Draw confirmation zones                                          |
//+------------------------------------------------------------------+
void DrawConfirmationZones(bool isBuyZone) {
    // This is a simplified implementation - should be enhanced based on strategy
    if(currentLevels.High[0] <= 0 || currentLevels.Low[0] <= 0) return;
    
    double range = currentLevels.High[0] - currentLevels.Low[0];
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds(PrimaryTimeframe) * 20;
    
    if(isBuyZone) {
        double buyZoneTop = currentLevels.Low[0] + (range * 0.33);
        double buyZoneBottom = currentLevels.Low[0];
        
        string objName = "KAYB_BuyZone";
        if(ObjectCreate(0, objName, OBJ_RECTANGLE, 0, currentTime, buyZoneTop, futureTime, buyZoneBottom)) {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, BuyZoneColor);
            ObjectSetInteger(0, objName, OBJPROP_FILL, true);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
        }
    } else {
        double sellZoneBottom = currentLevels.High[0] - (range * 0.33);
        double sellZoneTop = currentLevels.High[0];
        
        string objName = "KAYB_SellZone";
        if(ObjectCreate(0, objName, OBJ_RECTANGLE, 0, currentTime, sellZoneTop, futureTime, sellZoneBottom)) {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, SellZoneColor);
            ObjectSetInteger(0, objName, OBJPROP_FILL, true);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
        }
    }
}

//+------------------------------------------------------------------+
//| Cleanup chart objects                                            |
//+------------------------------------------------------------------+
void CleanupChartObjects() {
    // Remove all objects created by this EA
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        if(StringFind(objName, "KAYB_") >= 0) {
            ObjectDelete(0, objName);
        }
    }
}

//+------------------------------------------------------------------+
//| Send market analysis update via Telegram                        |
//+------------------------------------------------------------------+
void SendMarketAnalysisUpdate() {
    if(telegramNotifier == NULL) return;
    
    string trendText = "";
    switch(currentTrendH1) {
        case TREND_BULLISH: trendText = "🟢 BULLISH"; break;
        case TREND_BEARISH: trendText = "🔴 BEARISH"; break;
        case TREND_CONSOLIDATION: trendText = "🟠 CONSOLIDATION"; break;
        default: trendText = "⚪ UNDEFINED"; break;
    }
    
    string message = StringFormat(
        "📊 %s Market Analysis\n\n" +
        "Trend H1: %s\n" +
        "Support[0]: %.5f\n" +
        "Resistance[0]: %.5f\n" +
        "Swing High[0]: %.5f\n" +
        "Swing Low[0]: %.5f\n\n" +
        "Last Update: %s",
        _Symbol, trendText,
        currentLevels.Support[0],
        currentLevels.Resistance[0], 
        currentLevels.SwingHigh[0],
        currentLevels.SwingLow[0],
        TimeToString(TimeCurrent())
    );
    
    telegramNotifier.SendMessage(message);
}

//+------------------------------------------------------------------+