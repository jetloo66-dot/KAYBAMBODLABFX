# THEKAYBAMBODLABFX Strategy Expert Advisor

## Overview

The THEKAYBAMBODLABFX EA is a comprehensive MetaTrader 5 Expert Advisor that implements advanced price action analysis with sophisticated pattern recognition and automated trading capabilities. The EA analyzes market conditions using multiple timeframes and executes trades based on proven price action patterns and support/resistance levels.

## Key Features

### 🎯 Advanced Price Action Analysis
- **Multi-timeframe scanning**: H1, H4, and Daily (all configurable)
- **Level detection**: Support (S), Resistance (R), Swing High (SH), Swing Low (SL)
- **Market structure**: Higher High (HH), Higher Low (HL), Lower Low (LL), Lower High (LH)
- **Indexed level tracking**: S[0], S[1], S[2], etc. (most recent to oldest)
- **Configurable lookback**: Default 100 candles for comprehensive analysis

### 📊 Sophisticated Pattern Recognition
- **Pin Bar detection** with configurable body ratio (default 0.6)
- **Doji pattern recognition** with configurable body ratio (default 0.1)
- **Bullish/Bearish Engulfing patterns**
- **Break of Structure detection** on M5 timeframe
- **Retracement to confirmation zones**

### 🔄 Trend Detection System
- **Uptrend Conditions**: HH > previous HH, HL > previous HL, swing patterns
- **Downtrend Conditions**: HH < previous HH, HL < previous HL, swing patterns
- **Sideways market detection**
- **Dynamic trend strength calculation**

### ⚡ Trading Logic (9 Valid Sequences)

#### Buy Signal Sequences:
1. Pin Bar → Bullish Engulfing → Break of Structure → Retracement
2. Pin Bar → Break of Structure → Retracement
3. Pin Bar → Bullish Engulfing → Retracement
4. Doji → Bullish Engulfing → Retracement
5. Doji → Bullish Engulfing → Break of Structure → Retracement
6. Doji → Break of Structure → Retracement
7. Bullish Engulfing → Break of Structure → Retracement
8. Pin Bar → Bullish Engulfing
9. Doji → Bullish Engulfing

#### Sell Signal Sequences:
Same patterns but with bearish equivalents (Inverted Pin Bar, Bearish Engulfing, etc.)

#### Buy Signal Activation (H1 timeframe):
- At most recent Support ± 5 pips (configurable)
- At most recent Higher Low ± 5 pips (configurable)
- High of lowest bearish candle at most recent Support
- Most recent swing low

#### Sell Signal Activation (H1 timeframe):
- At most recent Resistance ± 5 pips (configurable)
- At most recent Lower High ± 5 pips (configurable)
- Low of highest bullish candle at most recent Resistance
- Most recent swing high

### 🛡️ Risk Management
- **Stop Loss**: 10 pips (configurable) above/below confirmation zone
- **Take Profit**: 50 pips (configurable) or swing low/high on H1
- **Position Limits**: Maximum 2 trades per pair simultaneously
- **Efficient trailing stop** with configurable distance and step
- **Risk-based lot size calculation**

### 📱 Telegram Integration
- **Real-time notifications** for trade entries and exits
- **Market analysis updates** with trend and level information
- **Pattern detection alerts**
- **Configurable message formatting** with emojis and structured data

### 📰 News Filter
- **Economic calendar integration** to avoid trading during high-impact news
- **Configurable filter window** (default 30 minutes before/after news)
- **Currency-specific filtering**

### 🎨 Visual Analysis Tools
- **Support/Resistance level visualization** with colored lines
- **Fibonacci retracement** drawing between swing points
- **Buy/Sell zone highlighting** with transparent rectangles
- **Real-time level updates** and chart annotations

## Installation

1. Copy all `.mqh` files to your MetaTrader 5 `Include` directory
2. Place `THEKAYBAMBODLABFX.mq5` in your `Experts` directory
3. Compile the EA in MetaEditor
4. Apply to chart with desired settings

## Configuration Parameters

### Timeframe Settings
- **AnalysisTimeframe1**: Primary analysis timeframe (default: H1)
- **AnalysisTimeframe2**: Secondary analysis timeframe (default: H4)
- **AnalysisTimeframe3**: Tertiary analysis timeframe (default: Daily)
- **ExecutionTimeframe**: Pattern execution timeframe (default: M5)

### Scan Settings
- **CandlesToScan**: Number of candles to analyze for levels (default: 100)
- **PatternScanCandles**: Candles to scan for patterns on M5 (default: 20)
- **ScanIntervalMinutes**: Chart scan frequency (default: 5 minutes)

### Level Detection
- **MaxLevelsToStore**: Maximum levels per type (default: 10)
- **LevelProximityPips**: Proximity tolerance for level matching (default: 5.0)
- **SwingStrength**: Swing point detection sensitivity (default: 5)

### Trading Settings
- **LotSize**: Fixed lot size for trades (default: 0.01)
- **StopLossPips**: Stop loss distance in pips (default: 10.0)
- **TakeProfitPips**: Take profit distance in pips (default: 50.0)
- **MaxTradesPerPair**: Maximum simultaneous trades (default: 2)
- **UseTrailingStop**: Enable trailing stop functionality (default: true)
- **TrailingStopPips**: Trailing stop distance (default: 10.0)
- **TrailingStepPips**: Trailing step size (default: 5.0)

