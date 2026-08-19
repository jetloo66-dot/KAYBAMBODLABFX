//+------------------------------------------------------------------+
//|                                          PriceActionManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs_Version1.mqh"

//+------------------------------------------------------------------+
//| Price Action Manager Class                                       |
//| Encapsulates all price action logic including patterns,          |
//| support/resistance, and market structure                         |
//+------------------------------------------------------------------+
class CPriceActionManager {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    
    // Pattern settings
    double m_pinBarRatio;
    double m_dojiBodyRatio;
    double m_engulfingRatio;
    
    // Level settings
    double m_levelProximityPips;
    int m_swingStrength;
    
    // Market structure
    MarketStructure m_structure;
    
    // Price levels
    PriceLevel m_supportLevels[];
    PriceLevel m_resistanceLevels[];
    PriceLevel m_swingHighs[];
    PriceLevel m_swingLows[];
    
public:
    // Constructor/Destructor
    CPriceActionManager();
    ~CPriceActionManager();
    
    // Initialization
    bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe);
    void SetPatternSettings(double pinBarRatio, double dojiBodyRatio, double engulfingRatio);
    void SetLevelSettings(double proximityPips, int swingStrength);
    
    // Pattern detection methods
    bool IsPinBar(int shift = 0);
    bool IsDoji(int shift = 0);
    bool IsBullishEngulfing(int shift = 0);
    bool IsBearishEngulfing(int shift = 0);
    bool IsHammer(int shift = 0);
    bool IsShootingStar(int shift = 0);
    bool IsInsideBar(int shift = 0);
    bool IsOutsideBar(int shift = 0);
    
    // Pattern analysis
    PatternAnalysis AnalyzePattern(int shift = 0);
    ENUM_CANDLE_PATTERN DetectPattern(int shift = 0);
    double CalculatePatternStrength(ENUM_CANDLE_PATTERN pattern, int shift = 0);
    
    // Support and Resistance detection
    bool DetectSupportResistance(int lookback = 50);
    double FindNearestSupport(double price);
    double FindNearestResistance(double price);
    bool IsPriceNearLevel(double price, double level, double tolerancePips);
    
    // Swing point detection
    bool DetectSwingPoints(int lookback = 50);
    double GetLastSwingHigh();
    double GetLastSwingLow();
    
    // Market structure analysis
    bool AnalyzeMarketStructure(int lookback = 100);
    ENUM_TREND_DIRECTION GetTrendDirection();
    bool IsBreakOfStructure(double price);
    bool IsChangeOfCharacter(double price);
    
    // Higher timeframe analysis
    bool DetectHigherHighs(int lookback = 20);
    bool DetectHigherLows(int lookback = 20);
    bool DetectLowerHighs(int lookback = 20);
    bool DetectLowerLows(int lookback = 20);
    
    // Price rejection analysis
    bool IsPriceRejection(int shift, double level);
    bool IsWickRejection(int shift);
    
    // Fibonacci levels
    bool CalculateFibonacciLevels();
    double GetFibonacciLevel(double ratio);
    
    // Getters for market structure
    MarketStructure GetMarketStructure() const { return m_structure; }
    PriceLevel[] GetSupportLevels() { return m_supportLevels; }
    PriceLevel[] GetResistanceLevels() { return m_resistanceLevels; }
    PriceLevel[] GetSwingHighs() { return m_swingHighs; }
    PriceLevel[] GetSwingLows() { return m_swingLows; }
    
    // Utility methods
    void ClearLevels();
    void PrintStructure();
    
