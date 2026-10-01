#ifndef KBLX_DASHBOARD_MQH
#define KBLX_DASHBOARD_MQH

#include "..\Core\Types.mqh"

class CKBLXDashboard
{
private:
   string m_prefix;
   string m_last_text;

public:
   CKBLXDashboard()
   {
      m_prefix = "KBLX_";
      m_last_text = "";
   }

   void Draw(const bool enabled, const string symbol, const ENUM_TIMEFRAMES timeframe,
             const KBLXStructure &structure, const string status)
   {
      string name = m_prefix + "DASHBOARD";
      if(!enabled)
      {
         ObjectDelete(0, name);
         m_last_text = "";
         return;
      }
      string trend = "NEUTRAL";
      if(structure.trend == KBLX_TREND_UP) trend = "UPTREND";
      if(structure.trend == KBLX_TREND_DOWN) trend = "DOWNTREND";
      if(structure.trend == KBLX_TREND_TRANSITION) trend = "TRANSITION";
      string text = StringFormat("KAYBAMBODLABFX | %s %s\nTrend: %s | HH:%d HL:%d LH:%d LL:%d\n%s",
                                 symbol, EnumToString(timeframe), trend,
                                 structure.hh_count, structure.hl_count,
                                 structure.lh_count, structure.ll_count, status);
      if(text == m_last_text && ObjectFind(0, name) >= 0)
         return;
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      m_last_text = text;
   }

   void DrawSwings(const bool enabled, const KBLXSwingPoint &swings[], const int count)
   {
      int shown = (enabled ? MathMin(count, 20) : 0);
      for(int i = 0; i < shown; i++)
      {
         string name = m_prefix + "SWING_" + IntegerToString((int)swings[i].pivot_time);
         if(ObjectFind(0, name) < 0)
            ObjectCreate(0, name, OBJ_ARROW, 0, swings[i].pivot_time, swings[i].price);
         ObjectSetInteger(0, name, OBJPROP_ARROWCODE,
                          swings[i].type == KBLX_SWING_HIGH ? 234 : 233);
         ObjectSetInteger(0, name, OBJPROP_COLOR,
                          swings[i].type == KBLX_SWING_HIGH ? clrTomato : clrDodgerBlue);
      }
      for(int object_index = ObjectsTotal(0) - 1; object_index >= 0; object_index--)
      {
         string name = ObjectName(0, object_index);
         if(StringFind(name, m_prefix + "SWING_") != 0)
            continue;
         bool retained = false;
         for(int i = 0; i < shown; i++)
         {
            string expected = m_prefix + "SWING_" +
                              IntegerToString((int)swings[i].pivot_time);
            if(name == expected)
            {
               retained = true;
               break;
            }
         }
         if(!retained)
            ObjectDelete(0, name);
      }
   }

   void Cleanup()
   {
      for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
      {
         string name = ObjectName(0, i);
         if(StringFind(name, m_prefix) == 0)
            ObjectDelete(0, name);
      }
   }
};

#endif
