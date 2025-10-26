//+------------------------------------------------------------------+
//|                                         MultiSymbolScanner.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs_Version1.mqh"

//+------------------------------------------------------------------+
//| Symbol Scan Result Structure                                     |
//+------------------------------------------------------------------+
struct SymbolScanResult {
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    bool hasSignal;
    ENUM_SIGNAL_DIRECTION signalDirection;
    double signalStrength;
    datetime scanTime;
    string description;
};

//+------------------------------------------------------------------+
//| Multi-Symbol Scanner Class                                       |
//| Scans multiple symbols/timeframes efficiently                    |
//+------------------------------------------------------------------+
class CMultiSymbolScanner {
private:
    string m_symbols[];
    ENUM_TIMEFRAMES m_timeframes[];
    int m_symbolCount;
    int m_timeframeCount;
    int m_scanIntervalSeconds;
    datetime m_lastScanTime;
    bool m_isScanning;
    SymbolScanResult m_scanResults[];
    int m_maxResults;
    
public:
    // Constructor/Destructor
    CMultiSymbolScanner();
    ~CMultiSymbolScanner();
    
    // Initialization
    bool Initialize(int scanIntervalMinutes = 5);
    bool AddSymbol(string symbol);
    bool AddTimeframe(ENUM_TIMEFRAMES timeframe);
    bool RemoveSymbol(string symbol);
    void ClearSymbols();
    void ClearTimeframes();
    
    // Scanning operations
    bool ScanAllMarkets();
    bool ScanSymbol(string symbol, ENUM_TIMEFRAMES timeframe);
    bool IsTimeToScan();
    bool IsScanning() const { return m_isScanning; }
    
    // Results management
    int GetResultCount() const { return ArraySize(m_scanResults); }
    SymbolScanResult GetResult(int index);
    void ClearResults();
    SymbolScanResult[] GetAllResults();
    int GetSignalCount();
    
    // Symbol management
    int GetSymbolCount() const { return m_symbolCount; }
    string GetSymbol(int index);
    bool IsSymbolValid(string symbol);
    
    // Timeframe management
    int GetTimeframeCount() const { return m_timeframeCount; }
    ENUM_TIMEFRAMES GetTimeframe(int index);
    
    // Configuration
    void SetScanInterval(int minutes);
    int GetScanInterval() const { return m_scanIntervalSeconds / 60; }
    datetime GetLastScanTime() const { return m_lastScanTime; }
    
