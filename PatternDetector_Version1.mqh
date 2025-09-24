//+------------------------------------------------------------------+
//|                                              PatternDetector.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs.mqh"
#include "GlobalVariables.mqh"

//+------------------------------------------------------------------+
//| Pattern Detector Class                                           |
//+------------------------------------------------------------------+
class CPatternDetector {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_lookback;
    bool m_initialized;
    
    // Pattern cache
    struct PatternCache {
        ENUM_CANDLE_PATTERN pattern;
        datetime timestamp;
        double strength;
        bool isValid;
    };
    
    PatternCache m_cache[];
    
    // Private methods
    bool ValidatePattern(ENUM_CANDLE_PATTERN pattern, int index);
    double CalculatePatternStrength(ENUM_CANDLE_PATTERN pattern, int index);
    bool GetCandleData(int index, double &open, double &high, double &low, double &close);
    
public:
    CPatternDetector(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
    ~CPatternDetector();
    
    // Initialization
    bool Initialize(int lookback = 20);
    
    // Core detection methods
    ENUM_CANDLE_PATTERN DetectPattern(int shift = 0);
    bool ValidateCurrentPattern();
    double GetPatternReliability(ENUM_CANDLE_PATTERN pattern);
    
    // Specific pattern detection methods
    bool IsDoji(int index);
    bool IsHammer(int index);
    bool IsShootingStar(int index);
    bool IsEngulfing(int index, bool bullish = true);
    bool IsInsideBar(int index);
    bool IsOutsideBar(int index);
    bool IsPinBar(int index);
    bool IsHarami(int index);
    bool IsMorningStar(int index);
    bool IsEveningStar(int index);
    
    // Advanced pattern methods
    ENUM_CANDLE_PATTERN DetectHarmonicPattern();
    ENUM_CANDLE_PATTERN DetectElliottWave();
    bool IsFibonacciPattern();
    
    // Signal generation
    SignalInfo GetCurrentSignal();
    
    // Main analysis method
    void AnalyzePatterns();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPatternDetector::CPatternDetector(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
    m_symbol = (symbol == "") ? _Symbol : symbol;
    m_timeframe = (timeframe == PERIOD_CURRENT) ? _Period : timeframe;
    m_lookback = 20;
    m_initialized = false;
    
    ArrayResize(m_cache, 50);
    for(int i = 0; i < ArraySize(m_cache); i++) {
        m_cache[i].pattern = PATTERN_NONE;
        m_cache[i].timestamp = 0;
        m_cache[i].strength = 0.0;
        m_cache[i].isValid = false;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPatternDetector::~CPatternDetector() {
    ArrayFree(m_cache);
}

//+------------------------------------------------------------------+
//| Initialize pattern detector                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::Initialize(int lookback = 20) {
    m_lookback = lookback;
    m_initialized = true;
    Print("PatternDetector initialized for ", m_symbol, " on ", EnumToString(m_timeframe));
    return true;
}

//+------------------------------------------------------------------+
//| Detect pattern at specific shift                                 |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CPatternDetector::DetectPattern(int shift = 0) {
    if(!m_initialized) {
        Print("PatternDetector not initialized");
        return PATTERN_NONE;
    }
    
    // Check cache first
    for(int i = 0; i < ArraySize(m_cache); i++) {
        if(m_cache[i].timestamp == iTime(m_symbol, m_timeframe, shift) && m_cache[i].isValid) {
            return m_cache[i].pattern;
        }
    }
    
    ENUM_CANDLE_PATTERN detectedPattern = PATTERN_NONE;
    
    // Check patterns in order of reliability
    if(IsEngulfing(shift, true)) detectedPattern = PATTERN_BULLISH_ENGULFING;
    else if(IsEngulfing(shift, false)) detectedPattern = PATTERN_BEARISH_ENGULFING;
    else if(IsMorningStar(shift)) detectedPattern = PATTERN_MORNING_STAR;
    else if(IsEveningStar(shift)) detectedPattern = PATTERN_EVENING_STAR;
    else if(IsHammer(shift)) detectedPattern = PATTERN_HAMMER;
    else if(IsShootingStar(shift)) detectedPattern = PATTERN_SHOOTING_STAR;
    else if(IsPinBar(shift)) detectedPattern = PATTERN_PIN_BAR;
    else if(IsDoji(shift)) detectedPattern = PATTERN_DOJI;
    else if(IsHarami(shift)) detectedPattern = PATTERN_HARAMI;
    else if(IsInsideBar(shift)) detectedPattern = PATTERN_INSIDE_BAR;
    else if(IsOutsideBar(shift)) detectedPattern = PATTERN_OUTSIDE_BAR;
    
    // Cache the result
    if(detectedPattern != PATTERN_NONE) {
        int cacheIndex = shift % ArraySize(m_cache);
        m_cache[cacheIndex].pattern = detectedPattern;
        m_cache[cacheIndex].timestamp = iTime(m_symbol, m_timeframe, shift);
        m_cache[cacheIndex].strength = CalculatePatternStrength(detectedPattern, shift);
        m_cache[cacheIndex].isValid = true;
    }
    
    return detectedPattern;
}

//+------------------------------------------------------------------+
//| Validate current pattern                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidateCurrentPattern() {
    ENUM_CANDLE_PATTERN pattern = DetectPattern(0);
    return ValidatePattern(pattern, 0);
}

//+------------------------------------------------------------------+
//| Get pattern reliability                                          |
//+------------------------------------------------------------------+
double CPatternDetector::GetPatternReliability(ENUM_CANDLE_PATTERN pattern) {
    switch(pattern) {
        case PATTERN_BULLISH_ENGULFING:
        case PATTERN_BEARISH_ENGULFING: return 0.85;
        case PATTERN_MORNING_STAR:
        case PATTERN_EVENING_STAR: return 0.90;
        case PATTERN_HAMMER: return 0.75;
        case PATTERN_SHOOTING_STAR: return 0.75;
        case PATTERN_PIN_BAR: return 0.70;
        case PATTERN_DOJI: return 0.60;
        case PATTERN_HARAMI: return 0.65;
        case PATTERN_INSIDE_BAR: return 0.55;
        case PATTERN_OUTSIDE_BAR: return 0.65;
        case PATTERN_THREE_SOLDIERS:
        case PATTERN_THREE_CROWS: return 0.80;
        default: return 0.0;
    }
}

//+------------------------------------------------------------------+
//| Doji pattern detection                                           |
//+------------------------------------------------------------------+
bool CPatternDetector::IsDoji(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double range = high - low;
    
    if(range == 0) return false;
    
    return (body / range <= 0.1);
}

//+------------------------------------------------------------------+
//| Hammer pattern detection                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::IsHammer(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double lowerWick = MathMin(open, close) - low;
    double upperWick = high - MathMax(open, close);
    
