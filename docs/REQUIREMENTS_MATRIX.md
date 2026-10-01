# Requirements Matrix

Status describes the intended canonical implementation in `EA/`, not the legacy root-level EAs.

| ID | Requirement | Module | Inputs | State | Implementation approach | Validation |
|---|---|---|---|---|---|---|
| R-01 | Native modern MQL5 EA using trade/position/order APIs | EA entry, Execution | General, execution | Planned | One `.mq5` entry point, modular `.mqh` files, `CTrade`; no MQL4 order calls | MetaEditor compile when available; static API review |
| R-02 | Cache symbol/timeframe rates and detect new bars | Core/Data | Symbols, timeframes, data | Planned | Bounded `CopyRates` cache, per-symbol/timeframe bar timestamp | Review shift handling; repeated-call/cache inspection |
| R-03 | Tick/point/digits/tick-value support for FX, metals, crypto and CFDs | Core/Data, Risk | Symbols, risk | Planned | Query symbol properties; use tick size/value and volume step, never assume pip scale | Formula review against symbol properties |
| R-04 | Deterministic confirmed swings, configurable strength/lookback/distance/age/equal tolerance | Market/Structure | Swing | Planned | Closed-rate pivot confirmation; reject too-young pivots and filter equal/near pivots | No-look-ahead audit; deterministic tie tests by inspection |
| R-05 | Three-pivot HH/HL uptrend and mirrored LL/LH downtrend sequences | Market/Structure | Structure | Planned | Retain ordered, typed swing history and require strict monotonic sequences | Sequence review; Buy/Sell symmetry audit |
| R-06 | UPTREND/DOWNTREND/NEUTRAL/TRANSITION trend state | Market/Structure | Trend | Planned | Derive state from confirmed structure; transition on opposing break/invalid structure | State table review |
| R-07 | Optional swing/structure/trend chart visuals under unique prefix | UI | Dashboard | Planned | Own prefixed chart objects only; cap/redraw only changed objects | Object-name and cleanup review |
| R-08 | Buy reversal LL2→LH2→LL1 where LL1 < LL2 < LH2; mirrored Sell | Strategy | Reversal | Planned | Explicit ordered swing pattern and mirrored comparisons | Symmetry table and scenario review |
| R-09 | Configurable close/intrabar BOS/CHOCH and selectable confirmation logic | Strategy | BOS/CHOCH | Planned | Break opposing confirmed swing; classify BOS with trend, CHOCH against trend | Break-level and close/intrabar review |
| R-10 | Four independently configurable retracement modules A–D | Strategy | Retracement A-D | Planned | Return-to-LL2, engulfed candle, pre-break candle, fib level; mirror all prices | Algorithm review and symmetry table |
| R-11 | Retracement combinations ANY/ALL/FIRST_VALID/PRIORITY/CONFLUENCE_REQUIRED | Strategy | Retracement combination | Planned | Deterministic module evaluation and selection in declared order | Branch/state review |
| R-12 | Primary timeframe gate using Fib/zone/trendline conditions | Strategy | Primary gate, zones, Fibonacci, trendline | Planned | Independently evaluate gate and combine by selected mode | Condition matrix review |
| R-13 | Configurable primary-to-confirmation timeframe map and weighted MTF decision | Strategy | Timeframes, MTF | Planned | Explicit eligibility mapping, score/count threshold and no implicit adjacent-TF assumptions | Mapping table and threshold review |
| R-14 | Lifecycle-managed demand/supply/Fib/trendline/retracement zones | Strategy/UI | Zones | Planned | Bounded zones, expiry, invalidation and mitigation states | Lifecycle transition review |
| R-15 | Structured analytical signal with unique ID and setup context | Strategy | Confluence, duplicate prevention | Planned | Signal carries side, TFs, structural state, retracement, zone, score and time | ID determinism and duplicate-check review |
| R-16 | Trade execution modes, validation, retry policy and retcode logging | Execution | Execution, order types | Planned | `CTrade`, symbol stops/freeze/volume/spread checks; bounded retries | Static review; broker demo required |
| R-17 | Prevent duplicate signal/order/position after repeated events or restart | Execution/Analytics | Duplicate prevention, restart | Planned | Derive setup ID and reconcile terminal positions/orders during initialization | Restart-state review and duplicate audit |
| R-18 | Fixed/risk-percent/risk-money/dynamic position size | Risk | Risk sizing | Planned | Risk cash divided by loss-per-lot derived from tick value/size; normalize volume | Dimensional analysis and broker demo |
| R-19 | Position/order limits total, direction, symbol and setup | Risk/Execution | Position limits | Planned | Count only this EA's magic/symbol as applicable; enforce before send | Count/filter review |
| R-20 | Fixed/zone/swing/ATR/manual/hybrid SL and TP1–TP5 | Risk | Stop loss, take profit | Planned | Calculate prices from signal geometry; validate broker minimums and RR | Price rounding and risk audit |
| R-21 | Partial TP allocations capped at 100%; break-even and trailing never worsen SL | Management | Partial profits, break-even/trailing | Planned | Track position volume/TP state and only tighten protective stops | Monotonic stop review; live demo required |
| R-22 | Period profit/loss limits with configurable action | Risk | Profit/loss limits | Planned | Period-start balance/equity references and stop/close/alert action | Boundary/reset review |
| R-23 | Native economic-calendar filter with no fabricated events | Filters | News | Planned | Query calendar where broker data is available; fail closed only when configured | Calendar availability and tester limitations documented |
| R-24 | Overnight-aware sessions, trading-day, spread filters | Filters | Session/spread | Planned | Server-time windows and configurable day/spread gates | Midnight boundary review |
| R-25 | Alerts, push and Telegram using configurable credentials | Alerts | Alerts | Planned | `Alert`, optional push and WebRequest; never hardcode/log credentials | Secret scan and WebRequest response review |
| R-26 | Dashboard with status, market, structure, setup, trade and performance | UI | Dashboard | Planned | Own-prefixed chart labels, redraw on changed content | Chart-object ownership review |
| R-27 | Deterministic trade memory, performance analytics and optional sample-gated filter | Analytics | Memory, performance filter | Planned | Record setup/outcome metrics, explicitly not ML; disabled-by-default threshold filter | Record-field and sample-gate review |
| R-28 | Optimization bounds and no future-data leakage | Core, Strategy, Risk | All optimization inputs | Planned | Clamp/validate parameter combinations and use only confirmed bars | Static audit and tester checklist |
| R-29 | New-bar analysis, cached indicators, bounded history and released handles | Core/EA | Data, debug | Planned | Separate analysis cadence from tick-time position management | Call-path and resource review |
| R-30 | Preserve all earlier-stage features through Stages 2–4 | All | All | Planned | Regression checks listed in each stage report | Cross-stage checklist |
| R-31 | Migration guide; retain legacy files | Repository | N/A | Planned | Add mapping in `MIGRATION_NOTES.md`; no legacy deletion | `git status` scope review |
| R-32 | Honest compile/test/profitability claims | Docs | Debug | Planned | Report lack of MetaEditor/tester where applicable; no performance guarantee | Final audit against available tools |

## Scope notes

The issue provides functional requirements but does not enumerate the purported 34 input-group names, all alert event names, or the numbered “section 70” acceptance checklist. `INPUT_SPECIFICATION.md` therefore defines 34 transparent, inferred groups from the supplied requirements; it does not claim these were supplied verbatim. This matrix records the full requirements available in the issue body.
