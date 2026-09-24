#property strict

bool KAYB_FilterA_VolumeNode(const MqlRates &rates[], bool isBuy, double ll1, double lh2, double &target)
{
   double lowBand = MathMin(ll1, lh2);
   double highBand = MathMax(ll1, lh2);
   double bestVol = -1.0;
   target = 0.0;

   int maxBars = MathMin(ArraySize(rates), InpSetupExpiryBars * 3);
   for(int i = 1; i < maxBars; ++i)
   {
      double mid = (rates[i].high + rates[i].low) * 0.5;
      if(mid < lowBand || mid > highBand)
         continue;
      if((double)rates[i].tick_volume > bestVol)
      {
         bestVol = (double)rates[i].tick_volume;
         target = mid;
      }
   }
   return (bestVol > 0.0);
}

bool KAYB_FilterB_EngulfZone(const MqlRates &rates[], bool isBuy, double &target)
{
   target = 0.0;
   int maxBars = MathMin(ArraySize(rates) - 2, InpSetupExpiryBars * 3);
   for(int i = 2; i < maxBars; ++i)
   {
      bool bullish = rates[i].close > rates[i].open;
      bool bearish = rates[i].close < rates[i].open;
      if(isBuy && bullish)
      {
         if(rates[i - 1].close < rates[i - 1].open && rates[i - 1].high >= rates[i].high && rates[i - 1].low <= rates[i].low)
         {
            target = rates[i].open;
            return true;
         }
      }
      if(!isBuy && bearish)
      {
         if(rates[i - 1].close > rates[i - 1].open && rates[i - 1].high >= rates[i].high && rates[i - 1].low <= rates[i].low)
         {
            target = rates[i].open;
            return true;
         }
      }
   }
   return false;
}

bool KAYB_FilterC_LastCandleBeforeBreak(const MqlRates &rates[], bool isBuy, double breakLevel, double &target)
{
   target = 0.0;
   int maxBars = MathMin(ArraySize(rates) - 1, InpSetupExpiryBars * 4);
   for(int i = 2; i < maxBars; ++i)
   {
      if(isBuy)
      {
         if(rates[i].close > rates[i].open && rates[i - 1].low < breakLevel)
         {
            target = rates[i].open;
            return true;
         }
      }
      else
      {
         if(rates[i].close < rates[i].open && rates[i - 1].high > breakLevel)
         {
            target = rates[i].open;
            return true;
         }
      }
   }
   return false;
}

bool KAYB_FilterD_Fib(bool isBuy, double ll1, double breakLevel, bool use618, double &target)
{
   double a = ll1;
   double b = breakLevel;
   if(a == b)
      return false;
   double ratio = use618 ? 0.618 : 0.5;
   if(isBuy)
      target = b - (b - a) * ratio;
   else
      target = b + (a - b) * ratio;
   return true;
}

bool KAYB_EvaluateFilterSelection(const bool enabledFlags[], const bool passedFlags[], int total)
{
   bool anyEnabled = false;
   for(int i = 0; i < total; ++i)
   {
      if(enabledFlags[i])
      {
         anyEnabled = true;
         break;
      }
   }
   if(!anyEnabled)
      return true;

   if(InpFilterCombinationMode == KAYB_FILTER_ANY)
   {
      for(int i = 0; i < total; ++i)
      {
         if(enabledFlags[i] && passedFlags[i])
            return true;
      }
      return false;
   }

   if(InpFilterCombinationMode == KAYB_FILTER_ALL)
   {
      for(int i = 0; i < total; ++i)
      {
         if(enabledFlags[i] && !passedFlags[i])
            return false;
      }
      return true;
   }

   // PRIORITY
   for(int i = 0; i < total; ++i)
   {
      if(enabledFlags[i])
         return passedFlags[i];
   }
   return false;
}

