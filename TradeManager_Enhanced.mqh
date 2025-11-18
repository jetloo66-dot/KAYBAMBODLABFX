//+------------------------------------------------------------------+
//|                                        TradeManager_Enhanced.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include <Trade\Trade.mqh>
#include "LogManager_Version1.mqh"

//+------------------------------------------------------------------+
//| Trade Management Structure                                       |
//+------------------------------------------------------------------+
struct TradeInfo {
    ulong ticket;
    string symbol;
    ENUM_ORDER_TYPE type;
    double volume;
    double openPrice;
    double stopLoss;
    double takeProfit;
    double currentPrice;
    double profit;
    datetime openTime;
    bool trailingEnabled;
    double trailingStop;
    double trailingStep;
    double initialStop;
    string comment;
};

//+------------------------------------------------------------------+
//| Enhanced Trade Manager Class                                    |
//+------------------------------------------------------------------+
class CTradeManagerEnhanced {
private:
    CLogManager* m_logger;
    CTrade m_trade;
    
    // Risk Management
    double m_maxRiskPercent;
    double m_maxDailyRisk;
    bool m_useFixedLotSize;
    double m_fixedLotSize;
    
    // Position Limits
    int m_maxTradesPerPair;
    int m_maxTotalTrades;
    
    // Trailing Stop Settings
    bool m_trailingEnabled;
    double m_trailingStopPips;
    double m_trailingStepPips;
    
    // Trade tracking
    TradeInfo m_activeTrades[];
    int m_tradeCount;
    
    // Daily statistics
    double m_dailyProfit;
    double m_dailyLoss;
    datetime m_lastResetDate;
    
public:
    CTradeManagerEnhanced(CLogManager* logger, int maxTradesPerPair = 2);
    ~CTradeManagerEnhanced();
    
    // Initialization
    bool Initialize(int magic);
    void SetRiskParameters(double maxRiskPercent, double maxDailyRisk, bool useFixedLot, double fixedLot);
    void SetTrailingParameters(bool enabled, double stopPips, double stepPips);
    
    // Position Management
    bool CanOpenNewPosition(ENUM_ORDER_TYPE orderType);
    double CalculateLotSize(double entryPrice, double stopLoss, ENUM_ORDER_TYPE orderType);
    bool OpenPosition(ENUM_ORDER_TYPE orderType, double lotSize, double entryPrice, double stopLoss, double takeProfit, string comment = "");
    bool ClosePosition(ulong ticket, string reason = "Manual Close");
    bool CloseAllPositions(string reason = "Close All");
    
    // Position Monitoring
    void ManageExistingPositions();
    void UpdateTrailingStops();
    void CheckForPartialClosures();
    void MonitorRiskLimits();
    
    // Information Methods
    int GetActiveTradeCount();
    int GetActiveTradeCount(string symbol);
    int GetActiveTradeCount(ENUM_ORDER_TYPE orderType);
    double GetTotalExposure();
    double GetTotalProfit();
    double GetDailyProfit();
    double GetDailyRisk();
    
    // Risk Management
    bool IsRiskLimitReached();
    bool IsDailyLossLimitReached();
    double GetAccountRisk();
    double GetPositionRisk(double entryPrice, double stopLoss, double lotSize);
    
