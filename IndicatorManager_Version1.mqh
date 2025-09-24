//+------------------------------------------------------------------+
//|                                            IndicatorManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Indicator types enumeration                                      |
//+------------------------------------------------------------------+
enum ENUM_INDICATOR_TYPE {
    IND_MA = 0,
    IND_RSI,
    IND_MACD,
    IND_ATR,
    IND_BOLLINGER,
    IND_STOCHASTIC,
    IND_ADX,
    IND_VOLUME
};

//+------------------------------------------------------------------+
//| Indicator data structure                                         |
//+------------------------------------------------------------------+
struct IndicatorData {
    int handle;
    ENUM_INDICATOR_TYPE type;
    ENUM_TIMEFRAMES timeframe;
    double buffer[];
    bool isValid;
    datetime lastUpdate;
    string name;
};

//+------------------------------------------------------------------+
//| Correlation data structure                                       |
//+------------------------------------------------------------------+
struct CorrelationData {
    ENUM_INDICATOR_TYPE ind1;
    ENUM_INDICATOR_TYPE ind2;
    double correlation;
    datetime lastCalculated;
    bool isValid;
};

//+------------------------------------------------------------------+
//| Indicator Manager Class                                          |
//+------------------------------------------------------------------+
class CIndicatorManager {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframes[];
    IndicatorData m_indicators[];
    CorrelationData m_correlations[];
    
    int m_maxIndicators;
    int m_bufferSize;
    datetime m_lastUpdate;
    bool m_isInitialized;
    
    // Cache management
    struct CacheData {
        string key;
        double value;
        datetime timestamp;
        bool isValid;
    };
    
    CacheData m_cache[];
    int m_maxCacheSize;
    
public:
    // Constructor/Destructor
    CIndicatorManager(string symbol = "");
    ~CIndicatorManager();
    
    // Initialization methods
    bool Initialize(ENUM_TIMEFRAMES timeframes[], int bufferSize = 100);
    bool CreateIndicatorHandles();
    bool InitializeBuffers();
    bool ValidateHandles();
    
    // Buffer management methods
    bool UpdateIndicators();
    bool UpdateBuffer(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe);
    double GetBufferValue(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe, int shift = 0);
    double GetBufferValue(ENUM_INDICATOR_TYPE type, int timeframeIndex, int shift = 0);
    bool CopyIndicatorData(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe, double &buffer[]);
    
    // Correlation analysis methods
    bool UpdateCorrelations();
    double GetIndicatorCorrelation(ENUM_INDICATOR_TYPE ind1, ENUM_INDICATOR_TYPE ind2);
    bool CalculateCorrelation(ENUM_INDICATOR_TYPE ind1, ENUM_INDICATOR_TYPE ind2, int period = 20);
    void UpdateCorrelationMatrix();
    
    // Cache management
    bool InitializeCache();
    double GetCachedValue(string key);
    void SetCachedValue(string key, double value);
    void ClearCache();
    bool ValidateCache();
    
    // Advanced indicator methods
    double GetOptimizedMA(ENUM_TIMEFRAMES timeframe, int period = 20);
    double GetSmoothedRSI(ENUM_TIMEFRAMES timeframe, int period = 14);
    double GetFilteredMACD(ENUM_TIMEFRAMES timeframe);
    double GetNormalizedATR(ENUM_TIMEFRAMES timeframe, int period = 14);
    
    // Utility methods
    bool IsIndicatorReady(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe);
    string GetIndicatorName(ENUM_INDICATOR_TYPE type);
    int GetIndicatorHandle(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe);
    void PrintIndicatorStatus();
    
private:
    // Helper methods
    int FindIndicatorIndex(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe);
    bool CreateMAHandle(ENUM_TIMEFRAMES timeframe);
    bool CreateRSIHandle(ENUM_TIMEFRAMES timeframe);
    bool CreateMACDHandle(ENUM_TIMEFRAMES timeframe);
    bool CreateATRHandle(ENUM_TIMEFRAMES timeframe);
    bool CreateBollingerHandle(ENUM_TIMEFRAMES timeframe);
    bool CreateStochasticHandle(ENUM_TIMEFRAMES timeframe);
    bool CreateADXHandle(ENUM_TIMEFRAMES timeframe);
    bool CreateVolumeHandle(ENUM_TIMEFRAMES timeframe);
    
