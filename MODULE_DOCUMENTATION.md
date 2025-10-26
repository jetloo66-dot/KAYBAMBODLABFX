# KAYBAMBODLABFX Modular Trading Bot - Module Documentation

## Overview
This trading bot is designed with a highly modular architecture where each manager is responsible for a specific aspect of the trading system. All managers are independent, replaceable, and communicate through well-defined interfaces.

## Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                   ModularTradingBot.mq5                     │
│                    (Main Coordinator)                        │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│Configuration │    │ GlobalVars   │    │  LogManager  │
│   Manager    │    │   Manager    │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
        │                   │                   │
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│MultiSymbol   │    │PriceAction   │    │   Telegram   │
│  Scanner     │    │   Manager    │    │   Manager    │
└──────────────┘    └──────────────┘    └──────────────┘
        │                   │                   │
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ NewsFilter   │    │     Risk     │    │    Trade     │
│   Manager    │    │   Manager    │    │  Execution   │
└──────────────┘    └──────────────┘    └──────────────┘
```

## Manager Modules

### 1. ConfigurationManager.mqh
**Responsibility:** Centralized management of all EA settings and parameters

**Key Features:**
- Loads settings from input parameters
- Validates all configuration values
- Provides getters/setters for runtime updates
- Supports saving/loading configuration to/from files
- Manages timeframe settings, trading parameters, risk settings, and visualization options

**Interface:**
```cpp
CConfigurationManager config;
config.Initialize();
config.LoadFromInputs(...);
double lotSize = config.GetLotSize();
config.SetLotSize(0.02);
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5, All other managers

---

### 2. GlobalVarsManager.mqh
**Responsibility:** Centralized state management for all global variables and shared data

**Key Features:**
- Manages system state (initialization, testing mode, optimization)
- Tracks trading state (signals, trades, success rate)
- Stores market data (symbol, timeframe, prices, spread)
- Maintains pattern and trend analysis state
- Manages risk metrics and error tracking
- Handles price level arrays and pattern history

**Interface:**
```cpp
CGlobalVarsManager globalVars;
globalVars.Initialize();
globalVars.UpdateMarketData();
bool isNewBar = globalVars.IsNewBar();
ENUM_TREND_DIRECTION trend = globalVars.GetCurrentTrend();
globalVars.SetCurrentTrend(TREND_UP, 0.8);
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5, All other managers

---

### 3. LogManager_Version1.mqh
**Responsibility:** Comprehensive logging system with multiple output levels

**Key Features:**
- Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- File and console logging
- Specialized logging for trades, signals, patterns, performance
- Log storage with configurable size limits
- Log statistics and filtering
- Performance metrics logging

**Interface:**
```cpp
CLogManager logger;
logger.Initialize(LOG_LEVEL_INFO, true, true);
logger.LogInfo("Trade executed", "TRADE");
logger.LogError("Order failed", "TRADE", errorCode);
logger.LogTrade("BUY", "EURUSD", 1.1000, 0.01);
logger.PrintLogStatistics();
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5

---

### 4. MultiSymbolScanner.mqh
**Responsibility:** Efficient scanning of multiple symbols and timeframes for trading opportunities

**Key Features:**
- Add/remove symbols dynamically
- Scan multiple timeframes simultaneously
- Configurable scan intervals
- Signal detection and storage
- Result filtering and querying
- Validates symbol availability

**Interface:**
```cpp
CMultiSymbolScanner scanner;
scanner.Initialize(5); // 5-minute scan interval
scanner.AddSymbol("EURUSD");
scanner.AddTimeframe(PERIOD_H1);
scanner.ScanAllMarkets();
int signalCount = scanner.GetSignalCount();
SymbolScanResult result = scanner.GetResult(0);
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5 (optional - for multi-symbol trading)

---

### 5. NewsFilterManager.mqh
**Responsibility:** News event filtering to avoid trading during high-impact news

**Key Features:**
- Add/manage news events manually or from calendar
- Filter by currency, importance, and time window
- Configurable filter windows (before/after news)
- Weekend and holiday filtering
- Event scheduling and querying
- Symbol-specific filtering

**Interface:**
```cpp
CNewsFilterManager newsFilter;
newsFilter.Initialize(30, 2); // 30 min window, medium+ importance
newsFilter.AddNewsEvent(eventTime, "USD", "NFP", 3);
bool isNewsTime = newsFilter.IsNewsTime("EURUSD");
int minutesUntilNext = newsFilter.GetMinutesUntilNextEvent();
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5

