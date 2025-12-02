//+------------------------------------------------------------------+
//|                                            SwingDetectionEA.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Production-Ready MT5 Swing Detection Expert Advisor"
#property description "Multi-timeframe swing strategy with H1 analysis and M5 execution"

#include <Trade\Trade.mqh>
#include "SwingDetection.mqh"
#include "SignalGenerator.mqh"
#include "SupportResistance.mqh"
#include "TelegramNotifier.mqh"
#include "ChartVisualization.mqh"
#include "ErrorHandler.mqh"

//+------------------------------------------------------------------+
//| Input Parameters - Grouped for Optimizer                         |
//+------------------------------------------------------------------+

//--- Timeframe Settings
input group "=== Timeframe Settings ==="
input ENUM_TIMEFRAMES InpHTFTimeframe = PERIOD_H1;     // Higher Timeframe (Analysis)
input ENUM_TIMEFRAMES InpLTFTimeframe = PERIOD_M5;     // Lower Timeframe (Execution)

//--- Stochastic Settings
input group "=== Stochastic Oscillator ==="
input int InpStochK = 5;                                // Stochastic K Period
input int InpStochD = 3;                                // Stochastic D Period
input int InpStochSlowing = 3;                          // Stochastic Slowing
input double InpStochOversold = 20.0;                   // Oversold Level
input double InpStochOverbought = 80.0;                 // Overbought Level

//--- Bollinger Bands Settings
input group "=== Bollinger Bands ==="
input int InpBBPeriod = 20;                             // Bollinger Bands Period
input double InpBBDeviation = 2.0;                      // Bollinger Bands Deviation

//--- Swing Detection Settings
input group "=== Swing Detection ==="
input int InpSwingLeftBars = 5;                         // Swing Left Bars
input int InpSwingRightBars = 5;                        // Swing Right Bars
input int InpMaxSwingLevels = 10;                       // Max Swing Levels to Store

//--- Trade Management
input group "=== Trade Management ==="
input double InpLotSize = 0.1;                          // Lot Size
input double InpSLPips = 10.0;                          // Stop Loss (Pips)
input double InpTPPips = 30.0;                          // Take Profit (Pips)
input double InpTrailingStart = 10.0;                   // Trailing Start (Pips)
input double InpTrailingStep = 5.0;                     // Trailing Step (Pips)
input int InpMagicNumber = 123456;                      // Magic Number
input int InpMaxTradesPerSymbol = 3;                    // Max Trades Per Symbol

//--- Risk Management
input group "=== Risk Management ==="
input bool InpUseRiskPercent = false;                   // Use Risk Percent
input double InpRiskPercent = 1.0;                      // Risk Percent per Trade
input double InpMaxDailyLoss = 5.0;                     // Max Daily Loss (%)

//--- Symbol Selection
input group "=== Symbol Settings ==="
input bool InpTradeEURUSD = true;                       // Trade EURUSD
input bool InpTradeGBPUSD = true;                       // Trade GBPUSD
input bool InpTradeUSDJPY = true;                       // Trade USDJPY
input bool InpTradeAUDUSD = true;                       // Trade AUDUSD
input bool InpTradeNZDUSD = true;                       // Trade NZDUSD
input bool InpTradeUSDCAD = true;                       // Trade USDCAD
input bool InpTradeUSDCHF = true;                       // Trade USDCHF
input bool InpTradeXAUUSD = false;                      // Trade XAUUSD (Gold)
input bool InpTradeBTCUSD = false;                      // Trade BTCUSD (Bitcoin)

//--- Scan Settings
input group "=== Scan Settings ==="
input int InpScanIntervalMinutes = 5;                   // Scan Interval (Minutes)

//--- Session Filters
input group "=== Session Filters ==="
input bool InpUseSessionFilter = false;                 // Use Session Filter
input int InpSessionStartHour = 0;                      // Session Start Hour
input int InpSessionEndHour = 23;                       // Session End Hour
input bool InpTradeMon = true;                          // Trade Monday
input bool InpTradeTue = true;                          // Trade Tuesday
input bool InpTradeWed = true;                          // Trade Wednesday
input bool InpTradeThu = true;                          // Trade Thursday
input bool InpTradeFri = true;                          // Trade Friday

