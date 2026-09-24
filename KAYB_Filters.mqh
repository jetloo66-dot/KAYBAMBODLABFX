#property strict

bool KAYB_IsInSession()
{
   if(!InpUseSessionFilter)
      return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(InpSessionStartHour <= InpSessionEndHour)
      return (dt.hour >= InpSessionStartHour && dt.hour <= InpSessionEndHour);
   return (dt.hour >= InpSessionStartHour || dt.hour <= InpSessionEndHour);
}

bool KAYB_CurrencyAllowed(const string list, const string curr)
{
   string upList = StringUpper(list);
   string upCurr = StringUpper(curr);
   return StringFind(upList, upCurr) >= 0;
}

bool KAYB_IsNewsBlocked(string &reason)
{
   reason = "";
   if(!InpUseNewsFilter)
      return false;

   datetime nowTime = TimeCurrent();
   datetime from = nowTime - InpNewsPreMinutes * 60;
   datetime to = nowTime + InpNewsPostMinutes * 60;

   MqlCalendarValue values[];
   int count = CalendarValueHistory(values, from, to, "", "");
   if(count <= 0)
      return false; // graceful fallback

   for(int i = 0; i < count; ++i)
   {
      MqlCalendarEvent evt;
      if(!CalendarEventById(values[i].event_id, evt))
         continue;

      MqlCalendarCountry c;
      if(!CalendarCountryById(evt.country_id, c))
         continue;

      if(!KAYB_CurrencyAllowed(InpNewsCurrencies, c.currency))
         continue;

      bool impactBlocked = false;
      long imp = (long)evt.importance;
      if(imp >= 3 && InpNewsBlockHigh)
         impactBlocked = true;
      else if(imp >= 2 && InpNewsBlockMedium)
         impactBlocked = true;
      if(!impactBlocked)
         continue;

      reason = "News block " + c.currency + " " + evt.name;
      return true;
   }
   return false;
}

datetime KAYB_LimitAnchor(ENUM_KAYBLimitMode mode)
{
   datetime t = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(t, dt);

   if(mode == KAYB_LIMIT_MINUTE)
      dt.sec = 0;
   else if(mode == KAYB_LIMIT_HOUR)
   {
      dt.min = 0;
      dt.sec = 0;
   }
   else if(mode == KAYB_LIMIT_DAY)
   {
      dt.hour = 0;
      dt.min = 0;
      dt.sec = 0;
   }
   else if(mode == KAYB_LIMIT_SESSION)
   {
      bool wraps = InpSessionStartHour > InpSessionEndHour;
      if(wraps && dt.hour < InpSessionEndHour)
      {
         datetime now = StructToTime(dt) - 86400;
         TimeToStruct(now, dt);
      }
      dt.hour = InpSessionStartHour;
      dt.min = 0;
      dt.sec = 0;
   }
   return StructToTime(dt);
}

void KAYB_InitLimitSnapshot(KAYBLimitSnapshot &snap)
{
   snap.anchor = 0;
   snap.startEquity = 0.0;
   snap.blocked = false;
   snap.reason = "";
}

bool KAYB_UpdateLimitState(KAYBLimitSnapshot &profitSnap, KAYBLimitSnapshot &lossSnap, string &reason)
{
   reason = "";
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);

   if(InpProfitTargetMode != KAYB_LIMIT_NONE)
   {
      datetime anchor = KAYB_LimitAnchor(InpProfitTargetMode);
      if(profitSnap.anchor != anchor)
      {
         profitSnap.anchor = anchor;
         profitSnap.startEquity = eq;
         profitSnap.blocked = false;
      }
      if(profitSnap.startEquity <= 0.0)
         profitSnap.startEquity = eq;
      double delta = eq - profitSnap.startEquity;
      if(InpLimitValueMode == KAYB_VALUE_PERCENT && profitSnap.startEquity <= 0.0)
         return false;
      double metric = (InpLimitValueMode == KAYB_VALUE_PERCENT) ? (delta / profitSnap.startEquity) * 100.0 : delta;
      if(metric >= InpProfitTargetValue)
      {
         profitSnap.blocked = true;
         profitSnap.reason = "profit target reached";
      }
   }

   if(InpLossLimitMode != KAYB_LIMIT_NONE)
   {
      datetime anchor = KAYB_LimitAnchor(InpLossLimitMode);
      if(lossSnap.anchor != anchor)
      {
         lossSnap.anchor = anchor;
         lossSnap.startEquity = eq;
         lossSnap.blocked = false;
      }
      if(lossSnap.startEquity <= 0.0)
         lossSnap.startEquity = eq;
      double delta = eq - lossSnap.startEquity;
      if(InpLimitValueMode == KAYB_VALUE_PERCENT && lossSnap.startEquity <= 0.0)
         return false;
      double metric = (InpLimitValueMode == KAYB_VALUE_PERCENT) ? (-delta / lossSnap.startEquity) * 100.0 : (-delta);
      if(metric >= InpLossLimitValue)
      {
         lossSnap.blocked = true;
         lossSnap.reason = "loss limit reached";
      }
   }

   if(profitSnap.blocked)
   {
      reason = profitSnap.reason;
      return true;
   }
   if(lossSnap.blocked)
   {
      reason = lossSnap.reason;
      return true;
   }
   return false;
}
