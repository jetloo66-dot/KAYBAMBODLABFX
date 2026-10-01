#ifndef KBLX_MARKET_DATA_MQH
#define KBLX_MARKET_DATA_MQH

#include "Types.mqh"

#define KBLX_RATE_CACHE_SLOTS 128

struct KBLXRateCache
{
   string symbol;
   ENUM_TIMEFRAMES timeframe;
   MqlRates rates[];
   int count;
   datetime bar_time;
   datetime last_seen_bar;
   datetime refreshed;
};

class CKBLXMarketData
{
private:
   KBLXRateCache m_cache[KBLX_RATE_CACHE_SLOTS];
   int m_cache_count;
   int m_max_cache_age_seconds;

   int FindSlot(const string symbol, const ENUM_TIMEFRAMES timeframe)
   {
      for(int i = 0; i < m_cache_count; i++)
         if(m_cache[i].symbol == symbol && m_cache[i].timeframe == timeframe)
            return i;

      if(m_cache_count >= KBLX_RATE_CACHE_SLOTS)
         return -1;

      int slot = m_cache_count++;
      m_cache[slot].symbol = symbol;
      m_cache[slot].timeframe = timeframe;
      m_cache[slot].count = 0;
      m_cache[slot].bar_time = 0;
      m_cache[slot].last_seen_bar = 0;
      m_cache[slot].refreshed = 0;
      return slot;
   }

public:
   CKBLXMarketData()
   {
      m_cache_count = 0;
      m_max_cache_age_seconds = 5;
   }

   void SetMaximumCacheAge(const int seconds)
   {
      m_max_cache_age_seconds = MathMax(0, seconds);
   }

   bool GetRates(const string symbol, const ENUM_TIMEFRAMES timeframe,
                 const int requested, MqlRates &out[])
   {
      if(requested < 1 || !SymbolSelect(symbol, true))
         return false;

      int slot = FindSlot(symbol, timeframe);
      if(slot < 0)
         return false;

      datetime current_bar = iTime(symbol, timeframe, 0);
      bool stale = (m_cache[slot].count < requested ||
                    m_cache[slot].bar_time != current_bar ||
                    TimeCurrent() - m_cache[slot].refreshed > m_max_cache_age_seconds);
      if(stale)
      {
         ArrayResize(m_cache[slot].rates, requested);
         ArraySetAsSeries(m_cache[slot].rates, true);
         int copied = CopyRates(symbol, timeframe, 0, requested, m_cache[slot].rates);
         if(copied < requested)
            return false;

         m_cache[slot].count = copied;
         m_cache[slot].bar_time = current_bar;
         m_cache[slot].refreshed = TimeCurrent();
      }

      ArrayResize(out, m_cache[slot].count);
      ArraySetAsSeries(out, true);
      if(ArrayCopy(out, m_cache[slot].rates, 0, 0, m_cache[slot].count) != m_cache[slot].count)
         return false;
      return true;
   }

   bool IsNewBar(const string symbol, const ENUM_TIMEFRAMES timeframe)
   {
      int slot = FindSlot(symbol, timeframe);
      if(slot < 0)
         return false;
      datetime current_bar = iTime(symbol, timeframe, 0);
      if(current_bar <= 0)
         return false;
      if(m_cache[slot].last_seen_bar == 0)
      {
         m_cache[slot].last_seen_bar = current_bar;
         return true;
      }
      if(m_cache[slot].last_seen_bar == current_bar)
         return false;
      m_cache[slot].last_seen_bar = current_bar;
      return true;
   }

   double PointSize(const string symbol)
   {
      double point = 0.0;
      if(!SymbolInfoDouble(symbol, SYMBOL_POINT, point))
         return 0.0;
      return point;
   }

   double TickSize(const string symbol)
   {
      double size = 0.0;
      if(!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE, size))
         return 0.0;
      if(size <= 0.0)
         size = PointSize(symbol);
      return size;
   }

   double NormalizePrice(const string symbol, const double price)
   {
      double tick = TickSize(symbol);
      long digits = 0;
      if(tick <= 0.0 || !SymbolInfoInteger(symbol, SYMBOL_DIGITS, digits))
         return 0.0;
      return NormalizeDouble(MathRound(price / tick) * tick, (int)digits);
   }

   double PointsToPrice(const string symbol, const double points)
   {
      return points * PointSize(symbol);
   }

   double PriceToPoints(const string symbol, const double distance)
   {
      double point = PointSize(symbol);
      if(point <= 0.0)
         return 0.0;
      return distance / point;
   }

   void Invalidate(const string symbol, const ENUM_TIMEFRAMES timeframe)
   {
      int slot = FindSlot(symbol, timeframe);
      if(slot >= 0)
      {
         m_cache[slot].count = 0;
         m_cache[slot].bar_time = 0;
      }
   }
};

#endif