    return (lowerWick >= body * 2 && upperWick <= body * 0.5 && body > 0);
}

//+------------------------------------------------------------------+
//| Shooting Star pattern detection                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::IsShootingStar(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double lowerWick = MathMin(open, close) - low;
    double upperWick = high - MathMax(open, close);
    
    return (upperWick >= body * 2 && lowerWick <= body * 0.5 && body > 0);
}

//+------------------------------------------------------------------+
//| Engulfing pattern detection                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::IsEngulfing(int index, bool bullish = true) {
    if(index >= Bars(m_symbol, m_timeframe) - 1) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    if(bullish) {
        // Bullish engulfing
        return (close2 < open2 && // Previous candle bearish
                close1 > open1 && // Current candle bullish
                open1 < close2 &&  // Opens below previous close
                close1 > open2);   // Closes above previous open
    } else {
        // Bearish engulfing
        return (close2 > open2 && // Previous candle bullish
                close1 < open1 && // Current candle bearish
                open1 > close2 &&  // Opens above previous close
                close1 < open2);   // Closes below previous open
    }
}

//+------------------------------------------------------------------+
//| Inside Bar pattern detection                                     |
//+------------------------------------------------------------------+
bool CPatternDetector::IsInsideBar(int index) {
    if(index >= Bars(m_symbol, m_timeframe) - 1) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    return (high1 < high2 && low1 > low2);
}

