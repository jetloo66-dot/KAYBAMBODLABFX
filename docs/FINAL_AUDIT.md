# Final Audit

## Static compile audit

* MetaEditor/MQL5 compiler and terminal were unavailable. **Compilation is unverified**; no `.ex5` binary is provided.
* A static repository check found 34 input groups, all local quoted include paths resolve, braces are balanced, and no TODO/FIXME/stub markers are present under `EA/`. This is not a substitute for compiler diagnostics.
* Compile-risk APIs to verify in MetaEditor include the broker-calendar functions (`CalendarValueHistory`, `CalendarEventById`), symbol expiration flags, `CTrade::PositionClosePartial`, and local include resolution when installed under `MQL5/Experts`.
* No Strategy Tester, demo execution, profitability, 80% accuracy, or drawdown assertion is claimed.

## Buy/Sell symmetry audit

| Component | Buy | Sell | Symmetrical? |
|---|---|---|---|
| Reversal pivots | LL2 < LH2, then LL1 < LL2 | HH2 > HL2, then HH1 > HH2 | Yes; price/time inequalities mirror |
| BOS/CHOCH break | Close/ask above middle high | Close/bid below middle low | Yes; close/intrabar modes differ only by side quote |
| Liquidity extension | LL1 extends below LL2 | HH1 extends above HH2 | Yes |
| A retracement | Return to LL2 | Return to HH2 | Yes |
| B engulf | Bearish body/wick engulfs bullish candle | Bullish body/wick engulfs bearish candle | Yes |
| C candle zone | Last bullish candle between low pivots | Last bearish candle between high pivots | Yes |
| D Fibonacci | Up retracement from low to break | Down retracement from high to break | Yes; same ratio |
| Trendline gate | Two latest confirmed lows | Two latest confirmed highs | Yes |
| Stops / targets | Below support, target above entry | Above resistance, target below entry | Yes |
| BE/trailing/partials | Stops move upward as price rises | Stops move downward as price falls | Yes; validated only by static review |

## Look-ahead and duplicate-order audits

* Swing pivots require all `SwingStrength` newer neighboring bars to be closed; forming bar 0 is not used to confirm them.
* Close-only BOS uses `rates[1]`. Intrabar mode intentionally uses live Bid/Ask and is not equivalent to a closed-bar confirmation.
* Engulf/retracement candle scanning excludes bar 0. Calendar events are obtained from the native API and never synthesized.
* Setup IDs use symbol, primary period, direction and both reversal pivot timestamps, so they do not change on each later bar. A terminal Global Variable is written after an accepted market/pending operation. Hash collisions are theoretically possible; broker restart/race testing is still required.

## Risk audit

* Position size for percentage/money risk uses `OrderCalcProfit` for a one-lot loss to the proposed stop; volume is floored to broker step and rejected below minimum.
* Price normalization uses tick size and digits. Long protective stops and targets round away from greater risk; short prices mirror the rounding.
* SL checks stop/freeze distance. Pending entries also check order-side geometry and broker expiration support.
* One RR/structure/Fibonacci/manual target is attached. Optional partials occur at R stages; no separate TP1–TP5 order ladder exists.
* Daily limits sum realized deals for this magic and stop new entries only. They do not include floating P/L or close positions.

## Broker compatibility and restart

* Point, digits, tick size, volume min/max/step, filling mode, stop/freeze levels and pending expiration mode are queried rather than hardcoded.
* Broker-specific tick-value calculations, symbol suffix handling, market hours, calendar coverage, hedging/netting mode and partial-close semantics still need validation.
* Position management re-selects positions by magic after restart. Setup IDs persist as terminal Global Variables. Pending-order state is not fully reconstructed, and local CSV records do not capture complete trade lifecycle analytics.

## Backtesting / optimization checklist

- [ ] Compile under the broker's target MetaTrader 5 build.
- [ ] Run Strategy Tester on FX majors, XAUUSD, BTCUSD and at least one CFD with verified symbol properties.
- [ ] Test H1/M15 and several explicitly configured primary/confirmation mappings, including missing-history cases.
- [ ] Cover both long/short structure sequences, equal pivots, skipped bars, gaps, spread spikes and overnight sessions.
- [ ] Test netting and hedging accounts, partial closes, rejected market/limit orders, stops/freeze levels and pending expirations.
- [ ] Test calendar available/unavailable paths and ensure enabled filtering fails closed.
- [ ] Use in-sample, out-of-sample and forward-demo periods; inspect transaction costs, drawdown and expectancy.
- [ ] Verify no future bar is used and no duplicate setup is placed after timer/tick/restart.
- [ ] Do not treat the issue's 80% accuracy/profit objectives as guaranteed acceptance results.

## Acceptance checklist

The issue body did not include the referenced numbered “section 70” checklist. The checklist below mirrors all requirements in the available mission (see IDs R-01–R-32):

| Area | Result | Reason |
|---|---|---|
| Canonical modular native EA and migration notes; legacy retained | PARTIAL | New tree and migration map exist; compiler and broker certification remain |
| Stage 0 requirements/ambiguity/architecture/state/input docs | DONE | Documents added; 34 group labels are explicitly reconstructed because the issue does not name them |
| Stage 1 data, confirmed swings, structure/trend, visualization | PARTIAL | Core algorithms implemented; full visualization and live validation remain |
| Stage 2 reversal, BOS/CHOCH, four retracements, MTF and signal object | PARTIAL | Core path present; lifecycle zones, complete mapping and replay validation remain |
| Stage 3 execution, risk, management, filters, alerts, dashboard | PARTIAL | Basic implementation present; retry, full limits, event coverage and dashboard sections remain |
| Stage 4 memory, analytics, optimization, restart recovery | PARTIAL | CSV and basic performance gate only; complete metrics and pending recovery remain |
| No look-ahead, unique prefix, no hardcoded credential, no MQL4 API in canonical tree | PASS (static review) | See audits above; legacy files are unchanged |
| Compile/backtest/profitability and 80% accuracy evidence | NOT VERIFIED | No MetaEditor/MT5 tester or broker data was available; no performance claim is made |

**Overall:** Deliverable is a documented, modular implementation baseline with explicit gaps, not a claim that every aspirational trading metric has been proven.
