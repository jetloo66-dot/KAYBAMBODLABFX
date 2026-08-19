//+------------------------------------------------------------------+
//|                                          ConfigurationManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs_Version1.mqh"

//+------------------------------------------------------------------+
//| Configuration Manager Class                                       |
//| Handles all input parameters, presets, and runtime configuration |
//+------------------------------------------------------------------+
class CConfigurationManager {
private:
    StrategySettings m_settings;
    bool m_initialized;
    string m_configFileName;
    
public:
    // Constructor/Destructor
    CConfigurationManager();
    ~CConfigurationManager();
    
    // Initialization
    bool Initialize();
    bool LoadDefaultSettings();
    bool LoadFromInputs(
        // Timeframe settings
        ENUM_TIMEFRAMES analysisTimeframe1,
        ENUM_TIMEFRAMES analysisTimeframe2,
        ENUM_TIMEFRAMES analysisTimeframe3,
        ENUM_TIMEFRAMES executionTimeframe,
        
        // Scanning parameters
        int candlesToScan,
        int patternScanCandles,
        int scanIntervalMinutes,
        
        // Level detection
        int maxLevelsToStore,
        double levelProximityPips,
        int swingStrength,
        
        // Trading parameters
        double lotSize,
        double stopLossPips,
        double takeProfitPips,
        bool useTrailingStop,
        double trailingStopPips,
        double trailingStepPips,
        
        // Pattern settings
        double pinBarRatio,
        double dojiBodyRatio,
        double engulfingRatio,
        
        // Risk management
        double maxRiskPercent,
        int maxPositions,
        double maxDailyLoss,
        
        // News filter
        bool useNewsFilter,
        int newsFilterMinutes,
        
        // Telegram settings
        string telegramBotToken,
        string telegramChatID,
        bool sendTelegramNotifications,
        
        // Visualization
        bool showLevels,
        bool showFibonacci,
        bool showZones,
        color supportColor,
        color resistanceColor,
        color buyZoneColor,
        color sellZoneColor,
        
        // Magic number
        int magicNumber
    );
    
    // Getters - Strategy Settings
    StrategySettings GetSettings() const { return m_settings; }
    
    // Timeframe getters
    ENUM_TIMEFRAMES GetAnalysisTimeframe(int index) const;
    ENUM_TIMEFRAMES GetExecutionTimeframe() const { return m_settings.executionTimeframe; }
    
    // Scanning parameters getters
    int GetCandlesToScan() const { return m_settings.candlesToScan; }
    int GetPatternScanCandles() const { return m_settings.patternScanCandles; }
    int GetScanIntervalMinutes() const { return m_settings.scanIntervalMinutes; }
    
    // Level detection getters
    int GetMaxLevelsToStore() const { return m_settings.maxLevelsToStore; }
    double GetLevelProximityPips() const { return m_settings.levelProximityPips; }
    int GetSwingStrength() const { return m_settings.swingStrength; }
    
    // Trading parameters getters
    double GetLotSize() const { return m_settings.lotSize; }
    double GetStopLossPips() const { return m_settings.stopLossPips; }
    double GetTakeProfitPips() const { return m_settings.takeProfitPips; }
    bool GetUseTrailingStop() const { return m_settings.useTrailingStop; }
    double GetTrailingStopPips() const { return m_settings.trailingStopPips; }
    double GetTrailingStepPips() const { return m_settings.trailingStepPips; }
    
    // Pattern settings getters
    double GetPinBarRatio() const { return m_settings.pinBarRatio; }
    double GetDojiBodyRatio() const { return m_settings.dojiBodyRatio; }
    double GetEngulfingRatio() const { return m_settings.engulfingRatio; }
    
    // Risk management getters
    double GetMaxRiskPercent() const { return m_settings.maxRiskPercent; }
    int GetMaxPositions() const { return m_settings.maxPositions; }
    double GetMaxDailyLoss() const { return m_settings.maxDailyLoss; }
    
    // News filter getters
    bool GetUseNewsFilter() const { return m_settings.useNewsFilter; }
    int GetNewsFilterMinutes() const { return m_settings.newsFilterMinutes; }
    
    // Telegram settings getters
    string GetTelegramBotToken() const { return m_settings.telegramBotToken; }
    string GetTelegramChatID() const { return m_settings.telegramChatID; }
    bool GetSendTelegramNotifications() const { return m_settings.sendTelegramNotifications; }
    
