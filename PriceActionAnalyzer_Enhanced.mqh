//+------------------------------------------------------------------+
//|                                  PriceActionAnalyzer_Enhanced.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Enhanced Price Action Analysis Class                            |
//+------------------------------------------------------------------+
class CPriceActionAnalyzerEnhanced {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_candlesToAnalyze;
    double m_pointValue;
    
public:
    CPriceActionAnalyzerEnhanced(string symbol, ENUM_TIMEFRAMES timeframe, int candles = 100);
    ~CPriceActionAnalyzerEnhanced();
    
    // Core Pattern Detection Methods
    bool IsPinBar(int index, double minWickRatio = 0.6);
    bool IsDoji(int index, double maxBodyRatio = 0.1);
    bool IsBullishEngulfing(int index);
    bool IsBearishEngulfing(int index);
    bool IsInsideBar(int index);
    bool IsOutsideBar(int index);
    bool IsHammer(int index);
    bool IsShootingStar(int index);
    bool IsHangingMan(int index);
    bool InvertedHammer(int index);
    
    // Advanced Pattern Detection
    bool IsMorningStar(int index);
    bool IsEveningStar(int index);
    bool IsHarami(int index);
    bool IsHaramiBullish(int index);
    bool IsHaramiBearish(int index);
    bool IsThreeWhiteSoldiers(int index);
    bool IsThreeBlackCrows(int index);
    
    // Market Structure Methods
    bool IsBreakOfStructure(int index, int lookback = 10);
    bool IsChangeOfCharacter(int index, int lookback = 20);
    bool IsLiquidityGrab(int index, int lookback = 5);
    bool IsOrderBlockFormed(int index, int lookback = 20);
    bool IsFairValueGap(int index);
    bool IsImbalance(int index);
    
    // Support/Resistance Methods
    double FindNearestSupport(double price, int lookback = 50);
    double FindNearestResistance(double price, int lookback = 50);
    bool IsPriceRejection(int index, double level, double tolerance);
    bool IsSupplyZone(int index, int lookback = 20);
    bool IsDemandZone(int index, int lookback = 20);
    bool IsKeyLevel(double price, int lookback = 100);
    
    // Trend Analysis Methods
    bool IsUptrend(int lookback = 20);
    bool IsDowntrend(int lookback = 20);
    bool IsSideways(int lookback = 20);
    bool IsHigherHigh(int index, int lookback = 10);
    bool IsHigherLow(int index, int lookback = 10);
    bool IsLowerHigh(int index, int lookback = 10);  
    bool IsLowerLow(int index, int lookback = 10);
    
    // Volume Analysis Methods
    bool IsVolumeConfirmation(int index);
    bool IsVolumeSpike(int index, double threshold = 1.5);
    bool IsVolumeDrying(int index, int lookback = 5);
    
    // Utility Methods
    double GetCandleBody(int index);
    double GetUpperWick(int index);
    double GetLowerWick(int index);
    double GetCandleRange(int index);
    double GetBodyRatio(int index);
    double GetWickRatio(int index, bool upper = true);
    bool IsBullishCandle(int index);
    bool IsBearishCandle(int index);
    
