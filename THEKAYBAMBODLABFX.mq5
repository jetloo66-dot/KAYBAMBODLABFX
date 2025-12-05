//+------------------------------------------------------------------+
//|                                             THEKAYBAMBODLABFX.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>
#include <Math\Stat\Math.mqh>
#include "Structs_Version1.mqh"
#include "PriceActionAnalyzer_Enhanced.mqh"
#include "NewsFilter_Version2.mqh"
#include "TelegramNotifications.mqh"
#include "RiskManager_Version2.mqh"

//--- Input Parameters
input group "=== TIMEFRAME SETTINGS ==="
input ENUM_TIMEFRAMES AnalysisTimeframe1 = PERIOD_H1;        // Primary Analysis Timeframe (H1)
input ENUM_TIMEFRAMES AnalysisTimeframe2 = PERIOD_H4;        // Secondary Analysis Timeframe (H4)  
input ENUM_TIMEFRAMES AnalysisTimeframe3 = PERIOD_D1;        // Tertiary Analysis Timeframe (Daily)
input ENUM_TIMEFRAMES ExecutionTimeframe = PERIOD_M5;        // Pattern Execution Timeframe (M5)

input group "=== SCAN SETTINGS ==="
input int CandlesToScan = 100;                               // Candles to scan for levels
input int PatternScanCandles = 20;                          // Candles to scan for patterns on M5
input int ScanIntervalMinutes = 5;                          // Chart scan interval (minutes)

input group "=== LEVEL DETECTION ==="
input int MaxLevelsToStore = 10;                            // Maximum levels to store per type
input double LevelProximityPips = 5.0;                      // Proximity to levels (pips)
input int SwingStrength = 5;                                // Swing detection strength

input group "=== TRADE SETTINGS ==="
input double LotSize = 0.01;                                // Lot Size
input double StopLossPips = 10.0;                           // Stop Loss (pips)
input double TakeProfitPips = 50.0;                         // Take Profit (pips)
input int MaxTradesPerPair = 2;                             // Maximum trades per pair
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

//--- Global Variables and Objects
CTrade trade;
CPriceActionAnalyzer* priceAnalyzer;
CPriceActionAnalyzer* patternAnalyzer; // Separate analyzer for M5 patterns
CNewsFilter* newsFilter;
CTelegramNotifications* telegram;
CRiskManager* riskManager;

datetime LastScanTime = 0;
int Magic = 789123;

//--- Level Arrays (indexed from most recent [0] to oldest [9])
double Support[10], Resistance[10], SwingHigh[10], SwingLow[10];
double HigherHigh[10], HigherLow[10], LowerLow[10], LowerHigh[10];
double High[10], Low[10];

//--- Pattern Detection Structure
struct PatternSequence {
    bool PinBar;              // (a) or (a1)
    bool Doji;                // (b) or (b2) 
    bool BullishEngulfing;    // (c)
    bool BearishEngulfing;    // (c3)
    bool BreakOfStructure;    // (d) or (d4)
    bool Retracement;         // (e) or (e5)
    int DetectionIndex;
    double ConfirmationLevel;
    datetime DetectionTime;
};

//--- Trend State
enum TrendDirection {
    TREND_NONE,
    TREND_UP,
    TREND_DOWN,
    TREND_SIDEWAYS
};

