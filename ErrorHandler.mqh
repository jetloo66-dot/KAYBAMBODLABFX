//+------------------------------------------------------------------+
//|                                               ErrorHandler.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Error Handler Class                                              |
//+------------------------------------------------------------------+
class CErrorHandler {
private:
    string m_logFile;
    bool m_enableLogging;
    bool m_enablePrintLog;
    int m_maxLogSize;
    
    string GetErrorDescription(int errorCode);
    string GetTimestamp();
    void WriteToFile(string message);
    
public:
    CErrorHandler(string logFile = "SwingEA_Log.txt", bool enableLogging = true);
    ~CErrorHandler();
    
    void SetEnableLogging(bool enable) { m_enableLogging = enable; }
    void SetEnablePrint(bool enable) { m_enablePrintLog = enable; }
    
    void LogError(string source, string message, int errorCode = 0);
    void LogWarning(string source, string message);
    void LogInfo(string source, string message);
    void LogTrade(string action, string symbol, double price, double sl, double tp);
    
    bool CheckDataGap(string symbol, ENUM_TIMEFRAMES timeframe, int minBars);
    bool CheckIndicatorHandle(int handle, string indicatorName);
    bool CheckAccountTradeAllowed();
    bool CheckSymbolTradeAllowed(string symbol);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CErrorHandler::CErrorHandler(string logFile, bool enableLogging) {
    m_logFile = logFile;
    m_enableLogging = enableLogging;
    m_enablePrintLog = true;
    m_maxLogSize = 10000; // Max lines in log
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CErrorHandler::~CErrorHandler(void) {
}

//+------------------------------------------------------------------+
//| Log error message                                                |
//+------------------------------------------------------------------+
void CErrorHandler::LogError(string source, string message, int errorCode = 0) {
    string logMessage = "[ERROR] [" + source + "] " + message;
    
    if(errorCode != 0) {
        logMessage += " | Error Code: " + IntegerToString(errorCode) + 
                     " (" + GetErrorDescription(errorCode) + ")";
    }
    
    if(m_enablePrintLog) {
        Print(logMessage);
    }
    
    if(m_enableLogging) {
        WriteToFile(logMessage);
    }
}

//+------------------------------------------------------------------+
//| Log warning message                                              |
//+------------------------------------------------------------------+
void CErrorHandler::LogWarning(string source, string message) {
    string logMessage = "[WARNING] [" + source + "] " + message;
    
    if(m_enablePrintLog) {
        Print(logMessage);
    }
    
    if(m_enableLogging) {
        WriteToFile(logMessage);
    }
}

//+------------------------------------------------------------------+
//| Log info message                                                 |
//+------------------------------------------------------------------+
void CErrorHandler::LogInfo(string source, string message) {
    string logMessage = "[INFO] [" + source + "] " + message;
    
    if(m_enablePrintLog) {
        Print(logMessage);
    }
    
    if(m_enableLogging) {
        WriteToFile(logMessage);
    }
}

//+------------------------------------------------------------------+
//| Log trade action                                                 |
//+------------------------------------------------------------------+
void CErrorHandler::LogTrade(string action, string symbol, double price, double sl, double tp) {
    string logMessage = "[TRADE] [" + action + "] Symbol: " + symbol + 
                       " | Price: " + DoubleToString(price, 5) +
                       " | SL: " + DoubleToString(sl, 5) +
                       " | TP: " + DoubleToString(tp, 5);
    
    if(m_enablePrintLog) {
        Print(logMessage);
    }
    
    if(m_enableLogging) {
        WriteToFile(logMessage);
    }
}

//+------------------------------------------------------------------+
//| Check for data gaps                                              |
//+------------------------------------------------------------------+
bool CErrorHandler::CheckDataGap(string symbol, ENUM_TIMEFRAMES timeframe, int minBars) {
    int bars = iBars(symbol, timeframe);
    
    if(bars < minBars) {
        LogWarning("DataCheck", "Insufficient bars for " + symbol + " " + 
                  EnumToString(timeframe) + ". Required: " + IntegerToString(minBars) +
                  ", Available: " + IntegerToString(bars));
        return false;
    }
    
    // Check for gaps in recent data
    datetime times[];
    if(CopyTime(symbol, timeframe, 0, 100, times) < 100) {
        LogWarning("DataCheck", "Unable to copy time data for " + symbol);
        return false;
    }
    
    ArraySetAsSeries(times, true);
    int periodSeconds = PeriodSeconds(timeframe);
    
    for(int i = 0; i < 10; i++) {
        int gap = (int)(times[i] - times[i+1]);
        if(gap > periodSeconds * 2) {
            LogWarning("DataCheck", "Data gap detected in " + symbol + " at " + 
                      TimeToString(times[i]));
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check indicator handle validity                                  |
//+------------------------------------------------------------------+
bool CErrorHandler::CheckIndicatorHandle(int handle, string indicatorName) {
    if(handle == INVALID_HANDLE) {
        LogError("IndicatorCheck", "Invalid handle for " + indicatorName, GetLastError());
        return false;
    }
    
    // Check if indicator is calculated
    if(BarsCalculated(handle) <= 0) {
        LogWarning("IndicatorCheck", indicatorName + " not yet calculated");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if account trading is allowed                              |
//+------------------------------------------------------------------+
bool CErrorHandler::CheckAccountTradeAllowed(void) {
    if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
        LogError("AccountCheck", "Trading is not allowed for this account");
        return false;
    }
    
    if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) {
        LogError("AccountCheck", "Expert trading is not allowed for this account");
        return false;
    }
    
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
        LogError("AccountCheck", "Automated trading is disabled in MT5");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if symbol trading is allowed                               |
//+------------------------------------------------------------------+
bool CErrorHandler::CheckSymbolTradeAllowed(string symbol) {
    if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE)) {
        LogError("SymbolCheck", "Trading disabled for " + symbol);
        return false;
    }
    
    datetime time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    // Check if market is open
    if(dt.day_of_week == 0 || dt.day_of_week == 6) {
        LogWarning("SymbolCheck", "Market closed (Weekend) for " + symbol);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get error description                                            |
//+------------------------------------------------------------------+
string CErrorHandler::GetErrorDescription(int errorCode) {
    switch(errorCode) {
        case 0: return "Success";
        case 4051: return "Invalid function parameter value";
        case 4054: return "No connection";
        case 4055: return "Old version";
        case 4060: return "Function not allowed";
        case 4067: return "Wrong server answer";
        case 4073: return "Too many requests";
        case 4106: return "Unknown symbol";
        case 4107: return "Invalid price";
        case 4108: return "Invalid ticket";
        case 4109: return "Trade not allowed";
        case 4110: return "Longs not allowed";
        case 4111: return "Shorts not allowed";
        case 4756: return "Trade context busy";
        case 4800: return "Trade timeout";
        case 10004: return "Requote";
        case 10006: return "Request rejected";
        case 10007: return "Request canceled";
        case 10008: return "Order placed";
        case 10009: return "Request completed";
        case 10010: return "Only part of request completed";
        case 10011: return "Request processing error";
        case 10012: return "Request timeout";
        case 10013: return "Invalid request";
        case 10014: return "Invalid volume";
        case 10015: return "Invalid price";
        case 10016: return "Invalid stops";
        case 10017: return "Trade disabled";
        case 10018: return "Market closed";
        case 10019: return "Not enough money";
        case 10020: return "Price changed";
        case 10021: return "No quotes";
        case 10022: return "Invalid order expiration";
        case 10023: return "Order changed";
        case 10024: return "Too many requests";
        case 10025: return "No changes";
        case 10026: return "AutoTrading disabled";
        case 10027: return "AutoTrading disabled by client";
        case 10028: return "Request locked";
        case 10029: return "Order/Position frozen";
        case 10030: return "Invalid order fill type";
        case 10031: return "No connection";
        case 10032: return "Allowed only for live accounts";
        case 10033: return "Number of orders limit reached";
        case 10034: return "Order/Position volume limit reached";
        case 10035: return "Invalid order/position type";
        case 10036: return "Position already closed";
        default: return "Unknown error";
    }
}

//+------------------------------------------------------------------+
//| Get timestamp string                                             |
//+------------------------------------------------------------------+
string CErrorHandler::GetTimestamp(void) {
    MqlDateTime dt;
    TimeCurrent(dt);
    
    return StringFormat("%04d.%02d.%02d %02d:%02d:%02d",
                       dt.year, dt.mon, dt.day,
                       dt.hour, dt.min, dt.sec);
}

//+------------------------------------------------------------------+
//| Write to log file                                                |
//+------------------------------------------------------------------+
void CErrorHandler::WriteToFile(string message) {
    int handle = FileOpen(m_logFile, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
    
    if(handle == INVALID_HANDLE) {
        // Try to create new file
        handle = FileOpen(m_logFile, FILE_WRITE | FILE_TXT | FILE_ANSI);
        if(handle == INVALID_HANDLE) {
            Print("Failed to open log file: ", GetLastError());
            return;
        }
    }
    
    // Go to end of file
    FileSeek(handle, 0, SEEK_END);
    
    // Write log entry
    string logEntry = GetTimestamp() + " | " + message + "\n";
    FileWriteString(handle, logEntry);
    
    FileClose(handle);
}
//+------------------------------------------------------------------+
