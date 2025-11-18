//+------------------------------------------------------------------+
//|                                   MultiSymbolScanner_Enhanced.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "PriceActionAnalyzer_Enhanced.mqh"
#include "Utilities_Enhanced.mqh"
#include "LogManager_Version1.mqh"

//+------------------------------------------------------------------+
//| Symbol Scan Result Structure                                    |
//+------------------------------------------------------------------+
struct SymbolScanResult {
    string symbol;
    double score;
    bool hasBuySignal;
    bool hasSellSignal;
    string patterns;
    double strength;
    ENUM_SIGNAL_DIRECTION direction;
    datetime scanTime;
    
    // Key levels
    double support;
    double resistance;
    double swingHigh;
    double swingLow;
    
    // Trend information
    bool isUptrend;
    bool isDowntrend;
    bool isSideways;
    
    // Pattern details
    bool pinBar;
    bool doji;
    bool engulfing;
    bool breakOfStructure;
    bool retracement;
    
    // Risk metrics
    double riskReward;
    double volatility;
    double spread;
};

//+------------------------------------------------------------------+
//| Multi-Symbol Scanner Class                                      |
//+------------------------------------------------------------------+
class CMultiSymbolScannerEnhanced {
private:
    CLogManager* m_logger;
    CPriceActionAnalyzerEnhanced* m_analyzers[];
    
    string m_symbols[];
    int m_symbolCount;
    datetime m_lastScanTime;
    int m_scanIntervalMinutes;
    
    SymbolScanResult m_scanResults[];
    int m_resultCount;
    
    // Configuration
    ENUM_TIMEFRAMES m_primaryTimeframe;
    ENUM_TIMEFRAMES m_executionTimeframe;
    int m_candlesToAnalyze;
    int m_patternScanCandles;
    double m_minScore;
    double m_minRiskReward;
    
    // Performance tracking
    ulong m_totalScanTime;
    int m_totalScans;
    
public:
    CMultiSymbolScannerEnhanced(CLogManager* logger);
    ~CMultiSymbolScannerEnhanced();
    
    // Initialization
    bool Initialize(string symbolList, ENUM_TIMEFRAMES primaryTF, ENUM_TIMEFRAMES executionTF);
    void SetScanParameters(int candlesToAnalyze, int patternCandles, int intervalMinutes);
    void SetFilterParameters(double minScore, double minRiskReward);
    
    // Scanning Methods
    bool ScanAllSymbols();
    bool ScanSymbol(string symbol);
    SymbolScanResult GetSymbolResult(string symbol);
    SymbolScanResult[] GetTopResults(int maxResults = 10);
    SymbolScanResult[] GetBuySignals(int maxResults = 5);
    SymbolScanResult[] GetSellSignals(int maxResults = 5);
    
    // Analysis Methods
    double CalculateSymbolScore(string symbol, const SymbolScanResult &result);
    bool HasValidSignal(const SymbolScanResult &result);
    bool PassesFilters(const SymbolScanResult &result);
    
    // Information Methods
    int GetScanResultCount();
    datetime GetLastScanTime();
    string GetScanSummary();
    string GetPerformanceReport();
    
    // Symbol Management
    bool AddSymbol(string symbol);
    bool RemoveSymbol(string symbol);
    void ClearSymbols();
    string[] GetScannedSymbols();
    
    // Utility Methods
    void SortResultsByScore();
    void SortResultsByStrength();
    void FilterResults(double minScore = 0.0);
    void ClearResults();
    
    // Export Methods
    bool ExportResultsToFile(string fileName);
    string ResultsToJSON();
    string ResultsToCSV();
    
private:
    bool InitializeSymbol(string symbol);
    void CleanupAnalyzers();
    int FindSymbolIndex(string symbol);
    int FindResultIndex(string symbol);
    void AddResult(const SymbolScanResult &result);
    void UpdateResult(int index, const SymbolScanResult &result);
    
    // Analysis helper methods
    bool AnalyzeKeyLevels(string symbol, SymbolScanResult &result);
    bool AnalyzeTrend(string symbol, SymbolScanResult &result);
    bool AnalyzePatterns(string symbol, SymbolScanResult &result);
    bool AnalyzeRiskMetrics(string symbol, SymbolScanResult &result);
    