TrendDirection CurrentTrend = TREND_SIDEWAYS;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize trading object
    trade.SetExpertMagicNumber(Magic);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(_Symbol);
    
    // Initialize analysis objects
    priceAnalyzer = new CPriceActionAnalyzer(_Symbol, AnalysisTimeframe1, CandlesToScan);
    patternAnalyzer = new CPriceActionAnalyzer(_Symbol, ExecutionTimeframe, PatternScanCandles);
    newsFilter = new CNewsFilter(NewsFilterMinutes);
    telegram = new CTelegramNotifications(TelegramBotToken, TelegramChatID, SendTelegramNotifications);
    riskManager = new CRiskManager(2.0, MaxTradesPerPair);
    
    // Initialize level arrays
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
    
    // Load news calendar
    if(UseNewsFilter) {
        newsFilter.LoadNewsCalendar();
    }
    
    // Send initialization message
    if(SendTelegramNotifications && telegram != NULL) {
        string message = "🚀 THEKAYBAMBODLABFX EA Initialized\n";
        message += "Symbol: " + _Symbol + "\n";
        message += "Timeframes: " + EnumToString(AnalysisTimeframe1) + ", " + EnumToString(AnalysisTimeframe2) + ", " + EnumToString(AnalysisTimeframe3) + "\n";
        message += "Execution: " + EnumToString(ExecutionTimeframe) + "\n";
        message += "Risk: " + DoubleToString(StopLossPips, 1) + " SL / " + DoubleToString(TakeProfitPips, 1) + " TP pips";
        telegram.SendMessage(message);
    }
    
    Print("THEKAYBAMBODLABFX EA initialized successfully for ", _Symbol);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Clean up chart objects
    CleanupChartObjects();
    
    // Send shutdown message
    if(SendTelegramNotifications && telegram != NULL) {
        telegram.SendMessage("⏹️ THEKAYBAMBODLABFX EA Shutdown\nReason: " + GetDeinitReasonText(reason));
    }
    
    // Clean up objects
    if(priceAnalyzer != NULL) delete priceAnalyzer;
    if(patternAnalyzer != NULL) delete patternAnalyzer;
    if(newsFilter != NULL) delete newsFilter;
    if(telegram != NULL) delete telegram;
    if(riskManager != NULL) delete riskManager;
    
    Print("THEKAYBAMBODLABFX EA deinitialized. Reason: ", GetDeinitReasonText(reason));
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if it's time to scan (every 5 minutes by default)
    datetime currentTime = TimeCurrent();
    if(currentTime - LastScanTime < ScanIntervalMinutes * 60) {
        ManageOpenPositions();
        return;
    }
    
    LastScanTime = currentTime;
    
    // Perform comprehensive market analysis
    PerformMarketAnalysis();
    
    // Manage existing positions
    ManageOpenPositions();
    
    // Check for new trade opportunities
    CheckTradeOpportunities();
}

//+------------------------------------------------------------------+
//| Perform comprehensive market analysis                            |
//+------------------------------------------------------------------+
void PerformMarketAnalysis() {
    // Detect price levels on different timeframes
    DetectPriceLevels(AnalysisTimeframe1);
    DetectPriceLevels(AnalysisTimeframe2);
    DetectPriceLevels(AnalysisTimeframe3);
    
    // Determine current trend
    DetermineTrend();
    
    // Visualize levels and zones if enabled
    if(ShowLevels) VisualizeLevels();
    if(ShowFibonacci) DrawFibonacciRetracement();
    if(ShowZones) VisualizeZones();
}

//+------------------------------------------------------------------+
//| Detect and store price levels                                   |
//+------------------------------------------------------------------+
void DetectPriceLevels(ENUM_TIMEFRAMES timeframe) {
    // Shift arrays to make room for new data
    ShiftLevelArrays();
    
    double high[], low[], close[], open[];
    int copied = CopyHigh(_Symbol, timeframe, 0, CandlesToScan, high);
    if(copied <= 0) return;
    
    CopyLow(_Symbol, timeframe, 0, CandlesToScan, low);
    CopyClose(_Symbol, timeframe, 0, CandlesToScan, close);
    CopyOpen(_Symbol, timeframe, 0, CandlesToScan, open);
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    
    // Find swing highs and lows
    for(int i = SwingStrength; i < ArraySize(high) - SwingStrength; i++) {
        bool isSwingHigh = true;
        bool isSwingLow = true;
        
        // Check for swing high
        for(int j = 1; j <= SwingStrength; j++) {
            if(high[i] <= high[i-j] || high[i] <= high[i+j]) {
                isSwingHigh = false;
                break;
            }
        }
        
        // Check for swing low
        for(int j = 1; j <= SwingStrength; j++) {
            if(low[i] >= low[i-j] || low[i] >= low[i+j]) {
                isSwingLow = false;
                break;
            }
        }
        
        if(isSwingHigh && SwingHigh[0] == 0) {
            SwingHigh[0] = high[i];
            Resistance[0] = high[i];
        }
        
        if(isSwingLow && SwingLow[0] == 0) {
            SwingLow[0] = low[i];
            Support[0] = low[i];
        }
    }
    
    // Detect trend structure levels
    DetectTrendStructure(high, low, close, open);
    
    // Store recent highs and lows
    High[0] = high[0];
    Low[0] = low[0];
}

