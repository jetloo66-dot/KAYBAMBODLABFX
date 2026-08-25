# Swing Detection EA - File Structure

## Complete File List

### Main Expert Advisor
- **SwingDetectionEA.mq5** (28 KB)
  - Main EA file with all initialization and trading logic
  - Includes OnInit, OnDeinit, OnTick, OnTradeTransaction functions
  - Multi-symbol management and position handling

### Helper Modules (MQH)
- **SwingDetection.mqh** (18 KB)
  - Swing point detection using fractal logic
  - Classification: HH, HL, LH, LL
  - Break of structure detection
  - Retracement validation

- **SignalGenerator.mqh** (17 KB)
  - H1 and M5 timeframe analysis
  - Stochastic oscillator integration
  - Bollinger Bands analysis
  - Signal generation and validation

- **SupportResistance.mqh** (15 KB)
  - Swing level tracking
  - Support/resistance identification
  - Level strength calculation
  - Historical level management

- **TelegramNotifier.mqh** (11 KB)
  - Telegram bot integration
  - Message formatting and sending
  - Trade alerts and notifications
  - Error reporting

- **ChartVisualization.mqh** (16 KB)
  - Chart object drawing
  - Swing point visualization
  - Signal arrows and zones
  - SL/TP level display

- **ErrorHandler.mqh** (12 KB)
  - Comprehensive error logging
  - File-based log management
  - Data validation
  - Trade permission checks

### Documentation
- **SwingDetectionEA_README.md** (11 KB)
  - Complete documentation
  - Strategy explanation
  - Installation guide
  - Configuration details
  - Optimization guide
  - Troubleshooting

- **QUICK_START.md** (5 KB)
  - 5-minute setup guide
  - Quick reference
  - Common settings
  - Troubleshooting checklist

- **FILE_STRUCTURE.md** (This file)
  - Complete file listing
  - Directory structure
  - Installation paths

### Configuration Presets (.set files)
- **SwingDetectionEA_Conservative.set** (1.1 KB)
  - Low risk settings
  - Single symbol trading
  - 0.01 lot size
  - Suitable for beginners

- **SwingDetectionEA_Moderate.set** (1.1 KB)
  - Balanced risk-reward
  - 3 major pairs
  - 0.1 lot size with risk %
  - Suitable for experienced traders

- **SwingDetectionEA_Aggressive.set** (1.1 KB)
  - Higher risk settings
  - All major pairs + gold
  - 0.5 lot size with 2% risk
  - Suitable for advanced traders

## Installation Directory Structure

```
MT5 Data Folder/
└── MQL5/
    └── Experts/
        ├── SwingDetectionEA.mq5          ← Main EA
        ├── SwingDetection.mqh             ← Helper modules
        ├── SignalGenerator.mqh
        ├── SupportResistance.mqh
        ├── TelegramNotifier.mqh
        ├── ChartVisualization.mqh
        ├── ErrorHandler.mqh
        └── Presets/
            ├── SwingDetectionEA_Conservative.set
            ├── SwingDetectionEA_Moderate.set
            └── SwingDetectionEA_Aggressive.set
```

Alternative structure (using subdirectory):
```
MT5 Data Folder/
└── MQL5/
    ├── Experts/
    │   └── SwingDetectionEA.mq5          ← Main EA
    └── Include/
        ├── SwingDetection.mqh             ← Helper modules
        ├── SignalGenerator.mqh
        ├── SignalGenerator.mqh
        ├── SupportResistance.mqh
        ├── TelegramNotifier.mqh
        ├── ChartVisualization.mqh
        └── ErrorHandler.mqh
```

## Log Files Created at Runtime

```
MT5 Data Folder/
└── MQL5/
    └── Files/
        └── SwingEA_SYMBOL_Log.txt        ← Generated logs (one per symbol)
```

## File Dependencies

```
SwingDetectionEA.mq5
├── <Trade\Trade.mqh>                     ← MT5 Standard Library
├── SwingDetection.mqh
├── SignalGenerator.mqh
│   └── SwingDetection.mqh                ← Nested dependency
├── SupportResistance.mqh
│   └── SwingDetection.mqh                ← Nested dependency
├── TelegramNotifier.mqh
├── ChartVisualization.mqh
│   ├── SwingDetection.mqh                ← Nested dependency
│   └── SupportResistance.mqh             ← Nested dependency
└── ErrorHandler.mqh
```

## File Sizes Reference

| File | Size | Lines | Description |
|------|------|-------|-------------|
| SwingDetectionEA.mq5 | 28 KB | ~650 | Main EA logic |
| SwingDetection.mqh | 18 KB | ~530 | Swing detection |
| SignalGenerator.mqh | 17 KB | ~460 | Signal generation |
| SupportResistance.mqh | 15 KB | ~420 | S/R tracking |
| TelegramNotifier.mqh | 11 KB | ~330 | Notifications |
| ChartVisualization.mqh | 16 KB | ~450 | Chart drawing |
| ErrorHandler.mqh | 12 KB | ~360 | Error handling |
| **Total Code** | **117 KB** | **~3200** | All modules |

## Version Information

**Version**: 1.00  
**Release Date**: December 2024  
**Platform**: MetaTrader 5  
**Language**: MQL5  
**Copyright**: KAYBAMBODLABFX  

## Required MT5 Version

- Minimum: Build 2980+
- Recommended: Latest stable build
- Platform: MetaTrader 5 (MT5 only, not compatible with MT4)

## External Dependencies

### Standard MT5 Libraries
- Trade.mqh (included with MT5)

### Internet Services
- Telegram API (api.telegram.org)
  - Must be added to allowed URLs in MT5

### No External DLLs
This EA does not use any external DLLs or third-party libraries beyond MT5 standard library.

## File Checksums (SHA256)

For verification of file integrity:
```
(checksums would be generated after final compilation)
SwingDetectionEA.mq5: [hash]
SwingDetection.mqh: [hash]
SignalGenerator.mqh: [hash]
...
```

## Installation Verification

After copying files, verify:
```
✓ All .mqh files in MQL5/Experts/ or MQL5/Include/
✓ SwingDetectionEA.mq5 in MQL5/Experts/
✓ .set files in MQL5/Presets/ (optional)
✓ No compilation errors (F7 in MetaEditor)
✓ EA appears in Navigator → Expert Advisors
```

## Backup Recommendation

Before any updates, backup these files:
```
- SwingDetectionEA.mq5
- All .mqh files
- Your custom .set files
- Log files (if needed for analysis)
```

## File Permissions

All files should have:
- Read: Yes
- Write: Yes (for logs)
- Execute: Not required (interpreted by MT5)

## Related Files (Not Included)

These files are part of MT5 standard installation:
- Trade.mqh
- Object.mqh
- Chart.mqh
- SymbolInfo.mqh

## Cleanup

To completely remove the EA:
```
1. Remove from charts
2. Delete SwingDetectionEA.mq5
3. Delete all .mqh helper modules
4. Delete .set preset files
5. Delete log files from MQL5/Files/
6. Delete compiled .ex5 file from MQL5/Experts/
```

---

**Note**: Keep backup copies of your customized settings and preset files before reinstalling or updating.
