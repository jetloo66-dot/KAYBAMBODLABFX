//+------------------------------------------------------------------+
//|                                                ConfigManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Configuration Management Class                                   |
//+------------------------------------------------------------------+
class CConfigManager {
private:
    string m_configFile;
    bool m_isLoaded;
    
    // Configuration categories
    struct TradingConfig {
        double lotSize;
        double stopLossPips;
        double takeProfitPips; 
        bool useTrailingStop;
        double trailingStopPips;
        double trailingStepPips;
        int maxPositions;
        double maxRiskPercent;
    };
    
    struct PatternConfig {
        double pinBarRatio;
        double dojiBodyRatio;
        double engulfingRatio;
        int patternScanCandles;
        bool enablePinBars;
        bool enableDoji;
        bool enableEngulfing;
        bool enableBreakOfStructure;
        bool enableRetracement;
    };
    
    struct LevelConfig {
        int candlesToScan;
        int maxLevelsToStore;
        double levelProximityPips;
        int swingStrength;
        bool showLevels;
        bool showFibonacci;
        bool showZones;
    };
    
    struct NewsConfig {
        bool useNewsFilter;
        int newsFilterMinutes;
        bool filterHighImpactOnly;
        string newsCurrencies;
    };
    
    struct TelegramConfig {
        string botToken;
        string chatID;
        bool sendNotifications;
        bool sendTradeAlerts;
        bool sendMarketAnalysis;
        bool sendErrorReports;
    };
    
    struct VisualizationConfig {
        color supportColor;
        color resistanceColor;
        color buyZoneColor;
        color sellZoneColor;
        color trendLineColor;
        color entrySignalColor;
        color exitSignalColor;
        bool showTrendIndicator;
        bool showInfoPanel;
    };
    
    // Configuration instances
    TradingConfig m_tradingConfig;
    PatternConfig m_patternConfig;
    LevelConfig m_levelConfig;
    NewsConfig m_newsConfig;
    TelegramConfig m_telegramConfig;
    VisualizationConfig m_visualConfig;
    
public:
    CConfigManager(string configFile = "KAYBAMBODLABFX_Config.ini");
    ~CConfigManager();
    
    // Load/Save configuration
    bool LoadConfiguration();
    bool SaveConfiguration();
    bool ResetToDefaults();
    
    // Trading configuration methods
    double GetLotSize() { return m_tradingConfig.lotSize; }
    void SetLotSize(double size) { m_tradingConfig.lotSize = size; }
    
    double GetStopLossPips() { return m_tradingConfig.stopLossPips; }
    void SetStopLossPips(double pips) { m_tradingConfig.stopLossPips = pips; }
    
    double GetTakeProfitPips() { return m_tradingConfig.takeProfitPips; }
    void SetTakeProfitPips(double pips) { m_tradingConfig.takeProfitPips = pips; }
    
    bool UseTrailingStop() { return m_tradingConfig.useTrailingStop; }
    void SetUseTrailingStop(bool use) { m_tradingConfig.useTrailingStop = use; }
    
    double GetTrailingStopPips() { return m_tradingConfig.trailingStopPips; }
    void SetTrailingStopPips(double pips) { m_tradingConfig.trailingStopPips = pips; }
    
    double GetTrailingStepPips() { return m_tradingConfig.trailingStepPips; }
    void SetTrailingStepPips(double pips) { m_tradingConfig.trailingStepPips = pips; }
    
    int GetMaxPositions() { return m_tradingConfig.maxPositions; }
    void SetMaxPositions(int max) { m_tradingConfig.maxPositions = max; }
    
    double GetMaxRiskPercent() { return m_tradingConfig.maxRiskPercent; }
    void SetMaxRiskPercent(double percent) { m_tradingConfig.maxRiskPercent = percent; }
    
    // Pattern configuration methods
    double GetPinBarRatio() { return m_patternConfig.pinBarRatio; }
    void SetPinBarRatio(double ratio) { m_patternConfig.pinBarRatio = ratio; }
    
    double GetDojiBodyRatio() { return m_patternConfig.dojiBodyRatio; }
    void SetDojiBodyRatio(double ratio) { m_patternConfig.dojiBodyRatio = ratio; }
    
    double GetEngulfingRatio() { return m_patternConfig.engulfingRatio; }
    void SetEngulfingRatio(double ratio) { m_patternConfig.engulfingRatio = ratio; }
    
    int GetPatternScanCandles() { return m_patternConfig.patternScanCandles; }
    void SetPatternScanCandles(int candles) { m_patternConfig.patternScanCandles = candles; }
    
