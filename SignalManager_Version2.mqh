//+------------------------------------------------------------------+
//|                                              SignalManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE {
    SIGNAL_NONE = 0,
    SIGNAL_BUY,
    SIGNAL_SELL
};

enum ENUM_PATTERN_TYPE {
    PATTERN_NONE = 0,
    PATTERN_DOJI,
    PATTERN_HAMMER,
    PATTERN_SHOOTING_STAR,
    PATTERN_BULLISH_ENGULFING,
    PATTERN_BEARISH_ENGULFING,
    PATTERN_PIN_BAR
};

//+------------------------------------------------------------------+
//| Signal Information Structure                                     |
//+------------------------------------------------------------------+
struct SignalInfo {
    ENUM_SIGNAL_TYPE direction;
    datetime timestamp;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double strength;
    ENUM_PATTERN_TYPE pattern;
    bool isValid;
    int confirmations;
    double correlation;
    string comment;
};

//+------------------------------------------------------------------+
//| Signal Manager Class                                             |
//+------------------------------------------------------------------+
class CSignalManager {
private:
    // Cache structures
    struct ValidationCache {
        datetime lastUpdate;
        bool isValid;
        double strength;
        int confirmations;
    };
    
    struct PatternCache {
        ENUM_PATTERN_TYPE pattern;
        double reliability;
        datetime detected;
    };
    
    struct CorrelationState {
        double maCorrelation;
        double rsiCorrelation;
        double macdCorrelation;
        datetime lastUpdate;
    };
    
    // Member variables
    ValidationCache m_validationCache[];
    PatternCache m_patternCache[];
    CorrelationState m_correlationState[];
    
    bool m_isInitialized;
    datetime m_lastUpdate;
    int m_maxCacheSize;
    double m_minSignalStrength;
    double m_minCorrelation;
    
    // Private methods
    void InitializeCache();
    bool ValidateCache();
    void UpdateCorrelationState();
    double CalculateSignalStrength(const SignalInfo &signal);
    void AddConfirmations(SignalInfo &signal);
    
public:
    // Constructor/Destructor
    CSignalManager();
    ~CSignalManager();
    
    // Core methods
    bool Initialize();
    SignalInfo GenerateSignal();
    bool ValidateSignal(SignalInfo &signal);
    bool UpdateSignal(SignalInfo &signal);
    
    // Pattern detection methods
    ENUM_PATTERN_TYPE DetectPattern(int shift = 0);
    bool IsPatternValid(ENUM_PATTERN_TYPE pattern);
    double GetPatternReliability(ENUM_PATTERN_TYPE pattern);
    
