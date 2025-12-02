# Swing Detection EA - Quick Start Guide

## 5-Minute Setup

### Step 1: Install Files (1 minute)
Copy these files to your MT5 data folder:
```
MQL5/Experts/
├── SwingDetectionEA.mq5          (Main EA)
├── SwingDetection.mqh             (Swing logic)
├── SignalGenerator.mqh            (Signal generation)
├── SupportResistance.mqh          (S/R tracking)
├── TelegramNotifier.mqh           (Notifications)
├── ChartVisualization.mqh         (Chart drawing)
└── ErrorHandler.mqh               (Error management)
```

**Find Data Folder:**
- MT5 → File → Open Data Folder → MQL5 → Experts

### Step 2: Enable Telegram (30 seconds)
1. MT5 → Tools → Options → Expert Advisors
2. Check ☑ "Allow WebRequest for listed URL:"
3. Add: `https://api.telegram.org`
4. Click OK

### Step 3: Compile EA (30 seconds)
1. Press F4 to open MetaEditor
2. Open `SwingDetectionEA.mq5`
3. Press F7 to compile
4. Check for "0 errors" message

### Step 4: Attach to Chart (1 minute)
1. Open EURUSD chart (any timeframe)
2. Press F7 to enable AutoTrading (button should be green)
3. Navigator → Expert Advisors → SwingDetectionEA
4. Drag EA to chart

### Step 5: Configure Settings (2 minutes)

**Minimal Configuration:**
```
=== Trade Management ===
Lot Size: 0.01 (start small!)
Stop Loss: 10 pips
Take Profit: 30 pips
Max Trades Per Symbol: 1 (initially)

=== Symbol Settings ===
Trade EURUSD: true
All others: false (start with one symbol)

=== Telegram Notifications ===
Enable Telegram: true
Bot Token: YOUR_BOT_TOKEN_HERE
Chat ID: YOUR_CHAT_ID_HERE
```

Click OK and you're done! 🚀

## What Happens Next?

### Immediate Actions
- EA starts scanning every 5 minutes
- You'll see chart comment with EA statistics
- Swing points will appear on chart
- Telegram notifications will arrive

### First Signal
When conditions align:
1. **Signal Detected** → Telegram notification
2. **Trade Executed** → Telegram notification with details
3. **Chart Updated** → Buy/sell arrow and trade box appear

### Monitoring
Watch for:
- 📊 Chart comment (top-left): Real-time stats
- 📱 Telegram: All trade events
- 📝 Log file: Detailed operation log
- ✅ MT5 Experts tab: Status messages

## Common Settings

### Conservative (Low Risk)
```
Lot Size: 0.01
Max Trades Per Symbol: 1
Risk Percent: 0.5%
Max Daily Loss: 2%
Symbols: EURUSD only
```

### Moderate (Balanced)
```
Lot Size: 0.1
Max Trades Per Symbol: 2
Risk Percent: 1%
Max Daily Loss: 5%
Symbols: EURUSD, GBPUSD, USDJPY
```

### Aggressive (High Risk)
```
Lot Size: 0.5
Max Trades Per Symbol: 3
Risk Percent: 2%
Max Daily Loss: 10%
Symbols: All major pairs
```

## Quick Checklist

Before Live Trading:
- [ ] Tested on demo account for 2+ weeks
- [ ] Reviewed and understand all parameters
- [ ] Set appropriate lot size for your account
- [ ] Configured risk limits (stop loss, daily loss)
- [ ] Verified Telegram notifications working
- [ ] Checked EA stats on chart
- [ ] Read the full README
- [ ] Have sufficient account balance (min $100 for micro lots)

## Key Parameters Explained

| Parameter | What It Does | Recommended |
|-----------|--------------|-------------|
| Lot Size | Trade volume | 0.01-0.1 |
| Stop Loss | Risk per trade | 10-20 pips |
| Take Profit | Profit target | 20-40 pips |
| Trailing Start | When to trail | 10 pips |
| Max Trades/Symbol | Trade limit | 1-3 |
| Scan Interval | Check frequency | 5 minutes |

## Strategy Summary

**What EA Does:**
1. Analyzes H1 for swing structure (HH, HL, LH, LL)
2. Confirms with M5 timeframe
3. Waits for oversold (buy) or overbought (sell)
4. Detects break of structure
5. Enters on retracement
6. Manages with trailing stop

**When It Trades:**
- ✅ Clear swing structure exists
- ✅ Stochastic + Bollinger confirm
- ✅ Break of structure detected
- ✅ Retracement to entry zone
- ✅ All filters pass

## Troubleshooting

### EA Not Starting?
```
Check:
1. AutoTrading enabled (F7, green button)
2. EA shows smiley face in top-right
3. No errors in Experts tab
4. Symbol trading hours active
```

### No Trades?
```
Normal! EA waits for:
- Perfect setup alignment
- May take hours/days
- Check chart comment for status
- Verify symbols enabled
```

### No Telegram Messages?
```
1. Check URL allowed in settings
2. Verify bot token correct
3. Test internet connection
4. Check chat ID correct
```

## Support

Need help?
1. Check `SwingEA_SYMBOL_Log.txt` for detailed logs
2. Review MT5 Experts tab for messages
3. Read full README for details
4. Test on demo first!

## Performance Expectations

**Realistic Goals:**
- Win Rate: 50-70%
- Profit Factor: 1.5-2.5
- Trades per Week: 5-20 (varies)
- Monthly Return: 5-15% (varies)

**Remember:**
- Not every day has trades
- Losing streaks happen
- Past ≠ future performance
- Demo test first!

---

**Ready to Start?** Follow Steps 1-5 above! 🎯

**Questions?** Read the full README for comprehensive documentation.

**Happy Trading!** 📈💰
