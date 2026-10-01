# Architecture

## Canonical source tree

```text
EA/
  KAYBAMBODLABFX.mq5             EA entry point and grouped user inputs
  Core/Types.mqh                 enums, settings-facing value objects, signal types
  Core/MarketData.mqh            bounded rate cache, symbol metadata, new-bar clock
  Market/StructureEngine.mqh     confirmed pivots, typed swing history, trend state
  Strategy/SignalEngine.mqh      reversal, BOS/CHOCH, retracement, MTF signal analysis
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
  FINAL_AUDIT.md
MIGRATION_NOTES.md
```

## Modules and ownership

| Module | Responsibility | Depends on |
|---|---|---|
| Entry EA | Inputs, initialization, timer/tick separation, orchestration | All modules |
| Core types | Direction, structure, zone, setup/signal value records | None |
| Market data | `MqlRates` retrieval/cache, symbol tick properties, bar timestamps | Core types |
| Structure | Pivots with confirmation time, HH/HL/LH/LL histories, trend classification | Core types, market data |
| Signal strategy | Reversal sequence, breaks, four retracements, primary gate, MTF confluence | Core types, structure, market data |
| Filters | Session/day/spread/news eligibility | Core types, market data/calendar API |
| Risk | Volume and protective levels/limits | Core types, symbol properties |
| Execution | CTrade send/cancel, validation and idempotency | Core types, risk, filters |
| Management | Open-position stop and partial-profit maintenance | Execution, risk |
| Alerts/UI | Notifications and own-prefixed chart objects | Core types |
| Analytics | Durable local trade records and summary statistics | Core types, terminal trade history |

The expected dependency direction is entry → orchestration/services → value types; strategy does not send orders. Strategy emits an analytical `Signal`; execution consumes a validated signal. Risk and filters can veto execution but do not alter structural classification.

## Data contracts

* `SwingPoint`: type, price, pivot time, confirmation time, source bar shift.
* `StructureSnapshot`: ordered recent highs/lows, HH/HL/LH/LL histories, trend state, protected levels.
* `Zone`: type, low/high, creation/expiry time, mitigation and invalidation state.
* `Signal`: stable setup ID, symbol, direction, primary/confirmation TFs, break type/level, chosen retracement, zone, score, timestamp.
* `TradeRecord`: setup context, execution costs, stop/target, realized result, MFE/MAE, R multiple and duration.

## Execution cadence

1. Initialization validates inputs, loads symbol metadata, initializes trade/UI services, and reconciles existing positions/orders.
2. `OnTimer`/new-bar path refreshes bounded market data, then structure, trend, zones and analytical signals once per configured timeframe bar.
3. Tick path manages existing positions and handles selected intrabar-entry policy; it does not rescan full history.
4. Before order send, filters, duplicate guard, limits, risk sizing, price/volume and broker stop/freeze rules are rechecked.
5. Trade transactions update memory and alerts. EA-owned objects and magic-number positions are the only resources managed.

## Stage status

Architecture is the target separation. Stage validation reports identify what is implemented and verified; a design diagram is not evidence of compilation or broker execution.
