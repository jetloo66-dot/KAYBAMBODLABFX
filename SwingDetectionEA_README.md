# Swing Detection Expert Advisor - Production Ready MT5 EA

## Overview
The Swing Detection EA is a production-ready, multi-timeframe swing trading system for MetaTrader 5 (MT5). It implements a comprehensive strategy that analyzes price structure on H1 timeframe and executes trades on M5 timeframe using swing detection, Stochastic oscillator, and Bollinger Bands.

## Strategy Description

### A. Higher Timeframe Analysis (H1)
- **Swing Detection**: Automatically identifies swing points (HH, HL, LH, LL) using fractal logic
- **Overbought Detection**: Stochastic > 80 AND price touches upper Bollinger Band
- **Oversold Detection**: Stochastic < 20 AND price touches lower Bollinger Band
- **Support/Resistance**: Tracks and stores last 10 swing levels for context

### B. Lower Timeframe Confirmation (M5)
- **Structure Confirmation**: Validates H1 signals with M5 swing structure
- **Break of Structure (BOS)**: 
  - Buy: Price closes above recent Lower High (LH)
  - Sell: Price closes below recent Higher Low (HL)
- **Retracement Logic**:
  - Buy: Waits for retracement to lowest candle in last Lower Low (LL)
  - Sell: Waits for retracement to highest candle in last Higher High (HH)

### C. Trade Activation
**Buy Setup:**
1. Oversold on both H1 and M5 (Stochastic < 20 + BB lower band touch)
2. Break of structure detected (price closes above LH on M5)
3. Retracement to last LL's lowest candle
4. Execute with configurable SL/TP

**Sell Setup:**
1. Overbought on both H1 and M5 (Stochastic > 80 + BB upper band touch)
2. Break of structure detected (price closes below HL on M5)
3. Retracement to last HH's highest candle
4. Execute with configurable SL/TP

## Features

### Core Functionality
- ✅ Multi-symbol scanning (9+ currency pairs and commodities)
- ✅ Multi-timeframe analysis (H1 + M5)
- ✅ Robust swing detection with fractal-based logic
- ✅ Break of structure identification
- ✅ Retracement detection and validation
- ✅ Automatic SL/TP calculation
- ✅ Trailing stop with break-even logic

### Risk Management
- ✅ Configurable lot size or risk percentage
- ✅ Maximum trades per symbol (default: 3)
- ✅ Daily loss limit protection
- ✅ Position sizing based on account equity
- ✅ Stop loss validation against broker requirements

### Filters & Accuracy
- ✅ Session time filters (configurable hours/days)
- ✅ News filter integration (placeholder for external calendar)
- ✅ Duplicate signal prevention
- ✅ Data gap detection
- ✅ Minimum bars validation

### Notifications
- ✅ Telegram integration for:
  - Signal detection alerts
  - Trade execution notifications
  - Take profit/stop loss hits
  - Trailing stop updates
  - Error notifications

### Visualization
- ✅ Swing points marked on chart (HH, HL, LH, LL)
- ✅ Buy/sell signals with arrows
- ✅ Support/resistance levels
- ✅ Trade boxes showing SL/TP
- ✅ Color-coded zones (green for buy, red for sell)

### Error Handling
- ✅ Comprehensive error logging to file
- ✅ Connection timeout handling
- ✅ Trade parameter validation
- ✅ Indicator handle validation
- ✅ Account and symbol trade permission checks

## Installation

1. **Copy Files to MT5:**
   - Place `SwingDetectionEA.mq5` in `MQL5/Experts/`
   - Place all `.mqh` files in `MQL5/Experts/` or `MQL5/Include/`

2. **Add Telegram URL to MT5:**
   - Open MT5 Terminal
   - Go to Tools → Options → Expert Advisors
   - Check "Allow WebRequest for listed URL:"
   - Add: `https://api.telegram.org`

