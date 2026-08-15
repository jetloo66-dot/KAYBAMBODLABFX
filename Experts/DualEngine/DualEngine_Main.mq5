//+------------------------------------------------------------------+
//|                                           DualEngine_Main.mq5   |
//|                    ICT + SMC Dual-Engine Expert Advisor          |
//|                    DualEngine Architecture — v1.00               |
//|                    Author: jetloo66-dot / KAYBAMBODLABFX         |
//|                                                                  |
//|  Architecture:                                                   |
//|    MarketRegimeAnalyzer -> selects ICT or SMC (or both) engine  |
//|    ICT_Engine   -> pure ICT concepts (FVG, OTE, Premium/Disc.)  |
//|    SMC_Engine   -> pure SMC concepts (AMD cycle, OB, BOS, CHoCH)|
//|    DualEngine_Main -> orchestrates, executes trades, manages risk|
//+------------------------------------------------------------------+
#property copyright "jetloo66-dot / KAYBAMBODLABFX"
#property link      "https://github.com/jetloo66-dot/KAYBAMBODLABFX"
#property version   "1.00"
#property strict
#property description "ICT + SMC Dual-Engine EA with Market Regime Analyzer"

#include <Trade\Trade.mqh>
#include "MarketRegime.mqh"
#include "ICT_Engine.mqh"
#include "SMC_Engine.mqh"

//+------------------------------------------------------------------+
//|  Engine Mode Override                                            |
//+------------------------------------------------------------------+
enum ENUM_ENGINE_MODE
{
   MODE_AUTO        = 0,   // Market Regime Analyzer decides
   MODE_ICT_ONLY    = 1,   // Always use ICT engine only
   MODE_SMC_ONLY    = 2,   // Always use SMC engine only
   MODE_BOTH_ALWAYS = 3    // Always evaluate both, take higher confidence
};

//+------------------------------------------------------------------+
//|  Input Parameters                                                |
//+------------------------------------------------------------------+

// ---- Engine Control ----
input group "=== ENGINE SETTINGS ==="
input ENUM_ENGINE_MODE EngineMode          = MODE_AUTO;        // Engine selection mode
input bool   EnableDiagnostics             = true;             // Enable diagnostic prints

// ---- Timeframe Settings ----
input group "=== TIMEFRAME SETTINGS ==="
input ENUM_TIMEFRAMES HTF_Timeframe        = PERIOD_H4;        // Higher timeframe (trend / regime)
input ENUM_TIMEFRAMES EntryTimeframe       = PERIOD_M15;       // Entry timeframe (signal generation)

// ---- Market Regime Analyzer ----
input group "=== MARKET REGIME ANALYZER ==="
input int    ADX_Period                    = 14;               // ADX indicator period
input double ADX_TrendLevel                = 25.0;             // ADX >= this = trending
input double ADX_RangeLevel                = 20.0;             // ADX <= this = ranging
input int    ATR_AvgBars                   = 50;               // Bars for average ATR (regime)
input double ATR_VolatileMult              = 1.5;              // ATR mult to flag volatile regime
input int    SwingRadius                   = 3;                // Swing detection radius (regime)

// ---- ATR Settings ----
input group "=== ATR SETTINGS ==="
input int    ATR_Period                    = 14;               // ATR period (entry TF)
input int    HTF_ATR_Period                = 14;               // ATR period (HTF)

// ---- ICT Engine Settings ----
input group "=== ICT ENGINE ==="
input int    FVG_LookbackBars              = 15;               // FVG search lookback (bars)
input double FVG_MinSizeATR                = 0.05;             // FVG minimum size as ATR fraction
input int    ICT_GMT_Offset                = 0;                // GMT offset for killzones
input double ICT_SL_BufferATR              = 0.5;              // ICT SL buffer (ATR multiples)

// ---- SMC Engine / AMD Cycle ----
input group "=== SMC ENGINE — AMD CYCLE ==="
input int    AccumulationBars              = 20;               // Bars to analyse for accumulation
input double AccumulationATRMultiplier     = 5.0;              // Max range as ATR multiple (legacy)
input double AdaptiveRangeRatio            = 0.7;              // Adaptive range ratio (v2.30 fix)
input double MaxBodyToRangeRatio           = 0.5;              // Max body/range ratio (v2.30 fix)
input double ManipulationPips              = 3.0;              // Min pip sweep beyond range
input int    ManipulationBars              = 5;                // Max bars for manipulation check
input int    OB_LookbackBars               = 10;               // OB / Breaker lookback (bars)
input double OB_ImpulseATRMultiplier       = 0.4;              // Impulse body as ATR multiple
input int    SMC_SwingRadius               = 3;                // Swing radius for BOS / CHoCH
input int    SMC_SwingLookback             = 30;               // Lookback bars for BOS / CHoCH
input int    MaxBarsInState                = 100;              // AMD state-machine timeout
input double SMC_SL_BufferATR              = 0.5;              // SMC SL buffer (ATR multiples)