---

### 6. PriceActionManager.mqh
**Responsibility:** Comprehensive price action analysis including patterns, S/R, and market structure

**Key Features:**
- Candlestick pattern detection (Pin Bar, Doji, Engulfing, Hammer, etc.)
- Support and resistance level detection
- Swing point identification
- Market structure analysis (trend, break of structure)
- Fibonacci level calculations
- Pattern strength calculation
- Price rejection analysis

**Interface:**
```cpp
CPriceActionManager priceAction;
priceAction.Initialize("EURUSD", PERIOD_H1);
priceAction.SetPatternSettings(0.6, 0.1, 1.0);

bool isPinBar = priceAction.IsPinBar(0);
PatternAnalysis pattern = priceAction.AnalyzePattern(0);
priceAction.DetectSupportResistance(50);
double support = priceAction.FindNearestSupport(price);
ENUM_TREND_DIRECTION trend = priceAction.GetTrendDirection();
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5

---

### 7. TelegramManager.mqh
**Responsibility:** Telegram notification system with rate limiting and message queueing

**Key Features:**
- Rate limiting (20 messages/minute default)
- Message queue for handling rate limits
- Specialized notification methods (trades, signals, patterns, risk, errors)
- Markdown formatting support
- Error tracking and retry logic
- Message encoding and web request handling

**Interface:**
```cpp
CTelegramManager telegram;
telegram.Initialize(botToken, chatID, true);
telegram.SendMessage("Hello from EA!");
telegram.SendTradeNotification("BUY", "EURUSD", 1.1000, 1.0950, 1.1100, 0.01);
telegram.SendSignalNotification(signalInfo);
telegram.ProcessQueue(); // Process queued messages
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5

---

### 8. RiskManager.mqh
**Responsibility:** Comprehensive risk management including position sizing and exposure control

**Key Features:**
- Dynamic lot size calculation based on risk percentage
- Position size calculation from entry/stop loss
- Risk-reward ratio calculation
- Daily loss limits
- Maximum drawdown control
- Position limit enforcement
- Account monitoring and statistics
- Exposure tracking per symbol

**Interface:**
```cpp
CRiskManager riskManager;
riskManager.Initialize(2.0, 10.0, 20.0); // 2% risk, 10% daily loss, 20% drawdown
double lotSize = riskManager.CalculateLotSize("EURUSD", 15.0);
bool canTrade = riskManager.CanOpenPosition("EURUSD");
double riskAmount = riskManager.CalculateRiskAmount(0.01, "EURUSD", 15.0);
RiskData data = riskManager.GetRiskData();
```

**Dependencies:** Structs_Version1.mqh

**Used By:** ModularTradingBot.mq5

---

## Integration Pattern

### Initialization Flow
1. **ModularTradingBot.mq5** creates instances of all managers
2. Configuration is loaded from input parameters via **ConfigurationManager**
3. **GlobalVarsManager** is initialized to prepare state management
4. **LogManager** is initialized for logging
5. All other managers are initialized with their specific settings
6. Managers are configured based on settings from **ConfigurationManager**

### Runtime Flow
1. **OnTick()** is called by MT5
2. **GlobalVarsManager** updates market data
3. Check for new bar via **GlobalVarsManager**
4. On new bar:
   - **PriceActionManager** performs market analysis
   - **NewsFilterManager** checks for news events
   - **RiskManager** validates risk limits
5. Trading decisions are made based on:
   - Pattern analysis from **PriceActionManager**
   - Risk validation from **RiskManager**
   - News filtering from **NewsFilterManager**
6. Trades are executed and logged via **LogManager**
7. Notifications sent via **TelegramManager**
8. **GlobalVarsManager** updates state

