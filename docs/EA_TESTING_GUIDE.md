# Canonical EA Setup and Testing

The modular native MT5 Expert Advisor is `EA/KAYBAMBODLABFX.mq5`. Keep the adjacent `Core`, `Market`, `Strategy`, `Risk`, `Execution`, `Management`, `Filters`, `Alerts`, `UI`, and `Analytics` folders together so the relative includes resolve. Legacy root-level EAs are not the canonical implementation; see `MIGRATION_NOTES.md`.

## Install and compile

1. Copy the complete `EA/` directory into the terminal's `MQL5/Experts/KAYBAMBODLABFX/` directory.
2. Open `KAYBAMBODLABFX.mq5` in MetaEditor and compile it with the same MT5 build used by the intended broker.
3. Confirm the configured broker symbol names exactly match Market Watch, including suffixes. Native calendar filtering may require broker calendar coverage.
4. Attach the EA to a chart, leave `InpAllowTrading=false`, and confirm the dashboard reports frame trend/context and no initialization errors.

## Strategy Tester checklist

1. Use one symbol and one entry timeframe first. Then enable higher-frame context and lower-frame independent/zone-gated execution.
2. Use “Every tick based on real ticks” where available; verify closed-bar break confirmation followed by a separate retracement to LL2 low (buy) or HH2 high (sell).
3. Inspect chart labels `1`, `2`, `3`, `CHOCH`/`BOS`, `Retrace`, connector, zones, SL and TP. Verify long and short symmetry.
4. Check FX pip versus non-FX point distances, broker tick size, volume step, stop/freeze limits, spread/news blocks, P&L windows, partial exits, BE/trailing and pending-order acceptance.
5. Repeat on demo for each broker/account mode before considering live use. Review the MT5 Experts/Journal logs and `KBLX_trade_memory.csv`.

Compilation, broker behavior and profitable results are not verified by the repository's static checks. The strategy does not guarantee a win rate, return, or protection from slippage/gaps.
