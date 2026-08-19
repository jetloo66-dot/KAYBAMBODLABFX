//+------------------------------------------------------------------+
//|                                                 RiskManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs_Version1.mqh"

//+------------------------------------------------------------------+
//| Risk Manager Class                                               |
//| Comprehensive risk management including position sizing,         |
//| drawdown control, and exposure management                        |
//+------------------------------------------------------------------+
class CRiskManager {
private:
    // Account information
    double m_accountBalance;
    double m_accountEquity;
    double m_initialBalance;
    
    // Risk settings
    double m_maxRiskPercent;
    double m_maxDailyLossPercent;
    double m_maxDrawdownPercent;
    int m_maxPositions;
    double m_maxLotSize;
    double m_minLotSize;
    
    // Current state
    double m_currentDrawdown;
    double m_dailyPnL;
    double m_peakEquity;
    int m_openPositions;
    datetime m_lastDailyReset;
    
    // Limits and controls
    bool m_riskLimitReached;
    bool m_dailyLimitReached;
    bool m_drawdownLimitReached;
    datetime m_limitReachedTime;
    
    // Position tracking
    PositionData m_positions[];
    int m_positionCount;
    
public:
    // Constructor/Destructor
    CRiskManager();
    ~CRiskManager();
    
    // Initialization
    bool Initialize(double maxRiskPercent = 2.0, double maxDailyLoss = 10.0, double maxDrawdown = 20.0);
    void SetMaxRiskPercent(double percent);
    void SetMaxDailyLoss(double percent);
    void SetMaxDrawdown(double percent);
    void SetMaxPositions(int maxPos) { m_maxPositions = maxPos; }
    
    // Risk calculations
    double CalculateLotSize(string symbol, double stopLossPips, double riskPercent = -1);
    double CalculatePositionSize(string symbol, double entryPrice, double stopLoss);
    double CalculateRiskAmount(double lotSize, string symbol, double stopLossPips);
    double CalculateRiskReward(double entryPrice, double stopLoss, double takeProfit);
    
    // Risk validation
    bool ValidateRisk(double riskAmount);
    bool CanOpenPosition();
    bool CanOpenPosition(string symbol);
    bool IsWithinRiskLimits();
    bool IsWithinDailyLimits();
    bool IsWithinDrawdownLimits();
    
    // Account monitoring
    void UpdateAccountInfo();
    void UpdateDailyPnL();
    void UpdateDrawdown();
    void UpdatePositions();
    void ResetDailyLimits();
    
    // Position management
    bool AddPosition(const PositionData &position);
    bool RemovePosition(ulong ticket);
    PositionData GetPosition(int index);
    int GetOpenPositions() const { return m_openPositions; }
    double GetTotalExposure();
    double GetTotalExposure(string symbol);
    
    // Risk metrics
    double GetCurrentDrawdown() const { return m_currentDrawdown; }
    double GetDailyPnL() const { return m_dailyPnL; }
    double GetAccountBalance() const { return m_accountBalance; }
    double GetAccountEquity() const { return m_accountEquity; }
    double GetMaxRiskPercent() const { return m_maxRiskPercent; }
    double GetAvailableRisk();
    
    // Risk limits
    bool IsRiskLimitReached() const { return m_riskLimitReached; }
    bool IsDailyLimitReached() const { return m_dailyLimitReached; }
    bool IsDrawdownLimitReached() const { return m_drawdownLimitReached; }
    void ResetRiskLimits();
    
    // Risk data
    RiskData GetRiskData();
    
