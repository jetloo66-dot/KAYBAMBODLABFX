# Stage 2 — Reversal, BOS/CHOCH, Retracement and MTF Validation

| Component | Result | Evidence / limitation |
|---|---|---|
| Buy LL2→LH2→LL1 and Sell mirror | PASS (static review) | Uses ordered confirmed pivot times; Buy requires LL1<LL2<LH2 and Sell requires HH1>HH2>HL2. |
| BOS/CHOCH | PARTIAL | Break level is the intervening pivot; classification follows current primary trend. Close/intrabar/either and filters exist. AND mode tracks both labels per setup; replay validation is unavailable. |
| Retracement A | PASS (static review) | Closed-bar touch of LL2/HH2 within point tolerance. |
| Retracement B | PARTIAL | Opposite-color body/wick engulf zone is symmetric and excludes forming bars; it is a deterministic candle-zone approximation, not multi-candle engulf logic. |
| Retracement C | PARTIAL | Uses the latest opposite-color closed candle between extreme pivots; exact phrase “before LL2 break” remains an interpretation. |
| Retracement D | PARTIAL | Fib touch supports wick/body anchors and configured ratio; extension and endpoint semantics need strategy tester calibration. |
| Combination policy | PARTIAL | ANY, ALL, first/priority and required-count paths exist. No statistical confluence calibration is provided. |
| Primary gate / zone | PARTIAL | Fib, candle zone and pivot trendline components can be combined ANY/ALL. Zones have expiry and pending expiry; mitigation/invalidation tracking is absent. |
| MTF | PARTIAL | Supports three explicitly selected confirmation periods, independent structures, single/multiple/all policies and weights. There is no automatic timeframe-map table by primary period; user supplies the periods. |
| Signal object / duplicate ID | PASS (static review) | Analytical signal carries setup pivots, direction, TFs, break, selected retracement, zone, score and stable pivot-derived ID. |
| Stage 1 regression | PASS (static review) | Stage 1 source remains unchanged in behavior; compile/runtime regression cannot be performed here. |

**Stage 2 conclusion:** A symmetric analytical signal path is implemented. No profitability/accuracy rate is claimed; all strategy outcomes remain to be tested on broker data.
