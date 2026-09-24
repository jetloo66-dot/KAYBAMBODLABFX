# KAYBAMBODLABFX MT5 Expert Advisor

This repository now includes a modular, native **MetaTrader 5 Expert Advisor** implementation:

- `KAYBAMBODLABFX_MT5_ProductionEA.mq5`
- `KAYB_Models.mqh`
- `KAYB_Config.mqh`
- `KAYB_Utils.mqh`
- `KAYB_StructureEngine.mqh`
- `KAYB_SetupEngines.mqh`
- `KAYB_ExecutionRisk.mqh`
- `KAYB_Filters.mqh`
- `KAYB_AlertsDashboard.mqh`
- `KAYB_TradeMemory.mqh`

## What it implements

- Six concurrent workflow slots with per-workflow on/off and configurable analysis/confirmation timeframe pairs.
- Closed-candle swing structure state, BOS/CHOCH checks, and symmetric buy/sell reversal + continuation signal engines.
- Reversal filters (a-d) with **ANY / ALL / PRIORITY** combination mode.
- Market and optional pending limit execution with symbol-aware distance handling:
  - Forex-style symbols: pip-aware handling.
  - High-volatility symbols (e.g., XAU/BTC style): point mode (or AUTO).
- Configurable SL/TP buffer, RR (default 1:3), break-even, trailing, and partial close trigger.
- Safeguards: spread, stop-level checks, max positions/pending caps, session filter.
- Economic calendar news blackout (with graceful fallback when data is unavailable).
- Profit/loss throttles across minute/hour/session/day in percent or money mode.
- On-chart dashboard, chart objects for zone/entry/SL/TP, and terminal/push/email/Telegram alerts.
- Deterministic trade-memory CSV persistence (Common Files) and optional memory score filter.

## Install

1. Copy all `.mq5`/`.mqh` files into your MT5 `MQL5/Experts` folder (or a subfolder preserving relative includes).
2. Open `KAYBAMBODLABFX_MT5_ProductionEA.mq5` in MetaEditor.
3. Compile and attach the EA to a chart.

## Telegram / WebRequest setup

If using Telegram alerts:

1. In MT5: **Tools → Options → Expert Advisors**.
2. Enable **Allow WebRequest for listed URL**.
3. Add: `https://api.telegram.org`.
4. Set `InpAlertTelegram=true` and configure:
   - `InpTelegramBotToken`
   - `InpTelegramChatId`

## Notification setup

- `InpAlertTerminal` for terminal alerts.
- `InpAlertPush` requires MT5 push configuration in terminal options.
- `InpAlertEmail` requires MT5 SMTP configuration in terminal options.

## Optimization guidance

Start optimization with:

- Workflow toggles/timeframes (`InpWF*Enabled`, `InpWF*AnalysisTF`, `InpWF*ConfirmTF`)
- Swing/structure inputs (`InpSwingLookback`, `InpStructureLookbackBars`, `InpSwingToleranceUnits`)
- Reversal filters (`InpFilter*`, `InpFilterCombinationMode`, `InpFilterD_UseFib618`)
- Risk/management (`InpUseRiskPercent`, `InpRiskPercent`, `InpStopBufferUnits`, `InpRR`)
- Trade limits (`InpMaxPositions`, `InpMaxPendingOrders`, `InpProfitTarget*`, `InpLossLimit*`)

## Backtesting notes and limitations

- This implementation is designed to avoid look-ahead by using closed-candle confirmation paths.
- MT5 Economic Calendar availability depends on terminal/account connectivity and broker support.
- The EA includes deterministic trade-memory statistics only; it does **not** do autonomous model training.
- Compile and run final verification in MetaEditor/MT5 Strategy Tester for your broker environment.
- No strategy can guarantee profits or “100% accuracy.” Use risk controls and validate thoroughly with your broker’s symbol specifications.