3. **Compile:**
   - Open MetaEditor (F4 in MT5)
   - Open `SwingDetectionEA.mq5`
   - Press F7 to compile
   - Fix any errors if they appear

4. **Attach to Chart:**
   - Open any chart (recommendation: EURUSD, M5)
   - Drag EA from Navigator to chart
   - Configure parameters
   - Enable AutoTrading (F7 or button in toolbar)

## Configuration

### Essential Parameters

#### Timeframes
- **Higher Timeframe (Analysis)**: Default H1 - for swing detection and trend analysis
- **Lower Timeframe (Execution)**: Default M5 - for entry timing

#### Stochastic Oscillator
- **K Period**: Default 5
- **D Period**: Default 3
- **Slowing**: Default 3
- **Oversold Level**: Default 20
- **Overbought Level**: Default 80

#### Bollinger Bands
- **Period**: Default 20
- **Deviation**: Default 2.0

#### Trade Management
- **Lot Size**: Default 0.1 (or use risk percentage)
- **Stop Loss**: Default 10 pips
- **Take Profit**: Default 30 pips
- **Trailing Start**: Default 10 pips
- **Trailing Step**: Default 5 pips
- **Max Trades Per Symbol**: Default 3

#### Symbol Selection
Enable/disable trading for each symbol:
- EURUSD, GBPUSD, USDJPY (Major Pairs)
- AUDUSD, NZDUSD, USDCAD, USDCHF (Minor Pairs)
- XAUUSD (Gold)
- BTCUSD (Bitcoin)

#### Telegram Notifications
- **Bot Token**: Your Telegram bot token (obtain from @BotFather)
- **Chat ID**: Your Telegram chat ID (obtain from @userinfobot)
- **Enable Telegram**: true/false

**How to get Telegram credentials:**
1. Open Telegram and search for @BotFather
2. Send `/newbot` command and follow instructions
3. Copy the bot token provided
4. Search for @userinfobot and send `/start`
5. Copy your chat ID (numeric value)

### Advanced Parameters

#### Session Filters
- **Use Session Filter**: Enable/disable time-based trading
- **Session Start Hour**: Trading start (0-23)
- **Session End Hour**: Trading end (0-23)
- **Trade Days**: Monday-Friday selection

#### Risk Management
- **Use Risk Percent**: Calculate lot size based on risk percentage
- **Risk Percent**: Default 1% per trade
- **Max Daily Loss**: Default 5% - EA stops trading if reached

#### Visualization
- **Show Swing Points**: Display swing levels on chart
- **Show S/R Levels**: Display support/resistance
- **Show Signals**: Display buy/sell arrows
- **Colors**: Customize buy/sell signal colors

## Module Architecture

### SwingDetectionEA.mq5 (Main EA)
- Initialization and deinitialization
- Multi-symbol management
- Main trading loop
- Position management
- Event handling

### SwingDetection.mqh
- Fractal-based swing point detection
- Swing classification (HH, HL, LH, LL)
- Break of structure detection
- Retracement validation
- Trend analysis

### SignalGenerator.mqh
- H1 and M5 timeframe analysis
- Stochastic oscillator integration
- Bollinger Bands analysis
- Overbought/oversold detection
- Signal generation and validation

### SupportResistance.mqh
- Swing level tracking
- Support/resistance identification
- Level strength calculation
- Historical level management
- Price proximity checks

### TelegramNotifier.mqh
- Message formatting
- HTTP request handling
- Trade alert notifications
- Performance notifications
- Error reporting

### ChartVisualization.mqh
- Swing point drawing
- Signal arrows
- Support/resistance lines
- Trade boxes (SL/TP display)
- Zone highlighting

### ErrorHandler.mqh
- Comprehensive error logging
- File-based log management
- Error code descriptions
- Data validation
- Trade permission checks

## Optimization Guide

### Strategy Tester Settings
1. Open Strategy Tester (Ctrl+R)
2. Select SwingDetectionEA
3. Set symbol and timeframe
4. Choose test period (minimum 3 months recommended)
5. Select optimization mode

