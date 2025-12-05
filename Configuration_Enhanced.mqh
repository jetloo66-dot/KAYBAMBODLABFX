//+------------------------------------------------------------------+
//|                                      Configuration_Enhanced.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Configuration Management Class                                  |
//+------------------------------------------------------------------+
class CConfigurationEnhanced {
private:
    string m_configFile;
    bool m_isInitialized;
    
public:
    CConfigurationEnhanced(string configFile = "KAYB_Config.ini");
    ~CConfigurationEnhanced();
    
    // Initialization
    bool Initialize();
    bool LoadConfiguration();
    bool SaveConfiguration();
    
    // Trading Configuration
    struct TradingConfig {
        // Timeframes
        ENUM_TIMEFRAMES primaryTimeframe;
        ENUM_TIMEFRAMES executionTimeframe;
        
        // Analysis Settings
        int candlesToAnalyze;
        int patternScanCandles;
        int scanIntervalMinutes;
        
        // Level Detection
        int maxLevelsPerType;
        double levelProximityPips;
        int swingDetectionStrength;
        
        // Trade Management
        double defaultLotSize;
        double stopLossBasePips;
        double takeProfitBasePips;
        int maxTradesPerPair;
        bool useTrailingStop;
        double trailingStopPips;
        double trailingStepPips;
        
        // Pattern Detection
        double pinBarWickRatio;
        double dojiMaxBodyRatio;
        double engulfingMinRatio;
        
        // Risk Management
        double maxRiskPercentPerTrade;
        double maxDailyRisk;
        bool useFixedLotSize;
        
        // News Filter
        bool useNewsFilter;
        int newsAvoidanceMinutes;
        
        // Telegram
        string telegramBotToken;
        string telegramChatID;
        bool enableTelegramNotifications;
        
        // Visualization
        bool showLevelsOnChart;
        bool drawBuyZones;
        bool drawSellZones;
        color supportLevelColor;
        color resistanceLevelColor;
        color buyZoneColor;
        color sellZoneColor;
        
        // Multi-Symbol
        string symbolsToScan;
        bool enableMultiSymbolTrading;
        
        // Advanced Settings
        bool enableStrictTrendRules;
        int trendLookbackPeriods;
        bool enableVolumeConfirmation;
        bool enableCorrelationFilter;
        double minPatternStrength;
        bool enableBacktesting;
        
        // Performance Settings
        int maxCacheSize;
        bool enableOptimization;
        int logLevel;
        bool enableDetailedLogging;
    };
    
    TradingConfig config;
    
    // Configuration Methods
    void SetDefaultConfiguration();
    void ApplyConfiguration();
    bool ValidateConfiguration();
    
    // Getter Methods
    TradingConfig GetConfiguration() { return config; }
    
    // Setter Methods
    void SetTradingTimeframes(ENUM_TIMEFRAMES primary, ENUM_TIMEFRAMES execution);
    void SetAnalysisSettings(int candles, int patterns, int interval);
    void SetLevelSettings(int maxLevels, double proximity, int swingStrength);
    void SetTradeSettings(double lotSize, double slPips, double tpPips, int maxTrades);
    void SetRiskSettings(double maxRisk, double dailyRisk, bool fixedLot);
    void SetPatternSettings(double pinRatio, double dojiRatio, double engulfRatio);
    void SetTelegramSettings(string token, string chatID, bool enabled);
    void SetVisualizationSettings(bool showLevels, bool buyZones, bool sellZones);
    
    // Advanced Configuration
    void EnableStrictMode(bool enabled);
    void SetPerformanceMode(bool optimized);
    void SetLoggingLevel(int level);
    
    // Profile Management
    bool SaveProfile(string profileName);
    bool LoadProfile(string profileName);
    bool DeleteProfile(string profileName);
    string[] GetAvailableProfiles();
    
    // Export/Import
    bool ExportConfiguration(string fileName);
    bool ImportConfiguration(string fileName);
    
    // Validation Methods
    bool IsValidTimeframe(ENUM_TIMEFRAMES tf);
    bool IsValidRiskLevel(double risk);
    bool IsValidLotSize(double lot);
    bool IsValidPipsValue(double pips);
    
private:
    bool CreateConfigFile();
    string ConfigValueToString(double value);
    string ConfigValueToString(int value);
    string ConfigValueToString(bool value);
    string ConfigValueToString(color value);
    string ConfigValueToString(ENUM_TIMEFRAMES value);
    
