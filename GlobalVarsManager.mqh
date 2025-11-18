//+------------------------------------------------------------------+
//|                                            GlobalVarsManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs_Version1.mqh"

//+------------------------------------------------------------------+
//| Global Variables Manager Class                                   |
//| Centralizes all global variables, shared arrays, and state       |
//+------------------------------------------------------------------+
class CGlobalVarsManager {
private:
    // System state
    bool m_isInitialized;
    bool m_isOptimization;
    bool m_isTesting;
    datetime m_startTime;
    datetime m_lastUpdate;
    
    // Trading state
    bool m_tradingEnabled;
    bool m_newBarDetected;
    int m_totalSignals;
    int m_validSignals;
    int m_executedTrades;
    int m_successfulTrades;
    
    // Market data
    string m_currentSymbol;
    ENUM_TIMEFRAMES m_currentTimeframe;
    double m_currentSpread;
    double m_currentAsk;
    double m_currentBid;
    
    // Pattern detection state
    ENUM_CANDLE_PATTERN m_lastPattern;
    datetime m_lastPatternTime;
    double m_lastPatternStrength;
    
    // Trend analysis state
    ENUM_TREND_DIRECTION m_currentTrend;
    double m_trendStrength;
    datetime m_trendChangeTime;
    
    // Risk management state
    double m_currentRisk;
    double m_dailyPnL;
    double m_maxDrawdown;
    bool m_riskLimitReached;
    
    // Error handling
    int m_lastErrorCode;
    string m_lastErrorMessage;
    datetime m_lastErrorTime;
    
    // Price level arrays
    PriceLevel m_supportLevels[];
    PriceLevel m_resistanceLevels[];
    PriceLevel m_swingHighs[];
    PriceLevel m_swingLows[];
    
    // Pattern history
    PatternAnalysis m_patternHistory[];
    int m_maxPatternHistory;
    
    // Performance metrics
    int m_totalCalculations;
    int m_averageCalculationTime;
    datetime m_performanceStartTime;
    
public:
    // Constructor/Destructor
    CGlobalVarsManager();
    ~CGlobalVarsManager();
    
    // Initialization
    bool Initialize();
    void Cleanup();
    
    // System state getters/setters
    bool IsInitialized() const { return m_isInitialized; }
    bool IsOptimization() const { return m_isOptimization; }
    bool IsTesting() const { return m_isTesting; }
    datetime GetStartTime() const { return m_startTime; }
    datetime GetLastUpdate() const { return m_lastUpdate; }
    void UpdateTimestamp() { m_lastUpdate = TimeCurrent(); }
    
    // Trading state getters/setters
    bool IsTradingEnabled() const { return m_tradingEnabled; }
    void SetTradingEnabled(bool enabled) { m_tradingEnabled = enabled; }
    bool IsNewBarDetected() const { return m_newBarDetected; }
    void SetNewBarDetected(bool detected) { m_newBarDetected = detected; }
    int GetTotalSignals() const { return m_totalSignals; }
    void IncrementTotalSignals() { m_totalSignals++; }
    int GetValidSignals() const { return m_validSignals; }
    void IncrementValidSignals() { m_validSignals++; }
    int GetExecutedTrades() const { return m_executedTrades; }
    void IncrementExecutedTrades() { m_executedTrades++; }
    int GetSuccessfulTrades() const { return m_successfulTrades; }
    void IncrementSuccessfulTrades() { m_successfulTrades++; }
    
    // Market data getters/setters
    string GetCurrentSymbol() const { return m_currentSymbol; }
    void SetCurrentSymbol(string symbol) { m_currentSymbol = symbol; }
    ENUM_TIMEFRAMES GetCurrentTimeframe() const { return m_currentTimeframe; }
    void SetCurrentTimeframe(ENUM_TIMEFRAMES timeframe) { m_currentTimeframe = timeframe; }
    double GetCurrentSpread() const { return m_currentSpread; }
    double GetCurrentAsk() const { return m_currentAsk; }
    double GetCurrentBid() const { return m_currentBid; }
    void UpdateMarketData();
    