    // Utility Methods
    void ResetDailyStatistics();
    void LogTradeStatistics();
    string GetTradeStatusReport();
    
private:
    void UpdateTradeArray();
    void UpdateDailyStatistics();
    bool IsNewTradingDay();
    double NormalizeLotSize(double lotSize);
    double CalculateStopLossPoints(double entryPrice, double stopLoss, ENUM_ORDER_TYPE orderType);
    double CalculateRiskAmount(double lotSize, double stopLossPoints);
    bool ValidateTradeParameters(ENUM_ORDER_TYPE orderType, double lotSize, double entryPrice, double stopLoss, double takeProfit);
    void AddTradeToArray(ulong ticket, ENUM_ORDER_TYPE orderType, double lotSize, double entryPrice, double stopLoss, double takeProfit, string comment);
    void RemoveTradeFromArray(ulong ticket);
    int FindTradeIndex(ulong ticket);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManagerEnhanced::CTradeManagerEnhanced(CLogManager* logger, int maxTradesPerPair = 2) {
    m_logger = logger;
    m_maxTradesPerPair = maxTradesPerPair;
    m_maxTotalTrades = 10;
    
    // Default risk parameters
    m_maxRiskPercent = 2.0;
    m_maxDailyRisk = 5.0;
    m_useFixedLotSize = false;
    m_fixedLotSize = 0.01;
    
    // Default trailing parameters
    m_trailingEnabled = true;
    m_trailingStopPips = 15.0;
    m_trailingStepPips = 5.0;
    
    // Initialize arrays
    ArrayResize(m_activeTrades, m_maxTotalTrades);
    m_tradeCount = 0;
    
    // Daily statistics
    m_dailyProfit = 0.0;
    m_dailyLoss = 0.0;
    m_lastResetDate = TimeCurrent();
    
    if(m_logger) m_logger.LogInfo("Trade manager initialized", "TRADEMGR");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManagerEnhanced::~CTradeManagerEnhanced() {
    if(m_logger) m_logger.LogInfo("Trade manager destroyed", "TRADEMGR");
}

//+------------------------------------------------------------------+
//| Initialize trade manager                                         |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::Initialize(int magic) {
    m_trade.SetExpertMagicNumber(magic);
    m_trade.SetMarginMode();
    m_trade.SetTypeFillingBySymbol(_Symbol);
    m_trade.SetDeviationInPoints(10);
    
    // Load existing positions
    UpdateTradeArray();
    
    if(m_logger) m_logger.LogInfo(StringFormat("Trade manager initialized with magic %d", magic), "TRADEMGR");
    return true;
}

//+------------------------------------------------------------------+
//| Set risk management parameters                                  |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::SetRiskParameters(double maxRiskPercent, double maxDailyRisk, bool useFixedLot, double fixedLot) {
    m_maxRiskPercent = maxRiskPercent;
    m_maxDailyRisk = maxDailyRisk;
    m_useFixedLotSize = useFixedLot;
    m_fixedLotSize = fixedLot;
    
    if(m_logger) {
        m_logger.LogInfo(StringFormat("Risk parameters set: MaxRisk=%.1f%%, DailyRisk=%.1f%%, FixedLot=%s (%.2f)", 
                        maxRiskPercent, maxDailyRisk, useFixedLot ? "Yes" : "No", fixedLot), "TRADEMGR");
    }
}

//+------------------------------------------------------------------+
//| Set trailing stop parameters                                    |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::SetTrailingParameters(bool enabled, double stopPips, double stepPips) {
    m_trailingEnabled = enabled;
    m_trailingStopPips = stopPips;
    m_trailingStepPips = stepPips;
    
    if(m_logger) {
        m_logger.LogInfo(StringFormat("Trailing parameters set: Enabled=%s, Stop=%.1f pips, Step=%.1f pips", 
                        enabled ? "Yes" : "No", stopPips, stepPips), "TRADEMGR");
    }
}

