//+------------------------------------------------------------------+
//|                                              SignalManager.mqh |
//|                               Copyright 2025, Expert Developer |
//|                                       https://www.example.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Expert Developer"
#property link      "https://www.example.com"
#property version   "1.0"
#property strict

#include "Structs.mqh"
#include "GlobalVariables.mqh"
#include "LogManager.mqh"
#include "IndicatorManager.mqh"
#include "TechnicalAnalyzer.mqh"

// Signal validation cache
struct SignalValidationCache {
    datetime lastUpdate;
    bool isValid;
    double strength;
    string direction;
    int confirmations;
    double correlation;
};

// Pattern recognition cache
struct PatternCache {
    datetime lastUpdate;
    ENUM_CANDLE_PATTERN pattern;
    bool isValid;
    double reliability;
};

// Signal correlation state
struct CorrelationState {
    double emaCorr;
    double rsiCorr;
    double macdCorr;
    double volCorr;
    datetime lastUpdate;
};

//+------------------------------------------------------------------+
//| Class for centralized signal management                           |
//+------------------------------------------------------------------+
class CSignalManager {
private:
    // Dependencies
    CLogManager* m_logger;
    CIndicatorManager* m_indicators;
    
    // Caching
    SignalValidationCache m_validationCache[];
    PatternCache m_patternCache[];
    CorrelationState m_correlationState[];
    
    // Settings
    int m_maxCacheSize;
    int m_maxPatternLookback;
    double m_minCorrelation;
    double m_minSignalStrength;
    
    // Internal state
    datetime m_lastUpdate;
    bool m_isInitialized;
    
    // Private methods
    void InitializeCache(int timeframes);
    bool ValidateCache(datetime currentTime);
    void UpdateCorrelationState();
    bool CheckTimeframeCorrelation(int tfIndex);
    double CalculateSignalStrength(const SignalInfo &signal);
    void AddSignalConfirmations(SignalInfo &signal);
    bool ValidateSignalPrices(SignalInfo &signal);
    
public:
    // Constructor/Destructor
    CSignalManager(CLogManager* logger, CIndicatorManager* indicators);
    ~CSignalManager();
    
    // Core methods
    bool Initialize(StrategySettings &settings, bool isOptimization);
    SignalInfo GenerateSignal(int timeframeIndex);
    bool ValidateSignal(SignalInfo &signal);
    bool UpdateSignal(SignalInfo &signal);
    
    // Pattern recognition
    ENUM_CANDLE_PATTERN DetectPattern(int shift);
    bool IsPatternValid(ENUM_CANDLE_PATTERN pattern);
    double GetPatternReliability(ENUM_CANDLE_PATTERN pattern);
    
    // Technical analysis
    bool CheckMultiTimeframeTrend(string direction);
    double GetTimeframeCorrelation(int tf1, int tf2);
    bool ValidateIndicatorCorrelations(string direction);
    
