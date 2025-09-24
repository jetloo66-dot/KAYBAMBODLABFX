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
CTrade trade;
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
    trade.SetExpertMagicNumber(Magic);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(_Symbol);
    
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
    
    Print("KAYBAMBODLABFX MultiStrategy EA initialized successfully");
    
    if(SendTelegramNotifications && TelegramBotToken != "" && TelegramChatID != "") {
        SendTelegramMessage("🤖 KAYBAMBODLABFX EA Started on " + _Symbol);
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Clean up chart objects
    ObjectsDeleteAll(0, "KAYB_");
    
    if(SendTelegramNotifications && TelegramBotToken != "" && TelegramChatID != "") {
        SendTelegramMessage("🛑 KAYBAMBODLABFX EA Stopped on " + _Symbol);
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if it's time for market scan
    if(TimeCurrent() - LastScanTime >= ScanIntervalMinutes * 60) {
        PerformMarketAnalysis();
        LastScanTime = TimeCurrent();
    }
    
    // Manage existing positions
    ManageTrailingStop();
    
    // Check for new trade opportunities
    CheckTradeConditions();
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
    
    // Draw Fibonacci retracement
    if(ShowFibonacci) {
        DrawFibonacciRetracement();
    }
    
    // Visualize levels and zones
    if(ShowLevels) {
        VisualizeLevels();
    }
    
    if(ShowZones) {
        VisualizeZones();
    }
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
    // Uptrend conditions
    bool uptrend = (HigherHigh[0] > HigherHigh[1] && 
                   HigherLow[0] > HigherLow[1] && 
                   SwingHigh[0] > SwingHigh[1] && 
                   SwingLow[0] > SwingLow[1]);
    
    // Downtrend conditions  
    bool downtrend = (HigherHigh[0] < HigherHigh[1] && 
                     HigherLow[0] < HigherLow[1] && 
                     SwingHigh[0] < SwingHigh[1] && 
                     SwingLow[0] < SwingLow[1]);
    
    if(uptrend) {
        CurrentTrend = TREND_UP;
    } else if(downtrend) {
        CurrentTrend = TREND_DOWN;
    } else {
        CurrentTrend = TREND_SIDEWAYS;
    }
}

//+------------------------------------------------------------------+
//| Check for trade conditions and execute trades                    |
//+------------------------------------------------------------------+
void CheckTradeConditions() {
    if(UseNewsFilter && IsNewsTime()) {
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
        }
        
        // Doji Detection
        if(IsDoji(high[i], low[i], open[i], close[i])) {
            patterns.Doji = true;
            patterns.ConfirmationIndex = i;
            patterns.ConfirmationLevel = close[i];
        }
        
        // Engulfing Patterns
        if(i > 0) {
            if(IsBullishEngulfing(high[i], low[i], open[i], close[i], 
                                high[i+1], low[i+1], open[i+1], close[i+1])) {
                patterns.BullishEngulfing = true;
                patterns.ConfirmationIndex = i;
                patterns.ConfirmationLevel = close[i+1];
            }
            
            if(IsBearishEngulfing(high[i], low[i], open[i], close[i], 
                                high[i+1], low[i+1], open[i+1], close[i+1])) {
                patterns.BearishEngulfing = true;
                patterns.ConfirmationIndex = i;
                patterns.ConfirmationLevel = close[i+1];
            }
        }
        
        // Break of Structure Detection
        if(IsBreakOfStructure(high, low, i)) {
            patterns.BreakOfStructure = true;
        }
        
        // Retracement Detection
        if(IsRetracement(close, patterns.ConfirmationLevel, i)) {
            patterns.Retracement = true;
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
    
    // Similar sequences as buy but with bearish patterns
    // Sequence I: (a) then (c) then (d) then (e)
    if(patterns.PinBar && patterns.BearishEngulfing && patterns.BreakOfStructure && patterns.Retracement) {
        return true;
    }
    
    // Add other sequences similar to buy logic but with bearish conditions
    // ... (implement all sequences)
    
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
    if(PositionsTotal() > 0) return; // Only one position at a time
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = price - StopLossPips * _Point;
    double tp = price + TakeProfitPips * _Point;
    
    if(trade.Buy(LotSize, _Symbol, price, sl, tp, "KAYB Buy Signal")) {
        string message = "🟢 BUY ORDER EXECUTED\n";
        message += "Symbol: " + _Symbol + "\n";
        message += "Price: " + DoubleToString(price, _Digits) + "\n";
        message += "SL: " + DoubleToString(sl, _Digits) + "\n";
        message += "TP: " + DoubleToString(tp, _Digits) + "\n";
        message += "Lot: " + DoubleToString(LotSize, 2) + "\n";
        message += "Trend: UPTREND\n";
        message += GetPatternDescription(patterns);
        
        SendTelegramMessage(message);
    }
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                               |
//+------------------------------------------------------------------+
void ExecuteSellTrade(PatternInfo &patterns) {
    if(PositionsTotal() > 0) return; // Only one position at a time
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = price + StopLossPips * _Point;
    double tp = price - TakeProfitPips * _Point;
    
    if(trade.Sell(LotSize, _Symbol, price, sl, tp, "KAYB Sell Signal")) {
        string message = "🔴 SELL ORDER EXECUTED\n";
        message += "Symbol: " + _Symbol + "\n";
        message += "Price: " + DoubleToString(price, _Digits) + "\n";
        message += "SL: " + DoubleToString(sl, _Digits) + "\n";
        message += "TP: " + DoubleToString(tp, _Digits) + "\n";
        message += "Lot: " + DoubleToString(LotSize, 2) + "\n";
        message += "Trend: DOWNTREND\n";
        message += GetPatternDescription(patterns);
        
        SendTelegramMessage(message);
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
//| Manage Trailing Stop                                             |
//+------------------------------------------------------------------+
void ManageTrailingStop() {
    if(!UseTrailingStop) return;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == Magic) {
                double currentSL = PositionGetDouble(POSITION_SL);
                double currentPrice;
                double newSL;
                
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
//| News Filter                                                      |
//+------------------------------------------------------------------+
bool IsNewsTime() {
    // Simplified news filter - can be enhanced with calendar data
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    // Avoid trading during typical news release hours
    if((dt.hour >= 8 && dt.hour <= 10) ||   // London/NY overlap
       (dt.hour >= 13 && dt.hour <= 15)) {   // NY session major news
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Draw Fibonacci Retracement                                       |
//+------------------------------------------------------------------+
void DrawFibonacciRetracement() {
    ObjectDelete(0, "KAYB_Fibo");
    
    if(CurrentTrend == TREND_UP && SwingLow[1] > 0 && SwingHigh[0] > 0) {
        // Uptrend: From previous Swing Low to recent Swing High
        ObjectCreate(0, "KAYB_Fibo", OBJ_FIBO, 0, 
                    iTime(_Symbol, _Period, 10), SwingLow[1],
                    iTime(_Symbol, _Period, 0), SwingHigh[0]);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_WIDTH, 1);
        
    } else if(CurrentTrend == TREND_DOWN && SwingHigh[1] > 0 && SwingLow[0] > 0) {
        // Downtrend: From previous Swing High to recent Swing Low
        ObjectCreate(0, "KAYB_Fibo", OBJ_FIBO, 0,
                    iTime(_Symbol, _Period, 10), SwingHigh[1],
                    iTime(_Symbol, _Period, 0), SwingLow[0]);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_COLOR, clrYellow);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, "KAYB_Fibo", OBJPROP_WIDTH, 1);
    }
}

//+------------------------------------------------------------------+
//| Visualize Support/Resistance Levels                             |
//+------------------------------------------------------------------+
void VisualizeLevels() {
    // Clean up old objects
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        if(StringFind(objName, "KAYB_Level_") >= 0) {
            ObjectDelete(0, objName);
        }
    }
    
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 50;
    
    // Draw Support levels
    for(int i = 0; i < ArraySize(Support); i++) {
        if(Support[i] > 0) {
            string objName = "KAYB_Level_S" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, Support[i], futureTime, Support[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, SupportColor);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "S[" + IntegerToString(i) + "]");
        }
    }
    
    // Draw Resistance levels
    for(int i = 0; i < ArraySize(Resistance); i++) {
        if(Resistance[i] > 0) {
            string objName = "KAYB_Level_R" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, Resistance[i], futureTime, Resistance[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, ResistanceColor);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "R[" + IntegerToString(i) + "]");
        }
    }
    
    // Draw Swing levels
    for(int i = 0; i < ArraySize(SwingHigh); i++) {
        if(SwingHigh[i] > 0) {
            string objName = "KAYB_Level_SH" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, SwingHigh[i], futureTime, SwingHigh[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrOrange);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "SH[" + IntegerToString(i) + "]");
        }
    }
    
    for(int i = 0; i < ArraySize(SwingLow); i++) {
        if(SwingLow[i] > 0) {
            string objName = "KAYB_Level_SL" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, SwingLow[i], futureTime, SwingLow[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrCyan);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "SL[" + IntegerToString(i) + "]");
        }
    }
}