    // Sorting helper methods
    static int CompareByScore(const SymbolScanResult &a, const SymbolScanResult &b);
    static int CompareByStrength(const SymbolScanResult &a, const SymbolScanResult &b);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMultiSymbolScannerEnhanced::CMultiSymbolScannerEnhanced(CLogManager* logger) {
    m_logger = logger;
    m_symbolCount = 0;
    m_resultCount = 0;
    m_lastScanTime = 0;
    m_scanIntervalMinutes = 5;
    
    // Default configuration
    m_primaryTimeframe = PERIOD_H1;
    m_executionTimeframe = PERIOD_M5;
    m_candlesToAnalyze = 100;
    m_patternScanCandles = 20;
    m_minScore = 0.6;
    m_minRiskReward = 1.5;
    
    // Performance tracking
    m_totalScanTime = 0;
    m_totalScans = 0;
    
    // Initialize arrays
    ArrayResize(m_symbols, 50);
    ArrayResize(m_analyzers, 50);
    ArrayResize(m_scanResults, 50);
    
    if(m_logger) m_logger.LogInfo("Multi-symbol scanner initialized", "SCANNER");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMultiSymbolScannerEnhanced::~CMultiSymbolScannerEnhanced() {
    CleanupAnalyzers();
    
    if(m_logger) m_logger.LogInfo("Multi-symbol scanner destroyed", "SCANNER");
}

//+------------------------------------------------------------------+
//| Initialize scanner with symbol list                            |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::Initialize(string symbolList, ENUM_TIMEFRAMES primaryTF, ENUM_TIMEFRAMES executionTF) {
    m_primaryTimeframe = primaryTF;
    m_executionTimeframe = executionTF;
    
    // Parse symbol list
    string symbols[] = CUtilitiesEnhanced::SplitString(symbolList, ",");
    
    bool allInitialized = true;
    
    for(int i = 0; i < ArraySize(symbols); i++) {
        string symbol = CUtilitiesEnhanced::TrimString(symbols[i]);
        if(symbol != "" && !AddSymbol(symbol)) {
            allInitialized = false;
            if(m_logger) m_logger.LogWarning("Failed to add symbol: " + symbol, "SCANNER");
        }
    }
    
    if(m_logger) {
        m_logger.LogInfo(StringFormat("Scanner initialized with %d symbols", m_symbolCount), "SCANNER");
    }
    
    return allInitialized;
}

//+------------------------------------------------------------------+
//| Set scan parameters                                             |
//+------------------------------------------------------------------+
void CMultiSymbolScannerEnhanced::SetScanParameters(int candlesToAnalyze, int patternCandles, int intervalMinutes) {
    m_candlesToAnalyze = candlesToAnalyze;
    m_patternScanCandles = patternCandles;
    m_scanIntervalMinutes = intervalMinutes;
    
    if(m_logger) {
        m_logger.LogInfo(StringFormat("Scan parameters updated: Candles=%d, Patterns=%d, Interval=%d min", 
                        candlesToAnalyze, patternCandles, intervalMinutes), "SCANNER");
    }
}

//+------------------------------------------------------------------+
//| Set filter parameters                                           |
//+------------------------------------------------------------------+
void CMultiSymbolScannerEnhanced::SetFilterParameters(double minScore, double minRiskReward) {
    m_minScore = minScore;
    m_minRiskReward = minRiskReward;
}

//+------------------------------------------------------------------+
//| Scan all symbols                                               |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::ScanAllSymbols() {
    if(m_symbolCount == 0) {
        if(m_logger) m_logger.LogWarning("No symbols to scan", "SCANNER");
        return false;
    }
    
    ulong startTime = GetTickCount();
    
    ClearResults();
    
    int successCount = 0;
    for(int i = 0; i < m_symbolCount; i++) {
        if(ScanSymbol(m_symbols[i])) {
            successCount++;
        }
    }
    
    m_lastScanTime = TimeCurrent();
    m_totalScanTime += (GetTickCount() - startTime);
    m_totalScans++;
    
