# Input Specification

The issue references 34 optimization groups but does not provide their individual names. The following 34 groups are an explicit reconstruction, not a claim that these headings were supplied verbatim. Units are stated in parameter names; no pip-to-point multiplier is assumed.

| # | Group | Representative parameters | Purpose / default policy | Range and optimization guidance |
|---:|---|---|---|---|
| 1 | `=== GENERAL ===` | `InpAllowTrading=true`, `InpMagicNumber=316316316`, `InpScanSeconds=5` | Master switch, ownership ID, timer cadence | Positive magic; 1–60 seconds |
| 2 | `=== SYMBOLS ===` | `InpSymbols=""`, `InpTradeChartSymbol=true` | Chart symbol by default; optional comma-separated symbols | Broker-specific exact names/suffixes |
| 3 | `=== TIMEFRAMES ===` | `InpPrimaryTF=PERIOD_H1`, `InpConfirmTF=PERIOD_M15` | Primary/confirmation periods | Enumerated supported MT5 periods |
| 4 | `=== DATA ===` | `InpHistoryBars=500`, `InpMaxCacheAgeSeconds=5` | Bounded rate caching and history depth | >= 100; avoid very large scans |
| 5 | `=== SWING ===` | `InpSwingStrength=2`, `InpSwingLookback=200`, `InpMinimumSwingDistancePoints=0`, `InpMaximumSwingAgeBars=100`, `InpEqualSwingTolerancePoints=0` | Pivot qualification | Strength >=1; test per symbol/TF |
| 6 | `=== STRUCTURE ===` | `InpStructureSwings=3` | Required monotone structural sequence | >= 3 |
| 7 | `=== TREND ===` | `InpNeutralOnConflict=true` | Structure-based trend state | No single-candle trend optimization |
| 8 | `=== LIQUIDITY ===` | `InpLiquiditySweepTolerancePoints=0`, `InpRequireSweep=false` | Optional stop-run context | Symbol-specific point ranges |
| 9 | `=== REVERSAL ===` | `InpEnableReversals=true`, `InpSetupMaximumAgeBars=50` | Enable LL2/LH2/LL1 and mirrored pattern | Test timeout after swing-age validation |
| 10 | `=== BOS/CHOCH ===` | `InpBreakConfirmation=CLOSE_ONLY`, `InpBreakSelection=CHOCH_OR_BOS` | Break policy and break classification selection | Enumerated modes; compare close to intrabar |
| 11 | `=== RETRACEMENT A ===` | `InpEnableRetraceA=true`, `InpRetraceATolerancePoints=0` | Return to LL2 / mirrored HH2 | Module-specific point tolerance |
| 12 | `=== RETRACEMENT B ===` | `InpEnableRetraceB=true`, `InpEngulfBodyOnly=true` | Engulfed opposite-color candle zone | Explicit body/wick rule |
| 13 | `=== RETRACEMENT C ===` | `InpEnableRetraceC=true` | Last opposite candle before extreme break | Closed bars only |
| 14 | `=== RETRACEMENT D ===` | `InpEnableRetraceD=true`, `InpFibRatio=0.618` | Fibonacci retracement | 0–1 ratio, conventional levels first |
| 15 | `=== RETRACEMENT COMBINATION ===` | `InpRetraceMode=ANY`, `InpRequiredRetracements=1` | ANY/ALL/FIRST_VALID/PRIORITY/CONFLUENCE_REQUIRED | Count cannot exceed enabled modules |
| 16 | `=== PRIMARY TIMEFRAME GATE ===` | `InpPrimaryGateMode=ANY`, `InpRequirePrimaryGate=false` | Independent primary-TF gate | Disable by default unless explicitly requested |
| 17 | `=== ZONES ===` | `InpZoneBufferPoints=0`, `InpZoneExpiryBars=100` | Demand/supply lifecycle | Symbol point units; finite expiry |
| 18 | `=== FIBONACCI ===` | `InpFibUseWicks=true`, `InpFibRatio2=0.5` | Endpoint and secondary level | Ratios 0–1 |
| 19 | `=== TRENDLINE ===` | `InpTrendlineEnabled=false`, `InpTrendlineWidthPoints=0` | Pivot-connected line zone | Disabled until calibrated |
| 20 | `=== CONFLUENCE ===` | `InpMinimumConfluence=1` | Minimum module score/count | Bound to available signal components |
| 21 | `=== MTF MAPPING ===` | `InpMTFConfirmationMode=SINGLE`, `InpMinimumConfirmations=1` | Explicit eligible confirmation TFs | Single/multiple/all and per-TF weights |
| 22 | `=== EXECUTION ===` | `InpExecutionMode=MARKET_ONLY`, `InpDeviationPoints=10`, `InpRetryCount=1` | Market/pending mode, deviation, bounded retry | Respect broker symbol settings |
| 23 | `=== DUPLICATE PREVENTION ===` | `InpPreventDuplicateSetups=true` | Signal/setup idempotency | Keep enabled |
| 24 | `=== RISK SIZING ===` | `InpSizingMode=RISK_PERCENT`, `InpRiskPercent=0.5`, `InpFixedLots=0.01` | Fixed/risk percent/money/dynamic sizing | Test tick value and volume step |
| 25 | `=== POSITION LIMITS ===` | `InpMaxPositionsTotal=3`, `InpMaxPositionsPerSymbol=3`, `InpMaxPendingOrders=3` | Caps per ownership scope | Nonnegative; test hedging/netting |
| 26 | `=== STOP LOSS ===` | `InpSLMode=ZONE_BASED`, `InpSLDistancePoints=100`, `InpSLATRMultiple=2` | Fixed/zone/swing/ATR/manual/hybrid SL | Distances are points, not pips |
| 27 | `=== TAKE PROFIT ===` | `InpTPMode=RR`, `InpRiskReward=3.0`, `InpTPCount=1` | RR/zone/Fib/manual TP1–TP5 | RR > 0; count 1–5 |
| 28 | `=== PARTIAL PROFITS ===` | `InpPartialTPPercent=0` | Allocation per TP | Cumulative allocation <=100% |
| 29 | `=== BREAK EVEN / TRAILING ===` | `InpBreakEvenEnabled=true`, `InpBreakEvenTriggerR=1`, `InpTrailEnabled=false` | Move to breakeven and trailing | Stops can only improve |
| 30 | `=== PROFIT / LOSS LIMITS ===` | `InpProfitLimitMode=DISABLED`, `InpLossLimitMode=DISABLED` | Period targets and action | Balance/equity reference and reset window |
| 31 | `=== NEWS / SESSION / SPREAD ===` | `InpNewsFilterEnabled=false`, `InpSessionFilterEnabled=false`, `InpMaxSpreadPoints=0` | Calendar, schedule and spread gates | Server timezone and calendar coverage |
| 32 | `=== ALERTS / TELEGRAM ===` | `InpAlertsEnabled=true`, `InpTelegramEnabled=false`, `InpTelegramBotToken=""`, `InpTelegramChatId=""` | Terminal, push and opt-in Telegram alerts | Secrets supplied only in terminal inputs |
| 33 | `=== DASHBOARD / MEMORY / ANALYTICS ===` | `InpDashboardEnabled=true`, `InpMemoryEnabled=true`, `InpPerformanceFilterEnabled=false` | Display and deterministic records/filter | Require sample minimum before filtering |
| 34 | `=== DEBUG ===` | `InpDebug=false`, `InpLogLevel=INFO` | Diagnostics without credential disclosure | Disable verbose output in production |

## Validation rules

Reject or disable invalid combinations at initialization: negative distances/counts, nonpositive risk/lot values, Fibonacci ratios outside `(0,1)`, TP count outside 1–5, partial allocations above 100%, invalid timeframes, or a confluence threshold above the enabled module count. Never clip an invalid stop through the market or increase a risk-based lot to satisfy a broker minimum.
