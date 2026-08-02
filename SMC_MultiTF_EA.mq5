//+------------------------------------------------------------------+
//|                                                   SMC_MultiTF_EA |
//| Smart Money Concept multi-timeframe Expert Advisor for MT5       |
//|                                                                  |
//| Strategy summary                                                 |
//| 1. Detect swing highs/lows using configurable left/right pivots. |
//| 2. Build mirrored SMC structure sequences:                       |
//|    - Buy:  LL2 -> LH2 -> LL1, then close above LH2              |
//|    - Sell: HH2 -> HL2 -> HH1, then close below HL2              |
//| 3. Support 3 entry modes: momentum, clean retrace, fib retrace. |
//| 4. Aggregate bias across 5 configurable timeframes and trade     |
//|    only when confluence meets the configured threshold.          |
//| 5. Manage SL/TP, partial close, break-even, trailing stop, news |
//|    filter, alerts, drawings, and on-chart dashboard.            |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://github.com/jetloo66-dot/KAYBAMBODLABFX"
#property version   "1.00"
#property strict
#property description "Multi-timeframe Smart Money Concept Expert Advisor."
#property description "Implements LL2-LH2-LL1 / HH2-HL2-HH1 structure, CHOCH/BOS, retracement modes, confluence, risk management, alerts, news filter, and chart dashboard."

#include <Trade/Trade.mqh>

enum ENUM_SMC_ENTRY_MODE
  {
   SMC_MODE_A = 0, // Immediate / momentum
   SMC_MODE_B = 1, // Clean retrace
   SMC_MODE_C = 2  // Retrace + Fibonacci
  };

enum ENUM_SMC_BIAS
  {
   SMC_BIAS_NEUTRAL = 0,
   SMC_BIAS_BULLISH = 1,
   SMC_BIAS_BEARISH = -1
  };

enum ENUM_SMC_SIGNAL_SIDE
  {
   SMC_SIDE_BUY = 1,
   SMC_SIDE_SELL = -1
  };

input group "=== STRUCTURE & TIMEFRAMES ==="
input ENUM_TIMEFRAMES InpTimeframeD1 = PERIOD_D1;
input ENUM_TIMEFRAMES InpTimeframeH4 = PERIOD_H4;
input ENUM_TIMEFRAMES InpTimeframeH1 = PERIOD_H1;
input ENUM_TIMEFRAMES InpTimeframeM15 = PERIOD_M15;
input ENUM_TIMEFRAMES InpTimeframeM5 = PERIOD_M5;
input int InpPivotLeftBars = 2;
input int InpPivotRightBars = 2;
input int InpBarsToScan = 600;
input int InpMinConfluence = 2;

input group "=== ENTRY MODES ==="
input bool InpUseGlobalMode = true;
input ENUM_SMC_ENTRY_MODE InpGlobalMode = SMC_MODE_A;
input ENUM_SMC_ENTRY_MODE InpModeD1 = SMC_MODE_A;
input ENUM_SMC_ENTRY_MODE InpModeH4 = SMC_MODE_A;
input ENUM_SMC_ENTRY_MODE InpModeH1 = SMC_MODE_A;
input ENUM_SMC_ENTRY_MODE InpModeM15 = SMC_MODE_A;
input ENUM_SMC_ENTRY_MODE InpModeM5 = SMC_MODE_A;
input int InpModeANextCandles = 2;
input double InpFibRetraceLevel1 = 0.500;
input double InpFibRetraceLevel2 = 0.618;
input double InpPinBarWickRatio = 1.50;

input group "=== RISK & EXECUTION ==="
input double InpLotSize = 0.01;
input bool InpUseRiskPercent = false;
input double InpRiskPercent = 1.0;
input double InpSL_OffsetPoints = 10.0;
input double InpRiskRewardMultiplier = 3.0;
input double InpPartialClosePercent = 50.0;
input double InpPartialRR = 1.0;
input bool InpEnableTrailingStop = true;
input double InpTrailingStartDistance = 15.0;
input double InpTrailingStepDistance = 5.0;
input bool InpEnableBreakEven = true;
input double InpBreakEvenRR = 1.0;
input double InpBreakEvenOffsetPoints = 1.0;
input int InpMaxOpenPositions = 1;
input long InpMagicNumber = 20260801;
input int InpMaxSlippagePoints = 20;
input string InpPointBasedSymbols = "XAUUSD,BTCUSD,ETHUSD";

input group "=== NEWS FILTER ==="
input bool InpEnableNewsFilter = true;
input int InpNewsBufferMinutesBefore = 30;
input int InpNewsBufferMinutesAfter = 30;

input group "=== ALERTS ==="
input bool InpEnableTelegramAlerts = false;
input string InpTelegramBotToken = "";
input string InpTelegramChatId = "";
input bool InpEnablePushAlerts = false;
input bool InpEnableNativeAlerts = true;
input bool InpEnablePrintLogs = true;

input group "=== VISUALS ==="
input color InpBullColor = clrLimeGreen;
input color InpBearColor = clrTomato;
input color InpNeutralColor = clrSilver;
input color InpZoneBuyColor = clrPaleGreen;
input color InpZoneSellColor = clrMistyRose;
input color InpDashboardBgColor = clrBlack;
input color InpDashboardTextColor = clrWhite;
input color InpTradeLineColor = clrGold;
input int InpStructureLineWidth = 2;
input int InpTradeLineWidth = 1;
input bool InpDrawAllTimeframes = true;
input ENUM_BASE_CORNER InpDashboardCorner = CORNER_LEFT_UPPER;
input int InpDashboardX = 10;
input int InpDashboardY = 20;

#define SMC_TF_COUNT 5
#define SMC_PREFIX "SMC_MTF_"

struct SwingPoint
  {
   int               index;
   datetime          time;
   double            price;
   bool              isHigh;
  };

struct StructureSignal
  {
   bool              valid;
   ENUM_SMC_SIGNAL_SIDE side;
   ENUM_SMC_ENTRY_MODE mode;
   ENUM_TIMEFRAMES   timeframe;
   string            timeframeName;
   string            signalName;
   datetime          signalTime;
   datetime          breakoutTime;
   datetime          retraceTime;
   datetime          p1Time;
   datetime          p2Time;
   datetime          p3Time;
   int               p1Index;
   int               p2Index;
   int               p3Index;
   int               breakoutIndex;
   int               retraceIndex;
   double            p1Price;
   double            p2Price;
   double            p3Price;
   double            breakoutPrice;
   double            retracePrice;
   double            zoneLow;
   double            zoneHigh;
   double            fibLevel1;
   double            fibLevel2;
   double            targetLow;
   double            targetHigh;
   double            entryPrice;
   double            stopLoss;
   double            takeProfit;
   double            partialPrice;
   bool              fresh;
   string            commentTag;
  };

struct TimeframeState
  {
   ENUM_TIMEFRAMES   timeframe;
   string            name;
   ENUM_SMC_ENTRY_MODE mode;
   datetime          lastProcessedBar;
   StructureSignal   buySignal;
   StructureSignal   sellSignal;
   ENUM_SMC_BIAS     bias;
   string            lastSignalLabel;
  };