    // Sort results by score
    SortResultsByScore();
    
    if(m_logger) {
        m_logger.LogInfo(StringFormat("Scan completed: %d/%d symbols successful, %d results", 
                        successCount, m_symbolCount, m_resultCount), "SCANNER");
    }
    
    return (successCount > 0);
}

//+------------------------------------------------------------------+
//| Scan individual symbol                                          |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::ScanSymbol(string symbol) {
    int symbolIndex = FindSymbolIndex(symbol);
    if(symbolIndex < 0 || m_analyzers[symbolIndex] == NULL) {
        return false;
    }
    
    SymbolScanResult result;
    ZeroMemory(result);
    
    result.symbol = symbol;
    result.scanTime = TimeCurrent();
    result.direction = SIGNAL_NONE;
    
    // Analyze key levels
    if(!AnalyzeKeyLevels(symbol, result)) {
        if(m_logger) m_logger.LogWarning("Failed to analyze key levels for " + symbol, "SCANNER");
        return false;
    }
    
    // Analyze trend
    if(!AnalyzeTrend(symbol, result)) {
        if(m_logger) m_logger.LogWarning("Failed to analyze trend for " + symbol, "SCANNER");
        return false;
    }
    
    // Analyze patterns
    if(!AnalyzePatterns(symbol, result)) {
        if(m_logger) m_logger.LogWarning("Failed to analyze patterns for " + symbol, "SCANNER");
        return false;
    }
    
    // Analyze risk metrics
    if(!AnalyzeRiskMetrics(symbol, result)) {
        if(m_logger) m_logger.LogWarning("Failed to analyze risk metrics for " + symbol, "SCANNER");
        return false;
    }
    
    // Calculate overall score
    result.score = CalculateSymbolScore(symbol, result);
    
    // Determine signals
    if(result.isUptrend && (result.pinBar || result.doji || result.engulfing || result.retracement)) {
        result.hasBuySignal = true;
        result.direction = SIGNAL_BUY;
    }
    
    if(result.isDowntrend && (result.pinBar || result.doji || result.engulfing || result.retracement)) {
        result.hasSellSignal = true;
        result.direction = SIGNAL_SELL;
    }
    
    // Add result if it passes filters
    if(PassesFilters(result)) {
        AddResult(result);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get symbol scan result                                          |
//+------------------------------------------------------------------+
SymbolScanResult CMultiSymbolScannerEnhanced::GetSymbolResult(string symbol) {
    SymbolScanResult emptyResult;
    ZeroMemory(emptyResult);
    
    int index = FindResultIndex(symbol);
    if(index >= 0) {
        return m_scanResults[index];
    }
    
    return emptyResult;
}

//+------------------------------------------------------------------+
//| Get top results by score                                       |
//+------------------------------------------------------------------+
SymbolScanResult[] CMultiSymbolScannerEnhanced::GetTopResults(int maxResults = 10) {
    SymbolScanResult results[];
    int count = MathMin(maxResults, m_resultCount);
    
    ArrayResize(results, count);
    
    for(int i = 0; i < count; i++) {
        results[i] = m_scanResults[i];
    }
    
    return results;
}

//+------------------------------------------------------------------+
//| Get buy signals                                                |
//+------------------------------------------------------------------+
SymbolScanResult[] CMultiSymbolScannerEnhanced::GetBuySignals(int maxResults = 5) {
    SymbolScanResult results[];
    int count = 0;
    
    ArrayResize(results, maxResults);
    
    for(int i = 0; i < m_resultCount && count < maxResults; i++) {
        if(m_scanResults[i].hasBuySignal) {
            results[count] = m_scanResults[i];
            count++;
        }
    }
    
    ArrayResize(results, count);
    return results;
}

//+------------------------------------------------------------------+
//| Get sell signals                                               |
//+------------------------------------------------------------------+
SymbolScanResult[] CMultiSymbolScannerEnhanced::GetSellSignals(int maxResults = 5) {
    SymbolScanResult results[];
    int count = 0;
    
    ArrayResize(results, maxResults);
    
    for(int i = 0; i < m_resultCount && count < maxResults; i++) {
        if(m_scanResults[i].hasSellSignal) {
            results[count] = m_scanResults[i];
            count++;
        }
    }
    
    ArrayResize(results, count);
    return results;
}

//+------------------------------------------------------------------+
//| Calculate symbol score                                          |
//+------------------------------------------------------------------+
double CMultiSymbolScannerEnhanced::CalculateSymbolScore(string symbol, const SymbolScanResult &result) {
    double score = 0.0;
    
    // Trend component (30%)
    if(result.isUptrend || result.isDowntrend) {
        score += 0.3;
    }
    
    // Pattern component (40%)
    double patternScore = 0.0;
    if(result.pinBar) patternScore += 0.1;
    if(result.doji) patternScore += 0.1;
    if(result.engulfing) patternScore += 0.15;
    if(result.breakOfStructure) patternScore += 0.1;
    if(result.retracement) patternScore += 0.05;
    
    score += patternScore;
    
    // Risk-reward component (20%)
    if(result.riskReward >= m_minRiskReward) {
        score += 0.2 * MathMin(result.riskReward / 3.0, 1.0); // Cap at 3:1 ratio
    }
    
    // Volatility component (10%)
    if(result.volatility > 0) {
        double avgVolatility = CUtilitiesEnhanced::GetAverageRange(20, 0, m_primaryTimeframe, symbol);
        if(avgVolatility > 0) {
            double volRatio = result.volatility / avgVolatility;
            if(volRatio >= 0.8 && volRatio <= 1.5) { // Optimal volatility range
                score += 0.1;
            }
        }
    }
    
    return MathMin(score, 1.0); // Cap at 1.0
}

//+------------------------------------------------------------------+
//| Check if result has valid signal                               |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::HasValidSignal(const SymbolScanResult &result) {
    return (result.hasBuySignal || result.hasSellSignal) && result.score >= m_minScore;
}