private:
    // Helper methods
    bool GetCandleData(int shift, double &open, double &high, double &low, double &close);
    double GetCandleBody(int shift);
    double GetUpperWick(int shift);
    double GetLowerWick(int shift);
    double GetCandleRange(int shift);
    bool IsBullishCandle(int shift);
    bool IsBearishCandle(int shift);
    double CalculateAverageTrueRange(int periods = 14);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CPriceActionManager::CPriceActionManager() {
    m_symbol = _Symbol;
    m_timeframe = _Period;
    
    m_pinBarRatio = 0.6;
    m_dojiBodyRatio = 0.1;
    m_engulfingRatio = 1.0;
    
    m_levelProximityPips = 5.0;
    m_swingStrength = 5;
    
    // Initialize structure
    m_structure.currentTrend = TREND_NONE;
    m_structure.trendStrength = 0.0;
    m_structure.isStructureValid = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CPriceActionManager::~CPriceActionManager() {
    ClearLevels();
}

//+------------------------------------------------------------------+
//| Initialize price action manager                                  |
//+------------------------------------------------------------------+
bool CPriceActionManager::Initialize(string symbol, ENUM_TIMEFRAMES timeframe) {
    m_symbol = symbol;
    m_timeframe = timeframe;
    
    // Initialize arrays
    ArrayResize(m_supportLevels, 0);
    ArrayResize(m_resistanceLevels, 0);
    ArrayResize(m_swingHighs, 0);
    ArrayResize(m_swingLows, 0);
    
    return true;
}

//+------------------------------------------------------------------+
//| Set pattern detection settings                                   |
//+------------------------------------------------------------------+
void CPriceActionManager::SetPatternSettings(double pinBarRatio, double dojiBodyRatio, double engulfingRatio) {
    m_pinBarRatio = pinBarRatio;
    m_dojiBodyRatio = dojiBodyRatio;
    m_engulfingRatio = engulfingRatio;
}

//+------------------------------------------------------------------+
//| Set level detection settings                                     |
//+------------------------------------------------------------------+
void CPriceActionManager::SetLevelSettings(double proximityPips, int swingStrength) {
    m_levelProximityPips = proximityPips;
    m_swingStrength = swingStrength;
}

//+------------------------------------------------------------------+
//| Get candle data                                                  |
//+------------------------------------------------------------------+
bool CPriceActionManager::GetCandleData(int shift, double &open, double &high, double &low, double &close) {
    double o[], h[], l[], c[];
    
    if(CopyOpen(m_symbol, m_timeframe, shift, 1, o) <= 0 ||
       CopyHigh(m_symbol, m_timeframe, shift, 1, h) <= 0 ||
       CopyLow(m_symbol, m_timeframe, shift, 1, l) <= 0 ||
       CopyClose(m_symbol, m_timeframe, shift, 1, c) <= 0) {
        return false;
    }
    
    open = o[0];
    high = h[0];
    low = l[0];
    close = c[0];
    
    return true;
}

//+------------------------------------------------------------------+
//| Get candle body size                                             |
//+------------------------------------------------------------------+
double CPriceActionManager::GetCandleBody(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0;
    return MathAbs(close - open);
}

//+------------------------------------------------------------------+
//| Get upper wick size                                              |
//+------------------------------------------------------------------+
double CPriceActionManager::GetUpperWick(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0;
    return high - MathMax(open, close);
}

//+------------------------------------------------------------------+
//| Get lower wick size                                              |
//+------------------------------------------------------------------+
double CPriceActionManager::GetLowerWick(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0;
    return MathMin(open, close) - low;
}

//+------------------------------------------------------------------+
//| Get candle range                                                 |
//+------------------------------------------------------------------+
double CPriceActionManager::GetCandleRange(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0;
    return high - low;
}

//+------------------------------------------------------------------+
//| Check if candle is bullish                                       |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsBullishCandle(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    return close > open;
}

//+------------------------------------------------------------------+
//| Check if candle is bearish                                       |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsBearishCandle(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    return close < open;
}

