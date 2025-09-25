//+------------------------------------------------------------------+
//|                                             THEKAYBAMBODLABFX.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// This is a simplified version of the KAYBAMBODLABFX EA
// For the full featured version, use KAYBAMBODLABFX_MultiStrategy_EA.mq5

#include <Trade\Trade.mqh>

//--- Input Parameters
input double LotSize = 0.01;                  // Lot size
input int TakeProfit = 500;                   // Take profit in points  
input int StopLoss = 150;                     // Stop loss in points
input int Magic = 123456;                     // Magic number

//--- Global Variables
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    trade.SetExpertMagicNumber(Magic);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(_Symbol);
    
    Print("THEKAYBAMBODLABFX EA initialized successfully");
    Print("NOTE: This is a basic template. Use KAYBAMBODLABFX_MultiStrategy_EA.mq5 for full features.");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("THEKAYBAMBODLABFX EA stopped");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Basic example - check for simple buy/sell conditions
    if(CheckBuyCondition()) {
        ExecuteBuyOrder();
    }
    
    if(CheckSellCondition()) {
        ExecuteSellOrder();
    }
}

//+------------------------------------------------------------------+
//| Check for buy conditions                                         |
//+------------------------------------------------------------------+
bool CheckBuyCondition() {
    // Simple example: buy if current close > previous close and no positions
    if(PositionsTotal() > 0) return false;
    
    double close[], prevClose[];
    if(CopyClose(_Symbol, _Period, 0, 2, close) <= 0) return false;
    
    ArraySetAsSeries(close, true);
    return (close[0] > close[1]);
}

//+------------------------------------------------------------------+
//| Check for sell conditions                                        |
//+------------------------------------------------------------------+
bool CheckSellCondition() {
    // Simple example: sell if current close < previous close and no positions
    if(PositionsTotal() > 0) return false;
    
    double close[];
    if(CopyClose(_Symbol, _Period, 0, 2, close) <= 0) return false;
    
    ArraySetAsSeries(close, true);
    return (close[0] < close[1]);
}

//+------------------------------------------------------------------+
//| Execute buy order                                                |
//+------------------------------------------------------------------+
void ExecuteBuyOrder() {
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl = price - StopLoss * _Point;
    double tp = price + TakeProfit * _Point;
    
    if(trade.Buy(LotSize, _Symbol, price, sl, tp, "KAYB Basic Buy")) {
        Print("Buy order executed at ", price);
    }
}

//+------------------------------------------------------------------+
//| Execute sell order                                               |
//+------------------------------------------------------------------+
void ExecuteSellOrder() {
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl = price + StopLoss * _Point;
    double tp = price - TakeProfit * _Point;
    
    if(trade.Sell(LotSize, _Symbol, price, sl, tp, "KAYB Basic Sell")) {
        Print("Sell order executed at ", price);
    }
}

//+------------------------------------------------------------------+