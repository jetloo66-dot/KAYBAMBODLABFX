#property strict


string KAYB_ObjectPrefix()
{
   return InpObjectPrefix + "_" + IntegerToString(InpMagicNumber) + "_" + IntegerToString((int)ChartID());
}

datetime g_lastAlertTime = 0;
string g_lastEvent = "";

void KAYB_SendTelegram(const string message)
{
   if(!InpAlertTelegram || InpTelegramBotToken == "" || InpTelegramChatId == "")
      return;
   string url = "https://api.telegram.org/bot" + InpTelegramBotToken + "/sendMessage";
   string payload = "chat_id=" + InpTelegramChatId + "&text=" + message;
   char post[];
   char result[];
   string reqHeaders = "Content-Type: application/x-www-form-urlencoded\r\n";
   string respHeaders = "";
   StringToCharArray(payload, post, 0, StringLen(payload));
   ResetLastError();
   int code = WebRequest("POST", url, reqHeaders, 5000, post, result, respHeaders);
   if(code == -1)
      Print("KAYB telegram error: ", GetLastError());
}

void KAYB_Notify(const string eventText)
{
   if(TimeCurrent() - g_lastAlertTime < InpAlertMinSeconds)
      return;

   g_lastAlertTime = TimeCurrent();
   g_lastEvent = eventText;

   if(InpAlertTerminal)
      Alert(eventText);
   if(InpAlertPush)
      SendNotification(eventText);
   if(InpAlertEmail)
      SendMail("KAYBAMBODLABFX EA", eventText);
   KAYB_SendTelegram(eventText);
}

void KAYB_DrawDashboard(const KAYBWorkflow workflows[], const KAYBStructureState states[], bool entriesBlocked, const string blockReason)
{
   if(!InpDashboardEnabled)
      return;

   string name = KAYB_ObjectPrefix() + "_Dashboard";
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   string text = "KAYB MT5 EA\n";
   text += "Symbol: " + _Symbol + "\n";
   text += "Blocked: " + (entriesBlocked ? "YES" : "NO") + (entriesBlocked ? (" (" + blockReason + ")") : "") + "\n";
   for(int i = 0; i < 6; ++i)
   {
      string st = states[i].trend == KAYB_TREND_UP ? "UP" : (states[i].trend == KAYB_TREND_DOWN ? "DOWN" : "NONE");
      text += workflows[i].label + ": " + st;
      if(states[i].chochUp || states[i].chochDown)
         text += " CHOCH";
      if(states[i].bosUp || states[i].bosDown)
         text += " BOS";
      text += "\n";
   }
   text += "Positions: " + IntegerToString(KAYB_OpenedPositionsByMagic(_Symbol, InpMagicNumber));
   text += "\nPending: " + IntegerToString(KAYB_PendingOrdersByMagic(_Symbol, InpMagicNumber));
   text += "\nLast: " + g_lastEvent;

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void KAYB_ClearVisuals()
{
   string prefix = KAYB_ObjectPrefix();
   for(int i = ObjectsTotal(0) - 1; i >= 0; --i)
   {
      string obj = ObjectName(0, i);
      if(StringFind(obj, prefix) == 0)
         ObjectDelete(0, obj);
   }
}

void KAYB_DrawSignalZone(const KAYBSetupSignal &sig)
{
   string base = KAYB_ObjectPrefix() + "_" + sig.workflowLabel + "_" + IntegerToString((int)sig.signalTime);
   ObjectCreate(0, base + "_zone", OBJ_RECTANGLE, 0, TimeCurrent(), sig.zoneLow, TimeCurrent() + 3600, sig.zoneHigh);
   ObjectSetInteger(0, base + "_zone", OBJPROP_COLOR, sig.isBuy ? clrGreen : clrTomato);
   ObjectSetInteger(0, base + "_zone", OBJPROP_BACK, true);
   ObjectSetInteger(0, base + "_zone", OBJPROP_FILL, true);

   ObjectCreate(0, base + "_entry", OBJ_HLINE, 0, 0, sig.entry);
   ObjectSetInteger(0, base + "_entry", OBJPROP_COLOR, clrAqua);

   ObjectCreate(0, base + "_sl", OBJ_HLINE, 0, 0, sig.stop);
   ObjectSetInteger(0, base + "_sl", OBJPROP_COLOR, clrRed);

   ObjectCreate(0, base + "_tp", OBJ_HLINE, 0, 0, sig.tp);
   ObjectSetInteger(0, base + "_tp", OBJPROP_COLOR, clrLime);
}
