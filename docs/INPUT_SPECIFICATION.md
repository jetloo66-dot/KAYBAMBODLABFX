# Input Specification

The issue references 34 input groups but does not supply their individual names. These are the 34 implemented group names reconstructed from its functional requirements; they are not represented as verbatim user-provided headings. Units are explicit: point distances are symbol points, not “pips.”

| # | Group | Input (default) | Purpose, valid range and optimization guidance |
|---:|---|---|---|
| 1 | `=== GENERAL ===` | `InpAllowTrading=true`; `InpMagicNumber=316316316`; `InpScanSeconds=5` | Master switch, position ownership, timer interval. Magic >0; interval 1–60s. Keep live trading off while validating. |
| 2 | `=== SYMBOLS ===` | `InpSymbols=""`; `InpTradeChartSymbol=true` | Comma-separated broker symbols (up to 32) plus chart symbol if enabled. Empty list uses chart symbol. Match broker suffixes exactly. |
| 3 | `=== TIMEFRAMES ===` | `InpPrimaryTF=H1`; `InpConfirmTF=M15`; `InpConfirmTF2=CURRENT`; `InpConfirmTF3=CURRENT` | Primary structure and up to three distinct confirmation frames. Confirmation periods must differ from primary and each other. |
| 4 | `=== DATA ===` | `InpHistoryBars=500`; `InpMaxCacheAgeSeconds=5` | Bounded history and rate-cache freshness. History 50–10,000; cache age >=0 (0 refreshes on every request). |
| 5 | `=== SWING ===` | `InpSwingStrength=2`; `InpSwingLookback=200`; `InpMinimumSwingDistancePoints=0`; `InpMaximumSwingAgeBars=100`; `InpEqualSwingTolerancePoints=0` | Pivot shape, search depth, price-separation, age and equality tolerance. Strength >=1; lookback >=2×strength+2; age 0 disables expiry, otherwise >strength. Tune per instrument/TF. |
| 6 | `=== STRUCTURE ===` | `InpStructureSwings=3` | Required consecutive monotone same-type swing classifications, 3–5. Larger values reduce signals; test with adequate history. |
| 7 | `=== TREND ===` | `InpUseStructureTrend=true` | Classify trend from market structure. False forces neutral classification; it does not disable the reversal rule. |
| 8 | `=== LIQUIDITY ===` | `InpRequireLiquiditySweep=false`; `InpLiquiditySweepTolerancePoints=0` | Require the LL/HH extension to meet a minimum sweep distance in points. Nonnegative; test against symbol tick size. |
| 9 | `=== REVERSAL ===` | `InpEnableReversals=true`; `InpSetupMaximumAgeBars=50` | Enable the symmetric three-pivot reversal and expire old extremes. Age >=1. |
| 10 | `=== BOS/CHOCH ===` | `InpBreakConfirmation=CLOSE_ONLY`; `InpBreakSelection=CHOCH_OR_BOS` | Close/intrabar/either break and CHOCH-only/BOS-only/either/both policy. Close-only is the conservative baseline; “both” requires both break classifications within one setup. |
| 11 | `=== RETRACEMENT A ===` | `InpEnableRetraceA=true`; `InpRetraceATolerancePoints=5` | Enable return to LL2/HH2; point tolerance >=0. |
| 12 | `=== RETRACEMENT B ===` | `InpEnableRetraceB=true`; `InpEngulfBodyOnly=true` | Engulfed opposite candle zone, using body bounds when true and wick bounds otherwise. |
| 13 | `=== RETRACEMENT C ===` | `InpEnableRetraceC=true` | Last opposite candle before the extreme/structure break. |
| 14 | `=== RETRACEMENT D ===` | `InpEnableRetraceD=true`; `InpFibRatio=0.618`; `InpFibUseWicks=true` | Fib retracement module and swing endpoint selection. Ratio strictly between 0 and 1; compare wick/body anchors out of sample. |
| 15 | `=== RETRACEMENT COMBINATION ===` | `InpRetraceMode=ANY`; `InpRequiredRetracements=1` | ANY, ALL, first valid, priority or minimum confluence. Required count 1–4 and no greater than enabled modules. |
| 16 | `=== PRIMARY TIMEFRAME GATE ===` | `InpRequirePrimaryGate=false`; `InpPrimaryGateMode=ANY` | Optional primary timeframe Fib/zone/trendline gate, combining available components with ANY or ALL. |
| 17 | `=== ZONES ===` | `InpZoneBufferPoints=5`; `InpZoneExpiryBars=100` | Add tolerance to zones and expire pending setups/orders. Buffer >=0; expiry >=1. |
| 18 | `=== FIBONACCI ===` | `InpSecondaryFibRatio=0.5` | Independent primary-gate Fibonacci ratio, strictly between 0 and 1. |
| 19 | `=== TRENDLINE ===` | `InpTrendlineEnabled=false`; `InpTrendlineWidthPoints=10` | Pivot-connected trendline gate and width in points. Width >=0; disabled until calibrated. |
| 20 | `=== CONFLUENCE ===` | `InpMinimumConfluenceScore=0` | Minimum weighted score across matching confirmations; >=0. Scores are rule counts/weights, not predicted accuracy. |
| 21 | `=== MTF MAPPING ===` | `InpMTFMode=SINGLE`; `InpMinimumConfirmations=1`; `InpConfirmationWeight=1`; `InpConfirmationWeight2=1`; `InpConfirmationWeight3=1` | Select one, a threshold of, or all enabled confirmation TFs. Threshold 1–3; weights >=0. TFs are configured explicitly in group 3. |
| 22 | `=== EXECUTION ===` | `InpExecutionMode=MARKET_ONLY`; `InpDeviationPoints=10` | Market, pending, both, or automatic limit selection; allowed deviation >=0 points. Broker filling/expiration constraints are checked. |
| 23 | `=== DUPLICATE PREVENTION ===` | `InpPreventDuplicateSetups=true` | Persist deterministic setup IDs in terminal global variables; leave enabled. |
| 24 | `=== RISK SIZING ===` | `InpSizingMode=RISK_PERCENT`; `InpFixedLots=0.01`; `InpRiskPercent=0.5`; `InpRiskMoney=50` | Fixed, account-risk-percent, or risk-money sizing. Lots >0; risk inputs >=0. `DYNAMIC_RISK` currently follows percentage sizing. |
| 25 | `=== POSITION LIMITS ===` | `InpMaxPositionsTotal=3`; `InpMaxPositionsPerSymbol=3`; `InpMaxPendingOrders=3` | Limits positions and pending orders for this magic. Position limits >=1; pending >=0. |
| 26 | `=== STOP LOSS ===` | `InpStopMode=ZONE_BASED`; `InpStopDistancePoints=100`; `InpStopBufferPoints=10`; `InpManualStopPrice=0`; `InpStopATRPeriod=14`; `InpStopATRMultiplier=2` | Fixed, zone, swing, ATR, manual or hybrid stops. Distances >=0; ATR period >=1 and multiplier >0; manual price must be protective when selected. |
| 27 | `=== TAKE PROFIT ===` | `InpTakeProfitMode=RR`; `InpRiskReward=3`; `InpTakeProfitCount=1`; `InpManualTakeProfitPrice=0`; `InpFibonacciExtension=1.618` | RR, structure, Fibonacci or manual target; RR >0; count 1–5; Fib extension >0; manual price must be beyond entry when selected. Current implementation attaches one TP; count additionally sets R-level partial-close stages. |
| 28 | `=== PARTIAL PROFITS ===` | `InpPartialClosePercent=0` | Percent closed at each enabled intermediate R stage. 0–100 and `(count−1)×percent <=100`; disabled by default. |
| 29 | `=== BREAK EVEN / TRAILING ===` | `InpBreakEvenEnabled=true`; `InpBreakEvenTriggerR=1`; `InpBreakEvenOffsetPoints=0`; `InpTrailingEnabled=false`; `InpTrailingStartPoints=100`; `InpTrailingDistancePoints=50`; `InpTrailingStepPoints=10` | Protective stop management. Trigger >0 R; point distances >=0. Stops only tighten; test symbol stop/freeze rules. |
| 30 | `=== PROFIT / LOSS LIMITS ===` | `InpSessionProfitLimitMoney=0`; `InpSessionLossLimitMoney=0` | Zero disables. Nonzero values stop new entries when this magic’s realized server-day P/L crosses the limit; no forced close. |
| 31 | `=== NEWS / SESSION / SPREAD ===` | `InpNewsFilterEnabled=false`; `InpNewsMinutesBefore=30`; `InpNewsMinutesAfter=30`; `InpSessionFilterEnabled=false`; `InpSessionStartHour=0`; `InpSessionEndHour=23`; `InpMaximumSpreadPoints=0`; `InpTradeMonday`…`InpTradeSunday` (weekdays true, weekends false) | Native high-impact calendar blackout, server-time window/day filter and spread cap. Times 0–23; 0 spread disables. Calendar failure blocks entry when enabled. |
| 32 | `=== ALERTS / TELEGRAM ===` | `InpAlertsEnabled=true`; `InpPushNotificationsEnabled=false`; `InpTelegramEnabled=false`; `InpTelegramBotToken=""`; `InpTelegramChatId=""` | Entry alerts, optional push/Telegram. Configure secrets only in terminal inputs and allowlist `https://api.telegram.org` in MT5; credentials are not logged or drawn. |
| 33 | `=== DASHBOARD / MEMORY / ANALYTICS ===` | `InpDashboardEnabled=true`; `InpDrawSwings=true`; `InpTradeMemoryEnabled=true`; `InpPerformanceFilterEnabled=false`; `InpPerformanceMinimumSample=30`; `InpPerformanceMinimumWinRate=50` | Own-prefixed display, local CSV trade log and optional symbol/magic closed-deal win-rate filter. Sample >=1; win-rate 0–100%. |
| 34 | `=== DEBUG ===` | `InpDebug=false` | Enables limited data/setup diagnostics; never prints Telegram credentials. |

## Initialization validation

The EA rejects invalid timeframes, duplicate confirmation periods, negative distances, impossible partial allocation, out-of-range Fibonacci ratios, or incompatible MTF thresholds. Risk sizing rounds down to broker volume steps and refuses a below-minimum result rather than raising risk. A broker tester run is still required to validate symbol-specific inputs.