//+------------------------------------------------------------------+
//| Check if result passes filters                                 |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::PassesFilters(const SymbolScanResult &result) {
    // Score filter
    if(result.score < m_minScore) return false;
    
    // Risk-reward filter
    if(result.riskReward < m_minRiskReward) return false;
    
    // Spread filter (max 3 pips for majors)
    double maxSpread = CUtilitiesEnhanced::IsForexPair(result.symbol) ? 3.0 : 10.0;
    if(CUtilitiesEnhanced::PointsToPips(result.spread, result.symbol) > maxSpread) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Add symbol to scanner                                           |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::AddSymbol(string symbol) {
    // Check if symbol already exists
    if(FindSymbolIndex(symbol) >= 0) {
        return true; // Already exists
    }
    
    // Check if we have space
    if(m_symbolCount >= ArraySize(m_symbols)) {
        ArrayResize(m_symbols, m_symbolCount + 10);
        ArrayResize(m_analyzers, m_symbolCount + 10);
    }
    
    // Initialize symbol
    if(!InitializeSymbol(symbol)) {
        return false;
    }
    
    m_symbols[m_symbolCount] = symbol;
    m_symbolCount++;
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize symbol for scanning                                 |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::InitializeSymbol(string symbol) {
    // Check if symbol exists in market watch
    if(!SymbolSelect(symbol, true)) {
        if(m_logger) m_logger.LogWarning("Symbol not available: " + symbol, "SCANNER");
        return false;
    }
    
    // Create price action analyzer
    CPriceActionAnalyzerEnhanced* analyzer = new CPriceActionAnalyzerEnhanced(symbol, m_primaryTimeframe, m_candlesToAnalyze);
    if(analyzer == NULL) {
        if(m_logger) m_logger.LogError("Failed to create analyzer for: " + symbol, "SCANNER");
        return false;
    }
    
    m_analyzers[m_symbolCount] = analyzer;
    
    if(m_logger) m_logger.LogInfo("Symbol initialized: " + symbol, "SCANNER");
    return true;
}

//+------------------------------------------------------------------+
//| Analyze key levels for symbol                                  |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::AnalyzeKeyLevels(string symbol, SymbolScanResult &result) {
    // Get current price
    MqlTick tick;
    if(!SymbolInfoTick(symbol, tick)) return false;
    
    double currentPrice = (tick.bid + tick.ask) / 2.0;
    
    int symbolIndex = FindSymbolIndex(symbol);
    if(symbolIndex < 0 || m_analyzers[symbolIndex] == NULL) return false;
    
    CPriceActionAnalyzerEnhanced* analyzer = m_analyzers[symbolIndex];
    
    // Find key levels
    result.support = analyzer.FindNearestSupport(currentPrice, 50);
    result.resistance = analyzer.FindNearestResistance(currentPrice, 50);
    
    // Find swing points
    result.swingHigh = CUtilitiesEnhanced::GetHighestHigh(20, 1, m_primaryTimeframe, symbol);
    result.swingLow = CUtilitiesEnhanced::GetLowestLow(20, 1, m_primaryTimeframe, symbol);
    
    return true;
}

