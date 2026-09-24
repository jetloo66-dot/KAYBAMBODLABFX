#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path('/home/runner/work/KAYBAMBODLABFX/KAYBAMBODLABFX')
ENTRY = ROOT / 'KAYBAMBODLABFX_MT5_ProductionEA.mq5'

REQUIRED = [
    'KAYB_Models.mqh',
    'KAYB_Config.mqh',
    'KAYB_Utils.mqh',
    'KAYB_StructureEngine.mqh',
    'KAYB_SetupEngines.mqh',
    'KAYB_ExecutionRisk.mqh',
    'KAYB_Filters.mqh',
    'KAYB_AlertsDashboard.mqh',
    'KAYB_TradeMemory.mqh',
]

def brace_balance(text: str):
    stack = 0
    for ch in text:
        if ch == '{':
            stack += 1
        elif ch == '}':
            stack -= 1
            if stack < 0:
                return False
    return stack == 0

ok = True
if not ENTRY.exists():
    print('Missing EA entry:', ENTRY)
    ok = False

for name in REQUIRED:
    p = ROOT / name
    if not p.exists():
        print('Missing module:', p)
        ok = False

for p in [ENTRY] + [ROOT / n for n in REQUIRED if (ROOT / n).exists()]:
    txt = p.read_text(encoding='utf-8')
    if not brace_balance(txt):
        print('Brace imbalance:', p)
        ok = False

print('MQL5 sanity check:', 'PASS' if ok else 'FAIL')
sys.exit(0 if ok else 1)