//+------------------------------------------------------------------+
//| Detect trend structure (HH, HL, LH, LL)                        |
//+------------------------------------------------------------------+
void DetectTrendStructure(const double &high[], const double &low[], const double &close[], const double &open[]) {
    // Find higher highs and higher lows for uptrend
    for(int i = 1; i < ArraySize(high) - 1; i++) {
        // Higher High detection
        if(high[i-1] > high[i] && HigherHigh[0] == 0) {
            HigherHigh[0] = high[i-1];
        }
        
        // Higher Low detection  
        if(low[i-1] > low[i] && HigherLow[0] == 0) {
            HigherLow[0] = low[i-1];
        }
        
        // Lower High detection
        if(high[i-1] < high[i] && LowerHigh[0] == 0) {
            LowerHigh[0] = high[i-1];
        }
        
        // Lower Low detection
        if(low[i-1] < low[i] && LowerLow[0] == 0) {
            LowerLow[0] = low[i-1];
        }
    }
}

//+------------------------------------------------------------------+
//| Determine current trend based on structure                       |
//+------------------------------------------------------------------+
void DetermineTrend() {
    bool uptrend = false;
    bool downtrend = false;
    
    // Uptrend conditions
    if(HigherHigh[0] > 0 && HigherHigh[1] > 0 && HigherHigh[0] > HigherHigh[1] &&
       HigherLow[0] > 0 && HigherLow[1] > 0 && HigherLow[0] > HigherLow[1] &&
       SwingHigh[0] > SwingHigh[1] && SwingLow[0] > SwingLow[1] &&
       High[0] > SwingHigh[1] && Low[0] > Low[1]) {
        uptrend = true;
    }
    
    // Downtrend conditions  
    if(HigherHigh[0] > 0 && HigherHigh[1] > 0 && HigherHigh[0] < HigherHigh[1] &&
       HigherLow[0] > 0 && HigherLow[1] > 0 && HigherLow[0] < HigherLow[1] &&
       SwingHigh[0] < SwingHigh[1] && SwingLow[0] < SwingLow[1] &&
       High[0] < SwingHigh[1] && Low[0] < Low[1]) {
        downtrend = true;
    }
    
    if(uptrend) {
        CurrentTrend = TREND_UP;
    } else if(downtrend) {
        CurrentTrend = TREND_DOWN;
    } else {
        CurrentTrend = TREND_SIDEWAYS;
    }
}

