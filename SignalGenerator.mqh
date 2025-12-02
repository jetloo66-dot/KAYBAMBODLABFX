//+------------------------------------------------------------------+
//|                                            SignalGenerator.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "SwingDetection.mqh"

//+------------------------------------------------------------------+
//| Signal Type Enumeration                                          |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_STATE {
    STATE_NONE = 0,
    STATE_OVERBOUGHT_H1,
    STATE_OVERSOLD_H1,
    STATE_OVERBOUGHT_M5,
    STATE_OVERSOLD_M5,
    STATE_BOS_BUY,       // Break of Structure Buy
    STATE_BOS_SELL,      // Break of Structure Sell
    STATE_RETRACEMENT_BUY,
    STATE_RETRACEMENT_SELL,
    STATE_SIGNAL_BUY,
    STATE_SIGNAL_SELL
};

//+------------------------------------------------------------------+
//| Signal Information Structure                                     |
//+------------------------------------------------------------------+
struct SignalData {
    ENUM_SIGNAL_STATE state;
    datetime timestamp;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    double lowestCandle;
    double highestCandle;
    bool isValid;
    string comment;
};

//+------------------------------------------------------------------+
//| Signal Generator Class                                           |
//+------------------------------------------------------------------+
class CSignalGenerator {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_htfTimeframe;  // Higher timeframe (H1)
    ENUM_TIMEFRAMES m_ltfTimeframe;  // Lower timeframe (M5)
    
    // Indicator parameters
    int m_stochKPeriod;
    int m_stochDPeriod;
    int m_stochSlowing;
    double m_stochOversold;
    double m_stochOverbought;
    
    int m_bbPeriod;
    double m_bbDeviation;
    
    double m_slPips;
    double m_tpPips;
    
    // Indicator handles
    int m_htfStochHandle;
    int m_ltfStochHandle;
    int m_htfBBHandle;
    int m_ltfBBHandle;
    
    // Swing detectors
    CSwingDetection* m_htfSwingDetector;
    CSwingDetection* m_ltfSwingDetector;
    
    // State tracking
    ENUM_SIGNAL_STATE m_currentState;
    datetime m_lastSignalTime;
    datetime m_lastUpdateTime;
    
    // Private methods
    bool IsOverboughtHTF();
    bool IsOversoldHTF();
    bool IsOverboughtLTF();
    bool IsOversoldLTF();
    bool IsPriceTouchingUpperBB(ENUM_TIMEFRAMES tf);
    bool IsPriceTouchingLowerBB(ENUM_TIMEFRAMES tf);
    double GetStochMain(int handle, int shift = 0);
    double GetBBUpper(int handle, int shift = 0);
    double GetBBLower(int handle, int shift = 0);
    double GetBBMiddle(int handle, int shift = 0);
    
public:
    CSignalGenerator(string symbol, 
                     ENUM_TIMEFRAMES htf = PERIOD_H1, 
                     ENUM_TIMEFRAMES ltf = PERIOD_M5);
    ~CSignalGenerator();
    
    bool Initialize(int stochK = 5, int stochD = 3, int stochSlowing = 3,
                   double stochOversold = 20, double stochOverbought = 80,
                   int bbPeriod = 20, double bbDeviation = 2.0,
                   double slPips = 10, double tpPips = 30,
                   int htfSwingLeft = 5, int htfSwingRight = 5,
                   int ltfSwingLeft = 3, int ltfSwingRight = 3,
                   int maxSwings = 10);
    
    void Update();
    bool GenerateSignal(SignalData &signal);
    