    // Advanced Utility Methods
    double GetAverageRange(int periods = 20, int startIndex = 1);
    double GetAverageBody(int periods = 20, int startIndex = 1);
    double GetAverageVolume(int periods = 20, int startIndex = 1);
    bool IsSignificantCandle(int index, double threshold = 1.5);
    
private:
    bool GetCandleData(int index, double &open, double &high, double &low, double &close, long &volume);
    bool IsValidIndex(int index);
    double CalculateDistance(double price1, double price2);
    bool IsWithinTolerance(double value1, double value2, double tolerance);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPriceActionAnalyzerEnhanced::CPriceActionAnalyzerEnhanced(string symbol, ENUM_TIMEFRAMES timeframe, int candles = 100) {
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_candlesToAnalyze = candles;
    m_pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPriceActionAnalyzerEnhanced::~CPriceActionAnalyzerEnhanced() {
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Pin Bar Pattern Detection                                        |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsPinBar(int index, double minWickRatio = 0.6) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return false;
    
    double body = MathAbs(close - open);
    double upperWick = high - MathMax(open, close);
    double lowerWick = MathMin(open, close) - low;
    double totalRange = high - low;
    
    if(totalRange <= 0) return false;
    
    // Bullish pin bar (hammer): long lower wick, small body, small upper wick
    if(lowerWick / totalRange >= minWickRatio && body / totalRange <= 0.3 && upperWick / totalRange <= 0.1) {
        return true;
    }
    
    // Bearish pin bar (shooting star): long upper wick, small body, small lower wick
    if(upperWick / totalRange >= minWickRatio && body / totalRange <= 0.3 && lowerWick / totalRange <= 0.1) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Doji Pattern Detection                                           |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsDoji(int index, double maxBodyRatio = 0.1) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return false;
    
    double body = MathAbs(close - open);
    double totalRange = high - low;
    
    if(totalRange <= 0) return false;
    
    // Doji: very small body relative to total range
    return (body / totalRange <= maxBodyRatio);
}

//+------------------------------------------------------------------+
//| Bullish Engulfing Pattern Detection                             |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsBullishEngulfing(int index) {
    if(!IsValidIndex(index) || !IsValidIndex(index + 1)) return false;
    
    double open1, high1, low1, close1, open2, high2, low2, close2;
    long volume1, volume2;
    
    if(!GetCandleData(index, open1, high1, low1, close1, volume1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2, volume2)) return false;
    
    // Previous candle is bearish
    bool prevBearish = close2 < open2;
    // Current candle is bullish
    bool currBullish = close1 > open1;
    // Current candle opens below previous close
    bool opensBelow = open1 < close2;
    // Current candle closes above previous open
    bool closesAbove = close1 > open2;
    // Current candle body is larger than previous
    bool largerBody = MathAbs(close1 - open1) > MathAbs(close2 - open2);
    
    return prevBearish && currBullish && opensBelow && closesAbove && largerBody;
}

//+------------------------------------------------------------------+
//| Bearish Engulfing Pattern Detection                             |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsBearishEngulfing(int index) {
    if(!IsValidIndex(index) || !IsValidIndex(index + 1)) return false;
    
    double open1, high1, low1, close1, open2, high2, low2, close2;
    long volume1, volume2;
    
    if(!GetCandleData(index, open1, high1, low1, close1, volume1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2, volume2)) return false;
    
    // Previous candle is bullish
    bool prevBullish = close2 > open2;
    // Current candle is bearish
    bool currBearish = close1 < open1;
    // Current candle opens above previous close
    bool opensAbove = open1 > close2;
    // Current candle closes below previous open
    bool closesBelow = close1 < open2;
    // Current candle body is larger than previous
    bool largerBody = MathAbs(close1 - open1) > MathAbs(close2 - open2);
    
    return prevBullish && currBearish && opensAbove && closesBelow && largerBody;
}

//+------------------------------------------------------------------+
//| Hammer Pattern Detection                                         |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsHammer(int index) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return false;
    
    double body = MathAbs(close - open);
    double upperWick = high - MathMax(open, close);
    double lowerWick = MathMin(open, close) - low;
    double totalRange = high - low;
    
    if(totalRange <= 0) return false;
    
    // Hammer: long lower wick (at least 2x body), small upper wick
    return (lowerWick >= 2 * body && upperWick <= body * 0.1 && body / totalRange >= 0.1);
}

//+------------------------------------------------------------------+
//| Shooting Star Pattern Detection                                 |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsShootingStar(int index) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return false;
    
    double body = MathAbs(close - open);
    double upperWick = high - MathMax(open, close);
    double lowerWick = MathMin(open, close) - low;
    double totalRange = high - low;
    
    if(totalRange <= 0) return false;
    
    // Shooting Star: long upper wick (at least 2x body), small lower wick
    return (upperWick >= 2 * body && lowerWick <= body * 0.1 && body / totalRange >= 0.1);
}

