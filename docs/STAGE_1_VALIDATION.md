# Stage 1 — Core, Structure and Trend Validation

| Component | Result | Evidence / limitation |
|---|---|---|
| Symbol/timeframe rates and cache | PARTIAL | `EA/Core/MarketData.mqh` keeps bounded per-symbol/timeframe `CopyRates` data, bar timestamps, point/tick/digits helpers. Cache path manually reviewed; no MT5 runtime available. |
| Forex/non-FX price handling | PARTIAL | Uses symbol point, tick size/digits, and `OrderCalcProfit`; cannot validate broker-specific crypto/CFD tick values without a broker terminal. |
| Confirmed swing engine | PASS (static review) | `EA/Market/StructureEngine.mqh` only confirms shifts `>= SwingStrength+1`, uses closed rates, deterministic strict/equality tolerance, age/distance filters and skips ambiguous same-candle high+low pivots. |
| HH/HL/LH/LL storage | PASS (static review) | Retains five latest levels/times per classification and forms comparisons in chronological pivot order. |
| Trend classification | PASS (static review) | Requires configured monotone HH+HL or LH+LL series; partial/conflicting evidence maps to TRANSITION or NEUTRAL. |
| Chart rendering | PARTIAL | Own `KBLX_` labels/arrows; caps swings at 20 and cleans stale objects. Zones/protected-level labels are not rendered. |
| No-look-ahead check | PASS (static review only) | Candidate is excluded until all newer neighboring bars are closed; shift 0 is never used as a pivot-confirmation neighbor. Intrabar price is only used when explicitly selected. This is not a tick-by-tick replay test. |

**Stage 1 conclusion:** Core structural behavior is present in canonical source. No MetaEditor compiler or MT5 data tester is installed in this environment, so this report is not a compile/runtime claim.
