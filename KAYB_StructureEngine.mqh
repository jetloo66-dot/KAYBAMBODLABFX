#property strict

bool KAYB_IsSwingHighRate(const MqlRates &rates[], int idx, int lookback)
{
   for(int j = idx - lookback; j <= idx + lookback; ++j)
   {
      if(j == idx)
         continue;
      if(rates[j].high >= rates[idx].high)
         return false;
   }
   return true;
}

bool KAYB_IsSwingLowRate(const MqlRates &rates[], int idx, int lookback)
{
   for(int j = idx - lookback; j <= idx + lookback; ++j)
   {
      if(j == idx)
         continue;
      if(rates[j].low <= rates[idx].low)
         return false;
   }
   return true;
}

bool KAYB_LoadRates(ENUM_TIMEFRAMES tf, int bars, MqlRates &rates[])
{
   int copied = CopyRates(_Symbol, tf, 0, bars, rates);
   if(copied < bars / 2)
      return false;
   ArraySetAsSeries(rates, true);
   return true;
}

void KAYB_CollectSwings(const MqlRates &rates[], int lookback, KAYBSwing &highs[], KAYBSwing &lows[])
{
   ArrayResize(highs, 0);
   ArrayResize(lows, 0);
   int bars = ArraySize(rates);
   for(int i = lookback + 1; i < bars - lookback; ++i)
   {
      if(KAYB_IsSwingHighRate(rates, i, lookback))
      {
         int p = ArraySize(highs);
         ArrayResize(highs, p + 1);
         highs[p].price = rates[i].high;
         highs[p].time = rates[i].time;
         highs[p].index = i;
      }
      if(KAYB_IsSwingLowRate(rates, i, lookback))
      {
         int p2 = ArraySize(lows);
         ArrayResize(lows, p2 + 1);
         lows[p2].price = rates[i].low;
         lows[p2].time = rates[i].time;
         lows[p2].index = i;
      }
   }
}

bool KAYB_Last3(const KAYBSwing &arr[], double &a, double &b, double &c)
{
   int n = ArraySize(arr);
   if(n < 3)
      return false;
   a = arr[n - 1].price;
   b = arr[n - 2].price;
   c = arr[n - 3].price;
   return true;
}

KAYBStructureState KAYB_BuildStructureState(ENUM_TIMEFRAMES tf)
{
   KAYBStructureState st;
   st.valid = false;
   st.trend = KAYB_TREND_NONE;
   st.bosUp = false;
   st.bosDown = false;
   st.chochUp = false;
   st.chochDown = false;
   st.lastBreakLevel = 0.0;
   st.lastBreakTime = 0;
   ArrayInitialize(st.hh, 0.0);
   ArrayInitialize(st.hl, 0.0);
   ArrayInitialize(st.ll, 0.0);
   ArrayInitialize(st.lh, 0.0);

   MqlRates rates[];
   if(!KAYB_LoadRates(tf, InpStructureLookbackBars, rates))
      return st;

   KAYBSwing highs[];
   KAYBSwing lows[];
   KAYB_CollectSwings(rates, MathMax(1, InpSwingLookback), highs, lows);

   double hh1, hh2, hh3, hl1, hl2, hl3;
   bool haveHigh3 = KAYB_Last3(highs, hh1, hh2, hh3);
   bool haveLow3 = KAYB_Last3(lows, hl1, hl2, hl3);

   if(haveHigh3)
   {
      st.hh[0] = hh1; st.hh[1] = hh2; st.hh[2] = hh3;
      st.lh[0] = hh1; st.lh[1] = hh2; st.lh[2] = hh3;
   }
   if(haveLow3)
   {
      st.hl[0] = hl1; st.hl[1] = hl2; st.hl[2] = hl3;
      st.ll[0] = hl1; st.ll[1] = hl2; st.ll[2] = hl3;
   }

   bool upSeq = haveHigh3 && haveLow3 && (hh1 > hh2 && hh2 > hh3) && (hl1 > hl2 && hl2 > hl3);
   bool downSeq = haveHigh3 && haveLow3 && (hl1 < hl2 && hl2 < hl3) && (hh1 < hh2 && hh2 < hh3);

   if(upSeq)
      st.trend = KAYB_TREND_UP;
   else if(downSeq)
      st.trend = KAYB_TREND_DOWN;

   int confirmShift = InpCloseBreakRequired ? 1 : 0;
   double tolerance = KAYB_UnitsToPrice(_Symbol, InpSwingToleranceUnits, InpDistanceMode);
   double closePrice = rates[confirmShift].close;

   double recentHigh = haveHigh3 ? hh1 : 0.0;
   double recentLow = haveLow3 ? hl1 : 0.0;

   if(recentHigh > 0.0 && closePrice > (recentHigh + tolerance))
   {
      st.bosUp = (st.trend == KAYB_TREND_UP);
      st.chochUp = (st.trend == KAYB_TREND_DOWN || st.trend == KAYB_TREND_NONE);
      st.lastBreakLevel = recentHigh;
      st.lastBreakTime = rates[confirmShift].time;
   }
   if(recentLow > 0.0 && closePrice < (recentLow - tolerance))
   {
      st.bosDown = (st.trend == KAYB_TREND_DOWN);
      st.chochDown = (st.trend == KAYB_TREND_UP || st.trend == KAYB_TREND_NONE);
      st.lastBreakLevel = recentLow;
      st.lastBreakTime = rates[confirmShift].time;
   }

   st.valid = haveHigh3 && haveLow3;
   return st;
}
