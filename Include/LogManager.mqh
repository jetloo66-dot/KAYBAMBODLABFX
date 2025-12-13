//+------------------------------------------------------------------+
//|                                                   LogManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs.mqh"
#include "GlobalVariables.mqh"

//+------------------------------------------------------------------+
//| Log Level Enumeration                                            |
//+------------------------------------------------------------------+
enum ENUM_LOG_LEVEL {
    LOG_LEVEL_DEBUG = 0,
    LOG_LEVEL_INFO,
    LOG_LEVEL_WARNING,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_CRITICAL
};

//+------------------------------------------------------------------+
//| Log Entry Structure                                              |
//+------------------------------------------------------------------+
struct LogEntry {
    datetime timestamp;
    ENUM_LOG_LEVEL level;
    string module;
    string message;
    int errorCode;
};

//+------------------------------------------------------------------+
//| Advanced Log Manager Class                                       |
//+------------------------------------------------------------------+
class CLogManager {
private:
    // Settings
    ENUM_LOG_LEVEL m_minLogLevel;
    bool m_enableFileLogging;
    bool m_enableConsoleLogging;
    bool m_enableTelegramLogging;
    string m_logFilePath;
    int m_maxLogEntries;
    
    // Log storage
    LogEntry m_logEntries[];
    int m_currentLogIndex;
    int m_totalLogs;
    
    // File handling
    int m_fileHandle;
    datetime m_lastFileWrite;
    
    // Performance
    datetime m_lastCleanup;
    bool m_isInitialized;
    
    // Private methods
    void WriteToFile(const LogEntry &entry);
    void WriteToConsole(const LogEntry &entry);
    string FormatLogEntry(const LogEntry &entry);
    string GetLevelString(ENUM_LOG_LEVEL level);
    void CleanupOldEntries();
    bool ShouldLog(ENUM_LOG_LEVEL level);
    
public:
    // Constructor/Destructor
    CLogManager();
    ~CLogManager();
    
    // Initialization
    bool Initialize(ENUM_LOG_LEVEL minLevel = LOG_LEVEL_INFO, 
                   bool enableFile = true, 
                   bool enableConsole = true);
    void SetLogLevel(ENUM_LOG_LEVEL level) { m_minLogLevel = level; }
    void SetFileLogging(bool enable) { m_enableFileLogging = enable; }
    void SetConsoleLogging(bool enable) { m_enableConsoleLogging = enable; }
    void SetTelegramLogging(bool enable) { m_enableTelegramLogging = enable; }
    
    // Core logging methods
    void LogDebug(string message, string module = "MAIN");
    void LogInfo(string message, string module = "MAIN");
    void LogWarning(string message, string module = "MAIN");
    void LogError(string message, string module = "MAIN", int errorCode = 0);
    void LogCritical(string message, string module = "MAIN", int errorCode = 0);
    
    // Specialized logging methods
    void LogTrade(string action, string symbol, double price, double volume, string reason = "");
    void LogSignal(const SignalInfo &signal);
    void LogPattern(ENUM_CANDLE_PATTERN pattern, double strength, string timeframe);
    void LogCorrelation(string indicator1, string indicator2, double correlation);
    void LogPerformance(string operation, int executionTime);
    void LogRisk(const RiskData &riskData);
    
    // Utility methods
    void ClearLogs();
    int GetLogCount() { return m_totalLogs; }
    LogEntry GetLastLog();
    LogEntry[] GetLogs(ENUM_LOG_LEVEL minLevel = LOG_LEVEL_DEBUG);
    void FlushLogs();
    
    // File operations
    bool OpenLogFile();
    void CloseLogFile();
    bool RotateLogFile();
    
