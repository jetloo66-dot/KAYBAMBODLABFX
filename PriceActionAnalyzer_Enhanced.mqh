//+------------------------------------------------------------------+
//|                                    PriceActionAnalyzer_Enhanced.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Enhanced Price Action Analysis Class                             |
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
    
    // Level Detection Methods
    double FindSwingHigh(int lookback = 20, int strength = 5);
    double FindSwingLow(int lookback = 20, int strength = 5);
    double FindHigherHigh(int lookback = 20);
    double FindHigherLow(int lookback = 20);
    double FindLowerHigh(int lookback = 20);
    double FindLowerLow(int lookback = 20);
    
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
//| Get candle data for specified index                              |
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
    return (index >= 0 && index < m_candlesToAnalyze);
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
    
    double high[], low[], close[];
    if(CopyHigh(m_symbol, m_timeframe, index, lookback + 5, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, lookback + 5, low) <= 0 ||
       CopyClose(m_symbol, m_timeframe, index, lookback + 5, close) <= 0) return false;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    // Find recent swing high and low
    double recentHigh = high[ArrayMaximum(high, 1, lookback)];
    double recentLow = low[ArrayMinimum(low, 1, lookback)];
    
    // Check if current price breaks structure
    double currentClose = close[0];
    
    // Bullish break of structure
    if(currentClose > recentHigh) return true;
    
    // Bearish break of structure
    if(currentClose < recentLow) return true;
    
    return false;
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
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < ArraySize(high); i++) {
        if(high[i] > price) {
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
//| Check if price is at a rejection level                           |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsPriceRejection(int index, double level, double tolerance) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double distance = MathAbs(close - level);
    if(distance <= tolerance) {
        // Check for rejection patterns
        double wickSize = 0;
        if(level > close) {
            wickSize = high - MathMax(open, close);
        } else {
            wickSize = MathMin(open, close) - low;
        }
        
        double body = MathAbs(close - open);
        return wickSize > body * 1.5; // Wick is at least 1.5x body size
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for uptrend                                                |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsUptrend(int lookback = 20) {
    double high[], low[];
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) return false;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    int higherHighs = 0;
    int higherLows = 0;
    
    for(int i = 1; i < ArraySize(high) - 1; i++) {
        if(high[i-1] > high[i]) higherHighs++;
        if(low[i-1] > low[i]) higherLows++;
    }
    
    return (higherHighs >= lookback * 0.6 && higherLows >= lookback * 0.6);
}

//+------------------------------------------------------------------+
//| Check for downtrend                                              |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsDowntrend(int lookback = 20) {
    double high[], low[];
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) return false;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    int lowerHighs = 0;
    int lowerLows = 0;
    
    for(int i = 1; i < ArraySize(high) - 1; i++) {
        if(high[i-1] < high[i]) lowerHighs++;
        if(low[i-1] < low[i]) lowerLows++;
    }
    
    return (lowerHighs >= lookback * 0.6 && lowerLows >= lookback * 0.6);
}

//+------------------------------------------------------------------+
//| Check for sideways market                                        |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsSideways(int lookback = 20) {
    return (!IsUptrend(lookback) && !IsDowntrend(lookback));
}

//+------------------------------------------------------------------+
//| Get candle body size                                             |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetCandleBody(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return 0.0;
    
    return MathAbs(close - open);
}

//+------------------------------------------------------------------+
//| Get upper wick size                                              |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetUpperWick(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return 0.0;
    
    return high - MathMax(open, close);
}

//+------------------------------------------------------------------+
//| Get lower wick size                                              |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetLowerWick(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return 0.0;
    
    return MathMin(open, close) - low;
}

//+------------------------------------------------------------------+
//| Get total candle range                                           |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::GetCandleRange(int index) {
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return 0.0;
    
    return high - low;
}

