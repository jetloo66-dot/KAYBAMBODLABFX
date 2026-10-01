# Buy and Sell State Machines

The Sell machine is the price/direction mirror of Buy. All market-structure transitions require confirmed closed-bar swings unless the explicitly selected intrabar mode is active. A candidate is invalidated rather than silently reused when an invalidation condition occurs.

| State | Buy condition / next transition | Sell mirror / next transition | Invalidations |
|---|---|---|---|
| `IDLE` | Wait for two confirmed lower lows (`LL2` and a lower `LL1`) with an intervening lower high `LH2`; then `REVERSAL_ARMED` | Two confirmed higher highs with intervening higher low; then `REVERSAL_ARMED` | History too old, data unavailable |
| `REVERSAL_ARMED` | Validate `LL1 < LL2 < LH2`; record protected structure and wait for upward break | Validate `HH1 > HH2 > HL2`; record protected structure and wait for downward break | New extreme extends reversal pattern, stale setup, configured age expires |
| `BREAK_PENDING` | Selected close/intrabar break of `LH2`; classify as CHOCH/BOS from prior trend; then `BREAK_CONFIRMED` | Break below `HL2`; classify symmetrically | Break fails/close returns inside (close mode), protected extreme breaks |
| `BREAK_CONFIRMED` | Evaluate retracement modules A–D and primary-TF gate | Evaluate mirrored modules A–D and gate | Opposite structural invalidation, zone expiry, setup timeout |
| `RETRACE_WAIT` | Any/all/priority policy selects a valid touch of LL2/zone/Fib/trendline; then `SIGNAL_READY` | Mirrored touch of HH2/zone/Fib/trendline; then `SIGNAL_READY` | Price closes beyond invalidation edge, zone mitigated beyond policy, signal timeout |
| `SIGNAL_READY` | Require MTF weight/count, filters, risk, limits and unique setup ID; then `EXECUTION_PENDING` | Same checks for Sell | Any gate fails; duplicate signal; data becomes stale |
| `EXECUTION_PENDING` | Validated CTrade operation accepted; then `POSITION_OPEN` | Same for Sell | Invalid quote/volume/stops, retry budget exhausted, rejected retcode |
| `POSITION_OPEN` | Manage SL, TP, partials, break-even/trailing; close → `COMPLETE` | Same mirrored management | Broker/terminal closes position; loss/profit limit action |
| `COMPLETE` | Persist result, notify, retain ID against duplicate re-entry; then `IDLE` for a new setup | Same for Sell | Record is not rewritten; new setup needs new ID |

## Deterministic event rules

* A setup ID includes symbol, primary timeframe, direction, pivot times and break confirmation time. Repeated timer/tick evaluations of the same setup cannot create a new ID.
* Only a close-based break can promote `BREAK_PENDING` using a closed candle. Intrabar mode may promote while quote is beyond the level and is documented as less conservative.
* A level/zone touch means candle-range intersection with the configured tolerance; merely approaching the zone does not pass.
* The setup expires after `SetupMaximumAgeBars` (when enabled) or any explicit structural invalidation. Expiry never rolls back an already opened position.
* Execution failure does not count as a completed trade; retries use bounded attempts and preserve the same ID.
* Both directions share the same transition logic with a signed direction factor; only inequalities and candle color are mirrored.