    // Technical analysis methods
    bool CheckMultiTimeframeTrend(string direction);
    double GetTimeframeCorrelation(ENUM_TIMEFRAMES tf1, ENUM_TIMEFRAMES tf2);
    bool ValidateIndicatorCorrelations(string direction);
    
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
    m_isInitialized = false;
    m_lastUpdate = 0;
    m_maxCacheSize = 100;
    m_minSignalStrength = 0.6;
    m_minCorrelation = 0.5;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalManager::~CSignalManager() {
    ClearCache();
    ArrayFree(m_validationCache);
    ArrayFree(m_patternCache);
    ArrayFree(m_correlationState);
}

//+------------------------------------------------------------------+
//| Initialize signal manager                                        |
//+------------------------------------------------------------------+
bool CSignalManager::Initialize() {
    InitializeCache();
    m_isInitialized = true;
    m_lastUpdate = TimeCurrent();
    Print("SignalManager initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Generate trading signal                                          |
//+------------------------------------------------------------------+
SignalInfo CSignalManager::GenerateSignal() {
    SignalInfo signal;
    signal.direction = SIGNAL_NONE;
    signal.timestamp = TimeCurrent();
    signal.isValid = false;
    signal.strength = 0.0;
    signal.confirmations = 0;
    signal.correlation = 0.0;
    
    if(!m_isInitialized) {
        Print("SignalManager not initialized");
        return signal;
    }
    
    // Detect pattern
    signal.pattern = DetectPattern(0);
    
    // Determine signal direction based on pattern
    if(signal.pattern == PATTERN_HAMMER || signal.pattern == PATTERN_BULLISH_ENGULFING) {
        if(CheckMultiTimeframeTrend("BUY")) {
            signal.direction = SIGNAL_BUY;
        }
    } else if(signal.pattern == PATTERN_SHOOTING_STAR || signal.pattern == PATTERN_BEARISH_ENGULFING) {
        if(CheckMultiTimeframeTrend("SELL")) {
            signal.direction = SIGNAL_SELL;
        }
    }
    
    // Set entry price
    if(signal.direction == SIGNAL_BUY) {
        signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    } else if(signal.direction == SIGNAL_SELL) {
        signal.entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    }
    
    // Calculate signal strength
    signal.strength = CalculateSignalStrength(signal);
    
    // Add confirmations
    AddConfirmations(signal);
    
    // Validate signal
    signal.isValid = ValidateSignal(signal);
    
    return signal;
}

//+------------------------------------------------------------------+
//| Validate signal                                                  |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateSignal(SignalInfo &signal) {
    if(signal.direction == SIGNAL_NONE) return false;
    if(signal.strength < m_minSignalStrength) return false;
    if(signal.confirmations < 2) return false;
    
    // Validate indicator correlations
    string direction = (signal.direction == SIGNAL_BUY) ? "BUY" : "SELL";
    if(!ValidateIndicatorCorrelations(direction)) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Update existing signal                                           |
//+------------------------------------------------------------------+
bool CSignalManager::UpdateSignal(SignalInfo &signal) {
    if(!signal.isValid) return false;
    
    // Recalculate strength
    signal.strength = CalculateSignalStrength(signal);
    
    // Update confirmations
    AddConfirmations(signal);
    
    // Re-validate
    signal.isValid = ValidateSignal(signal);
    
    return signal.isValid;
}

//+------------------------------------------------------------------+
//| Detect candlestick pattern                                       |
//+------------------------------------------------------------------+
ENUM_PATTERN_TYPE CSignalManager::DetectPattern(int shift = 0) {
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
    
    double body = MathAbs(close[0] - open[0]);
    double range = high[0] - low[0];
    double upperWick = high[0] - MathMax(open[0], close[0]);
    double lowerWick = MathMin(open[0], close[0]) - low[0];
    
    if(range == 0) return PATTERN_NONE;
    
    // Doji detection
    if(body / range < 0.1) {
        return PATTERN_DOJI;
    }
    
    // Hammer detection
    if(lowerWick > body * 2 && upperWick < body * 0.5) {
        return PATTERN_HAMMER;
    }
    
    // Shooting Star detection
    if(upperWick > body * 2 && lowerWick < body * 0.5) {
        return PATTERN_SHOOTING_STAR;
    }
    
    // Pin Bar detection
    if((lowerWick > body * 2 || upperWick > body * 2) && body / range < 0.3) {
        return PATTERN_PIN_BAR;
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
//| Check if pattern is valid                                        |
//+------------------------------------------------------------------+
bool CSignalManager::IsPatternValid(ENUM_PATTERN_TYPE pattern) {
    return (pattern != PATTERN_NONE && GetPatternReliability(pattern) >= 0.5);
}

//+------------------------------------------------------------------+
//| Get pattern reliability                                          |
//+------------------------------------------------------------------+
double CSignalManager::GetPatternReliability(ENUM_PATTERN_TYPE pattern) {
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
//| Check multi-timeframe trend                                     |
//+------------------------------------------------------------------+
bool CSignalManager::CheckMultiTimeframeTrend(string direction) {
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_H1, PERIOD_H4, PERIOD_D1};
    int confirmedTrends = 0;
    
    for(int i = 0; i < ArraySize(timeframes); i++) {
        double ma20[], ma50[];
        
        if(CopyBuffer(iMA(_Symbol, timeframes[i], 20, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma20) <= 0 ||
           CopyBuffer(iMA(_Symbol, timeframes[i], 50, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma50) <= 0) {
            continue;
        }
        
        if(direction == "BUY" && ma20[0] > ma50[0]) {
            confirmedTrends++;
        } else if(direction == "SELL" && ma20[0] < ma50[0]) {
            confirmedTrends++;
        }
    }
    
    return confirmedTrends >= 2;
}

//+------------------------------------------------------------------+
//| Get timeframe correlation                                        |
//+------------------------------------------------------------------+
double CSignalManager::GetTimeframeCorrelation(ENUM_TIMEFRAMES tf1, ENUM_TIMEFRAMES tf2) {
    double ma1[], ma2[];
    
    if(CopyBuffer(iMA(_Symbol, tf1, 20, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma1) <= 0 ||
       CopyBuffer(iMA(_Symbol, tf2, 20, 0, MODE_SMA, PRICE_CLOSE), 0, 0, 1, ma2) <= 0) {
        return 0.0;
    }
    
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double corr1 = (ma1[0] - price) / price;
    double corr2 = (ma2[0] - price) / price;
    
    return MathAbs(corr1 - corr2) < 0.001 ? 0.9 : 0.1;
}

//+------------------------------------------------------------------+
//| Validate indicator correlations                                  |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateIndicatorCorrelations(string direction) {
    // RSI validation
    double rsi[];
    if(CopyBuffer(iRSI(_Symbol, _Period, 14, PRICE_CLOSE), 0, 0, 1, rsi) > 0) {
        if(direction == "BUY" && rsi[0] > 50) return true;
        if(direction == "SELL" && rsi[0] < 50) return true;
    }
    
    // MACD validation
    double macdMain[], macdSignal[];
    if(CopyBuffer(iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE), 0, 0, 1, macdMain) > 0 &&
       CopyBuffer(iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE), 1, 0, 1, macdSignal) > 0) {
        if(direction == "BUY" && macdMain[0] > macdSignal[0]) return true;
        if(direction == "SELL" && macdMain[0] < macdSignal[0]) return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Initialize cache                                                 |
//+------------------------------------------------------------------+
void CSignalManager::InitializeCache() {
    ArrayResize(m_validationCache, m_maxCacheSize);
    ArrayResize(m_patternCache, 50);
    ArrayResize(m_correlationState, 10);
    
    for(int i = 0; i < ArraySize(m_validationCache); i++) {
        m_validationCache[i].lastUpdate = 0;
        m_validationCache[i].isValid = false;
        m_validationCache[i].strength = 0.0;
        m_validationCache[i].confirmations = 0;
    }
}

//+------------------------------------------------------------------+
//| Validate cache                                                   |
//+------------------------------------------------------------------+
bool CSignalManager::ValidateCache() {
    datetime currentTime = TimeCurrent();
    for(int i = 0; i < ArraySize(m_validationCache); i++) {
        if(currentTime - m_validationCache[i].lastUpdate > 3600) {
            m_validationCache[i].isValid = false;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| Update correlation state                                         |
//+------------------------------------------------------------------+
void CSignalManager::UpdateCorrelationState() {
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < ArraySize(m_correlationState); i++) {
        if(currentTime - m_correlationState[i].lastUpdate > 300) {
            m_correlationState[i].maCorrelation = 0.7;
            m_correlationState[i].rsiCorrelation = 0.6;
            m_correlationState[i].macdCorrelation = 0.8;
            m_correlationState[i].lastUpdate = currentTime;
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                        |
//+------------------------------------------------------------------+
double CSignalManager::CalculateSignalStrength(const SignalInfo &signal) {
    double strength = 0.0;
    
    // Pattern reliability (40%)
    strength += GetPatternReliability(signal.pattern) * 0.4;
    
    // Trend alignment (30%)
    string direction = (signal.direction == SIGNAL_BUY) ? "BUY" : "SELL";
    if(CheckMultiTimeframeTrend(direction)) {
        strength += 0.3;
    }
    
    // Confirmations (20%)
    strength += MathMin(signal.confirmations / 3.0, 1.0) * 0.2;
    
    // Correlation (10%)
    strength += signal.correlation * 0.1;
    
    return MathMin(strength, 1.0);
}

//+------------------------------------------------------------------+
//| Add signal confirmations                                         |
//+------------------------------------------------------------------+
void CSignalManager::AddConfirmations(SignalInfo &signal) {
    signal.confirmations = 0;
    
    // Volume confirmation
    double volume[];
    if(CopyTickVolume(_Symbol, _Period, 0, 2, volume) > 0) {
        ArraySetAsSeries(volume, true);
        if(volume[0] > volume[1]) {
            signal.confirmations++;
        }
    }
    
    // Pattern confirmation
    if(IsPatternValid(signal.pattern)) {
        signal.confirmations++;
    }
    
    // Price action confirmation
    double close[];
    if(CopyClose(_Symbol, _Period, 0, 2, close) > 0) {
        ArraySetAsSeries(close, true);
        if(signal.direction == SIGNAL_BUY && close[0] > close[1]) {
            signal.confirmations++;
        } else if(signal.direction == SIGNAL_SELL && close[0] < close[1]) {
            signal.confirmations++;
        }
    }
}

//+------------------------------------------------------------------+
//| Clear cache                                                      |
//+------------------------------------------------------------------+
void CSignalManager::ClearCache() {
    for(int i = 0; i < ArraySize(m_validationCache); i++) {
        m_validationCache[i].isValid = false;
    }
}

//+------------------------------------------------------------------+
//| Get signal details                                               |
//+------------------------------------------------------------------+
string CSignalManager::GetSignalDetails(const SignalInfo &signal) {
    string details = "Signal: " + EnumToString(signal.direction) + 
                    " | Pattern: " + EnumToString(signal.pattern) +
                    " | Strength: " + DoubleToString(signal.strength, 2) +
                    " | Confirmations: " + IntegerToString(signal.confirmations);
    return details;
}

//+------------------------------------------------------------------+
//| Check if signals are duplicate                                   |
//+------------------------------------------------------------------+
bool CSignalManager::IsSignalDuplicate(const SignalInfo &s1, const SignalInfo &s2) {
    return (s1.direction == s2.direction && 
            s1.pattern == s2.pattern &&
            MathAbs(s1.entryPrice - s2.entryPrice) < _Point * 5 &&
            MathAbs(s1.timestamp - s2.timestamp) < 300);
}

//+------------------------------------------------------------------+
//| Get current signal                                               |
//+------------------------------------------------------------------+
SignalInfo CSignalManager::GetSignal() {
    return GenerateSignal();
}