    // Statistics
    void PrintLogStatistics();
    int GetLogCountByLevel(ENUM_LOG_LEVEL level);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogManager::CLogManager() {
    m_minLogLevel = LOG_LEVEL_INFO;
    m_enableFileLogging = true;
    m_enableConsoleLogging = true;
    m_enableTelegramLogging = false;
    m_maxLogEntries = 10000;
    m_currentLogIndex = 0;
    m_totalLogs = 0;
    m_fileHandle = INVALID_HANDLE;
    m_lastFileWrite = 0;
    m_lastCleanup = 0;
    m_isInitialized = false;
    
    // Initialize log file path
    m_logFilePath = "KAYBAMBODLABFX_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogManager::~CLogManager() {
    if(m_fileHandle != INVALID_HANDLE) {
        FileClose(m_fileHandle);
    }
    ArrayFree(m_logEntries);
}

//+------------------------------------------------------------------+
//| Initialize log manager                                           |
//+------------------------------------------------------------------+
bool CLogManager::Initialize(ENUM_LOG_LEVEL minLevel = LOG_LEVEL_INFO, 
                            bool enableFile = true, 
                            bool enableConsole = true) {
    m_minLogLevel = minLevel;
    m_enableFileLogging = enableFile;
    m_enableConsoleLogging = enableConsole;
    
    // Initialize log entries array
    ArrayResize(m_logEntries, m_maxLogEntries);
    ArrayInitialize(m_logEntries, {0});
    
    // Open log file if enabled
    if(m_enableFileLogging) {
        if(!OpenLogFile()) {
            Print("Warning: Could not open log file, file logging disabled");
            m_enableFileLogging = false;
        }
    }
    
    m_isInitialized = true;
    LogInfo("LogManager initialized successfully", "LOGMANAGER");
    
    return true;
}

//+------------------------------------------------------------------+
//| Debug logging                                                    |
//+------------------------------------------------------------------+
void CLogManager::LogDebug(string message, string module = "MAIN") {
    if(!ShouldLog(LOG_LEVEL_DEBUG)) return;
    
    LogEntry entry;
    entry.timestamp = TimeCurrent();
    entry.level = LOG_LEVEL_DEBUG;
    entry.module = module;
    entry.message = message;
    entry.errorCode = 0;
    
    // Store in array
    m_logEntries[m_currentLogIndex] = entry;
    m_currentLogIndex = (m_currentLogIndex + 1) % m_maxLogEntries;
    m_totalLogs++;
    
    // Output to console
    if(m_enableConsoleLogging) {
        WriteToConsole(entry);
    }
    
    // Output to file
    if(m_enableFileLogging) {
        WriteToFile(entry);
    }
}

//+------------------------------------------------------------------+
//| Info logging                                                     |
//+------------------------------------------------------------------+
void CLogManager::LogInfo(string message, string module = "MAIN") {
    if(!ShouldLog(LOG_LEVEL_INFO)) return;
    
    LogEntry entry;
    entry.timestamp = TimeCurrent();
    entry.level = LOG_LEVEL_INFO;
    entry.module = module;
    entry.message = message;
    entry.errorCode = 0;
    
    // Store in array
    m_logEntries[m_currentLogIndex] = entry;
    m_currentLogIndex = (m_currentLogIndex + 1) % m_maxLogEntries;
    m_totalLogs++;
    
    // Output to console
    if(m_enableConsoleLogging) {
        WriteToConsole(entry);
    }
    
    // Output to file
    if(m_enableFileLogging) {
        WriteToFile(entry);
    }
}

//+------------------------------------------------------------------+
//| Warning logging                                                  |
//+------------------------------------------------------------------+
void CLogManager::LogWarning(string message, string module = "MAIN") {
    if(!ShouldLog(LOG_LEVEL_WARNING)) return;
    
    LogEntry entry;
    entry.timestamp = TimeCurrent();
    entry.level = LOG_LEVEL_WARNING;
    entry.module = module;
    entry.message = message;
    entry.errorCode = 0;
    
    // Store in array
    m_logEntries[m_currentLogIndex] = entry;
    m_currentLogIndex = (m_currentLogIndex + 1) % m_maxLogEntries;
    m_totalLogs++;
    
    // Output to console
    if(m_enableConsoleLogging) {
        WriteToConsole(entry);
    }
    
    // Output to file
    if(m_enableFileLogging) {
        WriteToFile(entry);
    }
}

//+------------------------------------------------------------------+
//| Error logging                                                    |
//+------------------------------------------------------------------+
void CLogManager::LogError(string message, string module = "MAIN", int errorCode = 0) {
    if(!ShouldLog(LOG_LEVEL_ERROR)) return;
    
    LogEntry entry;
    entry.timestamp = TimeCurrent();
    entry.level = LOG_LEVEL_ERROR;
    entry.module = module;
    entry.message = message;
    entry.errorCode = errorCode;
    
    // Store in array
    m_logEntries[m_currentLogIndex] = entry;
    m_currentLogIndex = (m_currentLogIndex + 1) % m_maxLogEntries;
    m_totalLogs++;
    
    // Output to console
    if(m_enableConsoleLogging) {
        WriteToConsole(entry);
    }
    
    // Output to file
    if(m_enableFileLogging) {
        WriteToFile(entry);
    }
}

//+------------------------------------------------------------------+
//| Critical logging                                                 |
//+------------------------------------------------------------------+
void CLogManager::LogCritical(string message, string module = "MAIN", int errorCode = 0) {
    LogEntry entry;
    entry.timestamp = TimeCurrent();
    entry.level = LOG_LEVEL_CRITICAL;
    entry.module = module;
    entry.message = message;
    entry.errorCode = errorCode;
    
    // Store in array
    m_logEntries[m_currentLogIndex] = entry;
    m_currentLogIndex = (m_currentLogIndex + 1) % m_maxLogEntries;
    m_totalLogs++;
    
    // Always output critical messages
    WriteToConsole(entry);
    
    if(m_enableFileLogging) {
        WriteToFile(entry);
        FlushLogs(); // Ensure critical messages are written immediately
    }
}

//+------------------------------------------------------------------+
//| Log trade information                                            |
//+------------------------------------------------------------------+
void CLogManager::LogTrade(string action, string symbol, double price, double volume, string reason = "") {
    string message = StringFormat("TRADE %s: %s %.5f lots at %.5f", 
                                 action, symbol, volume, price);
    if(reason != "") {
        message += " - " + reason;
    }
    LogInfo(message, "TRADE");
}

//+------------------------------------------------------------------+
//| Log signal information                                           |
//+------------------------------------------------------------------+
void CLogManager::LogSignal(const SignalInfo &signal) {
    string message = StringFormat("SIGNAL %s: %s Pattern=%s Strength=%.2f Entry=%.5f SL=%.5f TP=%.5f",
                                 EnumToString(signal.direction),
                                 signal.symbol,
                                 GetPatternString(signal.pattern),
                                 signal.patternStrength,
                                 signal.entryPrice,
                                 signal.stopLoss,
                                 signal.takeProfit);
    LogInfo(message, "SIGNAL");
}

//+------------------------------------------------------------------+
//| Log pattern detection                                            |
//+------------------------------------------------------------------+
void CLogManager::LogPattern(ENUM_CANDLE_PATTERN pattern, double strength, string timeframe) {
    string message = StringFormat("PATTERN: %s detected on %s with strength %.2f",
                                 GetPatternString(pattern),
                                 timeframe,
                                 strength);
    LogDebug(message, "PATTERN");
}

//+------------------------------------------------------------------+
//| Log correlation data                                             |
//+------------------------------------------------------------------+
void CLogManager::LogCorrelation(string indicator1, string indicator2, double correlation) {
    string message = StringFormat("CORRELATION: %s vs %s = %.3f",
                                 indicator1, indicator2, correlation);
    LogDebug(message, "CORRELATION");
}

//+------------------------------------------------------------------+
//| Log performance data                                             |
//+------------------------------------------------------------------+
void CLogManager::LogPerformance(string operation, int executionTime) {
    string message = StringFormat("PERFORMANCE: %s completed in %d ms",
                                 operation, executionTime);
    LogDebug(message, "PERFORMANCE");
}

//+------------------------------------------------------------------+
//| Log risk data                                                    |
//+------------------------------------------------------------------+
void CLogManager::LogRisk(const RiskData &riskData) {
    string message = StringFormat("RISK: Balance=%.2f Equity=%.2f Drawdown=%.2f%% Risk=%.2f%%",
                                 riskData.accountBalance,
                                 riskData.accountEquity,
                                 riskData.currentDrawdown,
                                 riskData.riskPercent);
    LogInfo(message, "RISK");
}

//+------------------------------------------------------------------+
//| Write to console                                                 |
//+------------------------------------------------------------------+
void CLogManager::WriteToConsole(const LogEntry &entry) {
    string formattedEntry = FormatLogEntry(entry);
    Print(formattedEntry);
}

//+------------------------------------------------------------------+
//| Write to file                                                    |
//+------------------------------------------------------------------+
void CLogManager::WriteToFile(const LogEntry &entry) {
    if(m_fileHandle == INVALID_HANDLE) return;
    
    string formattedEntry = FormatLogEntry(entry) + "\n";
    FileWriteString(m_fileHandle, formattedEntry);
    m_lastFileWrite = TimeCurrent();
    
    // Periodically flush to ensure data is written
    if(TimeCurrent() - m_lastFileWrite > 60) { // Every minute
        FileFlush(m_fileHandle);
    }
}

//+------------------------------------------------------------------+
//| Format log entry                                                 |
//+------------------------------------------------------------------+
string CLogManager::FormatLogEntry(const LogEntry &entry) {
    string timeStr = TimeToString(entry.timestamp, TIME_DATE | TIME_SECONDS);
    string levelStr = GetLevelString(entry.level);
    
    string formatted = StringFormat("[%s] [%s] [%s] %s",
                                   timeStr,
                                   levelStr,
                                   entry.module,
                                   entry.message);
    
    if(entry.errorCode != 0) {
        formatted += StringFormat(" (Error: %d)", entry.errorCode);
    }
    
    return formatted;
}

//+------------------------------------------------------------------+
//| Get level string                                                 |
//+------------------------------------------------------------------+
string CLogManager::GetLevelString(ENUM_LOG_LEVEL level) {
    switch(level) {
        case LOG_LEVEL_DEBUG: return "DEBUG";
        case LOG_LEVEL_INFO: return "INFO";
        case LOG_LEVEL_WARNING: return "WARN";
        case LOG_LEVEL_ERROR: return "ERROR";
        case LOG_LEVEL_CRITICAL: return "CRITICAL";
        default: return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Check if should log                                              |
//+------------------------------------------------------------------+
bool CLogManager::ShouldLog(ENUM_LOG_LEVEL level) {
    return (m_isInitialized && level >= m_minLogLevel);
}

//+------------------------------------------------------------------+
//| Open log file                                                    |
//+------------------------------------------------------------------+
bool CLogManager::OpenLogFile() {
    if(m_fileHandle != INVALID_HANDLE) {
        FileClose(m_fileHandle);
    }
    
    m_fileHandle = FileOpen(m_logFilePath, FILE_WRITE | FILE_TXT | FILE_ANSI);
    
    if(m_fileHandle == INVALID_HANDLE) {
        Print("Failed to open log file: ", m_logFilePath, " Error: ", GetLastError());
        return false;
    }
    
    // Write header
    string header = StringFormat("KAYBAMBODLABFX EA Log File - Started: %s\n", 
                                TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    FileWriteString(m_fileHandle, header);
    FileFlush(m_fileHandle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Close log file                                                   |
//+------------------------------------------------------------------+
void CLogManager::CloseLogFile() {
    if(m_fileHandle != INVALID_HANDLE) {
        FileClose(m_fileHandle);
        m_fileHandle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Flush logs to file                                               |
//+------------------------------------------------------------------+
void CLogManager::FlushLogs() {
    if(m_fileHandle != INVALID_HANDLE) {
        FileFlush(m_fileHandle);
    }
}

//+------------------------------------------------------------------+
//| Clear all logs                                                   |
//+------------------------------------------------------------------+
void CLogManager::ClearLogs() {
    ArrayInitialize(m_logEntries, {0});
    m_currentLogIndex = 0;
    m_totalLogs = 0;
    LogInfo("Log entries cleared", "LOGMANAGER");
}

//+------------------------------------------------------------------+
//| Get last log entry                                               |
//+------------------------------------------------------------------+
LogEntry CLogManager::GetLastLog() {
    if(m_totalLogs == 0) {
        LogEntry emptyEntry = {0};
        return emptyEntry;
    }
    
    int lastIndex = (m_currentLogIndex - 1 + m_maxLogEntries) % m_maxLogEntries;
    return m_logEntries[lastIndex];
}

//+------------------------------------------------------------------+
//| Print log statistics                                             |
//+------------------------------------------------------------------+
void CLogManager::PrintLogStatistics() {
    LogInfo(StringFormat("Log Statistics - Total: %d, Debug: %d, Info: %d, Warning: %d, Error: %d, Critical: %d",
                        m_totalLogs,
                        GetLogCountByLevel(LOG_LEVEL_DEBUG),
                        GetLogCountByLevel(LOG_LEVEL_INFO),
                        GetLogCountByLevel(LOG_LEVEL_WARNING),
                        GetLogCountByLevel(LOG_LEVEL_ERROR),
                        GetLogCountByLevel(LOG_LEVEL_CRITICAL)),
           "LOGMANAGER");
}

//+------------------------------------------------------------------+
//| Get log count by level                                           |
//+------------------------------------------------------------------+
int CLogManager::GetLogCountByLevel(ENUM_LOG_LEVEL level) {
    int count = 0;
    int maxEntries = MathMin(m_totalLogs, m_maxLogEntries);
    
    for(int i = 0; i < maxEntries; i++) {
        if(m_logEntries[i].level == level) {
            count++;
        }
    }
    
    return count;
}