struct ManagedPosition
  {
   ulong             ticket;
   ENUM_POSITION_TYPE type;
   double            entryPrice;
   double            initialSL;
   double            initialTP;
   double            partialPrice;
   bool              partialClosed;
   bool              breakEvenDone;
  };

CTrade g_trade;
TimeframeState g_tfStates[SMC_TF_COUNT];
ManagedPosition g_positions[32];
int g_positionCount = 0;
datetime g_lastBuyExecuted = 0;
datetime g_lastSellExecuted = 0;
bool g_tradingArmed = false;

string TfToLabel(const ENUM_TIMEFRAMES timeframe)
  {
   switch(timeframe)
     {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return EnumToString(timeframe);
     }
  }

ENUM_SMC_ENTRY_MODE ModeForSlot(const int slot)
  {
   if(InpUseGlobalMode)
      return InpGlobalMode;

   switch(slot)
     {
      case 0: return InpModeD1;
      case 1: return InpModeH4;
      case 2: return InpModeH1;
      case 3: return InpModeM15;
      case 4: return InpModeM5;
     }
   return InpGlobalMode;
  }

void ResetSignal(StructureSignal &signal)
  {
   signal.valid=false;
   signal.side=SMC_SIDE_BUY;
   signal.mode=SMC_MODE_A;
   signal.timeframe=PERIOD_CURRENT;
   signal.timeframeName="";
   signal.signalName="";
   signal.signalTime=0;
   signal.breakoutTime=0;
   signal.retraceTime=0;
   signal.p1Time=0;
   signal.p2Time=0;
   signal.p3Time=0;
   signal.p1Index=-1;
   signal.p2Index=-1;
   signal.p3Index=-1;
   signal.breakoutIndex=-1;
   signal.retraceIndex=-1;
   signal.p1Price=0.0;
   signal.p2Price=0.0;
   signal.p3Price=0.0;
   signal.breakoutPrice=0.0;
   signal.retracePrice=0.0;
   signal.zoneLow=0.0;
   signal.zoneHigh=0.0;
   signal.fibLevel1=0.0;
   signal.fibLevel2=0.0;
   signal.targetLow=0.0;
   signal.targetHigh=0.0;
   signal.entryPrice=0.0;
   signal.stopLoss=0.0;
   signal.takeProfit=0.0;
   signal.partialPrice=0.0;
   signal.fresh=false;
   signal.commentTag="";
  }

void InitializeTimeframes()
  {
   ENUM_TIMEFRAMES timeframes[SMC_TF_COUNT]={InpTimeframeD1,InpTimeframeH4,InpTimeframeH1,InpTimeframeM15,InpTimeframeM5};
   for(int i=0;i<SMC_TF_COUNT;i++)
     {
      g_tfStates[i].timeframe=timeframes[i];
      g_tfStates[i].name=TfToLabel(timeframes[i]);
      g_tfStates[i].mode=ModeForSlot(i);
      g_tfStates[i].lastProcessedBar=0;
      ResetSignal(g_tfStates[i].buySignal);
      ResetSignal(g_tfStates[i].sellSignal);
      g_tfStates[i].bias=SMC_BIAS_NEUTRAL;
      g_tfStates[i].lastSignalLabel="None";
     }
  }

bool IsPointBasedSymbol()
  {
   string symbol=_Symbol;
   StringToUpper(symbol);
   string list=InpPointBasedSymbols;
   string parts[];
   int count=StringSplit(list,',',parts);
   for(int i=0;i<count;i++)
     {
      string token=parts[i];
      StringTrimLeft(token);
      StringTrimRight(token);
      StringToUpper(token);
      if(token!="" && StringFind(symbol,token)>=0)
         return true;
     }
   return false;
  }

double TradingUnitSize()
  {
   if(IsPointBasedSymbol())
      return _Point;
   if(_Digits==3 || _Digits==5)
      return _Point*10.0;
   return _Point;
  }

double UnitsToPrice(const double units)
  {
   return units*TradingUnitSize();
  }

double NormalizePrice(const double price)
  {
   return NormalizeDouble(price,_Digits);
  }

double ClampVolume(const double volume)
  {
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0)
      step=0.01;
   double normalized=MathFloor(volume/step)*step;
   if(normalized<minLot)
      normalized=minLot;
   if(normalized>maxLot)
      normalized=maxLot;
   int lotDigits=2;
   if(step<0.1)
      lotDigits=2;
   if(step<0.01)
      lotDigits=3;
   return NormalizeDouble(normalized,lotDigits);
  }

double CalculateOrderVolume(const double entryPrice,const double stopLoss)
  {
   if(!InpUseRiskPercent)
      return ClampVolume(InpLotSize);

   double riskMoney=AccountInfoDouble(ACCOUNT_BALANCE)*(InpRiskPercent/100.0);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double distance=MathAbs(entryPrice-stopLoss);
   if(riskMoney<=0.0 || tickValue<=0.0 || tickSize<=0.0 || distance<=0.0)
      return ClampVolume(InpLotSize);

   double lossPerLot=(distance/tickSize)*tickValue;
   if(lossPerLot<=0.0)
      return ClampVolume(InpLotSize);

   return ClampVolume(riskMoney/lossPerLot);
  }

bool IsBullishCandle(const MqlRates &bar)
  {
   return (bar.close>bar.open);
  }

bool IsBearishCandle(const MqlRates &bar)
  {
   return (bar.close<bar.open);
  }

bool IsBullishEngulfing(const MqlRates &prev,const MqlRates &curr)
  {
   return (IsBearishCandle(prev) && IsBullishCandle(curr) && curr.close>=prev.open && curr.open<=prev.close);
  }

bool IsBearishEngulfing(const MqlRates &prev,const MqlRates &curr)
  {
   return (IsBullishCandle(prev) && IsBearishCandle(curr) && curr.open>=prev.close && curr.close<=prev.open);
  }

bool IsBullishRejection(const MqlRates &rates[],const int index)
  {
   if(index<=0)
      return false;

   MqlRates bar=rates[index];
   double body=MathAbs(bar.close-bar.open);
   double lower=MathMin(bar.open,bar.close)-bar.low;
   double upper=bar.high-MathMax(bar.open,bar.close);
   bool pin=(bar.close>=bar.open && lower>body*InpPinBarWickRatio && lower>upper);
   return (pin || IsBullishEngulfing(rates[index-1],bar));
  }

bool IsBearishRejection(const MqlRates &rates[],const int index)
  {
   if(index<=0)
      return false;

   MqlRates bar=rates[index];
   double body=MathAbs(bar.close-bar.open);
   double upper=bar.high-MathMax(bar.open,bar.close);
   double lower=MathMin(bar.open,bar.close)-bar.low;
   bool pin=(bar.close<=bar.open && upper>body*InpPinBarWickRatio && upper>lower);
   return (pin || IsBearishEngulfing(rates[index-1],bar));
  }

bool TouchesRange(const MqlRates &bar,const double low,const double high)
  {
   return (bar.low<=high && bar.high>=low);
  }

