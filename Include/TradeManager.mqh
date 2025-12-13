//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Trade Management Class                                           |
//+------------------------------------------------------------------+
class CTradeManager {
private:
    CTrade m_trade;
    ulong m_magicNumber;
    double m_lotSize;
    double m_stopLossPips;
    double m_takeProfitPips;
    bool m_useTrailingStop;
    double m_trailingStopPips;
    double m_trailingStepPips;
    int m_maxPositions;
    
    // Risk management
    double m_maxRiskPercent;
    double m_accountBalance;
    
    // Position tracking
    struct PositionInfo {
        ulong ticket;
        double entryPrice;
        double stopLoss;
        double takeProfit;
        double lotSize;
        ENUM_POSITION_TYPE type;
        datetime openTime;
        string symbol;
        string comment;
        double initialSL;
        bool trailingActive;
    };
    
    PositionInfo m_positions[];
    
public:
    CTradeManager(ulong magicNumber = 123456);
    ~CTradeManager();
    
    // Configuration methods
    void SetLotSize(double size) { m_lotSize = size; }
    void SetStopLoss(double pips) { m_stopLossPips = pips; }
    void SetTakeProfit(double pips) { m_takeProfitPips = pips; }
    void SetTrailingStop(bool use, double pips = 10.0, double step = 5.0);
    void SetMaxPositions(int max) { m_maxPositions = max; }
    void SetMaxRisk(double percent) { m_maxRiskPercent = percent; }
    
    // Trading methods
    bool OpenBuyPosition(string symbol, double lotSize = 0, double stopLoss = 0, double takeProfit = 0, string comment = "");
    bool OpenSellPosition(string symbol, double lotSize = 0, double stopLoss = 0, double takeProfit = 0, string comment = "");
    bool ClosePosition(ulong ticket);
    bool CloseAllPositions(string symbol = "");
    bool ModifyPosition(ulong ticket, double stopLoss, double takeProfit);
    
    // Position management
    void ManagePositions();
    void ManageTrailingStops();
    void UpdatePositionInfo();
    
    // Query methods
    int GetOpenPositions(string symbol = "");
    int GetBuyPositions(string symbol = "");
    int GetSellPositions(string symbol = "");
    double GetTotalProfit(string symbol = "");
    double GetTotalLots(string symbol = "");
    bool HasOpenPosition(string symbol = "");
    
    // Risk management methods
    double CalculateLotSize(double stopLossPoints, double riskPercent = 0);
    bool IsRiskAcceptable(double potentialLoss);
    bool CanOpenNewPosition(string symbol = "");
    
    // Position information methods
    bool GetPositionInfo(ulong ticket, PositionInfo &info);
    string GetPositionSummary(ulong ticket);
    string GetAllPositionsSummary();
    
    // Utility methods
    double GetSymbolPoint(string symbol);
    double GetSymbolDigits(string symbol);
    double PipsToPrice(string symbol, double pips);
    double PriceToPips(string symbol, double price);
    
