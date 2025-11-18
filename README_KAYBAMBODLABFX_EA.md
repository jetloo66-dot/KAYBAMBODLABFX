# KAYBAMBODLABFX Advanced Price Action EA

## Overview

The KAYBAMBODLABFX Advanced Price Action EA is a comprehensive MetaTrader 5 Expert Advisor that implements sophisticated price action analysis and automated trading strategies. This EA combines advanced technical analysis, multi-timeframe scanning, intelligent risk management, and professional-grade automation features.

## Key Features

### 🎯 Advanced Price Action Analysis
- **Key Level Detection**: Automatic identification of Support (S), Resistance (R), Swing High (SH), Swing Low (SL), Higher High (HH), Higher Low (HL), Lower Low (LL), Lower High (LH), High (H), and Low (L) levels with indexing system
- **Comprehensive Pattern Recognition**: Pin bars, Doji, Bullish/Bearish engulfing, Inside bars, Outside bars, Hammers, Shooting stars, and more
- **Market Structure Analysis**: Break of structure, Change of character, Liquidity grabs, Order blocks, Fair value gaps

### 📊 Multi-Timeframe Analysis
- **Primary Analysis**: H1 timeframe for trend detection and key levels
- **Execution Patterns**: M5 timeframe for entry signals
- **Configurable Timeframes**: Customizable primary and execution timeframes
- **Trend Detection**: Strict 6-condition trend rules for uptrend/downtrend confirmation

### 🤖 Automated Trading System
- **Pattern Sequences**: 9 different sequence combinations (I-IX) for buy/sell signals
- **Level-Based Activation**: Trades activated at specific key levels with proximity tolerance
- **Multi-Symbol Support**: Scan and trade major forex pairs, cryptocurrencies, and metals
- **Intelligent Entry Logic**: Multiple confirmation requirements before trade execution

### 💰 Advanced Risk Management
- **Position Sizing**: Risk-based or fixed lot size options
- **Stop Loss Management**: Configurable stop loss with trailing functionality
- **Daily Risk Limits**: Maximum daily risk percentage controls
- **Multi-Position Limits**: Maximum trades per pair and total trades
- **Risk-Reward Analysis**: Automatic R:R ratio calculations

### 📱 Communication & Alerts
- **Telegram Integration**: Real-time trade notifications and market analysis updates
- **Chart Visualization**: Automatic drawing of key levels, zones, and patterns
- **Comprehensive Logging**: Detailed logging system with multiple levels
- **Performance Monitoring**: Built-in performance tracking and reporting

### 🛡️ Professional Features
- **News Filter**: Avoid trading during high-impact news events
- **Market Session Awareness**: Trade timing based on market sessions
- **Error Handling**: Robust error handling and recovery mechanisms
- **Memory Optimization**: Efficient memory usage and performance optimization
- **Backup & Recovery**: State saving and restoration capabilities

## Installation Guide

### Prerequisites
- MetaTrader 5 platform
- Sufficient account balance for trading
- Stable internet connection
- Valid broker account with low spreads

### Installation Steps

1. **Download Files**
   - Copy all `.mq5` and `.mqh` files to your MetaTrader 5 `MQL5/Experts/` directory
   - Ensure all include files are in the same directory or `MQL5/Include/` directory

2. **Compile the EA**
   - Open MetaEditor in MetaTrader 5
   - Open `KAYBAMBODLABFX_AdvancedPriceAction_EA.mq5`
   - Compile the EA (F7 key)
   - Fix any compilation errors if they occur

3. **Configure Settings**
   - Attach the EA to a chart
   - Configure input parameters according to your preferences
   - Enable auto-trading in MetaTrader 5

## Configuration Parameters

### Analysis Settings
- **Primary Timeframe**: H1 (recommended) - Main analysis timeframe
- **Execution Timeframe**: M5 (recommended) - Pattern detection timeframe
- **Candles to Analyze**: 100 - Number of candles for level detection
- **Pattern Scan Candles**: 20 - M5 candles to scan for patterns

### Level Detection
- **Max Levels Per Type**: 10 - Maximum levels to store per category
- **Level Proximity Pips**: 5.0 - Distance tolerance for level activation
- **Swing Detection Strength**: 5 - Strength for swing point detection