    // Utility
    void PrintScanResults();
    
private:
    bool ValidateSymbol(string symbol);
    bool AddScanResult(const SymbolScanResult &result);
    void LimitResultsSize();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CMultiSymbolScanner::CMultiSymbolScanner() {
    m_symbolCount = 0;
    m_timeframeCount = 0;
    m_scanIntervalSeconds = 300; // 5 minutes default
    m_lastScanTime = 0;
    m_isScanning = false;
    m_maxResults = 1000; // Maximum scan results to keep
    
    ArrayResize(m_symbols, 0);
    ArrayResize(m_timeframes, 0);
    ArrayResize(m_scanResults, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CMultiSymbolScanner::~CMultiSymbolScanner() {
    ArrayFree(m_symbols);
    ArrayFree(m_timeframes);
    ArrayFree(m_scanResults);
}

//+------------------------------------------------------------------+
//| Initialize scanner with default settings                         |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::Initialize(int scanIntervalMinutes = 5) {
    m_scanIntervalSeconds = scanIntervalMinutes * 60;
    
    // Add current symbol by default
    if(!AddSymbol(_Symbol)) {
        Print("Failed to add default symbol: ", _Symbol);
        return false;
    }
    
    // Add current timeframe by default
    if(!AddTimeframe(_Period)) {
        Print("Failed to add default timeframe");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Add symbol to scan list                                          |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::AddSymbol(string symbol) {
    // Validate symbol first
    if(!ValidateSymbol(symbol)) {
        Print("Invalid symbol: ", symbol);
        return false;
    }
    
    // Check if symbol already exists
    for(int i = 0; i < m_symbolCount; i++) {
        if(m_symbols[i] == symbol) {
            return true; // Already exists
        }
    }
    
    // Add symbol
    if(ArrayResize(m_symbols, m_symbolCount + 1) > 0) {
        m_symbols[m_symbolCount] = symbol;
        m_symbolCount++;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Add timeframe to scan list                                       |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::AddTimeframe(ENUM_TIMEFRAMES timeframe) {
    // Check if timeframe already exists
    for(int i = 0; i < m_timeframeCount; i++) {
        if(m_timeframes[i] == timeframe) {
            return true; // Already exists
        }
    }
    
    // Add timeframe
    if(ArrayResize(m_timeframes, m_timeframeCount + 1) > 0) {
        m_timeframes[m_timeframeCount] = timeframe;
        m_timeframeCount++;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Remove symbol from scan list                                     |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::RemoveSymbol(string symbol) {
    for(int i = 0; i < m_symbolCount; i++) {
        if(m_symbols[i] == symbol) {
            // Shift remaining symbols
            for(int j = i; j < m_symbolCount - 1; j++) {
                m_symbols[j] = m_symbols[j + 1];
            }
            m_symbolCount--;
            ArrayResize(m_symbols, m_symbolCount);
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Clear all symbols                                                |
//+------------------------------------------------------------------+
void CMultiSymbolScanner::ClearSymbols() {
    ArrayResize(m_symbols, 0);
    m_symbolCount = 0;
}

//+------------------------------------------------------------------+
//| Clear all timeframes                                             |
//+------------------------------------------------------------------+
void CMultiSymbolScanner::ClearTimeframes() {
    ArrayResize(m_timeframes, 0);
    m_timeframeCount = 0;
}

//+------------------------------------------------------------------+
//| Check if it's time to scan                                       |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::IsTimeToScan() {
    datetime currentTime = TimeCurrent();
    return (currentTime - m_lastScanTime >= m_scanIntervalSeconds);
}

//+------------------------------------------------------------------+
//| Scan all markets (symbols and timeframes)                        |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::ScanAllMarkets() {
    if(!IsTimeToScan()) {
        return false;
    }
    
    if(m_isScanning) {
        return false; // Already scanning
    }
    
    m_isScanning = true;
    
    // Scan each symbol on each timeframe
    for(int s = 0; s < m_symbolCount; s++) {
        if(ValidateSymbol(m_symbols[s])) {
            for(int tf = 0; tf < m_timeframeCount; tf++) {
                ScanSymbol(m_symbols[s], m_timeframes[tf]);
            }
        }
    }
    
    m_lastScanTime = TimeCurrent();
    m_isScanning = false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Scan individual symbol on specific timeframe                     |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::ScanSymbol(string symbol, ENUM_TIMEFRAMES timeframe) {
    if(!ValidateSymbol(symbol)) {
        return false;
    }
    
    SymbolScanResult result;
    result.symbol = symbol;
    result.timeframe = timeframe;
    result.scanTime = TimeCurrent();
    result.hasSignal = false;
    result.signalDirection = SIGNAL_NONE;
    result.signalStrength = 0.0;
    result.description = "No signal";
    
    // Basic market data validation
    double high[], low[], close[], open[];
    
    if(CopyHigh(symbol, timeframe, 0, 10, high) <= 0 ||
       CopyLow(symbol, timeframe, 0, 10, low) <= 0 ||
       CopyClose(symbol, timeframe, 0, 10, close) <= 0 ||
       CopyOpen(symbol, timeframe, 0, 10, open) <= 0) {
        result.description = "Failed to get market data";
        AddScanResult(result);
        return false;
    }
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    
    // Simple signal detection (can be enhanced with pattern detection)
    // This is a placeholder for actual signal logic
    bool bullish = close[0] > close[1] && close[1] > close[2];
    bool bearish = close[0] < close[1] && close[1] < close[2];
    
    if(bullish) {
        result.hasSignal = true;
        result.signalDirection = SIGNAL_BUY;
        result.signalStrength = 0.7;
        result.description = "Bullish momentum detected";
    } else if(bearish) {
        result.hasSignal = true;
        result.signalDirection = SIGNAL_SELL;
        result.signalStrength = 0.7;
        result.description = "Bearish momentum detected";
    }
    
    return AddScanResult(result);
}

//+------------------------------------------------------------------+
//| Validate symbol                                                  |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::ValidateSymbol(string symbol) {
    // Check if symbol exists and is available
    if(!SymbolSelect(symbol, true)) {
        return false;
    }
    
    // Check if symbol has valid quotes
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    if(bid <= 0 || ask <= 0) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Add scan result                                                  |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::AddScanResult(const SymbolScanResult &result) {
    int size = ArraySize(m_scanResults);
    
    if(ArrayResize(m_scanResults, size + 1) > 0) {
        m_scanResults[size] = result;
        LimitResultsSize();
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Limit results size to prevent memory issues                      |
//+------------------------------------------------------------------+
void CMultiSymbolScanner::LimitResultsSize() {
    int size = ArraySize(m_scanResults);
    
    if(size > m_maxResults) {
        // Remove oldest results
        int toRemove = size - m_maxResults;
        for(int i = 0; i < m_maxResults; i++) {
            m_scanResults[i] = m_scanResults[i + toRemove];
        }
        ArrayResize(m_scanResults, m_maxResults);
    }
}

//+------------------------------------------------------------------+
//| Get scan result by index                                         |
//+------------------------------------------------------------------+
SymbolScanResult CMultiSymbolScanner::GetResult(int index) {
    if(index >= 0 && index < ArraySize(m_scanResults)) {
        return m_scanResults[index];
    }
    SymbolScanResult empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get all scan results                                             |
//+------------------------------------------------------------------+
SymbolScanResult[] CMultiSymbolScanner::GetAllResults() {
    return m_scanResults;
}

//+------------------------------------------------------------------+
//| Get count of signals detected                                    |
//+------------------------------------------------------------------+
int CMultiSymbolScanner::GetSignalCount() {
    int count = 0;
    for(int i = 0; i < ArraySize(m_scanResults); i++) {
        if(m_scanResults[i].hasSignal) {
            count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Clear all scan results                                           |
//+------------------------------------------------------------------+
void CMultiSymbolScanner::ClearResults() {
    ArrayResize(m_scanResults, 0);
}

//+------------------------------------------------------------------+
//| Get symbol by index                                              |
//+------------------------------------------------------------------+
string CMultiSymbolScanner::GetSymbol(int index) {
    if(index >= 0 && index < m_symbolCount) {
        return m_symbols[index];
    }
    return "";
}

//+------------------------------------------------------------------+
//| Check if symbol is valid                                         |
//+------------------------------------------------------------------+
bool CMultiSymbolScanner::IsSymbolValid(string symbol) {
    return ValidateSymbol(symbol);
}

//+------------------------------------------------------------------+
//| Get timeframe by index                                           |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CMultiSymbolScanner::GetTimeframe(int index) {
    if(index >= 0 && index < m_timeframeCount) {
        return m_timeframes[index];
    }
    return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Set scan interval in minutes                                     |
//+------------------------------------------------------------------+
void CMultiSymbolScanner::SetScanInterval(int minutes) {
    if(minutes > 0) {
        m_scanIntervalSeconds = minutes * 60;
    }
}

//+------------------------------------------------------------------+
//| Print scan results                                               |
//+------------------------------------------------------------------+
void CMultiSymbolScanner::PrintScanResults() {
    Print("=== Multi-Symbol Scanner Results ===");
    Print("Total Results: ", ArraySize(m_scanResults));
    Print("Signals Detected: ", GetSignalCount());
    
    for(int i = 0; i < ArraySize(m_scanResults); i++) {
        if(m_scanResults[i].hasSignal) {
            Print("Signal: ", m_scanResults[i].symbol, 
                  " [", EnumToString(m_scanResults[i].timeframe), "] ",
                  EnumToString(m_scanResults[i].signalDirection),
                  " Strength: ", m_scanResults[i].signalStrength,
                  " - ", m_scanResults[i].description);
        }
    }
    Print("===================================");
}