bool NoBullishGapLeft(const MqlRates &rates[],const int fromIndex,const int toIndex)
  {
   for(int i=MathMax(fromIndex+1,1);i<=toIndex;i++)
     {
      if(rates[i].low>rates[i-1].high)
         return false;
     }
   return true;
  }

bool NoBearishGapLeft(const MqlRates &rates[],const int fromIndex,const int toIndex)
  {
   for(int i=MathMax(fromIndex+1,1);i<=toIndex;i++)
     {
      if(rates[i].high<rates[i-1].low)
         return false;
     }
   return true;
  }

bool LoadRates(const ENUM_TIMEFRAMES timeframe,MqlRates &rates[],int &count)
  {
   count=CopyRates(_Symbol,timeframe,0,InpBarsToScan,rates);
   if(count<=MathMax(InpPivotLeftBars+InpPivotRightBars+10,50))
      return false;
   ArraySetAsSeries(rates,false);
   return true;
  }

bool IsPivotHigh(const MqlRates &rates[],const int count,const int index)
  {
   if(index<InpPivotLeftBars || index>count-1-InpPivotRightBars)
      return false;

   for(int i=1;i<=InpPivotLeftBars;i++)
      if(rates[index].high<=rates[index-i].high)
         return false;

   for(int i=1;i<=InpPivotRightBars;i++)
      if(rates[index].high<=rates[index+i].high)
         return false;

   return true;
  }

bool IsPivotLow(const MqlRates &rates[],const int count,const int index)
  {
   if(index<InpPivotLeftBars || index>count-1-InpPivotRightBars)
      return false;

   for(int i=1;i<=InpPivotLeftBars;i++)
      if(rates[index].low>=rates[index-i].low)
         return false;

   for(int i=1;i<=InpPivotRightBars;i++)
      if(rates[index].low>=rates[index+i].low)
         return false;

   return true;
  }

int DetectSwings(const MqlRates &rates[],const int count,SwingPoint &swings[])
  {
   ArrayResize(swings,0);
   int detected=0;
   for(int i=InpPivotLeftBars;i<=count-1-InpPivotRightBars;i++)
     {
      bool high=IsPivotHigh(rates,count,i);
      bool low=IsPivotLow(rates,count,i);
      if(high==low)
         continue;

      ArrayResize(swings,detected+1);
      swings[detected].index=i;
      swings[detected].time=rates[i].time;
      swings[detected].price=(high ? rates[i].high : rates[i].low);
      swings[detected].isHigh=high;
      detected++;
     }
   return detected;
  }

int FindBullishTargetCandle(const MqlRates &rates[],const int p2Index,const int p3Index,double &targetLow,double &targetHigh)
  {
   targetLow=0.0;
   targetHigh=0.0;
   int target=-1;
   for(int i=p2Index+1;i<p3Index-1;i++)
     {
      if(IsBullishCandle(rates[i]) && IsBearishCandle(rates[i+1]) &&
         rates[i+1].open>=rates[i].close && rates[i+1].close<=rates[i].open)
        {
         target=i;
        }
     }

   if(target<0)
     {
      for(int i=p3Index-1;i>p2Index;i--)
        {
         if(IsBullishCandle(rates[i]))
           {
            target=i;
            break;
           }
        }
     }

   if(target>=0)
     {
      targetLow=MathMin(rates[target].open,rates[target].close);
      targetHigh=MathMax(rates[target].open,rates[target].close);
     }
   return target;
  }

int FindBearishTargetCandle(const MqlRates &rates[],const int p2Index,const int p3Index,double &targetLow,double &targetHigh)
  {
   targetLow=0.0;
   targetHigh=0.0;
   int target=-1;
   for(int i=p2Index+1;i<p3Index-1;i++)
     {
      if(IsBearishCandle(rates[i]) && IsBullishCandle(rates[i+1]) &&
         rates[i+1].close>=rates[i].open && rates[i+1].open<=rates[i].close)
        {
         target=i;
        }
     }

   if(target<0)
     {
      for(int i=p3Index-1;i>p2Index;i--)
        {
         if(IsBearishCandle(rates[i]))
           {
            target=i;
            break;
           }
        }
     }

   if(target>=0)
     {
      targetLow=MathMin(rates[target].open,rates[target].close);
      targetHigh=MathMax(rates[target].open,rates[target].close);
     }
   return target;
  }

void FillRiskLevels(StructureSignal &signal)
  {
   double offset=UnitsToPrice(InpSL_OffsetPoints);
   double riskDistance=0.0;
   if(signal.side==SMC_SIDE_BUY)
     {
      signal.stopLoss=NormalizePrice(signal.zoneLow-offset);
      riskDistance=MathAbs(signal.entryPrice-signal.stopLoss);
      signal.takeProfit=NormalizePrice(signal.entryPrice+(riskDistance*InpRiskRewardMultiplier));
      signal.partialPrice=NormalizePrice(signal.entryPrice+(riskDistance*InpPartialRR));
     }
   else
     {
      signal.stopLoss=NormalizePrice(signal.zoneHigh+offset);
      riskDistance=MathAbs(signal.stopLoss-signal.entryPrice);
      signal.takeProfit=NormalizePrice(signal.entryPrice-(riskDistance*InpRiskRewardMultiplier));
      signal.partialPrice=NormalizePrice(signal.entryPrice-(riskDistance*InpPartialRR));
     }
  }

bool EvaluateBullishModeA(const MqlRates &rates[],const int lastCompleted,StructureSignal &signal)
  {
   signal.signalName="CHOCH/BOS";
   signal.entryPrice=rates[signal.breakoutIndex].close;
   signal.signalTime=rates[signal.breakoutIndex].time;
   signal.breakoutPrice=rates[signal.breakoutIndex].close;

   int limit=MathMin(lastCompleted,signal.breakoutIndex+InpModeANextCandles);
   for(int i=signal.breakoutIndex+1;i<=limit;i++)
     {
      if(IsBullishRejection(rates,i))
        {
         signal.signalName="Retrace";
         signal.signalTime=rates[i].time;
         signal.entryPrice=rates[i].close;
         signal.retraceIndex=i;
         signal.retraceTime=rates[i].time;
         signal.retracePrice=rates[i].close;
        }
     }
   return true;
  }

bool EvaluateBearishModeA(const MqlRates &rates[],const int lastCompleted,StructureSignal &signal)
  {
   signal.signalName="CHOCH/BOS";
   signal.entryPrice=rates[signal.breakoutIndex].close;
   signal.signalTime=rates[signal.breakoutIndex].time;
   signal.breakoutPrice=rates[signal.breakoutIndex].close;

   int limit=MathMin(lastCompleted,signal.breakoutIndex+InpModeANextCandles);
   for(int i=signal.breakoutIndex+1;i<=limit;i++)
     {
      if(IsBearishRejection(rates,i))
        {
         signal.signalName="Retrace";
         signal.signalTime=rates[i].time;
         signal.entryPrice=rates[i].close;
         signal.retraceIndex=i;
         signal.retraceTime=rates[i].time;
         signal.retracePrice=rates[i].close;
        }
     }
   return true;
  }