### Trade Management
- **Default Lot Size**: 0.01 - Base position size
- **Stop Loss Base Pips**: 10.0 - Base stop loss distance
- **Take Profit Base Pips**: 50.0 - Base take profit distance
- **Max Trades Per Pair**: 2 - Maximum concurrent trades per symbol
- **Use Trailing Stop**: true - Enable trailing stop functionality
- **Trailing Stop Pips**: 15.0 - Trailing stop distance
- **Trailing Step Pips**: 5.0 - Trailing step size

### Pattern Detection
- **Pin Bar Wick Ratio**: 0.6 - Minimum wick to body ratio for pin bars
- **Doji Max Body Ratio**: 0.1 - Maximum body ratio for doji patterns
- **Engulfing Min Ratio**: 1.0 - Minimum ratio for engulfing patterns

### Risk Management
- **Max Risk Percent Per Trade**: 2.0% - Maximum risk per individual trade
- **Max Daily Risk**: 5.0% - Maximum daily risk exposure
- **Use Fixed Lot Size**: false - Use risk-based position sizing

### Telegram Settings
- **Bot Token**: Your Telegram bot token
- **Chat ID**: Your Telegram chat ID
- **Enable Notifications**: true/false - Enable Telegram alerts

### Symbols to Scan
Default: "EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,USDCAD,NZDUSD,XAUUSD,XAGUSD,BTCUSD,ETHUSD"

## Trading Logic

### Trend Detection (H1 Timeframe)
The EA uses strict trend detection rules where **all conditions must be met**:

**Uptrend Conditions:**
1. HH[0] > HH[1] (Current Higher High > Previous Higher High)
2. HL[0] > HL[1] (Current Higher Low > Previous Higher Low)
3. SH[0] > SH[1] (Current Swing High > Previous Swing High)
4. SL[0] > SL[1] (Current Swing Low > Previous Swing Low)
5. H[0] > SH[1] (Current High > Previous Swing High)
6. L[0] > L[1] (Current Low > Previous Low)

**Downtrend Conditions:**
All opposite conditions must be met for downtrend confirmation.

### Buy Signal Sequences (M5 Timeframe)
The EA looks for specific pattern sequences:

**Sequence I**: (a) Pin Bar → (c) Bullish Engulfing → (d) Break of Structure → (e) Retracement
**Sequence II**: (a) Pin Bar → (b) Doji → (c) Bullish Engulfing → (d) Break of Structure → (e) Retracement
**Sequence III**: (b) Doji → (c) Bullish Engulfing → (d) Break of Structure → (e) Retracement
**Sequence IV**: (a) Pin Bar → (d) Break of Structure → (e) Retracement
**Sequence V**: (b) Doji → (d) Break of Structure → (e) Retracement
**Sequence VI**: (c) Bullish Engulfing → (d) Break of Structure → (e) Retracement
**Sequence VII**: (a) Pin Bar → (c) Bullish Engulfing
**Sequence VIII**: (b) Doji → (c) Bullish Engulfing
**Sequence IX**: (d) Break of Structure → (e) Retracement

### Trade Activation Levels (Buy Signals)
Trades are activated when price is near:
- S[0] (Most recent Support)
- Within 5 pips of S[0]
- HL[0] (Most recent Higher Low)
- Within 5 pips of HL[0]
- High of lowest bearish candle at S[0]
- SL[0] (Most recent Swing Low)

### Sell Signal Logic
Similar sequences apply for sell signals but with bearish patterns and resistance/high levels.

## Risk Management

### Position Sizing
- **Risk-Based**: Calculates lot size based on account balance and risk percentage
- **Fixed Lot**: Uses predetermined lot size
- **Symbol Normalization**: Automatically adjusts to broker's minimum/maximum lot sizes

### Stop Loss Management
- **Initial Stop**: Set based on configuration (default 10 pips above/below confirmation zone)
- **Trailing Stop**: Moves stop loss in favorable direction
- **Take Profit**: Set at swing levels or fixed pip distance (default 50 pips)

### Daily Risk Controls
- **Maximum Daily Risk**: 5% of account balance (configurable)
- **Position Limits**: Maximum 2 trades per pair, 10 total trades
- **News Avoidance**: 30-minute buffer around high-impact news

## Telegram Setup

### Creating a Telegram Bot
1. Search for @BotFather on Telegram
2. Send `/newbot` command
3. Follow instructions to create your bot
4. Copy the bot token provided
5. Get your chat ID by messaging @userinfobot