//--- News Filter
input group "=== News Filter ==="
input bool InpUseNewsFilter = false;                    // Use News Filter
input int InpNewsFilterMinutes = 60;                    // Minutes Before/After News

//--- Telegram Settings
input group "=== Telegram Notifications ==="
input bool InpEnableTelegram = true;                    // Enable Telegram
input string InpBotToken = "8472308793:AAGirMjp6R5Fjvbm8W5_X7EpL8LDt-LPikw"; // Bot Token
input string InpChatID = "394543952";                   // Chat ID

//--- Visualization
input group "=== Visualization ==="
input bool InpShowSwingPoints = true;                   // Show Swing Points
input bool InpShowSRLevels = true;                      // Show Support/Resistance
input bool InpShowSignals = true;                       // Show Signals
input color InpBuyColor = clrLime;                      // Buy Signal Color
input color InpSellColor = clrRed;                      // Sell Signal Color

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade trade;
CTelegramNotifier* telegram;
CChartVisualization* chart;
CErrorHandler* errorHandler;

// Symbol data structures
struct SymbolData {
    string symbol;
    bool enabled;
    CSignalGenerator* signalGen;
    CSupportResistance* srManager;
    datetime lastScanTime;
    datetime lastTradeTime;
    int openTrades;
};

SymbolData g_symbols[];
datetime g_lastGlobalUpdate = 0;
int g_totalTrades = 0;
double g_dailyPnL = 0;
datetime g_dailyPnLReset = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("Initializing Swing Detection EA...");
    
    // Initialize error handler
    errorHandler = new CErrorHandler("SwingEA_" + Symbol() + "_Log.txt", true);
    errorHandler.LogInfo("OnInit", "Starting Swing Detection EA initialization");
    
    // Check if trading is allowed
    if(!errorHandler.CheckAccountTradeAllowed()) {
        errorHandler.LogError("OnInit", "Trading not allowed on this account");
        Alert("Swing Detection EA: Trading not allowed!");
        return INIT_FAILED;
    }
    
    // Initialize trade object
    trade.SetExpertMagicNumber(InpMagicNumber);
    trade.SetMarginMode();
    trade.SetTypeFillingBySymbol(Symbol());
    trade.SetDeviationInPoints(10);
    
    // Initialize Telegram
    telegram = new CTelegramNotifier(InpBotToken, InpChatID, InpEnableTelegram);
    telegram.SendMessage("🚀 Swing Detection EA Started\nSymbol: " + Symbol() + 
                        "\nTimeframe: " + EnumToString(Period()));
    
    // Initialize chart visualization
    chart = new CChartVisualization(Symbol(), ChartID());
    chart.Initialize();
    chart.SetBuyColor(InpBuyColor);
    chart.SetSellColor(InpSellColor);
    
    // Setup symbols to trade
    if(!SetupSymbols()) {
        errorHandler.LogError("OnInit", "Failed to setup symbols");
        return INIT_FAILED;
    }
    
    errorHandler.LogInfo("OnInit", "Successfully initialized " + 
                        IntegerToString(ArraySize(g_symbols)) + " symbols");
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("Deinitializing Swing Detection EA. Reason: ", reason);
    
    if(errorHandler != NULL) {
        errorHandler.LogInfo("OnDeinit", "Stopping EA. Reason: " + IntegerToString(reason));
    }
    
    // Send final notification
    if(telegram != NULL) {
        telegram.SendMessage("⏹️ Swing Detection EA Stopped\nReason: " + 
                           IntegerToString(reason));
        delete telegram;
        telegram = NULL;
    }
    
    // Cleanup symbol data
    for(int i = 0; i < ArraySize(g_symbols); i++) {
        if(g_symbols[i].signalGen != NULL) {
            delete g_symbols[i].signalGen;
        }
        if(g_symbols[i].srManager != NULL) {
            delete g_symbols[i].srManager;
        }
    }
    ArrayFree(g_symbols);
    
    // Cleanup chart
    if(chart != NULL) {
        delete chart;
        chart = NULL;
    }
    
    // Cleanup error handler
    if(errorHandler != NULL) {
        delete errorHandler;
        errorHandler = NULL;
    }
    
    Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if it's time to scan
    datetime currentTime = TimeCurrent();
    
    if(currentTime - g_lastGlobalUpdate < InpScanIntervalMinutes * 60) {
        return; // Not time yet
    }
    
    g_lastGlobalUpdate = currentTime;
    
    // Update daily P&L
    UpdateDailyPnL();
    
    // Check daily loss limit
    if(InpMaxDailyLoss > 0 && g_dailyPnL < -InpMaxDailyLoss) {
        Comment("Daily loss limit reached: ", DoubleToString(g_dailyPnL, 2), "%");
        return;
    }
    
    // Scan all enabled symbols
    for(int i = 0; i < ArraySize(g_symbols); i++) {
        if(!g_symbols[i].enabled) continue;
        
        ProcessSymbol(g_symbols[i]);
    }
    
    // Manage open positions
    ManagePositions();
    
    // Update visualization for current symbol
    UpdateVisualization();
    
    // Update comment
    UpdateComment();
}

