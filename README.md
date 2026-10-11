# KAYBAMBODLABFX

## SMC_MultiTF_EA.mq5

This repository now includes `SMC_MultiTF_EA.mq5`, a native MetaTrader 5 Expert Advisor that implements a configurable Smart Money Concept multi-timeframe workflow.

### Install

1. Copy `SMC_MultiTF_EA.mq5` from this repository into your MT5 `MQL5/Experts/` folder.
2. Open it in MetaEditor and compile.
3. Attach the EA to a chart in MT5 and allow Algo Trading.
4. If Telegram alerts are enabled, add `https://api.telegram.org` to MT5 WebRequest allowed URLs.

### Strategy overview

- Detects swing highs/lows, pivots, and fractal-style turning points using configurable left/right bars.
- Evaluates mirrored bullish and bearish SMC structure:
  - Buy: `LL2 -> LH2 -> LL1`, then CHOCH/BOS close above `LH2`
  - Sell: `HH2 -> HL2 -> HH1`, then CHOCH/BOS close below `HL2`
- Supports three entry modes:
  - `SMC_MODE_A`: breakout / immediate momentum with optional next-candle rejection confirmation
  - `SMC_MODE_B`: clean retrace into the structure zone with rejection confirmation
  - `SMC_MODE_C`: retrace mode with Fibonacci confluence
- Runs the same logic across 5 configurable timeframes and trades only when confluence reaches `InpMinConfluence`.
- Draws numbered structure points, CHOCH/BOS, retrace labels, structure lines, demand/supply rectangles, and active SL/TP/partial-profit levels.

### Key configurable inputs

- Timeframes: `InpTimeframeD1`, `InpTimeframeH4`, `InpTimeframeH1`, `InpTimeframeM15`, `InpTimeframeM5`
- Structure engine: `InpPivotLeftBars`, `InpPivotRightBars`, `InpBarsToScan`
- Confluence / mode: `InpMinConfluence`, `InpUseGlobalMode`, `InpGlobalMode`, per-timeframe mode inputs
- Risk: `InpLotSize`, `InpUseRiskPercent`, `InpRiskPercent`, `InpSL_OffsetPoints`, `InpRiskRewardMultiplier`
- Management: partial close, break-even, trailing stop, max open positions, magic number
- Filters / alerts: MT5 calendar news filter, Telegram, push, native alerts
- Visualization: dashboard position, colors, line widths, all-timeframe drawing toggle

### Notes

- High-volatility symbols listed in `InpPointBasedSymbols` use point-based offsets; standard FX symbols use pip-style offsets derived from broker digits.
- News blocking uses the MT5 economic calendar and checks high-impact events around the current server time.
