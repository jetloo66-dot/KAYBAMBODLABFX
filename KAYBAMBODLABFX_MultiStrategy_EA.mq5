//+------------------------------------------------------------------+
//|                                KAYBAMBODLABFX_MultiStrategy_EA.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>
#include "Include/Structs.mqh"
#include "Include/LogManager.mqh"
#include "Include/RiskManager.mqh"
#include "Include/NewsFilter.mqh"
#include "Include/VisualIndicators.mqh"
#include "Include/ConfigManager.mqh"
#include "Include/TradeManager.mqh"
#include "Include/TelegramNotifier.mqh"
#include "Include/PriceActionAnalyzer.mqh"

//--- Input Parameters
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

//--- Global Variables
CTradeManager* tradeManager;
CNewsFilter* newsFilter;
CVisualIndicators* visualIndicators;
CConfigManager* configManager;
CTelegramNotifications* telegramNotifier;
CLogManager* logManager;
CRiskManager* riskManager;

datetime LastScanTime = 0;
int Magic = 123456;

//--- Level Arrays (indexed)
double Support[10], Resistance[10], SwingHigh[10], SwingLow[10];
double HigherHigh[10], HigherLow[10], LowerLow[10], LowerHigh[10];
double High[10], Low[10];

//--- Pattern Detection Variables
struct PatternInfo {
    bool PinBar;
    bool Doji;
    bool BullishEngulfing;
    bool BearishEngulfing;
    bool BreakOfStructure;
    bool Retracement;
    int ConfirmationIndex;
    double ConfirmationLevel;
};

//--- Trend State
enum TrendDirection {
    TREND_UP,
    TREND_DOWN,
    TREND_SIDEWAYS
};

