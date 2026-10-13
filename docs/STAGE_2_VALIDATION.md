# Stage 2 — Reversal, BOS/CHOCH, Retracement and MTF Validation

| Component | Result | Evidence / limitation |
|---|---|---|
| Buy LL2→LH2→LL1 and mirrored Sell sequence | PASS (static review) | Swings are chronological; strict inequalities are `LL1 < LL2 < LH2` and `HH1 > HH2 > HL2`. |
| Closed-bar break confirmation | PASS (static review) | Detects a close cross of LH2/HL2 after the last extreme; shift 0 is not used for break confirmation. |
| BOS/CHOCH labels | PARTIAL | Break classification uses the established structure direction. BOS-only and CHOCH-only are selectable; the unsupported AND choice is rejected. |
| Retracement A | PASS (static review) | Requires a later tick/closed range to reach LL2 candle low or HH2 candle high within configured point tolerance. |
| Optional retracement B–D | PARTIAL | Engulf zone, opposite candle zone and Fib touch are selectable and mirrored; semantics are deterministic but need replay testing. |
| Seven configurable timeframes | PASS (static review) | D1/H4/H1/M30/M15/M5/M1 each have scan/context and entry switches with independent structure state. |
| Higher-frame zone and MTF rules | PARTIAL | H4-to-M1 demand/supply gates, independent scans, trend alignment modes and per-frame weights are wired. Exact broker/timeframe behavior is untested. |
| Signal metadata and duplicate ID | PASS (static review) | Signal carries pivots, break type/time, retrace time/zone and stable symbol/timeframe/direction/pivot-derived ID. |
| Stage 1 regression | PASS (static review) | Confirmed-swing and structure algorithms remain wired; runtime regression is unavailable. |

**Stage 2 conclusion:** The core sequence and post-break entry lifecycle is present in source. MQL5 compilation and chronological Strategy Tester replay remain required; no trading performance is asserted.