//+------------------------------------------------------------------+
//| Setup trading symbols                                            |
//+------------------------------------------------------------------+
bool SetupSymbols() {
    ArrayResize(g_symbols, 0);
    
    // Add symbols based on inputs
    AddSymbolIfEnabled("EURUSD", InpTradeEURUSD);
    AddSymbolIfEnabled("GBPUSD", InpTradeGBPUSD);
    AddSymbolIfEnabled("USDJPY", InpTradeUSDJPY);
    AddSymbolIfEnabled("AUDUSD", InpTradeAUDUSD);
    AddSymbolIfEnabled("NZDUSD", InpTradeNZDUSD);
    AddSymbolIfEnabled("USDCAD", InpTradeUSDCAD);
    AddSymbolIfEnabled("USDCHF", InpTradeUSDCHF);
    AddSymbolIfEnabled("XAUUSD", InpTradeXAUUSD);
    AddSymbolIfEnabled("BTCUSD", InpTradeBTCUSD);
    
    if(ArraySize(g_symbols) == 0) {
        Print("Error: No symbols enabled for trading");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Add symbol if enabled                                            |
//+------------------------------------------------------------------+
void AddSymbolIfEnabled(string symbol, bool enabled) {
    if(!enabled) return;
    
    // Try to select symbol
    if(!SymbolSelect(symbol, true)) {
        if(errorHandler != NULL) {
            errorHandler.LogWarning("AddSymbol", "Symbol " + symbol + " not available");
        }
        return;
    }
    
    // Check if symbol trading is allowed
    if(errorHandler != NULL && !errorHandler.CheckSymbolTradeAllowed(symbol)) {
        errorHandler.LogWarning("AddSymbol", "Trading not allowed for " + symbol);
        return;
    }
    
    // Check data availability
    if(errorHandler != NULL && !errorHandler.CheckDataGap(symbol, InpHTFTimeframe, 100)) {
        errorHandler.LogWarning("AddSymbol", "Insufficient data for " + symbol);
        return;
    }
    
    int size = ArraySize(g_symbols);
    ArrayResize(g_symbols, size + 1);
    
    g_symbols[size].symbol = symbol;
    g_symbols[size].enabled = true;
    g_symbols[size].lastScanTime = 0;
    g_symbols[size].lastTradeTime = 0;
    g_symbols[size].openTrades = 0;
    
    // Initialize signal generator
    g_symbols[size].signalGen = new CSignalGenerator(symbol, InpHTFTimeframe, InpLTFTimeframe);
    if(!g_symbols[size].signalGen.Initialize(InpStochK, InpStochD, InpStochSlowing,
                                             InpStochOversold, InpStochOverbought,
                                             InpBBPeriod, InpBBDeviation,
                                             InpSLPips, InpTPPips)) {
        if(errorHandler != NULL) {
            errorHandler.LogError("AddSymbol", "Failed to initialize signal generator for " + symbol);
        }
        g_symbols[size].enabled = false;
        return;
    }
    
    // Initialize support/resistance manager
    g_symbols[size].srManager = new CSupportResistance(symbol, InpHTFTimeframe, InpMaxSwingLevels);
    CSwingDetection* htfSwing = g_symbols[size].signalGen.GetHTFSwingDetector();
    if(htfSwing != NULL) {
        g_symbols[size].srManager.Initialize(htfSwing);
    }
    
    Print("Successfully added symbol: ", symbol);
}

//+------------------------------------------------------------------+
//| Process individual symbol                                        |
//+------------------------------------------------------------------+
void ProcessSymbol(SymbolData &symbolData) {
    // Check session filters
    if(!IsWithinTradingSession()) {
        return;
    }
    
    // Check news filter
    if(InpUseNewsFilter && IsNewsTime()) {
        return;
    }
    
    // Update signal generator
    symbolData.signalGen.Update();
    symbolData.srManager.Update();
    
    // Count open trades for this symbol
    symbolData.openTrades = CountOpenTrades(symbolData.symbol);
    
    // Check max trades limit
    if(symbolData.openTrades >= InpMaxTradesPerSymbol) {
        return;
    }
    
    // Generate signal
    SignalData signal;
    if(symbolData.signalGen.GenerateSignal(signal)) {
        if(signal.isValid) {
            // Send notification
            if(telegram != NULL) {
                string signalType = (signal.state == STATE_SIGNAL_BUY) ? "BUY" : "SELL";
                telegram.SendSignalDetected(symbolData.symbol, signalType, 
                                          signal.entryPrice, signal.comment);
            }
            
            // Execute trade
            if(errorHandler != NULL) {
                errorHandler.LogInfo("ProcessSymbol", "Valid signal detected for " + symbolData.symbol);
            }
            ExecuteTrade(symbolData, signal);
        }
    }
    
    symbolData.lastScanTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Handle trade events                                              |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
    // Log trade events
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
        if(PositionSelectByTicket(trans.position)) {
            string symbol = PositionGetString(POSITION_SYMBOL);
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            if(profit > 0 && telegram != NULL) {
                telegram.SendTakeProfitHit(symbol, trans.position, profit);
            }
            else if(profit < 0 && telegram != NULL) {
                telegram.SendStopLossHit(symbol, trans.position, MathAbs(profit));
            }
            
            if(errorHandler != NULL) {
                errorHandler.LogTrade("CLOSE", symbol, 
                                    PositionGetDouble(POSITION_PRICE_CURRENT),
                                    PositionGetDouble(POSITION_SL),
                                    PositionGetDouble(POSITION_TP));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Execute trade based on signal                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(SymbolData &symbolData, SignalData &signal) {
    // Validate parameters
    if(!ValidateTradeParameters(symbolData.symbol, signal)) {
        if(errorHandler != NULL) {
            errorHandler.LogWarning("ExecuteTrade", "Trade validation failed for " + symbolData.symbol);
        }
        return;
    }
    
    // Calculate lot size
    double lotSize = InpLotSize;
    if(InpUseRiskPercent) {
        lotSize = CalculateLotSize(symbolData.symbol, signal.entryPrice, signal.stopLoss, InpRiskPercent);
    }
    
    // Normalize lot size
    double minLot = SymbolInfoDouble(symbolData.symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbolData.symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbolData.symbol, SYMBOL_VOLUME_STEP);
    lotSize = MathMax(minLot, MathMin(maxLot, MathRound(lotSize / lotStep) * lotStep));
    
    bool success = false;
    ulong ticket = 0;
    
    if(signal.state == STATE_SIGNAL_BUY) {
        trade.SetSymbol(symbolData.symbol);
        success = trade.Buy(lotSize, symbolData.symbol, signal.entryPrice, 
                          signal.stopLoss, signal.takeProfit, 
                          "SwingEA Buy: " + signal.comment);
        ticket = trade.ResultOrder();
        
        // Visualize
        if(success && symbolData.symbol == Symbol() && InpShowSignals) {
            chart.DrawBuySignal(TimeCurrent(), signal.entryPrice, signal.comment);
            chart.DrawTradeBox(TimeCurrent(), signal.entryPrice, signal.stopLoss, signal.takeProfit, true);
        }
    }
    else if(signal.state == STATE_SIGNAL_SELL) {
        trade.SetSymbol(symbolData.symbol);
        success = trade.Sell(lotSize, symbolData.symbol, signal.entryPrice, 
                           signal.stopLoss, signal.takeProfit, 
                           "SwingEA Sell: " + signal.comment);
        ticket = trade.ResultOrder();
        
        // Visualize
        if(success && symbolData.symbol == Symbol() && InpShowSignals) {
            chart.DrawSellSignal(TimeCurrent(), signal.entryPrice, signal.comment);
            chart.DrawTradeBox(TimeCurrent(), signal.entryPrice, signal.stopLoss, signal.takeProfit, false);
        }
    }
    
    // Send notification
    if(success && telegram != NULL) {
        string orderType = (signal.state == STATE_SIGNAL_BUY) ? "BUY" : "SELL";
        telegram.SendTradeExecuted(symbolData.symbol, orderType, signal.entryPrice,
                                  signal.stopLoss, signal.takeProfit, lotSize, ticket);
    }
    
    if(success) {
        symbolData.lastTradeTime = TimeCurrent();
        g_totalTrades++;
        
        if(errorHandler != NULL) {
            errorHandler.LogTrade(
                (signal.state == STATE_SIGNAL_BUY) ? "BUY" : "SELL",
                symbolData.symbol, signal.entryPrice, signal.stopLoss, signal.takeProfit
            );
        }
    } else {
        int errorCode = GetLastError();
        string errorDesc = trade.ResultRetcodeDescription();
        
        if(errorHandler != NULL) {
            errorHandler.LogError("ExecuteTrade", 
                                "Trade execution failed for " + symbolData.symbol + ": " + errorDesc,
                                errorCode);
        }
        
        if(telegram != NULL) {
            telegram.SendError("Trade execution failed for " + symbolData.symbol + 
                             ": " + errorDesc);
        }
    }
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManagePositions() {
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0) continue;
        
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        
        string symbol = PositionGetString(POSITION_SYMBOL);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double profit = 0;
        
        // Apply trailing stop
        if(type == POSITION_TYPE_BUY) {
            profit = (currentPrice - openPrice) / point;
            if(profit >= InpTrailingStart * 10) {
                double newSL = currentPrice - (InpTrailingStep * 10 * point);
                if(newSL > sl + (point * 10)) {
                    trade.PositionModify(ticket, newSL, tp);
                    if(telegram != NULL) {
                        telegram.SendTrailingStopTriggered(symbol, ticket, newSL);
                    }
                }
            }
        }
        else if(type == POSITION_TYPE_SELL) {
            profit = (openPrice - currentPrice) / point;
            if(profit >= InpTrailingStart * 10) {
                double newSL = currentPrice + (InpTrailingStep * 10 * point);
                if(newSL < sl - (point * 10) || sl == 0) {
                    trade.PositionModify(ticket, newSL, tp);
                    if(telegram != NULL) {
                        telegram.SendTrailingStopTriggered(symbol, ticket, newSL);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Validate trade parameters                                        |
//+------------------------------------------------------------------+
bool ValidateTradeParameters(string symbol, SignalData &signal) {
    if(signal.entryPrice <= 0 || signal.stopLoss <= 0 || signal.takeProfit <= 0) {
        return false;
    }
    
    // Verify minimum distance
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int stopsLevel = (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minDistance = stopsLevel * point;
    
    if(signal.state == STATE_SIGNAL_BUY) {
        if(signal.entryPrice - signal.stopLoss < minDistance) return false;
        if(signal.takeProfit - signal.entryPrice < minDistance) return false;
    } else {
        if(signal.stopLoss - signal.entryPrice < minDistance) return false;
        if(signal.entryPrice - signal.takeProfit < minDistance) return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol, double entry, double sl, double riskPercent) {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = balance * riskPercent / 100.0;
    
    double slDistance = MathAbs(entry - sl);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    
    double lotSize = (riskAmount * tickSize) / (slDistance * tickValue);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Count open trades for symbol                                     |
//+------------------------------------------------------------------+
int CountOpenTrades(string symbol) {
    int count = 0;
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i) <= 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        if(PositionGetString(POSITION_SYMBOL) == symbol) count++;
    }
    return count;
}

//+------------------------------------------------------------------+
//| Check if within trading session                                  |
//+------------------------------------------------------------------+
bool IsWithinTradingSession() {
    if(!InpUseSessionFilter) return true;
    
    MqlDateTime dt;
    TimeCurrent(dt);
    
    // Check day of week
    bool validDay = false;
    switch(dt.day_of_week) {
        case 1: validDay = InpTradeMon; break;
        case 2: validDay = InpTradeTue; break;
        case 3: validDay = InpTradeWed; break;
        case 4: validDay = InpTradeThu; break;
        case 5: validDay = InpTradeFri; break;
        default: validDay = false;
    }
    
    if(!validDay) return false;
    
    // Check hour
    if(dt.hour < InpSessionStartHour || dt.hour >= InpSessionEndHour) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if it's news time                                          |
//+------------------------------------------------------------------+
bool IsNewsTime() {
    // Placeholder - would need external news calendar integration
    return false;
}

//+------------------------------------------------------------------+
//| Update daily P&L                                                 |
//+------------------------------------------------------------------+
void UpdateDailyPnL() {
    MqlDateTime dt;
    TimeCurrent(dt);
    datetime today = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
    
    if(g_dailyPnLReset != today) {
        g_dailyPnL = 0;
        g_dailyPnLReset = today;
    }
    
    // Calculate current day profit
    double dailyProfit = 0;
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i) <= 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber) continue;
        dailyProfit += PositionGetDouble(POSITION_PROFIT);
    }
    
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    g_dailyPnL = (dailyProfit / balance) * 100.0;
}

//+------------------------------------------------------------------+
//| Update visualization                                             |
//+------------------------------------------------------------------+
void UpdateVisualization() {
    if(chart == NULL) return;
    
    // Find current symbol data
    for(int i = 0; i < ArraySize(g_symbols); i++) {
        if(g_symbols[i].symbol == Symbol()) {
            if(InpShowSwingPoints) {
                CSwingDetection* htfSwing = g_symbols[i].signalGen.GetHTFSwingDetector();
                CSwingDetection* ltfSwing = g_symbols[i].signalGen.GetLTFSwingDetector();
                if(htfSwing != NULL) chart.DrawSwingPoints(htfSwing);
                if(ltfSwing != NULL) chart.DrawSwingPoints(ltfSwing);
            }
            
            if(InpShowSRLevels) {
                chart.DrawSupportResistance(g_symbols[i].srManager);
            }
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Update chart comment                                             |
//+------------------------------------------------------------------+
void UpdateComment() {
    string comment = "=== Swing Detection EA ===\n";
    comment += "Total Trades: " + IntegerToString(g_totalTrades) + "\n";
    comment += "Daily P&L: " + DoubleToString(g_dailyPnL, 2) + "%\n";
    comment += "Active Symbols: " + IntegerToString(ArraySize(g_symbols)) + "\n";
    comment += "Open Positions: " + IntegerToString(PositionsTotal()) + "\n";
    comment += "Last Scan: " + TimeToString(g_lastGlobalUpdate, TIME_SECONDS) + "\n";
    
    Comment(comment);
}
//+------------------------------------------------------------------+
