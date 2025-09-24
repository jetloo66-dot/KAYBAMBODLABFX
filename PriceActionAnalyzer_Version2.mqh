//+------------------------------------------------------------------+
//|                                         PriceActionAnalyzer.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Find nearest resistance level (continued)                        |
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