### Parameters to Optimize
**High Impact:**
- Stochastic K Period (3-10)
- Stochastic Oversold/Overbought (15-25 / 75-85)
- BB Period (15-25)
- BB Deviation (1.5-2.5)
- Stop Loss Pips (5-20)
- Take Profit Pips (15-50)

**Medium Impact:**
- Swing Left/Right Bars (3-7)
- Trailing Start (5-15)
- Max Trades Per Symbol (1-5)

**Low Impact:**
- Scan Interval (1-10 minutes)
- Session filters (depends on strategy)

### Optimization Tips
1. Start with single symbol optimization
2. Use genetic algorithm for faster results
3. Focus on profit factor > 1.5
4. Aim for win rate > 50%
5. Validate on different time periods
6. Forward test before live trading

## Performance Monitoring

### Key Metrics to Track
- **Win Rate**: Target > 50%
- **Profit Factor**: Target > 1.5
- **Risk/Reward Ratio**: Target > 1:2
- **Max Drawdown**: Keep < 20%
- **Daily P&L**: Monitor against limits

### Chart Comment Display
The EA displays real-time statistics:
- Total trades executed
- Daily profit/loss percentage
- Number of active symbols
- Open positions count
- Last scan timestamp

### Log Files
Check log files for detailed information:
- `SwingEA_SYMBOL_Log.txt` - Detailed operation log
- MT5 Experts tab - Real-time messages
- Strategy Tester report - Historical performance

## Troubleshooting

### Common Issues

**EA Not Trading:**
- ✓ Check AutoTrading is enabled (F7)
- ✓ Verify account allows automated trading
- ✓ Check symbol trading hours
- ✓ Ensure sufficient account balance
- ✓ Review session filter settings

**No Telegram Notifications:**
- ✓ Add api.telegram.org to allowed URLs
- ✓ Verify bot token and chat ID
- ✓ Test with telegram test bot
- ✓ Check internet connection

**Compilation Errors:**
- ✓ Ensure all .mqh files are in correct folder
- ✓ Check Trade library is available
- ✓ Update MT5 to latest version
- ✓ Review error messages in MetaEditor

**High CPU Usage:**
- ✓ Increase scan interval
- ✓ Reduce number of enabled symbols
- ✓ Disable chart visualization if not needed

## Best Practices

### Live Trading
1. **Start Small**: Begin with minimum lot size
2. **Test First**: Use demo account for at least 2 weeks
3. **Monitor Daily**: Check EA performance regularly
4. **Set Limits**: Configure daily loss limits
5. **Diversify**: Don't trade all symbols at once initially

### Risk Management
1. Never risk more than 1-2% per trade
2. Set appropriate daily loss limits
3. Monitor correlation between symbols
4. Maintain adequate account balance
5. Review performance weekly

### Optimization
1. Optimize quarterly or semi-annually
2. Use walk-forward analysis
3. Test on multiple symbols
4. Validate on different market conditions
5. Keep backup of working parameters

## Version History

### v1.0 (Current)
- Initial production release
- Multi-timeframe swing detection
- H1 analysis + M5 execution
- Full Telegram integration
- Comprehensive error handling
- Chart visualization
- Multi-symbol support
- Risk management features

## Support & Updates

### Documentation
- This README file
- Inline code comments
- Log file analysis

### Getting Help
1. Review log files for errors
2. Check MT5 Expert tab for messages
3. Verify all parameters are configured
4. Test on demo account first

## Disclaimer

This Expert Advisor is provided for educational and trading purposes. Past performance does not guarantee future results. Always test thoroughly on a demo account before live trading. Trading forex and CFDs involves significant risk of loss. Only trade with money you can afford to lose.

## License

Copyright 2024, KAYBAMBODLABFX
All rights reserved.

---

**Happy Trading! 📈**