// ---- Risk Management ----
input group "=== RISK MANAGEMENT ==="
input double RiskPercent                   = 1.0;              // Risk per trade (% of balance)
input double MinRiskReward                 = 2.0;              // Minimum risk:reward ratio
input double MaxSpreadPoints               = 50;               // Max spread (points)
input int    MaxOpenTrades                 = 1;                // Max concurrent trades
input int    MagicNumber                   = 234567;           // EA magic number
input int    SlippagePoints                = 20;               // Slippage tolerance (points)
input int    MinConfluenceScore            = 40;               // Min confidence score to trade
input int    ConflictEdgeThreshold         = 20;               // Min score gap needed to trade when engines disagree

// ---- Stop Loss / Trailing / Break-Even ----
input group "=== STOP LOSS / TRAILING ==="
input bool   UseTrailingSL                 = true;             // Enable trailing stop
input double TrailingSLATR                 = 1.0;              // Trailing SL distance (ATR mult)
input bool   UseBreakEven                  = true;             // Enable break-even
input double BreakEvenATR                  = 1.0;              // Move SL to BE when profit >= ATR mult

//+------------------------------------------------------------------+
//|  Global Variables                                                |
//+------------------------------------------------------------------+
CTrade  g_trade;

// Indicator handles (created in OnInit, never inside detection functions)
int g_atrHandle    = INVALID_HANDLE;   // ATR on entry TF
int g_htfAtrHandle = INVALID_HANDLE;   // ATR on HTF
int g_adxHandle    = INVALID_HANDLE;   // ADX on HTF (for regime)

// Bar tracking
datetime g_lastEntryBarTime = 0;
datetime g_lastHTFBarTime   = 0;

// Regime and engine cache (updated on new HTF bar only)
ENUM_MARKET_REGIME g_currentRegime = REGIME_CHOPPY;
ENUM_ENGINE_SELECT g_engineSelect  = ENGINE_NONE;
double             g_adxValue      = 0.0;

// HTF swing levels
double g_htfSwingHigh = 0.0;
double g_htfSwingLow  = 0.0;
int    g_htfDirection = 0;

// SMC persistent state
SMC_State g_smcState;

//+------------------------------------------------------------------+
//|  OnInit                                                          |
//+------------------------------------------------------------------+
int OnInit()
{
   PrintFormat("DualEngine EA init | %s | HTF: %s | Entry: %s | Mode: %s",
      Symbol(),
      EnumToString(HTF_Timeframe),
      EnumToString(EntryTimeframe),
      EnumToString(EngineMode));

   // Create ATR handles on the correct timeframes
   g_atrHandle    = iATR(Symbol(), EntryTimeframe, ATR_Period);
   g_htfAtrHandle = iATR(Symbol(), HTF_Timeframe,  HTF_ATR_Period);
   g_adxHandle    = iADX(Symbol(), HTF_Timeframe,  ADX_Period);

   if(g_atrHandle    == INVALID_HANDLE ||
      g_htfAtrHandle == INVALID_HANDLE ||
      g_adxHandle    == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create one or more indicator handles");
      return INIT_FAILED;
   }

   // Configure CTrade
   g_trade.SetExpertMagicNumber(MagicNumber);
   g_trade.SetDeviationInPoints(SlippagePoints);

   ENUM_ORDER_TYPE_FILLING fillMode = ORDER_FILLING_RETURN;
   long fillingModes = SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE);
   if((fillingModes & SYMBOL_FILLING_IOC) != 0) fillMode = ORDER_FILLING_IOC;
   if((fillingModes & SYMBOL_FILLING_FOK) != 0) fillMode = ORDER_FILLING_FOK;
   g_trade.SetTypeFilling(fillMode);

   // Initialise SMC state machine
   SMC_InitState(g_smcState);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//|  OnDeinit                                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_atrHandle    != INVALID_HANDLE) { IndicatorRelease(g_atrHandle);    g_atrHandle    = INVALID_HANDLE; }
   if(g_htfAtrHandle != INVALID_HANDLE) { IndicatorRelease(g_htfAtrHandle); g_htfAtrHandle = INVALID_HANDLE; }
   if(g_adxHandle    != INVALID_HANDLE) { IndicatorRelease(g_adxHandle);    g_adxHandle    = INVALID_HANDLE; }
   PrintFormat("DualEngine EA removed. Reason: %d", reason);
}