//+------------------------------------------------------------------+
//| Check if new position can be opened                            |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::CanOpenNewPosition(ENUM_ORDER_TYPE orderType) {
    // Check daily risk limit
    if(IsDailyLossLimitReached()) {
        if(m_logger) m_logger.LogWarning("Daily loss limit reached", "TRADEMGR");
        return false;
    }
    
    // Check total position limit
    if(GetActiveTradeCount() >= m_maxTotalTrades) {
        if(m_logger) m_logger.LogWarning("Maximum total trades reached", "TRADEMGR");
        return false;
    }
    
    // Check pair-specific limit
    if(GetActiveTradeCount(_Symbol) >= m_maxTradesPerPair) {
        if(m_logger) m_logger.LogWarning(StringFormat("Maximum trades per pair reached for %s", _Symbol), "TRADEMGR");
        return false;
    }
    
    // Check account risk
    if(GetAccountRisk() >= m_maxRiskPercent) {
        if(m_logger) m_logger.LogWarning("Account risk limit reached", "TRADEMGR");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk                          |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::CalculateLotSize(double entryPrice, double stopLoss, ENUM_ORDER_TYPE orderType) {
    if(m_useFixedLotSize) {
        return NormalizeLotSize(m_fixedLotSize);
    }
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * (m_maxRiskPercent / 100.0);
    
    double stopLossPoints = CalculateStopLossPoints(entryPrice, stopLoss, orderType);
    if(stopLossPoints <= 0) return NormalizeLotSize(m_fixedLotSize);
    
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * (SymbolInfoDouble(_Symbol, SYMBOL_POINT) / tickSize);
    
    double lotSize = riskAmount / (stopLossPoints * pointValue);
    
    return NormalizeLotSize(lotSize);
}

//+------------------------------------------------------------------+
//| Open new position                                               |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::OpenPosition(ENUM_ORDER_TYPE orderType, double lotSize, double entryPrice, double stopLoss, double takeProfit, string comment = "") {
    if(!CanOpenNewPosition(orderType)) {
        return false;
    }
    
    if(!ValidateTradeParameters(orderType, lotSize, entryPrice, stopLoss, takeProfit)) {
        if(m_logger) m_logger.LogError("Invalid trade parameters", "TRADEMGR");
        return false;
    }
    
    lotSize = NormalizeLotSize(lotSize);
    
    bool result = false;
    ulong ticket = 0;
    
    if(orderType == ORDER_TYPE_BUY) {
        result = m_trade.Buy(lotSize, _Symbol, entryPrice, stopLoss, takeProfit, comment);
        ticket = m_trade.ResultOrder();
    }
    else if(orderType == ORDER_TYPE_SELL) {
        result = m_trade.Sell(lotSize, _Symbol, entryPrice, stopLoss, takeProfit, comment);
        ticket = m_trade.ResultOrder();
    }
    
    if(result && ticket > 0) {
        AddTradeToArray(ticket, orderType, lotSize, entryPrice, stopLoss, takeProfit, comment);
        
        if(m_logger) {
            m_logger.LogInfo(StringFormat("Position opened: Ticket=%d, Type=%s, Lot=%.2f, Price=%.5f, SL=%.5f, TP=%.5f", 
                            ticket, orderType == ORDER_TYPE_BUY ? "BUY" : "SELL", 
                            lotSize, entryPrice, stopLoss, takeProfit), "TRADEMGR");
        }
        
        return true;
    }
    else {
        if(m_logger) m_logger.LogError(StringFormat("Failed to open position: %d", GetLastError()), "TRADEMGR");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Close specific position                                          |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::ClosePosition(ulong ticket, string reason = "Manual Close") {
    if(!PositionSelectByTicket(ticket)) {
        if(m_logger) m_logger.LogError(StringFormat("Position not found: %d", ticket), "TRADEMGR");
        return false;
    }
    
    double volume = PositionGetDouble(POSITION_VOLUME);
    double currentPrice = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                         SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    bool result = m_trade.PositionClose(ticket);
    
    if(result) {
        RemoveTradeFromArray(ticket);
        
        if(m_logger) {
            m_logger.LogInfo(StringFormat("Position closed: Ticket=%d, Reason=%s, Price=%.5f", 
                            ticket, reason, currentPrice), "TRADEMGR");
        }
        
        return true;
    }
    else {
        if(m_logger) m_logger.LogError(StringFormat("Failed to close position %d: %d", ticket, GetLastError()), "TRADEMGR");
        return false;
    }
}

//+------------------------------------------------------------------+
//| Close all positions                                             |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::CloseAllPositions(string reason = "Close All") {
    bool allClosed = true;
    
    for(int i = m_tradeCount - 1; i >= 0; i--) {
        if(!ClosePosition(m_activeTrades[i].ticket, reason)) {
            allClosed = false;
        }
    }
    
    if(m_logger) {
        m_logger.LogInfo(StringFormat("Close all positions: Success=%s, Reason=%s", 
                        allClosed ? "Yes" : "Partial", reason), "TRADEMGR");
    }
    
    return allClosed;
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::ManageExistingPositions() {
    // Check if it's a new trading day
    if(IsNewTradingDay()) {
        ResetDailyStatistics();
    }
    
    // Update trade array with current positions
    UpdateTradeArray();
    
    // Update daily statistics
    UpdateDailyStatistics();
    
    // Update trailing stops
    if(m_trailingEnabled) {
        UpdateTrailingStops();
    }
    
    // Check for partial closures
    CheckForPartialClosures();
    
    // Monitor risk limits
    MonitorRiskLimits();
}

//+------------------------------------------------------------------+
//| Update trailing stops for all positions                         |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::UpdateTrailingStops() {
    for(int i = 0; i < m_tradeCount; i++) {
        ulong ticket = m_activeTrades[i].ticket;
        
        if(!PositionSelectByTicket(ticket)) continue;
        
        double currentPrice = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        double currentSL = PositionGetDouble(POSITION_SL);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        
        double trailingPoints = m_trailingStopPips * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        double stepPoints = m_trailingStepPips * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        
        double newSL = currentSL;
        bool updateSL = false;
        
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            // For buy positions, trail stop loss upward
            double proposedSL = currentPrice - trailingPoints;
            
            if(proposedSL > currentSL + stepPoints || currentSL == 0) {
                newSL = proposedSL;
                updateSL = true;
            }
        }
        else {
            // For sell positions, trail stop loss downward
            double proposedSL = currentPrice + trailingPoints;
            
            if(proposedSL < currentSL - stepPoints || currentSL == 0) {
                newSL = proposedSL;
                updateSL = true;
            }
        }
        
        if(updateSL) {
            double currentTP = PositionGetDouble(POSITION_TP);
            
            if(m_trade.PositionModify(ticket, newSL, currentTP)) {
                m_activeTrades[i].stopLoss = newSL;
                
                if(m_logger) {
                    m_logger.LogInfo(StringFormat("Trailing stop updated: Ticket=%d, New SL=%.5f", 
                                    ticket, newSL), "TRADEMGR");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Get active trade count                                          |
//+------------------------------------------------------------------+
int CTradeManagerEnhanced::GetActiveTradeCount() {
    return m_tradeCount;
}

//+------------------------------------------------------------------+
//| Get active trade count for specific symbol                     |
//+------------------------------------------------------------------+
int CTradeManagerEnhanced::GetActiveTradeCount(string symbol) {
    int count = 0;
    
    for(int i = 0; i < m_tradeCount; i++) {
        if(m_activeTrades[i].symbol == symbol) {
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get active trade count for specific order type                 |
//+------------------------------------------------------------------+
int CTradeManagerEnhanced::GetActiveTradeCount(ENUM_ORDER_TYPE orderType) {
    int count = 0;
    
    for(int i = 0; i < m_tradeCount; i++) {
        if(m_activeTrades[i].type == orderType) {
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get total exposure                                              |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::GetTotalExposure() {
    double totalExposure = 0.0;
    
    for(int i = 0; i < m_tradeCount; i++) {
        totalExposure += m_activeTrades[i].volume * m_activeTrades[i].currentPrice;
    }
    
    return totalExposure;
}

//+------------------------------------------------------------------+
//| Get total profit                                                |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::GetTotalProfit() {
    double totalProfit = 0.0;
    
    for(int i = 0; i < m_tradeCount; i++) {
        totalProfit += m_activeTrades[i].profit;
    }
    
    return totalProfit;
}

//+------------------------------------------------------------------+
//| Get daily profit                                                |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::GetDailyProfit() {
    return m_dailyProfit - m_dailyLoss;
}

//+------------------------------------------------------------------+
//| Check if daily loss limit is reached                           |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::IsDailyLossLimitReached() {
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double dailyLossLimit = accountBalance * (m_maxDailyRisk / 100.0);
    
    return (m_dailyLoss >= dailyLossLimit);
}

//+------------------------------------------------------------------+
//| Get current account risk percentage                             |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::GetAccountRisk() {
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if(accountBalance <= 0) return 0.0;
    
    double totalRisk = 0.0;
    
    for(int i = 0; i < m_tradeCount; i++) {
        double riskAmount = GetPositionRisk(m_activeTrades[i].openPrice, 
                                           m_activeTrades[i].stopLoss, 
                                           m_activeTrades[i].volume);
        totalRisk += riskAmount;
    }
    
    return (totalRisk / accountBalance) * 100.0;
}

//+------------------------------------------------------------------+
//| Calculate position risk                                          |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::GetPositionRisk(double entryPrice, double stopLoss, double lotSize) {
    if(stopLoss <= 0 || entryPrice <= 0 || lotSize <= 0) return 0.0;
    
    double stopLossPoints = MathAbs(entryPrice - stopLoss);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * (SymbolInfoDouble(_Symbol, SYMBOL_POINT) / tickSize);
    
    return stopLossPoints * pointValue * lotSize;
}

//+------------------------------------------------------------------+
//| Update trade array with current positions                       |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::UpdateTradeArray() {
    m_tradeCount = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i) == 0) continue;
        
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        string symbol = PositionGetString(POSITION_SYMBOL);
        
        // Only track positions for current symbol managed by this EA
        if(symbol != _Symbol) continue;
        
        if(m_tradeCount < ArraySize(m_activeTrades)) {
            m_activeTrades[m_tradeCount].ticket = ticket;
            m_activeTrades[m_tradeCount].symbol = symbol;
            m_activeTrades[m_tradeCount].type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
            m_activeTrades[m_tradeCount].volume = PositionGetDouble(POSITION_VOLUME);
            m_activeTrades[m_tradeCount].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            m_activeTrades[m_tradeCount].stopLoss = PositionGetDouble(POSITION_SL);
            m_activeTrades[m_tradeCount].takeProfit = PositionGetDouble(POSITION_TP);
            m_activeTrades[m_tradeCount].currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            m_activeTrades[m_tradeCount].profit = PositionGetDouble(POSITION_PROFIT);
            m_activeTrades[m_tradeCount].openTime = (datetime)PositionGetInteger(POSITION_TIME);
            m_activeTrades[m_tradeCount].comment = PositionGetString(POSITION_COMMENT);
            
            m_tradeCount++;
        }
    }
}

//+------------------------------------------------------------------+
//| Normalize lot size according to symbol specifications          |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::NormalizeLotSize(double lotSize) {
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    lotSize = MathRound(lotSize / lotStep) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate stop loss in points                                   |
//+------------------------------------------------------------------+
double CTradeManagerEnhanced::CalculateStopLossPoints(double entryPrice, double stopLoss, ENUM_ORDER_TYPE orderType) {
    if(orderType == ORDER_TYPE_BUY) {
        return (entryPrice - stopLoss) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    }
    else {
        return (stopLoss - entryPrice) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    }
}

//+------------------------------------------------------------------+
//| Validate trade parameters                                        |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::ValidateTradeParameters(ENUM_ORDER_TYPE orderType, double lotSize, double entryPrice, double stopLoss, double takeProfit) {
    // Check lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    if(lotSize < minLot || lotSize > maxLot) {
        return false;
    }
    
    // Check stop loss
    if(stopLoss <= 0) return false;
    
    double minStopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if(orderType == ORDER_TYPE_BUY) {
        if(entryPrice - stopLoss < minStopLevel) return false;
        if(takeProfit > 0 && takeProfit - entryPrice < minStopLevel) return false;
    }
    else {
        if(stopLoss - entryPrice < minStopLevel) return false;
        if(takeProfit > 0 && entryPrice - takeProfit < minStopLevel) return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Add trade to tracking array                                     |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::AddTradeToArray(ulong ticket, ENUM_ORDER_TYPE orderType, double lotSize, double entryPrice, double stopLoss, double takeProfit, string comment) {
    if(m_tradeCount < ArraySize(m_activeTrades)) {
        m_activeTrades[m_tradeCount].ticket = ticket;
        m_activeTrades[m_tradeCount].symbol = _Symbol;
        m_activeTrades[m_tradeCount].type = orderType;
        m_activeTrades[m_tradeCount].volume = lotSize;
        m_activeTrades[m_tradeCount].openPrice = entryPrice;
        m_activeTrades[m_tradeCount].stopLoss = stopLoss;
        m_activeTrades[m_tradeCount].takeProfit = takeProfit;
        m_activeTrades[m_tradeCount].currentPrice = entryPrice;
        m_activeTrades[m_tradeCount].profit = 0.0;
        m_activeTrades[m_tradeCount].openTime = TimeCurrent();
        m_activeTrades[m_tradeCount].comment = comment;
        m_activeTrades[m_tradeCount].trailingEnabled = m_trailingEnabled;
        m_activeTrades[m_tradeCount].trailingStop = m_trailingStopPips;
        m_activeTrades[m_tradeCount].trailingStep = m_trailingStepPips;
        m_activeTrades[m_tradeCount].initialStop = stopLoss;
        
        m_tradeCount++;
    }
}

//+------------------------------------------------------------------+
//| Remove trade from tracking array                                |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::RemoveTradeFromArray(ulong ticket) {
    int index = FindTradeIndex(ticket);
    if(index >= 0) {
        // Shift array elements
        for(int i = index; i < m_tradeCount - 1; i++) {
            m_activeTrades[i] = m_activeTrades[i + 1];
        }
        m_tradeCount--;
    }
}

//+------------------------------------------------------------------+
//| Find trade index in array                                       |
//+------------------------------------------------------------------+
int CTradeManagerEnhanced::FindTradeIndex(ulong ticket) {
    for(int i = 0; i < m_tradeCount; i++) {
        if(m_activeTrades[i].ticket == ticket) {
            return i;
        }
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Check if it's a new trading day                                 |
//+------------------------------------------------------------------+
bool CTradeManagerEnhanced::IsNewTradingDay() {
    MqlDateTime currentTime, lastResetTime;
    TimeToStruct(TimeCurrent(), currentTime);
    TimeToStruct(m_lastResetDate, lastResetTime);
    
    return (currentTime.day != lastResetTime.day || 
            currentTime.mon != lastResetTime.mon || 
            currentTime.year != lastResetTime.year);
}

//+------------------------------------------------------------------+
//| Reset daily statistics                                           |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::ResetDailyStatistics() {
    m_dailyProfit = 0.0;
    m_dailyLoss = 0.0;
    m_lastResetDate = TimeCurrent();
    
    if(m_logger) m_logger.LogInfo("Daily statistics reset", "TRADEMGR");
}

//+------------------------------------------------------------------+
//| Update daily statistics                                          |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::UpdateDailyStatistics() {
    // This would need to track closed positions during the day
    // For now, we'll use a simplified approach
    double currentProfit = GetTotalProfit();
    
    if(currentProfit > 0) {
        m_dailyProfit += currentProfit;
    } else {
        m_dailyLoss += MathAbs(currentProfit);
    }
}

//+------------------------------------------------------------------+
//| Check for partial closures based on profit targets             |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::CheckForPartialClosures() {
    // Implementation for partial closure logic
    // This is a placeholder for advanced position management
}