//+------------------------------------------------------------------+
//| Outside Bar pattern detection                                    |
//+------------------------------------------------------------------+
bool CPatternDetector::IsOutsideBar(int index) {
    if(index >= Bars(m_symbol, m_timeframe) - 1) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    return (high1 > high2 && low1 < low2);
}

//+------------------------------------------------------------------+
//| Pin Bar pattern detection                                        |
//+------------------------------------------------------------------+
bool CPatternDetector::IsPinBar(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double range = high - low;
    double upperWick = high - MathMax(open, close);
    double lowerWick = MathMin(open, close) - low;
    
    if(range == 0) return false;
    
    double bodyRatio = body / range;
    
    // Pin bar characteristics
    return (bodyRatio <= 0.3 && 
           (upperWick > body * 1.5 || lowerWick > body * 1.5));
}

//+------------------------------------------------------------------+
//| Harami pattern detection                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::IsHarami(int index) {
    if(index >= Bars(m_symbol, m_timeframe) - 1) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    double body1 = MathAbs(close1 - open1);
    double body2 = MathAbs(close2 - open2);
    
    // Current candle is smaller and within previous candle's body
    return (body1 < body2 && 
            MathMax(open1, close1) < MathMax(open2, close2) &&
            MathMin(open1, close1) > MathMin(open2, close2));
}

//+------------------------------------------------------------------+
//| Morning Star pattern detection                                   |
//+------------------------------------------------------------------+
bool CPatternDetector::IsMorningStar(int index) {
    if(index >= Bars(m_symbol, m_timeframe) - 2) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    double open3, high3, low3, close3;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2) ||
       !GetCandleData(index + 2, open3, high3, low3, close3)) return false;
    
    // First candle: bearish
    // Second candle: small body (doji/spinner)
    // Third candle: bullish, closes above first candle's midpoint
    
    bool firstBearish = close3 < open3;
    bool secondSmall = MathAbs(close2 - open2) < MathAbs(close3 - open3) * 0.3;
    bool thirdBullish = close1 > open1;
    bool thirdCloseHigh = close1 > (open3 + close3) / 2;
    
    return (firstBearish && secondSmall && thirdBullish && thirdCloseHigh);
}

//+------------------------------------------------------------------+
//| Evening Star pattern detection                                   |
//+------------------------------------------------------------------+
bool CPatternDetector::IsEveningStar(int index) {
    if(index >= Bars(m_symbol, m_timeframe) - 2) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    double open3, high3, low3, close3;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2) ||
       !GetCandleData(index + 2, open3, high3, low3, close3)) return false;
    
    // First candle: bullish
    // Second candle: small body (doji/spinner)
    // Third candle: bearish, closes below first candle's midpoint
    
    bool firstBullish = close3 > open3;
    bool secondSmall = MathAbs(close2 - open2) < MathAbs(close3 - open3) * 0.3;
    bool thirdBearish = close1 < open1;
    bool thirdCloseLow = close1 < (open3 + close3) / 2;
    
    return (firstBullish && secondSmall && thirdBearish && thirdCloseLow);
}

