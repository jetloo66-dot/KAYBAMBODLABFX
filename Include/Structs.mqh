//+------------------------------------------------------------------+
//|                                                     Structs.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_CANDLE_PATTERN {
    PATTERN_NONE = 0,
    PATTERN_DOJI,
    PATTERN_HAMMER,
    PATTERN_SHOOTING_STAR,
    PATTERN_BULLISH_ENGULFING,
    PATTERN_BEARISH_ENGULFING,
    PATTERN_MORNING_STAR,
    PATTERN_EVENING_STAR,
    PATTERN_HARAMI,
    PATTERN_THREE_SOLDIERS,
    PATTERN_THREE_CROWS,
    PATTERN_INSIDE_BAR,
    PATTERN_OUTSIDE_BAR,
    PATTERN_PIN_BAR
};

enum ENUM_INDICATOR_TYPE {
    IND_MA = 0,
    IND_RSI,
    IND_MACD,
    IND_ATR,
    IND_BOLLINGER,
    IND_ICHIMOKU,
    IND_ADX,
    IND_VOLUME
};

enum ENUM_SIGNAL_DIRECTION {
    SIGNAL_NONE = 0,
    SIGNAL_BUY,
    SIGNAL_SELL
};

enum ENUM_TREND_DIRECTION {
    TREND_NONE = 0,
    TREND_UP,
    TREND_DOWN,
    TREND_SIDEWAYS
};

//+------------------------------------------------------------------+
//| Signal Information Structure                                     |
//+------------------------------------------------------------------+
struct SignalInfo {
    // Basic signal data
    ENUM_SIGNAL_DIRECTION direction;
    datetime timestamp;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double lotSize;
    string symbol;
    
    // Pattern information
    ENUM_CANDLE_PATTERN pattern;
    double patternStrength;
    double patternReliability;
    
    // Technical analysis
    ENUM_TREND_DIRECTION trend;
    double trendStrength;
    double supportLevel;
    double resistanceLevel;
    
    // Confirmation data
    int confirmations;
    double correlation;
    bool isValid;
    double confidence;
    
    // Risk management
    double riskPercent;
    double riskReward;
    double maxRisk;
    
    // Additional data
    string comment;
    int magicNumber;
    datetime expiry;
};

//+------------------------------------------------------------------+
//| Strategy Settings Structure                                      |
//+------------------------------------------------------------------+
struct StrategySettings {
    // Timeframe settings
    ENUM_TIMEFRAMES analysisTimeframes[3];
    ENUM_TIMEFRAMES executionTimeframe;
    
    // Scanning parameters
    int candlesToScan;
    int patternScanCandles;
    int scanIntervalMinutes;
    
    // Level detection
    int maxLevelsToStore;
    double levelProximityPips;
    int swingStrength;
    
    // Trading parameters
    double lotSize;
    double stopLossPips;
    double takeProfitPips;
    bool useTrailingStop;
    double trailingStopPips;
    double trailingStepPips;
    
    // Pattern settings
    double pinBarRatio;
    double dojiBodyRatio;
    double engulfingRatio;
    
    // Risk management
    double maxRiskPercent;
    int maxPositions;
    double maxDailyLoss;
    
    // News filter
    bool useNewsFilter;
    int newsFilterMinutes;
    
    // Telegram settings
    string telegramBotToken;
    string telegramChatID;
    bool sendTelegramNotifications;
    
    // Visualization
    bool showLevels;
    bool showFibonacci;
    bool showZones;
    color supportColor;
    color resistanceColor;
    color buyZoneColor;
    color sellZoneColor;
    
    // Magic number
    int magicNumber;
};

//+------------------------------------------------------------------+
//| Price Level Structure                                            |
//+------------------------------------------------------------------+
struct PriceLevel {
    double price;
    datetime timestamp;
    int strength;
    int touches;
    bool isValid;
    string type; // "SUPPORT", "RESISTANCE", "SWING_HIGH", "SWING_LOW"
    ENUM_TIMEFRAMES timeframe;
};

//+------------------------------------------------------------------+
//| Pattern Analysis Result                                          |
//+------------------------------------------------------------------+
struct PatternAnalysis {
    ENUM_CANDLE_PATTERN pattern;
    bool isValid;
    double strength;
    double reliability;
    int barIndex;
    datetime timestamp;
    string description;
    bool isBullish;
    double confirmationLevel;
};