KAYBSetupSignal KAYB_BuildReversalSignal(const KAYBStructureState &st, const KAYBWorkflow &wf)
{
   KAYBSetupSignal sig;
   sig.valid = false;
   sig.isBuy = (st.chochUp || st.bosUp);
   sig.fromReversal = true;
   sig.setupTag = "EngineA-Reversal";
   sig.filterTag = "";
   sig.workflowLabel = wf.label;
   sig.timeframe = wf.confirmTf;
   sig.signalTime = TimeCurrent();

   if(!st.valid)
      return sig;

   bool isBuy = (st.chochUp || st.bosUp);
   bool isSell = (st.chochDown || st.bosDown);
   if(!isBuy && !isSell)
      return sig;

   MqlRates rates[];
   if(!KAYB_LoadRates(wf.confirmTf, MathMax(120, InpSetupExpiryBars * 10), rates))
      return sig;

   double ll2 = st.ll[1];
   double lh2 = st.lh[1];
   double ll1 = st.ll[0];
   if(isSell)
   {
      ll2 = st.hh[1];
      lh2 = st.hl[1];
      ll1 = st.hh[0];
   }

   double targets[4];
   bool enabled[4] = { InpFilterA_VolumeNode, InpFilterB_EngulfedBullBear, InpFilterC_LastCandleBeforeBreak, InpFilterD_FibRetracement };
   bool passed[4] = { false, false, false, false };
   ArrayInitialize(targets, 0.0);

   passed[0] = enabled[0] ? KAYB_FilterA_VolumeNode(rates, isBuy, ll1, lh2, targets[0]) : false;
   passed[1] = enabled[1] ? KAYB_FilterB_EngulfZone(rates, isBuy, targets[1]) : false;
   passed[2] = enabled[2] ? KAYB_FilterC_LastCandleBeforeBreak(rates, isBuy, ll2, targets[2]) : false;
   passed[3] = enabled[3] ? KAYB_FilterD_Fib(isBuy, ll1, st.lastBreakLevel > 0.0 ? st.lastBreakLevel : lh2, InpFilterD_UseFib618, targets[3]) : false;

   if(!KAYB_EvaluateFilterSelection(enabled, passed, 4))
      return sig;

   double selectedEntry = 0.0;
   if(InpFilterCombinationMode == KAYB_FILTER_PRIORITY)
   {
      for(int i = 0; i < 4; ++i)
      {
         if(enabled[i] && passed[i])
         {
            selectedEntry = targets[i];
            break;
         }
      }
   }
   else
   {
      double sum = 0.0;
      int cnt = 0;
      for(int i = 0; i < 4; ++i)
      {
         if(enabled[i] && passed[i])
         {
            sum += targets[i];
            cnt++;
         }
      }
      selectedEntry = (cnt > 0) ? (sum / cnt) : 0.0;
   }

   if(selectedEntry <= 0.0)
      selectedEntry = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double buffer = KAYB_UnitsToPrice(_Symbol, InpStopBufferUnits, InpDistanceMode);
   double stop = isBuy ? MathMin(ll1, ll2) - buffer : MathMax(ll1, ll2) + buffer;
   if(InpManualSLUnits > 0.0)
      stop = isBuy ? selectedEntry - KAYB_UnitsToPrice(_Symbol, InpManualSLUnits, InpDistanceMode)
                   : selectedEntry + KAYB_UnitsToPrice(_Symbol, InpManualSLUnits, InpDistanceMode);

   double risk = MathAbs(selectedEntry - stop);
   if(risk <= SymbolInfoDouble(_Symbol, SYMBOL_POINT))
      return sig;

   double target = isBuy ? selectedEntry + risk * InpRR : selectedEntry - risk * InpRR;
   if(InpManualTPUnits > 0.0)
      target = isBuy ? selectedEntry + KAYB_UnitsToPrice(_Symbol, InpManualTPUnits, InpDistanceMode)
                     : selectedEntry - KAYB_UnitsToPrice(_Symbol, InpManualTPUnits, InpDistanceMode);

   sig.valid = true;
   sig.isBuy = isBuy;
   sig.entry = selectedEntry;
   sig.stop = stop;
   sig.tp = target;
   sig.zoneLow = MathMin(ll1, ll2);
   sig.zoneHigh = MathMax(lh2, st.lastBreakLevel);
   sig.filterTag = (InpFilterCombinationMode == KAYB_FILTER_ANY ? "any" : (InpFilterCombinationMode == KAYB_FILTER_ALL ? "all" : "priority"));
   sig.reason = (isBuy ? "LL2-LH2-LL1 + break" : "HH2-HL2-HH1 + break");
   return sig;
}

KAYBSetupSignal KAYB_BuildContinuationSignal(const KAYBStructureState &st, const KAYBWorkflow &wf, datetime lastEventTime)
{
   KAYBSetupSignal sig;
   sig.valid = false;
   sig.fromReversal = false;
   sig.setupTag = "EngineB-Continuation";
   sig.filterTag = "continuation";
   sig.workflowLabel = wf.label;
   sig.timeframe = wf.confirmTf;
   sig.signalTime = TimeCurrent();

   if(!st.valid)
      return sig;

   bool buyContinuation = (st.bosUp && st.lastBreakTime > lastEventTime);
   bool sellContinuation = (st.bosDown && st.lastBreakTime > lastEventTime);
   if(!buyContinuation && !sellContinuation)
      return sig;

   MqlRates rates[];
   if(!KAYB_LoadRates(wf.confirmTf, 160, rates))
      return sig;

   double retraceCandleOpen = 0.0;
   int maxBars = MathMin(ArraySize(rates) - 1, InpSetupExpiryBars * 4);
   for(int i = 1; i < maxBars; ++i)
   {
      bool bearish = rates[i].close < rates[i].open;
      bool bullish = rates[i].close > rates[i].open;
      if(buyContinuation && bearish)
      {
         retraceCandleOpen = rates[i].open;
         break;
      }
      if(sellContinuation && bullish)
      {
         retraceCandleOpen = rates[i].open;
         break;
      }
   }
   if(retraceCandleOpen <= 0.0)
      return sig;

   bool isBuy = buyContinuation;
   double entry = retraceCandleOpen;
   double buffer = KAYB_UnitsToPrice(_Symbol, InpStopBufferUnits, InpDistanceMode);
   double stop = isBuy ? st.hl[0] - buffer : st.lh[0] + buffer;
   if(InpManualSLUnits > 0.0)
      stop = isBuy ? entry - KAYB_UnitsToPrice(_Symbol, InpManualSLUnits, InpDistanceMode)
                   : entry + KAYB_UnitsToPrice(_Symbol, InpManualSLUnits, InpDistanceMode);
   double risk = MathAbs(entry - stop);
   if(risk <= SymbolInfoDouble(_Symbol, SYMBOL_POINT))
      return sig;

   double tp = isBuy ? entry + risk * InpRR : entry - risk * InpRR;
   if(InpManualTPUnits > 0.0)
      tp = isBuy ? entry + KAYB_UnitsToPrice(_Symbol, InpManualTPUnits, InpDistanceMode)
                 : entry - KAYB_UnitsToPrice(_Symbol, InpManualTPUnits, InpDistanceMode);

   sig.valid = true;
   sig.isBuy = isBuy;
   sig.entry = entry;
   sig.stop = stop;
   sig.tp = tp;
   sig.zoneLow = MathMin(st.hl[0], st.ll[0]);
   sig.zoneHigh = MathMax(st.hh[0], st.lh[0]);
   sig.reason = isBuy ? "BOS up retrace to last bearish candle" : "BOS down retrace to last bullish candle";
   return sig;
}