bool EvaluateBullishModeB(const MqlRates &rates[],const int lastCompleted,StructureSignal &signal)
  {
   for(int i=signal.breakoutIndex+1;i<=lastCompleted;i++)
     {
      bool inZone=TouchesRange(rates[i],signal.zoneLow,signal.zoneHigh);
      bool inTarget=(signal.targetHigh<=signal.targetLow || TouchesRange(rates[i],signal.targetLow,signal.targetHigh));
      if(inZone && inTarget && NoBullishGapLeft(rates,signal.breakoutIndex,i) && IsBullishRejection(rates,i))
        {
         signal.signalName="Retrace";
         signal.signalTime=rates[i].time;
         signal.entryPrice=rates[i].close;
         signal.retraceIndex=i;
         signal.retraceTime=rates[i].time;
         signal.retracePrice=rates[i].close;
         return true;
        }
     }
   return false;
  }

bool EvaluateBearishModeB(const MqlRates &rates[],const int lastCompleted,StructureSignal &signal)
  {
   for(int i=signal.breakoutIndex+1;i<=lastCompleted;i++)
     {
      bool inZone=TouchesRange(rates[i],signal.zoneLow,signal.zoneHigh);
      bool inTarget=(signal.targetHigh<=signal.targetLow || TouchesRange(rates[i],signal.targetLow,signal.targetHigh));
      if(inZone && inTarget && NoBearishGapLeft(rates,signal.breakoutIndex,i) && IsBearishRejection(rates,i))
        {
         signal.signalName="Retrace";
         signal.signalTime=rates[i].time;
         signal.entryPrice=rates[i].close;
         signal.retraceIndex=i;
         signal.retraceTime=rates[i].time;
         signal.retracePrice=rates[i].close;
         return true;
        }
     }
   return false;
  }

bool EvaluateBullishModeC(const MqlRates &rates[],const int lastCompleted,StructureSignal &signal)
  {
   for(int i=signal.breakoutIndex+1;i<=lastCompleted;i++)
     {
      bool inZone=TouchesRange(rates[i],signal.zoneLow,signal.zoneHigh);
      bool inTarget=(signal.targetHigh>signal.targetLow && TouchesRange(rates[i],signal.targetLow,signal.targetHigh));
      bool fibTouch=(rates[i].low<=signal.fibLevel1 && rates[i].close>=signal.fibLevel1) ||
                    (rates[i].low<=signal.fibLevel2 && rates[i].close>=signal.fibLevel2);
      if(inZone && NoBullishGapLeft(rates,signal.breakoutIndex,i) && (inTarget || fibTouch))
        {
         signal.signalName="Retrace";
         signal.signalTime=rates[i].time;
         signal.entryPrice=rates[i].close;
         signal.retraceIndex=i;
         signal.retraceTime=rates[i].time;
         signal.retracePrice=rates[i].close;
         return true;
        }
     }
   return false;
  }

bool EvaluateBearishModeC(const MqlRates &rates[],const int lastCompleted,StructureSignal &signal)
  {
   for(int i=signal.breakoutIndex+1;i<=lastCompleted;i++)
     {
      bool inZone=TouchesRange(rates[i],signal.zoneLow,signal.zoneHigh);
      bool inTarget=(signal.targetHigh>signal.targetLow && TouchesRange(rates[i],signal.targetLow,signal.targetHigh));
      bool fibTouch=(rates[i].high>=signal.fibLevel1 && rates[i].close<=signal.fibLevel1) ||
                    (rates[i].high>=signal.fibLevel2 && rates[i].close<=signal.fibLevel2);
      if(inZone && NoBearishGapLeft(rates,signal.breakoutIndex,i) && (inTarget || fibTouch))
        {
         signal.signalName="Retrace";
         signal.signalTime=rates[i].time;
         signal.entryPrice=rates[i].close;
         signal.retraceIndex=i;
         signal.retraceTime=rates[i].time;
         signal.retracePrice=rates[i].close;
         return true;
        }
     }
   return false;
  }

bool DetectBullishSignal(const ENUM_TIMEFRAMES timeframe,const string timeframeName,const ENUM_SMC_ENTRY_MODE mode,const MqlRates &rates[],const int count,StructureSignal &signal)
  {
   ResetSignal(signal);
   signal.side=SMC_SIDE_BUY;
   signal.mode=mode;
   signal.timeframe=timeframe;
   signal.timeframeName=timeframeName;

   SwingPoint swings[];
   int swingCount=DetectSwings(rates,count,swings);
   if(swingCount<3)
      return false;

   int lastCompleted=count-2;
   for(int s=swingCount-1;s>=2;s--)
     {
      if(swings[s].isHigh || !swings[s-1].isHigh || swings[s-2].isHigh)
         continue;

      double ll2=swings[s-2].price;
      double lh2=swings[s-1].price;
      double ll1=swings[s].price;
      if(!(ll2<lh2 && ll1<ll2))
         continue;

      int breakout=-1;
      for(int i=swings[s].index+1;i<=lastCompleted;i++)
        {
         if(rates[i].close>lh2)
           {
            breakout=i;
            break;
           }
        }
      if(breakout<0)
         continue;

      signal.valid=true;
      signal.p1Index=swings[s-2].index;
      signal.p2Index=swings[s-1].index;
      signal.p3Index=swings[s].index;
      signal.p1Time=swings[s-2].time;
      signal.p2Time=swings[s-1].time;
      signal.p3Time=swings[s].time;
      signal.p1Price=ll2;
      signal.p2Price=lh2;
      signal.p3Price=ll1;
      signal.zoneLow=MathMin(ll1,lh2);
      signal.zoneHigh=MathMax(ll1,lh2);
      signal.fibLevel1=NormalizePrice(ll1+((lh2-ll1)*InpFibRetraceLevel1));
      signal.fibLevel2=NormalizePrice(ll1+((lh2-ll1)*InpFibRetraceLevel2));
      signal.breakoutIndex=breakout;
      signal.breakoutTime=rates[breakout].time;
      signal.breakoutPrice=rates[breakout].close;
      signal.commentTag="BUY_"+timeframeName+"_MODE_"+IntegerToString((int)mode);
      FindBullishTargetCandle(rates,signal.p2Index,signal.p3Index,signal.targetLow,signal.targetHigh);

      bool ok=false;
      if(mode==SMC_MODE_A)
         ok=EvaluateBullishModeA(rates,lastCompleted,signal);
      else if(mode==SMC_MODE_B)
         ok=EvaluateBullishModeB(rates,lastCompleted,signal);
      else
         ok=EvaluateBullishModeC(rates,lastCompleted,signal);

      if(ok)
        {
         FillRiskLevels(signal);
         return true;
        }
      ResetSignal(signal);
      signal.side=SMC_SIDE_BUY;
      signal.mode=mode;
      signal.timeframe=timeframe;
      signal.timeframeName=timeframeName;
     }
   return false;
  }

