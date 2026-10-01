# Stage 3 — Execution, Risk, Management, Filters and UI Validation

| Component | Result | Evidence / limitation |
|---|---|---|
| Market/limit execution | PARTIAL | Uses synchronous `CTrade`, market, limit, auto and market-plus-limit paths. No retry loop or stop-order variant; retcodes are checked/logged. |
| Order validation | PARTIAL | Validates price, tick/digits, stop/freeze distance, volume step, expiration capability, spread and configured limits; terminal/broker execution has not been tested. |
| Duplicate setups | PASS (static review) | Persistent terminal-global setup key based on symbol/timeframe/direction and both reversal pivot times; opened positions are selected by magic. |
| Risk sizing | PARTIAL | Fixed lots, risk percent and risk money use `OrderCalcProfit`; `DYNAMIC_RISK` currently aliases risk-percent sizing. Below-minimum volume is rejected, never rounded up. |
| Position limits | PARTIAL | Total/per-symbol positions and per-symbol pending counts; no buy/sell-side or per-setup cap. |
| SL/TP | PARTIAL | Fixed/zone/swing/ATR/manual/hybrid SL, RR/structure/Fibonacci/manual TP and R-stage partials. Only one broker TP is placed per position. |
| BE/trailing/partials | PARTIAL | Break-even and trailing only tighten. R-stage partial percent is bounded by input validation. Netting/hedging-specific partial-close behavior needs terminal testing. |
| Period targets | PARTIAL | Realized server-day P/L stops new trades; no hourly/minute/session windows, equity target, close-existing or alert-only modes. |
| News/session/spread | PARTIAL | Native high-impact calendar for base/quote currency, server-time day/session and spread checks. Calendar coverage and Strategy Tester support are broker-dependent; enabled lookup errors fail closed. |
| Alerts | PARTIAL | Signal alerts to MT5, optional push and opt-in Telegram. Not all fills, modifications, partials, rejections and close events have dedicated notifications. Token/chat values are runtime-only and excluded from logs/UI. |
| Dashboard | PARTIAL | Status and structure label plus bounded pivot arrows with own object prefix. Not all requested dashboard sections/zones/performance are shown. |
| Stage 1–2 regression | PASS (static review) | No prior-stage source was removed; cannot execute an MT5 regression backtest here. |

**Stage 3 conclusion:** Basic order/risk/position management is in place, but this is not a broker-certified production release. Validate on a demo account before any live use.