    // Utility
    void PrintRiskStatus();
    void PrintPositions();
    
private:
    double NormalizeLotSize(string symbol, double lotSize);
    bool CheckDailyReset();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager() {
    m_accountBalance = 0.0;
    m_accountEquity = 0.0;
    m_initialBalance = 0.0;
    
    m_maxRiskPercent = 2.0;
    m_maxDailyLossPercent = 10.0;
    m_maxDrawdownPercent = 20.0;
    m_maxPositions = 1;
    m_maxLotSize = 10.0;
    m_minLotSize = 0.01;
    
    m_currentDrawdown = 0.0;
    m_dailyPnL = 0.0;
    m_peakEquity = 0.0;
    m_openPositions = 0;
    m_lastDailyReset = 0;
    
    m_riskLimitReached = false;
    m_dailyLimitReached = false;
    m_drawdownLimitReached = false;
    m_limitReachedTime = 0;
    
    m_positionCount = 0;
    ArrayResize(m_positions, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager() {
    ArrayFree(m_positions);
}

//+------------------------------------------------------------------+
//| Initialize risk manager                                          |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(double maxRiskPercent, double maxDailyLoss, double maxDrawdown) {
    m_maxRiskPercent = maxRiskPercent;
    m_maxDailyLossPercent = maxDailyLoss;
    m_maxDrawdownPercent = maxDrawdown;
    
    UpdateAccountInfo();
    m_initialBalance = m_accountBalance;
    m_peakEquity = m_accountEquity;
    m_lastDailyReset = TimeCurrent();
    
    return true;
}

//+------------------------------------------------------------------+
//| Set maximum risk percent                                         |
//+------------------------------------------------------------------+
void CRiskManager::SetMaxRiskPercent(double percent) {
    if(percent > 0 && percent <= 10.0) {
        m_maxRiskPercent = percent;
    }
}

//+------------------------------------------------------------------+
//| Set maximum daily loss                                           |
//+------------------------------------------------------------------+
void CRiskManager::SetMaxDailyLoss(double percent) {
    if(percent > 0 && percent <= 50.0) {
        m_maxDailyLossPercent = percent;
    }
}

//+------------------------------------------------------------------+
//| Set maximum drawdown                                             |
//+------------------------------------------------------------------+
void CRiskManager::SetMaxDrawdown(double percent) {
    if(percent > 0 && percent <= 50.0) {
        m_maxDrawdownPercent = percent;
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(string symbol, double stopLossPips, double riskPercent) {
    if(riskPercent < 0) {
        riskPercent = m_maxRiskPercent;
    }
    
    double riskAmount = m_accountBalance * (riskPercent / 100.0);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    if(tickValue == 0 || tickSize == 0 || point == 0 || stopLossPips == 0) {
        return m_minLotSize;
    }
    
    // Calculate pip value for 1 lot
    double pipValue = (tickValue / tickSize) * point;
    
    // Calculate lot size
    double lotSize = riskAmount / (stopLossPips * pipValue);
    
    // Normalize and validate
    lotSize = NormalizeLotSize(symbol, lotSize);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate position size based on entry and stop loss             |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePositionSize(string symbol, double entryPrice, double stopLoss) {
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(point == 0) return m_minLotSize;
    
    double stopLossPips = MathAbs(entryPrice - stopLoss) / point;
    
    return CalculateLotSize(symbol, stopLossPips);
}

//+------------------------------------------------------------------+
//| Calculate risk amount for a position                             |
//+------------------------------------------------------------------+
double CRiskManager::CalculateRiskAmount(double lotSize, string symbol, double stopLossPips) {
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    if(tickValue == 0 || tickSize == 0 || point == 0) {
        return 0.0;
    }
    
    double pipValue = (tickValue / tickSize) * point;
    double riskAmount = lotSize * stopLossPips * pipValue;
    
    return riskAmount;
}

//+------------------------------------------------------------------+
//| Calculate risk-reward ratio                                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateRiskReward(double entryPrice, double stopLoss, double takeProfit) {
    double risk = MathAbs(entryPrice - stopLoss);
    double reward = MathAbs(takeProfit - entryPrice);
    
    if(risk == 0) return 0.0;
    
    return reward / risk;
}

//+------------------------------------------------------------------+
//| Validate risk amount                                             |
//+------------------------------------------------------------------+
bool CRiskManager::ValidateRisk(double riskAmount) {
    double maxRiskAmount = m_accountBalance * (m_maxRiskPercent / 100.0);
    return (riskAmount <= maxRiskAmount);
}

//+------------------------------------------------------------------+
//| Check if can open new position                                   |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenPosition() {
    CheckDailyReset();
    UpdateAccountInfo();
    UpdateDailyPnL();
    UpdateDrawdown();
    
    // Check position limit
    if(m_openPositions >= m_maxPositions) {
        return false;
    }
    
    // Check all risk limits
    if(!IsWithinRiskLimits() || !IsWithinDailyLimits() || !IsWithinDrawdownLimits()) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if can open position for specific symbol                   |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenPosition(string symbol) {
    if(!CanOpenPosition()) {
        return false;
    }
    
    // Check if already have position in this symbol
    for(int i = 0; i < m_positionCount; i++) {
        if(m_positions[i].symbol == symbol) {
            return false; // Already have position in this symbol
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if within risk limits                                      |
//+------------------------------------------------------------------+
bool CRiskManager::IsWithinRiskLimits() {
    double totalRisk = GetTotalExposure();
    double maxRisk = m_accountBalance * (m_maxRiskPercent / 100.0) * m_maxPositions;
    
    if(totalRisk > maxRisk) {
        m_riskLimitReached = true;
        m_limitReachedTime = TimeCurrent();
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if within daily limits                                     |
//+------------------------------------------------------------------+
bool CRiskManager::IsWithinDailyLimits() {
    CheckDailyReset();
    
    double dailyLossLimit = m_accountBalance * (m_maxDailyLossPercent / 100.0);
    
    if(m_dailyPnL < -dailyLossLimit) {
        m_dailyLimitReached = true;
        m_limitReachedTime = TimeCurrent();
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if within drawdown limits                                  |
//+------------------------------------------------------------------+
bool CRiskManager::IsWithinDrawdownLimits() {
    if(m_currentDrawdown > m_maxDrawdownPercent) {
        m_drawdownLimitReached = true;
        m_limitReachedTime = TimeCurrent();
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update account information                                       |
//+------------------------------------------------------------------+
void CRiskManager::UpdateAccountInfo() {
    m_accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    m_accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(m_initialBalance == 0) {
        m_initialBalance = m_accountBalance;
    }
}

//+------------------------------------------------------------------+
//| Update daily P&L                                                 |
//+------------------------------------------------------------------+
void CRiskManager::UpdateDailyPnL() {
    CheckDailyReset();
    
    // Calculate daily P&L from positions
    double totalProfit = 0.0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionSelectByTicket(PositionGetTicket(i))) {
            datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
            
            // Check if position was opened today
            if(openTime >= m_lastDailyReset) {
                totalProfit += PositionGetDouble(POSITION_PROFIT);
                totalProfit += PositionGetDouble(POSITION_SWAP);
            }
        }
    }
    
    m_dailyPnL = totalProfit;
}

//+------------------------------------------------------------------+
//| Update drawdown                                                  |
//+------------------------------------------------------------------+
void CRiskManager::UpdateDrawdown() {
    // Update peak equity
    if(m_accountEquity > m_peakEquity) {
        m_peakEquity = m_accountEquity;
    }
    
    // Calculate drawdown
    if(m_peakEquity > 0) {
        m_currentDrawdown = ((m_peakEquity - m_accountEquity) / m_peakEquity) * 100.0;
    }
}

//+------------------------------------------------------------------+
//| Update positions array                                           |
//+------------------------------------------------------------------+
void CRiskManager::UpdatePositions() {
    ArrayResize(m_positions, 0);
    m_positionCount = 0;
    m_openPositions = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && PositionSelectByTicket(ticket)) {
            PositionData pos;
            pos.ticket = ticket;
            pos.symbol = PositionGetString(POSITION_SYMBOL);
            pos.type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            pos.volume = PositionGetDouble(POSITION_VOLUME);
            pos.openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            pos.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            pos.stopLoss = PositionGetDouble(POSITION_SL);
            pos.takeProfit = PositionGetDouble(POSITION_TP);
            pos.profit = PositionGetDouble(POSITION_PROFIT);
            pos.swap = PositionGetDouble(POSITION_SWAP);
            pos.openTime = (datetime)PositionGetInteger(POSITION_TIME);
            pos.magic = (int)PositionGetInteger(POSITION_MAGIC);
            pos.comment = PositionGetString(POSITION_COMMENT);
            
            AddPosition(pos);
        }
    }
}

//+------------------------------------------------------------------+
//| Check and reset daily limits                                     |
//+------------------------------------------------------------------+
bool CRiskManager::CheckDailyReset() {
    datetime currentTime = TimeCurrent();
    MqlDateTime dtCurrent, dtLast;
    
    TimeToStruct(currentTime, dtCurrent);
    TimeToStruct(m_lastDailyReset, dtLast);
    
    // Check if day changed
    if(dtCurrent.day != dtLast.day || dtCurrent.mon != dtLast.mon || dtCurrent.year != dtLast.year) {
        ResetDailyLimits();
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Reset daily limits                                               |
//+------------------------------------------------------------------+
void CRiskManager::ResetDailyLimits() {
    m_dailyPnL = 0.0;
    m_dailyLimitReached = false;
    m_lastDailyReset = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Add position to tracking                                         |
//+------------------------------------------------------------------+
bool CRiskManager::AddPosition(const PositionData &position) {
    int size = ArraySize(m_positions);
    if(ArrayResize(m_positions, size + 1) > 0) {
        m_positions[size] = position;
        m_positionCount++;
        m_openPositions++;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Remove position from tracking                                    |
//+------------------------------------------------------------------+
bool CRiskManager::RemovePosition(ulong ticket) {
    for(int i = 0; i < m_positionCount; i++) {
        if(m_positions[i].ticket == ticket) {
            // Shift remaining positions
            for(int j = i; j < m_positionCount - 1; j++) {
                m_positions[j] = m_positions[j + 1];
            }
            m_positionCount--;
            m_openPositions--;
            ArrayResize(m_positions, m_positionCount);
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get position by index                                            |
//+------------------------------------------------------------------+
PositionData CRiskManager::GetPosition(int index) {
    if(index >= 0 && index < m_positionCount) {
        return m_positions[index];
    }
    PositionData empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get total exposure (position values, not actual risk)            |
//| Note: This calculates total position value (volume * price).     |
//| For actual risk exposure, calculate SL distance * pip value      |
//+------------------------------------------------------------------+
double CRiskManager::GetTotalExposure() {
    double totalExposure = 0.0;
    
    for(int i = 0; i < m_positionCount; i++) {
        double positionValue = m_positions[i].volume * m_positions[i].currentPrice;
        totalExposure += positionValue;
    }
    
    return totalExposure;
}

//+------------------------------------------------------------------+
//| Get total exposure for symbol (position values, not actual risk) |
//| Note: This calculates total position value (volume * price).     |
//| For actual risk exposure, calculate SL distance * pip value      |
//+------------------------------------------------------------------+
double CRiskManager::GetTotalExposure(string symbol) {
    double totalExposure = 0.0;
    
    for(int i = 0; i < m_positionCount; i++) {
        if(m_positions[i].symbol == symbol) {
            double positionValue = m_positions[i].volume * m_positions[i].currentPrice;
            totalExposure += positionValue;
        }
    }
    
    return totalExposure;
}

//+------------------------------------------------------------------+
//| Get available risk                                               |
//+------------------------------------------------------------------+
double CRiskManager::GetAvailableRisk() {
    double maxRisk = m_accountBalance * (m_maxRiskPercent / 100.0);
    double usedRisk = GetTotalExposure();
    return MathMax(0, maxRisk - usedRisk);
}

//+------------------------------------------------------------------+
//| Reset risk limits                                                |
//+------------------------------------------------------------------+
void CRiskManager::ResetRiskLimits() {
    m_riskLimitReached = false;
    m_dailyLimitReached = false;
    m_drawdownLimitReached = false;
    m_limitReachedTime = 0;
}

//+------------------------------------------------------------------+
//| Get risk data structure                                          |
//+------------------------------------------------------------------+
RiskData CRiskManager::GetRiskData() {
    UpdateAccountInfo();
    UpdateDailyPnL();
    UpdateDrawdown();
    
    RiskData data;
    data.accountBalance = m_accountBalance;
    data.accountEquity = m_accountEquity;
    data.currentDrawdown = m_currentDrawdown;
    data.maxDrawdown = m_maxDrawdownPercent;
    data.dailyPnL = m_dailyPnL;
    data.totalRisk = GetTotalExposure();
    data.riskPercent = m_maxRiskPercent;
    data.openPositions = m_openPositions;
    data.riskLimitReached = m_riskLimitReached;
    data.dailyLimitReached = m_dailyLimitReached;
    data.lastRiskUpdate = TimeCurrent();
    
    return data;
}

//+------------------------------------------------------------------+
//| Normalize lot size                                               |
//+------------------------------------------------------------------+
double CRiskManager::NormalizeLotSize(string symbol, double lotSize) {
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    if(minLot == 0) minLot = m_minLotSize;
    if(maxLot == 0) maxLot = m_maxLotSize;
    if(lotStep == 0) lotStep = 0.01;
    
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    lotSize = MathRound(lotSize / lotStep) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Print risk status                                                |
//+------------------------------------------------------------------+
void CRiskManager::PrintRiskStatus() {
    UpdateAccountInfo();
    UpdateDailyPnL();
    UpdateDrawdown();
    
    Print("=== Risk Manager Status ===");
    Print("Account Balance: ", m_accountBalance);
    Print("Account Equity: ", m_accountEquity);
    Print("Current Drawdown: ", m_currentDrawdown, "%");
    Print("Daily P&L: ", m_dailyPnL);
    Print("Open Positions: ", m_openPositions, "/", m_maxPositions);
    Print("Total Exposure: ", GetTotalExposure());
    Print("Available Risk: ", GetAvailableRisk());
    Print("Risk Limit Reached: ", m_riskLimitReached ? "Yes" : "No");
    Print("Daily Limit Reached: ", m_dailyLimitReached ? "Yes" : "No");
    Print("Drawdown Limit Reached: ", m_drawdownLimitReached ? "Yes" : "No");
    Print("===========================");
}

//+------------------------------------------------------------------+
//| Print positions                                                  |
//+------------------------------------------------------------------+
void CRiskManager::PrintPositions() {
    UpdatePositions();
    
    Print("=== Open Positions ===");
    Print("Total: ", m_positionCount);
    
    for(int i = 0; i < m_positionCount; i++) {
        Print("Position #", i + 1, ": ",
              m_positions[i].symbol, " ",
              EnumToString(m_positions[i].type), " ",
              m_positions[i].volume, " lots, ",
              "P&L: ", m_positions[i].profit + m_positions[i].swap);
    }
    
    Print("======================");
}
