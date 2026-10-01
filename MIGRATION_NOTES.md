# Migration Notes

The canonical implementation is `EA/KAYBAMBODLABFX.mq5`. Copy the complete `EA/` folder into the terminal's `MQL5/Experts/KAYBAMBODLABFX/` folder while preserving its subdirectories; compile and test there before enabling live trading. Add `https://api.telegram.org` to MT5's allowed WebRequest URLs only if Telegram is enabled. Supply token/chat ID through EA inputs; never commit them.

No legacy source was deleted or modified in this change. After the canonical EA has been compiled, reviewed and independently backtested, the following root-level files are candidates for removal by a later, separately reviewed cleanup:

| Legacy file(s) | Replaced by / migration note |
|---|---|
| `KAYBAMBODLABFX.mq5`, `KAYBAMBODLABFX_MultiStrategy_EA.mq5`, `PrecisionStructureEA_Final.mq5`, `RegimeBasedSMCStrategyEA.mq5`, `THEKAYBAMBODLABFX.mq5` | `EA/KAYBAMBODLABFX.mq5`; do not assume every legacy option or experimental regime feature is preserved |
| `StructureBasedEA_v1.0.mq5`, `StructureBasedEA_Complete_v2.0.mq5`, `StructureBasedEA_Production_v3.0.mq5` | `EA/Market/StructureEngine.mqh` + `EA/Strategy/SignalEngine.mqh`; old versions are templates/stubs |
| `GlobalVariables_Version1.mqh`, `GlobalVariables_Version1 (1).mqh` | `EA/Core/Types.mqh`, `EA/Core/MarketData.mqh`; the two legacy files were byte-identical |
| `IndicatorManager_Version1.mqh` | No indicator-manager dependency in canonical build; rate cache is `EA/Core/MarketData.mqh` |
| `LogManager_Version1.mqh` | Standard terminal logging in the canonical services; legacy includes refer to differently named files |
| `MarketScanner_Version2.mqh` | Symbol loop is in `EA/KAYBAMBODLABFX.mq5` |
| `NewsFilter_Version2.mqh` | Native economic-calendar filtering in `EA/Filters/TradingFilters.mqh` |
| `PatternDetector_Version1.mqh`, `PatternDetector_Version2.mqh` | Strategy-specific engulfing/retracement rules in `EA/Strategy/SignalEngine.mqh`; unrelated pattern catalog is not migrated |
| `PriceActionAnalyzer_Version1.mqh`, `PriceActionAnalyzer_Version2.mqh` | Confirmed pivots/structure in `EA/Market/StructureEngine.mqh` |
| `RiskManagementLibrary.mqh`, `RiskManager_Version2.mqh` | `EA/Risk/RiskManager.mqh` |
| `SignalManager_Version1.mqh`, `SignalManager_Version2.mqh`, `SignalManager_Complete_Version1.mqh` | `EA/Strategy/SignalEngine.mqh` produces analysis-only signals |
| `Structs_Version1.mqh` | Canonical value types in `EA/Core/Types.mqh` |
| `TelegramNotifications.mqh` | `EA/Alerts/AlertEngine.mqh`; credentials are runtime inputs, not source constants |
| `MQL5/Indicators/SMC_StructureAlert.mq5` | Remains an independent indicator; not replaced by this EA |

The old loose modules are not included by the new EA because several have missing/renamed include dependencies and the versions overlap. They remain available for reference, but do not mix them into the canonical source without a separate compile/review.