//+------------------------------------------------------------------+
//| Visualize Buy/Sell Zones                                        |
//+------------------------------------------------------------------+
void VisualizeZones() {
    // Clean up old zones
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        if(StringFind(objName, "KAYB_Zone_") >= 0) {
            ObjectDelete(0, objName);
        }
    }
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double pipDistance = LevelProximityPips * _Point;
    
    // Create buy zones
    if(Support[0] > 0) {
        CreateZone("KAYB_Zone_BuySupport", Support[0] - pipDistance, Support[0] + pipDistance, BuyZoneColor);
    }
    
    if(HigherLow[0] > 0) {
        CreateZone("KAYB_Zone_BuyHL", HigherLow[0] - pipDistance, HigherLow[0] + pipDistance, BuyZoneColor);
    }
    
    if(SwingLow[0] > 0) {
        CreateZone("KAYB_Zone_BuySL", SwingLow[0] - pipDistance, SwingLow[0] + pipDistance, BuyZoneColor);
    }
    
    // Create sell zones
    if(Resistance[0] > 0) {
        CreateZone("KAYB_Zone_SellResistance", Resistance[0] - pipDistance, Resistance[0] + pipDistance, SellZoneColor);
    }
    
    if(LowerHigh[0] > 0) {
        CreateZone("KAYB_Zone_SellLH", LowerHigh[0] - pipDistance, LowerHigh[0] + pipDistance, SellZoneColor);
    }
    
    if(SwingHigh[0] > 0) {
        CreateZone("KAYB_Zone_SellSH", SwingHigh[0] - pipDistance, SwingHigh[0] + pipDistance, SellZoneColor);
    }
}

//+------------------------------------------------------------------+
//| Create Zone Rectangle                                            |
//+------------------------------------------------------------------+
void CreateZone(string name, double price1, double price2, color zoneColor) {
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 50;
    
    ObjectCreate(0, name, OBJ_RECTANGLE, 0, currentTime, price1, futureTime, price2);
    ObjectSetInteger(0, name, OBJPROP_COLOR, zoneColor);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_FILL, true);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
//| Send Telegram Message                                            |
//+------------------------------------------------------------------+
void SendTelegramMessage(string message) {
    if(!SendTelegramNotifications || TelegramBotToken == "" || TelegramChatID == "") {
        return;
    }
    
    string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
    string payload = "chat_id=" + TelegramChatID + "&text=" + message;
    
    char post[], result[];
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    
    StringToCharArray(payload, post, 0, StringLen(payload));
    
    int timeout = 5000; // 5 seconds timeout
    int res = WebRequest("POST", url, headers, timeout, post, result, headers);
    
    if(res == -1) {
        Print("Telegram notification failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+