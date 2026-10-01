# Advanced Zone Structure EA for MT5

## Overview

The **Advanced Zone Structure EA** is a sophisticated multi-phase Expert Advisor that combines:
- **Zone Detection**: Support/resistance areas based on fractal pivots
- **Market Structure Analysis**: HH, HL, LH, LL identification
- **Candle Pattern Recognition**: Pin bars, engulfing, inside bars
- **Multi-Strategy Entry Logic**: Three distinct trading strategies
- **Advanced Trade Management**: Dynamic SL/TP, trailing stop, break-even
- **Comprehensive Risk Management**: Position limits, daily loss caps, filters

## Key Features

### ✅ Phase-Based Architecture
- **Phase 1**: Zone Detection & Management
- **Phase 2**: Market Structure Analysis
- **Phase 3**: Candle Pattern Recognition
- **Phase 4**: Signal Generation (3 Strategies)
- **Phase 5**: Trade Management
- **Phase 6**: Risk & Position Management

### ✅ Three Trading Strategies

**Strategy A: Zone Touch + Structure**
- Buy: Price at support + HH/HL formation
- Sell: Price at resistance + LH/LL formation

**Strategy B: BOS + Retracement**
- Entry after Break of Structure
- Waits for retracement to structure levels

**Strategy C: Pattern + Zone Confluence**
- Pin bars or engulfing patterns at zones
- High confluence requirement

### ✅ Advanced Features
- Top 3 support/resistance zones tracked
- Last 10 structure points stored
- Confluence scoring system (0-100)
- Dynamic SL/TP based on zones
- Break-even and trailing stop
- Session and day-of-week filters
- Daily loss limit protection
- Spread filtering
- One trade per bar option

## Installation

1. Download `AdvancedZoneStructureEA.mq5`
2. Copy to: `MetaTrader 5/MQL5/Experts/`
3. Restart MT5 or refresh Navigator
4. Find "AdvancedZoneStructureEA" in Expert Advisors list

## Quick Start

### Basic Setup
1. Drag EA onto chart (H1 recommended)
2. Allow AutoTrading
3. Set basic parameters:
   - **LotSize**: 0.01 or 0.1
   - **SLPoints**: 100
   - **TPPoints**: 300
   - **MinConfluenceScore**: 70

### Recommended Settings for Beginners

```
=== ZONE DETECTION ===
ZoneLookbackBars = 100
ZoneFractalRadius = 2
ZoneMinTouches = 2

=== STRUCTURE ANALYSIS ===
StructureSwingBars = 5
RequireHLForBuy = true
RequireLHForSell = true

=== PATTERN DETECTION ===
EnablePinBars = true
EnableEngulfing = true
PinBarRatio = 0.66

=== ENTRY LOGIC ===
EnableStrategyA = true
EnableStrategyB = true
EnableStrategyC = true
MinConfluenceScore = 70

=== TRADE MANAGEMENT ===
LotSize = 0.01
SLPoints = 100
TPPoints = 300
UseDynamicSL = true
UseDynamicTP = true
RiskRewardRatio = 3.0
TrailingStopPoints = 50
BreakEvenPoints = 150

=== RISK MANAGEMENT ===
MaxPositions = 2
MaxDailyLossPercent = 5.0
MaxSpreadPoints = 30
OneTradePerBar = true
```

## Parameter Guide

### Zone Detection Parameters

| Parameter | Description | Range | Default |
|-----------|-------------|-------|---------|
| ZoneLookbackBars | Bars to scan for zones | 50-200 | 100 |
| ZoneFractalRadius | Fractal detection radius | 2-5 | 2 |
| ZoneMinTouches | Min touches for valid zone | 2-5 | 2 |
| ZoneThicknessPoints | Zone thickness in points | 20-100 | 50 |
| ZoneRecalcBars | Recalc zones every N bars | 1-20 | 5 |
| ZoneProximityPoints | Price proximity to zone | 5-50 | 10 |

### Structure Analysis Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| StructureSwingBars | Bars for swing detection | 5 |
| RequireHHForBuy | Require HH for buy signals | false |
| RequireHLForBuy | Require HL for buy signals | true |
| RequireLHForSell | Require LH for sell signals | true |
| RequireLLForSell | Require LL for sell signals | false |

### Pattern Detection Parameters

| Parameter | Description | Range | Default |
|-----------|-------------|-------|---------|
| EnablePinBars | Enable pin bar detection | - | true |
| EnableEngulfing | Enable engulfing detection | - | true |
| PinBarRatio | Pin bar wick/body ratio | 0.5-0.8 | 0.66 |
| EngulfingRatio | Engulfing size ratio | 1.0-1.5 | 1.1 |
| RequirePatternAtZone | Pattern must form at zone | - | true |

### Entry Logic Parameters

| Parameter | Description | Range | Default |
|-----------|-------------|-------|---------|
| EnableStrategyA | Zone Touch + Structure | - | true |
| EnableStrategyB | BOS + Retracement | - | true |
| EnableStrategyC | Pattern + Zone Confluence | - | true |
| MinConfluenceScore | Min confluence score (0-100) | 50-90 | 70 |

### Trade Management Parameters