//+------------------------------------------------------------------+
//| Detect harmonic patterns (simplified)                           |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CPatternDetector::DetectHarmonicPattern() {
    // Simplified harmonic pattern detection
    // In a full implementation, this would detect Gartley, Butterfly, etc.
    return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Detect Elliott Wave patterns (simplified)                       |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CPatternDetector::DetectElliottWave() {
    // Simplified Elliott Wave detection
    // In a full implementation, this would detect wave patterns
    return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Check for Fibonacci-based patterns                              |
//+------------------------------------------------------------------+
bool CPatternDetector::IsFibonacciPattern() {
    // Simplified Fibonacci pattern detection
    return false;
}

//+------------------------------------------------------------------+
//| Get current signal based on detected pattern                    |
//+------------------------------------------------------------------+
SignalInfo CPatternDetector::GetCurrentSignal() {
    SignalInfo signal;
    ZeroMemory(signal);
    
    ENUM_CANDLE_PATTERN pattern = DetectPattern(0);
    signal.pattern = pattern;
    signal.patternStrength = CalculatePatternStrength(pattern, 0);
    signal.timestamp = TimeCurrent();
    signal.symbol = m_symbol;
    
    // Determine signal direction
    switch(pattern) {
        case PATTERN_BULLISH_ENGULFING:
        case PATTERN_HAMMER:
        case PATTERN_MORNING_STAR:
            signal.direction = SIGNAL_BUY;
            break;
            
        case PATTERN_BEARISH_ENGULFING:
        case PATTERN_SHOOTING_STAR:
        case PATTERN_EVENING_STAR:
            signal.direction = SIGNAL_SELL;
            break;
            
        default:
            signal.direction = SIGNAL_NONE;
    }
    
    signal.isValid = (pattern != PATTERN_NONE && signal.patternStrength >= 0.5);
    signal.confidence = signal.patternStrength * GetPatternReliability(pattern);
    
    return signal;
}

//+------------------------------------------------------------------+
//| Analyze patterns on multiple timeframes                         |
//+------------------------------------------------------------------+
void CPatternDetector::AnalyzePatterns() {
    if(!m_initialized) return;
    
    // Analyze patterns on current timeframe
    for(int i = 0; i < m_lookback; i++) {
        ENUM_CANDLE_PATTERN pattern = DetectPattern(i);
        if(pattern != PATTERN_NONE) {
            Print("Pattern detected: ", GetPatternString(pattern), 
                  " at bar ", i, " with strength ", 
                  CalculatePatternStrength(pattern, i));
        }
    }
}

//+------------------------------------------------------------------+
//| Get candle data                                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::GetCandleData(int index, double &open, double &high, double &low, double &close) {
    if(index < 0 || index >= Bars(m_symbol, m_timeframe)) return false;
    
    double openArray[], highArray[], lowArray[], closeArray[];
    
    if(CopyOpen(m_symbol, m_timeframe, index, 1, openArray) <= 0 ||
       CopyHigh(m_symbol, m_timeframe, index, 1, highArray) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, 1, lowArray) <= 0 ||
       CopyClose(m_symbol, m_timeframe, index, 1, closeArray) <= 0) {
        return false;
    }
    
    open = openArray[0];
    high = highArray[0];
    low = lowArray[0];
    close = closeArray[0];
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate pattern                                                 |
//+------------------------------------------------------------------+
bool CPatternDetector::ValidatePattern(ENUM_CANDLE_PATTERN pattern, int index) {
    if(pattern == PATTERN_NONE) return false;
    
    double strength = CalculatePatternStrength(pattern, index);
    double reliability = GetPatternReliability(pattern);
    
    return (strength >= 0.5 && reliability >= 0.6);
}

//+------------------------------------------------------------------+
//| Calculate pattern strength                                       |
//+------------------------------------------------------------------+
double CPatternDetector::CalculatePatternStrength(ENUM_CANDLE_PATTERN pattern, int index) {
    if(pattern == PATTERN_NONE) return 0.0;
    
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return 0.0;
    
    double body = MathAbs(close - open);
    double range = high - low;
    
    if(range == 0) return 0.0;
    
    double strength = 0.0;
    
    switch(pattern) {
        case PATTERN_DOJI:
            strength = 1.0 - (body / range);
            break;
            
        case PATTERN_HAMMER:
        case PATTERN_SHOOTING_STAR: {
            double wickRatio = (pattern == PATTERN_HAMMER) ? 
                              (MathMin(open, close) - low) / range :
                              (high - MathMax(open, close)) / range;
            strength = wickRatio;
            break;
        }
        
        case PATTERN_BULLISH_ENGULFING:
        case PATTERN_BEARISH_ENGULFING: {
            if(index < Bars(m_symbol, m_timeframe) - 1) {
                double prevOpen, prevHigh, prevLow, prevClose;
                if(GetCandleData(index + 1, prevOpen, prevHigh, prevLow, prevClose)) {
                    double engulfRatio = body / MathAbs(prevClose - prevOpen);
                    strength = MathMin(engulfRatio / 2.0, 1.0);
                }
            }
            break;
        }
        
        default:
            strength = 0.6; // Default strength for other patterns
    }
    
    return MathMax(0.0, MathMin(1.0, strength));
}