//+------------------------------------------------------------------+
//|  OnTick                                                          |
//+------------------------------------------------------------------+
void OnTick()
{
   // Manage open positions on every tick (trailing SL / break-even)
   ManageOpenTrades();

   // --- New HTF bar: update regime, swing levels, and engine selection ---
   datetime htfBarTime = iTime(Symbol(), HTF_Timeframe, 1);
   if(htfBarTime != g_lastHTFBarTime)
   {
      g_lastHTFBarTime = htfBarTime;
      UpdateHTFAnalysis();
   }

   // --- New entry TF bar: check signals ---
   datetime entryBarTime = iTime(Symbol(), EntryTimeframe, 1);
   if(entryBarTime == g_lastEntryBarTime) return;
   g_lastEntryBarTime = entryBarTime;

   // Spread filter
   if(IsSpreadTooHigh())
   {
      if(EnableDiagnostics) Print("[Main] Spread too high — skipping bar");
      return;
   }

   // Max open trades guard
   if(CountOpenTrades() >= MaxOpenTrades) return;

   // Determine which engine(s) to run
   ENUM_ENGINE_SELECT engineToUse = DetermineEngine();
   if(engineToUse == ENGINE_NONE)
   {
      if(EnableDiagnostics) Print("[Main] ENGINE_NONE — regime is choppy, skipping");
      return;
   }

   // Run selected engine(s)
   SignalResult ictResult, smcResult;
   ictResult.direction  = 0;
   ictResult.confidence = 0;
   ictResult.entryType  = "";
   ictResult.engineName = "ICT";
   smcResult.direction  = 0;
   smcResult.confidence = 0;
   smcResult.entryType  = "";
   smcResult.engineName = "SMC";

   bool runICT = (engineToUse == ENGINE_ICT  || engineToUse == ENGINE_BOTH);
   bool runSMC = (engineToUse == ENGINE_SMC  || engineToUse == ENGINE_BOTH);

   if(runICT)
   {
      ictResult = ICT_Analyze(
         Symbol(), EntryTimeframe,
         g_atrHandle,
         FVG_LookbackBars, FVG_MinSizeATR,
         ICT_SL_BufferATR, MinRiskReward,
         ICT_GMT_Offset,
         g_htfSwingHigh, g_htfSwingLow,
         g_htfDirection,
         g_currentRegime, g_adxValue
      );
   }

   if(runSMC)
   {
      smcResult = SMC_Analyze(
         g_smcState,
         Symbol(), EntryTimeframe,
         g_atrHandle,
         g_htfDirection,
         AccumulationBars,
         AccumulationATRMultiplier,
         AdaptiveRangeRatio,
         MaxBodyToRangeRatio,
         ManipulationBars, ManipulationPips,
         OB_LookbackBars, OB_ImpulseATRMultiplier,
         SMC_SwingRadius, SMC_SwingLookback,
         MaxBarsInState,
         SMC_SL_BufferATR, MinRiskReward,
         g_currentRegime, g_adxValue,
         EnableDiagnostics
      );
   }

   if(EnableDiagnostics)
   {
      if(runICT) PrintFormat("[Main] ICT  score=%d dir=%d type=%s rr=%.2f",
         ictResult.confidence, ictResult.direction, ictResult.entryType, ictResult.riskReward);
      if(runSMC) PrintFormat("[Main] SMC  score=%d dir=%d type=%s rr=%.2f",
         smcResult.confidence, smcResult.direction, smcResult.entryType, smcResult.riskReward);
   }

   // Pick the best signal
   SignalResult best = SelectBestSignal(ictResult, smcResult, engineToUse);

   // Execute if signal qualifies
   if(best.direction != 0 && best.confidence >= MinConfluenceScore)
   {
      ExecuteTrade(best);
   }
}