//+------------------------------------------------------------------+
//| Pin Bar Detection                                                |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsPinBar(int shift = 0) {
    double body = GetCandleBody(shift);
    double totalRange = GetCandleRange(shift);
    
    if(totalRange == 0) return false;
    
    double bodyRatio = body / totalRange;
    double upperWick = GetUpperWick(shift);
    double lowerWick = GetLowerWick(shift);
    
    // Bullish Pin Bar (hammer)
    if(lowerWick > body * 2 && upperWick < body && bodyRatio < m_pinBarRatio) {
        return true;
    }
    
    // Bearish Pin Bar (shooting star)
    if(upperWick > body * 2 && lowerWick < body && bodyRatio < m_pinBarRatio) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Doji Detection                                                   |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsDoji(int shift = 0) {
    double body = GetCandleBody(shift);
    double totalRange = GetCandleRange(shift);
    
    if(totalRange == 0) return false;
    
    double bodyRatio = body / totalRange;
    
    return bodyRatio <= m_dojiBodyRatio;
}

//+------------------------------------------------------------------+
//| Bullish Engulfing Detection                                      |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsBullishEngulfing(int shift = 0) {
    double o1, h1, l1, c1, o2, h2, l2, c2;
    
    if(!GetCandleData(shift, o1, h1, l1, c1) ||
       !GetCandleData(shift + 1, o2, h2, l2, c2)) {
        return false;
    }
    
    return (c2 < o2) && (c1 > o1) && (o1 < c2) && (c1 > o2) && 
           ((c1 - o1) > m_engulfingRatio * (o2 - c2));
}

//+------------------------------------------------------------------+
//| Bearish Engulfing Detection                                      |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsBearishEngulfing(int shift = 0) {
    double o1, h1, l1, c1, o2, h2, l2, c2;
    
    if(!GetCandleData(shift, o1, h1, l1, c1) ||
       !GetCandleData(shift + 1, o2, h2, l2, c2)) {
        return false;
    }
    
    return (c2 > o2) && (c1 < o1) && (o1 > c2) && (c1 < o2) && 
           ((o1 - c1) > m_engulfingRatio * (c2 - o2));
}

//+------------------------------------------------------------------+
//| Hammer Detection                                                 |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsHammer(int shift = 0) {
    double body = GetCandleBody(shift);
    double lowerWick = GetLowerWick(shift);
    double upperWick = GetUpperWick(shift);
    
    return (lowerWick > body * 2) && (upperWick < body * 0.5) && IsBullishCandle(shift);
}

//+------------------------------------------------------------------+
//| Shooting Star Detection                                          |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsShootingStar(int shift = 0) {
    double body = GetCandleBody(shift);
    double upperWick = GetUpperWick(shift);
    double lowerWick = GetLowerWick(shift);
    
    return (upperWick > body * 2) && (lowerWick < body * 0.5) && IsBearishCandle(shift);
}

//+------------------------------------------------------------------+
//| Inside Bar Detection                                             |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsInsideBar(int shift = 0) {
    double o1, h1, l1, c1, o2, h2, l2, c2;
    
    if(!GetCandleData(shift, o1, h1, l1, c1) ||
       !GetCandleData(shift + 1, o2, h2, l2, c2)) {
        return false;
    }
    
    return (h1 < h2 && l1 > l2);
}

//+------------------------------------------------------------------+
//| Outside Bar Detection                                            |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsOutsideBar(int shift = 0) {
    double o1, h1, l1, c1, o2, h2, l2, c2;
    
    if(!GetCandleData(shift, o1, h1, l1, c1) ||
       !GetCandleData(shift + 1, o2, h2, l2, c2)) {
        return false;
    }
    
    return (h1 > h2 && l1 < l2);
}