    // Error handling
    string GetLastError();
    void LogTradeAction(string action, string symbol, double price, double lots, string result);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager(ulong magicNumber = 123456) {
    m_magicNumber = magicNumber;
    m_trade.SetExpertMagicNumber(m_magicNumber);
    m_trade.SetMarginMode();
    
    // Set default values
    m_lotSize = 0.01;
    m_stopLossPips = 15.0;
    m_takeProfitPips = 50.0;
    m_useTrailingStop = true;
    m_trailingStopPips = 10.0;
    m_trailingStepPips = 5.0;
    m_maxPositions = 1;
    m_maxRiskPercent = 2.0;
    
    m_accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Initialize positions array
    ArrayResize(m_positions, 0);
    
    Print("TradeManager initialized with Magic Number: ", m_magicNumber);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager(void) {
    ArrayFree(m_positions);
}

//+------------------------------------------------------------------+
//| Set trailing stop configuration                                  |
//+------------------------------------------------------------------+
void CTradeManager::SetTrailingStop(bool use, double pips = 10.0, double step = 5.0) {
    m_useTrailingStop = use;
    m_trailingStopPips = pips;
    m_trailingStepPips = step;
}

//+------------------------------------------------------------------+
//| Open buy position                                                |
//+------------------------------------------------------------------+
bool CTradeManager::OpenBuyPosition(string symbol, double lotSize = 0, double stopLoss = 0, double takeProfit = 0, string comment = "") {
    if(!CanOpenNewPosition(symbol)) {
        Print("Cannot open new position for ", symbol);
        return false;
    }
    
    // Use default values if not specified
    if(lotSize == 0) lotSize = m_lotSize;
    if(comment == "") comment = "KAYB Buy";
    
    double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double sl = 0, tp = 0;
    
    // Calculate stop loss and take profit
    if(stopLoss == 0 && m_stopLossPips > 0) {
        sl = price - PipsToPrice(symbol, m_stopLossPips);
    } else if(stopLoss > 0) {
        sl = stopLoss;
    }
    
    if(takeProfit == 0 && m_takeProfitPips > 0) {
        tp = price + PipsToPrice(symbol, m_takeProfitPips);
    } else if(takeProfit > 0) {
        tp = takeProfit;
    }
    
    // Calculate appropriate lot size based on risk
    if(sl > 0) {
        double riskLotSize = CalculateLotSize(MathAbs(price - sl) / GetSymbolPoint(symbol), m_maxRiskPercent);
        if(riskLotSize > 0 && riskLotSize < lotSize) {
            lotSize = riskLotSize;
        }
    }
    
    m_trade.SetTypeFillingBySymbol(symbol);
    bool result = m_trade.Buy(lotSize, symbol, price, sl, tp, comment);
    
    if(result) {
        LogTradeAction("BUY", symbol, price, lotSize, "SUCCESS");
        UpdatePositionInfo();
        return true;
    } else {
        LogTradeAction("BUY", symbol, price, lotSize, "FAILED: " + GetLastError());
        return false;
    }
}

//+------------------------------------------------------------------+
//| Open sell position                                               |
//+------------------------------------------------------------------+
bool CTradeManager::OpenSellPosition(string symbol, double lotSize = 0, double stopLoss = 0, double takeProfit = 0, string comment = "") {
    if(!CanOpenNewPosition(symbol)) {
        Print("Cannot open new position for ", symbol);
        return false;
    }
    
    // Use default values if not specified
    if(lotSize == 0) lotSize = m_lotSize;
    if(comment == "") comment = "KAYB Sell";
    
    double price = SymbolInfoDouble(symbol, SYMBOL_BID);
    double sl = 0, tp = 0;
    
    // Calculate stop loss and take profit
    if(stopLoss == 0 && m_stopLossPips > 0) {
        sl = price + PipsToPrice(symbol, m_stopLossPips);
    } else if(stopLoss > 0) {
        sl = stopLoss;
    }
    
    if(takeProfit == 0 && m_takeProfitPips > 0) {
        tp = price - PipsToPrice(symbol, m_takeProfitPips);
    } else if(takeProfit > 0) {
        tp = takeProfit;
    }
    
    // Calculate appropriate lot size based on risk
    if(sl > 0) {
        double riskLotSize = CalculateLotSize(MathAbs(sl - price) / GetSymbolPoint(symbol), m_maxRiskPercent);
        if(riskLotSize > 0 && riskLotSize < lotSize) {
            lotSize = riskLotSize;
        }
    }
    
    m_trade.SetTypeFillingBySymbol(symbol);
    bool result = m_trade.Sell(lotSize, symbol, price, sl, tp, comment);
    
    if(result) {
        LogTradeAction("SELL", symbol, price, lotSize, "SUCCESS");
        UpdatePositionInfo();
        return true;
    } else {
        LogTradeAction("SELL", symbol, price, lotSize, "FAILED: " + GetLastError());
        return false;
    }
}

//+------------------------------------------------------------------+
//| Close position by ticket                                         |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket) {
    if(PositionSelectByTicket(ticket)) {
        string symbol = PositionGetString(POSITION_SYMBOL);
        double lots = PositionGetDouble(POSITION_VOLUME);
        double price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                      SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
        
        bool result = m_trade.PositionClose(ticket);
        
        if(result) {
            LogTradeAction("CLOSE", symbol, price, lots, "SUCCESS");
            UpdatePositionInfo();
            return true;
        } else {
            LogTradeAction("CLOSE", symbol, price, lots, "FAILED: " + GetLastError());
            return false;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
bool CTradeManager::CloseAllPositions(string symbol = "") {
    bool allClosed = true;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                string posSymbol = PositionGetString(POSITION_SYMBOL);
                if(symbol == "" || symbol == posSymbol) {
                    ulong ticket = PositionGetTicket(i);
                    if(!ClosePosition(ticket)) {
                        allClosed = false;
                    }
                }
            }
        }
    }
    
    return allClosed;
}

//+------------------------------------------------------------------+
//| Modify position                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(ulong ticket, double stopLoss, double takeProfit) {
    if(PositionSelectByTicket(ticket)) {
        bool result = m_trade.PositionModify(ticket, stopLoss, takeProfit);
        
        if(result) {
            string symbol = PositionGetString(POSITION_SYMBOL);
            LogTradeAction("MODIFY", symbol, 0, 0, "SUCCESS - SL:" + DoubleToString(stopLoss, _Digits) + " TP:" + DoubleToString(takeProfit, _Digits));
            UpdatePositionInfo();
            return true;
        } else {
            LogTradeAction("MODIFY", "", 0, 0, "FAILED: " + GetLastError());
            return false;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Manage all open positions                                        |
//+------------------------------------------------------------------+
void CTradeManager::ManagePositions() {
    UpdatePositionInfo();
    
    if(m_useTrailingStop) {
        ManageTrailingStops();
    }
}

//+------------------------------------------------------------------+
//| Manage trailing stops                                            |
//+------------------------------------------------------------------+
void CTradeManager::ManageTrailingStops() {
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                ulong ticket = PositionGetTicket(i);
                string symbol = PositionGetString(POSITION_SYMBOL);
                ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double currentSL = PositionGetDouble(POSITION_SL);
                double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double currentTP = PositionGetDouble(POSITION_TP);
                
                double trailDistance = PipsToPrice(symbol, m_trailingStopPips);
                double trailStep = PipsToPrice(symbol, m_trailingStepPips);
                
                if(type == POSITION_TYPE_BUY) {
                    double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
                    double newSL = currentPrice - trailDistance;
                    
                    // Only move SL if it's better than current and meets step requirement
                    if(newSL > currentSL + trailStep || (currentSL == 0 && newSL > entryPrice)) {
                        ModifyPosition(ticket, newSL, currentTP);
                    }
                    
                } else if(type == POSITION_TYPE_SELL) {
                    double currentPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
                    double newSL = currentPrice + trailDistance;
                    
                    // Only move SL if it's better than current and meets step requirement
                    if(newSL < currentSL - trailStep || (currentSL == 0 && newSL < entryPrice)) {
                        ModifyPosition(ticket, newSL, currentTP);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update position information                                      |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePositionInfo() {
    ArrayResize(m_positions, 0);
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                int size = ArraySize(m_positions);
                ArrayResize(m_positions, size + 1);
                
                m_positions[size].ticket = PositionGetTicket(i);
                m_positions[size].entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                m_positions[size].stopLoss = PositionGetDouble(POSITION_SL);
                m_positions[size].takeProfit = PositionGetDouble(POSITION_TP);
                m_positions[size].lotSize = PositionGetDouble(POSITION_VOLUME);
                m_positions[size].type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                m_positions[size].openTime = PositionGetInteger(POSITION_TIME);
                m_positions[size].symbol = PositionGetString(POSITION_SYMBOL);
                m_positions[size].comment = PositionGetString(POSITION_COMMENT);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Get number of open positions                                     |
//+------------------------------------------------------------------+
int CTradeManager::GetOpenPositions(string symbol = "") {
    int count = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                if(symbol == "" || symbol == PositionGetString(POSITION_SYMBOL)) {
                    count++;
                }
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get number of buy positions                                      |
//+------------------------------------------------------------------+
int CTradeManager::GetBuyPositions(string symbol = "") {
    int count = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber && 
               PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
                if(symbol == "" || symbol == PositionGetString(POSITION_SYMBOL)) {
                    count++;
                }
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get number of sell positions                                     |
//+------------------------------------------------------------------+
int CTradeManager::GetSellPositions(string symbol = "") {
    int count = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber && 
               PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
                if(symbol == "" || symbol == PositionGetString(POSITION_SYMBOL)) {
                    count++;
                }
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Check if can open new position                                   |
//+------------------------------------------------------------------+
bool CTradeManager::CanOpenNewPosition(string symbol = "") {
    int currentPositions = GetOpenPositions(symbol);
    
    if(currentPositions >= m_maxPositions) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CTradeManager::CalculateLotSize(double stopLossPoints, double riskPercent = 0) {
    if(riskPercent == 0) riskPercent = m_maxRiskPercent;
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * riskPercent / 100.0;
    
    string symbol = _Symbol;
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    double moneyPerPoint = tickValue * point / tickSize;
    double lotSize = riskAmount / (stopLossPoints * moneyPerPoint);
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    lotSize = MathRound(lotSize / lotStep) * lotStep;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Get symbol point value                                           |
//+------------------------------------------------------------------+
double CTradeManager::GetSymbolPoint(string symbol) {
    return SymbolInfoDouble(symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Get symbol digits                                                |
//+------------------------------------------------------------------+
double CTradeManager::GetSymbolDigits(string symbol) {
    return (double)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
}

//+------------------------------------------------------------------+
//| Convert pips to price                                            |
//+------------------------------------------------------------------+
double CTradeManager::PipsToPrice(string symbol, double pips) {
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    // Adjust for 5-digit brokers
    if(digits == 5 || digits == 3) {
        return pips * point * 10;
    } else {
        return pips * point;
    }
}

//+------------------------------------------------------------------+
//| Convert price to pips                                            |
//+------------------------------------------------------------------+
double CTradeManager::PriceToPips(string symbol, double price) {
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    // Adjust for 5-digit brokers
    if(digits == 5 || digits == 3) {
        return price / (point * 10);
    } else {
        return price / point;
    }
}

//+------------------------------------------------------------------+
//| Get last error message                                           |
//+------------------------------------------------------------------+
string CTradeManager::GetLastError() {
    uint errorCode = m_trade.ResultRetcode();
    return "Error " + IntegerToString(errorCode) + ": " + m_trade.ResultRetcodeDescription();
}

//+------------------------------------------------------------------+
//| Log trade action                                                 |
//+------------------------------------------------------------------+
void CTradeManager::LogTradeAction(string action, string symbol, double price, double lots, string result) {
    string logMessage = StringFormat("[TRADE] %s %s: %.5f lots at %.5f - %s", 
                                   action, symbol, lots, price, result);
    Print(logMessage);
}

//+------------------------------------------------------------------+
//| Get position summary                                             |
//+------------------------------------------------------------------+
string CTradeManager::GetAllPositionsSummary() {
    string summary = "=== Open Positions Summary ===\n";
    int totalPositions = GetOpenPositions();
    
    if(totalPositions == 0) {
        summary += "No open positions.\n";
        return summary;
    }
    
    double totalProfit = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i)) {
            if(PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
                ulong ticket = PositionGetTicket(i);
                string symbol = PositionGetString(POSITION_SYMBOL);
                ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double lots = PositionGetDouble(POSITION_VOLUME);
                double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                double profit = PositionGetDouble(POSITION_PROFIT);
                
                summary += StringFormat("%s %s %.2f lots @ %.5f P&L: %.2f\n",
                                      (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                                      symbol, lots, entryPrice, profit);
                totalProfit += profit;
            }
        }
    }
    
    summary += StringFormat("Total Positions: %d | Total P&L: %.2f", totalPositions, totalProfit);
    return summary;
}