//+------------------------------------------------------------------+
//| Monitor risk limits                                             |
//+------------------------------------------------------------------+
void CTradeManagerEnhanced::MonitorRiskLimits() {
    if(IsDailyLossLimitReached()) {
        if(m_logger) m_logger.LogWarning("Daily loss limit reached - closing all positions", "TRADEMGR");
        CloseAllPositions("Daily Loss Limit");
    }
    
    if(GetAccountRisk() >= m_maxRiskPercent * 1.2) { // 20% buffer
        if(m_logger) m_logger.LogWarning("Account risk limit exceeded", "TRADEMGR");
    }
}

//+------------------------------------------------------------------+
//| Get trade status report                                         |
//+------------------------------------------------------------------+
string CTradeManagerEnhanced::GetTradeStatusReport() {
    string report = StringFormat("=== Trade Manager Status ===\n");
    report += StringFormat("Active Trades: %d/%d\n", m_tradeCount, m_maxTotalTrades);
    report += StringFormat("Total Exposure: %.2f\n", GetTotalExposure());
    report += StringFormat("Total Profit: %.2f\n", GetTotalProfit());
    report += StringFormat("Account Risk: %.2f%%\n", GetAccountRisk());
    report += StringFormat("Daily P&L: %.2f\n", GetDailyProfit());
    
    return report;
}

//+------------------------------------------------------------------+