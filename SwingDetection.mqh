//+------------------------------------------------------------------+
//|                                              SwingDetection.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Swing Type Enumeration                                           |
//+------------------------------------------------------------------+
enum ENUM_SWING_TYPE {
    SWING_NONE = 0,
    SWING_HH,    // Higher High
    SWING_HL,    // Higher Low
    SWING_LH,    // Lower High
    SWING_LL     // Lower Low
};

//+------------------------------------------------------------------+
//| Swing Point Structure                                            |
//+------------------------------------------------------------------+
struct SwingPoint {
    datetime time;
    double price;
    int barIndex;
    ENUM_SWING_TYPE type;
    bool isHigh;
    int strength;
};

//+------------------------------------------------------------------+
//| Swing Detection Class                                            |
//+------------------------------------------------------------------+
class CSwingDetection {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_leftBars;
    int m_rightBars;
    int m_maxSwings;
    
    SwingPoint m_swingHighs[];
    SwingPoint m_swingLows[];
    
    datetime m_lastSwingHighTime;
    datetime m_lastSwingLowTime;
    
    // Private methods
    bool IsSwingHigh(int index);
    bool IsSwingLow(int index);
    void AddSwingHigh(datetime time, double price, int index);
    void AddSwingLow(datetime time, double price, int index);
    void CleanOldSwings();
    ENUM_SWING_TYPE ClassifySwingHigh(double currentHigh, double previousHigh);
    ENUM_SWING_TYPE ClassifySwingLow(double currentLow, double previousLow);
    
public:
    CSwingDetection(string symbol, ENUM_TIMEFRAMES timeframe, int leftBars = 5, int rightBars = 5, int maxSwings = 10);
    ~CSwingDetection();
    
    bool Initialize();
    void Update();
    
    // Getters
    int GetSwingHighCount() { return ArraySize(m_swingHighs); }
    int GetSwingLowCount() { return ArraySize(m_swingLows); }
    bool GetLastSwingHigh(SwingPoint &point);
    bool GetLastSwingLow(SwingPoint &point);
    bool GetSwingHigh(int index, SwingPoint &point);
    bool GetSwingLow(int index, SwingPoint &point);
    
    // Analysis methods
    bool IsBreakOfStructureBuy(double currentPrice);
    bool IsBreakOfStructureSell(double currentPrice);
    bool IsRetracementToLastLL(double currentLow);
    bool IsRetracementToLastHH(double currentHigh);
    double GetLastLLLowestPrice();
    double GetLastHHHighestPrice();
    
