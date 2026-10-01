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
| R-07 | Optional swing/structure/trend chart visuals under unique prefix | UI | Dashboard | Partial | Bounded swing arrows and trend summary; no per-level zone labels | Object ownership review |
| R-08 | Buy reversal LL2→LH2→LL1; mirrored Sell | Strategy | Reversal | Implemented | Ordered pivots with strict mirrored inequalities | Static symmetry review |
| R-09 | Configurable close/intrabar BOS/CHOCH and selectable confirmation | Strategy | BOS/CHOCH | Partial | Break classification derives from current structure; both mode tracks each event per setup | State logic review; tester unavailable |
| R-10 | Four independently configurable retracement modules A–D | Strategy | Retracement A-D | Partial | A–D implemented as level/candle-zone/Fib touches; candle semantics are deterministic | Symmetry and boundary review |
| R-11 | ANY/ALL/FIRST_VALID/PRIORITY/CONFLUENCE_REQUIRED | Strategy | Retracement combination | Partial | Modes select from enabled modules; ALL means all configured module conditions pass | Branch review |
| R-12 | Primary gate using Fib/zone/trendline | Strategy | Primary gate, zones, Fibonacci, trendline | Partial | ANY/ALL across available gate components; no zone invalidation/mitigation tracking | Condition review |
| R-13 | Configurable primary-to-confirmation map and weighted MTF | Strategy | Timeframes, MTF | Partial | Up to three explicit distinct confirmation TFs with weights and single/multiple/all modes | Mapping/threshold review |
| R-14 | Lifecycle-managed demand/supply/Fib/trendline/retracement zones | Strategy/UI | Zones | Partial | Setup zone and pending expiry implemented; lifecycle mitigation and charted zone set are not | State review |
| R-15 | Structured analytical signal with unique ID and setup context | Strategy | Confluence, duplicate prevention | Implemented | Stable symbol/TF/direction/pivot-based ID and signal context | ID review |
| R-16 | Trade modes, validation, retry and retcode logging | Execution | Execution, order types | Partial | `CTrade`, broker stop/freeze/volume/expiration checks and rejection logs; no retry loop | Static review |
| R-17 | Duplicate prevention across events/restarts | Execution/Analytics | Duplicate prevention, restart | Partial | Terminal global setup key; terminal positions are managed after restart; no explicit pending-state reconstruction | Global-variable/position review |
| R-18 | Fixed/risk-percent/risk-money/dynamic sizing | Risk | Risk sizing | Partial | Fixed, percent and money sizing via `OrderCalcProfit`; dynamic currently aliases percent | Formula review |
| R-19 | Limits total/direction/symbol/setup | Risk/Execution | Position limits | Partial | Total, per-symbol and pending limits for this magic; no direction/setup-specific caps | Ownership/count review |
| R-20 | SL modes and TP1–TP5 | Risk | Stop loss, take profit | Partial | Fixed/zone/swing/ATR/manual/hybrid SL, one configured target mode and optional R-stage partial closes | Formula review |
| R-21 | Partial allocations, break-even and trailing | Management | Partial profits, break-even/trailing | Partial | R-stage percent partials, BE and tightening trailing; account-mode behavior needs tester verification | Monotonic stop review |
| R-22 | Period profit/loss limits and action | Risk | Profit/loss limits | Partial | Realized server-day P/L stops new entries; no other windows or close-existing action | Boundary review |
| R-23 | Native economic-calendar filter | Filters | News | Implemented (unverified) | High-impact base/quote calendar lookup; no fabricated events; lookup failure blocks entry | Broker calendar/tester verification unavailable |
| R-24 | Session, day and spread filters | Filters | Session/spread | Implemented | Server-time, overnight-aware session and configurable days/spread gate | Static boundary review |
| R-25 | Alert, push and Telegram | Alerts | Alerts | Partial | Signal alerts; configurable credentials; no event-complete trade lifecycle alert suite | Secret scan and API setup requirement |
| R-26 | Status/market/structure/setup/trade/performance dashboard | UI | Dashboard | Partial | Own-prefixed status and structure label plus swing arrows | Chart-object review |
| R-27 | Trade memory, analytics and performance filter | Analytics | Memory, performance filter | Partial | Local close-deal CSV and minimum-sample symbol/magic win-rate gate; no MFE/MAE/R or per-session analytics | File/state review |
| R-28 | Optimization bounds/no future-data leakage | Core, Strategy, Risk | All optimization inputs | Partial | Input guards and confirmed-bar calculations; several broker scenarios still need validation | Static audit |
| R-29 | New-bar analysis, cache, bounded history, released handles | Core/EA | Data, debug | Partial | Timer/new-bar analysis, cached bounded rates, no indicator handles created | Call-path review |
| R-30 | Preserve earlier-stage features in later stages | All | All | Implemented in source scope | Stage reports record retained features and explicit gaps | Cross-stage static review |
| R-31 | Migration guide; retain legacy files | Repository | N/A | Implemented | `MIGRATION_NOTES.md`; legacy files untouched | Git scope review |
| R-32 | Honest validation/profitability claims | Docs | Debug | Implemented | Audit states compiler/tester/profitability limitations | Final audit |

## Scope notes

The issue provides functional requirements but does not enumerate the purported 34 input-group names, all alert event names, or the numbered “section 70” acceptance checklist. `INPUT_SPECIFICATION.md` therefore defines 34 transparent, inferred groups from the supplied requirements; it does not claim these were supplied verbatim. This matrix records the full requirements available in the issue body.
