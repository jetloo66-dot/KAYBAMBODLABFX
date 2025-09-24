//+------------------------------------------------------------------+
//|                                              SignalManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs.mqh"
#include "GlobalVariables.mqh"

//+------------------------------------------------------------------+
//| Signal Manager Class                                             |
//+------------------------------------------------------------------+
class CSignalManager {
private:
    // Cache structures
    struct SignalCache {
        datetime lastUpdate;
        bool isValid;
        double strength;
        int confirmations;
    };
    
    SignalCache m_cache[];
    bool m_initialized;
    datetime m_lastUpdate;
    
    // Private methods
    void InitializeCache();
    bool ValidateCache();
    void UpdateCorrelationState();
    
public:
    CSignalManager();
    ~CSignalManager();
    
    // Core methods
    bool Initialize();
    SignalInfo GenerateSignal();
    bool ValidateSignal(SignalInfo &signal);
    bool UpdateSignal(SignalInfo &signal);
    
    // Pattern detection methods
    ENUM_CANDLE_PATTERN DetectPattern();
    bool IsPatternValid(ENUM_CANDLE_PATTERN pattern);
    double GetPatternReliability(ENUM_CANDLE_PATTERN pattern);
    
    // Technical analysis methods
    bool CheckMultiTimeframeTrend();
    double GetTimeframeCorrelation(int tf1, int tf2);
    bool ValidateIndicatorCorrelations();
    