### Configuration
- Enter bot token in EA settings
- Enter your chat ID in EA settings
- Enable notifications in EA settings

### Message Types
- **Trade Alerts**: Buy/sell order notifications
- **Market Analysis**: Periodic market condition updates
- **Performance Reports**: Daily/weekly performance summaries
- **Error Notifications**: Critical error alerts

## Chart Visualization

### Level Display
- **Support Levels**: Blue horizontal lines (S[0], S[1], etc.)
- **Resistance Levels**: Red horizontal lines (R[0], R[1], etc.)
- **Swing Points**: Dotted lines for swing highs/lows
- **Buy Zones**: Green rectangular zones
- **Sell Zones**: Orange rectangular zones

### Pattern Indicators
- **Pin Bars**: Highlighted with arrows
- **Engulfing Patterns**: Marked with rectangles
- **Break of Structure**: Trend line breaks
- **Key Levels**: Labeled horizontal lines

## Performance Monitoring

### Built-in Metrics
- **Win Rate**: Percentage of profitable trades
- **Average Risk-Reward**: Mean R:R ratio achieved
- **Maximum Drawdown**: Largest consecutive loss
- **Profit Factor**: Gross profit / Gross loss ratio
- **Sharpe Ratio**: Risk-adjusted return metric

### Reporting Features
- **Daily Reports**: End-of-day performance summary
- **Weekly Analysis**: Weekly trend and performance review
- **Monthly Statistics**: Comprehensive monthly analysis
- **Export Options**: CSV and JSON export capabilities

## Troubleshooting

### Common Issues

1. **EA Not Trading**
   - Check if auto-trading is enabled
   - Verify symbol availability in Market Watch
   - Ensure sufficient account balance
   - Check if news filter is blocking trades

2. **Compilation Errors**
   - Verify all include files are present
   - Check file paths and names
   - Ensure MetaTrader 5 is updated

3. **Telegram Not Working**
   - Verify bot token and chat ID
   - Check internet connection
   - Ensure Telegram bot is active

4. **High Spread Issues**
   - Adjust spread filter settings
   - Use during active market hours
   - Choose broker with competitive spreads

### Log Analysis
The EA maintains detailed logs in the following categories:
- **INIT**: Initialization and setup messages
- **ANALYSIS**: Market analysis and scanning results
- **PATTERN**: Pattern detection events
- **TRADE**: Trade execution and management
- **RISK**: Risk management alerts
- **ERROR**: Error conditions and recovery

## Best Practices

### Account Setup
- **Minimum Balance**: $1000 recommended for proper risk management
- **Leverage**: 1:30 to 1:100 for conservative trading
- **Spread**: Choose broker with spreads under 2 pips for majors
- **Execution**: ECN or STP accounts preferred

### Optimization
- **Backtest First**: Always backtest on historical data
- **Forward Test**: Use demo account before live trading
- **Start Small**: Begin with minimum lot sizes
- **Monitor Performance**: Regular performance review

### Market Conditions
- **Best Performance**: Trending markets with clear directional bias
- **Avoid**: High-impact news periods and low liquidity sessions
- **Optimal Sessions**: London and New York sessions for forex
- **Volatility**: Works best in moderate to high volatility environments

## Support and Updates

### Documentation
- Complete source code documentation in comments
- Pattern recognition examples and explanations
- Risk management calculation details
- Performance optimization guidelines

### Maintenance
- Regular parameter optimization recommended
- Market condition adjustments as needed
- Periodic code updates for improved performance
- Bug fixes and feature enhancements

## Disclaimer

This Expert Advisor is provided for educational and informational purposes. Trading foreign exchange and other financial instruments involves substantial risk and may not be suitable for all investors. Past performance is not indicative of future results. Please ensure you understand the risks involved and seek independent financial advice if necessary.

The developers of this EA are not responsible for any financial losses incurred from its use. Always test thoroughly on a demo account before using on a live account.

## Version History

### Version 2.0 (Current)
- Complete rewrite with enhanced price action analysis
- Multi-symbol scanning capabilities
- Advanced risk management system
- Telegram integration
- Professional chart visualization
- Comprehensive documentation

### Features Added
- 9-sequence pattern recognition system
- Strict trend detection rules
- Level-based trade activation
- Multi-timeframe analysis
- Performance monitoring
- News filter integration
- Backup and recovery system

---

*KAYBAMBODLABFX - Advanced Price Action Trading Solutions*