bool DetectBearishSignal(const ENUM_TIMEFRAMES timeframe,const string timeframeName,const ENUM_SMC_ENTRY_MODE mode,const MqlRates &rates[],const int count,StructureSignal &signal)
  {
   ResetSignal(signal);
   signal.side=SMC_SIDE_SELL;
   signal.mode=mode;
   signal.timeframe=timeframe;
   signal.timeframeName=timeframeName;

   SwingPoint swings[];
   int swingCount=DetectSwings(rates,count,swings);
   if(swingCount<3)
      return false;

   int lastCompleted=count-2;
   for(int s=swingCount-1;s>=2;s--)
     {
      if(!swings[s].isHigh || swings[s-1].isHigh || !swings[s-2].isHigh)
         continue;

      double hh2=swings[s-2].price;
      double hl2=swings[s-1].price;
      double hh1=swings[s].price;
      if(!(hh2>hl2 && hh1>hh2))
         continue;

      int breakout=-1;
      for(int i=swings[s].index+1;i<=lastCompleted;i++)
        {
         if(rates[i].close<hl2)
           {
            breakout=i;
            break;
           }
        }
      if(breakout<0)
         continue;

      signal.valid=true;
      signal.p1Index=swings[s-2].index;
      signal.p2Index=swings[s-1].index;
      signal.p3Index=swings[s].index;
      signal.p1Time=swings[s-2].time;
      signal.p2Time=swings[s-1].time;
      signal.p3Time=swings[s].time;
      signal.p1Price=hh2;
      signal.p2Price=hl2;
      signal.p3Price=hh1;
      signal.zoneLow=MathMin(hl2,hh1);
      signal.zoneHigh=MathMax(hl2,hh1);
      signal.fibLevel1=NormalizePrice(hh1-((hh1-hl2)*InpFibRetraceLevel1));
      signal.fibLevel2=NormalizePrice(hh1-((hh1-hl2)*InpFibRetraceLevel2));
      signal.breakoutIndex=breakout;
      signal.breakoutTime=rates[breakout].time;
      signal.breakoutPrice=rates[breakout].close;
      signal.commentTag="SELL_"+timeframeName+"_MODE_"+IntegerToString((int)mode);
      FindBearishTargetCandle(rates,signal.p2Index,signal.p3Index,signal.targetLow,signal.targetHigh);

      bool ok=false;
      if(mode==SMC_MODE_A)
         ok=EvaluateBearishModeA(rates,lastCompleted,signal);
      else if(mode==SMC_MODE_B)
         ok=EvaluateBearishModeB(rates,lastCompleted,signal);
      else
         ok=EvaluateBearishModeC(rates,lastCompleted,signal);

      if(ok)
        {
         FillRiskLevels(signal);
         return true;
        }
      ResetSignal(signal);
      signal.side=SMC_SIDE_SELL;
      signal.mode=mode;
      signal.timeframe=timeframe;
      signal.timeframeName=timeframeName;
     }
   return false;
  }

void DeleteObjectsByPrefix(const string prefix)
  {
   ObjectsDeleteAll(0,prefix);
  }

void CreateText(const string name,const datetime when,const double price,const string text,const color clr)
  {
   ObjectCreate(0,name,OBJ_TEXT,0,when,price);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
  }

void CreateTrend(const string name,const datetime t1,const double p1,const datetime t2,const double p2,const color clr,const int width)
  {
   ObjectCreate(0,name,OBJ_TREND,0,t1,p1,t2,p2);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
  }

void CreateHLine(const string name,const double price,const color clr,const int width,const ENUM_LINE_STYLE style)
  {
   ObjectCreate(0,name,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
  }

void DrawStructure(const int slot,const StructureSignal &signal)
  {
   string prefix=SMC_PREFIX+g_tfStates[slot].name+"_";
   DeleteObjectsByPrefix(prefix);
   if(!signal.valid)
      return;

   color lineColor=(signal.side==SMC_SIDE_BUY ? InpBullColor : InpBearColor);
   color zoneColor=(signal.side==SMC_SIDE_BUY ? InpZoneBuyColor : InpZoneSellColor);

   CreateText(prefix+"P1",signal.p1Time,signal.p1Price,"1",lineColor);
   CreateText(prefix+"P2",signal.p2Time,signal.p2Price,"2",lineColor);
   CreateText(prefix+"P3",signal.p3Time,signal.p3Price,"3",lineColor);
   CreateText(prefix+"BRK",signal.breakoutTime,signal.breakoutPrice,"CHOCH/BOS",lineColor);
   if(signal.retraceTime>0)
      CreateText(prefix+"RET",signal.retraceTime,signal.retracePrice,"Retrace",lineColor);

   CreateTrend(prefix+"L12",signal.p1Time,signal.p1Price,signal.p2Time,signal.p2Price,lineColor,InpStructureLineWidth);
   CreateTrend(prefix+"L23",signal.p2Time,signal.p2Price,signal.p3Time,signal.p3Price,lineColor,InpStructureLineWidth);
   CreateTrend(prefix+"L3B",signal.p3Time,signal.p3Price,signal.breakoutTime,signal.breakoutPrice,lineColor,InpStructureLineWidth);
   if(signal.retraceTime>0)
      CreateTrend(prefix+"LBR",signal.breakoutTime,signal.breakoutPrice,signal.retraceTime,signal.retracePrice,lineColor,InpStructureLineWidth);

   datetime rectEnd=(signal.retraceTime>0 ? signal.retraceTime : TimeCurrent());
   ObjectCreate(0,prefix+"ZONE",OBJ_RECTANGLE,0,signal.p2Time,signal.zoneHigh,rectEnd,signal.zoneLow);
   ObjectSetInteger(0,prefix+"ZONE",OBJPROP_COLOR,zoneColor);
   ObjectSetInteger(0,prefix+"ZONE",OBJPROP_BACK,true);
   ObjectSetInteger(0,prefix+"ZONE",OBJPROP_FILL,true);
   ObjectSetInteger(0,prefix+"ZONE",OBJPROP_WIDTH,1);
  }

void DrawTradeLevels()
  {
   DeleteObjectsByPrefix(SMC_PREFIX+"TRADE_");
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber)
         continue;

      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double partial=(type==POSITION_TYPE_BUY ? entry+MathAbs(entry-sl)*InpPartialRR : entry-MathAbs(sl-entry)*InpPartialRR);
      CreateHLine(SMC_PREFIX+"TRADE_SL_"+(string)ticket,sl,InpBearColor,InpTradeLineWidth,STYLE_DOT);
      CreateHLine(SMC_PREFIX+"TRADE_TP_"+(string)ticket,tp,InpBullColor,InpTradeLineWidth,STYLE_DOT);
      CreateHLine(SMC_PREFIX+"TRADE_P1_"+(string)ticket,partial,InpTradeLineColor,InpTradeLineWidth,STYLE_DASH);
     }
  }

string BiasToText(const ENUM_SMC_BIAS bias)
  {
   if(bias==SMC_BIAS_BULLISH)
      return "Bullish";
   if(bias==SMC_BIAS_BEARISH)
      return "Bearish";
   return "Neutral";
  }

