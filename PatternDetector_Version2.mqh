//+------------------------------------------------------------------+
//|                                             PatternDetector.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Pattern Detection Class                                          |
//+------------------------------------------------------------------+
class CPatternDetector {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_lookbackBars;
    double m_minPatternStrength;
    datetime m_lastAnalysis;
    
    // Pattern cache
    struct PatternData {
        ENUM_PATTERN_TYPE pattern;
        int barIndex;
        double strength;
        double reliability;
        datetime timestamp;
        bool isValid;
    };
    
    PatternData m_patternHistory[];
    int m_historySize;
    
public:
    // Constructor/Destructor
    CPatternDetector(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
    ~CPatternDetector();
    
    // Initialization
    bool Initialize(int lookbackBars = 100, double minStrength = 0.5);
    
    // Core detection methods
    ENUM_PATTERN_TYPE DetectPattern(int shift = 0);
    bool ValidateCurrentPattern();
    double GetPatternReliability(ENUM_PATTERN_TYPE pattern);
    
    // Specialized pattern detection
    bool IsDoji(int shift = 0, double maxBodyRatio = 0.1);
    bool IsHammer(int shift = 0);
    bool IsShootingStar(int shift = 0);
    bool IsEngulfing(int shift = 0, bool bullish = true);
    bool IsPinBar(int shift = 0, double minWickRatio = 2.0);
    bool IsInsideBar(int shift = 0);
    bool IsOutsideBar(int shift = 0);
    bool IsThreeWhiteSoldiers(int shift = 0);
    bool IsThreeBlackCrows(int shift = 0);
    bool IsMorningStar(int shift = 0);
    bool IsEveningStar(int shift = 0);
    bool IsHarami(int shift = 0);
    
    // Advanced pattern methods
    bool DetectHarmonicPattern(string patternType = "GARTLEY");
    bool DetectElliottWave();
    bool IsFibonacciPattern(double level = 0.618);
    
    // Signal generation
    SignalInfo GetCurrentSignal();
    
    // Main analysis method
    void AnalyzePatterns();
    
    // Utility methods
    double CalculatePatternStrength(ENUM_PATTERN_TYPE pattern, int shift = 0);
    bool ValidatePattern(ENUM_PATTERN_TYPE pattern, int shift = 0);
    string GetPatternName(ENUM_PATTERN_TYPE pattern);
    void ClearHistory();
    
private:
    // Helper methods
    bool GetCandleData(int shift, double &open, double &high, double &low, double &close);
    double GetCandleBody(int shift);
    double GetUpperWick(int shift);
    double GetLowerWick(int shift);
    double GetCandleRange(int shift);
    bool IsBullishCandle(int shift);
    bool IsBearishCandle(int shift);
    double GetAverageRange(int periods = 14);
    bool IsSignificantCandle(int shift, double multiplier = 1.5);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPatternDetector::CPatternDetector(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
    m_symbol = (symbol == "") ? _Symbol : symbol;
    m_timeframe = (timeframe == PERIOD_CURRENT) ? _Period : timeframe;
    m_lookbackBars = 100;
    m_minPatternStrength = 0.5;
    m_lastAnalysis = 0;
    m_historySize = 0;
    
    ArrayResize(m_patternHistory, 50);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPatternDetector::~CPatternDetector() {
    ArrayFree(m_patternHistory);
}

//+------------------------------------------------------------------+
//| Initialize pattern detector                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::Initialize(int lookbackBars = 100, double minStrength = 0.5) {
    m_lookbackBars = lookbackBars;
    m_minPatternStrength = minStrength;
    
    // Clear history
    ClearHistory();
    
    Print("Pattern Detector initialized for ", m_symbol, " on ", EnumToString(m_timeframe));
    return true;
}

//+------------------------------------------------------------------+
//| Main pattern detection method                                    |
//+------------------------------------------------------------------+
ENUM_PATTERN_TYPE CPatternDetector::DetectPattern(int shift = 0) {
    // Check single candle patterns first
    if(IsDoji(shift)) return PATTERN_DOJI;
    if(IsHammer(shift)) return PATTERN_HAMMER;
    if(IsShootingStar(shift)) return PATTERN_SHOOTING_STAR;
    if(IsPinBar(shift)) return PATTERN_PIN_BAR;
    
    // Check two-candle patterns
    if(IsEngulfing(shift, true)) return PATTERN_BULLISH_ENGULFING;
    if(IsEngulfing(shift, false)) return PATTERN_BEARISH_ENGULFING;
    
    return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Validate current pattern                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidateCurrentPattern() {
    ENUM_PATTERN_TYPE pattern = DetectPattern(0);
    return ValidatePattern(pattern, 0);
}

//+------------------------------------------------------------------+
//| Get pattern reliability                                          |
//+------------------------------------------------------------------+
double CPatternDetector::GetPatternReliability(ENUM_PATTERN_TYPE pattern) {
    switch(pattern) {
        case PATTERN_DOJI: return 0.6;
        case PATTERN_HAMMER: return 0.75;
        case PATTERN_SHOOTING_STAR: return 0.75;
        case PATTERN_BULLISH_ENGULFING: return 0.8;
        case PATTERN_BEARISH_ENGULFING: return 0.8;
        case PATTERN_PIN_BAR: return 0.7;
        default: return 0.0;
    }
}

//+------------------------------------------------------------------+
//| Doji pattern detection                                           |
//+------------------------------------------------------------------+
bool CPatternDetector::IsDoji(int shift = 0, double maxBodyRatio = 0.1) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double range = high - low;
    
    if(range == 0) return false;
    
    return (body / range <= maxBodyRatio);
}

//+------------------------------------------------------------------+
//| Hammer pattern detection                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::IsHammer(int shift = 0) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double lowerWick = MathMin(open, close) - low;
    double upperWick = high - MathMax(open, close);
    
    // Hammer criteria: long lower wick, small body, small upper wick
    return (lowerWick >= body * 2 && upperWick <= body * 0.5 && body > 0);
}

//+------------------------------------------------------------------+
//| Shooting Star pattern detection                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::IsShootingStar(int shift = 0) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double lowerWick = MathMin(open, close) - low;
    double upperWick = high - MathMax(open, close);
    