//+------------------------------------------------------------------+
//| Detect pattern at specific shift                                 |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CPriceActionManager::DetectPattern(int shift = 0) {
    if(IsDoji(shift)) return PATTERN_DOJI;
    if(IsHammer(shift)) return PATTERN_HAMMER;
    if(IsShootingStar(shift)) return PATTERN_SHOOTING_STAR;
    if(IsBullishEngulfing(shift)) return PATTERN_BULLISH_ENGULFING;
    if(IsBearishEngulfing(shift)) return PATTERN_BEARISH_ENGULFING;
    if(IsPinBar(shift)) return PATTERN_PIN_BAR;
    if(IsInsideBar(shift)) return PATTERN_INSIDE_BAR;
    if(IsOutsideBar(shift)) return PATTERN_OUTSIDE_BAR;
    
    return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Analyze pattern                                                  |
//+------------------------------------------------------------------+
PatternAnalysis CPriceActionManager::AnalyzePattern(int shift = 0) {
    PatternAnalysis analysis;
    analysis.pattern = DetectPattern(shift);
    analysis.isValid = (analysis.pattern != PATTERN_NONE);
    analysis.barIndex = shift;
    analysis.timestamp = iTime(m_symbol, m_timeframe, shift);
    analysis.strength = CalculatePatternStrength(analysis.pattern, shift);
    analysis.reliability = 0.7; // Default reliability
    
    // Determine if bullish or bearish
    analysis.isBullish = (analysis.pattern == PATTERN_HAMMER || 
                         analysis.pattern == PATTERN_BULLISH_ENGULFING);
    
    return analysis;
}

//+------------------------------------------------------------------+
//| Calculate pattern strength                                       |
//+------------------------------------------------------------------+
double CPriceActionManager::CalculatePatternStrength(ENUM_CANDLE_PATTERN pattern, int shift = 0) {
    if(pattern == PATTERN_NONE) return 0.0;
    
    double strength = 0.5; // Base strength
    
    // Increase strength based on candle size relative to ATR
    double atr = CalculateAverageTrueRange(14);
    double candleRange = GetCandleRange(shift);
    
    if(atr > 0) {
        double sizeRatio = candleRange / atr;
        strength += MathMin(0.3, sizeRatio * 0.1);
    }
    
    return MathMin(1.0, strength);
}