    double StringToDouble(string value);
    int StringToInt(string value);
    bool StringToBool(string value);
    color StringToColor(string value);
    ENUM_TIMEFRAMES StringToTimeframe(string value);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CConfigurationEnhanced::CConfigurationEnhanced(string configFile = "KAYB_Config.ini") {
    m_configFile = configFile;
    m_isInitialized = false;
    
    // Set default configuration
    SetDefaultConfiguration();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CConfigurationEnhanced::~CConfigurationEnhanced() {
    if(m_isInitialized) {
        SaveConfiguration();
    }
}

//+------------------------------------------------------------------+
//| Initialize configuration system                                  |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::Initialize() {
    // Create config file if it doesn't exist
    if(!CreateConfigFile()) {
        Print("ERROR: Failed to create configuration file");
        return false;
    }
    
    // Load configuration from file
    if(!LoadConfiguration()) {
        Print("WARNING: Failed to load configuration, using defaults");
        SetDefaultConfiguration();
    }
    
    // Validate configuration
    if(!ValidateConfiguration()) {
        Print("WARNING: Invalid configuration detected, applying defaults");
        SetDefaultConfiguration();
    }
    
    m_isInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Set default configuration values                                |
//+------------------------------------------------------------------+
void CConfigurationEnhanced::SetDefaultConfiguration() {
    // Timeframes
    config.primaryTimeframe = PERIOD_H1;
    config.executionTimeframe = PERIOD_M5;
    
    // Analysis Settings
    config.candlesToAnalyze = 100;
    config.patternScanCandles = 20;
    config.scanIntervalMinutes = 5;
    
    // Level Detection
    config.maxLevelsPerType = 10;
    config.levelProximityPips = 5.0;
    config.swingDetectionStrength = 5;
    
    // Trade Management
    config.defaultLotSize = 0.01;
    config.stopLossBasePips = 10.0;
    config.takeProfitBasePips = 50.0;
    config.maxTradesPerPair = 2;
    config.useTrailingStop = true;
    config.trailingStopPips = 15.0;
    config.trailingStepPips = 5.0;
    
    // Pattern Detection
    config.pinBarWickRatio = 0.6;
    config.dojiMaxBodyRatio = 0.1;
    config.engulfingMinRatio = 1.0;
    
    // Risk Management
    config.maxRiskPercentPerTrade = 2.0;
    config.maxDailyRisk = 5.0;
    config.useFixedLotSize = false;
    
    // News Filter
    config.useNewsFilter = true;
    config.newsAvoidanceMinutes = 30;
    
    // Telegram
    config.telegramBotToken = "";
    config.telegramChatID = "";
    config.enableTelegramNotifications = false;
    
    // Visualization
    config.showLevelsOnChart = true;
    config.drawBuyZones = true;
    config.drawSellZones = true;
    config.supportLevelColor = clrBlue;
    config.resistanceLevelColor = clrRed;
    config.buyZoneColor = clrLimeGreen;
    config.sellZoneColor = clrOrange;
    
    // Multi-Symbol
    config.symbolsToScan = "EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD,XAUUSD,XAGUSD,BTCUSD,ETHUSD";
    config.enableMultiSymbolTrading = false;
    
    // Advanced Settings
    config.enableStrictTrendRules = true;
    config.trendLookbackPeriods = 50;
    config.enableVolumeConfirmation = false;
    config.enableCorrelationFilter = false;
    config.minPatternStrength = 0.6;
    config.enableBacktesting = false;
    
    // Performance Settings
    config.maxCacheSize = 1000;
    config.enableOptimization = true;
    config.logLevel = 2; // INFO level
    config.enableDetailedLogging = false;
}

//+------------------------------------------------------------------+
//| Load configuration from file                                    |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::LoadConfiguration() {
    // In a real implementation, this would read from an INI file
    // For MQL5, we'd use file operations or global variables
    
    // Example implementation using global variables
    string prefix = "KAYB_Config_";
    
    // Timeframes
    config.primaryTimeframe = (ENUM_TIMEFRAMES)GlobalVariableGet(prefix + "PrimaryTF");
    config.executionTimeframe = (ENUM_TIMEFRAMES)GlobalVariableGet(prefix + "ExecutionTF");
    
    // Analysis Settings
    config.candlesToAnalyze = (int)GlobalVariableGet(prefix + "CandlesToAnalyze");
    config.patternScanCandles = (int)GlobalVariableGet(prefix + "PatternScanCandles");
    config.scanIntervalMinutes = (int)GlobalVariableGet(prefix + "ScanInterval");
    
    // Trade Management
    config.defaultLotSize = GlobalVariableGet(prefix + "DefaultLotSize");
    config.stopLossBasePips = GlobalVariableGet(prefix + "StopLossPips");
    config.takeProfitBasePips = GlobalVariableGet(prefix + "TakeProfitPips");
    config.maxTradesPerPair = (int)GlobalVariableGet(prefix + "MaxTrades");
    
    // Risk Management
    config.maxRiskPercentPerTrade = GlobalVariableGet(prefix + "MaxRisk");
    config.maxDailyRisk = GlobalVariableGet(prefix + "DailyRisk");
    config.useFixedLotSize = (bool)GlobalVariableGet(prefix + "UseFixedLot");
    
    // If no configuration exists, return false to use defaults
    if(GlobalVariableGet(prefix + "Initialized") != 1.0) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Save configuration to file                                      |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::SaveConfiguration() {
    // Example implementation using global variables
    string prefix = "KAYB_Config_";
    
    // Timeframes
    GlobalVariableSet(prefix + "PrimaryTF", (double)config.primaryTimeframe);
    GlobalVariableSet(prefix + "ExecutionTF", (double)config.executionTimeframe);
    
    // Analysis Settings
    GlobalVariableSet(prefix + "CandlesToAnalyze", (double)config.candlesToAnalyze);
    GlobalVariableSet(prefix + "PatternScanCandles", (double)config.patternScanCandles);
    GlobalVariableSet(prefix + "ScanInterval", (double)config.scanIntervalMinutes);
    
    // Trade Management
    GlobalVariableSet(prefix + "DefaultLotSize", config.defaultLotSize);
    GlobalVariableSet(prefix + "StopLossPips", config.stopLossBasePips);
    GlobalVariableSet(prefix + "TakeProfitPips", config.takeProfitBasePips);
    GlobalVariableSet(prefix + "MaxTrades", (double)config.maxTradesPerPair);
    
    // Risk Management
    GlobalVariableSet(prefix + "MaxRisk", config.maxRiskPercentPerTrade);
    GlobalVariableSet(prefix + "DailyRisk", config.maxDailyRisk);
    GlobalVariableSet(prefix + "UseFixedLot", (double)config.useFixedLotSize);
    
    // Mark as initialized
    GlobalVariableSet(prefix + "Initialized", 1.0);
    
    return true;
}

//+------------------------------------------------------------------+
//| Validate configuration                                           |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::ValidateConfiguration() {
    // Validate timeframes
    if(!IsValidTimeframe(config.primaryTimeframe) || !IsValidTimeframe(config.executionTimeframe)) {
        return false;
    }
    
    // Validate analysis settings
    if(config.candlesToAnalyze < 10 || config.candlesToAnalyze > 10000) {
        return false;
    }
    
    if(config.patternScanCandles < 5 || config.patternScanCandles > 100) {
        return false;
    }
    
    // Validate risk settings
    if(!IsValidRiskLevel(config.maxRiskPercentPerTrade) || !IsValidRiskLevel(config.maxDailyRisk)) {
        return false;
    }
    
    // Validate lot size
    if(!IsValidLotSize(config.defaultLotSize)) {
        return false;
    }
    
    // Validate pips values
    if(!IsValidPipsValue(config.stopLossBasePips) || !IsValidPipsValue(config.takeProfitBasePips)) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Set trading timeframes                                          |
//+------------------------------------------------------------------+
void CConfigurationEnhanced::SetTradingTimeframes(ENUM_TIMEFRAMES primary, ENUM_TIMEFRAMES execution) {
    if(IsValidTimeframe(primary) && IsValidTimeframe(execution)) {
        config.primaryTimeframe = primary;
        config.executionTimeframe = execution;
    }
}

//+------------------------------------------------------------------+
//| Set analysis settings                                           |
//+------------------------------------------------------------------+
void CConfigurationEnhanced::SetAnalysisSettings(int candles, int patterns, int interval) {
    if(candles >= 10 && candles <= 10000) {
        config.candlesToAnalyze = candles;
    }
    
    if(patterns >= 5 && patterns <= 100) {
        config.patternScanCandles = patterns;
    }
    
    if(interval >= 1 && interval <= 1440) {
        config.scanIntervalMinutes = interval;
    }
}

//+------------------------------------------------------------------+
//| Set risk settings                                               |
//+------------------------------------------------------------------+
void CConfigurationEnhanced::SetRiskSettings(double maxRisk, double dailyRisk, bool fixedLot) {
    if(IsValidRiskLevel(maxRisk)) {
        config.maxRiskPercentPerTrade = maxRisk;
    }
    
    if(IsValidRiskLevel(dailyRisk)) {
        config.maxDailyRisk = dailyRisk;
    }
    
    config.useFixedLotSize = fixedLot;
}

//+------------------------------------------------------------------+
//| Set Telegram settings                                           |
//+------------------------------------------------------------------+
void CConfigurationEnhanced::SetTelegramSettings(string token, string chatID, bool enabled) {
    config.telegramBotToken = token;
    config.telegramChatID = chatID;
    config.enableTelegramNotifications = enabled && (token != "" && chatID != "");
}

//+------------------------------------------------------------------+
//| Enable strict mode                                              |
//+------------------------------------------------------------------+
void CConfigurationEnhanced::EnableStrictMode(bool enabled) {
    config.enableStrictTrendRules = enabled;
    config.enableVolumeConfirmation = enabled;
    config.enableCorrelationFilter = enabled;
    config.minPatternStrength = enabled ? 0.8 : 0.6;
}

//+------------------------------------------------------------------+
//| Set performance mode                                            |
//+------------------------------------------------------------------+
void CConfigurationEnhanced::SetPerformanceMode(bool optimized) {
    config.enableOptimization = optimized;
    config.maxCacheSize = optimized ? 500 : 1000;
    config.enableDetailedLogging = !optimized;
}

//+------------------------------------------------------------------+
//| Save configuration profile                                      |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::SaveProfile(string profileName) {
    // Implementation would save current config under a profile name
    string prefix = "KAYB_Profile_" + profileName + "_";
    
    // Save all configuration values with profile prefix
    GlobalVariableSet(prefix + "PrimaryTF", (double)config.primaryTimeframe);
    GlobalVariableSet(prefix + "ExecutionTF", (double)config.executionTimeframe);
    GlobalVariableSet(prefix + "DefaultLotSize", config.defaultLotSize);
    GlobalVariableSet(prefix + "StopLossPips", config.stopLossBasePips);
    GlobalVariableSet(prefix + "TakeProfitPips", config.takeProfitBasePips);
    GlobalVariableSet(prefix + "MaxRisk", config.maxRiskPercentPerTrade);
    
    // Mark profile as existing
    GlobalVariableSet("KAYB_ProfileExists_" + profileName, 1.0);
    
    return true;
}

//+------------------------------------------------------------------+
//| Load configuration profile                                      |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::LoadProfile(string profileName) {
    // Check if profile exists
    if(GlobalVariableGet("KAYB_ProfileExists_" + profileName) != 1.0) {
        return false;
    }
    