| Parameter | Description | Range | Default |
|-----------|-------------|-------|---------|
| LotSize | Fixed lot size | 0.01-10 | 0.1 |
| UseRiskPercent | Use % risk position sizing | - | false |
| RiskPercent | Risk per trade (%) | 0.5-5 | 1.0 |
| SLPoints | Stop loss in points | 50-200 | 100 |
| TPPoints | Take profit in points | 100-500 | 300 |
| UseDynamicSL | SL based on zone/pattern | - | true |
| UseDynamicTP | TP based on next zone | - | true |
| RiskRewardRatio | Risk:Reward ratio | 1.5-5.0 | 3.0 |
| TrailingStopPoints | Trailing stop distance | 20-100 | 50 |
| BreakEvenPoints | Profit to trigger BE | 50-200 | 150 |
| BreakEvenOffsetPoints | BE offset | 5-20 | 10 |

### Risk Management Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| MaxPositions | Max open positions | 3 |
| MaxDailyLossPercent | Max daily loss % | 5.0 |
| MaxSpreadPoints | Max allowed spread | 30 |
| OneTradePerBar | One signal per bar | true |
| TradeOnNewBarOnly | Trade only on new bar | true |

## Understanding Confluence Scoring

The EA calculates a confluence score (0-100) for each signal:

- **Zone Strength**: 0-30 points
  - Based on touches, recency, and age
  
- **Structure Alignment**: 0-25 points
  - HH/HL for buys, LH/LL for sells
  
- **Pattern Strength**: 0-25 points
  - Pin bars: 70, Engulfing: 80, Inside: 40
  
- **Trend Direction**: 0-10 points
  - Uptrend for buys, downtrend for sells
  
- **Recent Touches**: 0-10 points
  - Recent touches increase score

**Minimum Score**: Only trades with score ≥ MinConfluenceScore execute

## Visualization

### On-Chart Display

**Support Zones**: Blue rectangles
**Resistance Zones**: Red rectangles

**Structure Points**:
- HH: Green "HH" label
- HL: Light Green "HL" label
- LH: Orange "LH" label
- LL: Red "LL" label

**Info Panel** (top-left):
- Current trend
- Zone strengths
- Open positions
- Daily loss

## Optimization Guide

### Recommended Approach

1. **Single Strategy First**
   - Enable only Strategy A initially
   - Optimize for 3-6 months
   - Note best parameters

2. **Add Other Strategies**
   - Enable Strategy B or C
   - Test independently
   - Combine best performers

3. **Key Parameters to Optimize**
   - ZoneLookbackBars
   - StructureSwingBars
   - MinConfluenceScore
   - SLPoints / TPPoints
   - RiskRewardRatio
   - TrailingStopPoints

4. **Optimization Targets**
   - Profit Factor ≥ 1.5
   - Sharpe Ratio ≥ 1.0
   - Max Drawdown < 20%
   - Win Rate ≥ 45%

### Forward Testing

After optimization:
- Forward test on next 3 months
- Demo test for 2+ weeks
- Monitor performance metrics
- Adjust if necessary

## Trading Tips

### Best Practices

1. **Start Small**: Use micro lots (0.01) initially
2. **One Strategy**: Test strategies individually first
3. **Demo First**: Always test on demo before live
4. **Monitor Closely**: Watch first 10-20 trades carefully
5. **Adjust Parameters**: Optimize for your symbol/timeframe
6. **Regular Review**: Re-optimize quarterly or after major market changes

### Symbol/Timeframe Recommendations

**Forex Majors** (EURUSD, GBPUSD, USDJPY):
- Timeframe: H1 or H4
- ZoneLookbackBars: 100-150
- MinConfluenceScore: 70-80

**Forex Minors**:
- Timeframe: H4 or D1
- ZoneLookbackBars: 80-120
- MinConfluenceScore: 75-85

**Indices** (US30, NAS100):
- Timeframe: M15 or H1
- ZoneLookbackBars: 150-200
- MinConfluenceScore: 65-75

## Risk Warning

⚠️ **Trading involves substantial risk of loss**

- Never risk more than you can afford to lose
- Past performance does not guarantee future results
- Always use proper risk management
- Start with demo account
- Monitor your trades regularly
- Use stop losses always

## Support & Updates

- **Version**: 1.0
- **Release Date**: 2024-12-16
- **Author**: KAYBAMBODLABFX
- **License**: For personal use

## Changelog

### Version 1.0 (2024-12-16)
- Initial release
- Three entry strategies implemented
- Full zone and structure analysis
- Pattern recognition system
- Advanced trade management
- Comprehensive risk controls
- Visualization features

## FAQ

**Q: Why no trades?**
A: Check confluence score threshold, increase lookback bars, or verify zones are being detected.

**Q: Too many trades?**
A: Increase MinConfluenceScore, enable OneTradePerBar, or reduce enabled strategies.

**Q: Large drawdown?**
A: Reduce lot size, enable UseRiskPercent, set stricter risk limits.

**Q: Zones not showing?**
A: Enable ShowZones, check ZoneMinTouches requirement.

**Q: How to improve win rate?**
A: Optimize parameters, use higher confluence scores, test single strategies.

---

**Happy Trading! 📈**

*Remember: This EA is a tool. Your success depends on proper testing, risk management, and ongoing monitoring.*