color BiasToColor(const ENUM_SMC_BIAS bias)
  {
   if(bias==SMC_BIAS_BULLISH)
      return InpBullColor;
   if(bias==SMC_BIAS_BEARISH)
      return InpBearColor;
   return InpNeutralColor;
  }

void CreateLabel(const string name,const string text,const int x,const int y,const color clr,const int fontSize=9)
  {
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,InpDashboardCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,fontSize);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
  }

void DrawDashboard()
  {
   DeleteObjectsByPrefix(SMC_PREFIX+"DASH_");

   int bull=0,bear=0;
   string latestSignal="Last: None";
   datetime latestSignalTime=0;
   for(int i=0;i<SMC_TF_COUNT;i++)
     {
      if(g_tfStates[i].bias==SMC_BIAS_BULLISH)
         bull++;
      else if(g_tfStates[i].bias==SMC_BIAS_BEARISH)
         bear++;

      if(g_tfStates[i].buySignal.valid && g_tfStates[i].buySignal.signalTime>latestSignalTime)
        {
         latestSignalTime=g_tfStates[i].buySignal.signalTime;
         latestSignal="Last: BUY "+g_tfStates[i].buySignal.signalName+" @ "+g_tfStates[i].name;
        }
      if(g_tfStates[i].sellSignal.valid && g_tfStates[i].sellSignal.signalTime>latestSignalTime)
        {
         latestSignalTime=g_tfStates[i].sellSignal.signalTime;
         latestSignal="Last: SELL "+g_tfStates[i].sellSignal.signalName+" @ "+g_tfStates[i].name;
        }
     }

   ObjectCreate(0,SMC_PREFIX+"DASH_BG",OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,SMC_PREFIX+"DASH_BG",OBJPROP_CORNER,InpDashboardCorner);
   ObjectSetInteger(0,SMC_PREFIX+"DASH_BG",OBJPROP_XDISTANCE,InpDashboardX);
   ObjectSetInteger(0,SMC_PREFIX+"DASH_BG",OBJPROP_YDISTANCE,InpDashboardY);
   ObjectSetInteger(0,SMC_PREFIX+"DASH_BG",OBJPROP_XSIZE,280);
   ObjectSetInteger(0,SMC_PREFIX+"DASH_BG",OBJPROP_YSIZE,182);
   ObjectSetInteger(0,SMC_PREFIX+"DASH_BG",OBJPROP_BGCOLOR,InpDashboardBgColor);
   ObjectSetInteger(0,SMC_PREFIX+"DASH_BG",OBJPROP_COLOR,InpTradeLineColor);

   CreateLabel(SMC_PREFIX+"DASH_TITLE","SMC MultiTF EA",InpDashboardX+10,InpDashboardY+8,InpTradeLineColor,10);
   for(int i=0;i<SMC_TF_COUNT;i++)
     {
      string row=g_tfStates[i].name+": "+BiasToText(g_tfStates[i].bias)+" | "+g_tfStates[i].lastSignalLabel;
      CreateLabel(SMC_PREFIX+"DASH_TF_"+(string)i,row,InpDashboardX+10,InpDashboardY+28+(i*18),BiasToColor(g_tfStates[i].bias),9);
     }

   string modeText=(InpUseGlobalMode ? "Global "+IntegerToString((int)InpGlobalMode) : "Per-TF");
   CreateLabel(SMC_PREFIX+"DASH_C1","Confluence B/S: "+IntegerToString(bull)+"/"+IntegerToString(bear),InpDashboardX+10,InpDashboardY+122,InpDashboardTextColor,9);
   CreateLabel(SMC_PREFIX+"DASH_C2","Mode: "+modeText+" | Open: "+IntegerToString(CountOpenPositions()),InpDashboardX+10,InpDashboardY+138,InpDashboardTextColor,9);
   CreateLabel(SMC_PREFIX+"DASH_C3",latestSignal,InpDashboardX+10,InpDashboardY+154,InpDashboardTextColor,9);
   double spread=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
   CreateLabel(SMC_PREFIX+"DASH_C4","Symbol: "+_Symbol+" | Spread: "+DoubleToString(spread,1),InpDashboardX+10,InpDashboardY+170,InpDashboardTextColor,9);
  }

void LogEvent(const string message)
  {
   if(InpEnablePrintLogs)
      Print(message);
   if(InpEnableNativeAlerts)
      Alert(message);
   if(InpEnablePushAlerts)
      SendNotification(message);
  }

string UrlEncode(string text)
  {
   StringReplace(text,"%","%25");
   StringReplace(text,"\n","%0A");
   StringReplace(text," ","%20");
   StringReplace(text,"#","%23");
   StringReplace(text,"&","%26");
   StringReplace(text,"?","%3F");
   StringReplace(text,"=","%3D");
   return text;
  }

void SendTelegram(const string message)
  {
   if(!InpEnableTelegramAlerts || InpTelegramBotToken=="" || InpTelegramChatId=="")
      return;

   string url="https://api.telegram.org/bot"+InpTelegramBotToken+"/sendMessage";
   string payload="chat_id="+InpTelegramChatId+"&text="+UrlEncode(message);
   char post[];
   char result[];
   string headers="Content-Type: application/x-www-form-urlencoded\r\n";
   StringToCharArray(payload,post,0,StringLen(payload));
   ResetLastError();
   int rc=WebRequest("POST",url,headers,5000,post,result,headers);
   if(rc==-1 && InpEnablePrintLogs)
      Print("Telegram WebRequest failed: ",GetLastError());
  }

void NotifyAll(const string message)
  {
   LogEvent(message);
   SendTelegram(message);
  }

int CountOpenPositions()
  {
   int total=0;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)==_Symbol && (long)PositionGetInteger(POSITION_MAGIC)==InpMagicNumber)
         total++;
     }
   return total;
  }

int FindManagedPosition(const ulong ticket)
  {
   for(int i=0;i<g_positionCount;i++)
      if(g_positions[i].ticket==ticket)
         return i;
   return -1;
  }

void AddOrUpdateManagedPosition(const ulong ticket,const ENUM_POSITION_TYPE type,const double entry,const double sl,const double tp,const double partialPrice)
  {
   int idx=FindManagedPosition(ticket);
   if(idx<0 && g_positionCount<ArraySize(g_positions))
     {
      idx=g_positionCount++;
      g_positions[idx].ticket=ticket;
      g_positions[idx].type=type;
      g_positions[idx].entryPrice=entry;
      g_positions[idx].initialSL=sl;
      g_positions[idx].initialTP=tp;
      g_positions[idx].partialPrice=partialPrice;
      g_positions[idx].partialClosed=false;
      g_positions[idx].breakEvenDone=false;
     }
   else if(idx>=0)
     {
      g_positions[idx].type=type;
      g_positions[idx].entryPrice=entry;
     }
  }

void RemoveManagedPosition(const ulong ticket)
  {
   int idx=FindManagedPosition(ticket);
   if(idx<0)
      return;
   for(int i=idx;i<g_positionCount-1;i++)
      g_positions[i]=g_positions[i+1];
   g_positionCount--;
  }