//+------------------------------------------------------------------+
//|  UpdateHTFAnalysis                                              |
//|  Called on new HTF bar. Updates regime and swing levels.        |
//+------------------------------------------------------------------+
void UpdateHTFAnalysis()
{
   // Read ADX
   double adxBuf[];
   ArraySetAsSeries(adxBuf, true);
   if(CopyBuffer(g_adxHandle, 0, 1, 3, adxBuf) >= 3)
      g_adxValue = adxBuf[0];

   // Classify market regime
   g_currentRegime = MR_GetMarketRegime(
      Symbol(), HTF_Timeframe,
      g_adxHandle, g_htfAtrHandle,
      ADX_Period, HTF_ATR_Period,
      ATR_AvgBars, SwingRadius,
      ADX_TrendLevel, ADX_RangeLevel,
      ATR_VolatileMult
   );

   // Update HTF swing reference levels
   SMC_DetectSwings(Symbol(), HTF_Timeframe, 50, SwingRadius, g_htfSwingHigh, g_htfSwingLow);

   // HTF direction from BOS (1=bull, -1=bear, 0=none)
   g_htfDirection = SMC_DetectBOS(Symbol(), HTF_Timeframe, SwingRadius, 50);

   // Pre-compute engine selection (MODE_AUTO only)
   if(EngineMode == MODE_AUTO)
   {
      double ictScore = ICT_GetRegimeScore(g_currentRegime, g_adxValue);
      double smcScore = SMC_GetRegimeScore(g_currentRegime, g_adxValue);
      g_engineSelect  = MR_SelectEngine(g_currentRegime, ictScore, smcScore);

      if(EnableDiagnostics)
         PrintFormat("[Regime] %s | ADX=%.1f | ICTscore=%.0f SMCscore=%.0f | Engine=%s | HTFDir=%d",
            MR_RegimeToString(g_currentRegime), g_adxValue,
            ictScore, smcScore,
            MR_EngineToString(g_engineSelect), g_htfDirection);
   }
   else
   {
      if(EnableDiagnostics)
         PrintFormat("[Regime] %s | ADX=%.1f | HTFDir=%d | EngineMode=%s (override)",
            MR_RegimeToString(g_currentRegime), g_adxValue,
            g_htfDirection, EnumToString(EngineMode));
   }
}

//+------------------------------------------------------------------+
//|  DetermineEngine                                                |
//+------------------------------------------------------------------+
ENUM_ENGINE_SELECT DetermineEngine()
{
   switch(EngineMode)
   {
      case MODE_ICT_ONLY:    return ENGINE_ICT;
      case MODE_SMC_ONLY:    return ENGINE_SMC;
      case MODE_BOTH_ALWAYS: return ENGINE_BOTH;
      case MODE_AUTO:
      default:               return g_engineSelect;
   }
}

//+------------------------------------------------------------------+
//|  SelectBestSignal                                               |
//|  Returns the higher-confidence directionally-valid signal.      |
//+------------------------------------------------------------------+
SignalResult SelectBestSignal(
   const SignalResult &ict,
   const SignalResult &smc,
   const ENUM_ENGINE_SELECT mode
)
{
   // Only one engine ran
   if(mode == ENGINE_ICT) return ict;
   if(mode == ENGINE_SMC) return smc;

   // Both engines ran — prefer signals in agreement
   if(ict.direction != 0 && smc.direction != 0)
   {
      if(ict.direction == smc.direction)
      {
         // Same direction: take the higher confidence signal
         return (ict.confidence >= smc.confidence) ? ict : smc;
      }
      else
      {
         // Conflicting directions: take the higher confidence one,
         // but only if it exceeds the other by at least ConflictEdgeThreshold points
         int diff = ict.confidence - smc.confidence;
         if(MathAbs(diff) < ConflictEdgeThreshold)
         {
            SignalResult none;
            none.direction  = 0;
            none.confidence = 0;
            none.entryType  = "";
            none.engineName = "NONE";
            return none;
         }
         return (diff > 0) ? ict : smc;
      }
   }

   // Only one has a signal
   if(ict.direction != 0) return ict;
   if(smc.direction != 0) return smc;

   SignalResult none;
   none.direction  = 0;
   none.confidence = 0;
   none.entryType  = "";
   none.engineName = "NONE";
   return none;
}