    double CalculatePearsonCorrelation(double &array1[], double &array2[], int period);
    bool ValidateIndicatorData(int indicatorIndex);
    void CleanupInvalidHandles();
    string GenerateCacheKey(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe, int shift);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIndicatorManager::CIndicatorManager(string symbol = "") {
    m_symbol = (symbol == "") ? _Symbol : symbol;
    m_maxIndicators = 50;
    m_bufferSize = 100;
    m_maxCacheSize = 500;
    m_lastUpdate = 0;
    m_isInitialized = false;
    
    ArrayResize(m_indicators, m_maxIndicators);
    ArrayResize(m_correlations, 20);
    ArrayResize(m_cache, m_maxCacheSize);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CIndicatorManager::~CIndicatorManager() {
    // Release all indicator handles
    for(int i = 0; i < ArraySize(m_indicators); i++) {
        if(m_indicators[i].handle != INVALID_HANDLE) {
            IndicatorRelease(m_indicators[i].handle);
        }
    }
    
    ArrayFree(m_indicators);
    ArrayFree(m_correlations);
    ArrayFree(m_cache);
    ArrayFree(m_timeframes);
}

//+------------------------------------------------------------------+
//| Initialize indicator manager                                     |
//+------------------------------------------------------------------+
bool CIndicatorManager::Initialize(ENUM_TIMEFRAMES timeframes[], int bufferSize = 100) {
    m_bufferSize = bufferSize;
    
    // Copy timeframes
    int tfCount = ArraySize(timeframes);
    ArrayResize(m_timeframes, tfCount);
    ArrayCopy(m_timeframes, timeframes);
    
    // Initialize cache
    if(!InitializeCache()) {
        Print("Failed to initialize cache");
        return false;
    }
    
    // Create indicator handles
    if(!CreateIndicatorHandles()) {
        Print("Failed to create indicator handles");
        return false;
    }
    
    // Initialize buffers
    if(!InitializeBuffers()) {
        Print("Failed to initialize buffers");
        return false;
    }
    
    // Validate handles
    if(!ValidateHandles()) {
        Print("Some indicator handles are invalid");
    }
    
    m_isInitialized = true;
    m_lastUpdate = TimeCurrent();
    
    Print("IndicatorManager initialized successfully for ", m_symbol);
    return true;
}

//+------------------------------------------------------------------+
//| Create indicator handles                                         |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateIndicatorHandles() {
    int indicatorIndex = 0;
    
    for(int tf = 0; tf < ArraySize(m_timeframes); tf++) {
        ENUM_TIMEFRAMES timeframe = m_timeframes[tf];
        
        // Create MA handles
        if(!CreateMAHandle(timeframe)) {
            Print("Failed to create MA handle for ", EnumToString(timeframe));
        }
        
        // Create RSI handles
        if(!CreateRSIHandle(timeframe)) {
            Print("Failed to create RSI handle for ", EnumToString(timeframe));
        }
        
        // Create MACD handles
        if(!CreateMACDHandle(timeframe)) {
            Print("Failed to create MACD handle for ", EnumToString(timeframe));
        }
        
        // Create ATR handles
        if(!CreateATRHandle(timeframe)) {
            Print("Failed to create ATR handle for ", EnumToString(timeframe));
        }
        
        // Create Bollinger handles
        if(!CreateBollingerHandle(timeframe)) {
            Print("Failed to create Bollinger handle for ", EnumToString(timeframe));
        }
        
        // Create Stochastic handles
        if(!CreateStochasticHandle(timeframe)) {
            Print("Failed to create Stochastic handle for ", EnumToString(timeframe));
        }
        
        // Create ADX handles
        if(!CreateADXHandle(timeframe)) {
            Print("Failed to create ADX handle for ", EnumToString(timeframe));
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize buffers                                               |
//+------------------------------------------------------------------+
bool CIndicatorManager::InitializeBuffers() {
    for(int i = 0; i < ArraySize(m_indicators); i++) {
        if(m_indicators[i].handle != INVALID_HANDLE) {
            ArrayResize(m_indicators[i].buffer, m_bufferSize);
            ArraySetAsSeries(m_indicators[i].buffer, true);
            m_indicators[i].isValid = true;
            m_indicators[i].lastUpdate = 0;
        }
    }
    return true;
}

//+------------------------------------------------------------------+
//| Validate indicator handles                                       |
//+------------------------------------------------------------------+
bool CIndicatorManager::ValidateHandles() {
    bool allValid = true;
    
    for(int i = 0; i < ArraySize(m_indicators); i++) {
        if(m_indicators[i].handle != INVALID_HANDLE) {
            if(!ValidateIndicatorData(i)) {
                m_indicators[i].isValid = false;
                allValid = false;
            }
        }
    }
    
    return allValid;
}

//+------------------------------------------------------------------+
//| Update all indicators                                            |
//+------------------------------------------------------------------+
bool CIndicatorManager::UpdateIndicators() {
    datetime currentTime = TimeCurrent();
    bool success = true;
    
    for(int i = 0; i < ArraySize(m_indicators); i++) {
        if(m_indicators[i].handle != INVALID_HANDLE && m_indicators[i].isValid) {
            if(!UpdateBuffer(m_indicators[i].type, m_indicators[i].timeframe)) {
                success = false;
            }
        }
    }
    
    m_lastUpdate = currentTime;
    return success;
}

//+------------------------------------------------------------------+
//| Update specific indicator buffer                                 |
//+------------------------------------------------------------------+
bool CIndicatorManager::UpdateBuffer(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe) {
    int index = FindIndicatorIndex(type, timeframe);
    if(index < 0 || m_indicators[index].handle == INVALID_HANDLE) {
        return false;
    }
    
    // Copy data from indicator to buffer
    int copied = CopyBuffer(m_indicators[index].handle, 0, 0, m_bufferSize, m_indicators[index].buffer);
    
    if(copied > 0) {
        m_indicators[index].lastUpdate = TimeCurrent();
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get buffer value                                                 |
//+------------------------------------------------------------------+
double CIndicatorManager::GetBufferValue(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe, int shift = 0) {
    int index = FindIndicatorIndex(type, timeframe);
    if(index < 0 || !m_indicators[index].isValid || shift >= ArraySize(m_indicators[index].buffer)) {
        return 0.0;
    }
    
    // Check cache first
    string cacheKey = GenerateCacheKey(type, timeframe, shift);
    double cachedValue = GetCachedValue(cacheKey);
    if(cachedValue != 0.0) {
        return cachedValue;
    }
    
    double value = m_indicators[index].buffer[shift];
    
    // Store in cache
    SetCachedValue(cacheKey, value);
    
    return value;
}

//+------------------------------------------------------------------+
//| Get buffer value by timeframe index                             |
//+------------------------------------------------------------------+
double CIndicatorManager::GetBufferValue(ENUM_INDICATOR_TYPE type, int timeframeIndex, int shift = 0) {
    if(timeframeIndex >= ArraySize(m_timeframes)) {
        return 0.0;
    }
    
    return GetBufferValue(type, m_timeframes[timeframeIndex], shift);
}

//+------------------------------------------------------------------+
//| Copy indicator data                                              |
//+------------------------------------------------------------------+
bool CIndicatorManager::CopyIndicatorData(ENUM_INDICATOR_TYPE type, ENUM_TIMEFRAMES timeframe, double &buffer[]) {
    int index = FindIndicatorIndex(type, timeframe);
    if(index < 0 || !m_indicators[index].isValid) {
        return false;
    }
    
    return ArrayCopy(buffer, m_indicators[index].buffer) > 0;
}

//+------------------------------------------------------------------+
//| Update correlations                                              |
//+------------------------------------------------------------------+
bool CIndicatorManager::UpdateCorrelations() {
    ENUM_INDICATOR_TYPE indicators[] = {IND_MA, IND_RSI, IND_MACD, IND_ATR};
    int indCount = ArraySize(indicators);
    int corrIndex = 0;
    
    for(int i = 0; i < indCount && corrIndex < ArraySize(m_correlations); i++) {
        for(int j = i + 1; j < indCount && corrIndex < ArraySize(m_correlations); j++) {
            if(CalculateCorrelation(indicators[i], indicators[j], 20)) {
                corrIndex++;
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get indicator correlation                                        |
//+------------------------------------------------------------------+
double CIndicatorManager::GetIndicatorCorrelation(ENUM_INDICATOR_TYPE ind1, ENUM_INDICATOR_TYPE ind2) {
    for(int i = 0; i < ArraySize(m_