### Pattern Settings
- **PinBarRatio**: Pin bar body-to-range ratio (default: 0.6)
- **DojiBodyRatio**: Doji body-to-range ratio (default: 0.1)
- **EngulfingRatio**: Engulfing pattern size ratio (default: 1.0)

### News Filter
- **UseNewsFilter**: Enable news filtering (default: true)
- **NewsFilterMinutes**: Minutes to avoid trading around news (default: 30)

### Telegram Settings
- **TelegramBotToken**: Your Telegram bot token
- **TelegramChatID**: Your Telegram chat ID
- **SendTelegramNotifications**: Enable notifications (default: false)

### Visualization
- **ShowLevels**: Display support/resistance levels (default: true)
- **ShowFibonacci**: Display Fibonacci retracement (default: true)
- **ShowZones**: Display buy/sell zones (default: true)
- **SupportColor**: Support level color (default: Blue)
- **ResistanceColor**: Resistance level color (default: Red)
- **BuyZoneColor**: Buy zone color (default: Lime)
- **SellZoneColor**: Sell zone color (default: Orange)

## How It Works

### 1. Market Analysis Phase
The EA continuously scans multiple timeframes (H1, H4, Daily) to:
- Identify key support and resistance levels
- Track market structure changes (HH, HL, LH, LL)
- Determine overall trend direction
- Store levels in indexed arrays for quick reference

### 2. Pattern Recognition Phase
On the M5 timeframe, the EA scans the last 20 candles for:
- Pin bar formations (bullish and bearish)
- Doji patterns indicating indecision
- Bullish and bearish engulfing patterns
- Break of structure signals
- Retracement to key levels

### 3. Signal Validation Phase
When patterns are detected, the EA validates them against:
- Current trend direction
- Proximity to key levels (within 5 pips by default)
- One of the 9 valid trading sequences
- Risk management criteria
- News filter (if enabled)

### 4. Trade Execution Phase
Upon valid signal confirmation:
- Calculate optimal lot size based on risk parameters
- Set stop loss 10 pips from entry (or at confirmation zone)
- Set take profit at 50 pips or next swing level
- Execute trade with appropriate magic number
- Send Telegram notification (if enabled)

### 5. Trade Management Phase
For open positions:
- Monitor trailing stop conditions
- Update stop loss as price moves favorably
- Track overall risk exposure
- Close positions at target levels

## File Structure

```
THEKAYBAMBODLABFX/
├── THEKAYBAMBODLABFX.mq5              # Main EA file
├── PriceActionAnalyzer_Enhanced.mqh    # Enhanced pattern recognition
├── NewsFilter_Version2.mqh             # News filtering system
├── TelegramNotifications.mqh           # Telegram integration
├── RiskManager_Version2.mqh            # Risk management
├── Structs_Version1.mqh                # Data structures
├── EA_Validation_Test.mq5              # Testing script
└── README_THEKAYBAMBODLABFX_EA.md      # This documentation
```

## Best Practices

### 1. Market Conditions
- **Trending markets**: Best performance during clear uptrends or downtrends
- **Range-bound markets**: May generate fewer signals but higher accuracy
- **High volatility**: Adjust pip distances for better performance

### 2. Symbol Selection
- **Major forex pairs**: EUR/USD, GBP/USD, USD/JPY work well
- **Crypto pairs**: Bitcoin and Ethereum pairs supported
- **Metals**: Gold and Silver analysis included

### 3. Risk Management
- Never risk more than 2% of account per trade
- Use appropriate lot sizes for account balance
- Monitor maximum drawdown limits
- Enable trailing stops for trend following

### 4. Optimization
- Test on historical data before live trading
- Adjust parameters based on market conditions
- Monitor performance across different timeframes
- Use news filter during high-impact events

## Telegram Setup

1. Create a Telegram bot:
   - Message @BotFather on Telegram
   - Use `/newbot` command
   - Get your bot token

2. Get your chat ID:
   - Message your bot
   - Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
   - Find your chat ID in the response

3. Configure EA:
   - Set `TelegramBotToken` parameter
   - Set `TelegramChatID` parameter
   - Enable `SendTelegramNotifications`

## Testing and Validation

Use the included `EA_Validation_Test.mq5` script to:
- Test pattern detection accuracy
- Validate level identification
- Check trend analysis functionality
- Verify trading sequence logic

## Support and Maintenance

### Performance Monitoring
- Track win rate and profit factor
- Monitor drawdown levels
- Analyze trade frequency
- Review pattern accuracy

### Regular Updates
- Market condition adjustments
- Pattern recognition improvements
- Risk management enhancements
- New feature additions

## Disclaimer

This EA is for educational and research purposes. Trading forex and CFDs involves substantial risk of loss. Past performance does not guarantee future results. Always test thoroughly on demo accounts before live trading.

## Version History

- **v2.00**: Complete rewrite with advanced price action analysis
- **v1.00**: Basic implementation with simple conditions

---

*Copyright 2024 KAYBAMBODLABFX. All rights reserved.*