//+------------------------------------------------------------------+
//| Analyze trend for symbol                                       |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::AnalyzeTrend(string symbol, SymbolScanResult &result) {
    int symbolIndex = FindSymbolIndex(symbol);
    if(symbolIndex < 0 || m_analyzers[symbolIndex] == NULL) return false;
    
    CPriceActionAnalyzerEnhanced* analyzer = m_analyzers[symbolIndex];
    
    result.isUptrend = analyzer.IsUptrend(20);
    result.isDowntrend = analyzer.IsDowntrend(20);
    result.isSideways = analyzer.IsSideways(20);
    
    return true;
}

//+------------------------------------------------------------------+
//| Analyze patterns for symbol                                    |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::AnalyzePatterns(string symbol, SymbolScanResult &result) {
    int symbolIndex = FindSymbolIndex(symbol);
    if(symbolIndex < 0 || m_analyzers[symbolIndex] == NULL) return false;
    
    CPriceActionAnalyzerEnhanced* analyzer = m_analyzers[symbolIndex];
    
    // Check for patterns in recent candles
    for(int i = 0; i < m_patternScanCandles; i++) {
        if(analyzer.IsPinBar(i)) result.pinBar = true;
        if(analyzer.IsDoji(i)) result.doji = true;
        if(analyzer.IsBullishEngulfing(i) || analyzer.IsBearishEngulfing(i)) result.engulfing = true;
        if(analyzer.IsBreakOfStructure(i)) result.breakOfStructure = true;
    }
    
    // Check for retracement (simplified)
    MqlTick tick;
    if(SymbolInfoTick(symbol, tick)) {
        double currentPrice = (tick.bid + tick.ask) / 2.0;
        double range = result.swingHigh - result.swingLow;
        
        if(range > 0) {
            double retracementLevel = result.swingLow + (range * 0.618); // 61.8% Fibonacci
            result.retracement = (MathAbs(currentPrice - retracementLevel) <= range * 0.05);
        }
    }
    
    // Build patterns string
    string patterns = "";
    if(result.pinBar) patterns += "PinBar,";
    if(result.doji) patterns += "Doji,";
    if(result.engulfing) patterns += "Engulfing,";
    if(result.breakOfStructure) patterns += "BOS,";
    if(result.retracement) patterns += "Retracement,";
    
    if(StringLen(patterns) > 0) {
        patterns = StringSubstr(patterns, 0, StringLen(patterns) - 1); // Remove last comma
    }
    
    result.patterns = patterns;
    
    return true;
}

//+------------------------------------------------------------------+
//| Analyze risk metrics for symbol                                |
//+------------------------------------------------------------------+
bool CMultiSymbolScannerEnhanced::AnalyzeRiskMetrics(string symbol, SymbolScanResult &result) {
    // Calculate risk-reward ratio
    MqlTick tick;
    if(!SymbolInfoTick(symbol, tick)) return false;
    
    double currentPrice = (tick.bid + tick.ask) / 2.0;
    double stopLoss = result.isUptrend ? result.support : result.resistance;
    double takeProfit = result.isUptrend ? result.resistance : result.support;
    
    if(stopLoss > 0 && takeProfit > 0) {
        result.riskReward = CUtilitiesEnhanced::CalculateRiskRewardRatio(currentPrice, stopLoss, takeProfit, result.isUptrend);
    }
    
    // Calculate volatility (average range)
    result.volatility = CUtilitiesEnhanced::GetAverageRange(20, 0, m_primaryTimeframe, symbol);
    
    // Get spread
    result.spread = CUtilitiesEnhanced::GetSpread(symbol);
    
    return true;
}