    // Utility methods
    void ClearCache();
    string GetSignalDetails(const SignalInfo &signal);
    bool IsSignalDuplicate(const SignalInfo &s1, const SignalInfo &s2);
    SignalInfo GetSignal();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalManager::CSignalManager() {
    m_initialized = false;
    m_lastUpdate = 0;
    ArrayResize(m_cache, 10);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalManager::~CSignalManager() {
    ArrayFree(m_cache);
}

//+------------------------------------------------------------------+
//| Initialize signal manager                                        |
//+------------------------------------------------------------------+
bool CSignalManager::Initialize() {
    InitializeCache();
    m_initialized = true;
    m_lastUpdate = TimeCurrent();
    Print("SignalManager initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Generate signal                                                  |
//+------------------------------------------------------------------+
SignalInfo CSignalManager::GenerateSignal() {
    SignalInfo signal;
    ZeroMemory(signal);
    
    if(!m_initialized) {
        Print("SignalManager not initialized");
        return signal;
    }
    
    // Detect pattern
    signal.pattern = DetectPattern();
    signal.patternStrength = GetPatternReliability(signal.pattern);
    signal.timestamp = TimeCurrent();
    signal.symbol = _Symbol;
    
    // Determine direction based on pattern
    if(signal.pattern == PATTERN_BULLISH_ENGULFING || 
       signal.pattern == PATTERN_HAMMER) {
        signal.direction = SIGNAL_BUY;
    } else if(signal.pattern == PATTERN_BEARISH_ENGULFING || 
              signal.pattern == PATTERN_SHOOTING_STAR) {
        signal.direction = SIGNAL_SELL;
    }
    
    // Validate signal
    signal.isValid = ValidateSignal(signal);
    
    return signal;
}

//+------------------------------------------------------------------+
//| Validate signal                                                  |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateSignal(SignalInfo &signal) {
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.patternStrength < 0.5) return false;
    
    // Check multi-timeframe alignment
    if(!CheckMultiTimeframeTrend()) return false;
    
    // Validate indicator correlations
    if(!ValidateIndicatorCorrelations()) return false;
    
    signal.confidence = signal.patternStrength * 0.6 + 
                       (CheckMultiTimeframeTrend() ? 0.4 : 0.0);
    
    return signal.confidence >= 0.6;
}

//+------------------------------------------------------------------+
//| Update signal                                                    |
//+------------------------------------------------------------------+
bool CSignalManager::UpdateSignal(SignalInfo &signal) {
    if(!signal.isValid) return false;
    
    // Recalculate confidence
    signal.confidence = signal.patternStrength * 0.6 + 
                       (CheckMultiTimeframeTrend() ? 0.4 : 0.0);
    
    // Re-validate
    signal.isValid = (signal.confidence >= 0.6);
    
    return signal.isValid;
}

//+------------------------------------------------------------------+
//| Detect pattern                                                   |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CSignalManager::DetectPattern() {
    double open[], high[], low[], close[];
    
    if(CopyOpen(_Symbol, _Period, 0, 3, open) <= 0 ||
       CopyHigh(_Symbol, _Period, 0, 3, high) <= 0 ||
       CopyLow(_Symbol, _Period, 0, 3, low) <= 0 ||
       CopyClose(_Symbol, _Period, 0, 3, close) <= 0) {
        return PATTERN_NONE;
    }
    
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    // Doji detection
    double body = MathAbs(close[0] - open[0]);
    double range = high[0] - low[0];
    if(range > 0 && body / range < 0.1) {
        return PATTERN_DOJI;
    }
    
    // Hammer detection
    double lowerWick = MathMin(open[0], close[0]) - low[0];
    double upperWick = high[0] - MathMax(open[0], close[0]);
    if(lowerWick > body * 2 && upperWick < body * 0.5) {
        return PATTERN_HAMMER;
    }
    
    // Shooting star detection
    if(upperWick > body * 2 && lowerWick < body * 0.5) {
        return PATTERN_SHOOTING_STAR;
    }
    
    // Bullish engulfing
    if(ArraySize(close) >= 2) {
        bool prevBearish = close[1] < open[1];
        bool currBullish = close[0] > open[0];
        if(prevBearish && currBullish && 
           open[0] < close[1] && close[0] > open[1]) {
            return PATTERN_BULLISH_ENGULFING;
        }
        
        // Bearish engulfing
        bool prevBullish = close[1] > open[1];
        bool currBearish = close[0] < open[0];
        if(prevBullish && currBearish && 
           open[0] > close[1] && close[0] < open[1]) {
            return PATTERN_BEARISH_ENGULFING;
        }
    }
    
    return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Check if pattern is valid                                        |
//+------------------------------------------------------------------+
bool CSignalManager::IsPatternValid(ENUM_CANDLE_PATTERN pattern) {
    return pattern != PATTERN_NONE && GetPatternReliability(pattern) >= 0.5;
}

//+------------------------------------------------------------------+
//| Get pattern reliability                                          |
//+------------------------------------------------------------------+
double CSignalManager::GetPatternReliability(ENUM_CANDLE_PATTERN pattern) {
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
//| Check multi-timeframe trend                                      |
//+------------------------------------------------------------------+
bool CSignalManager::CheckMultiTimeframeTrend() {
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_H1, PERIOD_H4, PERIOD_D1};
    int bullishCount = 0;
    int bearishCount = 0;
    
    for(int i = 0; i < ArraySize(timeframes); i++) {
        double ma20[], ma50[];
        
        if(CopyBuffer(iMA(_Symbol, timeframes[i], 20, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma20) > 0 &&
           CopyBuffer(iMA(_Symbol, timeframes[i], 50, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma50) > 0) {
            
            if(ma20[0] > ma50[0]) bullishCount++;
            else bearishCount++;
        }
    }
    
    return (bullishCount >= 2 || bearishCount >= 2);
}

//+------------------------------------------------------------------+
//| Get timeframe correlation                                        |
//+------------------------------------------------------------------+
double CSignalManager::GetTimeframeCorrelation(int tf1, int tf2) {
    // Simplified correlation - compare MA slopes
    double ma1_1[], ma1_2[], ma2_1[], ma2_2[];
    
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_M5, PERIOD_H1, PERIOD_H4, PERIOD_D1};
    
    if(tf1 >= ArraySize(timeframes) || tf2 >= ArraySize(timeframes)) return 0.0;
    
    if(CopyBuffer(iMA(_Symbol, timeframes[tf1], 20, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 2, ma1_1) > 0 &&
       CopyBuffer(iMA(_Symbol, timeframes[tf2], 20, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 2, ma2_1) > 0) {
        
        double slope1 = ma1_1[0] - ma1_1[1];
        double slope2 = ma2_1[0] - ma2_1[1];
        
        if(slope1 * slope2 > 0) return 0.8; // Same direction
        else return -0.3; // Opposite direction
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Validate indicator correlations                                  |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateIndicatorCorrelations() {
    // Check RSI
    double rsi[];
    int rsiHandle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    if(CopyBuffer(rsiHandle, 0, 0, 1, rsi) <= 0) return false;
    
    // Check MACD
    double macd[], signal[];
    int macdHandle = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE);
    if(CopyBuffer(macdHandle, 0, 0, 1, macd) <= 0 ||
       CopyBuffer(macdHandle, 1, 0, 1, signal) <= 0) return false;
    
    // Simple validation - avoid extreme conditions
    if(rsi[0] > 20 && rsi[0] < 80) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Initialize cache                                                 |
//+------------------------------------------------------------------+
void CSignalManager::InitializeCache() {
    for(int i = 0; i < ArraySize(m_cache); i++) {
        m_cache[i].lastUpdate = 0;
        m_cache[i].isValid = false;
        m_cache[i].strength = 0.0;
        m_cache[i].confirmations = 0;
    }
}

//+------------------------------------------------------------------+
//| Validate cache                                                   |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateCache() {
    datetime currentTime = TimeCurrent();
    for(int i = 0; i < ArraySize(m_cache); i++) {
        if(currentTime - m_cache[i].lastUpdate > 3600) { // 1 hour expiry
            m_cache[i].isValid = false;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| Update correlation state                                         |
//+------------------------------------------------------------------+
void CSignalManager::UpdateCorrelationState() {
    ValidateCache();
    m_lastUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Clear cache                                                      |
//+------------------------------------------------------------------+
void CSignalManager::ClearCache() {
    for(int i = 0; i < ArraySize(m_cache); i++) {
        m_cache[i].isValid = false;
        m_cache[i].lastUpdate = 0;
    }
}

//+------------------------------------------------------------------+
//| Get signal details                                               |
//+------------------------------------------------------------------+
string CSignalManager::GetSignalDetails(const SignalInfo &signal) {
    string details = StringFormat("Signal: %s, Pattern: %s, Strength: %.2f, Confidence: %.2f",
                                 EnumToString(signal.direction),
                                 GetPatternString(signal.pattern),
                                 signal.patternStrength,
                                 signal.confidence);
    return details;
}

//+------------------------------------------------------------------+
//| Check if signals are duplicate                                   |
//+------------------------------------------------------------------+
bool CSignalManager::IsSignalDuplicate(const SignalInfo &s1, const SignalInfo &s2) {
    return (s1.symbol == s2.symbol &&
            s1.direction == s2.direction &&
            s1.pattern == s2.pattern &&
            MathAbs(s1.timestamp - s2.timestamp) < 300); // 5 minutes
}

//+------------------------------------------------------------------+
//| Get current signal                                               |
//+------------------------------------------------------------------+
SignalInfo CSignalManager::GetSignal() {
    return GenerateSignal();
}