//+------------------------------------------------------------------+
//| Calculate Average True Range                                     |
//+------------------------------------------------------------------+
double CPriceActionManager::CalculateAverageTrueRange(int periods = 14) {
    double high[], low[], close[];
    
    if(CopyHigh(m_symbol, m_timeframe, 0, periods + 1, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, 0, periods + 1, low) <= 0 ||
       CopyClose(m_symbol, m_timeframe, 0, periods + 1, close) <= 0) {
        return 0.0;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    double sum = 0.0;
    for(int i = 0; i < periods; i++) {
        double tr = MathMax(high[i] - low[i], 
                   MathMax(MathAbs(high[i] - close[i + 1]), 
                          MathAbs(low[i] - close[i + 1])));
        sum += tr;
    }
    
    return sum / periods;
}

//+------------------------------------------------------------------+
//| Detect support and resistance levels                             |
//+------------------------------------------------------------------+
bool CPriceActionManager::DetectSupportResistance(int lookback = 50) {
    double high[], low[], close[];
    
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0 ||
       CopyClose(m_symbol, m_timeframe, 0, lookback, close) <= 0) {
        return false;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    // Clear existing levels
    ArrayResize(m_supportLevels, 0);
    ArrayResize(m_resistanceLevels, 0);
    
    double tolerance = m_levelProximityPips * _Point;
    
    // Find support levels
    for(int i = 1; i < lookback - 1; i++) {
        int touchCount = 0;
        for(int j = 0; j < lookback; j++) {
            if(MathAbs(low[j] - low[i]) <= tolerance) {
                touchCount++;
            }
        }
        
        if(touchCount >= 2) {
            PriceLevel level;
            level.price = low[i];
            level.timestamp = iTime(m_symbol, m_timeframe, i);
            level.strength = touchCount;
            level.touches = touchCount;
            level.isValid = true;
            level.type = "SUPPORT";
            level.timeframe = m_timeframe;
            
            int size = ArraySize(m_supportLevels);
            ArrayResize(m_supportLevels, size + 1);
            m_supportLevels[size] = level;
        }
    }
    
    // Find resistance levels
    for(int i = 1; i < lookback - 1; i++) {
        int touchCount = 0;
        for(int j = 0; j < lookback; j++) {
            if(MathAbs(high[j] - high[i]) <= tolerance) {
                touchCount++;
            }
        }
        
        if(touchCount >= 2) {
            PriceLevel level;
            level.price = high[i];
            level.timestamp = iTime(m_symbol, m_timeframe, i);
            level.strength = touchCount;
            level.touches = touchCount;
            level.isValid = true;
            level.type = "RESISTANCE";
            level.timeframe = m_timeframe;
            
            int size = ArraySize(m_resistanceLevels);
            ArrayResize(m_resistanceLevels, size + 1);
            m_resistanceLevels[size] = level;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Find nearest support level                                       |
//+------------------------------------------------------------------+
double CPriceActionManager::FindNearestSupport(double price) {
    double nearest = 0.0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < ArraySize(m_supportLevels); i++) {
        if(m_supportLevels[i].price < price) {
            double distance = price - m_supportLevels[i].price;
            if(distance < minDistance) {
                minDistance = distance;
                nearest = m_supportLevels[i].price;
            }
        }
    }
    
    return nearest;
}

//+------------------------------------------------------------------+
//| Find nearest resistance level                                    |
//+------------------------------------------------------------------+
double CPriceActionManager::FindNearestResistance(double price) {
    double nearest = 0.0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < ArraySize(m_resistanceLevels); i++) {
        if(m_resistanceLevels[i].price > price) {
            double distance = m_resistanceLevels[i].price - price;
            if(distance < minDistance) {
                minDistance = distance;
                nearest = m_resistanceLevels[i].price;
            }
        }
    }
    
    return nearest;
}

//+------------------------------------------------------------------+
//| Check if price is near a level                                   |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsPriceNearLevel(double price, double level, double tolerancePips) {
    double tolerance = tolerancePips * _Point;
    return MathAbs(price - level) <= tolerance;
}

//+------------------------------------------------------------------+
//| Detect swing points                                              |
//+------------------------------------------------------------------+
bool CPriceActionManager::DetectSwingPoints(int lookback = 50) {
    double high[], low[];
    
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) {
        return false;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    // Clear existing swings
    ArrayResize(m_swingHighs, 0);
    ArrayResize(m_swingLows, 0);
    
    // Detect swing highs
    for(int i = m_swingStrength; i < lookback - m_swingStrength; i++) {
        bool isSwingHigh = true;
        for(int j = i - m_swingStrength; j <= i + m_swingStrength; j++) {
            if(j != i && high[j] >= high[i]) {
                isSwingHigh = false;
                break;
            }
        }
        
        if(isSwingHigh) {
            PriceLevel level;
            level.price = high[i];
            level.timestamp = iTime(m_symbol, m_timeframe, i);
            level.strength = m_swingStrength;
            level.isValid = true;
            level.type = "SWING_HIGH";
            level.timeframe = m_timeframe;
            
            int size = ArraySize(m_swingHighs);
            ArrayResize(m_swingHighs, size + 1);
            m_swingHighs[size] = level;
        }
    }
    
    // Detect swing lows
    for(int i = m_swingStrength; i < lookback - m_swingStrength; i++) {
        bool isSwingLow = true;
        for(int j = i - m_swingStrength; j <= i + m_swingStrength; j++) {
            if(j != i && low[j] <= low[i]) {
                isSwingLow = false;
                break;
            }
        }
        
        if(isSwingLow) {
            PriceLevel level;
            level.price = low[i];
            level.timestamp = iTime(m_symbol, m_timeframe, i);
            level.strength = m_swingStrength;
            level.isValid = true;
            level.type = "SWING_LOW";
            level.timeframe = m_timeframe;
            
            int size = ArraySize(m_swingLows);
            ArrayResize(m_swingLows, size + 1);
            m_swingLows[size] = level;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get last swing high                                              |
//+------------------------------------------------------------------+
double CPriceActionManager::GetLastSwingHigh() {
    int size = ArraySize(m_swingHighs);
    if(size > 0) {
        return m_swingHighs[0].price;
    }
    return 0.0;
}

//+------------------------------------------------------------------+
//| Get last swing low                                               |
//+------------------------------------------------------------------+
double CPriceActionManager::GetLastSwingLow() {
    int size = ArraySize(m_swingLows);
    if(size > 0) {
        return m_swingLows[0].price;
    }
    return 0.0;
}

//+------------------------------------------------------------------+
//| Analyze market structure                                         |
//+------------------------------------------------------------------+
bool CPriceActionManager::AnalyzeMarketStructure(int lookback = 100) {
    // Detect swing points first
    if(!DetectSwingPoints(lookback)) {
        return false;
    }
    
    // Analyze trend direction based on swing points
    int swingHighCount = ArraySize(m_swingHighs);
    int swingLowCount = ArraySize(m_swingLows);
    
    if(swingHighCount >= 2 && swingLowCount >= 2) {
        // Check for higher highs and higher lows (uptrend)
        if(m_swingHighs[0].price > m_swingHighs[1].price &&
           m_swingLows[0].price > m_swingLows[1].price) {
            m_structure.currentTrend = TREND_UP;
            m_structure.trendStrength = 0.8;
        }
        // Check for lower lows and lower highs (downtrend)
        else if(m_swingHighs[0].price < m_swingHighs[1].price &&
                m_swingLows[0].price < m_swingLows[1].price) {
            m_structure.currentTrend = TREND_DOWN;
            m_structure.trendStrength = 0.8;
        }
        else {
            m_structure.currentTrend = TREND_SIDEWAYS;
            m_structure.trendStrength = 0.5;
        }
    }
    
    m_structure.isStructureValid = true;
    m_structure.lastUpdate = TimeCurrent();
    
    return true;
}

//+------------------------------------------------------------------+
//| Get trend direction                                              |
//+------------------------------------------------------------------+
ENUM_TREND_DIRECTION CPriceActionManager::GetTrendDirection() {
    return m_structure.currentTrend;
}

//+------------------------------------------------------------------+
//| Check for break of structure                                     |
//+------------------------------------------------------------------+
bool CPriceActionManager::IsBreakOfStructure(double price) {
    if(m_structure.currentTrend == TREND_UP) {
        // In uptrend, BOS occurs when price breaks below recent swing low
        double lastSwingLow = GetLastSwingLow();
        return (price < lastSwingLow);
    }
    else if(m_structure.currentTrend == TREND_DOWN) {
        // In downtrend, BOS occurs when price breaks above recent swing high
        double lastSwingHigh = GetLastSwingHigh();
        return (price > lastSwingHigh);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Clear all price levels                                           |
//+------------------------------------------------------------------+
void CPriceActionManager::ClearLevels() {
    ArrayFree(m_supportLevels);
    ArrayFree(m_resistanceLevels);
    ArrayFree(m_swingHighs);
    ArrayFree(m_swingLows);
}

//+------------------------------------------------------------------+
//| Print market structure                                           |
//+------------------------------------------------------------------+
void CPriceActionManager::PrintStructure() {
    Print("=== Market Structure ===");
    Print("Trend: ", EnumToString(m_structure.currentTrend));
    Print("Trend Strength: ", m_structure.trendStrength);
    Print("Support Levels: ", ArraySize(m_supportLevels));
    Print("Resistance Levels: ", ArraySize(m_resistanceLevels));
    Print("Swing Highs: ", ArraySize(m_swingHighs));
    Print("Swing Lows: ", ArraySize(m_swingLows));
    Print("========================");
}