    // Visualization getters
    bool GetShowLevels() const { return m_settings.showLevels; }
    bool GetShowFibonacci() const { return m_settings.showFibonacci; }
    bool GetShowZones() const { return m_settings.showZones; }
    color GetSupportColor() const { return m_settings.supportColor; }
    color GetResistanceColor() const { return m_settings.resistanceColor; }
    color GetBuyZoneColor() const { return m_settings.buyZoneColor; }
    color GetSellZoneColor() const { return m_settings.sellZoneColor; }
    
    // Magic number getter
    int GetMagicNumber() const { return m_settings.magicNumber; }
    
    // Setters - Runtime configuration updates
    void SetLotSize(double lotSize);
    void SetStopLossPips(double stopLoss);
    void SetTakeProfitPips(double takeProfit);
    void SetMaxRiskPercent(double maxRisk);
    void SetUseNewsFilter(bool useFilter);
    void SetSendTelegramNotifications(bool sendNotifications);
    
    // Validation
    bool ValidateSettings();
    string GetValidationErrors();
    
    // File operations
    bool SaveToFile(string filename);
    bool LoadFromFile(string filename);
    
    // Utility
    bool IsInitialized() const { return m_initialized; }
    void PrintSettings();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CConfigurationManager::CConfigurationManager() {
    m_initialized = false;
    m_configFileName = "KAYBAMBODLABFX_Config.txt";
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CConfigurationManager::~CConfigurationManager() {
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Initialize with default settings                                 |
//+------------------------------------------------------------------+
bool CConfigurationManager::Initialize() {
    return LoadDefaultSettings();
}

//+------------------------------------------------------------------+
//| Load default settings                                            |
//+------------------------------------------------------------------+
bool CConfigurationManager::LoadDefaultSettings() {
    // Timeframe settings
    m_settings.analysisTimeframes[0] = PERIOD_H1;
    m_settings.analysisTimeframes[1] = PERIOD_H4;
    m_settings.analysisTimeframes[2] = PERIOD_D1;
    m_settings.executionTimeframe = PERIOD_M5;
    
    // Scanning parameters
    m_settings.candlesToScan = 100;
    m_settings.patternScanCandles = 20;
    m_settings.scanIntervalMinutes = 5;
    
    // Level detection
    m_settings.maxLevelsToStore = 10;
    m_settings.levelProximityPips = 5.0;
    m_settings.swingStrength = 5;
    
    // Trading parameters
    m_settings.lotSize = 0.01;
    m_settings.stopLossPips = 15.0;
    m_settings.takeProfitPips = 50.0;
    m_settings.useTrailingStop = true;
    m_settings.trailingStopPips = 10.0;
    m_settings.trailingStepPips = 5.0;
    
    // Pattern settings
    m_settings.pinBarRatio = 0.6;
    m_settings.dojiBodyRatio = 0.1;
    m_settings.engulfingRatio = 1.0;
    
    // Risk management
    m_settings.maxRiskPercent = 2.0;
    m_settings.maxPositions = 1;
    m_settings.maxDailyLoss = 10.0;
    
    // News filter
    m_settings.useNewsFilter = true;
    m_settings.newsFilterMinutes = 30;
    
    // Telegram settings
    m_settings.telegramBotToken = "";
    m_settings.telegramChatID = "";
    m_settings.sendTelegramNotifications = false;
    
    // Visualization
    m_settings.showLevels = true;
    m_settings.showFibonacci = true;
    m_settings.showZones = true;
    m_settings.supportColor = clrBlue;
    m_settings.resistanceColor = clrRed;
    m_settings.buyZoneColor = clrLime;
    m_settings.sellZoneColor = clrOrange;
    
    // Magic number
    m_settings.magicNumber = 123456;
    
    m_initialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Load settings from input parameters                              |
//+------------------------------------------------------------------+
bool CConfigurationManager::LoadFromInputs(
    ENUM_TIMEFRAMES analysisTimeframe1,
    ENUM_TIMEFRAMES analysisTimeframe2,
    ENUM_TIMEFRAMES analysisTimeframe3,
    ENUM_TIMEFRAMES executionTimeframe,
    int candlesToScan,
    int patternScanCandles,
    int scanIntervalMinutes,
    int maxLevelsToStore,
    double levelProximityPips,
    int swingStrength,
    double lotSize,
    double stopLossPips,
    double takeProfitPips,
    bool useTrailingStop,
    double trailingStopPips,
    double trailingStepPips,
    double pinBarRatio,
    double dojiBodyRatio,
    double engulfingRatio,
    double maxRiskPercent,
    int maxPositions,
    double maxDailyLoss,
    bool useNewsFilter,
    int newsFilterMinutes,
    string telegramBotToken,
    string telegramChatID,
    bool sendTelegramNotifications,
    bool showLevels,
    bool showFibonacci,
    bool showZones,
    color supportColor,
    color resistanceColor,
    color buyZoneColor,
    color sellZoneColor,
    int magicNumber
) {
    // Timeframe settings
    m_settings.analysisTimeframes[0] = analysisTimeframe1;
    m_settings.analysisTimeframes[1] = analysisTimeframe2;
    m_settings.analysisTimeframes[2] = analysisTimeframe3;
    m_settings.executionTimeframe = executionTimeframe;
    
    // Scanning parameters
    m_settings.candlesToScan = candlesToScan;
    m_settings.patternScanCandles = patternScanCandles;
    m_settings.scanIntervalMinutes = scanIntervalMinutes;
    
    // Level detection
    m_settings.maxLevelsToStore = maxLevelsToStore;
    m_settings.levelProximityPips = levelProximityPips;
    m_settings.swingStrength = swingStrength;
    
    // Trading parameters
    m_settings.lotSize = lotSize;
    m_settings.stopLossPips = stopLossPips;
    m_settings.takeProfitPips = takeProfitPips;
    m_settings.useTrailingStop = useTrailingStop;
    m_settings.trailingStopPips = trailingStopPips;
    m_settings.trailingStepPips = trailingStepPips;
    
    // Pattern settings
    m_settings.pinBarRatio = pinBarRatio;
    m_settings.dojiBodyRatio = dojiBodyRatio;
    m_settings.engulfingRatio = engulfingRatio;
    
    // Risk management
    m_settings.maxRiskPercent = maxRiskPercent;
    m_settings.maxPositions = maxPositions;
    m_settings.maxDailyLoss = maxDailyLoss;
    
    // News filter
    m_settings.useNewsFilter = useNewsFilter;
    m_settings.newsFilterMinutes = newsFilterMinutes;
    
    // Telegram settings
    m_settings.telegramBotToken = telegramBotToken;
    m_settings.telegramChatID = telegramChatID;
    m_settings.sendTelegramNotifications = sendTelegramNotifications;
    
    // Visualization
    m_settings.showLevels = showLevels;
    m_settings.showFibonacci = showFibonacci;
    m_settings.showZones = showZones;
    m_settings.supportColor = supportColor;
    m_settings.resistanceColor = resistanceColor;
    m_settings.buyZoneColor = buyZoneColor;
    m_settings.sellZoneColor = sellZoneColor;
    
    // Magic number
    m_settings.magicNumber = magicNumber;
    
    m_initialized = ValidateSettings();
    return m_initialized;
}

//+------------------------------------------------------------------+
//| Get analysis timeframe by index                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CConfigurationManager::GetAnalysisTimeframe(int index) const {
    if(index >= 0 && index < 3) {
        return m_settings.analysisTimeframes[index];
    }
    return PERIOD_CURRENT;
}

//+------------------------------------------------------------------+
//| Set lot size with validation                                     |
//+------------------------------------------------------------------+
void CConfigurationManager::SetLotSize(double lotSize) {
    if(lotSize >= 0.01 && lotSize <= 100.0) {
        m_settings.lotSize = lotSize;
    }
}

//+------------------------------------------------------------------+
//| Set stop loss with validation                                    |
//+------------------------------------------------------------------+
void CConfigurationManager::SetStopLossPips(double stopLoss) {
    if(stopLoss >= 5.0 && stopLoss <= 1000.0) {
        m_settings.stopLossPips = stopLoss;
    }
}

//+------------------------------------------------------------------+
//| Set take profit with validation                                  |
//+------------------------------------------------------------------+
void CConfigurationManager::SetTakeProfitPips(double takeProfit) {
    if(takeProfit >= 5.0 && takeProfit <= 2000.0) {
        m_settings.takeProfitPips = takeProfit;
    }
}

//+------------------------------------------------------------------+
//| Set max risk percent with validation                             |
//+------------------------------------------------------------------+
void CConfigurationManager::SetMaxRiskPercent(double maxRisk) {
    if(maxRisk >= 0.1 && maxRisk <= 10.0) {
        m_settings.maxRiskPercent = maxRisk;
    }
}

//+------------------------------------------------------------------+
//| Set news filter usage                                            |
//+------------------------------------------------------------------+
void CConfigurationManager::SetUseNewsFilter(bool useFilter) {
    m_settings.useNewsFilter = useFilter;
}

//+------------------------------------------------------------------+
//| Set telegram notifications                                       |
//+------------------------------------------------------------------+
void CConfigurationManager::SetSendTelegramNotifications(bool sendNotifications) {
    m_settings.sendTelegramNotifications = sendNotifications;
}

//+------------------------------------------------------------------+
//| Validate settings                                                |
//+------------------------------------------------------------------+
bool CConfigurationManager::ValidateSettings() {
    bool valid = true;
    
    // Validate lot size
    if(m_settings.lotSize < 0.01 || m_settings.lotSize > 100.0) {
        valid = false;
    }
    
    // Validate stop loss and take profit
    if(m_settings.stopLossPips < 5.0 || m_settings.stopLossPips > 1000.0) {
        valid = false;
    }
    
    if(m_settings.takeProfitPips < 5.0 || m_settings.takeProfitPips > 2000.0) {
        valid = false;
    }
    
    // Validate risk percent
    if(m_settings.maxRiskPercent < 0.1 || m_settings.maxRiskPercent > 10.0) {
        valid = false;
    }
    
    // Validate pattern ratios
    if(m_settings.pinBarRatio < 0.1 || m_settings.pinBarRatio > 1.0) {
        valid = false;
    }
    
    if(m_settings.dojiBodyRatio < 0.0 || m_settings.dojiBodyRatio > 0.5) {
        valid = false;
    }
    
    if(m_settings.engulfingRatio < 0.5 || m_settings.engulfingRatio > 2.0) {
        valid = false;
    }
    
    return valid;
}

//+------------------------------------------------------------------+
//| Get validation errors                                            |
//+------------------------------------------------------------------+
string CConfigurationManager::GetValidationErrors() {
    string errors = "";
    
    if(m_settings.lotSize < 0.01 || m_settings.lotSize > 100.0) {
        errors += "Invalid lot size. Must be between 0.01 and 100.0\n";
    }
    
    if(m_settings.stopLossPips < 5.0 || m_settings.stopLossPips > 1000.0) {
        errors += "Invalid stop loss. Must be between 5.0 and 1000.0 pips\n";
    }
    
    if(m_settings.takeProfitPips < 5.0 || m_settings.takeProfitPips > 2000.0) {
        errors += "Invalid take profit. Must be between 5.0 and 2000.0 pips\n";
    }
    
    if(m_settings.maxRiskPercent < 0.1 || m_settings.maxRiskPercent > 10.0) {
        errors += "Invalid max risk percent. Must be between 0.1 and 10.0\n";
    }
    
    return errors;
}

//+------------------------------------------------------------------+
//| Save settings to file                                            |
//+------------------------------------------------------------------+
bool CConfigurationManager::SaveToFile(string filename) {
    int fileHandle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
    
    if(fileHandle == INVALID_HANDLE) {
        return false;
    }
    
    FileWriteString(fileHandle, "KAYBAMBODLABFX Configuration File\n");
    FileWriteString(fileHandle, "LotSize=" + DoubleToString(m_settings.lotSize, 2) + "\n");
    FileWriteString(fileHandle, "StopLossPips=" + DoubleToString(m_settings.stopLossPips, 1) + "\n");
    FileWriteString(fileHandle, "TakeProfitPips=" + DoubleToString(m_settings.takeProfitPips, 1) + "\n");
    FileWriteString(fileHandle, "MaxRiskPercent=" + DoubleToString(m_settings.maxRiskPercent, 2) + "\n");
    FileWriteString(fileHandle, "UseNewsFilter=" + IntegerToString(m_settings.useNewsFilter ? 1 : 0) + "\n");
    
    FileClose(fileHandle);
    return true;
}

//+------------------------------------------------------------------+
//| Load settings from file                                          |
//+------------------------------------------------------------------+
bool CConfigurationManager::LoadFromFile(string filename) {
    int fileHandle = FileOpen(filename, FILE_READ | FILE_TXT | FILE_ANSI);
    
    if(fileHandle == INVALID_HANDLE) {
        return false;
    }
    
    // Simple file reading implementation
    // In a full implementation, would parse key-value pairs
    
    FileClose(fileHandle);
    return true;
}

//+------------------------------------------------------------------+
//| Print current settings                                           |
//+------------------------------------------------------------------+
void CConfigurationManager::PrintSettings() {
    Print("=== KAYBAMBODLABFX Configuration ===");
    Print("Lot Size: ", m_settings.lotSize);
    Print("Stop Loss: ", m_settings.stopLossPips, " pips");
    Print("Take Profit: ", m_settings.takeProfitPips, " pips");
    Print("Max Risk: ", m_settings.maxRiskPercent, "%");
    Print("Use News Filter: ", m_settings.useNewsFilter ? "Yes" : "No");
    Print("Send Telegram: ", m_settings.sendTelegramNotifications ? "Yes" : "No");
    Print("===================================");
}