double CalculateRR(const ManagedPosition &pos,const double marketPrice)
  {
   double risk=(pos.type==POSITION_TYPE_BUY ? pos.entryPrice-pos.initialSL : pos.initialSL-pos.entryPrice);
   if(risk<=0.0)
      return 0.0;
   double reward=(pos.type==POSITION_TYPE_BUY ? marketPrice-pos.entryPrice : pos.entryPrice-marketPrice);
   return reward/risk;
  }

bool SymbolContainsCurrency(const string symbolCurrency,const string eventCurrency)
  {
   if(symbolCurrency==eventCurrency)
      return true;
   return false;
  }

bool IsNewsWindowBlocked()
  {
   if(!InpEnableNewsFilter)
      return false;

   string base=SymbolInfoString(_Symbol,SYMBOL_CURRENCY_BASE);
   string profit=SymbolInfoString(_Symbol,SYMBOL_CURRENCY_PROFIT);
   datetime from=TimeCurrent()-(InpNewsBufferMinutesBefore*60);
   datetime to=TimeCurrent()+(InpNewsBufferMinutesAfter*60);
   MqlCalendarValue values[];
   int total=CalendarValueHistory(values,from,to,"","");
   if(total<=0)
      return false;

   for(int i=0;i<total;i++)
     {
      MqlCalendarEvent event;
      if(!CalendarEventById(values[i].event_id,event))
         continue;
      if(event.importance!=CALENDAR_IMPORTANCE_HIGH)
         continue;

      MqlCalendarCountry country;
      string currency="";
      if(CalendarCountryById((long)event.country_id,country))
         currency=country.currency;

      if(SymbolContainsCurrency(base,currency) || SymbolContainsCurrency(profit,currency))
         return true;
     }
   return false;
  }

void RefreshTimeframeState(const int slot)
  {
   MqlRates rates[];
   int count=0;
   if(!LoadRates(g_tfStates[slot].timeframe,rates,count))
      return;

   StructureSignal previousBuy=g_tfStates[slot].buySignal;
   StructureSignal previousSell=g_tfStates[slot].sellSignal;

   g_tfStates[slot].mode=ModeForSlot(slot);
   DetectBullishSignal(g_tfStates[slot].timeframe,g_tfStates[slot].name,g_tfStates[slot].mode,rates,count,g_tfStates[slot].buySignal);
   DetectBearishSignal(g_tfStates[slot].timeframe,g_tfStates[slot].name,g_tfStates[slot].mode,rates,count,g_tfStates[slot].sellSignal);

   g_tfStates[slot].buySignal.fresh=(g_tfStates[slot].buySignal.valid && g_tfStates[slot].buySignal.signalTime!=previousBuy.signalTime);
   g_tfStates[slot].sellSignal.fresh=(g_tfStates[slot].sellSignal.valid && g_tfStates[slot].sellSignal.signalTime!=previousSell.signalTime);

   if(g_tfStates[slot].buySignal.valid && (!g_tfStates[slot].sellSignal.valid || g_tfStates[slot].buySignal.signalTime>=g_tfStates[slot].sellSignal.signalTime))
     {
      g_tfStates[slot].bias=SMC_BIAS_BULLISH;
      g_tfStates[slot].lastSignalLabel=g_tfStates[slot].buySignal.signalName;
      if(g_tfStates[slot].buySignal.fresh)
         NotifyAll("Bullish signal detected on "+_Symbol+" ["+g_tfStates[slot].name+"] "+g_tfStates[slot].buySignal.signalName);
      if(InpDrawAllTimeframes || slot==SMC_TF_COUNT-1)
         DrawStructure(slot,g_tfStates[slot].buySignal);
     }
   else if(g_tfStates[slot].sellSignal.valid)
     {
      g_tfStates[slot].bias=SMC_BIAS_BEARISH;
      g_tfStates[slot].lastSignalLabel=g_tfStates[slot].sellSignal.signalName;
      if(g_tfStates[slot].sellSignal.fresh)
         NotifyAll("Bearish signal detected on "+_Symbol+" ["+g_tfStates[slot].name+"] "+g_tfStates[slot].sellSignal.signalName);
      if(InpDrawAllTimeframes || slot==SMC_TF_COUNT-1)
         DrawStructure(slot,g_tfStates[slot].sellSignal);
     }
   else
     {
      g_tfStates[slot].bias=SMC_BIAS_NEUTRAL;
      g_tfStates[slot].lastSignalLabel="None";
      if(InpDrawAllTimeframes || slot==SMC_TF_COUNT-1)
         DeleteObjectsByPrefix(SMC_PREFIX+g_tfStates[slot].name+"_");
     }
  }

void ProcessNewBars()
  {
   for(int i=0;i<SMC_TF_COUNT;i++)
     {
      datetime closedBar=iTime(_Symbol,g_tfStates[i].timeframe,1);
      if(closedBar<=0)
         continue;
      if(g_tfStates[i].lastProcessedBar!=closedBar)
        {
         g_tfStates[i].lastProcessedBar=closedBar;
         RefreshTimeframeState(i);
        }
     }
  }

bool ExecuteSignal(const StructureSignal &signal)
  {
   if(!signal.valid || signal.signalTime<=0)
      return false;
   if(!g_tradingArmed)
      return false;
   if(CountOpenPositions()>=InpMaxOpenPositions)
      return false;
   if(IsNewsWindowBlocked())
      return false;

   double marketPrice=(signal.side==SMC_SIDE_BUY ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID));
   double riskDistance=MathAbs(marketPrice-signal.stopLoss);
   if(marketPrice<=0.0 || riskDistance<=0.0)
      return false;

   double takeProfit=(signal.side==SMC_SIDE_BUY ? marketPrice+(riskDistance*InpRiskRewardMultiplier) : marketPrice-(riskDistance*InpRiskRewardMultiplier));
   marketPrice=NormalizePrice(marketPrice);
   takeProfit=NormalizePrice(takeProfit);

   int stopsLevel=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double minStopDistance=(double)stopsLevel*_Point;
   if(minStopDistance>0.0)
     {
      if(MathAbs(marketPrice-signal.stopLoss)<minStopDistance || MathAbs(takeProfit-marketPrice)<minStopDistance)
        {
         if(InpEnablePrintLogs)
            Print("Order rejected by EA due to broker stop-level distance. Min=",DoubleToString(minStopDistance,_Digits));
         return false;
        }
     }

   double volume=CalculateOrderVolume(marketPrice,signal.stopLoss);
   if(volume<=0.0)
      return false;

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpMaxSlippagePoints);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   bool sent=false;
   string comment=signal.commentTag;
   if(signal.side==SMC_SIDE_BUY)
      sent=g_trade.Buy(volume,_Symbol,0.0,signal.stopLoss,takeProfit,comment);
   else
      sent=g_trade.Sell(volume,_Symbol,0.0,signal.stopLoss,takeProfit,comment);

   if(sent)
     {
      string msg=(signal.side==SMC_SIDE_BUY ? "Buy" : "Sell")+" trade opened on "+_Symbol+" ["+signal.timeframeName+"] "+signal.signalName;
      NotifyAll(msg);
      return true;
     }

   if(InpEnablePrintLogs)
      Print("Order send failed: ",g_trade.ResultRetcode()," ",g_trade.ResultRetcodeDescription());
   return false;
  }