//+------------------------------------------------------------------+
//| Break of Structure Detection                                     |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsBreakOfStructure(int index, int lookback = 10) {
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
//| Change of Character Detection                                    |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsChangeOfCharacter(int index, int lookback = 20) {
    if(!IsValidIndex(index)) return false;
    
    double close[], high[], low[];
    if(CopyClose(m_symbol, m_timeframe, index, lookback + 5, close) <= 0 ||
       CopyHigh(m_symbol, m_timeframe, index, lookback + 5, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, lookback + 5, low) <= 0) return false;
    
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    // Analyze recent trend direction
    int bullishCandles = 0, bearishCandles = 0;
    
    for(int i = 1; i <= lookback; i++) {
        if(close[i] > close[i + 1]) bullishCandles++;
        else if(close[i] < close[i + 1]) bearishCandles++;
    }
    
    // Current candle should be opposite to recent trend
    bool currentBullish = close[0] > close[1];
    bool recentTrendBearish = bearishCandles > bullishCandles;
    bool recentTrendBullish = bullishCandles > bearishCandles;
    
    // Check for strong reversal signal
    if(currentBullish && recentTrendBearish && IsSignificantCandle(index)) {
        return true; // Bullish change of character
    }
    
    if(!currentBullish && recentTrendBullish && IsSignificantCandle(index)) {
        return true; // Bearish change of character
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Liquidity Grab Detection                                         |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsLiquidityGrab(int index, int lookback = 5) {
    if(!IsValidIndex(index)) return false;
    
    double high[], low[], close[];
    if(CopyHigh(m_symbol, m_timeframe, index, lookback + 3, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, lookback + 3, low) <= 0 ||
       CopyClose(m_symbol, m_timeframe, index, lookback + 3, close) <= 0) return false;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    // Find recent high/low
    double recentHigh = high[1];
    double recentLow = low[1];
    
    for(int i = 2; i <= lookback; i++) {
        recentHigh = MathMax(recentHigh, high[i]);
        recentLow = MathMin(recentLow, low[i]);
    }
    
    // Liquidity grab: spike above/below key level then immediate reversal
    if(high[0] > recentHigh && close[0] < recentHigh) {
        return true; // Grab above highs then close lower
    }
    
    if(low[0] < recentLow && close[0] > recentLow) {
        return true; // Grab below lows then close higher
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Find Nearest Support Level                                       |
//+------------------------------------------------------------------+
double CPriceActionAnalyzerEnhanced::FindNearestSupport(double price, int lookback = 50) {
    double low[];
    if(CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) return 0;
    
    ArraySetAsSeries(low, true);
    
    double nearestSupport = 0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < ArraySize(low); i++) {
        if(low[i] < price) { // Only consider levels below current price
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
//| Find Nearest Resistance Level                                    |
//+------------------------------------------------------------------+
double CPriceActionAnalyzerEnhanced::FindNearestResistance(double price, int lookback = 50) {
    double high[];
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0) return 0;
    
    ArraySetAsSeries(high, true);
    
    double nearestResistance = 0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < ArraySize(high); i++) {
        if(high[i] > price) { // Only consider levels above current price
            double distance = high[i] - price;
            if(distance < minDistance) {
                minDistance = distance;
                nearestResistance = high[i];
            }
        }
    }
    
    return nearestResistance;
}

//+------------------------------------------------------------------+
//| Check if price shows rejection at a level                       |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsPriceRejection(int index, double level, double tolerance) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return false;
    
    double tolerancePoints = tolerance * m_pointValue;
    
    // Check for rejection at resistance (price touches level from below then closes lower)
    if(high >= level - tolerancePoints && high <= level + tolerancePoints && close < open) {
        return true;
    }
    
    // Check for rejection at support (price touches level from above then closes higher)
    if(low >= level - tolerancePoints && low <= level + tolerancePoints && close > open) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for uptrend                                                |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsUptrend(int lookback = 20) {
    double close[];
    if(CopyClose(m_symbol, m_timeframe, 0, lookback, close) <= 0) return false;
    
    ArraySetAsSeries(close, true);
    
    // Simple trend check: more closes higher than lower
    int higherCloses = 0;
    for(int i = 1; i < ArraySize(close); i++) {
        if(close[i - 1] > close[i]) higherCloses++;
    }
    
    return (higherCloses > (ArraySize(close) - 1) / 2);
}

//+------------------------------------------------------------------+
//| Check for downtrend                                              |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsDowntrend(int lookback = 20) {
    double close[];
    if(CopyClose(m_symbol, m_timeframe, 0, lookback, close) <= 0) return false;
    
    ArraySetAsSeries(close, true);
    
    // Simple trend check: more closes lower than higher
    int lowerCloses = 0;
    for(int i = 1; i < ArraySize(close); i++) {
        if(close[i - 1] < close[i]) lowerCloses++;
    }
    
    return (lowerCloses > (ArraySize(close) - 1) / 2);
}

//+------------------------------------------------------------------+
//| Get candle body size                                             |
//+------------------------------------------------------------------+
double CPriceActionAnalyzerEnhanced::GetCandleBody(int index) {
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return 0;
    
    return MathAbs(close - open);
}

//+------------------------------------------------------------------+
//| Get upper wick size                                              |
//+------------------------------------------------------------------+
double CPriceActionAnalyzerEnhanced::GetUpperWick(int index) {
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return 0;
    
    return high - MathMax(open, close);
}

//+------------------------------------------------------------------+
//| Get lower wick size                                              |
//+------------------------------------------------------------------+
double CPriceActionAnalyzerEnhanced::GetLowerWick(int index) {
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return 0;
    
    return MathMin(open, close) - low;
}

//+------------------------------------------------------------------+
//| Get total candle range                                           |
//+------------------------------------------------------------------+
double CPriceActionAnalyzerEnhanced::GetCandleRange(int index) {
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return 0;
    
    return high - low;
}

//+------------------------------------------------------------------+
//| Check if candle is significant compared to average              |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsSignificantCandle(int index, double threshold = 1.5) {
    double currentRange = GetCandleRange(index);
    double averageRange = GetAverageRange(20, index + 1);
    
    if(averageRange <= 0) return false;
    
    return (currentRange >= averageRange * threshold);
}

//+------------------------------------------------------------------+
//| Get average range over specified periods                        |
//+------------------------------------------------------------------+
double CPriceActionAnalyzerEnhanced::GetAverageRange(int periods = 20, int startIndex = 1) {
    double high[], low[];
    if(CopyHigh(m_symbol, m_timeframe, startIndex, periods, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, startIndex, periods, low) <= 0) return 0;
    
    double totalRange = 0;
    for(int i = 0; i < ArraySize(high); i++) {
        totalRange += (high[i] - low[i]);
    }
    
    return totalRange / ArraySize(high);
}

//+------------------------------------------------------------------+
//| Get candle data helper function                                  |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::GetCandleData(int index, double &open, double &high, double &low, double &close, long &volume) {
    if(!IsValidIndex(index)) return false;
    
    double openArray[], highArray[], lowArray[], closeArray[];
    long volumeArray[];
    
    if(CopyOpen(m_symbol, m_timeframe, index, 1, openArray) <= 0 ||
       CopyHigh(m_symbol, m_timeframe, index, 1, highArray) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, 1, lowArray) <= 0 ||
       CopyClose(m_symbol, m_timeframe, index, 1, closeArray) <= 0 ||
       CopyTickVolume(m_symbol, m_timeframe, index, 1, volumeArray) <= 0) {
        return false;
    }
    
    open = openArray[0];
    high = highArray[0];
    low = lowArray[0];
    close = closeArray[0];
    volume = volumeArray[0];
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if index is valid                                          |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsValidIndex(int index) {
    return (index >= 0 && index < Bars(m_symbol, m_timeframe));
}

//+------------------------------------------------------------------+
//| Check if candle is bullish                                       |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsBullishCandle(int index) {
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return false;
    
    return close > open;
}

//+------------------------------------------------------------------+
//| Check if candle is bearish                                       |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzerEnhanced::IsBearishCandle(int index) {
    double open, high, low, close;
    long volume;
    if(!GetCandleData(index, open, high, low, close, volume)) return false;
    
    return close < open;
}

//+------------------------------------------------------------------+