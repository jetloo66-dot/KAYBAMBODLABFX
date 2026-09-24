#property strict
#property version   "1.00"
#property description "KAYBAMBODLABFX modular structure EA for MT5"

#include <Trade/Trade.mqh>
#include "KAYB_Models.mqh"
#include "KAYB_Config.mqh"
#include "KAYB_Utils.mqh"
#include "KAYB_StructureEngine.mqh"
#include "KAYB_SetupEngines.mqh"
#include "KAYB_ExecutionRisk.mqh"
#include "KAYB_Filters.mqh"
#include "KAYB_AlertsDashboard.mqh"
#include "KAYB_TradeMemory.mqh"

CTrade g_trade;
KAYBWorkflow g_workflows[6];
KAYBStructureState g_states[6];
datetime g_lastContinuationEvent[6];
datetime g_lastSignalTime[6];
KAYBLimitSnapshot g_profitSnap;
KAYBLimitSnapshot g_lossSnap;

void KAYB_InitWorkflows()
{
   g_workflows[0].enabled = InpWF1Enabled;
   g_workflows[0].analysisTf = InpWF1AnalysisTF;
   g_workflows[0].confirmTf = InpWF1ConfirmTF;
   g_workflows[0].label = "WF1 D1->lower";

   g_workflows[1].enabled = InpWF2Enabled;
   g_workflows[1].analysisTf = InpWF2AnalysisTF;
   g_workflows[1].confirmTf = InpWF2ConfirmTF;
   g_workflows[1].label = "WF2 H4->lower";

   g_workflows[2].enabled = InpWF3Enabled;
   g_workflows[2].analysisTf = InpWF3AnalysisTF;
   g_workflows[2].confirmTf = InpWF3ConfirmTF;
   g_workflows[2].label = "WF3 H1->lower";

   g_workflows[3].enabled = InpWF4Enabled;
   g_workflows[3].analysisTf = InpWF4AnalysisTF;
   g_workflows[3].confirmTf = InpWF4ConfirmTF;
   g_workflows[3].label = "WF4 M30->lower";

   g_workflows[4].enabled = InpWF5Enabled;
   g_workflows[4].analysisTf = InpWF5AnalysisTF;
   g_workflows[4].confirmTf = InpWF5ConfirmTF;
   g_workflows[4].label = "WF5 M15->lower";

   g_workflows[5].enabled = InpWF6Enabled;
   g_workflows[5].analysisTf = InpWF6AnalysisTF;
   g_workflows[5].confirmTf = InpWF6ConfirmTF;
   g_workflows[5].label = "WF6 M5->M5";
}

bool KAYB_ValidateWorkflows()
{
   for(int i = 0; i < 6; ++i)
   {
      if(!g_workflows[i].enabled)
         continue;
      bool ok = KAYB_IsLowerOrEqualTF(g_workflows[i].analysisTf, g_workflows[i].confirmTf);
      if(!ok)
      {
         Print("Invalid workflow timeframe pair for ", g_workflows[i].label,
               ": analysis=", EnumToString(g_workflows[i].analysisTf),
               " confirmation=", EnumToString(g_workflows[i].confirmTf));
         return false;
      }
   }
   return true;
}

bool KAYB_IsDuplicateSignal(int idx, const KAYBSetupSignal &sig)
{
   if(g_lastSignalTime[idx] == 0)
      return false;
   return (sig.signalTime == g_lastSignalTime[idx]);
}

bool KAYB_EntryBlocked(string &reason)
{
   reason = "";
   if(!KAYB_IsInSession())
   {
      reason = "session filter";
      return true;
   }

   string newsReason;
   if(KAYB_IsNewsBlocked(newsReason))
   {
      reason = newsReason;
      return true;
   }

   if(KAYB_UpdateLimitState(g_profitSnap, g_lossSnap, reason))
      return true;

   return false;
}