### Communication Pattern
- Managers do NOT directly depend on each other (loose coupling)
- Communication happens through **ModularTradingBot.mq5** coordinator
- Shared data structures defined in **Structs_Version1.mqh**
- State is centralized in **GlobalVarsManager**
- Configuration is centralized in **ConfigurationManager**

## Extensibility

### Adding a New Manager
1. Create new `.mqh` file (e.g., `MyNewManager.mqh`)
2. Include **Structs_Version1.mqh** for shared structures
3. Implement manager class with clear interface
4. Add `#include "MyNewManager.mqh"` in **ModularTradingBot.mq5**
5. Create instance in **OnInit()**
6. Integrate into trading logic as needed

### Replacing an Existing Manager
1. Create new manager with same interface
2. Replace `#include` statement in **ModularTradingBot.mq5**
3. No other changes needed due to loose coupling

### Example: Adding PerformanceManager
```cpp
// PerformanceManager.mqh
class CPerformanceManager {
public:
    bool Initialize();
    void TrackTrade(double profit, double loss);
    double GetWinRate();
    double GetProfitFactor();
    void PrintReport();
};

// In ModularTradingBot.mq5
#include "PerformanceManager.mqh"
CPerformanceManager *perfManager;

int OnInit() {
    perfManager = new CPerformanceManager();
    perfManager.Initialize();
    // ...
}
```

## File Structure
```
KAYBAMBODLABFX/
├── ModularTradingBot.mq5           # Main EA file
├── ConfigurationManager.mqh         # Configuration management
├── GlobalVarsManager.mqh            # Global state management
├── LogManager_Version1.mqh          # Logging system
├── MultiSymbolScanner.mqh           # Multi-symbol scanning
├── NewsFilterManager.mqh            # News filtering
├── PriceActionManager.mqh           # Price action analysis
├── TelegramManager.mqh              # Telegram notifications
├── RiskManager.mqh                  # Risk management
├── Structs_Version1.mqh             # Shared data structures
└── MODULE_DOCUMENTATION.md          # This file
```

## Best Practices

### For Developers
1. **Keep managers independent** - Avoid cross-dependencies
2. **Use shared structures** - Define common data types in Structs_Version1.mqh
3. **Log extensively** - Use LogManager for debugging
4. **Validate inputs** - Check parameters in Initialize() methods
5. **Handle errors gracefully** - Return false on errors, log details
6. **Document interfaces** - Clear method signatures and comments

### For Users
1. **Review settings** - Validate all input parameters before use
2. **Test in demo** - Always test new configurations in demo account
3. **Monitor logs** - Check logs for errors and warnings
4. **Start conservative** - Begin with low risk settings
5. **Understand managers** - Read documentation for each manager you use

## Testing

### Unit Testing Approach
Each manager can be tested independently:
```cpp
// Test ConfigurationManager
CConfigurationManager config;
config.Initialize();
config.SetLotSize(0.01);
Assert(config.GetLotSize() == 0.01);
```

### Integration Testing
Test manager interactions in ModularTradingBot.mq5:
1. Load configuration
2. Initialize all managers
3. Simulate market conditions
4. Verify correct behavior

### Validation Checklist
- [ ] All managers initialize successfully
- [ ] Configuration validation works
- [ ] Risk limits are respected
- [ ] Patterns are detected correctly
- [ ] Trades execute as expected
- [ ] Notifications are sent properly
- [ ] Logs capture all events

## Troubleshooting

### Common Issues

**Manager fails to initialize**
- Check input parameters are valid
- Verify dependencies are included
- Review logs for error messages

**Risk limits not working**
- Ensure RiskManager is updated regularly
- Check account balance is sufficient
- Verify max position limits

**Patterns not detected**
- Validate price data is available
- Check pattern settings are reasonable
- Review PriceActionManager configuration

**Notifications not sent**
- Verify Telegram token and chat ID
- Check internet connection
- Review rate limiting settings
- Process message queue regularly

## Support
For issues, questions, or contributions, refer to the main repository documentation.

## Version History
- **v1.00** (2024) - Initial modular architecture release
  - Complete manager separation
  - All core managers implemented
  - Comprehensive documentation
