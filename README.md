# KAYBAMBODLABFX Trading Strategy EA

## Complete Professional Trading Expert Advisor

This repository contains a comprehensive, professional-grade MQL5 Expert Advisor implementing advanced price action analysis, pattern recognition, and automated trading strategies.

## Features

### ✅ **Complete File Structure**
- `KAYBAMBODLABFX_MultiStrategy_EA.mq5` - Main EA with full functionality
- `THEKAYBAMBODLABFX.mq5` - Simplified template version
- `Include/` directory with all required modules:
  - `NewsFilter.mqh` - Economic calendar integration
  - `VisualIndicators.mqh` - Chart visualization system
  - `ConfigManager.mqh` - Configuration management
  - `TradeManager.mqh` - Advanced trade execution and management
  - `TelegramNotifier.mqh` - Real-time notifications
  - `PriceActionAnalyzer.mqh` - Price action analysis
  - `LogManager.mqh` - Comprehensive logging system
  - `RiskManager.mqh` - Risk management controls
  - `Structs.mqh` - Data structures and enumerations

### ✅ **Price Action Analysis System**
- **Support/Resistance Detection**: S[0], S[1], R[0], R[1] indexing
- **Swing Point Detection**: SH[0], SH[1], SL[0], SL[1] indexing  
- **Trend Structure Analysis**: HH[0], HH[1], HL[0], HL[1], LH[0], LH[1], LL[0], LL[1] indexing
- **6-Criteria Trend Analysis**: Comprehensive trend determination based on multiple factors

### ✅ **Pattern Recognition**
- **Pin Bar Detection**: Configurable ratio-based detection
- **Doji Pattern Recognition**: Body-to-range ratio analysis
- **Engulfing Patterns**: Bullish and bearish engulfing detection
- **Break of Structure**: Market structure break identification
- **Retracement Analysis**: Price retracement to key levels

### ✅ **Complete Trading Logic - All 9 Sequences**
1. **(a) → (c) → (d) → (e)**: Pin Bar → Engulfing → Break of Structure → Retracement
2. **(a) → (d) → (e)**: Pin Bar → Break of Structure → Retracement
3. **(a) → (c) → (e)**: Pin Bar → Engulfing → Retracement
4. **(b) → (c) → (e)**: Doji → Engulfing → Retracement
5. **(b) → (c) → (d) → (e)**: Doji → Engulfing → Break of Structure → Retracement
6. **(b) → (d) → (e)**: Doji → Break of Structure → Retracement
7. **(c) → (d) → (e)**: Engulfing → Break of Structure → Retracement
8. **(a) → (c)**: Pin Bar → Engulfing
9. **(b) → (c)**: Doji → Engulfing

### ✅ **Advanced Risk Management**
- **Position Sizing**: Risk-based lot calculation
- **Stop Loss/Take Profit**: Configurable pip-based levels
- **Trailing Stop**: Dynamic stop loss management
- **Maximum Positions**: Configurable position limits
- **Risk Percentage**: Account balance risk controls
- **Daily Loss Limits**: Maximum daily drawdown protection

### ✅ **Real-Time Telegram Integration**
- **Trade Alerts**: Instant buy/sell notifications
- **Market Analysis**: Trend and pattern updates
- **Error Reporting**: System error notifications
- **Status Updates**: EA start/stop notifications
- **Pattern Alerts**: Real-time pattern detection alerts

### ✅ **Economic News Filter**
- **High-Impact Events**: NFP, FOMC, ECB meetings
- **Configurable Avoidance**: Time-based trade filtering
- **Multi-Currency Support**: Currency-specific filtering
- **Automatic Calendar Loading**: Built-in news event management

### ✅ **Advanced Visualization System**
- **Support/Resistance Levels**: Color-coded horizontal levels
- **Trading Zones**: Buy/sell zone highlighting
- **Pattern Markers**: Visual pattern identification on chart
- **Trend Indicators**: Dynamic trend direction display
- **Fibonacci Retracements**: Automatic fib level drawing
- **Entry/Exit Signals**: Trade execution markers

### ✅ **Professional Code Architecture**
- **Object-Oriented Design**: Modular class-based structure
- **Memory Management**: Proper object lifecycle management
- **Error Handling**: Comprehensive error checking and logging
- **Configuration Management**: Persistent settings with validation
- **Logging System**: Multi-level debugging and trade logging
- **Performance Optimized**: Efficient real-time analysis

## Installation

1. Copy the entire repository to your MetaTrader 5 data folder
2. Ensure the `Include/` directory structure is maintained
3. Compile `KAYBAMBODLABFX_MultiStrategy_EA.mq5` in MetaEditor
4. Configure input parameters as needed
5. Optional: Set up Telegram bot token and chat ID for notifications

## Configuration

### Main Parameters
- **Lot Size**: Trade volume (0.01 - 10.0)
- **Stop Loss**: Pips for stop loss (10-200)
- **Take Profit**: Pips for take profit (20-500)
- **Trailing Stop**: Enable/disable trailing stops
- **Max Positions**: Maximum concurrent positions

### Pattern Settings
- **Pin Bar Ratio**: Body-to-range ratio (0.1-0.8)
- **Doji Body Ratio**: Maximum body size (0.05-0.2)
- **Engulfing Ratio**: Minimum engulfing size (0.8-2.0)

### News Filter
- **Enable News Filter**: Avoid trading during news
- **Filter Minutes**: Minutes before/after news (15-60)

### Telegram Settings
- **Bot Token**: Your Telegram bot token
- **Chat ID**: Your Telegram chat ID
- **Enable Notifications**: Turn on/off alerts

## Usage

1. **Strategy Testing**: Use Strategy Tester for backtesting
2. **Demo Trading**: Test on demo account first
3. **Live Trading**: Deploy on live account with proper risk management
4. **Monitoring**: Watch logs and Telegram notifications
5. **Optimization**: Adjust parameters based on performance

## Technical Requirements

- **MetaTrader 5**: Build 3060 or higher
- **MQL5 Compiler**: Latest version
- **Memory**: Minimum 8GB RAM recommended
- **Internet**: Required for news filter and Telegram
- **Permissions**: Allow URL/WebRequest for Telegram functionality

## Risk Warning

Trading forex involves substantial risk of loss and is not suitable for all investors. Past performance is not indicative of future results. Always use proper risk management and never risk more than you can afford to lose.

## Support

For technical support, configuration help, or feature requests, please refer to the code documentation or contact the development team.

---

**KAYBAMBODLABFX** - Professional Trading Solutions
