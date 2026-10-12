#ifndef KBLX_DASHBOARD_MQH
#define KBLX_DASHBOARD_MQH

#include "..\Core\Types.mqh"

class CKBLXDashboard
{
private:
   string m_prefix;
   string m_last_text;

   void DrawText(const string name, const datetime time, const double price,
                 const string text, const color foreground)
   {
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
      ObjectMove(0, name, 0, time, price);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }

   void DrawSegment(const string name, const datetime first_time,
                    const double first_price, const datetime last_time,
                    const double last_price, const color foreground)
   {
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_TREND, 0, first_time, first_price,
                      last_time, last_price);
      else
      {
         ObjectMove(0, name, 0, first_time, first_price);
         ObjectMove(0, name, 1, last_time, last_price);
      }
      ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }

   void DrawZone(const string name, const KBLXZone &zone, const color foreground)
   {
      if(!zone.valid)
      {
         ObjectDelete(0, name);
         return;
      }
      datetime end_time = (zone.expires > zone.created
                           ? zone.expires : TimeCurrent() + PeriodSeconds(_Period) * 20);
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, zone.created, zone.high,
                      end_time, zone.low);
      else
      {
         ObjectMove(0, name, 0, zone.created, zone.high);
         ObjectMove(0, name, 1, end_time, zone.low);
      }
      ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }

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

         void DrawSignal(const KBLXSignal &signal, const KBLXMarketContext &context,
                         const double stop, const double target)
         {
            for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
            {
               string name = ObjectName(0, i);
               if(StringFind(name, m_prefix + "SETUP_") == 0)
                  ObjectDelete(0, name);
            }
            string key = StringFormat("%I64d_%I64d_%c",
               (long)signal.first_pivot_time, (long)signal.last_pivot_time,
               signal.direction == KBLX_DIRECTION_BUY ? 'B' : 'S');
            color setup_color = (signal.direction == KBLX_DIRECTION_BUY
                                 ? clrDodgerBlue : clrTomato);
            string base = m_prefix + "SETUP_" + key + "_";
            DrawText(base + "1", signal.first_pivot_time, signal.first_pivot_price,
                     "1", setup_color);
            DrawText(base + "2", signal.middle_pivot_time, signal.middle_pivot_price,
                     "2", setup_color);
            DrawText(base + "3", signal.last_pivot_time, signal.last_pivot_price,
                     "3", setup_color);
            DrawText(base + "BREAK", signal.break_time, signal.middle_pivot_price,
                     signal.break_type == KBLX_BREAK_BOS ? "BOS" : "CHOCH", clrGold);
            DrawText(base + "RETRACE", signal.retracement_time, signal.entry,
                     "Retrace", clrAqua);
            DrawSegment(base + "LINE1", signal.first_pivot_time, signal.first_pivot_price,
                        signal.middle_pivot_time, signal.middle_pivot_price, setup_color);
            DrawSegment(base + "LINE2", signal.middle_pivot_time, signal.middle_pivot_price,
                        signal.last_pivot_time, signal.last_pivot_price, setup_color);
            DrawSegment(base + "LINE3", signal.last_pivot_time, signal.last_pivot_price,
                        signal.break_time, signal.middle_pivot_price, clrGold);
            DrawSegment(base + "LINE4", signal.break_time, signal.middle_pivot_price,
                        signal.retracement_time, signal.entry, clrAqua);
            DrawZone(base + "TRADE_ZONE", signal.zone, setup_color);
            DrawZone(base + "DEMAND", context.demand, clrSeaGreen);
            DrawZone(base + "SUPPLY", context.supply, clrIndianRed);
            DrawZone(base + "VOLUME", context.volume_zone, clrDarkGoldenrod);

            string sl_name = base + "SL";
            string tp_name = base + "TP";
            if(ObjectFind(0, sl_name) < 0) ObjectCreate(0, sl_name, OBJ_HLINE, 0, 0, stop);
            if(ObjectFind(0, tp_name) < 0) ObjectCreate(0, tp_name, OBJ_HLINE, 0, 0, target);
            ObjectSetDouble(0, sl_name, OBJPROP_PRICE, stop);
            ObjectSetDouble(0, tp_name, OBJPROP_PRICE, target);
            ObjectSetInteger(0, sl_name, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, tp_name, OBJPROP_COLOR, clrLimeGreen);
            ObjectSetInteger(0, sl_name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, tp_name, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, sl_name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, tp_name, OBJPROP_SELECTABLE, false);
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