    // Structure analysis
    bool IsUptrend();
    bool IsDowntrend();
    ENUM_SWING_TYPE GetCurrentStructure();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSwingDetection::CSwingDetection(string symbol, ENUM_TIMEFRAMES timeframe, int leftBars, int rightBars, int maxSwings) {
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_leftBars = leftBars;
    m_rightBars = rightBars;
    m_maxSwings = maxSwings;
    m_lastSwingHighTime = 0;
    m_lastSwingLowTime = 0;
    
    ArrayResize(m_swingHighs, 0);
    ArrayResize(m_swingLows, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSwingDetection::~CSwingDetection(void) {
    ArrayFree(m_swingHighs);
    ArrayFree(m_swingLows);
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CSwingDetection::Initialize(void) {
    // Verify symbol exists
    if(!SymbolSelect(m_symbol, true)) {
        Print("Error: Symbol ", m_symbol, " not found");
        return false;
    }
    
    // Initial swing detection
    Update();
    return true;
}

//+------------------------------------------------------------------+
//| Update swing points                                              |
//+------------------------------------------------------------------+
void CSwingDetection::Update(void) {
    int bars = iBars(m_symbol, m_timeframe);
    if(bars < m_leftBars + m_rightBars + 10) {
        Print("Insufficient bars for swing detection");
        return;
    }
    
    // Scan for swing highs and lows
    // Limit scan to 200 bars by default to balance accuracy and performance
    // This can be adjusted based on timeframe and requirements
    int maxScanBars = 200;
    for(int i = m_rightBars; i < MathMin(bars - m_leftBars, maxScanBars); i++) {
        if(IsSwingHigh(i)) {
            MqlRates rates[];
            if(CopyRates(m_symbol, m_timeframe, i, 1, rates) > 0) {
                AddSwingHigh(rates[0].time, rates[0].high, i);
            }
        }
        
        if(IsSwingLow(i)) {
            MqlRates rates[];
            if(CopyRates(m_symbol, m_timeframe, i, 1, rates) > 0) {
                AddSwingLow(rates[0].time, rates[0].low, i);
            }
        }
    }
    
    CleanOldSwings();
}

//+------------------------------------------------------------------+
//| Check if bar is a swing high                                     |
//+------------------------------------------------------------------+
bool CSwingDetection::IsSwingHigh(int index) {
    double high[];
    if(CopyHigh(m_symbol, m_timeframe, index - m_leftBars, m_leftBars + m_rightBars + 1, high) <= 0)
        return false;
    
    double centerHigh = high[m_leftBars];
    
    // Check if center bar is higher than surrounding bars
    for(int i = 0; i < ArraySize(high); i++) {
        if(i == m_leftBars) continue;
        if(high[i] >= centerHigh) return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if bar is a swing low                                      |
//+------------------------------------------------------------------+
bool CSwingDetection::IsSwingLow(int index) {
    double low[];
    if(CopyLow(m_symbol, m_timeframe, index - m_leftBars, m_leftBars + m_rightBars + 1, low) <= 0)
        return false;
    
    double centerLow = low[m_leftBars];
    
    // Check if center bar is lower than surrounding bars
    for(int i = 0; i < ArraySize(low); i++) {
        if(i == m_leftBars) continue;
        if(low[i] <= centerLow) return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Add swing high                                                   |
//+------------------------------------------------------------------+
void CSwingDetection::AddSwingHigh(datetime time, double price, int index) {
    // Avoid duplicates
    if(time == m_lastSwingHighTime) return;
    
    int size = ArraySize(m_swingHighs);
    ArrayResize(m_swingHighs, size + 1);
    
    m_swingHighs[size].time = time;
    m_swingHighs[size].price = price;
    m_swingHighs[size].barIndex = index;
    m_swingHighs[size].isHigh = true;
    m_swingHighs[size].strength = m_leftBars + m_rightBars;
    
    // Classify swing type
    if(size > 0) {
        m_swingHighs[size].type = ClassifySwingHigh(price, m_swingHighs[size-1].price);
    } else {
        m_swingHighs[size].type = SWING_NONE;
    }
    
    m_lastSwingHighTime = time;
}

//+------------------------------------------------------------------+
//| Add swing low                                                    |
//+------------------------------------------------------------------+
void CSwingDetection::AddSwingLow(datetime time, double price, int index) {
    // Avoid duplicates
    if(time == m_lastSwingLowTime) return;
    
    int size = ArraySize(m_swingLows);
    ArrayResize(m_swingLows, size + 1);
    
    m_swingLows[size].time = time;
    m_swingLows[size].price = price;
    m_swingLows[size].barIndex = index;
    m_swingLows[size].isHigh = false;
    m_swingLows[size].strength = m_leftBars + m_rightBars;
    
    // Classify swing type
    if(size > 0) {
        m_swingLows[size].type = ClassifySwingLow(price, m_swingLows[size-1].price);
    } else {
        m_swingLows[size].type = SWING_NONE;
    }
    
    m_lastSwingLowTime = time;
}

//+------------------------------------------------------------------+
//| Clean old swings keeping only recent ones                        |
//+------------------------------------------------------------------+
void CSwingDetection::CleanOldSwings(void) {
    // Keep only the last m_maxSwings
    int highCount = ArraySize(m_swingHighs);
    if(highCount > m_maxSwings) {
        SwingPoint temp[];
        ArrayResize(temp, m_maxSwings);
        for(int i = 0; i < m_maxSwings; i++) {
            temp[i] = m_swingHighs[highCount - m_maxSwings + i];
        }
        // Manually copy instead of ArrayCopy to ensure compatibility
        ArrayResize(m_swingHighs, m_maxSwings);
        for(int i = 0; i < m_maxSwings; i++) {
            m_swingHighs[i] = temp[i];
        }
    }
    
    int lowCount = ArraySize(m_swingLows);
    if(lowCount > m_maxSwings) {
        SwingPoint temp[];
        ArrayResize(temp, m_maxSwings);
        for(int i = 0; i < m_maxSwings; i++) {
            temp[i] = m_swingLows[lowCount - m_maxSwings + i];
        }
        // Manually copy instead of ArrayCopy to ensure compatibility
        ArrayResize(m_swingLows, m_maxSwings);
        for(int i = 0; i < m_maxSwings; i++) {
            m_swingLows[i] = temp[i];
        }
    }
}

//+------------------------------------------------------------------+
//| Classify swing high type                                         |
//+------------------------------------------------------------------+
ENUM_SWING_TYPE CSwingDetection::ClassifySwingHigh(double currentHigh, double previousHigh) {
    if(currentHigh > previousHigh)
        return SWING_HH;  // Higher High
    else
        return SWING_LH;  // Lower High
}

//+------------------------------------------------------------------+
//| Classify swing low type                                          |
//+------------------------------------------------------------------+
ENUM_SWING_TYPE CSwingDetection::ClassifySwingLow(double currentLow, double previousLow) {
    if(currentLow > previousLow)
        return SWING_HL;  // Higher Low
    else
        return SWING_LL;  // Lower Low
}

//+------------------------------------------------------------------+
//| Get last swing high                                              |
//+------------------------------------------------------------------+
bool CSwingDetection::GetLastSwingHigh(SwingPoint &point) {
    int size = ArraySize(m_swingHighs);
    if(size == 0) return false;
    
    point = m_swingHighs[size - 1];
    return true;
}

//+------------------------------------------------------------------+
//| Get last swing low                                               |
//+------------------------------------------------------------------+
bool CSwingDetection::GetLastSwingLow(SwingPoint &point) {
    int size = ArraySize(m_swingLows);
    if(size == 0) return false;
    
    point = m_swingLows[size - 1];
    return true;
}

//+------------------------------------------------------------------+
//| Get swing high by index                                          |
//+------------------------------------------------------------------+
bool CSwingDetection::GetSwingHigh(int index, SwingPoint &point) {
    if(index < 0 || index >= ArraySize(m_swingHighs)) return false;
    point = m_swingHighs[index];
    return true;
}

//+------------------------------------------------------------------+
//| Get swing low by index                                           |
//+------------------------------------------------------------------+
bool CSwingDetection::GetSwingLow(int index, SwingPoint &point) {
    if(index < 0 || index >= ArraySize(m_swingLows)) return false;
    point = m_swingLows[index];
    return true;
}

//+------------------------------------------------------------------+
//| Check for break of structure - Buy                               |
//+------------------------------------------------------------------+
bool CSwingDetection::IsBreakOfStructureBuy(double currentPrice) {
    SwingPoint lastHigh;
    if(!GetLastSwingHigh(lastHigh)) return false;
    
    // For buy, price should break above last LH (Lower High)
    if(lastHigh.type == SWING_LH && currentPrice > lastHigh.price) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for break of structure - Sell                              |
//+------------------------------------------------------------------+
bool CSwingDetection::IsBreakOfStructureSell(double currentPrice) {
    SwingPoint lastLow;
    if(!GetLastSwingLow(lastLow)) return false;
    
    // For sell, price should break below last HL (Higher Low)
    if(lastLow.type == SWING_HL && currentPrice < lastLow.price) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check retracement to last LL                                     |
//+------------------------------------------------------------------+
bool CSwingDetection::IsRetracementToLastLL(double currentLow) {
    SwingPoint lastLL;
    if(!GetLastSwingLow(lastLL)) return false;
    
    if(lastLL.type != SWING_LL) return false;
    
    double lowestPrice = GetLastLLLowestPrice();
    if(lowestPrice == 0) return false;
    
    // Check if current low touched or came close to the lowest price
    double tolerance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10; // 10 points tolerance
    return (MathAbs(currentLow - lowestPrice) <= tolerance);
}

//+------------------------------------------------------------------+
//| Check retracement to last HH                                     |
//+------------------------------------------------------------------+
bool CSwingDetection::IsRetracementToLastHH(double currentHigh) {
    SwingPoint lastHH;
    if(!GetLastSwingHigh(lastHH)) return false;
    
    if(lastHH.type != SWING_HH) return false;
    
    double highestPrice = GetLastHHHighestPrice();
    if(highestPrice == 0) return false;
    
    // Check if current high touched or came close to the highest price
    double tolerance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10; // 10 points tolerance
    return (MathAbs(currentHigh - highestPrice) <= tolerance);
}

//+------------------------------------------------------------------+
//| Get lowest price in last LL swing                                |
//+------------------------------------------------------------------+
double CSwingDetection::GetLastLLLowestPrice(void) {
    SwingPoint lastLL;
    if(!GetLastSwingLow(lastLL)) return 0;
    
    if(lastLL.type != SWING_LL) return 0;
    
    // Get the lowest price in the range around this swing
    double low[];
    int bars = m_leftBars + m_rightBars + 1;
    if(CopyLow(m_symbol, m_timeframe, lastLL.barIndex - m_leftBars, bars, low) <= 0)
        return lastLL.price;
    
    double lowest = low[0];
    for(int i = 1; i < ArraySize(low); i++) {
        if(low[i] < lowest) lowest = low[i];
    }
    
    return lowest;
}

//+------------------------------------------------------------------+
//| Get highest price in last HH swing                               |
//+------------------------------------------------------------------+
double CSwingDetection::GetLastHHHighestPrice(void) {
    SwingPoint lastHH;
    if(!GetLastSwingHigh(lastHH)) return 0;
    
    if(lastHH.type != SWING_HH) return 0;
    
    // Get the highest price in the range around this swing
    double high[];
    int bars = m_leftBars + m_rightBars + 1;
    if(CopyHigh(m_symbol, m_timeframe, lastHH.barIndex - m_leftBars, bars, high) <= 0)
        return lastHH.price;
    
    double highest = high[0];
    for(int i = 1; i < ArraySize(high); i++) {
        if(high[i] > highest) highest = high[i];
    }
    
    return highest;
}

//+------------------------------------------------------------------+
//| Check if uptrend                                                 |
//+------------------------------------------------------------------+
bool CSwingDetection::IsUptrend(void) {
    int size = MathMin(ArraySize(m_swingHighs), ArraySize(m_swingLows));
    if(size < 2) return false;
    
    int hhCount = 0, hlCount = 0;
    
    // Check last few swings
    for(int i = MathMax(0, size - 3); i < size; i++) {
        if(i < ArraySize(m_swingHighs) && m_swingHighs[i].type == SWING_HH)
            hhCount++;
        if(i < ArraySize(m_swingLows) && m_swingLows[i].type == SWING_HL)
            hlCount++;
    }
    
    return (hhCount >= 2 || hlCount >= 2);
}

//+------------------------------------------------------------------+
//| Check if downtrend                                               |
//+------------------------------------------------------------------+
bool CSwingDetection::IsDowntrend(void) {
    int size = MathMin(ArraySize(m_swingHighs), ArraySize(m_swingLows));
    if(size < 2) return false;
    
    int lhCount = 0, llCount = 0;
    
    // Check last few swings
    for(int i = MathMax(0, size - 3); i < size; i++) {
        if(i < ArraySize(m_swingHighs) && m_swingHighs[i].type == SWING_LH)
            lhCount++;
        if(i < ArraySize(m_swingLows) && m_swingLows[i].type == SWING_LL)
            llCount++;
    }
    
    return (lhCount >= 2 || llCount >= 2);
}

//+------------------------------------------------------------------+
//| Get current structure                                            |
//+------------------------------------------------------------------+
ENUM_SWING_TYPE CSwingDetection::GetCurrentStructure(void) {
    SwingPoint lastHigh, lastLow;
    
    if(!GetLastSwingHigh(lastHigh) || !GetLastSwingLow(lastLow))
        return SWING_NONE;
    
    // Return the most recent swing type
    if(lastHigh.time > lastLow.time)
        return lastHigh.type;
    else
        return lastLow.type;
}
//+------------------------------------------------------------------+