TrendDirection CurrentTrend = TREND_SIDEWAYS;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize log manager first for debugging
    logManager = new CLogManager("KAYBAMBODLABFX_Log.txt");
    logManager.SetLogLevel(LOG_LEVEL_INFO);
    logManager.LogInfo("KAYBAMBODLABFX EA initialization started", "MAIN");
    
    // Initialize configuration manager
    configManager = new CConfigManager();
    if(!configManager.LoadConfiguration()) {
        logManager.LogWarning("Failed to load configuration, using defaults", "CONFIG");
    }
    
    // Initialize risk manager
    riskManager = new CRiskManager(2.0, 1); // 2% risk, max 1 position
    logManager.LogInfo("Risk manager initialized", "RISK");
    
    // Initialize trade manager with magic number
    tradeManager = new CTradeManager(Magic);
    tradeManager.SetLotSize(LotSize);
    tradeManager.SetStopLoss(StopLossPips);
    tradeManager.SetTakeProfit(TakeProfitPips);
    tradeManager.SetTrailingStop(UseTrailingStop, TrailingStopPips, TrailingStepPips);
    tradeManager.SetMaxPositions(1);
    tradeManager.SetMaxRisk(2.0);
    logManager.LogInfo("Trade manager initialized", "TRADE");
    
    // Initialize news filter
    newsFilter = new CNewsFilter(NewsFilterMinutes);
    newsFilter.SetEnabled(UseNewsFilter);
    newsFilter.LoadNewsCalendar();
    logManager.LogInfo("News filter initialized", "NEWS");
    
    // Initialize visual indicators
    visualIndicators = new CVisualIndicators("KAYB_");
    visualIndicators.SetColors(SupportColor, ResistanceColor, BuyZoneColor, SellZoneColor);
    logManager.LogInfo("Visual indicators initialized", "VISUAL");
    
    // Initialize telegram notifier
    telegramNotifier = new CTelegramNotifications(TelegramBotToken, TelegramChatID, SendTelegramNotifications);
    if(SendTelegramNotifications && TelegramBotToken != "" && TelegramChatID != "") {
        logManager.LogInfo("Telegram notifications enabled", "TELEGRAM");
    }
    
    // Initialize arrays
    ArrayInitialize(Support, 0.0);
    ArrayInitialize(Resistance, 0.0);
    ArrayInitialize(SwingHigh, 0.0);
    ArrayInitialize(SwingLow, 0.0);
    ArrayInitialize(HigherHigh, 0.0);
    ArrayInitialize(HigherLow, 0.0);
    ArrayInitialize(LowerLow, 0.0);
    ArrayInitialize(LowerHigh, 0.0);
    ArrayInitialize(High, 0.0);
    ArrayInitialize(Low, 0.0);
    
    logManager.LogInfo("Price level arrays initialized", "MAIN");
    
    Print("KAYBAMBODLABFX MultiStrategy EA initialized successfully");
    logManager.LogInfo("KAYBAMBODLABFX MultiStrategy EA initialized successfully", "MAIN");
    
    if(SendTelegramNotifications && TelegramBotToken != "" && TelegramChatID != "") {
        telegramNotifier.SendMessage("🤖 KAYBAMBODLABFX EA Started on " + _Symbol);
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    if(logManager != NULL) {
        logManager.LogInfo("KAYBAMBODLABFX EA deinitialization started", "MAIN");
    }
    
    // Clean up chart objects
    if(visualIndicators != NULL) {
        visualIndicators.ClearAll();
        delete visualIndicators;
    }
    
    if(SendTelegramNotifications && telegramNotifier != NULL) {
        telegramNotifier.SendMessage("🛑 KAYBAMBODLABFX EA Stopped on " + _Symbol);
    }
    
    // Clean up objects
    if(tradeManager != NULL) delete tradeManager;
    if(newsFilter != NULL) delete newsFilter;
    if(configManager != NULL) delete configManager;
    if(telegramNotifier != NULL) delete telegramNotifier;
    if(riskManager != NULL) delete riskManager;
    
    if(logManager != NULL) {
        logManager.LogInfo("KAYBAMBODLABFX EA deinitialized successfully", "MAIN");
        delete logManager;
    }
    
    Print("KAYBAMBODLABFX EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if(tradeManager == NULL) return;
    
    // Check if it's time for market scan
    if(TimeCurrent() - LastScanTime >= ScanIntervalMinutes * 60) {
        PerformMarketAnalysis();
        LastScanTime = TimeCurrent();
    }
    
    // Manage existing positions
    tradeManager.ManagePositions();
    
    // Check for new trade opportunities
    CheckTradeConditions();
}

//+------------------------------------------------------------------+
//| Perform comprehensive market analysis                            |
//+------------------------------------------------------------------+
void PerformMarketAnalysis() {
    if(visualIndicators == NULL) return;
    
    // Detect price levels on different timeframes
    DetectPriceLevels(AnalysisTimeframe1);
    DetectPriceLevels(AnalysisTimeframe2);
    DetectPriceLevels(AnalysisTimeframe3);
    
    // Determine current trend
    DetermineTrend();
    
    // Draw Fibonacci retracement
    if(ShowFibonacci) {
        DrawFibonacciRetracement();
    }
    
    // Visualize levels and zones
    if(ShowLevels) {
        visualIndicators.DrawSupportResistance(Support, Resistance, MaxLevelsToStore);
        visualIndicators.DrawSwingLevels(SwingHigh, SwingLow, MaxLevelsToStore);
        visualIndicators.DrawTrendStructure(HigherHigh, HigherLow, LowerHigh, LowerLow, MaxLevelsToStore);
    }
    
    if(ShowZones) {
        VisualizeZones();
    }
    
    // Update trend indicator
    int trendDirection = 0;
    if(CurrentTrend == TREND_UP) trendDirection = 1;
    else if(CurrentTrend == TREND_DOWN) trendDirection = -1;
    visualIndicators.DrawTrendIndicator(trendDirection);
}

//+------------------------------------------------------------------+
//| Detect and store price levels                                   |
//+------------------------------------------------------------------+
void DetectPriceLevels(ENUM_TIMEFRAMES timeframe) {
    // Shift arrays to make room for new data
    ShiftLevelArrays();
    
    double high[], low[], close[], open[];
    
    if(CopyHigh(_Symbol, timeframe, 0, CandlesToScan, high) <= 0 ||
       CopyLow(_Symbol, timeframe, 0, CandlesToScan, low) <= 0 ||
       CopyClose(_Symbol, timeframe, 0, CandlesToScan, close) <= 0 ||
       CopyOpen(_Symbol, timeframe, 0, CandlesToScan, open) <= 0) {
        return;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    
    // Store basic highs and lows
    High[0] = high[0];
    Low[0] = low[0];
    
    // Detect swing highs and lows
    DetectSwingPoints(high, low, SwingStrength);
    
    // Detect support and resistance levels
    DetectSupportResistance(high, low, close);
    
    // Detect higher highs, higher lows, lower highs, lower lows
    DetectTrendStructure(high, low);
}

//+------------------------------------------------------------------+
//| Shift level arrays to accommodate new data                       |
//+------------------------------------------------------------------+
void ShiftLevelArrays() {
    // Shift all arrays one position
    for(int i = ArraySize(Support) - 1; i > 0; i--) {
        Support[i] = Support[i-1];
        Resistance[i] = Resistance[i-1];
        SwingHigh[i] = SwingHigh[i-1];
        SwingLow[i] = SwingLow[i-1];
        HigherHigh[i] = HigherHigh[i-1];
        HigherLow[i] = HigherLow[i-1];
        LowerLow[i] = LowerLow[i-1];
        LowerHigh[i] = LowerHigh[i-1];
        High[i] = High[i-1];
        Low[i] = Low[i-1];
    }
}

//+------------------------------------------------------------------+
//| Detect swing points                                              |
//+------------------------------------------------------------------+
void DetectSwingPoints(const double &high[], const double &low[], int strength) {
    // Detect swing highs
    for(int i = strength; i < ArraySize(high) - strength; i++) {
        bool isSwingHigh = true;
        for(int j = i - strength; j <= i + strength; j++) {
            if(j != i && high[j] >= high[i]) {
                isSwingHigh = false;
                break;
            }
        }
        if(isSwingHigh) {
            SwingHigh[0] = high[i];
            break;
        }
    }
    
    // Detect swing lows
    for(int i = strength; i < ArraySize(low) - strength; i++) {
        bool isSwingLow = true;
        for(int j = i - strength; j <= i + strength; j++) {
            if(j != i && low[j] <= low[i]) {
                isSwingLow = false;
                break;
            }
        }
        if(isSwingLow) {
            SwingLow[0] = low[i];
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Detect support and resistance levels                             |
//+------------------------------------------------------------------+
void DetectSupportResistance(const double &high[], const double &low[], const double &close[]) {
    // Simple support/resistance detection based on price rejection
    double currentPrice = close[0];
    
    // Find recent support level
    for(int i = 1; i < ArraySize(low); i++) {
        int touchCount = 0;
        for(int j = 0; j < ArraySize(low); j++) {
            if(MathAbs(low[j] - low[i]) <= LevelProximityPips * _Point) {
                touchCount++;
            }
        }
        if(touchCount >= 2) {
            Support[0] = low[i];
            break;
        }
    }
    
    // Find recent resistance level
    for(int i = 1; i < ArraySize(high); i++) {
        int touchCount = 0;
        for(int j = 0; j < ArraySize(high); j++) {
            if(MathAbs(high[j] - high[i]) <= LevelProximityPips * _Point) {
                touchCount++;
            }
        }
        if(touchCount >= 2) {
            Resistance[0] = high[i];
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Detect trend structure                                           |
//+------------------------------------------------------------------+
void DetectTrendStructure(const double &high[], const double &low[]) {
    // Detect Higher Highs and Higher Lows
    if(ArraySize(high) > 1 && high[0] > high[1]) {
        HigherHigh[0] = high[0];
    }
    
    if(ArraySize(low) > 1 && low[0] > low[1]) {
        HigherLow[0] = low[0];
    }
    
    // Detect Lower Lows and Lower Highs  
    if(ArraySize(low) > 1 && low[0] < low[1]) {
        LowerLow[0] = low[0];
    }
    
    if(ArraySize(high) > 1 && high[0] < high[1]) {
        LowerHigh[0] = high[0];
    }
}

//+------------------------------------------------------------------+
//| Determine current trend direction                                |
//+------------------------------------------------------------------+
void DetermineTrend() {
    int uptrendCount = 0;
    int downtrendCount = 0;
    
    // Criteria 1: Higher Highs and Higher Lows
    if(HigherHigh[0] > HigherHigh[1] && HigherLow[0] > HigherLow[1]) {
        uptrendCount++;
    } else if(HigherHigh[0] < HigherHigh[1] && HigherLow[0] < HigherLow[1]) {
        downtrendCount++;
    }
    
    // Criteria 2: Recent Swing Highs and Lows
    if(SwingHigh[0] > SwingHigh[1] && SwingLow[0] > SwingLow[1]) {
        uptrendCount++;
    } else if(SwingHigh[0] < SwingHigh[1] && SwingLow[0] < SwingLow[1]) {
        downtrendCount++;
    }
    
    // Criteria 3: Current High/Low vs Previous
    if(High[0] > High[1] && Low[0] > Low[1]) {
        uptrendCount++;
    } else if(High[0] < High[1] && Low[0] < Low[1]) {
        downtrendCount++;
    }
    
    // Criteria 4: Support and Resistance levels
    if(Support[0] > Support[1] && Resistance[0] > Resistance[1]) {
        uptrendCount++;
    } else if(Support[0] < Support[1] && Resistance[0] < Resistance[1]) {
        downtrendCount++;
    }
    
    // Criteria 5: Price action above/below key levels
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    if(currentPrice > Support[0] && currentPrice > SwingLow[0]) {
        uptrendCount++;
    } else if(currentPrice < Resistance[0] && currentPrice < SwingHigh[0]) {
        downtrendCount++;
    }
    
    // Criteria 6: Break of structure confirmation
    if(HigherHigh[0] > 0 && LowerLow[0] == 0) {
        uptrendCount++;
    } else if(LowerLow[0] > 0 && HigherHigh[0] == 0) {
        downtrendCount++;
    }
    
    // Determine trend based on criteria count (need at least 4 out of 6 for strong trend)
    if(uptrendCount >= 4) {
        CurrentTrend = TREND_UP;
    } else if(downtrendCount >= 4) {
        CurrentTrend = TREND_DOWN;
    } else {
        CurrentTrend = TREND_SIDEWAYS;
    }
    
    // Log trend analysis for debugging
    Print("Trend Analysis - Uptrend: ", uptrendCount, "/6, Downtrend: ", downtrendCount, "/6, Result: ", 
          CurrentTrend == TREND_UP ? "UPTREND" : (CurrentTrend == TREND_DOWN ? "DOWNTREND" : "SIDEWAYS"));
}

//+------------------------------------------------------------------+
//| Check for trade conditions and execute trades                    |
//+------------------------------------------------------------------+
void CheckTradeConditions() {
    if(newsFilter != NULL && newsFilter.IsNewsTime()) {
        return; // Don't trade during news
    }
    
    PatternInfo patterns = AnalyzePatterns();
    
    // Check buy conditions in uptrend
    if(CurrentTrend == TREND_UP) {
        if(CheckBuySequence(patterns)) {
            ExecuteBuyTrade(patterns);
        }
    }
    
    // Check sell conditions in downtrend
    if(CurrentTrend == TREND_DOWN) {
        if(CheckSellSequence(patterns)) {
            ExecuteSellTrade(patterns);
        }
    }
}

//+------------------------------------------------------------------+
//| Analyze patterns on execution timeframe                          |
//+------------------------------------------------------------------+
PatternInfo AnalyzePatterns() {
    PatternInfo patterns;
    patterns.PinBar = false;
    patterns.Doji = false;
    patterns.BullishEngulfing = false;
    patterns.BearishEngulfing = false;
    patterns.BreakOfStructure = false;
    patterns.Retracement = false;
    patterns.ConfirmationIndex = -1;
    patterns.ConfirmationLevel = 0.0;
    
    double high[], low[], close[], open[];
    
    if(CopyHigh(_Symbol, ExecutionTimeframe, 0, PatternScanCandles, high) <= 0 ||
       CopyLow(_Symbol, ExecutionTimeframe, 0, PatternScanCandles, low) <= 0 ||
       CopyClose(_Symbol, ExecutionTimeframe, 0, PatternScanCandles, close) <= 0 ||
       CopyOpen(_Symbol, ExecutionTimeframe, 0, PatternScanCandles, open) <= 0) {
        return patterns;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    
    for(int i = 0; i < PatternScanCandles - 1; i++) {
        // Pin Bar Detection
        if(IsPinBar(high[i], low[i], open[i], close[i])) {
            patterns.PinBar = true;
            patterns.ConfirmationIndex = i;
            patterns.ConfirmationLevel = close[i];
            
            // Draw pattern marker on chart
            if(visualIndicators != NULL) {
                double markerPrice = (high[i] + low[i]) / 2;
                visualIndicators.DrawPatternMarker("PinBar", i, markerPrice, clrYellow);
            }
        }
        
        // Doji Detection
        if(IsDoji(high[i], low[i], open[i], close[i])) {
            patterns.Doji = true;
            patterns.ConfirmationIndex = i;
            patterns.ConfirmationLevel = close[i];
            
            // Draw pattern marker on chart
            if(visualIndicators != NULL) {
                double markerPrice = (high[i] + low[i]) / 2;
                visualIndicators.DrawPatternMarker("Doji", i, markerPrice, clrWhite);
            }
        }
        
        // Engulfing Patterns
        if(i > 0) {
            if(IsBullishEngulfing(high[i], low[i], open[i], close[i], 
                                high[i+1], low[i+1], open[i+1], close[i+1])) {
                patterns.BullishEngulfing = true;
                patterns.ConfirmationIndex = i;
                patterns.ConfirmationLevel = close[i+1];
                
                // Draw pattern marker on chart
                if(visualIndicators != NULL) {
                    double markerPrice = (high[i] + low[i]) / 2;
                    visualIndicators.DrawPatternMarker("BullEngulf", i, markerPrice, clrLime);
                }
            }
            
            if(IsBearishEngulfing(high[i], low[i], open[i], close[i], 
                                high[i+1], low[i+1], open[i+1], close[i+1])) {
                patterns.BearishEngulfing = true;
                patterns.ConfirmationIndex = i;
                patterns.ConfirmationLevel = close[i+1];
                
                // Draw pattern marker on chart
                if(visualIndicators != NULL) {
                    double markerPrice = (high[i] + low[i]) / 2;
                    visualIndicators.DrawPatternMarker("BearEngulf", i, markerPrice, clrRed);
                }
            }
        }
        
        // Break of Structure Detection
        if(IsBreakOfStructure(high, low, i)) {
            patterns.BreakOfStructure = true;
            
            // Draw pattern marker on chart
            if(visualIndicators != NULL) {
                double markerPrice = (high[i] + low[i]) / 2;
                visualIndicators.DrawPatternMarker("BreakStruct", i, markerPrice, clrOrange);
            }
        }
        
        // Retracement Detection
        if(IsRetracement(close, patterns.ConfirmationLevel, i)) {
            patterns.Retracement = true;
            
            // Draw pattern marker on chart
            if(visualIndicators != NULL) {
                double markerPrice = (high[i] + low[i]) / 2;
                visualIndicators.DrawPatternMarker("Retracement", i, markerPrice, clrCyan);
            }
        }
    }
    
    return patterns;
}

//+------------------------------------------------------------------+
//| Pin Bar Detection                                                |
//+------------------------------------------------------------------+
bool IsPinBar(double high, double low, double open, double close) {
    double body = MathAbs(close - open);
    double totalRange = high - low;
    
    if(totalRange == 0) return false;
    
    double bodyRatio = body / totalRange;
    double upperWick = high - MathMax(open, close);
    double lowerWick = MathMin(open, close) - low;
    
    // Bullish Pin Bar (hammer)
    if(lowerWick > body * 2 && upperWick < body && bodyRatio < PinBarRatio) {
        return true;
    }
    
    // Bearish Pin Bar (shooting star)
    if(upperWick > body * 2 && lowerWick < body && bodyRatio < PinBarRatio) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Doji Detection                                                   |
//+------------------------------------------------------------------+
bool IsDoji(double high, double low, double open, double close) {
    double body = MathAbs(close - open);
    double totalRange = high - low;
    
    if(totalRange == 0) return false;
    
    double bodyRatio = body / totalRange;
    
    return bodyRatio <= DojiBodyRatio;
}

//+------------------------------------------------------------------+
//| Bullish Engulfing Detection                                      |
//+------------------------------------------------------------------+
bool IsBullishEngulfing(double h1, double l1, double o1, double c1,
                       double h2, double l2, double o2, double c2) {
    return (c2 < o2) && (c1 > o1) && (o1 < c2) && (c1 > o2) && ((c1 - o1) > EngulfingRatio * (o2 - c2));
}

//+------------------------------------------------------------------+
//| Bearish Engulfing Detection                                      |
//+------------------------------------------------------------------+
bool IsBearishEngulfing(double h1, double l1, double o1, double c1,
                       double h2, double l2, double o2, double c2) {
    return (c2 > o2) && (c1 < o1) && (o1 > c2) && (c1 < o2) && ((o1 - c1) > EngulfingRatio * (c2 - o2));
}

//+------------------------------------------------------------------+
//| Break of Structure Detection                                     |
//+------------------------------------------------------------------+
bool IsBreakOfStructure(const double &high[], const double &low[], int index) {
    if(index >= ArraySize(high) - 5) return false;
    
    // Look for structure break (simplified)
    if(CurrentTrend == TREND_UP) {
        // Look for break below recent swing low
        double recentLow = low[index + 1];
        for(int i = index + 2; i < MathMin(index + 10, ArraySize(low)); i++) {
            recentLow = MathMin(recentLow, low[i]);
        }
        return low[index] < recentLow - LevelProximityPips * _Point;
    } else if(CurrentTrend == TREND_DOWN) {
        // Look for break above recent swing high
        double recentHigh = high[index + 1];
        for(int i = index + 2; i < MathMin(index + 10, ArraySize(high)); i++) {
            recentHigh = MathMax(recentHigh, high[i]);
        }
        return high[index] > recentHigh + LevelProximityPips * _Point;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Retracement Detection                                            |
//+------------------------------------------------------------------+
bool IsRetracement(const double &close[], double confirmationLevel, int index) {
    if(confirmationLevel == 0.0) return false;
    
    double currentPrice = close[index];
    double distance = MathAbs(currentPrice - confirmationLevel);
    
    return distance <= LevelProximityPips * _Point;
}

//+------------------------------------------------------------------+
//| Check Buy Sequence Patterns                                     |
//+------------------------------------------------------------------+
bool CheckBuySequence(PatternInfo &patterns) {
    if(!IsNearBuyLevel()) return false;
    
    // Sequence I: (a) then (c) then (d) then (e)
    if(patterns.PinBar && patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence II: (a) then (d) then (e)
    if(patterns.PinBar && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence III: (a) then (c) then (e)
    if(patterns.PinBar && patterns.BullishEngulfing && patterns.Retracement) {
        return true;
    }
    
    // Sequence IV: (b) then (c) then (e)
    if(patterns.Doji && patterns.BullishEngulfing && patterns.Retracement) {
        return true;
    }
    
    // Sequence V: (b) then (c) then (d) then (e)
    if(patterns.Doji && patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence VI: (b) then (d) then (e)
    if(patterns.Doji && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence VII: (c) then (d) then (e)
    if(patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence VIII: (a) then (c)
    if(patterns.PinBar && patterns.BullishEngulfing) {
        return true;
    }
    
    // Sequence IX: (b) then (c)
    if(patterns.Doji && patterns.BullishEngulfing) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check Sell Sequence Patterns                                    |
//+------------------------------------------------------------------+
bool CheckSellSequence(PatternInfo &patterns) {
    if(!IsNearSellLevel()) return false;
    
    // Sequence I: (a) then (c) then (d) then (e) - Pin Bar + Bearish Engulfing + Break of Structure + Retracement
    if(patterns.PinBar && patterns.BearishEngulfing && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence II: (a) then (d) then (e) - Pin Bar + Break of Structure + Retracement
    if(patterns.PinBar && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence III: (a) then (c) then (e) - Pin Bar + Bearish Engulfing + Retracement
    if(patterns.PinBar && patterns.BearishEngulfing && patterns.Retracement) {
        return true;
    }
    
    // Sequence IV: (b) then (c) then (e) - Doji + Bearish Engulfing + Retracement
    if(patterns.Doji && patterns.BearishEngulfing && patterns.Retracement) {
        return true;
    }
    
    // Sequence V: (b) then (c) then (d) then (e) - Doji + Bearish Engulfing + Break of Structure + Retracement
    if(patterns.Doji && patterns.BearishEngulfing && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence VI: (b) then (d) then (e) - Doji + Break of Structure + Retracement
    if(patterns.Doji && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence VII: (c) then (d) then (e) - Bearish Engulfing + Break of Structure + Retracement
    if(patterns.BearishEngulfing && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Sequence VIII: (a) then (c) - Pin Bar + Bearish Engulfing
    if(patterns.PinBar && patterns.BearishEngulfing) {
        return true;
    }
    
    // Sequence IX: (b) then (c) - Doji + Bearish Engulfing
    if(patterns.Doji && patterns.BearishEngulfing) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is near buy levels                               |
//+------------------------------------------------------------------+
bool IsNearBuyLevel() {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double pipDistance = LevelProximityPips * _Point;
    
    // Check if near recent Support
    if(Support[0] > 0 && MathAbs(currentPrice - Support[0]) <= pipDistance) {
        return true;
    }
    
    // Check if near recent Higher Low
    if(HigherLow[0] > 0 && MathAbs(currentPrice - HigherLow[0]) <= pipDistance) {
        return true;
    }
    
    // Check if near recent Swing Low
    if(SwingLow[0] > 0 && MathAbs(currentPrice - SwingLow[0]) <= pipDistance) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is near sell levels                              |
//+------------------------------------------------------------------+
bool IsNearSellLevel() {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double pipDistance = LevelProximityPips * _Point;
    
    // Check if near recent Resistance
    if(Resistance[0] > 0 && MathAbs(currentPrice - Resistance[0]) <= pipDistance) {
        return true;
    }
    
    // Check if near recent Lower High
    if(LowerHigh[0] > 0 && MathAbs(currentPrice - LowerHigh[0]) <= pipDistance) {
        return true;
    }
    
    // Check if near recent Swing High
    if(SwingHigh[0] > 0 && MathAbs(currentPrice - SwingHigh[0]) <= pipDistance) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Execute Buy Trade                                                |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(PatternInfo &patterns) {
    if(tradeManager == NULL || riskManager == NULL) return;
    if(tradeManager.GetOpenPositions(_Symbol) > 0) return; // Only one position at a time
    
    // Risk management checks
    if(!riskManager.IsTradeAllowed()) {
        if(logManager != NULL) {
            logManager.LogWarning("Trade rejected by risk management", "RISK");
        }
        return;
    }
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = price - StopLossPips * _Point;
    double tp = price + TakeProfitPips * _Point;
    
    // Calculate risk-adjusted lot size
    double riskLotSize = riskManager.CalculateLotSize(StopLossPips, 2.0);
    double lotToUse = (riskLotSize > 0 && riskLotSize < LotSize) ? riskLotSize : LotSize;
    
    if(tradeManager.OpenBuyPosition(_Symbol, lotToUse, sl, tp, "KAYB Buy Signal")) {
        string message = "🟢 BUY ORDER EXECUTED\n";
        message += "Symbol: " + _Symbol + "\n";
        message += "Price: " + DoubleToString(price, _Digits) + "\n";
        message += "SL: " + DoubleToString(sl, _Digits) + "\n";
        message += "TP: " + DoubleToString(tp, _Digits) + "\n";
        message += "Lot: " + DoubleToString(lotToUse, 2) + "\n";
        message += "Trend: UPTREND\n";
        message += GetPatternDescription(patterns);
        
        if(telegramNotifier != NULL) {
            telegramNotifier.SendMessage(message);
        }
        
        if(logManager != NULL) {
            logManager.LogTrade("BUY", _Symbol, price, lotToUse, "Pattern-based signal");
        }
        
        // Draw entry signal on chart
        if(visualIndicators != NULL) {
            visualIndicators.DrawEntrySignal(price, true, "Pattern Signal");
        }
    } else {
        if(logManager != NULL) {
            logManager.LogError("Failed to execute BUY trade", "TRADE");
        }
    }
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                               |
//+------------------------------------------------------------------+
void ExecuteSellTrade(PatternInfo &patterns) {
    if(tradeManager == NULL || riskManager == NULL) return;
    if(tradeManager.GetOpenPositions(_Symbol) > 0) return; // Only one position at a time
    
    // Risk management checks
    if(!riskManager.IsTradeAllowed()) {
        if(logManager != NULL) {
            logManager.LogWarning("Trade rejected by risk management", "RISK");
        }
        return;
    }
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = price + StopLossPips * _Point;
    double tp = price - TakeProfitPips * _Point;
    
    // Calculate risk-adjusted lot size
    double riskLotSize = riskManager.CalculateLotSize(StopLossPips, 2.0);
    double lotToUse = (riskLotSize > 0 && riskLotSize < LotSize) ? riskLotSize : LotSize;
    
    if(tradeManager.OpenSellPosition(_Symbol, lotToUse, sl, tp, "KAYB Sell Signal")) {
        string message = "🔴 SELL ORDER EXECUTED\n";
        message += "Symbol: " + _Symbol + "\n";
        message += "Price: " + DoubleToString(price, _Digits) + "\n";
        message += "SL: " + DoubleToString(sl, _Digits) + "\n";
        message += "TP: " + DoubleToString(tp, _Digits) + "\n";
        message += "Lot: " + DoubleToString(lotToUse, 2) + "\n";
        message += "Trend: DOWNTREND\n";
        message += GetPatternDescription(patterns);
        
        if(telegramNotifier != NULL) {
            telegramNotifier.SendMessage(message);
        }
        
        if(logManager != NULL) {
            logManager.LogTrade("SELL", _Symbol, price, lotToUse, "Pattern-based signal");
        }
        
        // Draw entry signal on chart
        if(visualIndicators != NULL) {
            visualIndicators.DrawEntrySignal(price, false, "Pattern Signal");
        }
    } else {
        if(logManager != NULL) {
            logManager.LogError("Failed to execute SELL trade", "TRADE");
        }
    }
}

//+------------------------------------------------------------------+
//| Get pattern description for notifications                        |
//+------------------------------------------------------------------+
string GetPatternDescription(PatternInfo &patterns) {
    string desc = "Patterns detected:\n";
    if(patterns.PinBar) desc += "• Pin Bar\n";
    if(patterns.Doji) desc += "• Doji\n";
    if(patterns.BullishEngulfing) desc += "• Bullish Engulfing\n";
    if(patterns.BearishEngulfing) desc += "• Bearish Engulfing\n";
    if(patterns.BreakOfStructure) desc += "• Break of Structure\n";
    if(patterns.Retracement) desc += "• Retracement to Zone\n";
    return desc;
}

//+------------------------------------------------------------------+
//| Draw Fibonacci Retracement                                       |
//+------------------------------------------------------------------+
void DrawFibonacciRetracement() {
    if(visualIndicators == NULL) return;
    
    if(CurrentTrend == TREND_UP && SwingLow[1] > 0 && SwingHigh[0] > 0) {
        // Uptrend: From previous Swing Low to recent Swing High
        datetime startTime = iTime(_Symbol, _Period, 10);
        datetime endTime = iTime(_Symbol, _Period, 0);
        visualIndicators.DrawFibonacciRetracement(SwingHigh[0], SwingLow[1], startTime, endTime);
        
    } else if(CurrentTrend == TREND_DOWN && SwingHigh[1] > 0 && SwingLow[0] > 0) {
        // Downtrend: From previous Swing High to recent Swing Low
        datetime startTime = iTime(_Symbol, _Period, 10);
        datetime endTime = iTime(_Symbol, _Period, 0);
        visualIndicators.DrawFibonacciRetracement(SwingHigh[1], SwingLow[0], startTime, endTime);
    }
}

//+------------------------------------------------------------------+
//| Visualize Buy/Sell Zones                                        |
//+------------------------------------------------------------------+
void VisualizeZones() {
    if(visualIndicators == NULL) return;
    
    double buyLevels[10], sellLevels[10];
    int buyCount = 0, sellCount = 0;
    double pipDistance = LevelProximityPips * _Point;
    
    // Collect buy levels
    if(Support[0] > 0) { buyLevels[buyCount] = Support[0]; buyCount++; }
    if(HigherLow[0] > 0) { buyLevels[buyCount] = HigherLow[0]; buyCount++; }
    if(SwingLow[0] > 0) { buyLevels[buyCount] = SwingLow[0]; buyCount++; }
    
    // Collect sell levels
    if(Resistance[0] > 0) { sellLevels[sellCount] = Resistance[0]; sellCount++; }
    if(LowerHigh[0] > 0) { sellLevels[sellCount] = LowerHigh[0]; sellCount++; }
    if(SwingHigh[0] > 0) { sellLevels[sellCount] = SwingHigh[0]; sellCount++; }
    
    // Draw zones using visual indicators
    visualIndicators.DrawBuyZones(buyLevels, pipDistance, buyCount);
    visualIndicators.DrawSellZones(sellLevels, pipDistance, sellCount);
}

//+------------------------------------------------------------------+