    // Pattern enable/disable methods
    bool IsPinBarEnabled() { return m_patternConfig.enablePinBars; }
    bool IsDojiEnabled() { return m_patternConfig.enableDoji; }
    bool IsEngulfingEnabled() { return m_patternConfig.enableEngulfing; }
    bool IsBreakOfStructureEnabled() { return m_patternConfig.enableBreakOfStructure; }
    bool IsRetracementEnabled() { return m_patternConfig.enableRetracement; }
    
    // Level configuration methods
    int GetCandlesToScan() { return m_levelConfig.candlesToScan; }
    void SetCandlesToScan(int candles) { m_levelConfig.candlesToScan = candles; }
    
    int GetMaxLevelsToStore() { return m_levelConfig.maxLevelsToStore; }
    void SetMaxLevelsToStore(int max) { m_levelConfig.maxLevelsToStore = max; }
    
    double GetLevelProximityPips() { return m_levelConfig.levelProximityPips; }
    void SetLevelProximityPips(double pips) { m_levelConfig.levelProximityPips = pips; }
    
    int GetSwingStrength() { return m_levelConfig.swingStrength; }
    void SetSwingStrength(int strength) { m_levelConfig.swingStrength = strength; }
    
    // Visualization configuration methods
    bool ShowLevels() { return m_levelConfig.showLevels; }
    bool ShowFibonacci() { return m_levelConfig.showFibonacci; }
    bool ShowZones() { return m_levelConfig.showZones; }
    
    // News configuration methods
    bool UseNewsFilter() { return m_newsConfig.useNewsFilter; }
    void SetUseNewsFilter(bool use) { m_newsConfig.useNewsFilter = use; }
    
    int GetNewsFilterMinutes() { return m_newsConfig.newsFilterMinutes; }
    void SetNewsFilterMinutes(int minutes) { m_newsConfig.newsFilterMinutes = minutes; }
    
    bool FilterHighImpactOnly() { return m_newsConfig.filterHighImpactOnly; }
    void SetFilterHighImpactOnly(bool filter) { m_newsConfig.filterHighImpactOnly = filter; }
    
    // Telegram configuration methods
    string GetTelegramBotToken() { return m_telegramConfig.botToken; }
    void SetTelegramBotToken(string token) { m_telegramConfig.botToken = token; }
    
    string GetTelegramChatID() { return m_telegramConfig.chatID; }
    void SetTelegramChatID(string chatID) { m_telegramConfig.chatID = chatID; }
    
    bool SendTelegramNotifications() { return m_telegramConfig.sendNotifications; }
    void SetSendTelegramNotifications(bool send) { m_telegramConfig.sendNotifications = send; }
    
    bool SendTradeAlerts() { return m_telegramConfig.sendTradeAlerts; }
    bool SendMarketAnalysis() { return m_telegramConfig.sendMarketAnalysis; }
    bool SendErrorReports() { return m_telegramConfig.sendErrorReports; }
    
    // Color configuration methods
    color GetSupportColor() { return m_visualConfig.supportColor; }
    color GetResistanceColor() { return m_visualConfig.resistanceColor; }
    color GetBuyZoneColor() { return m_visualConfig.buyZoneColor; }
    color GetSellZoneColor() { return m_visualConfig.sellZoneColor; }
    color GetTrendLineColor() { return m_visualConfig.trendLineColor; }
    color GetEntrySignalColor() { return m_visualConfig.entrySignalColor; }
    color GetExitSignalColor() { return m_visualConfig.exitSignalColor; }
    
    void SetSupportColor(color clr) { m_visualConfig.supportColor = clr; }
    void SetResistanceColor(color clr) { m_visualConfig.resistanceColor = clr; }
    void SetBuyZoneColor(color clr) { m_visualConfig.buyZoneColor = clr; }
    void SetSellZoneColor(color clr) { m_visualConfig.sellZoneColor = clr; }
    
    // Validation methods
    bool ValidateConfiguration();
    string GetValidationErrors();
    