    // Getters
    CSwingDetection* GetHTFSwingDetector() { return m_htfSwingDetector; }
    CSwingDetection* GetLTFSwingDetector() { return m_ltfSwingDetector; }
    ENUM_SIGNAL_STATE GetCurrentState() { return m_currentState; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSignalGenerator::CSignalGenerator(string symbol, ENUM_TIMEFRAMES htf, ENUM_TIMEFRAMES ltf) {
    m_symbol = symbol;
    m_htfTimeframe = htf;
    m_ltfTimeframe = ltf;
    
    m_htfStochHandle = INVALID_HANDLE;
    m_ltfStochHandle = INVALID_HANDLE;
    m_htfBBHandle = INVALID_HANDLE;
    m_ltfBBHandle = INVALID_HANDLE;
    
    m_htfSwingDetector = NULL;
    m_ltfSwingDetector = NULL;
    
    m_currentState = STATE_NONE;
    m_lastSignalTime = 0;
    m_lastUpdateTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSignalGenerator::~CSignalGenerator(void) {
    if(m_htfStochHandle != INVALID_HANDLE) IndicatorRelease(m_htfStochHandle);
    if(m_ltfStochHandle != INVALID_HANDLE) IndicatorRelease(m_ltfStochHandle);
    if(m_htfBBHandle != INVALID_HANDLE) IndicatorRelease(m_htfBBHandle);
    if(m_ltfBBHandle != INVALID_HANDLE) IndicatorRelease(m_ltfBBHandle);
    
    if(m_htfSwingDetector != NULL) delete m_htfSwingDetector;
    if(m_ltfSwingDetector != NULL) delete m_ltfSwingDetector;
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CSignalGenerator::Initialize(int stochK, int stochD, int stochSlowing,
                                  double stochOversold, double stochOverbought,
                                  int bbPeriod, double bbDeviation,
                                  double slPips, double tpPips,
                                  int htfSwingLeft, int htfSwingRight,
                                  int ltfSwingLeft, int ltfSwingRight,
                                  int maxSwings) {
    
    m_stochKPeriod = stochK;
    m_stochDPeriod = stochD;
    m_stochSlowing = stochSlowing;
    m_stochOversold = stochOversold;
    m_stochOverbought = stochOverbought;
    m_bbPeriod = bbPeriod;
    m_bbDeviation = bbDeviation;
    m_slPips = slPips;
    m_tpPips = tpPips;
    
    // Initialize indicators
    m_htfStochHandle = iStochastic(m_symbol, m_htfTimeframe, m_stochKPeriod, m_stochDPeriod, 
                                   m_stochSlowing, MODE_SMA, STO_LOWHIGH);
    m_ltfStochHandle = iStochastic(m_symbol, m_ltfTimeframe, m_stochKPeriod, m_stochDPeriod, 
                                   m_stochSlowing, MODE_SMA, STO_LOWHIGH);
    m_htfBBHandle = iBands(m_symbol, m_htfTimeframe, m_bbPeriod, 0, m_bbDeviation, PRICE_CLOSE);
    m_ltfBBHandle = iBands(m_symbol, m_ltfTimeframe, m_bbPeriod, 0, m_bbDeviation, PRICE_CLOSE);
    
    if(m_htfStochHandle == INVALID_HANDLE || m_ltfStochHandle == INVALID_HANDLE ||
       m_htfBBHandle == INVALID_HANDLE || m_ltfBBHandle == INVALID_HANDLE) {
        Print("Error creating indicators for ", m_symbol);
        return false;
    }
    
    // Initialize swing detectors with configurable parameters
    m_htfSwingDetector = new CSwingDetection(m_symbol, m_htfTimeframe, htfSwingLeft, htfSwingRight, maxSwings);
    m_ltfSwingDetector = new CSwingDetection(m_symbol, m_ltfTimeframe, ltfSwingLeft, ltfSwingRight, maxSwings);
    
    if(!m_htfSwingDetector.Initialize() || !m_ltfSwingDetector.Initialize()) {
        Print("Error initializing swing detectors for ", m_symbol);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update signal generator                                          |
//+------------------------------------------------------------------+
void CSignalGenerator::Update(void) {
    m_htfSwingDetector.Update();
    m_ltfSwingDetector.Update();
    m_lastUpdateTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Generate trading signal                                          |
//+------------------------------------------------------------------+
bool CSignalGenerator::GenerateSignal(SignalData &signal) {
    signal.isValid = false;
    signal.state = STATE_NONE;
    signal.timestamp = TimeCurrent();
    signal.comment = "";
    
    // Get current price
    MqlTick tick;
    if(!SymbolInfoTick(m_symbol, tick)) return false;
    
    double currentPrice = tick.last;
    double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    
    // Check for buy signal
    if(IsOversoldHTF() && IsOversoldLTF()) {
        signal.comment += "HTF+LTF Oversold|";
        
        // Check for break of structure
        if(m_ltfSwingDetector.IsBreakOfStructureBuy(currentPrice)) {
            signal.comment += "BOS Buy|";
            
            // Get current low
            double low[];
            if(CopyLow(m_symbol, m_ltfTimeframe, 0, 5, low) > 0) {
                ArraySetAsSeries(low, true);
                
                // Check for retracement
                if(m_ltfSwingDetector.IsRetracementToLastLL(low[0])) {
                    signal.comment += "Retracement to LL|";
                    signal.state = STATE_SIGNAL_BUY;
                    signal.isValid = true;
                    
                    // Calculate entry, SL, TP
                    signal.entryPrice = tick.ask;
                    signal.lowestCandle = m_ltfSwingDetector.GetLastLLLowestPrice();
                    signal.stopLoss = signal.lowestCandle - (m_slPips * point);
                    
                    // TP is fixed pips above entry (HTF BB reference removed to avoid logic errors)
                    signal.takeProfit = signal.entryPrice + (m_tpPips * point);
                    
                    m_lastSignalTime = TimeCurrent();
                    return true;
                }
            }
        }
    }
    
    // Check for sell signal
    if(IsOverboughtHTF() && IsOverboughtLTF()) {
        signal.comment += "HTF+LTF Overbought|";
        
        // Check for break of structure
        if(m_ltfSwingDetector.IsBreakOfStructureSell(currentPrice)) {
            signal.comment += "BOS Sell|";
            
            // Get current high
            double high[];
            if(CopyHigh(m_symbol, m_ltfTimeframe, 0, 5, high) > 0) {
                ArraySetAsSeries(high, true);
                
                // Check for retracement
                if(m_ltfSwingDetector.IsRetracementToLastHH(high[0])) {
                    signal.comment += "Retracement to HH|";
                    signal.state = STATE_SIGNAL_SELL;
                    signal.isValid = true;
                    
                    // Calculate entry, SL, TP
                    signal.entryPrice = tick.bid;
                    signal.highestCandle = m_ltfSwingDetector.GetLastHHHighestPrice();
                    signal.stopLoss = signal.highestCandle + (m_slPips * point);
                    
                    // TP is fixed pips below entry (HTF BB reference removed to avoid logic errors)
                    signal.takeProfit = signal.entryPrice - (m_tpPips * point);
                    
                    m_lastSignalTime = TimeCurrent();
                    return true;
                }
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if HTF is overbought                                       |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsOverboughtHTF(void) {
    double stochValue = GetStochMain(m_htfStochHandle, 0);
    bool touchingBB = IsPriceTouchingUpperBB(m_htfTimeframe);
    
    return (stochValue > m_stochOverbought && touchingBB);
}

//+------------------------------------------------------------------+
//| Check if HTF is oversold                                         |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsOversoldHTF(void) {
    double stochValue = GetStochMain(m_htfStochHandle, 0);
    bool touchingBB = IsPriceTouchingLowerBB(m_htfTimeframe);
    
    return (stochValue < m_stochOversold && touchingBB);
}

//+------------------------------------------------------------------+
//| Check if LTF is overbought                                       |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsOverboughtLTF(void) {
    double stochValue = GetStochMain(m_ltfStochHandle, 0);
    bool touchingBB = IsPriceTouchingUpperBB(m_ltfTimeframe);
    
    return (stochValue > m_stochOverbought && touchingBB);
}

//+------------------------------------------------------------------+
//| Check if LTF is oversold                                         |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsOversoldLTF(void) {
    double stochValue = GetStochMain(m_ltfStochHandle, 0);
    bool touchingBB = IsPriceTouchingLowerBB(m_ltfTimeframe);
    
    return (stochValue < m_stochOversold && touchingBB);
}

//+------------------------------------------------------------------+
//| Check if price is touching upper Bollinger Band                  |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsPriceTouchingUpperBB(ENUM_TIMEFRAMES tf) {
    int handle = (tf == m_htfTimeframe) ? m_htfBBHandle : m_ltfBBHandle;
    
    double bbUpper = GetBBUpper(handle, 0);
    if(bbUpper == 0) return false;
    
    double high[];
    if(CopyHigh(m_symbol, tf, 0, 3, high) <= 0) return false;
    ArraySetAsSeries(high, true);
    
    double tolerance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10;
    
    for(int i = 0; i < 3; i++) {
        if(MathAbs(high[i] - bbUpper) <= tolerance || high[i] > bbUpper)
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is touching lower Bollinger Band                  |
//+------------------------------------------------------------------+
bool CSignalGenerator::IsPriceTouchingLowerBB(ENUM_TIMEFRAMES tf) {
    int handle = (tf == m_htfTimeframe) ? m_htfBBHandle : m_ltfBBHandle;
    
    double bbLower = GetBBLower(handle, 0);
    if(bbLower == 0) return false;
    
    double low[];
    if(CopyLow(m_symbol, tf, 0, 3, low) <= 0) return false;
    ArraySetAsSeries(low, true);
    
    double tolerance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10;
    
    for(int i = 0; i < 3; i++) {
        if(MathAbs(low[i] - bbLower) <= tolerance || low[i] < bbLower)
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get Stochastic main line value                                   |
//+------------------------------------------------------------------+
double CSignalGenerator::GetStochMain(int handle, int shift = 0) {
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(handle, MAIN_LINE, shift, 1, buffer) <= 0)
        return -1;
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get Bollinger Band upper value                                   |
//+------------------------------------------------------------------+
double CSignalGenerator::GetBBUpper(int handle, int shift = 0) {
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(handle, UPPER_BAND, shift, 1, buffer) <= 0)
        return 0;
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get Bollinger Band lower value                                   |
//+------------------------------------------------------------------+
double CSignalGenerator::GetBBLower(int handle, int shift = 0) {
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(handle, LOWER_BAND, shift, 1, buffer) <= 0)
        return 0;
    
    return buffer[0];
}

//+------------------------------------------------------------------+
//| Get Bollinger Band middle value                                  |
//+------------------------------------------------------------------+
double CSignalGenerator::GetBBMiddle(int handle, int shift = 0) {
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if(CopyBuffer(handle, BASE_LINE, shift, 1, buffer) <= 0)
        return 0;
    
    return buffer[0];
}
//+------------------------------------------------------------------+