    // Shooting star criteria: long upper wick, small body, small lower wick
    return (upperWick >= body * 2 && lowerWick <= body * 0.5 && body > 0);
}

//+------------------------------------------------------------------+
//| Engulfing pattern detection                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::IsEngulfing(int shift = 0, bool bullish = true) {
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(shift, open1, high1, low1, close1) ||
       !GetCandleData(shift + 1, open2, high2, low2, close2)) {
        return false;
    }
    
    if(bullish) {
        // Bullish engulfing: bearish candle followed by bullish engulfing candle
        return (close2 < open2 && close1 > open1 && 
                open1 < close2 && close1 > open2);
    } else {
        // Bearish engulfing: bullish candle followed by bearish engulfing candle
        return (close2 > open2 && close1 < open1 && 
                open1 > close2 && close1 < open2);
    }
}

//+------------------------------------------------------------------+
//| Pin Bar pattern detection                                        |
//+------------------------------------------------------------------+
bool CPatternDetector::IsPinBar(int shift = 0, double minWickRatio = 2.0) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double lowerWick = MathMin(open, close) - low;
    double upperWick = high - MathMax(open, close);
    double range = high - low;
    
    if(range == 0 || body == 0) return false;
    
    // Pin bar criteria: significant wick on one side, small body
    bool hasSignificantWick = (lowerWick >= body * minWickRatio || upperWick >= body * minWickRatio);
    bool hasSmallBody = (body / range < 0.3);
    
    return hasSignificantWick && hasSmallBody;
}

//+------------------------------------------------------------------+
//| Inside Bar pattern detection                                     |
//+------------------------------------------------------------------+
bool CPatternDetector::IsInsideBar(int shift = 0) {
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(shift, open1, high1, low1, close1) ||
       !GetCandleData(shift + 1, open2, high2, low2, close2)) {
        return false;
    }
    
    // Inside bar: current bar's range is within previous bar's range
    return (high1 <= high2 && low1 >= low2);
}