    string prefix = "KAYB_Profile_" + profileName + "_";
    
    // Load configuration values
    config.primaryTimeframe = (ENUM_TIMEFRAMES)GlobalVariableGet(prefix + "PrimaryTF");
    config.executionTimeframe = (ENUM_TIMEFRAMES)GlobalVariableGet(prefix + "ExecutionTF");
    config.defaultLotSize = GlobalVariableGet(prefix + "DefaultLotSize");
    config.stopLossBasePips = GlobalVariableGet(prefix + "StopLossPips");
    config.takeProfitBasePips = GlobalVariableGet(prefix + "TakeProfitPips");
    config.maxRiskPercentPerTrade = GlobalVariableGet(prefix + "MaxRisk");
    
    return true;
}

//+------------------------------------------------------------------+
//| Validation helper methods                                       |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::IsValidTimeframe(ENUM_TIMEFRAMES tf) {
    return (tf == PERIOD_M1 || tf == PERIOD_M5 || tf == PERIOD_M15 || tf == PERIOD_M30 ||
            tf == PERIOD_H1 || tf == PERIOD_H4 || tf == PERIOD_D1 || tf == PERIOD_W1 || tf == PERIOD_MN1);
}

bool CConfigurationEnhanced::IsValidRiskLevel(double risk) {
    return (risk > 0.0 && risk <= 50.0); // Maximum 50% risk
}

bool CConfigurationEnhanced::IsValidLotSize(double lot) {
    return (lot >= 0.01 && lot <= 100.0);
}

bool CConfigurationEnhanced::IsValidPipsValue(double pips) {
    return (pips > 0.0 && pips <= 1000.0);
}

//+------------------------------------------------------------------+
//| Create configuration file                                       |
//+------------------------------------------------------------------+
bool CConfigurationEnhanced::CreateConfigFile() {
    // In a real implementation, this would create an INI file
    // For now, we'll just return true as we're using global variables
    return true;
}

//+------------------------------------------------------------------+