#ifndef KBLX_STRUCTURE_ENGINE_MQH
#define KBLX_STRUCTURE_ENGINE_MQH

#include "..\Core\MarketData.mqh"

#define KBLX_MAX_SWINGS 128

class CKBLXStructureEngine
{
private:
   KBLXSwingPoint m_swings[KBLX_MAX_SWINGS];
   int m_swing_count;

   bool IsPivot(const MqlRates &rates[], const int shift, const int strength,
                const KBLXSwingType type, const double tolerance)
   {
      double price = (type == KBLX_SWING_HIGH ? rates[shift].high : rates[shift].low);
      for(int offset = 1; offset <= strength; offset++)
      {
         int newer = shift - offset;
         int older = shift + offset;
         if(newer < 1 || older >= ArraySize(rates))
            return false;
         double newer_price = (type == KBLX_SWING_HIGH ? rates[newer].high : rates[newer].low);
         double older_price = (type == KBLX_SWING_HIGH ? rates[older].high : rates[older].low);
         if(type == KBLX_SWING_HIGH)
         {
            if(newer_price > price + tolerance ||
               older_price > price + tolerance ||
               MathAbs(older_price - price) <= tolerance)
               return false;
         }
         else if(newer_price < price - tolerance ||
                 older_price < price - tolerance ||
                 MathAbs(older_price - price) <= tolerance)
            return false;
      }
      return true;
   }

   void AddSwing(const KBLXSwingPoint &point, const double min_distance)
   {
      if(m_swing_count > 0 && m_swings[m_swing_count - 1].type == point.type)
      {
         int last = m_swing_count - 1;
         if(MathAbs(m_swings[last].price - point.price) < min_distance)
         {
            bool more_extreme = (point.type == KBLX_SWING_HIGH
                                 ? point.price > m_swings[last].price
                                 : point.price < m_swings[last].price);
            if(more_extreme)
               m_swings[last] = point;
            return;
         }
      }
      if(m_swing_count == KBLX_MAX_SWINGS)
      {
         for(int i = 1; i < KBLX_MAX_SWINGS; i++)
            m_swings[i - 1] = m_swings[i];
         m_swing_count--;
      }
      m_swings[m_swing_count++] = point;
   }

   void PushLevel(double &values[], datetime &times[], int &count,
                  const double value, const datetime time)
   {
      if(count == 5)
      {
         for(int i = 1; i < 5; i++)
         {
            values[i - 1] = values[i];
            times[i - 1] = times[i];
         }
         count--;
      }
      values[count] = value;
      times[count] = time;
      count++;
   }

public:
   CKBLXStructureEngine()
   {
      m_swing_count = 0;
   }