//+------------------------------------------------------------------+
//| Find symbol index in array                                     |
//+------------------------------------------------------------------+
int CMultiSymbolScannerEnhanced::FindSymbolIndex(string symbol) {
    for(int i = 0; i < m_symbolCount; i++) {
        if(m_symbols[i] == symbol) return i;
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Find result index in array                                     |
//+------------------------------------------------------------------+
int CMultiSymbolScannerEnhanced::FindResultIndex(string symbol) {
    for(int i = 0; i < m_resultCount; i++) {
        if(m_scanResults[i].symbol == symbol) return i;
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Add result to array                                            |
//+------------------------------------------------------------------+
void CMultiSymbolScannerEnhanced::AddResult(const SymbolScanResult &result) {
    if(m_resultCount >= ArraySize(m_scanResults)) {
        ArrayResize(m_scanResults, m_resultCount + 10);
    }
    
    m_scanResults[m_resultCount] = result;
    m_resultCount++;
}

//+------------------------------------------------------------------+
//| Sort results by score                                          |
//+------------------------------------------------------------------+
void CMultiSymbolScannerEnhanced::SortResultsByScore() {
    // Simple bubble sort by score (descending)
    for(int i = 0; i < m_resultCount - 1; i++) {
        for(int j = 0; j < m_resultCount - 1 - i; j++) {
            if(m_scanResults[j].score < m_scanResults[j + 1].score) {
                SymbolScanResult temp = m_scanResults[j];
                m_scanResults[j] = m_scanResults[j + 1];
                m_scanResults[j + 1] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Clear all results                                              |
//+------------------------------------------------------------------+
void CMultiSymbolScannerEnhanced::ClearResults() {
    m_resultCount = 0;
}

//+------------------------------------------------------------------+
//| Cleanup analyzers                                              |
//+------------------------------------------------------------------+
void CMultiSymbolScannerEnhanced::CleanupAnalyzers() {
    for(int i = 0; i < m_symbolCount; i++) {
        if(m_analyzers[i] != NULL) {
            delete m_analyzers[i];
            m_analyzers[i] = NULL;
        }
    }
}

//+------------------------------------------------------------------+
//| Get scan summary                                               |
//+------------------------------------------------------------------+
string CMultiSymbolScannerEnhanced::GetScanSummary() {
    int buySignals = 0, sellSignals = 0;
    double avgScore = 0.0;
    
    for(int i = 0; i < m_resultCount; i++) {
        if(m_scanResults[i].hasBuySignal) buySignals++;
        if(m_scanResults[i].hasSellSignal) sellSignals++;
        avgScore += m_scanResults[i].score;
    }
    
    if(m_resultCount > 0) avgScore /= m_resultCount;
    
    string summary = StringFormat(
        "=== Scan Summary ===\n" +
        "Symbols Scanned: %d\n" +
        "Results Found: %d\n" +
        "Buy Signals: %d\n" +
        "Sell Signals: %d\n" +
        "Average Score: %.2f\n" +
        "Last Scan: %s\n",
        m_symbolCount, m_resultCount, buySignals, sellSignals, avgScore,
        TimeToString(m_lastScanTime)
    );
    
    return summary;
}

//+------------------------------------------------------------------+
//| Get performance report                                          |
//+------------------------------------------------------------------+
string CMultiSymbolScannerEnhanced::GetPerformanceReport() {
    double avgScanTime = m_totalScans > 0 ? (double)m_totalScanTime / m_totalScans : 0.0;
    
    string report = StringFormat(
        "=== Performance Report ===\n" +
        "Total Scans: %d\n" +
        "Total Scan Time: %d ms\n" +
        "Average Scan Time: %.2f ms\n" +
        "Symbols per Scan: %d\n",
        m_totalScans, (int)m_totalScanTime, avgScanTime, m_symbolCount
    );
    
    return report;
}

//+------------------------------------------------------------------+