//+------------------------------------------------------------------+
//| Outside Bar pattern detection                                    |
//+------------------------------------------------------------------+
bool CPatternDetector::IsOutsideBar(int shift = 0) {
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(shift, open1, high1, low1, close1) ||
       !GetCandleData(shift + 1, open2, high2, low2, close2)) {
        return false;
    }
    
    // Outside bar: current bar's range engulfs previous bar's range
    return (high1 > high2 && low1 < low2);
}

//+------------------------------------------------------------------+
//| Three White Soldiers pattern detection                          |
//+------------------------------------------------------------------+
bool CPatternDetector::IsThreeWhiteSoldiers(int shift = 0) {
    for(int i = 0; i < 3; i++) {
        if(!IsBullishCandle(shift + i)) return false;
        
        if(i > 0) {
            double open1, high1, low1, close1;
            double open2, high2, low2, close2;
            
            if(!GetCandleData(shift + i - 1, open1, high1, low1, close1) ||
               !GetCandleData(shift + i, open2, high2, low2, close2)) {
                return false;
            }
            
            // Each candle should close higher than the previous
            if(close1 <= close2 || open1 <= open2) return false;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| Three Black Crows pattern detection                             |
//+------------------------------------------------------------------+
bool CPatternDetector::IsThreeBlackCrows(int shift = 0) {
    for(int i = 0; i < 3; i++) {
        if(!IsBearishCandle(shift + i)) return false;
        
        if(i > 0) {
            double open1, high1, low1, close1;
            double open2, high2, low2, close2;
            
            if(!GetCandleData(shift + i - 1, open1, high1, low1, close1) ||
               !GetCandleData(shift + i, open2, high2, low2, close2)) {
                return false;
            }
            
            // Each candle should close lower than the previous
            if(close1 >= close2 || open1 >= open2) return false;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| Morning Star pattern detection                                   |
//+------------------------------------------------------------------+
bool CPatternDetector::IsMorningStar(int shift = 0) {
    // Three candle pattern: bearish, small body, bullish
    if(!IsBearishCandle(shift + 2)) return false; // First candle bearish
    if(!IsBullishCandle(shift)) return false;     // Third candle bullish
    if(!IsDoji(shift + 1)) return false;          // Middle candle small body
    
    double open1, high1, low1, close1; // Third candle (bullish)
    double close3, open3;              // First candle (bearish)
    
    if(!GetCandleData(shift, open1, high1, low1, close1) ||
       !GetCandleData(shift + 2, open3, high1, low1, close3)) {
        return false;
    }
    
    // Third candle should close above midpoint of first candle
    return close1 > (open3 + close3) / 2;
}

//+------------------------------------------------------------------+
//| Evening Star pattern detection                                   |
//+------------------------------------------------------------------+
bool CPatternDetector::IsEveningStar(int shift = 0) {
    // Three candle pattern: bullish, small body, bearish
    if(!IsBullishCandle(shift + 2)) return false; // First candle bullish
    if(!IsBearishCandle(shift)) return false;     // Third candle bearish
    if(!IsDoji(shift + 1)) return false;          // Middle candle small body
    
    double open1, high1, low1, close1; // Third candle (bearish)
    double close3, open3;              // First candle (bullish)
    
    if(!GetCandleData(shift, open1, high1, low1, close1) ||
       !GetCandleData(shift + 2, open3, high1, low1, close3)) {
        return false;
    }
    
    // Third candle should close below midpoint of first candle
    return close1 < (open3 + close3) / 2;
}

//+------------------------------------------------------------------+
//| Harami pattern detection                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::IsHarami(int shift = 0) {
    return IsInsideBar(shift); // Harami is essentially an inside bar
}

//+------------------------------------------------------------------+
//| Detect harmonic patterns                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectHarmonicPattern(string patternType = "GARTLEY") {
    // Simplified harmonic pattern detection
    // In practice, this would involve complex Fibonacci ratio calculations
    return false; // Placeholder implementation
}

//+------------------------------------------------------------------+
//| Detect Elliott Wave patterns                                     |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectElliottWave() {
    // Simplified Elliott Wave detection
    // In practice, this would involve wave counting and Fibonacci analysis
    return false; // Placeholder implementation
}

//+------------------------------------------------------------------+
//| Check for Fibonacci pattern                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::IsFibonacciPattern(double level = 0.618) {
    // Simplified Fibonacci retracement pattern
    // In practice, this would calculate retracement levels
    return false; // Placeholder implementation
}

//+------------------------------------------------------------------+
//| Get current signal based on detected patterns                    |
//+------------------------------------------------------------------+
SignalInfo CPatternDetector::GetCurrentSignal() {
    SignalInfo signal;
    signal.direction = SIGNAL_NONE;
    signal.timestamp = TimeCurrent();
    signal.isValid = false;
    
    ENUM_PATTERN_TYPE pattern = DetectPattern(0);
    signal.pattern = pattern;
    
    if(pattern != PATTERN_NONE) {
        signal.strength = CalculatePatternStrength(pattern, 0);
        
        // Determine signal direction based on pattern
        if(pattern == PATTERN_HAMMER || pattern == PATTERN_BULLISH_ENGULFING) {
            signal.direction = SIGNAL_BUY;
        } else if(pattern == PATTERN_SHOOTING_STAR || pattern == PATTERN_BEARISH_ENGULFING) {
            signal.direction = SIGNAL_SELL;
        }
        
        signal.isValid = ValidatePattern(pattern, 0);
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze patterns and update history                             |
//+------------------------------------------------------------------+
void CPatternDetector::AnalyzePatterns() {
    datetime currentTime = TimeCurrent();
    
    // Only analyze if enough time has passed
    if(currentTime - m_lastAnalysis < PeriodSeconds(m_timeframe)) {
        return;
    }
    
    for(int i = 0; i < 10; i++) { // Analyze last 10 bars
        ENUM_PATTERN_TYPE pattern = DetectPattern(i);
        
        if(pattern != PATTERN_NONE) {
            // Add to history
            if(m_historySize < ArraySize(m_patternHistory)) {
                m_patternHistory[m_historySize].pattern = pattern;
                m_patternHistory[m_historySize].barIndex = i;
                m_patternHistory[m_historySize].strength = CalculatePatternStrength(pattern, i);
                m_patternHistory[m_historySize].reliability = GetPatternReliability(pattern);
                m_patternHistory[m_historySize].timestamp = iTime(m_symbol, m_timeframe, i);
                m_patternHistory[m_historySize].isValid = ValidatePattern(pattern, i);
                m_historySize++;
            }
        }
    }
    
    m_lastAnalysis = currentTime;
}

//+------------------------------------------------------------------+
//| Calculate pattern strength                                       |
//+------------------------------------------------------------------+
double CPatternDetector::CalculatePatternStrength(ENUM_PATTERN_TYPE pattern, int shift = 0) {
    double baseReliability = GetPatternReliability(pattern);
    double volumeMultiplier = 1.0;
    double rangeMultiplier = 1.0;
    
    // Volume confirmation
    double volume[];
    if(CopyTickVolume(m_symbol, m_timeframe, shift, 2, volume) > 0) {
        ArraySetAsSeries(volume, true);
        if(volume[0] > volume[1]) {
            volumeMultiplier = 1.2;
        }
    }
    
    // Range confirmation
    double averageRange = GetAverageRange(14);
    double currentRange = GetCandleRange(shift);
    if(currentRange > averageRange) {
        rangeMultiplier = 1.1;
    }
    
    return MathMin(baseReliability * volumeMultiplier * rangeMultiplier, 1.0);
}

//+------------------------------------------------------------------+
//| Validate pattern                                                 |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidatePattern(ENUM_PATTERN_TYPE pattern, int shift = 0) {
    if(pattern == PATTERN_NONE) return false;
    
    double strength = CalculatePatternStrength(pattern, shift);
    return strength >= m_minPatternStrength;
}

//+------------------------------------------------------------------+
//| Get pattern name                                                 |
//+------------------------------------------------------------------+
string CPatternDetector::GetPatternName(ENUM_PATTERN_TYPE pattern) {
    switch(pattern) {
        case PATTERN_DOJI: return "Doji";
        case PATTERN_HAMMER: return "Hammer";
        case PATTERN_SHOOTING_STAR: return "Shooting Star";
        case PATTERN_BULLISH_ENGULFING: return "Bullish Engulfing";
        case PATTERN_BEARISH_ENGULFING: return "Bearish Engulfing";
        case PATTERN_PIN_BAR: return "Pin Bar";
        default: return "None";
    }
}

//+------------------------------------------------------------------+
//| Clear pattern history                                            |
//+------------------------------------------------------------------+
void CPatternDetector::ClearHistory() {
    m_historySize = 0;
    for(int i = 0; i < ArraySize(m_patternHistory); i++) {
        m_patternHistory[i].pattern = PATTERN_NONE;
        m_patternHistory[i].isValid = false;
    }
}

//+------------------------------------------------------------------+
//| Get candle data helper                                           |
//+------------------------------------------------------------------+
bool CPatternDetector::GetCandleData(int shift, double &open, double &high, double &low, double &close) {
    double openArray[], highArray[], lowArray[], closeArray[];
    
    if(CopyOpen(m_symbol, m_timeframe, shift, 1, openArray) <= 0 ||
       CopyHigh(m_symbol, m_timeframe, shift, 1, highArray) <= 0 ||
       CopyLow(m_symbol, m_timeframe, shift, 1, lowArray) <= 0 ||
       CopyClose(m_symbol, m_timeframe, shift, 1, closeArray) <= 0) {
        return false;
    }
    
    open = openArray[0];
    high = highArray[0];
    low = lowArray[0];
    close = closeArray[0];
    
    return true;
}

//+------------------------------------------------------------------+
//| Get candle body size                                             |
//+------------------------------------------------------------------+
double CPatternDetector::GetCandleBody(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0.0;
    return MathAbs(close - open);
}

//+------------------------------------------------------------------+
//| Get upper wick size                                              |
//+------------------------------------------------------------------+
double CPatternDetector::GetUpperWick(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0.0;
    return high - MathMax(open, close);
}

//+------------------------------------------------------------------+
//| Get lower wick size                                              |
//+------------------------------------------------------------------+
double CPatternDetector::GetLowerWick(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0.0;
    return MathMin(open, close) - low;
}

//+------------------------------------------------------------------+
//| Get candle range                                                 |
//+------------------------------------------------------------------+
double CPatternDetector::GetCandleRange(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return 0.0;
    return high - low;
}

//+------------------------------------------------------------------+
//| Check if candle is bullish                                       |
//+------------------------------------------------------------------+
bool CPatternDetector::IsBullishCandle(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    return close > open;
}

//+------------------------------------------------------------------+
//| Check if candle is bearish                                       |
//+------------------------------------------------------------------+
bool CPatternDetector::IsBearishCandle(int shift) {
    double open, high, low, close;
    if(!GetCandleData(shift, open, high, low, close)) return false;
    return close < open;
}

//+------------------------------------------------------------------+
//| Get average range                                                |
//+------------------------------------------------------------------+
double CPatternDetector::GetAverageRange(int periods = 14) {
    double high[], low[];
    if(CopyHigh(m_symbol, m_timeframe, 0, periods, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, 0, periods, low) <= 0) {
        return 0.0;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    double totalRange = 0.0;
    for(int i = 0; i < periods; i++) {
        totalRange += high[i] - low[i];
    }
    
    return totalRange / periods;
}

//+------------------------------------------------------------------+
//| Check if candle is significant                                   |
//+------------------------------------------------------------------+
bool CPatternDetector::IsSignificantCandle(int shift, double multiplier = 1.5) {
    double currentRange = GetCandleRange(shift);
    double averageRange = GetAverageRange(14);
    
    return currentRange >= averageRange * multiplier;
}