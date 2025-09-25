//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Risk Management Class                                            |
//+------------------------------------------------------------------+
class CRiskManager {
private:
    double m_maxRiskPercent;
    double m_maxDailyLoss;
    double m_maxDrawdown;
    double m_accountBalance;
    double m_currentDrawdown;
    int m_maxPositions;
    
public:
    CRiskManager(double maxRisk = 2.0, int maxPositions = 1);
    ~CRiskManager();
    
    // Risk calculation methods
    double CalculateLotSize(double stopLossPoints, double riskPercent);
    bool IsTradeAllowed();
    bool IsRiskAcceptable(double potentialLoss);
    void UpdateDrawdown();
    
    // Position management
    bool CanOpenPosition();
    int GetMaxPositions() { return m_maxPositions; }
    void SetMaxPositions(int max) { m_maxPositions = max; }
    
    // Daily limits
    bool IsDailyLimitReached();
    void ResetDailyCounters();
    
    // Utility methods
    double GetAccountRisk();
    double GetCurrentDrawdown() { return m_currentDrawdown; }
    void SetMaxRiskPercent(double risk) { m_maxRiskPercent = risk; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(double maxRisk = 2.0, int maxPositions = 1) {
    m_maxRiskPercent = maxRisk;
    m_maxPositions = maxPositions;
    m_maxDailyLoss = 5.0; // 5% daily loss limit
    m_maxDrawdown = 10.0; // 10% maximum drawdown
    m_accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    m_currentDrawdown = 0.0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager() {
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Calculate optimal lot size based on risk                        |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double stopLossPoints, double riskPercent) {
    if(stopLossPoints <= 0) return 0.0;
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * (riskPercent / 100.0);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(tickValue == 0 || pointValue == 0) return 0.0;
    
    double lotSize = riskAmount / (stopLossPoints * pointValue * (tickValue / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE)));
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    lotSize = MathRound(lotSize / lotStep) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Check if trade is allowed based on risk rules                   |
//+------------------------------------------------------------------+
bool CRiskManager::IsTradeAllowed() {
    UpdateDrawdown();
    
    // Check maximum positions
    if(PositionsTotal() >= m_maxPositions) return false;
    
    // Check drawdown limit
    if(m_currentDrawdown >= m_maxDrawdown) return false;
    
    // Check daily loss limit
    if(IsDailyLimitReached()) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if risk is acceptable for the trade                       |
//+------------------------------------------------------------------+
bool CRiskManager::IsRiskAcceptable(double potentialLoss) {
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskPercent = (potentialLoss / accountBalance) * 100.0;
    
    return riskPercent <= m_maxRiskPercent;
}

//+------------------------------------------------------------------+
//| Update current drawdown                                          |
//+------------------------------------------------------------------+
void CRiskManager::UpdateDrawdown() {
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(currentBalance > 0) {
        m_currentDrawdown = ((currentBalance - equity) / currentBalance) * 100.0;
        m_currentDrawdown = MathMax(m_currentDrawdown, 0.0);
    }
}

//+------------------------------------------------------------------+
//| Check if we can open new position                               |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenPosition() {
    return (PositionsTotal() < m_maxPositions) && IsTradeAllowed();
}

//+------------------------------------------------------------------+
//| Check if daily loss limit is reached                            |
//+------------------------------------------------------------------+
bool CRiskManager::IsDailyLimitReached() {
    // Get today's P&L
    datetime todayStart = TimeCurrent() - (TimeCurrent() % 86400); // Start of today
    double todayPnL = 0.0;
    
    // Calculate P&L from today's closed positions
    for(int i = HistoryDealsTotal() - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0) {
            datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
            if(dealTime >= todayStart) {
                todayPnL += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            } else {
                break; // Deals are sorted by time, so we can break here
            }
        }
    }
    
    // Add current floating P&L
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i)) {
            todayPnL += PositionGetDouble(POSITION_PROFIT);
        }
    }
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double lossPercent = MathAbs(todayPnL / accountBalance) * 100.0;
    
    return (todayPnL < 0 && lossPercent >= m_maxDailyLoss);
}

//+------------------------------------------------------------------+
//| Get current account risk                                         |
//+------------------------------------------------------------------+
double CRiskManager::GetAccountRisk() {
    double totalRisk = 0.0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i)) {
            double positionProfit = PositionGetDouble(POSITION_PROFIT);
            if(positionProfit < 0) {
                totalRisk += MathAbs(positionProfit);
            }
        }
    }
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    return (totalRisk / accountBalance) * 100.0;
}