    // Utility methods
    void ClearCache();
    string GetSignalDetails(const SignalInfo &signal);
    bool IsSignalDuplicate(const SignalInfo &s1, const SignalInfo &s2);
    SignalInfo GetSignal();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CSignalManager::CSignalManager(CLogManager* logger, CIndicatorManager* indicators)
{
    m_logger = logger;
    m_indicators = indicators;
    
    m_isInitialized = false;
    m_lastUpdate = 0;
    m_maxCacheSize = 100;
    m_maxPatternLookback = 20;
    m_minCorrelation = 0.5;
    m_minSignalStrength = 0.6;
    
    if(m_logger) m_logger.LogDebug("Constructor CSignalManager called");
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CSignalManager::~CSignalManager()
{
    ClearCache();
    ArrayFree(m_validationCache);
    ArrayFree(m_patternCache);
    ArrayFree(m_correlationState);
    
    if(m_logger) m_logger.LogDebug("Destructor CSignalManager called");
}

//+------------------------------------------------------------------+
//| Initialize signal manager                                         |
//+------------------------------------------------------------------+
bool CSignalManager::Initialize(StrategySettings &settings, bool isOptimization)
{
    if(m_logger) m_logger.LogInfo("Initializing SignalManager", "SIGNALMANAGER");
    
    m_minCorrelation = settings.maxRiskPercent / 100.0; // Use risk as correlation threshold
    m_minSignalStrength = 0.6;
    m_maxCacheSize = isOptimization ? 50 : 200;
    
    // Initialize cache arrays
    InitializeCache(MAX_TIMEFRAMES);
    
    m_isInitialized = true;
    m_lastUpdate = TimeCurrent();
    
    if(m_logger) m_logger.LogInfo("SignalManager initialized successfully", "SIGNALMANAGER");
    return true;
}

//+------------------------------------------------------------------+
//| Generate signal for specific timeframe                           |
//+------------------------------------------------------------------+
SignalInfo CSignalManager::GenerateSignal(int timeframeIndex)
{
    SignalInfo signal = {0};
    
    if(!m_isInitialized) {
        if(m_logger) m_logger.LogError("SignalManager not initialized", "SIGNALMANAGER");
        return signal;
    }
    
    // Initialize signal
    signal.timestamp = TimeCurrent();
    signal.symbol = _Symbol;
    signal.direction = SIGNAL_NONE;
    signal.isValid = false;
    signal.confidence = 0.0;
    
    // Detect pattern
    signal.pattern = DetectPattern(0);
    signal.patternStrength = GetPatternReliability(signal.pattern);
    
    // Check trend alignment
    if(CheckMultiTimeframeTrend("BUY")) {
        signal.direction = SIGNAL_BUY;
        signal.trend = TREND_UP;
    } else if(CheckMultiTimeframeTrend("SELL")) {
        signal.direction = SIGNAL_SELL;
        signal.trend = TREND_DOWN;
    }
    
    // Calculate signal strength
    signal.confidence = CalculateSignalStrength(signal);
    
    // Add confirmations
    AddSignalConfirmations(signal);
    
    // Validate signal
    signal.isValid = ValidateSignal(signal);
    
    if(m_logger && signal.isValid) {
        m_logger.LogSignal(signal);
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Validate signal                                                   |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateSignal(SignalInfo &signal)
{
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.confidence < m_minSignalStrength) return false;
    if(signal.patternStrength < 0.3) return false;
    
    // Validate prices
    if(!ValidateSignalPrices(signal)) return false;
    
    // Check correlations
    if(!ValidateIndicatorCorrelations(EnumToString(signal.direction))) return false;
    
    // Update validation cache
    if(ArraySize(m_validationCache) > 0) {
        m_validationCache[0].lastUpdate = TimeCurrent();
        m_validationCache[0].isValid = true;
        m_validationCache[0].strength = signal.confidence;
        m_validationCache[0].direction = EnumToString(signal.direction);
        m_validationCache[0].confirmations = signal.confirmations;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update existing signal                                            |
//+------------------------------------------------------------------+
bool CSignalManager::UpdateSignal(SignalInfo &signal)
{
    if(!signal.isValid) return false;
    
    // Recalculate signal strength
    signal.confidence = CalculateSignalStrength(signal);
    
    // Update confirmations
    AddSignalConfirmations(signal);
    
    // Re-validate
    signal.isValid = ValidateSignal(signal);
    
    return signal.isValid;
}

//+------------------------------------------------------------------+
//| Detect candlestick pattern                                       |
//+------------------------------------------------------------------+
ENUM_CANDLE_PATTERN CSignalManager::DetectPattern(int shift)
{
    double open[], high[], low[], close[];
    
    if(CopyOpen(_Symbol, _Period, shift, 3, open) <= 0 ||
       CopyHigh(_Symbol, _Period, shift, 3, high) <= 0 ||
       CopyLow(_Symbol, _Period, shift, 3, low) <= 0 ||
       CopyClose(_Symbol, _Period, shift, 3, close) <= 0) {
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
    
    // Pin Bar detection
    double upperWick = high[0] - MathMax(open[0], close[0]);
    double lowerWick = MathMin(open[0], close[0]) - low[0];
    if(range > 0) {
        if(lowerWick > body * 2 && upperWick < body * 0.5) {
            return PATTERN_HAMMER;
        }
        if(upperWick > body * 2 && lowerWick < body * 0.5) {
            return PATTERN_SHOOTING_STAR;
        }
    }
    
    // Engulfing patterns
    if(ArraySize(close) >= 2) {
        bool prevBearish = close[1] < open[1];
        bool currBullish = close[0] > open[0];
        if(prevBearish && currBullish && open[0] < close[1] && close[0] > open[1]) {
            return PATTERN_BULLISH_ENGULFING;
        }
        
        bool prevBullish = close[1] > open[1];
        bool currBearish = close[0] < open[0];
        if(prevBullish && currBearish && open[0] > close[1] && close[0] < open[1]) {
            return PATTERN_BEARISH_ENGULFING;
        }
    }
    
    return PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Check if pattern is valid                                         |
//+------------------------------------------------------------------+
bool CSignalManager::IsPatternValid(ENUM_CANDLE_PATTERN pattern)
{
    if(pattern == PATTERN_NONE) return false;
    
    double reliability = GetPatternReliability(pattern);
    return reliability >= 0.5;
}

//+------------------------------------------------------------------+
//| Get pattern reliability                                           |
//+------------------------------------------------------------------+
double CSignalManager::GetPatternReliability(ENUM_CANDLE_PATTERN pattern)
{
    switch(pattern) {
        case PATTERN_DOJI: return 0.6;
        case PATTERN_HAMMER: return 0.7;
        case PATTERN_SHOOTING_STAR: return 0.7;
        case PATTERN_BULLISH_ENGULFING: return 0.8;
        case PATTERN_BEARISH_ENGULFING: return 0.8;
        case PATTERN_MORNING_STAR: return 0.9;
        case PATTERN_EVENING_STAR: return 0.9;
        case PATTERN_PIN_BAR: return 0.75;
        default: return 0.0;
    }
}

//+------------------------------------------------------------------+
//| Check multi-timeframe trend alignment                            |
//+------------------------------------------------------------------+
bool CSignalManager::CheckMultiTimeframeTrend(string direction)
{
    int confirmedTimeframes = 0;
    int totalTimeframes = 3; // H1, H4, D1
    
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_H1, PERIOD_H4, PERIOD_D1};
    
    for(int i = 0; i < ArraySize(timeframes); i++) {
        double ma1[], ma2[];
        
        if(CopyBuffer(iMA(_Symbol, timeframes[i], 20, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 2, ma1) <= 0 ||
           CopyBuffer(iMA(_Symbol, timeframes[i], 50, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 2, ma2) <= 0) {
            continue;
        }
        
        ArraySetAsSeries(ma1, true);
        ArraySetAsSeries(ma2, true);
        
        if(direction == "BUY" && ma1[0] > ma2[0] && ma1[0] > ma1[1]) {
            confirmedTimeframes++;
        } else if(direction == "SELL" && ma1[0] < ma2[0] && ma1[0] < ma1[1]) {
            confirmedTimeframes++;
        }
    }
    
    return confirmedTimeframes >= 2; // At least 2 out of 3 timeframes
}

//+------------------------------------------------------------------+
//| Get correlation between timeframes                               |
//+------------------------------------------------------------------+
double CSignalManager::GetTimeframeCorrelation(int tf1, int tf2)
{
    // Simplified correlation calculation
    double correlation = 0.0;
    
    if(m_indicators) {
        // Get indicator values from both timeframes
        double val1 = m_indicators.GetBufferValue(IND_MA, tf1, 0);
        double val2 = m_indicators.GetBufferValue(IND_MA, tf2, 0);
        
        if(val1 != 0 && val2 != 0) {
            correlation = MathMin(val1, val2) / MathMax(val1, val2);
        }
    }
    
    return correlation;
}

//+------------------------------------------------------------------+
//| Validate indicator correlations                                  |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateIndicatorCorrelations(string direction)
{
    if(!m_indicators) return true; // Skip if no indicator manager
    
    // Check RSI correlation
    double rsi = m_indicators.GetBufferValue(IND_RSI, 0, 0);
    bool rsiValid = false;
    
    if(direction == "BUY" && rsi < 30) rsiValid = true;      // Oversold
    else if(direction == "SELL" && rsi > 70) rsiValid = true; // Overbought
    else if(rsi > 30 && rsi < 70) rsiValid = true;           // Neutral zone
    
    // Check MACD correlation
    double macdMain = m_indicators.GetBufferValue(IND_MACD, 0, 0);
    double macdSignal = m_indicators.GetBufferValue(IND_MACD, 0, 1);
    bool macdValid = false;
    
    if(direction == "BUY" && macdMain > macdSignal) macdValid = true;
    else if(direction == "SELL" && macdMain < macdSignal) macdValid = true;
    
    return rsiValid && macdValid;
}

//+------------------------------------------------------------------+
//| Initialize cache arrays                                           |
//+------------------------------------------------------------------+
void CSignalManager::InitializeCache(int timeframes)
{
    ArrayResize(m_validationCache, timeframes);
    ArrayResize(m_patternCache, m_maxPatternLookback);
    ArrayResize(m_correlationState, timeframes);
    
    // Initialize structures
    for(int i = 0; i < ArraySize(m_validationCache); i++) {
        m_validationCache[i].lastUpdate = 0;
        m_validationCache[i].isValid = false;
        m_validationCache[i].strength = 0.0;
        m_validationCache[i].direction = "";
        m_validationCache[i].confirmations = 0;
        m_validationCache[i].correlation = 0.0;
    }
    
    for(int i = 0; i < ArraySize(m_patternCache); i++) {
        m_patternCache[i].lastUpdate = 0;
        m_patternCache[i].pattern = PATTERN_NONE;
        m_patternCache[i].isValid = false;
        m_patternCache[i].reliability = 0.0;
    }
    
    for(int i = 0; i < ArraySize(m_correlationState); i++) {
        m_correlationState[i].emaCorr = 0.0;
        m_correlationState[i].rsiCorr = 0.0;
        m_correlationState[i].macdCorr = 0.0;
        m_correlationState[i].volCorr = 0.0;
        m_correlationState[i].lastUpdate = 0;
    }
}

//+------------------------------------------------------------------+
//| Validate cache                                                    |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateCache(datetime currentTime)
{
    for(int i = 0; i < ArraySize(m_validationCache); i++) {
        if(currentTime - m_validationCache[i].lastUpdate > 3600) { // 1 hour expiry
            m_validationCache[i].isValid = false;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| Update correlation state                                          |
//+------------------------------------------------------------------+
void CSignalManager::UpdateCorrelationState()
{
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < ArraySize(m_correlationState); i++) {
        if(currentTime - m_correlationState[i].lastUpdate > 300) { // 5 minutes
            if(m_indicators) {
                m_correlationState[i].emaCorr = m_indicators.GetBufferValue(IND_MA, i, 0);
                m_correlationState[i].rsiCorr = m_indicators.GetBufferValue(IND_RSI, i, 0);
                m_correlationState[i].macdCorr = m_indicators.GetBufferValue(IND_MACD, i, 0);
            }
            m_correlationState[i].lastUpdate = currentTime;
        }
    }
}

//+------------------------------------------------------------------+
//| Check timeframe correlation                                       |
//+------------------------------------------------------------------+
bool CSignalManager::CheckTimeframeCorrelation(int tfIndex)
{
    if(tfIndex >= ArraySize(m_correlationState)) return false;
    
    UpdateCorrelationState();
    
    double correlation = (m_correlationState[tfIndex].emaCorr + 
                         m_correlationState[tfIndex].rsiCorr + 
                         m_correlationState[tfIndex].macdCorr) / 3.0;
    
    return MathAbs(correlation) >= m_minCorrelation;
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                         |
//+------------------------------------------------------------------+
double CSignalManager::CalculateSignalStrength(const SignalInfo &signal)
{
    double strength = 0.0;
    
    // Pattern strength contribution (40%)
    strength += signal.patternStrength * 0.4;
    
    // Trend alignment contribution (30%)
    if(signal.trend != TREND_NONE) {
        strength += signal.trendStrength * 0.3;
    }
    
    // Confirmation contribution (20%)
    strength += MathMin(signal.confirmations / 3.0, 1.0) * 0.2;
    
    // Correlation contribution (10%)
    strength += signal.correlation * 0.1;
    
    return MathMin(strength, 1.0);
}

//+------------------------------------------------------------------+
//| Add signal confirmations                                          |
//+------------------------------------------------------------------+
void CSignalManager::AddSignalConfirmations(SignalInfo &signal)
{
    signal.confirmations = 0;
    
    // Volume confirmation
    double volume[];
    if(CopyTickVolume(_Symbol, _Period, 0, 2, volume) > 0) {
        ArraySetAsSeries(volume, true);
        if(volume[0] > volume[1]) {
            signal.confirmations++;
        }
    }
    
    // Price action confirmation
    if(signal.pattern != PATTERN_NONE) {
        signal.confirmations++;
    }
    
    // Trend confirmation
    if(signal.trend != TREND_NONE) {
        signal.confirmations++;