    // Pattern detection state getters/setters
    ENUM_CANDLE_PATTERN GetLastPattern() const { return m_lastPattern; }
    void SetLastPattern(ENUM_CANDLE_PATTERN pattern, double strength);
    datetime GetLastPatternTime() const { return m_lastPatternTime; }
    double GetLastPatternStrength() const { return m_lastPatternStrength; }
    
    // Trend analysis state getters/setters
    ENUM_TREND_DIRECTION GetCurrentTrend() const { return m_currentTrend; }
    void SetCurrentTrend(ENUM_TREND_DIRECTION trend, double strength);
    double GetTrendStrength() const { return m_trendStrength; }
    datetime GetTrendChangeTime() const { return m_trendChangeTime; }
    
    // Risk management state getters/setters
    double GetCurrentRisk() const { return m_currentRisk; }
    void SetCurrentRisk(double risk) { m_currentRisk = risk; }
    double GetDailyPnL() const { return m_dailyPnL; }
    void SetDailyPnL(double pnl) { m_dailyPnL = pnl; }
    double GetMaxDrawdown() const { return m_maxDrawdown; }
    void SetMaxDrawdown(double drawdown) { m_maxDrawdown = drawdown; }
    bool IsRiskLimitReached() const { return m_riskLimitReached; }
    void SetRiskLimitReached(bool reached) { m_riskLimitReached = reached; }
    
    // Error handling
    int GetLastErrorCode() const { return m_lastErrorCode; }
    string GetLastErrorMessage() const { return m_lastErrorMessage; }
    datetime GetLastErrorTime() const { return m_lastErrorTime; }
    void LogError(int errorCode, string message);
    
    // Price level management
    bool AddSupportLevel(PriceLevel &level);
    bool AddResistanceLevel(PriceLevel &level);
    bool AddSwingHigh(PriceLevel &level);
    bool AddSwingLow(PriceLevel &level);
    int GetSupportLevelCount() const { return ArraySize(m_supportLevels); }
    int GetResistanceLevelCount() const { return ArraySize(m_resistanceLevels); }
    PriceLevel GetSupportLevel(int index);
    PriceLevel GetResistanceLevel(int index);
    PriceLevel GetSwingHigh(int index);
    PriceLevel GetSwingLow(int index);
    void ClearPriceLevels();
    
    // Pattern history management
    bool AddPatternToHistory(const PatternAnalysis &pattern);
    int GetPatternHistoryCount() const { return ArraySize(m_patternHistory); }
    PatternAnalysis GetPatternFromHistory(int index);
    void ClearPatternHistory();
    
    // Performance metrics
    void IncrementCalculations() { m_totalCalculations++; }
    int GetTotalCalculations() const { return m_totalCalculations; }
    void UpdatePerformanceMetrics();
    
