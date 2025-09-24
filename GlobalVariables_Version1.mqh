//+------------------------------------------------------------------+
//|                                              GlobalVariables.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Global Constants                                                 |
//+------------------------------------------------------------------+
#define MAX_LEVELS 10
#define MAX_PATTERNS 20
#define MAX_TIMEFRAMES 4
#define MAX_CACHE_SIZE 1000
#define MAX_CORRELATION_PAIRS 50

// Trading constants
#define MIN_LOT_SIZE 0.01
#define MAX_LOT_SIZE 100.0
#define MIN_STOP_LOSS 5.0
#define MAX_STOP_LOSS 1000.0
#define MIN_TAKE_PROFIT 5.0
#define MAX_TAKE_PROFIT 2000.0

// Pattern detection constants
#define MIN_PATTERN_STRENGTH 0.1
#define MAX_PATTERN_STRENGTH 1.0
#define MIN_PATTERN_RELIABILITY 0.5
#define MAX_PATTERN_RELIABILITY 1.0

// Risk management constants
#define MIN_RISK_PERCENT 0.1
#define MAX_RISK_PERCENT 10.0
#define MAX_DAILY_LOSS_PERCENT 20.0
#define MAX_DRAWDOWN_PERCENT 50.0

// Correlation constants
#define MIN_CORRELATION -1.0
#define MAX_CORRELATION 1.0
#define STRONG_CORRELATION_THRESHOLD 0.7
#define WEAK_CORRELATION_THRESHOLD 0.3

// Cache constants
#define CACHE_EXPIRY_SECONDS 3600 // 1 hour
#define MAX_CACHE_AGE_SECONDS 7200 // 2 hours

// Telegram constants
#define TELEGRAM_MAX_MESSAGE_LENGTH 4096
#define TELEGRAM_TIMEOUT_SECONDS 30

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
// System state
extern bool g_isInitialized = false;
extern bool g_isOptimization = false;
extern bool g_isTesting = false;
extern datetime g_lastUpdate = 0;
extern datetime g_startTime = 0;

// Trading state
extern bool g_tradingEnabled = true;
extern bool g_newBarDetected = false;
extern int g_totalSignals = 0;
extern int g_validSignals = 0;
extern int g_executedTrades = 0;
extern int g_successfulTrades = 0;

// Market data
extern string g_currentSymbol = "";
extern ENUM_TIMEFRAMES g_currentTimeframe = PERIOD_CURRENT;
extern double g_currentSpread = 0.0;
extern double g_currentAsk = 0.0;
extern double g_currentBid = 0.0;

// Pattern detection state
extern ENUM_CANDLE_PATTERN g_lastPattern = PATTERN_NONE;
extern datetime g_lastPatternTime = 0;
extern double g_lastPatternStrength = 0.0;

// Trend analysis state
extern ENUM_TREND_DIRECTION g_currentTrend = TREND_NONE;
extern double g_trendStrength = 0.0;
extern datetime g_trendChangeTime = 0;

// Risk management state
extern double g_currentRisk = 0.0;
extern double g_dailyPnL = 0.0;
extern double g_maxDrawdown = 0.0;
extern bool g_riskLimitReached = false;

// Correlation state
extern double g_averageCorrelation = 0.0;
extern int g_correlationCount = 0;
extern datetime g_lastCorrelationUpdate = 0;

// Cache state
extern int g_cacheHits = 0;
extern int g_cacheMisses = 0;
extern datetime g_lastCacheCleanup = 0;

// Error handling
extern int g_lastErrorCode = 0;
extern string g_lastErrorMessage = "";
extern datetime g_lastErrorTime = 0;

// Performance metrics
extern int g_totalCalculations = 0;
extern int g_averageCalculationTime = 0;
extern datetime g_performanceStartTime = 0;

//+------------------------------------------------------------------+
//| Global Arrays                                                    |
//+------------------------------------------------------------------+
// Price levels
extern double g_supportLevels[MAX_LEVELS];
extern double g_resistanceLevels[MAX_LEVELS];
extern double g_swingHighs[MAX_LEVELS];
extern double g_swingLows[MAX_LEVELS];

// Pattern history
extern ENUM_CANDLE_PATTERN g_patternHistory[MAX_PATTERNS];
extern datetime g_patternTimes[MAX_PATTERNS];
extern double g_patternStrengths[MAX_PATTERNS];

// Timeframes
extern ENUM_TIMEFRAMES g_analysisTimeframes[MAX_TIMEFRAMES];
extern bool g_timeframeEnabled[MAX_TIMEFRAMES];

// Indicator handles
extern int g_indicatorHandles[MAX_TIMEFRAMES * 10];
extern bool g_handleValid[MAX_TIMEFRAMES * 10];

