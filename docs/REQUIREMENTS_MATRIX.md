# Requirements Matrix

Status describes the actual canonical source in `EA/`, not the legacy root-level EAs. `Implemented` means code is present and statically reviewed; no MetaEditor build or Strategy Tester run was available.

| ID | Requirement | Module | Inputs | State | Implementation approach | Validation |
|---|---|---|---|---|---|---|
| R-01 | Native modern MQL5 EA using trade/position/order APIs | EA entry, Execution | General, execution | Implemented (uncompiled) | One `.mq5` entry point, modular `.mqh` files, `CTrade`; no MQL4 order calls in canonical tree | Static include/API review; MetaEditor compile unavailable |
| R-02 | Cache symbol/timeframe rates and detect new bars | Core/Data | Symbols, timeframes, data | Implemented | Bounded `CopyRates` cache, per-symbol/timeframe bar timestamp | Static cache/shift review |
| R-03 | Tick/point/digits/tick-value support for FX, metals, crypto and CFDs | Core/Data, Risk | Symbols, risk | Implemented | Query symbol properties; `OrderCalcProfit` and volume step, never assume pip scale | Dimensional/static review; broker test unavailable |
| R-04 | Deterministic confirmed swings, configurable strength/lookback/distance/age/equal tolerance | Market/Structure | Swing | Implemented | Closed-rate pivot confirmation; reject too-young pivots and filter equal/near pivots | No-look-ahead review |
| R-05 | Three-pivot HH/HL uptrend and mirrored LL/LH downtrend sequences | Market/Structure | Structure | Implemented | Retain ordered typed swings and require monotone sequences | Static comparison review |
| R-06 | UPTREND/DOWNTREND/NEUTRAL/TRANSITION trend state | Market/Structure | Trend | Implemented | Derive classification from confirmed structure | State logic review |
| R-07 | Optional swing/setup/context/SL/TP chart visuals under unique prefix | UI | Dashboard | Implemented (static review) | Swing arrows and accepted setup pivot numbers, BOS/CHOCH, retrace connector, zones, SL and final TP are drawn | Object ownership review; chart test unavailable |
| R-08 | Buy reversal LL2→LH2→LL1; mirrored Sell | Strategy | Reversal | Implemented | Ordered confirmed pivots with strict mirrored inequalities; labels identify the three points | Static symmetry review |
| R-09 | Closed-bar break above LH2/below HL2; configurable BOS/CHOCH selection | Strategy | BOS/CHOCH | Partial | Historical closed-rate crossing is detected after LL1/HH1; type derives from structure trend. AND selection is rejected | Chronology and close-cross review; tester unavailable |
| R-10 | Retracement to LL2 low / HH2 high after break | Strategy | Retracement A | Implemented (static review) | Current quote must touch the pivot candle's low (buy) or high (sell) after a closed-bar break | Shift/order/tolerance review |
| R-11 | ANY/ALL/FIRST_VALID/PRIORITY/CONFLUENCE_REQUIRED | Strategy | Retracement combination | Partial | Modes select from enabled modules; ALL means all configured module conditions pass | Branch review |
| R-12 | Primary gate using Fib/zone/trendline | Strategy | Primary gate, zones, Fibonacci, trendline | Partial | ANY/ALL across available gate components; no zone invalidation/mitigation tracking | Condition review |
| R-13 | Configurable D1/H4/H1/M30/M15/M5/M1 contexts and weighted MTF | Strategy | Timeframes, MTF | Partial | Seven configurable frames have separate structure/context caches and entry switches; weighted structure-trend alignment gates MTF modes | Timeframe/caching review; tester unavailable |
| R-14 | Demand/supply and highest tick-volume price zones | Market/UI | Context | Partial | Confirmed pivot candle zones plus bounded typical-price tick-volume bins; not exchange-grade volume profile | Static bin/pivot review |
| R-15 | Structured analytical signal with unique ID and setup context | Strategy | Confluence, duplicate prevention | Implemented | Stable symbol/TF/direction/pivot-based ID and signal context | ID review |
| R-16 | Trade modes, validation, retry and retcode logging | Execution | Execution, order types | Partial | `CTrade`, broker stop/freeze/volume/expiration checks and rejection logs; no retry loop | Static review |
| R-17 | Duplicate prevention across events/restarts | Execution/Analytics | Duplicate prevention, restart | Partial | Terminal global setup key; terminal positions are managed after restart; no explicit pending-state reconstruction | Global-variable/position review |
| R-18 | Fixed/risk-percent/risk-money/dynamic sizing | Risk | Risk sizing | Partial | Fixed, percent and money sizing via `OrderCalcProfit`; dynamic currently aliases percent | Formula review |
| R-19 | Limits total/direction/symbol/setup | Risk/Execution | Position limits | Partial | Total, per-symbol and pending limits for this magic; no direction/setup-specific caps | Ownership/count review |
| R-20 | Configurable SL and TP1–TP5 R ladder | Risk | Stop loss, take profit | Partial | SL supports fixed/zone/swing/ATR/manual/hybrid; final broker TP uses configured final R/other mode; intermediate R levels trigger partials | Formula review; broker execution unverified |
| R-21 | Partial allocations, break-even and trailing | Management | Partial profits, break-even/trailing | Partial | R-stage partial closes, BE and tightening trailing; netting/hedging behavior requires tester verification | Monotonic stop review |
| R-22 | Minute/hour/session/day profit and loss limits | Risk | Profit/loss limits | Partial | Realized server-time window P/L limits block new entries; open positions are not force-closed | Boundary review |
| R-23 | Native economic-calendar filter | Filters | News | Implemented (unverified) | High-impact base/quote calendar lookup; no fabricated events; lookup failure blocks entry | Broker calendar/tester verification unavailable |
| R-24 | Session, day and spread filters | Filters | Session/spread | Implemented | Server-time, overnight-aware session and configurable days/spread gate | Static boundary review |
| R-25 | Alert, push and Telegram | Alerts | Alerts | Partial | Accepted signal alerts via terminal, optional push and Telegram; no complete lifecycle/TP-ladder notifications | Secret scan and API setup requirement |
| R-26 | Status/market/structure/setup/trade dashboard | UI | Dashboard | Partial | Own-prefixed trend/status, pivots, break/retrace connector, context zones, SL/TP; no full account statistics | Chart-object review |
| R-27 | Trade memory and setup-aware performance gate | Analytics | Memory, performance filter | Partial | Completed-position CSV outcomes tagged by entry direction/timeframe; deterministic sample/win-rate gate; no model training or full expectancy metrics | File/history review |
| R-28 | Optimization bounds/no future-data leakage | Core, Strategy, Risk | All optimization inputs | Partial | Input guards and confirmed-bar calculations; several broker scenarios still need validation | Static audit |
| R-29 | Tick scans, cache, bounded history, released handles | Core/EA | Data, debug | Implemented (static review) | Optional per-tick scans plus timer fallback, seven-frame cached rates, no indicator handles created | Call-path review |
| R-30 | Preserve earlier-stage features in later stages | All | All | Implemented in source scope | Stage reports record retained features and explicit gaps | Cross-stage static review |
| R-31 | Migration guide; retain legacy files | Repository | N/A | Implemented | `MIGRATION_NOTES.md`; legacy files untouched | Git scope review |
| R-32 | Honest validation/profitability claims | Docs | Debug | Implemented | Audit states compiler/tester/profitability limitations | Final audit |

## Scope notes

The issue provides functional requirements but does not enumerate the purported 34 input-group names, all alert event names, or the numbered “section 70” acceptance checklist. `INPUT_SPECIFICATION.md` therefore defines 34 transparent, inferred groups from the supplied requirements; it does not claim these were supplied verbatim. This matrix records the full requirements available in the issue body.