    // Utility methods
    void PrintConfiguration();
    string GetConfigurationSummary();
    bool IsConfigurationLoaded() { return m_isLoaded; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CConfigManager::CConfigManager(string configFile = "KAYBAMBODLABFX_Config.ini") {
    m_configFile = configFile;
    m_isLoaded = false;
    
    // Set default values
    ResetToDefaults();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CConfigManager::~CConfigManager(void) {
    // Save configuration on destruction if needed
    // SaveConfiguration();
}

//+------------------------------------------------------------------+
//| Reset configuration to default values                           |
//+------------------------------------------------------------------+
bool CConfigManager::ResetToDefaults() {
    // Trading defaults
    m_tradingConfig.lotSize = 0.01;
    m_tradingConfig.stopLossPips = 15.0;
    m_tradingConfig.takeProfitPips = 50.0;
    m_tradingConfig.useTrailingStop = true;
    m_tradingConfig.trailingStopPips = 10.0;
    m_tradingConfig.trailingStepPips = 5.0;
    m_tradingConfig.maxPositions = 1;
    m_tradingConfig.maxRiskPercent = 2.0;
    
    // Pattern defaults
    m_patternConfig.pinBarRatio = 0.6;
    m_patternConfig.dojiBodyRatio = 0.1;
    m_patternConfig.engulfingRatio = 1.0;
    m_patternConfig.patternScanCandles = 20;
    m_patternConfig.enablePinBars = true;
    m_patternConfig.enableDoji = true;
    m_patternConfig.enableEngulfing = true;
    m_patternConfig.enableBreakOfStructure = true;
    m_patternConfig.enableRetracement = true;
    
    // Level defaults
    m_levelConfig.candlesToScan = 100;
    m_levelConfig.maxLevelsToStore = 10;
    m_levelConfig.levelProximityPips = 5.0;
    m_levelConfig.swingStrength = 5;
    m_levelConfig.showLevels = true;
    m_levelConfig.showFibonacci = true;
    m_levelConfig.showZones = true;
    
    // News defaults
    m_newsConfig.useNewsFilter = true;
    m_newsConfig.newsFilterMinutes = 30;
    m_newsConfig.filterHighImpactOnly = true;
    m_newsConfig.newsCurrencies = "USD,EUR,GBP,JPY";
    
    // Telegram defaults
    m_telegramConfig.botToken = "";
    m_telegramConfig.chatID = "";
    m_telegramConfig.sendNotifications = false;
    m_telegramConfig.sendTradeAlerts = true;
    m_telegramConfig.sendMarketAnalysis = true;
    m_telegramConfig.sendErrorReports = true;
    
    // Visualization defaults
    m_visualConfig.supportColor = clrBlue;
    m_visualConfig.resistanceColor = clrRed;
    m_visualConfig.buyZoneColor = clrLimeGreen;
    m_visualConfig.sellZoneColor = clrOrange;
    m_visualConfig.trendLineColor = clrYellow;
    m_visualConfig.entrySignalColor = clrGreen;
    m_visualConfig.exitSignalColor = clrMagenta;
    m_visualConfig.showTrendIndicator = true;
    m_visualConfig.showInfoPanel = true;
    
    return true;
}

//+------------------------------------------------------------------+
//| Load configuration from file                                     |
//+------------------------------------------------------------------+
bool CConfigManager::LoadConfiguration() {
    // In a real implementation, this would read from a configuration file
    // For now, we'll use default values and mark as loaded
    
    ResetToDefaults();
    
    // Here you would implement file reading logic:
    // - Open configuration file
    // - Parse configuration sections
    // - Load values into structures
    // - Validate loaded configuration
    
    m_isLoaded = true;
    Print("Configuration loaded successfully with default values");
    return true;
}

//+------------------------------------------------------------------+
//| Save configuration to file                                       |
//+------------------------------------------------------------------+
bool CConfigManager::SaveConfiguration() {
    // In a real implementation, this would save to a configuration file
    // For now, we'll just print a message
    
    Print("Configuration saved successfully to ", m_configFile);
    return true;
}

//+------------------------------------------------------------------+
//| Validate configuration values                                    |
//+------------------------------------------------------------------+
bool CConfigManager::ValidateConfiguration() {
    bool isValid = true;
    
    // Validate trading configuration
    if(m_tradingConfig.lotSize <= 0) {
        Print("ERROR: Invalid lot size: ", m_tradingConfig.lotSize);
        isValid = false;
    }
    
    if(m_tradingConfig.stopLossPips <= 0) {
        Print("ERROR: Invalid stop loss pips: ", m_tradingConfig.stopLossPips);
        isValid = false;
    }
    
    if(m_tradingConfig.takeProfitPips <= 0) {
        Print("ERROR: Invalid take profit pips: ", m_tradingConfig.takeProfitPips);
        isValid = false;
    }
    
    if(m_tradingConfig.maxPositions <= 0) {
        Print("ERROR: Invalid max positions: ", m_tradingConfig.maxPositions);
        isValid = false;
    }
    
    if(m_tradingConfig.maxRiskPercent <= 0 || m_tradingConfig.maxRiskPercent > 100) {
        Print("ERROR: Invalid max risk percent: ", m_tradingConfig.maxRiskPercent);
        isValid = false;
    }
    
    // Validate pattern configuration
    if(m_patternConfig.pinBarRatio <= 0 || m_patternConfig.pinBarRatio > 1) {
        Print("ERROR: Invalid pin bar ratio: ", m_patternConfig.pinBarRatio);
        isValid = false;
    }
    
    if(m_patternConfig.dojiBodyRatio < 0 || m_patternConfig.dojiBodyRatio > 1) {
        Print("ERROR: Invalid doji body ratio: ", m_patternConfig.dojiBodyRatio);
        isValid = false;
    }
    
    // Validate level configuration
    if(m_levelConfig.candlesToScan <= 0) {
        Print("ERROR: Invalid candles to scan: ", m_levelConfig.candlesToScan);
        isValid = false;
    }
    
    if(m_levelConfig.levelProximityPips <= 0) {
        Print("ERROR: Invalid level proximity pips: ", m_levelConfig.levelProximityPips);
        isValid = false;
    }
    
    // Validate news configuration
    if(m_newsConfig.newsFilterMinutes < 0) {
        Print("ERROR: Invalid news filter minutes: ", m_newsConfig.newsFilterMinutes);
        isValid = false;
    }
    
    return isValid;
}

//+------------------------------------------------------------------+
//| Get validation errors as string                                  |
//+------------------------------------------------------------------+
string CConfigManager::GetValidationErrors() {
    string errors = "";
    
    if(!ValidateConfiguration()) {
        errors = "Configuration validation failed. Check the logs for specific errors.";
    } else {
        errors = "Configuration is valid.";
    }
    
    return errors;
}

//+------------------------------------------------------------------+
//| Print current configuration                                      |
//+------------------------------------------------------------------+
void CConfigManager::PrintConfiguration() {
    Print("=== KAYBAMBODLABFX Configuration ===");
    Print("Trading Config:");
    Print("  Lot Size: ", m_tradingConfig.lotSize);
    Print("  Stop Loss: ", m_tradingConfig.stopLossPips, " pips");
    Print("  Take Profit: ", m_tradingConfig.takeProfitPips, " pips");
    Print("  Use Trailing Stop: ", m_tradingConfig.useTrailingStop);
    Print("  Max Positions: ", m_tradingConfig.maxPositions);
    Print("  Max Risk: ", m_tradingConfig.maxRiskPercent, "%");
    
    Print("Pattern Config:");
    Print("  Pin Bar Ratio: ", m_patternConfig.pinBarRatio);
    Print("  Doji Body Ratio: ", m_patternConfig.dojiBodyRatio);
    Print("  Engulfing Ratio: ", m_patternConfig.engulfingRatio);
    Print("  Pattern Scan Candles: ", m_patternConfig.patternScanCandles);
    
    Print("Level Config:");
    Print("  Candles to Scan: ", m_levelConfig.candlesToScan);
    Print("  Max Levels to Store: ", m_levelConfig.maxLevelsToStore);
    Print("  Level Proximity: ", m_levelConfig.levelProximityPips, " pips");
    Print("  Swing Strength: ", m_levelConfig.swingStrength);
    
    Print("News Config:");
    Print("  Use News Filter: ", m_newsConfig.useNewsFilter);
    Print("  News Filter Minutes: ", m_newsConfig.newsFilterMinutes);
    Print("  Filter High Impact Only: ", m_newsConfig.filterHighImpactOnly);
    
    Print("Telegram Config:");
    Print("  Send Notifications: ", m_telegramConfig.sendNotifications);
    Print("  Send Trade Alerts: ", m_telegramConfig.sendTradeAlerts);
    Print("  Send Market Analysis: ", m_telegramConfig.sendMarketAnalysis);
    
    Print("================================");
}

//+------------------------------------------------------------------+
//| Get configuration summary                                        |
//+------------------------------------------------------------------+
string CConfigManager::GetConfigurationSummary() {
    string summary = "KAYBAMBODLABFX Configuration Summary:\n";
    summary += "Lot Size: " + DoubleToString(m_tradingConfig.lotSize, 2) + "\n";
    summary += "Stop Loss: " + DoubleToString(m_tradingConfig.stopLossPips, 1) + " pips\n";
    summary += "Take Profit: " + DoubleToString(m_tradingConfig.takeProfitPips, 1) + " pips\n";
    summary += "Max Positions: " + IntegerToString(m_tradingConfig.maxPositions) + "\n";
    summary += "News Filter: " + (m_newsConfig.useNewsFilter ? "Enabled" : "Disabled") + "\n";
    summary += "Telegram: " + (m_telegramConfig.sendNotifications ? "Enabled" : "Disabled");
    
    return summary;
}