//+------------------------------------------------------------------+
//| Market Structure Data                                            |
//+------------------------------------------------------------------+
struct MarketStructure {
    // Trend data
    ENUM_TREND_DIRECTION currentTrend;
    double trendStrength;
    datetime trendStart;
    
    // Key levels
    double higherHigh;
    double higherLow;
    double lowerHigh;
    double lowerLow;
    
    // Swing points
    double swingHigh;
    double swingLow;
    datetime swingHighTime;
    datetime swingLowTime;
    
    // Structure breaks
    bool breakOfStructure;
    bool changeOfCharacter;
    double structureBreakLevel;
    
    // Fibonacci levels
    double fib236;
    double fib382;
    double fib500;
    double fib618;
    double fib786;
    
    bool isStructureValid;
    datetime lastUpdate;
};

//+------------------------------------------------------------------+
//| Risk Data Structure                                              |
//+------------------------------------------------------------------+
struct RiskData {
    double accountBalance;
    double accountEquity;
    double currentDrawdown;
    double maxDrawdown;
    double dailyPnL;
    double totalRisk;
    double riskPercent;
    int openPositions;
    bool riskLimitReached;
    bool dailyLimitReached;
    datetime lastRiskUpdate;
};

//+------------------------------------------------------------------+
//| Trade Execution Data                                             |
//+------------------------------------------------------------------+
struct TradeExecution {
    bool canTrade;
    string reason;
    double calculatedLotSize;
    double stopLossPrice;
    double takeProfitPrice;
    double riskAmount;
    double rewardAmount;
    double riskRewardRatio;
    int slippage;
    int magic;
    string comment;
};

//+------------------------------------------------------------------+
//| News Event Structure                                             |
//+------------------------------------------------------------------+
struct NewsEvent {
    datetime eventTime;
    string currency;
    string eventName;
    int importance; // 1=Low, 2=Medium, 3=High
    string forecast;
    string previous;
    string actual;
    bool affectsSymbol;
};

//+------------------------------------------------------------------+
//| Indicator Data Structure                                         |
//+------------------------------------------------------------------+
struct IndicatorData {
    ENUM_INDICATOR_TYPE type;
    double value;
    double previousValue;
    double smoothedValue;
    double filteredValue;
    bool isValid;
    datetime timestamp;
    int period;
    string timeframe;
    double correlation;
};

//+------------------------------------------------------------------+
//| Cache Entry Structure                                            |
//+------------------------------------------------------------------+
struct CacheEntry {
    string key;
    double value;
    datetime timestamp;
    bool isValid;
    int accessCount;
    datetime lastAccess;
};

//+------------------------------------------------------------------+
//| Correlation Data Structure                                       |
//+------------------------------------------------------------------+
struct CorrelationData {
    string indicator1;
    string indicator2;
    double correlation;
    datetime calculated;
    bool isValid;
    int timeframe1;
    int timeframe2;
    int period;
};

//+------------------------------------------------------------------+
//| Optimization Result Structure                                    |
//+------------------------------------------------------------------+
struct OptimizationResult {
    double correlation;
    double efficiency;
    double lag;
    double noise;
    double smoothness;
    bool isOptimal;
    string parameters;
    datetime optimized;
};

//+------------------------------------------------------------------+
//| Validation Result Structure                                      |
//+------------------------------------------------------------------+
struct ValidationResult {
    bool isValid;
    double score;
    string reason;
    int errorCode;
    string details;
    datetime validated;
};

//+------------------------------------------------------------------+
//| Position Management Structure                                    |
//+------------------------------------------------------------------+
struct PositionData {
    ulong ticket;
    string symbol;
    ENUM_POSITION_TYPE type;
    double volume;
    double openPrice;
    double currentPrice;
    double stopLoss;
    double takeProfit;
    double profit;
    double swap;
    datetime openTime;
    int magic;
    string comment;
    bool trailingEnabled;
    double trailingStop;
    double trailingStep;
};

//+------------------------------------------------------------------+
//| Telegram Message Structure                                       |
//+------------------------------------------------------------------+
struct TelegramMessage {
    string chatID;
    string text;
    string parseMode;
    bool disableWebPagePreview;
    bool disableNotification;
    int messageID;
    bool sent;
    datetime timestamp;
};