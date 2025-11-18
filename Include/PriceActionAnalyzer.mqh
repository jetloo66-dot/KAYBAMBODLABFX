//+------------------------------------------------------------------+
//|                                         PriceActionAnalyzer.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Price Action Analysis Class                                      |
//+------------------------------------------------------------------+
class CPriceActionAnalyzer {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_candlesToAnalyze;
    
public:
    CPriceActionAnalyzer(string symbol, ENUM_TIMEFRAMES timeframe, int candles = 100);
    ~CPriceActionAnalyzer();
    
    // Pattern Detection Methods
    bool IsPinBar(int index, double minRatio = 0.6);
    bool IsDoji(int index, double maxBodyRatio = 0.1);
    bool IsBullishEngulfing(int index);
    bool IsBearishEngulfing(int index);
    bool IsInsideBar(int index);
    bool IsOutsideBar(int index);
    bool IsHammer(int index);
    bool IsShootingStar(int index);
    
    // Market Structure Methods
    bool IsBreakOfStructure(int index, int lookback = 10);
    bool IsChangeOfCharacter(int index, int lookback = 20);
    bool IsLiquidityGrab(int index, int lookback = 5);
    
    // Support/Resistance Methods
    double FindNearestSupport(double price, int lookback = 50);
    double FindNearestResistance(double price, int lookback = 50);
    bool IsPriceRejection(int index, double level, double tolerance);
    
    // Trend Analysis Methods
    bool IsUptrend(int lookback = 20);
    bool IsDowntrend(int lookback = 20);
    bool IsSideways(int lookback = 20);
    
    // Utility Methods
    double GetCandleBody(int index);
    double GetUpperWick(int index);
    double GetLowerWick(int index);
    double GetCandleRange(int index);
    
private:
    bool GetCandleData(int index, double &open, double &high, double &low, double &close);
    bool IsValidIndex(int index);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPriceActionAnalyzer::CPriceActionAnalyzer(string symbol, ENUM_TIMEFRAMES timeframe, int candles = 100) {
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_candlesToAnalyze = candles;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPriceActionAnalyzer::~CPriceActionAnalyzer(void) {
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Pin Bar Detection                                                |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsPinBar(int index, double minRatio = 0.6) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double totalRange = high - low;
    double upperWick = high - MathMax(open, close);
    double lowerWick = MathMin(open, close) - low;
    
    if(totalRange == 0) return false;
    
    double bodyRatio = body / totalRange;
    
    // Bullish Pin Bar (Hammer)
    if(lowerWick >= body * 2 && upperWick <= body * 0.5 && bodyRatio <= minRatio) {
        return true;
    }
    
    // Bearish Pin Bar (Shooting Star)  
    if(upperWick >= body * 2 && lowerWick <= body * 0.5 && bodyRatio <= minRatio) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Doji Detection                                                   |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsDoji(int index, double maxBodyRatio = 0.1) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double totalRange = high - low;
    
    if(totalRange == 0) return false;
    
    double bodyRatio = body / totalRange;
    
    return bodyRatio <= maxBodyRatio;
}

//+------------------------------------------------------------------+
//| Bullish Engulfing Detection                                      |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsBullishEngulfing(int index) {
    if(!IsValidIndex(index) || !IsValidIndex(index + 1)) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    // Previous candle is bearish
    bool prevBearish = close2 < open2;
    // Current candle is bullish
    bool currBullish = close1 > open1;
    // Current candle opens below previous close
    bool opensBelow = open1 < close2;
    // Current candle closes above previous open
    bool closesAbove = close1 > open2;
    
    return prevBearish && currBullish && opensBelow && closesAbove;
}

//+------------------------------------------------------------------+
//| Bearish Engulfing Detection                                      |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsBearishEngulfing(int index) {
    if(!IsValidIndex(index) || !IsValidIndex(index + 1)) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    // Previous candle is bullish
    bool prevBullish = close2 > open2;
    // Current candle is bearish
    bool currBearish = close1 < open1;
    // Current candle opens above previous close
    bool opensAbove = open1 > close2;
    // Current candle closes below previous open
    bool closesBelow = close1 < open2;
    
    return prevBullish && currBearish && opensAbove && closesBelow;
}

//+------------------------------------------------------------------+
//| Break of Structure Detection                                     |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsBreakOfStructure(int index, int lookback = 10) {
    if(!IsValidIndex(index)) return false;
    
    double high[], low[];
    if(CopyHigh(m_symbol, m_timeframe, index, lookback + 5, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, lookback + 5, low) <= 0) return false;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    // Find recent swing high/low
    double swingHigh = high[1];
    double swingLow = low[1];
    
    for(int i = 2; i <= lookback; i++) {
        swingHigh = MathMax(swingHigh, high[i]);
        swingLow = MathMin(swingLow, low[i]);
    }
    
    // Check for break above swing high (bullish BOS)
    if(high[0] > swingHigh) return true;
    
    // Check for break below swing low (bearish BOS)
    if(low[0] < swingLow) return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Get candle data                                                  |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::GetCandleData(int index, double &open, double &high, double &low, double &close) {
    if(!IsValidIndex(index)) return false;
    
    double openArray[], highArray[], lowArray[], closeArray[];
    
    if(CopyOpen(m_symbol, m_timeframe, index, 1, openArray) <= 0 ||
       CopyHigh(m_symbol, m_timeframe, index, 1, highArray) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, 1, lowArray) <= 0 ||
       CopyClose(m_symbol, m_timeframe, index, 1, closeArray) <= 0) {
        return false;
    }
    
    open = openArray[0];
    high = highArray[0];
    low = lowArray[0];
    close = closeArray[0];
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if index is valid                                          |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsValidIndex(int index) {
    return (index >= 0 && index < Bars(m_symbol, m_timeframe));
}

//+------------------------------------------------------------------+
//| Find nearest support level                                       |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindNearestSupport(double price, int lookback = 50) {
    double low[];
    if(CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) return 0.0;
    
    ArraySetAsSeries(low, true);
    
    double nearestSupport = 0.0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < ArraySize(low); i++) {
        if(low[i] < price) {
            double distance = price - low[i];
            if(distance < minDistance) {
                minDistance = distance;
                nearestSupport = low[i];
            }
        }
    }
    
    return nearestSupport;
}

//+------------------------------------------------------------------+
//| Find nearest resistance level                                    |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindNearestResistance(double price, int lookback = 50) {
    double high[];
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0) return 0.0;
    
    ArraySetAsSeries(high, true);
    
    double nearestResistance = 0.0;
    double minDistance