   bool Update(CKBLXMarketData &data, const string symbol, const ENUM_TIMEFRAMES timeframe,
               const int history_bars, const int strength, const int maximum_age,
               const double minimum_distance_points, const double equal_tolerance_points,
               const int required_structure_swings, KBLXStructure &structure)
   {
      structure.valid = false;
      structure.trend = KBLX_TREND_NEUTRAL;
      int required = MathMax(history_bars, strength * 2 + 10);
      MqlRates rates[];
      if(!data.GetRates(symbol, timeframe, required, rates))
         return false;

      m_swing_count = 0;
      double point = data.PointSize(symbol);
      double min_distance = MathMax(0.0, minimum_distance_points) * point;
      double tolerance = MathMax(0.0, equal_tolerance_points) * point;
      int oldest_shift = MathMin(ArraySize(rates) - strength - 1, history_bars);
      for(int shift = oldest_shift; shift >= strength + 1; shift--)
      {
         if(maximum_age > 0 && shift > maximum_age)
            continue;
         bool is_high = IsPivot(rates, shift, strength, KBLX_SWING_HIGH, tolerance);
         bool is_low = IsPivot(rates, shift, strength, KBLX_SWING_LOW, tolerance);
         if(is_high && is_low)
            continue;
         KBLXSwingPoint pivot;
         pivot.shift = shift;
         pivot.pivot_time = rates[shift].time;
         pivot.confirmed_time = rates[1].time;

         if(is_high)
         {
            pivot.type = KBLX_SWING_HIGH;
            pivot.price = rates[shift].high;
            AddSwing(pivot, min_distance);
         }
         if(is_low)
         {
            pivot.type = KBLX_SWING_LOW;
            pivot.price = rates[shift].low;
            AddSwing(pivot, min_distance);
         }
      }

      ArrayInitialize(structure.hh, 0.0);
      ArrayInitialize(structure.hl, 0.0);
      ArrayInitialize(structure.lh, 0.0);
      ArrayInitialize(structure.ll, 0.0);
      ArrayInitialize(structure.hh_time, 0);
      ArrayInitialize(structure.hl_time, 0);
      ArrayInitialize(structure.lh_time, 0);
      ArrayInitialize(structure.ll_time, 0);
      structure.hh_count = 0;
      structure.hl_count = 0;
      structure.lh_count = 0;
      structure.ll_count = 0;
      structure.latest_high = 0.0;
      structure.latest_low = 0.0;
      structure.latest_high_time = 0;
      structure.latest_low_time = 0;

      KBLXSwingPoint prior_high;
      KBLXSwingPoint prior_low;
      bool has_prior_high = false;
      bool has_prior_low = false;
      for(int i = 0; i < m_swing_count; i++)
      {
         KBLXSwingPoint current = m_swings[i];
         if(current.type == KBLX_SWING_HIGH)
         {
            if(has_prior_high)
            {
               if(current.price > prior_high.price)
                  PushLevel(structure.hh, structure.hh_time, structure.hh_count, current.price, current.pivot_time);
               else if(current.price < prior_high.price)
                  PushLevel(structure.lh, structure.lh_time, structure.lh_count, current.price, current.pivot_time);
            }
            prior_high = current;
            has_prior_high = true;
            structure.latest_high = current.price;
            structure.latest_high_time = current.pivot_time;
         }
         else
         {
            if(has_prior_low)
            {
               if(current.price > prior_low.price)
                  PushLevel(structure.hl, structure.hl_time, structure.hl_count, current.price, current.pivot_time);
               else if(current.price < prior_low.price)
                  PushLevel(structure.ll, structure.ll_time, structure.ll_count, current.price, current.pivot_time);
            }
            prior_low = current;
            has_prior_low = true;
            structure.latest_low = current.price;
            structure.latest_low_time = current.pivot_time;
         }
      }

      int required = MathMax(3, required_structure_swings);
      bool rising_highs = (structure.hh_count >= required);
      bool rising_lows = (structure.hl_count >= required);
      bool falling_highs = (structure.lh_count >= required);
      bool falling_lows = (structure.ll_count >= required);
      if(rising_highs)
         for(int i = structure.hh_count - required + 1; i < structure.hh_count; i++)
            if(structure.hh[i] <= structure.hh[i - 1]) rising_highs = false;
      if(rising_lows)
         for(int i = structure.hl_count - required + 1; i < structure.hl_count; i++)
            if(structure.hl[i] <= structure.hl[i - 1]) rising_lows = false;
      if(falling_highs)
         for(int i = structure.lh_count - required + 1; i < structure.lh_count; i++)
            if(structure.lh[i] >= structure.lh[i - 1]) falling_highs = false;
      if(falling_lows)
         for(int i = structure.ll_count - required + 1; i < structure.ll_count; i++)
            if(structure.ll[i] >= structure.ll[i - 1]) falling_lows = false;

      if(rising_highs && rising_lows)
         structure.trend = KBLX_TREND_UP;
      else if(falling_highs && falling_lows)
         structure.trend = KBLX_TREND_DOWN;
      else if((rising_highs || rising_lows || falling_highs || falling_lows) && m_swing_count >= 4)
         structure.trend = KBLX_TREND_TRANSITION;
      structure.valid = (m_swing_count >= 4);
      return structure.valid;
   }

   int GetSwings(KBLXSwingPoint &out[], const int maximum = 32)
   {
      int count = MathMin(MathMin(maximum, m_swing_count), ArraySize(out));
      for(int i = 0; i < count; i++)
         out[i] = m_swings[m_swing_count - count + i];
      return count;
   }

   int SwingCount()
   {
      return m_swing_count;
   }
};

#endif