//+------------------------------------------------------------------+
//| Global Utility Functions                                         |
//+------------------------------------------------------------------+
void InitializeGlobalVariables() {
    g_isInitialized = false;
    g_isOptimization = MQLInfoInteger(MQL_OPTIMIZATION);
    g_isTesting = MQLInfoInteger(MQL_TESTER);
    g_startTime = TimeCurrent();
    g_currentSymbol = _Symbol;
    g_currentTimeframe = _Period;
    
    // Initialize arrays
    ArrayInitialize(g_supportLevels, 0.0);
    ArrayInitialize(g_resistanceLevels, 0.0);
    ArrayInitialize(g_swingHighs, 0.0);
    ArrayInitialize(g_swingLows, 0.0);
    
    ArrayInitialize(g_patternHistory, PATTERN_NONE);
    ArrayInitialize(g_patternTimes, 0);
    ArrayInitialize(g_patternStrengths, 0.0);
    
    ArrayInitialize(g_indicatorHandles, INVALID_HANDLE);
    ArrayInitialize(g_handleValid, false);
    
    ArrayInitialize(g_timeframeEnabled, false);
    
    g_isInitialized = true;
}

void UpdateGlobalMarketData() {
    g_currentAsk = SymbolInfoDouble(g_currentSymbol, SYMBOL_ASK);
    g_currentBid = SymbolInfoDouble(g_currentSymbol, SYMBOL_BID);
    g_currentSpread = g_currentAsk - g_currentBid;
    g_lastUpdate = TimeCurrent();
}

void CleanupGlobalVariables() {
    // Clean up indicator handles
    for(int i = 0; i < ArraySize(g_indicatorHandles); i++) {
        if(g_indicatorHandles[i] != INVALID_HANDLE) {
            IndicatorRelease(g_indicatorHandles[i]);
            g_indicatorHandles[i] = INVALID_HANDLE;
        }
    }
    
    g_isInitialized = false;
}

bool IsNewBar() {
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(g_currentSymbol, g_currentTimeframe, 0);
    
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        g_newBarDetected = true;
        return true;
    }
    
    g_newBarDetected = false;
    return false;
}

string GetTimeframeString(ENUM_TIMEFRAMES timeframe) {
    switch(timeframe) {
        case PERIOD_M1: return "M1";
        case PERIOD_M5: return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1: return "H1";
        case PERIOD_H4: return "H4";
        case PERIOD_D1: return "D1";
        case PERIOD_W1: return "W1";
        case PERIOD_MN1: return "MN1";
        default: return "UNKNOWN";
    }
}

string GetPatternString(ENUM_CANDLE_PATTERN pattern) {
    switch(pattern) {
        case PATTERN_DOJI: return "Doji";
        case PATTERN_HAMMER: return "Hammer";
        case PATTERN_SHOOTING_STAR: return "Shooting Star";
        case PATTERN_BULLISH_ENGULFING: return "Bullish Engulfing";
        case PATTERN_BEARISH_ENGULFING: return "Bearish Engulfing";
        case PATTERN_MORNING_STAR: return "Morning Star";
        case PATTERN_EVENING_STAR: return "Evening Star";
        case PATTERN_HARAMI: return "Harami";
        case PATTERN_THREE_SOLDIERS: return "Three White Soldiers";
        case PATTERN_THREE_CROWS: return "Three Black Crows";
        case PATTERN_INSIDE_BAR: return "Inside Bar";
        case PATTERN_OUTSIDE_BAR: return "Outside Bar";
        case PATTERN_PIN_BAR: return "Pin Bar";
        default: return "None";
    }
}

string GetTrendString(ENUM_TREND_DIRECTION trend) {
    switch(trend) {
        case TREND_UP: return "UPTREND";
        case TREND_DOWN: return "DOWNTREND";
        case TREND_SIDEWAYS: return "SIDEWAYS";
        default: return "NONE";
    }
}

double NormalizeLotSize(double lotSize) {
    double minLot = SymbolInfoDouble(g_currentSymbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(g_currentSymbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(g_currentSymbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    lotSize = MathRound(lotSize / lotStep) * lotStep;
    
    return lotSize;
}

double NormalizePrice(double price) {
    int digits = (int)SymbolInfoInteger(g_currentSymbol, SYMBOL_DIGITS);
    return NormalizeDouble(price, digits);
}

bool IsMarketOpen() {
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    // Simple market hours check (can be enhanced)
    if(dt.day_of_week == 0 || dt.day_of_week == 6) return false; // Weekend
    if(dt.hour < 1 || dt.hour > 23) return false; // Outside trading hours
    
    return true;
}

void LogError(int errorCode, string message) {
    g_lastErrorCode = errorCode;
    g_lastErrorMessage = message;
    g_lastErrorTime = TimeCurrent();
    
    Print("ERROR [", errorCode, "]: ", message);
}

void UpdatePerformanceMetrics() {
    g_totalCalculations++;
    
    if(g_performanceStartTime == 0) {
        g_performanceStartTime = TimeCurrent();
    }
}