//+------------------------------------------------------------------+
//|  CalculateLotSize                                               |
//|  Risk-percentage position sizing via tick value formula.        |
//+------------------------------------------------------------------+
double CalculateLotSize(const double slPoints)
{
   if(slPoints <= 0.0) return 0.0;

   double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0.0 || tickSize <= 0.0) return 0.0;

   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;

   double valuePerPoint = tickValue / tickSize;
   if(valuePerPoint <= 0.0) return 0.0;

   double lots = riskMoney / (slPoints * valuePerPoint);

   // Clamp to broker limits
   double minLot  = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   if(lotStep <= 0.0) lotStep = 0.01;

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//|  ExecuteTrade                                                   |
//|  Validates and sends the order via CTrade.                      |
//+------------------------------------------------------------------+
void ExecuteTrade(const SignalResult &sig)
{
   if(sig.direction == 0) return;

   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

   double entryPrice = NormalizeDouble(sig.entryPrice, digits);
   double sl         = NormalizeDouble(sig.stopLoss,   digits);
   double tp         = NormalizeDouble(sig.takeProfit, digits);

   double slPoints = MathAbs(entryPrice - sl) / SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if(slPoints <= 0.0)
   {
      Print("[Main] ExecuteTrade: SL distance is zero — skipping");
      return;
   }

   double lots = CalculateLotSize(slPoints);
   if(lots <= 0.0)
   {
      Print("[Main] ExecuteTrade: Lot size is zero — skipping");
      return;
   }

   string comment = StringFormat("DE_%s_%s", sig.engineName, sig.entryType);

   bool ok = false;
   if(sig.direction == 1)
   {
      double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      ok = g_trade.Buy(lots, Symbol(), ask, sl, tp, comment);
   }
   else
   {
      double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      ok = g_trade.Sell(lots, Symbol(), bid, sl, tp, comment);
   }

   if(ok)
   {
      PrintFormat("[Main] Trade placed | %s %s | engine=%s type=%s | lots=%.2f SL=%.5f TP=%.5f RR=%.2f score=%d",
         (sig.direction == 1 ? "BUY" : "SELL"), Symbol(),
         sig.engineName, sig.entryType,
         lots, sl, tp, sig.riskReward, sig.confidence);

      // After a successful SMC entry, reset its state so it looks for the next setup
      if(sig.engineName == "SMC")
         SMC_InitState(g_smcState);
   }
   else
   {
      PrintFormat("[Main] Trade FAILED | error=%d %s", g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//|  ManageOpenTrades                                               |
//|  Trailing SL and break-even management.                         |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   if(!UseTrailingSL && !UseBreakEven) return;

   // Retrieve current ATR for trailing distance
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(g_atrHandle, 0, 0, 3, atrBuf) < 3) return;
   double atr = atrBuf[0];
   if(atr <= 0.0) return;

   double trailDist = TrailingSLATR * atr;
   double beDist    = BreakEvenATR  * atr;

   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol())    continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      int    posType   = (int)PositionGetInteger(POSITION_TYPE);

      double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      int    digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

      double newSL = currentSL;

      if(posType == POSITION_TYPE_BUY)
      {
         double profit = bid - openPrice;

         // Break-even: move SL to open price when profit >= beDist
         if(UseBreakEven && profit >= beDist && currentSL < openPrice)
            newSL = NormalizeDouble(openPrice, digits);

         // Trailing SL: keep SL trailDist below current bid
         if(UseTrailingSL)
         {
            double trail = NormalizeDouble(bid - trailDist, digits);
            if(trail > newSL) newSL = trail;
         }

         if(newSL > currentSL && newSL < bid)
            g_trade.PositionModify(ticket, newSL, currentTP);
      }
      else if(posType == POSITION_TYPE_SELL)
      {
         double profit = openPrice - ask;

         if(UseBreakEven && profit >= beDist && (currentSL > openPrice || currentSL == 0.0))
            newSL = NormalizeDouble(openPrice, digits);

         if(UseTrailingSL)
         {
            double trail = NormalizeDouble(ask + trailDist, digits);
            if(currentSL == 0.0 || trail < newSL) newSL = trail;
         }

         if((currentSL == 0.0 || newSL < currentSL) && newSL > ask)
            g_trade.PositionModify(ticket, newSL, currentTP);
      }
   }
}

//+------------------------------------------------------------------+
//|  CountOpenTrades                                                |
//|  Counts positions for this EA / symbol.                         |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol())    continue;
      count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|  IsSpreadTooHigh                                                |
//+------------------------------------------------------------------+
bool IsSpreadTooHigh()
{
   double spread = (double)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   return (spread > MaxSpreadPoints);
}