//+------------------------------------------------------------------+
//| Find swing high                                                  |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindSwingHigh(int lookback = 20, int strength = 5) {
    double high[];
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0) return 0.0;
    
    ArraySetAsSeries(high, true);
    
    for(int i = strength; i < ArraySize(high) - strength; i++) {
        bool isSwingHigh = true;
        
        for(int j = 1; j <= strength; j++) {
            if(high[i] <= high[i-j] || high[i] <= high[i+j]) {
                isSwingHigh = false;
                break;
            }
        }
        
        if(isSwingHigh) return high[i];
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Find swing low                                                   |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindSwingLow(int lookback = 20, int strength = 5) {
    double low[];
    if(CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) return 0.0;
    
    ArraySetAsSeries(low, true);
    
    for(int i = strength; i < ArraySize(low) - strength; i++) {
        bool isSwingLow = true;
        
        for(int j = 1; j <= strength; j++) {
            if(low[i] >= low[i-j] || low[i] >= low[i+j]) {
                isSwingLow = false;
                break;
            }
        }
        
        if(isSwingLow) return low[i];
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Find higher high                                                 |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindHigherHigh(int lookback = 20) {
    double high[];
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0) return 0.0;
    
    ArraySetAsSeries(high, true);
    
    // Find the most recent higher high
    for(int i = 1; i < ArraySize(high) - 1; i++) {
        if(high[i-1] > high[i]) {
            return high[i-1];
        }
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Find higher low                                                  |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindHigherLow(int lookback = 20) {
    double low[];
    if(CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) return 0.0;
    
    ArraySetAsSeries(low, true);
    
    // Find the most recent higher low
    for(int i = 1; i < ArraySize(low) - 1; i++) {
        if(low[i-1] > low[i]) {
            return low[i-1];
        }
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Find lower high                                                  |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindLowerHigh(int lookback = 20) {
    double high[];
    if(CopyHigh(m_symbol, m_timeframe, 0, lookback, high) <= 0) return 0.0;
    
    ArraySetAsSeries(high, true);
    
    // Find the most recent lower high
    for(int i = 1; i < ArraySize(high) - 1; i++) {
        if(high[i-1] < high[i]) {
            return high[i-1];
        }
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Find lower low                                                   |
//+------------------------------------------------------------------+
double CPriceActionAnalyzer::FindLowerLow(int lookback = 20) {
    double low[];
    if(CopyLow(m_symbol, m_timeframe, 0, lookback, low) <= 0) return 0.0;
    
    ArraySetAsSeries(low, true);
    
    // Find the most recent lower low
    for(int i = 1; i < ArraySize(low) - 1; i++) {
        if(low[i-1] < low[i]) {
            return low[i-1];
        }
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Inside Bar Detection                                             |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsInsideBar(int index) {
    if(!IsValidIndex(index) || !IsValidIndex(index + 1)) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    // Current candle is inside the previous candle
    return (high1 < high2 && low1 > low2);
}

//+------------------------------------------------------------------+
//| Outside Bar Detection                                            |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsOutsideBar(int index) {
    if(!IsValidIndex(index) || !IsValidIndex(index + 1)) return false;
    
    double open1, high1, low1, close1;
    double open2, high2, low2, close2;
    
    if(!GetCandleData(index, open1, high1, low1, close1) ||
       !GetCandleData(index + 1, open2, high2, low2, close2)) return false;
    
    // Current candle engulfs the previous candle
    return (high1 > high2 && low1 < low2);
}

//+------------------------------------------------------------------+
//| Hammer Detection                                                 |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsHammer(int index) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double lowerWick = MathMin(open, close) - low;
    double upperWick = high - MathMax(open, close);
    double totalRange = high - low;
    
    if(totalRange == 0) return false;
    
    // Hammer conditions: long lower wick, small upper wick, small body
    return (lowerWick >= body * 2 && upperWick <= body * 0.3 && body <= totalRange * 0.3);
}

//+------------------------------------------------------------------+
//| Shooting Star Detection                                          |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsShootingStar(int index) {
    if(!IsValidIndex(index)) return false;
    
    double open, high, low, close;
    if(!GetCandleData(index, open, high, low, close)) return false;
    
    double body = MathAbs(close - open);
    double lowerWick = MathMin(open, close) - low;
    double upperWick = high - MathMax(open, close);
    double totalRange = high - low;
    
    if(totalRange == 0) return false;
    
    // Shooting star conditions: long upper wick, small lower wick, small body
    return (upperWick >= body * 2 && lowerWick <= body * 0.3 && body <= totalRange * 0.3);
}

//+------------------------------------------------------------------+
//| Change of Character Detection                                    |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsChangeOfCharacter(int index, int lookback = 20) {
    if(!IsValidIndex(index)) return false;
    
    // Simplified implementation - would need more sophisticated logic
    return IsBreakOfStructure(index, lookback);
}

//+------------------------------------------------------------------+
//| Liquidity Grab Detection                                         |
//+------------------------------------------------------------------+
bool CPriceActionAnalyzer::IsLiquidityGrab(int index, int lookback = 5) {
    if(!IsValidIndex(index)) return false;
    
    double high[], low[];
    if(CopyHigh(m_symbol, m_timeframe, index, lookback + 2, high) <= 0 ||
       CopyLow(m_symbol, m_timeframe, index, lookback + 2, low) <= 0) return false;
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    // Check if price briefly swept above recent high or below recent low
    double recentHigh = high[ArrayMaximum(high, 1, lookback)];
    double recentLow = low[ArrayMinimum(low, 1, lookback)];
    
    double currentHigh = high[0];
    double currentLow = low[0];
    
    // Liquidity grab above recent high
    if(currentHigh > recentHigh && currentLow < recentHigh) return true;
    
    // Liquidity grab below recent low
    if(currentLow < recentLow && currentHigh > recentLow) return true;
    
    return false;
}
//+------------------------------------------------------------------+