void EvaluateConfluenceAndTrade()
  {
   int bull=0,bear=0;
   StructureSignal bestBuy;
   StructureSignal bestSell;
   ResetSignal(bestBuy);
   ResetSignal(bestSell);

   for(int i=0;i<SMC_TF_COUNT;i++)
     {
      if(g_tfStates[i].bias==SMC_BIAS_BULLISH)
         bull++;
      if(g_tfStates[i].bias==SMC_BIAS_BEARISH)
         bear++;

      if(g_tfStates[i].buySignal.valid && g_tfStates[i].buySignal.fresh)
        {
         if(bestBuy.signalTime<g_tfStates[i].buySignal.signalTime)
            bestBuy=g_tfStates[i].buySignal;
        }
      if(g_tfStates[i].sellSignal.valid && g_tfStates[i].sellSignal.fresh)
        {
         if(bestSell.signalTime<g_tfStates[i].sellSignal.signalTime)
            bestSell=g_tfStates[i].sellSignal;
        }
     }

   if(bull>=InpMinConfluence && bestBuy.valid && bestBuy.signalTime>g_lastBuyExecuted && (bestSell.signalTime<=bestBuy.signalTime || bear<InpMinConfluence))
     {
      if(ExecuteSignal(bestBuy))
         g_lastBuyExecuted=bestBuy.signalTime;
     }

   if(bear>=InpMinConfluence && bestSell.valid && bestSell.signalTime>g_lastSellExecuted && (bestBuy.signalTime<bestSell.signalTime || bull<InpMinConfluence))
     {
      if(ExecuteSignal(bestSell))
         g_lastSellExecuted=bestSell.signalTime;
     }
  }

void ManagePositions()
  {
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber)
         continue;

      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double entry=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double currentPrice=(type==POSITION_TYPE_BUY ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK));
      double partial=(type==POSITION_TYPE_BUY ? entry+MathAbs(entry-sl)*InpPartialRR : entry-MathAbs(sl-entry)*InpPartialRR);
      AddOrUpdateManagedPosition(ticket,type,entry,sl,tp,NormalizePrice(partial));
      int idx=FindManagedPosition(ticket);
      if(idx<0)
         continue;

      double rr=CalculateRR(g_positions[idx],currentPrice);
      double volume=PositionGetDouble(POSITION_VOLUME);

      if(!g_positions[idx].partialClosed)
        {
         bool partialHit=((type==POSITION_TYPE_BUY && currentPrice>=g_positions[idx].partialPrice) ||
                          (type==POSITION_TYPE_SELL && currentPrice<=g_positions[idx].partialPrice));
         if(partialHit && InpPartialClosePercent>0.0 && InpPartialClosePercent<100.0)
           {
            double closeVolume=ClampVolume(volume*(InpPartialClosePercent/100.0));
            if(closeVolume<volume && g_trade.PositionClosePartial(ticket,closeVolume))
              {
               g_positions[idx].partialClosed=true;
               NotifyAll("Partial close executed on "+_Symbol+" ticket "+(string)ticket);
              }
           }
        }

      if(InpEnableBreakEven && !g_positions[idx].breakEvenDone && rr>=InpBreakEvenRR)
        {
         double newSL=(type==POSITION_TYPE_BUY ? entry+UnitsToPrice(InpBreakEvenOffsetPoints) : entry-UnitsToPrice(InpBreakEvenOffsetPoints));
         if((type==POSITION_TYPE_BUY && newSL>sl) || (type==POSITION_TYPE_SELL && (sl==0.0 || newSL<sl)))
           {
            if(g_trade.PositionModify(ticket,NormalizePrice(newSL),tp))
              {
               g_positions[idx].breakEvenDone=true;
               NotifyAll("Break-even triggered on "+_Symbol+" ticket "+(string)ticket);
              }
           }
        }

      if(InpEnableTrailingStop)
        {
         double startDistance=UnitsToPrice(InpTrailingStartDistance);
         double stepDistance=UnitsToPrice(InpTrailingStepDistance);
         bool canTrail=((type==POSITION_TYPE_BUY && currentPrice-entry>=startDistance) ||
                        (type==POSITION_TYPE_SELL && entry-currentPrice>=startDistance) ||
                        g_positions[idx].partialClosed || rr>=InpPartialRR);
         if(canTrail)
           {
            double newSL=sl;
            if(type==POSITION_TYPE_BUY)
              {
               newSL=NormalizePrice(currentPrice-stepDistance);
               if(newSL>sl)
                  g_trade.PositionModify(ticket,newSL,tp);
              }
            else
              {
               newSL=NormalizePrice(currentPrice+stepDistance);
               if(sl==0.0 || newSL<sl)
                  g_trade.PositionModify(ticket,newSL,tp);
              }
           }
        }
     }

   DrawTradeLevels();
  }

int OnInit()
  {
   InitializeTimeframes();
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetDeviationInPoints(InpMaxSlippagePoints);

   ProcessNewBars();
   for(int i=0;i<SMC_TF_COUNT;i++)
     {
      g_tfStates[i].buySignal.fresh=false;
      g_tfStates[i].sellSignal.fresh=false;
     }
   DrawDashboard();
   NotifyAll("SMC_MultiTF_EA initialized on "+_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   DeleteObjectsByPrefix(SMC_PREFIX);
   if(InpEnablePrintLogs)
      Print("SMC_MultiTF_EA deinitialized. Reason=",reason);
  }

void OnTick()
  {
   ProcessNewBars();
   ManagePositions();
   if(!g_tradingArmed)
     {
      g_tradingArmed=true;
      DrawDashboard();
      return;
     }
   EvaluateConfluenceAndTrade();
   DrawDashboard();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD)
      return;
   if(trans.deal==0)
      return;
   if(!HistoryDealSelect(trans.deal))
      return;

   string symbol=HistoryDealGetString(trans.deal,DEAL_SYMBOL);
   long magic=HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
   if(symbol!=_Symbol || magic!=InpMagicNumber)
      return;

   ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
   ENUM_DEAL_REASON reason=(ENUM_DEAL_REASON)HistoryDealGetInteger(trans.deal,DEAL_REASON);
   ulong positionId=(ulong)HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID);

   if(entry==DEAL_ENTRY_IN)
     {
      double price=HistoryDealGetDouble(trans.deal,DEAL_PRICE);
      double volume=HistoryDealGetDouble(trans.deal,DEAL_VOLUME);
      NotifyAll("Trade filled on "+symbol+" price "+DoubleToString(price,_Digits)+" volume "+DoubleToString(volume,2));
     }
   else if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY)
     {
      if(reason==DEAL_REASON_TP)
         NotifyAll("Take profit hit on "+symbol);
      else if(reason==DEAL_REASON_SL)
         NotifyAll("Stop loss hit on "+symbol);
      RemoveManagedPosition(positionId);
     }
  }