    // Utility functions
    bool IsNewBar();
    bool IsMarketOpen();
    void PrintStatistics();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CGlobalVarsManager::CGlobalVarsManager() {
    m_isInitialized = false;
    m_isOptimization = false;
    m_isTesting = false;
    m_startTime = 0;
    m_lastUpdate = 0;
    
    m_tradingEnabled = true;
    m_newBarDetected = false;
    m_totalSignals = 0;
    m_validSignals = 0;
    m_executedTrades = 0;
    m_successfulTrades = 0;
    
    m_currentSymbol = _Symbol;
    m_currentTimeframe = _Period;
    m_currentSpread = 0.0;
    m_currentAsk = 0.0;
    m_currentBid = 0.0;
    
    m_lastPattern = PATTERN_NONE;
    m_lastPatternTime = 0;
    m_lastPatternStrength = 0.0;
    
    m_currentTrend = TREND_NONE;
    m_trendStrength = 0.0;
    m_trendChangeTime = 0;
    
    m_currentRisk = 0.0;
    m_dailyPnL = 0.0;
    m_maxDrawdown = 0.0;
    m_riskLimitReached = false;
    
    m_lastErrorCode = 0;
    m_lastErrorMessage = "";
    m_lastErrorTime = 0;
    
    m_maxPatternHistory = 100;
    
    m_totalCalculations = 0;
    m_averageCalculationTime = 0;
    m_performanceStartTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CGlobalVarsManager::~CGlobalVarsManager() {
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize global variables manager                              |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::Initialize() {
    m_isOptimization = MQLInfoInteger(MQL_OPTIMIZATION);
    m_isTesting = MQLInfoInteger(MQL_TESTER);
    m_startTime = TimeCurrent();
    m_currentSymbol = _Symbol;
    m_currentTimeframe = _Period;
    m_performanceStartTime = TimeCurrent();
    
    // Initialize arrays
    ArrayResize(m_supportLevels, 0);
    ArrayResize(m_resistanceLevels, 0);
    ArrayResize(m_swingHighs, 0);
    ArrayResize(m_swingLows, 0);
    ArrayResize(m_patternHistory, 0);
    
    UpdateMarketData();
    
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup global variables                                         |
//+------------------------------------------------------------------+
void CGlobalVarsManager::Cleanup() {
    ArrayFree(m_supportLevels);
    ArrayFree(m_resistanceLevels);
    ArrayFree(m_swingHighs);
    ArrayFree(m_swingLows);
    ArrayFree(m_patternHistory);
    
    m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Update market data                                               |
//+------------------------------------------------------------------+
void CGlobalVarsManager::UpdateMarketData() {
    m_currentAsk = SymbolInfoDouble(m_currentSymbol, SYMBOL_ASK);
    m_currentBid = SymbolInfoDouble(m_currentSymbol, SYMBOL_BID);
    m_currentSpread = m_currentAsk - m_currentBid;
    m_lastUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Set last pattern detected                                        |
//+------------------------------------------------------------------+
void CGlobalVarsManager::SetLastPattern(ENUM_CANDLE_PATTERN pattern, double strength) {
    m_lastPattern = pattern;
    m_lastPatternStrength = strength;
    m_lastPatternTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Set current trend                                                |
//+------------------------------------------------------------------+
void CGlobalVarsManager::SetCurrentTrend(ENUM_TREND_DIRECTION trend, double strength) {
    if(m_currentTrend != trend) {
        m_trendChangeTime = TimeCurrent();
    }
    m_currentTrend = trend;
    m_trendStrength = strength;
}

//+------------------------------------------------------------------+
//| Log error                                                        |
//+------------------------------------------------------------------+
void CGlobalVarsManager::LogError(int errorCode, string message) {
    m_lastErrorCode = errorCode;
    m_lastErrorMessage = message;
    m_lastErrorTime = TimeCurrent();
    Print("ERROR [", errorCode, "]: ", message);
}

//+------------------------------------------------------------------+
//| Add support level                                                |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::AddSupportLevel(PriceLevel &level) {
    int size = ArraySize(m_supportLevels);
    if(ArrayResize(m_supportLevels, size + 1) > 0) {
        m_supportLevels[size] = level;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Add resistance level                                             |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::AddResistanceLevel(PriceLevel &level) {
    int size = ArraySize(m_resistanceLevels);
    if(ArrayResize(m_resistanceLevels, size + 1) > 0) {
        m_resistanceLevels[size] = level;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Add swing high                                                   |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::AddSwingHigh(PriceLevel &level) {
    int size = ArraySize(m_swingHighs);
    if(ArrayResize(m_swingHighs, size + 1) > 0) {
        m_swingHighs[size] = level;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Add swing low                                                    |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::AddSwingLow(PriceLevel &level) {
    int size = ArraySize(m_swingLows);
    if(ArrayResize(m_swingLows, size + 1) > 0) {
        m_swingLows[size] = level;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get support level by index                                       |
//+------------------------------------------------------------------+
PriceLevel CGlobalVarsManager::GetSupportLevel(int index) {
    if(index >= 0 && index < ArraySize(m_supportLevels)) {
        return m_supportLevels[index];
    }
    PriceLevel empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get resistance level by index                                    |
//+------------------------------------------------------------------+
PriceLevel CGlobalVarsManager::GetResistanceLevel(int index) {
    if(index >= 0 && index < ArraySize(m_resistanceLevels)) {
        return m_resistanceLevels[index];
    }
    PriceLevel empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get swing high by index                                          |
//+------------------------------------------------------------------+
PriceLevel CGlobalVarsManager::GetSwingHigh(int index) {
    if(index >= 0 && index < ArraySize(m_swingHighs)) {
        return m_swingHighs[index];
    }
    PriceLevel empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get swing low by index                                           |
//+------------------------------------------------------------------+
PriceLevel CGlobalVarsManager::GetSwingLow(int index) {
    if(index >= 0 && index < ArraySize(m_swingLows)) {
        return m_swingLows[index];
    }
    PriceLevel empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Clear all price levels                                           |
//+------------------------------------------------------------------+
void CGlobalVarsManager::ClearPriceLevels() {
    ArrayResize(m_supportLevels, 0);
    ArrayResize(m_resistanceLevels, 0);
    ArrayResize(m_swingHighs, 0);
    ArrayResize(m_swingLows, 0);
}

//+------------------------------------------------------------------+
//| Add pattern to history                                           |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::AddPatternToHistory(const PatternAnalysis &pattern) {
    int size = ArraySize(m_patternHistory);
    
    // Limit history size
    if(size >= m_maxPatternHistory) {
        // Shift array to make room
        for(int i = 0; i < size - 1; i++) {
            m_patternHistory[i] = m_patternHistory[i + 1];
        }
        m_patternHistory[size - 1] = pattern;
    } else {
        if(ArrayResize(m_patternHistory, size + 1) > 0) {
            m_patternHistory[size] = pattern;
        } else {
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get pattern from history                                         |
//+------------------------------------------------------------------+
PatternAnalysis CGlobalVarsManager::GetPatternFromHistory(int index) {
    if(index >= 0 && index < ArraySize(m_patternHistory)) {
        return m_patternHistory[index];
    }
    PatternAnalysis empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Clear pattern history                                            |
//+------------------------------------------------------------------+
void CGlobalVarsManager::ClearPatternHistory() {
    ArrayResize(m_patternHistory, 0);
}

//+------------------------------------------------------------------+
//| Check for new bar                                                |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::IsNewBar() {
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(m_currentSymbol, m_currentTimeframe, 0);
    
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        m_newBarDetected = true;
        return true;
    }
    
    m_newBarDetected = false;
    return false;
}

//+------------------------------------------------------------------+
//| Check if market is open                                          |
//+------------------------------------------------------------------+
bool CGlobalVarsManager::IsMarketOpen() {
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    // Simple market hours check
    if(dt.day_of_week == 0 || dt.day_of_week == 6) return false; // Weekend
    if(dt.hour < 1 || dt.hour > 23) return false; // Outside trading hours
    
    return true;
}

//+------------------------------------------------------------------+
//| Update performance metrics                                       |
//+------------------------------------------------------------------+
void CGlobalVarsManager::UpdatePerformanceMetrics() {
    m_totalCalculations++;
    
    if(m_performanceStartTime == 0) {
        m_performanceStartTime = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Print statistics                                                 |
//+------------------------------------------------------------------+
void CGlobalVarsManager::PrintStatistics() {
    Print("=== Global Variables Statistics ===");
    Print("Total Signals: ", m_totalSignals);
    Print("Valid Signals: ", m_validSignals);
    Print("Executed Trades: ", m_executedTrades);
    Print("Successful Trades: ", m_successfulTrades);
    Print("Current Trend: ", EnumToString(m_currentTrend));
    Print("Trend Strength: ", m_trendStrength);
    Print("Daily P&L: ", m_dailyPnL);
    Print("Max Drawdown: ", m_maxDrawdown);
    Print("Support Levels: ", ArraySize(m_supportLevels));
    Print("Resistance Levels: ", ArraySize(m_resistanceLevels));
    Print("Pattern History: ", ArraySize(m_patternHistory));
    Print("===================================");
}
