#ifndef KBLX_TRADING_FILTERS_MQH
#define KBLX_TRADING_FILTERS_MQH

#include "..\Core\Types.mqh"

class CKBLXTradingFilters
{
private:
   datetime m_pnl_checked;
   bool m_pnl_cache_valid;
   bool m_pnl_cached_allowed;

   void CachePnLResult(const datetime checked, const bool allowed)
   {
      m_pnl_checked = checked;
      m_pnl_cached_allowed = allowed;
      m_pnl_cache_valid = true;
   }

   bool IsSupportedCalendarCurrency(const string currency)
   {
      string currencies = " USD EUR GBP JPY CHF CAD AUD NZD SEK NOK DKK PLN CZK HUF TRY ZAR MXN SGD HKD CNY INR BRL KRW ";
      return StringFind(currencies, " " + currency + " ") >= 0;
   }

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

   bool IsNewsWindow(const string symbol, const int minutes_before,
                     const int minutes_after, const int minimum_importance)
   {
      string base_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
      string quote_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
      datetime now = TimeTradeServer();
      datetime from = now - minutes_after * 60;
      datetime to = now + minutes_before * 60;
      MqlCalendarValue values[];
      string currencies[2];
      currencies[0] = base_currency;
      currencies[1] = quote_currency;
      for(int c = 0; c < 2; c++)
      {
         if(!IsSupportedCalendarCurrency(currencies[c]))
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
            if((int)event.importance >= minimum_importance)
               return true;
         }
      }
      return false;
   }

public:
   CKBLXTradingFilters()
   {
      m_pnl_checked = 0;
      m_pnl_cache_valid = false;
      m_pnl_cached_allowed = true;
   }

   void InvalidatePnL()
   {
      m_pnl_cache_valid = false;
   }

   bool IsProfitLossAllowed(const long magic, const bool profit_enabled,
                            const double profit_percent, const bool loss_enabled,
                            const double loss_percent, const KBLXLimitPeriod period,
                            const int minutes, const int hours,
                            const int session_start_hour, const int session_end_hour,
                            const double profit_limit_money,
                            const double loss_limit_money)
   {
      if(!profit_enabled && !loss_enabled &&
         profit_limit_money <= 0.0 && loss_limit_money <= 0.0)
         return true;
      datetime now = TimeTradeServer();
      if(m_pnl_cache_valid && now >= m_pnl_checked &&
         now - m_pnl_checked < 5)
         return m_pnl_cached_allowed;
      MqlDateTime day;
      TimeToStruct(now, day);
      int current_hour = day.hour;
      datetime start = 0;
      if(period == KBLX_LIMIT_MINUTES)
         start = now - MathMax(1, minutes) * 60;
      else if(period == KBLX_LIMIT_HOURS)
         start = now - MathMax(1, hours) * 3600;
      else if(period == KBLX_LIMIT_SESSION)
      {
         day.hour = session_start_hour;
         day.min = 0;
         day.sec = 0;
         start = StructToTime(day);
         if(session_start_hour > session_end_hour && current_hour <= session_end_hour)
            start -= 86400;
      }
      else
      {
         day.hour = 0;
         day.min = 0;
         day.sec = 0;
         start = StructToTime(day);
      }
      if(!HistorySelect(start, now))
      {
         CachePnLResult(now, false);
         return false;
      }
      double realized = 0.0;
      double account_movement = 0.0;
      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket == 0)
            continue;
         double deal_change = HistoryDealGetDouble(ticket, DEAL_PROFIT) +
                              HistoryDealGetDouble(ticket, DEAL_COMMISSION) +
                              HistoryDealGetDouble(ticket, DEAL_SWAP) +
                              HistoryDealGetDouble(ticket, DEAL_FEE);
         account_movement += deal_change;
         ENUM_DEAL_TYPE type =
            (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == magic &&
            (type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL))
            realized += deal_change;
      }
      double period_start_balance = AccountInfoDouble(ACCOUNT_BALANCE) -
                                    account_movement;
      if(period_start_balance <= 0.0)
         period_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(profit_limit_money > 0.0 && realized >= profit_limit_money)
      {
         CachePnLResult(now, false);
         return false;
      }
      if(loss_limit_money > 0.0 && realized <= -loss_limit_money)
      {
         CachePnLResult(now, false);
         return false;
      }
      if(profit_enabled && profit_percent > 0.0 &&
         realized >= period_start_balance * profit_percent / 100.0)
      {
         CachePnLResult(now, false);
         return false;
      }
      if(loss_enabled && loss_percent > 0.0 &&
         realized <= -period_start_balance * loss_percent / 100.0)
      {
         CachePnLResult(now, false);
         return false;
      }
      CachePnLResult(now, true);
      return true;
   }

   bool IsAllowed(const string symbol, const bool session_enabled,
                  const int session_start_hour, const int session_end_hour,
                  const bool monday, const bool tuesday, const bool wednesday,
                  const bool thursday, const bool friday, const bool saturday,
                  const bool sunday, const double maximum_spread_points,
                  const bool news_enabled, const int news_before_minutes,
                  const int news_after_minutes, const int news_minimum_importance)
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
      if(news_enabled && IsNewsWindow(symbol, news_before_minutes, news_after_minutes,
                                      news_minimum_importance))
         return false;
      return true;
   }
};

#endif
