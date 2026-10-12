# Buy and Sell Setup Lifecycle

The implementation re-derives the candidate from bounded historical rates on each scan; these named states describe its chronological lifecycle, not persisted in-memory enum states. The Sell path mirrors Buy.

| State | Buy condition / next transition | Sell mirror / next transition | Invalidation |
|---|---|---|---|
| `IDLE` | Wait for confirmed LL2, intervening LH2 and later LL1 with `LL1 < LL2 < LH2` | Confirm HH2, intervening HL2 and later HH1 with `HH1 > HH2 > HL2` | Missing/insufficient rates or no valid pivots |
| `REVERSAL_ARMED` | Sequence must satisfy the strict inequalities and maximum-age limit | Mirrored strict inequalities and maximum-age limit | Pivot age expires or optional sweep threshold fails |
| `BREAK_PENDING` | Find a closed-bar cross above LH2 after LL1 | Find a closed-bar cross below HL2 after HH1 | No qualifying close cross or selected BOS/CHOCH type does not match |
| `BREAK_CONFIRMED` | Search only after the break for a return to LL2 candle low within tolerance | Search only after the break for a return to HH2 candle high within tolerance | Setup-age limit, zone-touch absent, or optional confluence fails |
| `RETRACE_CONFIRMED` | Validate timeframe/context gates, P&L/news/session/spread, memory and duplicate filters | Same checks on Sell context | Any required gate rejects |
| `EXECUTION` | Submit configured market/limit operation with validated stops, target and size | Same mirrored order logic | Broker rejects or position/order cap blocks |
| `POSITION_OPEN` | Manage configured R-stage partials, break-even and trailing | Same mirrored management | Position closes by broker, SL/TP or user |
| `COMPLETE` | Record completed position outcome when memory is enabled | Same for Sell | New pivot-time setup ID required for another entry |

## Deterministic event rules

* Swings use closed bars only; the structure engine confirms a pivot after `SwingStrength` newer closed bars.
* Break detection uses closed-bar crossing above the middle high/below the middle low. Entry retracement is tick-confirmed by default and must occur after the break.
* A buy entry tests LL2 candle low; a sell tests HH2 candle high. Configured tolerance is expressed in points and the signal is mirrored.
* Setup IDs use symbol, timeframe, direction and LL2/HH2 and LL1/HH1 pivot times. Duplicate suppression is persisted in terminal Global Variables after accepted execution.
* Candidate state is reconstructed rather than persisted. No bounded retry loop, full pending-order recovery or broker-certified transition behavior is claimed.