//+------------------------------------------------------------------+
//| Check for trade opportunities                                    |
//+------------------------------------------------------------------+
void CheckTradeOpportunities() {
    // Skip trading during news if filter is enabled
    if(UseNewsFilter && newsFilter != NULL && newsFilter.IsNewsTime()) {
        return;
    }
    
    // Check risk limits
    if(riskManager != NULL && !riskManager.CanOpenPosition()) {
        return;
    }
    
    // Analyze patterns on execution timeframe (M5)
    PatternSequence patterns = AnalyzePatternsM5();
    
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
//| Analyze patterns on M5 timeframe                                |
//+------------------------------------------------------------------+
PatternSequence AnalyzePatternsM5() {
    PatternSequence patterns = {};
    
    if(patternAnalyzer == NULL) return patterns;
    
    // Scan last 20 candles on M5 for patterns
    for(int i = 1; i <= PatternScanCandles; i++) {
        // Pattern detection
        if(patternAnalyzer.IsPinBar(i, PinBarRatio)) {
            patterns.PinBar = true;
            patterns.DetectionIndex = i;
        }
        
        if(patternAnalyzer.IsDoji(i, DojiBodyRatio)) {
            patterns.Doji = true;
            patterns.DetectionIndex = i;
        }
        
        if(patternAnalyzer.IsBullishEngulfing(i)) {
            patterns.BullishEngulfing = true;
            patterns.DetectionIndex = i;
        }
        
        if(patternAnalyzer.IsBearishEngulfing(i)) {
            patterns.BearishEngulfing = true;
            patterns.DetectionIndex = i;
        }
        
        if(patternAnalyzer.IsBreakOfStructure(i)) {
            patterns.BreakOfStructure = true;
            patterns.DetectionIndex = i;
        }
        
        // Check for retracement to confirmation zone
        patterns.Retracement = CheckRetracementToZone();
    }
    
    patterns.DetectionTime = TimeCurrent();
    return patterns;
}

//+------------------------------------------------------------------+
//| Check if price retraced to confirmation buy/sell zone           |
//+------------------------------------------------------------------+
bool CheckRetracementToZone() {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double pipDistance = LevelProximityPips * _Point;
    
    // Check proximity to key levels
    if(Support[0] > 0 && MathAbs(currentPrice - Support[0]) <= pipDistance) return true;
    if(Resistance[0] > 0 && MathAbs(currentPrice - Resistance[0]) <= pipDistance) return true;
    if(HigherLow[0] > 0 && MathAbs(currentPrice - HigherLow[0]) <= pipDistance) return true;
    if(LowerHigh[0] > 0 && MathAbs(currentPrice - LowerHigh[0]) <= pipDistance) return true;
    if(SwingLow[0] > 0 && MathAbs(currentPrice - SwingLow[0]) <= pipDistance) return true;
    if(SwingHigh[0] > 0 && MathAbs(currentPrice - SwingHigh[0]) <= pipDistance) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check valid buy sequences                                        |
//+------------------------------------------------------------------+
bool CheckBuySequence(const PatternSequence &patterns) {
    // Valid Buy Sequences:
    // 1. (a) → (c) → (d) → (e)
    if(patterns.PinBar && patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 2. (a) → (d) → (e)
    if(patterns.PinBar && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 3. (a) → (c) → (e)
    if(patterns.PinBar && patterns.BullishEngulfing && patterns.Retracement) return true;
    
    // 4. (b) → (c) → (e)
    if(patterns.Doji && patterns.BullishEngulfing && patterns.Retracement) return true;
    
    // 5. (b) → (c) → (d) → (e)
    if(patterns.Doji && patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 6. (b) → (d) → (e)
    if(patterns.Doji && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 7. (c) → (d) → (e)
    if(patterns.BullishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 8. (a) → (c)
    if(patterns.PinBar && patterns.BullishEngulfing) return true;
    
    // 9. (b) → (c)
    if(patterns.Doji && patterns.BullishEngulfing) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check valid sell sequences                                       |
//+------------------------------------------------------------------+
bool CheckSellSequence(const PatternSequence &patterns) {
    // Valid Sell Sequences (same logic but with bearish patterns):
    // 1. (a1) → (c3) → (d4) → (e5)
    if(patterns.PinBar && patterns.BearishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 2. (a1) → (d4) → (e5)
    if(patterns.PinBar && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 3. (a1) → (c3) → (e5)
    if(patterns.PinBar && patterns.BearishEngulfing && patterns.Retracement) return true;
    
    // 4. (b2) → (c3) → (e5)
    if(patterns.Doji && patterns.BearishEngulfing && patterns.Retracement) return true;
    
    // 5. (b2) → (c3) → (d4) → (e5)
    if(patterns.Doji && patterns.BearishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 6. (b2) → (d4) → (e5)
    if(patterns.Doji && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 7. (c3) → (d4) → (e5)
    if(patterns.BearishEngulfing && patterns.BreakOfStructure && patterns.Retracement) return true;
    
    // 8. (a1) → (c3)
    if(patterns.PinBar && patterns.BearishEngulfing) return true;
    
    // 9. (b2) → (c3)
    if(patterns.Doji && patterns.BearishEngulfing) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Execute buy trade                                                |
//+------------------------------------------------------------------+
void ExecuteBuyTrade(const PatternSequence &patterns) {
    if(PositionsTotal() >= MaxTradesPerPair) return;
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = price - StopLossPips * _Point;
    double tp = (SwingHigh[0] > 0) ? SwingHigh[0] : price + TakeProfitPips * _Point;
    
    // Calculate lot size based on risk
    double lotSize = LotSize;
    if(riskManager != NULL) {
        lotSize = riskManager.CalculateLotSize(StopLossPips, 2.0);
    }
    
    if(trade.Buy(lotSize, _Symbol, price, sl, tp, "KAYB Buy Signal")) {
        // Send Telegram notification
        if(SendTelegramNotifications && telegram != NULL) {
            string message = "🟢 BUY TRADE EXECUTED\n";
            message += "Symbol: " + _Symbol + "\n";
            message += "Entry: " + DoubleToString(price, _Digits) + "\n";
            message += "SL: " + DoubleToString(sl, _Digits) + "\n";
            message += "TP: " + DoubleToString(tp, _Digits) + "\n";
            message += "Lot: " + DoubleToString(lotSize, 2) + "\n";
            message += "Patterns: " + GetPatternDescription(patterns);
            telegram.SendMessage(message);
        }
        
        Print("Buy trade executed for ", _Symbol, " at ", price);
    }
}

//+------------------------------------------------------------------+
//| Execute sell trade                                               |
//+------------------------------------------------------------------+
void ExecuteSellTrade(const PatternSequence &patterns) {
    if(PositionsTotal() >= MaxTradesPerPair) return;
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = price + StopLossPips * _Point;
    double tp = (SwingLow[0] > 0) ? SwingLow[0] : price - TakeProfitPips * _Point;
    
    // Calculate lot size based on risk
    double lotSize = LotSize;
    if(riskManager != NULL) {
        lotSize = riskManager.CalculateLotSize(StopLossPips, 2.0);
    }
    
    if(trade.Sell(lotSize, _Symbol, price, sl, tp, "KAYB Sell Signal")) {
        // Send Telegram notification
        if(SendTelegramNotifications && telegram != NULL) {
            string message = "🔴 SELL TRADE EXECUTED\n";
            message += "Symbol: " + _Symbol + "\n";
            message += "Entry: " + DoubleToString(price, _Digits) + "\n";
            message += "SL: " + DoubleToString(sl, _Digits) + "\n";
            message += "TP: " + DoubleToString(tp, _Digits) + "\n";
            message += "Lot: " + DoubleToString(lotSize, 2) + "\n";
            message += "Patterns: " + GetPatternDescription(patterns);
            telegram.SendMessage(message);
        }
        
        Print("Sell trade executed for ", _Symbol, " at ", price);
    }
}

//+------------------------------------------------------------------+
//| Manage open positions (trailing stop, etc.)                     |
//+------------------------------------------------------------------+
void ManageOpenPositions() {
    if(!UseTrailingStop) return;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == Magic) {
                double currentSL = PositionGetDouble(POSITION_SL);
                double currentPrice, newSL;
                
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                    currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                    newSL = currentPrice - TrailingStopPips * _Point;
                    
                    if(newSL > currentSL + TrailingStepPips * _Point) {
                        trade.PositionModify(PositionGetTicket(i), newSL, PositionGetDouble(POSITION_TP));
                    }
                } else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                    currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                    newSL = currentPrice + TrailingStopPips * _Point;
                    
                    if(newSL < currentSL - TrailingStepPips * _Point || currentSL == 0) {
                        trade.PositionModify(PositionGetTicket(i), newSL, PositionGetDouble(POSITION_TP));
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+
void ShiftLevelArrays() {
    // Shift all level arrays to make room for new data
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
    
    // Reset first elements
    Support[0] = 0.0;
    Resistance[0] = 0.0;
    SwingHigh[0] = 0.0;
    SwingLow[0] = 0.0;
    HigherHigh[0] = 0.0;
    HigherLow[0] = 0.0;
    LowerLow[0] = 0.0;
    LowerHigh[0] = 0.0;
    High[0] = 0.0;
    Low[0] = 0.0;
}

string GetPatternDescription(const PatternSequence &patterns) {
    string desc = "";
    if(patterns.PinBar) desc += "Pin Bar, ";
    if(patterns.Doji) desc += "Doji, ";
    if(patterns.BullishEngulfing) desc += "Bullish Engulfing, ";
    if(patterns.BearishEngulfing) desc += "Bearish Engulfing, ";
    if(patterns.BreakOfStructure) desc += "Break of Structure, ";
    if(patterns.Retracement) desc += "Retracement";
    return desc;
}

string GetDeinitReasonText(int reason) {
    switch(reason) {
        case REASON_PROGRAM: return "Expert Advisor terminated";
        case REASON_REMOVE: return "Expert Advisor removed from chart";
        case REASON_RECOMPILE: return "Expert Advisor recompiled";
        case REASON_CHARTCHANGE: return "Chart period or symbol changed";
        case REASON_CHARTCLOSE: return "Chart closed";
        case REASON_PARAMETERS: return "Parameters changed";
        case REASON_ACCOUNT: return "Account changed";
        case REASON_TEMPLATE: return "Template changed";
        case REASON_INITFAILED: return "Initialization failed";
        case REASON_CLOSE: return "Terminal closed";
        default: return "Unknown reason";
    }
}

void VisualizeLevels() {
    // Clean up old objects
    CleanupChartObjects();
    
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 50;
    
    // Draw Support levels
    for(int i = 0; i < ArraySize(Support); i++) {
        if(Support[i] > 0) {
            string objName = "KAYB_S" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, Support[i], futureTime, Support[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, SupportColor);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
        }
    }
    
    // Draw Resistance levels
    for(int i = 0; i < ArraySize(Resistance); i++) {
        if(Resistance[i] > 0) {
            string objName = "KAYB_R" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, Resistance[i], futureTime, Resistance[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, ResistanceColor);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
        }
    }
}

void DrawFibonacciRetracement() {
    if(SwingHigh[0] > 0 && SwingLow[0] > 0) {
        ObjectCreate(0, "KAYB_Fibo", OBJ_FIBO, 0, TimeCurrent() - PeriodSeconds() * 50, SwingHigh[0], TimeCurrent(), SwingLow[0]);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_WIDTH, 1);
    }
}

void VisualizeZones() {
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    datetime currentTime = TimeCurrent();
    
    // Draw buy zones around support levels
    for(int i = 0; i < ArraySize(Support); i++) {
        if(Support[i] > 0) {
            double zoneLow = Support[i] - LevelProximityPips * _Point;
            double zoneHigh = Support[i] + LevelProximityPips * _Point;
            
            string objName = "KAYB_BuyZone" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_RECTANGLE, 0, currentTime - PeriodSeconds() * 10, zoneLow, currentTime + PeriodSeconds() * 50, zoneHigh);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, BuyZoneColor);
            ObjectSetInteger(0, objName, OBJPROP_FILL, true);
            ObjectSetInteger(0, objName, OBJPROP_BACK, true);
        }
    }
    
    // Draw sell zones around resistance levels
    for(int i = 0; i < ArraySize(Resistance); i++) {
        if(Resistance[i] > 0) {
            double zoneLow = Resistance[i] - LevelProximityPips * _Point;
            double zoneHigh = Resistance[i] + LevelProximityPips * _Point;
            
            string objName = "KAYB_SellZone" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_RECTANGLE, 0, currentTime - PeriodSeconds() * 10, zoneLow, currentTime + PeriodSeconds() * 50, zoneHigh);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, SellZoneColor);
            ObjectSetInteger(0, objName, OBJPROP_FILL, true);
            ObjectSetInteger(0, objName, OBJPROP_BACK, true);
        }
    }
}

void CleanupChartObjects() {
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        if(StringFind(objName, "KAYB_") >= 0) {
            ObjectDelete(0, objName);
        }
    }
}
//+------------------------------------------------------------------+