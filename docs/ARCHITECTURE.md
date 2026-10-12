# Architecture

## Canonical source tree

```text
EA/
  KAYBAMBODLABFX.mq5             EA entry point and grouped user inputs
  Core/Types.mqh                 enums, settings-facing value objects, signal types
  Core/MarketData.mqh            bounded rate cache, symbol metadata, new-bar clock
  Market/StructureEngine.mqh     confirmed pivots, typed swing history, trend state
  Market/ContextEngine.mqh       local pivot demand/supply and tick-volume price bins
  Strategy/SignalEngine.mqh      reversal sequence, close break and LL2/HH2 retracement
  Filters/TradingFilters.mqh     sessions, spread, trading days, economic calendar
  Risk/RiskManager.mqh           sizing, volume normalization, SL/TP and limits
  Execution/TradeExecutor.mqh    CTrade validation, duplicate guard, order submission
  Management/PositionManager.mqh break-even, trailing and partial close management
  Alerts/AlertEngine.mqh         terminal/push/Telegram notifications
  UI/Dashboard.mqh               uniquely-prefixed chart objects
  Analytics/TradeMemory.mqh      deterministic trade journal and performance metrics
docs/
  REQUIREMENTS_MATRIX.md, AMBIGUITY_REGISTER.md, ARCHITECTURE.md,
  STATE_MACHINE.md, INPUT_SPECIFICATION.md, STAGE_1_VALIDATION.md,
  STAGE_2_VALIDATION.md, STAGE_3_VALIDATION.md, STAGE_4_VALIDATION.md,
  FINAL_AUDIT.md, EA_TESTING_GUIDE.md
MIGRATION_NOTES.md
```

## Modules and ownership

| Module | Responsibility | Depends on |
|---|---|---|
| Entry EA | Inputs, seven-frame cache orchestration, context gates and execution cadence | All modules |
| Core types | Direction, structure, zone, setup/signal value records | None |
| Market data | `MqlRates` retrieval/cache, symbol tick properties, bar timestamps | Core types |
| Structure | Pivots with confirmation time, HH/HL/LH/LL histories, trend classification | Core types, market data |
| Context engine | Confirmed pivot-candle zones and approximate typical-price tick-volume node | Core types, structure, market data |
| Signal strategy | Reversal sequence, closed-bar break, pivot-edge retracement and optional modules | Core types, structure, market data |
| Filters | Session/day/spread/news eligibility | Core types, market data/calendar API |
| Risk | Volume and protective levels/limits | Core types, symbol properties |
| Execution | CTrade send/cancel, validation and idempotency | Core types, risk, filters |
| Management | Open-position stop and partial-profit maintenance | Execution, risk |
| Alerts/UI | Notifications and own-prefixed chart objects | Core types |
| Analytics | Completed-position local journal and optional setup-aware win-rate gate | Core types, terminal trade history |

The expected dependency direction is entry → orchestration/services → value types; strategy does not send orders. Strategy emits an analytical `Signal`; execution consumes a validated signal. Risk and filters can veto execution but do not alter structural classification.

## Data contracts

* `SwingPoint`: type, price, pivot time, confirmation time, source bar shift.
* `StructureSnapshot`: ordered recent highs/lows, HH/HL/LH/LL histories, trend state, protected levels.
* `Zone`: type, low/high, creation/expiry time, mitigation and invalidation state.
* `Signal`: stable setup ID, symbol, direction/timeframe, three pivot prices/times, break type/time, retracement time, zone and score.
* `MarketContext`: local demand/supply candle zones, approximate tick-volume node, average volume and structure trend.
* `TradeRecord`: position ID, close time, symbol/magic, entry setup tag and net realized result; execution-cost/MFE/MAE fields are not currently collected.

## Execution cadence

1. Initialization validates inputs and configures execution, market-data, management, alert and timer services.
2. Each scan updates seven selected structure/context frames on new bars, then evaluates configured entry frames.
3. Optional tick path re-evaluates the bounded historical setup and current retracement quote; timer path scans when tick scanning is disabled.
4. Before order send, filters, duplicate guard, limits, risk sizing, price/volume and broker stop/freeze rules are rechecked.
5. Trade transactions update completed-position memory when enabled. Magic-number positions are managed; chart objects use the `KBLX_` prefix.

## Stage status

Architecture is the target separation. Stage validation reports identify what is implemented and verified; a design diagram is not evidence of compilation or broker execution.
