#ifndef KBLX_TRADING_FILTERS_MQH
#define KBLX_TRADING_FILTERS_MQH

#include "..\Core\Types.mqh"

class CKBLXTradingFilters
{
private:
   bool IsTradingDay(const int day, const bool monday, const bool tuesday,
                     const bool wednesday, const bool thursday, const bool friday,
                     const bool saturday, const bool sunday)
   {
      if(day == 0) return sunday;
      if(day == 1) return monday;
      if(day == 2) return tuesday;
      if(day == 3) return wednesday;
      if(day == 4) return thursday;
      if(day == 5) return friday;
      return saturday;
   }

   bool IsNewsWindow(const string symbol, const int minutes_before, const int minutes_after)
   {
      string base_currency = "";
      string quote_currency = "";
      if(StringLen(symbol) >= 6)
      {
         base_currency = StringSubstr(symbol, 0, 3);
         quote_currency = StringSubstr(symbol, 3, 3);
      }
      datetime now = TimeTradeServer();
      datetime from = now - minutes_after * 60;
      datetime to = now + minutes_before * 60;
      MqlCalendarValue values[];
      string currencies[2];
      currencies[0] = base_currency;
      currencies[1] = quote_currency;
      for(int c = 0; c < 2; c++)
      {
         if(currencies[c] == "")
            continue;
         ArrayResize(values, 0);
         int count = CalendarValueHistory(values, from, to, "", currencies[c]);
         if(count < 0)
            return true;
         for(int i = 0; i < count; i++)
         {
            MqlCalendarEvent event;
            if(!CalendarEventById(values[i].event_id, event))
               return true;
            if(event.importance == CALENDAR_IMPORTANCE_HIGH)
               return true;
         }
      }
      return false;
   }

public:
   bool IsDailyPnLAllowed(const long magic, const double profit_limit,
                          const double loss_limit)
   {
      if(profit_limit <= 0.0 && loss_limit <= 0.0)
         return true;
      datetime now = TimeTradeServer();
      MqlDateTime day;
      TimeToStruct(now, day);
      day.hour = 0;
      day.min = 0;
      day.sec = 0;
      datetime start = StructToTime(day);
      if(!HistorySelect(start, now))
         return false;
      double realized = 0.0;
      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0 || HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic)
            continue;
         realized += HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                     HistoryDealGetDouble(ticket, DEAL_COMMISSION) +
                     HistoryDealGetDouble(ticket, DEAL_SWAP);
      }
      if(profit_limit > 0.0 && realized >= profit_limit)
         return false;
      if(loss_limit > 0.0 && realized <= -loss_limit)
         return false;
      return true;
   }

   bool IsAllowed(const string symbol, const bool session_enabled,
                  const int session_start_hour, const int session_end_hour,
                  const bool monday, const bool tuesday, const bool wednesday,
                  const bool thursday, const bool friday, const bool saturday,
                  const bool sunday, const double maximum_spread_points,
                  const bool news_enabled, const int news_before_minutes,
                  const int news_after_minutes)
   {
      MqlDateTime now;
      TimeToStruct(TimeTradeServer(), now);
      if(!IsTradingDay(now.day_of_week, monday, tuesday, wednesday, thursday,
                       friday, saturday, sunday))
         return false;

      if(session_enabled)
      {
         if(session_start_hour < 0 || session_start_hour > 23 ||
            session_end_hour < 0 || session_end_hour > 23)
            return false;
         bool in_session = (session_start_hour <= session_end_hour
                            ? now.hour >= session_start_hour && now.hour <= session_end_hour
                            : now.hour >= session_start_hour || now.hour <= session_end_hour);
         if(!in_session)
            return false;
      }

      if(maximum_spread_points > 0.0)
      {
         MqlTick tick;
         double point = 0.0;
         if(!SymbolInfoTick(symbol, tick) ||
            !SymbolInfoDouble(symbol, SYMBOL_POINT, point) || point <= 0.0 ||
            (tick.ask - tick.bid) / point > maximum_spread_points)
            return false;
      }
      if(news_enabled && IsNewsWindow(symbol, news_before_minutes, news_after_minutes))
         return false;
      return true;
   }
};

#endif