void KAYB_ProcessSignals()
{
   string blockReason;
   bool blocked = KAYB_EntryBlocked(blockReason);

   for(int i = 0; i < 6; ++i)
   {
      if(!g_workflows[i].enabled)
         continue;

      KAYBStructureState stAnalysis = KAYB_BuildStructureState(g_workflows[i].analysisTf);
      KAYBStructureState stConfirm = KAYB_BuildStructureState(g_workflows[i].confirmTf);
      g_states[i] = stAnalysis.valid ? stAnalysis : stConfirm;

      if(!stAnalysis.valid || !stConfirm.valid)
         continue;

      // Reversal engine
      KAYBSetupSignal revSig = KAYB_BuildReversalSignal(stConfirm, g_workflows[i]);
      if(revSig.valid)
      {
         bool analysisAllowsLong = (stAnalysis.trend != KAYB_TREND_DOWN);
         bool analysisAllowsShort = (stAnalysis.trend != KAYB_TREND_UP);
         if((revSig.isBuy && !analysisAllowsLong) || (!revSig.isBuy && !analysisAllowsShort))
            revSig.valid = false;
      }
      if(revSig.valid && !KAYB_IsDuplicateSignal(i, revSig))
      {
         if(!blocked)
         {
            if(InpUseMemoryScoreFilter)
            {
               double score;
               int samples;
               if(KAYB_GetMemoryScore(_Symbol, InpMagicNumber, revSig.setupTag, revSig.filterTag, score, samples) && samples >= InpMemoryMinSample)
               {
                  if(score < InpMemoryScoreThreshold)
                  {
                     Print("Memory score rejected signal: ", DoubleToString(score, 3));
                     continue;
                  }
               }
            }

            if(KAYB_PlaceSignal(g_trade, revSig, InpMagicNumber))
            {
               g_lastSignalTime[i] = revSig.signalTime;
               g_lastContinuationEvent[i] = stConfirm.lastBreakTime;
               KAYB_DrawSignalZone(revSig);
               KAYB_Notify("Order placed: " + revSig.workflowLabel + " " + KAYB_SideToString(revSig.isBuy) + " " + revSig.setupTag + " " + revSig.filterTag);
            }
         }
      }

      // Continuation engine (duplicate-protected by break time)
      KAYBSetupSignal contSig = KAYB_BuildContinuationSignal(stConfirm, g_workflows[i], g_lastContinuationEvent[i]);
      if(contSig.valid && !KAYB_IsDuplicateSignal(i, contSig))
      {
         if(!blocked && KAYB_PlaceSignal(g_trade, contSig, InpMagicNumber))
         {
            g_lastSignalTime[i] = contSig.signalTime;
            g_lastContinuationEvent[i] = stConfirm.lastBreakTime;
            KAYB_DrawSignalZone(contSig);
            KAYB_Notify("Order placed: " + contSig.workflowLabel + " " + KAYB_SideToString(contSig.isBuy) + " " + contSig.setupTag);
         }
      }
   }

   KAYB_DrawDashboard(g_workflows, g_states, blocked, blockReason);
}

int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetMarginMode();

   KAYB_InitWorkflows();
   if(!KAYB_ValidateWorkflows())
      return INIT_PARAMETERS_INCORRECT;

   ArrayInitialize(g_lastContinuationEvent, 0);
   ArrayInitialize(g_lastSignalTime, 0);

   KAYB_InitLimitSnapshot(g_profitSnap);
   KAYB_InitLimitSnapshot(g_lossSnap);

   KAYB_ResetTradeMemoryIfNeeded();
   KAYB_EnsureMemoryFile();

   EventSetTimer(1);
   KAYB_Notify("KAYBAMBODLABFX MT5 Production EA initialized on " + _Symbol);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   KAYB_ClearVisuals();
   KAYB_Notify("KAYBAMBODLABFX EA stopped on " + _Symbol + " reason=" + IntegerToString(reason));
}

void OnTick()
{
   KAYB_ManageOpenPositions(g_trade, InpMagicNumber);
   if(InpScanEveryTick)
      KAYB_ProcessSignals();
}

void OnTimer()
{
   if(!InpScanEveryTick)
      KAYB_ProcessSignals();
   KAYB_ManageOpenPositions(g_trade, InpMagicNumber);
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   int used = (int)request.action + (int)result.retcode;
   if(used == -2147483648)
      Print("unused");
   KAYB_CaptureDealToMemory(trans);
}
