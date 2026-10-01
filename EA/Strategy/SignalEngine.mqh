#ifndef KBLX_SIGNAL_ENGINE_MQH
#define KBLX_SIGNAL_ENGINE_MQH

#include "..\Market\StructureEngine.mqh"

class CKBLXSignalEngine
{
private:
   bool m_buy_choch_seen;
   bool m_buy_bos_seen;
   bool m_sell_choch_seen;
   bool m_sell_bos_seen;
   datetime m_buy_setup_time;
   datetime m_sell_setup_time;
   string m_buy_setup_key;
   string m_sell_setup_key;

   bool Touches(const MqlRates &bar, const double level, const double tolerance)
   {
      return (bar.low <= level + tolerance && bar.high >= level - tolerance);
   }

   bool Intersects(const MqlRates &bar, const double low, const double high,
                   const double tolerance)
   {
      return (bar.low <= high + tolerance && bar.high >= low - tolerance);
   }

   bool BreakAllowed(const KBLXBreakType type, const KBLXBreakSelection selection)
   {
      if(selection == KBLX_CHOCH_AND_BOS)
         return false;
      if(selection == KBLX_CHOCH_ONLY)
         return type == KBLX_BREAK_CHOCH;
      if(selection == KBLX_BOS_ONLY)
         return type == KBLX_BREAK_BOS;
      return type != KBLX_BREAK_NONE;
   }

   bool EligibleTimeframe(const ENUM_TIMEFRAMES primary, const ENUM_TIMEFRAMES confirm)
   {
      return (primary != PERIOD_CURRENT && confirm != PERIOD_CURRENT &&
              primary != confirm && PeriodSeconds(primary) > 0 &&
              PeriodSeconds(confirm) > 0);
   }

   string MakeSignalID(const string symbol, const ENUM_TIMEFRAMES timeframe,
                       const KBLXDirection direction, const datetime second_pivot,
                       const datetime third_pivot)
   {
      return StringFormat("%s:%d:%d:%I64d:%I64d", symbol, (int)timeframe,
                          (int)direction, (long)second_pivot, (long)third_pivot);
   }

public:
   CKBLXSignalEngine()
   {
      m_buy_choch_seen = false;
      m_buy_bos_seen = false;
      m_sell_choch_seen = false;
      m_sell_bos_seen = false;
      m_buy_setup_time = 0;
      m_sell_setup_time = 0;
      m_buy_setup_key = "";
      m_sell_setup_key = "";
   }

   bool Analyze(CKBLXMarketData &data, CKBLXStructureEngine &engine,
                const string symbol, const ENUM_TIMEFRAMES primary_tf,
                const ENUM_TIMEFRAMES confirm_tf, const KBLXStructure &structure,
                const KBLXStructure &confirm_structure, const int history_bars,
                const KBLXBreakConfirmation break_confirmation,
                const KBLXBreakSelection break_selection,
                const bool enable_a, const bool enable_b, const bool enable_c,
                const bool enable_d, const KBLXRetracementMode retrace_mode,
                const int required_retracements, const double tolerance_points,
                const double fib_ratio, const bool primary_gate,
                const KBLXPrimaryGateMode primary_gate_mode,
                const double secondary_fib_ratio,
                const bool require_sweep, const double sweep_tolerance_points,
                const int setup_maximum_age, const bool engulf_body_only,
                const bool fib_use_wicks, const int zone_expiry_bars,
                const bool trendline_enabled, const double trendline_width_points,
                const double confirmation_weight,
                KBLXSignal &signal)
   {
      signal.valid = false;
      if(!structure.valid || !confirm_structure.valid ||
         !EligibleTimeframe(primary_tf, confirm_tf))
         return false;

      KBLXSwingPoint swings[];
      ArrayResize(swings, engine.SwingCount());
      int swing_count = engine.GetSwings(swings, engine.SwingCount());
      if(swing_count < 5)
         return false;

      KBLXSwingPoint lows[32];
      KBLXSwingPoint highs[32];
      int low_count = 0;
      int high_count = 0;
      for(int i = 0; i < swing_count; i++)
      {
         if(swings[i].type == KBLX_SWING_LOW && low_count < 32)
            lows[low_count++] = swings[i];
         else if(swings[i].type == KBLX_SWING_LOW)
         {
            for(int j = 1; j < 32; j++) lows[j - 1] = lows[j];
            lows[31] = swings[i];
         }
         if(swings[i].type == KBLX_SWING_HIGH && high_count < 32)
            highs[high_count++] = swings[i];
         else if(swings[i].type == KBLX_SWING_HIGH)
         {
            for(int j = 1; j < 32; j++) highs[j - 1] = highs[j];
            highs[31] = swings[i];
         }
      }
      if(low_count < 2 || high_count < 2)
         return false;

      KBLXDirection direction = KBLX_DIRECTION_NONE;
      KBLXSwingPoint first_extreme, middle_pivot, last_extreme;
      KBLXSwingPoint buy_middle, sell_middle;
      bool has_buy_middle = false;
      bool has_sell_middle = false;
      for(int i = high_count - 1; i >= 0; i--)
         if(highs[i].pivot_time > lows[low_count - 2].pivot_time &&
            highs[i].pivot_time < lows[low_count - 1].pivot_time)
         {
            buy_middle = highs[i];
            has_buy_middle = true;
            break;
         }
      for(int i = low_count - 1; i >= 0; i--)
         if(lows[i].pivot_time > highs[high_count - 2].pivot_time &&
            lows[i].pivot_time < highs[high_count - 1].pivot_time)
         {
            sell_middle = lows[i];
            has_sell_middle = true;
            break;
         }
      if(has_buy_middle &&
         lows[low_count - 2].price < buy_middle.price &&
         lows[low_count - 1].price < lows[low_count - 2].price)
      {
         first_extreme = lows[low_count - 2];
         middle_pivot = buy_middle;
         last_extreme = lows[low_count - 1];
         direction = KBLX_DIRECTION_BUY;
      }
      else if(has_sell_middle &&
              highs[high_count - 2].price > sell_middle.price &&
              highs[high_count - 1].price > highs[high_count - 2].price)
      {
         first_extreme = highs[high_count - 2];
         middle_pivot = sell_middle;
         last_extreme = highs[high_count - 1];
         direction = KBLX_DIRECTION_SELL;
      }
      if(direction == KBLX_DIRECTION_NONE)
         return false;
      double sweep_tolerance = MathMax(0.0, sweep_tolerance_points) * data.PointSize(symbol);
      if(require_sweep &&
         ((direction == KBLX_DIRECTION_BUY &&
           first_extreme.price - last_extreme.price < sweep_tolerance) ||
          (direction == KBLX_DIRECTION_SELL &&
           last_extreme.price - first_extreme.price < sweep_tolerance)))
         return false;
      if(setup_maximum_age > 0 && last_extreme.shift > setup_maximum_age)
         return false;

      MqlRates rates[];
      int requested = MathMax(history_bars, 100);
      if(!data.GetRates(symbol, primary_tf, requested, rates) || ArraySize(rates) < 3)
         return false;
      bool close_break = (direction == KBLX_DIRECTION_BUY
                          ? rates[1].close > middle_pivot.price
                          : rates[1].close < middle_pivot.price);
      MqlTick tick;
      if(!SymbolInfoTick(symbol, tick))
         return false;
      bool intrabar_break = (direction == KBLX_DIRECTION_BUY
                             ? tick.ask > middle_pivot.price
                             : tick.bid < middle_pivot.price);
      bool break_confirmed = (break_confirmation == KBLX_CLOSE_ONLY ? close_break :
                              break_confirmation == KBLX_INTRABAR ? intrabar_break :
                              (close_break || intrabar_break));
      if(!break_confirmed)
         return false;
      int break_shift = -1;
      int first_candidate_shift = MathMin(middle_pivot.shift - 1, ArraySize(rates) - 2);
      for(int shift = first_candidate_shift; shift >= 1; shift--)
      {
         bool crossed = (direction == KBLX_DIRECTION_BUY
                         ? rates[shift].close > middle_pivot.price &&
                           rates[shift + 1].close <= middle_pivot.price
                         : rates[shift].close < middle_pivot.price &&
                           rates[shift + 1].close >= middle_pivot.price);
         if(crossed)
         {
            break_shift = shift;
            break;
         }
      }
      double break_price = (break_shift >= 1
                            ? rates[break_shift].close : middle_pivot.price);
      datetime break_time = (break_shift >= 1 ? rates[break_shift].time :
                             intrabar_break && !close_break ? rates[0].time : rates[1].time);

      KBLXBreakType break_type = KBLX_BREAK_NONE;
      if(direction == KBLX_DIRECTION_BUY)
         break_type = (structure.trend == KBLX_TREND_UP
                       ? KBLX_BREAK_BOS : KBLX_BREAK_CHOCH);
      else
         break_type = (structure.trend == KBLX_TREND_DOWN
                       ? KBLX_BREAK_BOS : KBLX_BREAK_CHOCH);
      if(break_selection == KBLX_CHOCH_AND_BOS)
      {
         string setup_key = StringFormat("%s:%d:%I64d", symbol, (int)primary_tf,
                                         (long)first_extreme.pivot_time);
         if(direction == KBLX_DIRECTION_BUY)
         {
            if(m_buy_setup_key != setup_key)
            {
               m_buy_setup_key = setup_key;
               m_buy_setup_time = first_extreme.pivot_time;
               m_buy_choch_seen = false;
               m_buy_bos_seen = false;
            }
            if(break_type == KBLX_BREAK_CHOCH) m_buy_choch_seen = true;
            if(break_type == KBLX_BREAK_BOS) m_buy_bos_seen = true;
            if(!m_buy_choch_seen || !m_buy_bos_seen) return false;
         }
         else
         {
            if(m_sell_setup_key != setup_key)
            {
               m_sell_setup_key = setup_key;
               m_sell_setup_time = first_extreme.pivot_time;
               m_sell_choch_seen = false;
               m_sell_bos_seen = false;
            }
            if(break_type == KBLX_BREAK_CHOCH) m_sell_choch_seen = true;
            if(break_type == KBLX_BREAK_BOS) m_sell_bos_seen = true;
            if(!m_sell_choch_seen || !m_sell_bos_seen) return false;
         }
      }
      else if(!BreakAllowed(break_type, break_selection))
         return false;

      double point = data.PointSize(symbol);
      double tolerance = MathMax(0.0, tolerance_points) * point;
      bool module[4] = {false, false, false, false};
      bool configured[4];
      configured[0] = enable_a;
      configured[1] = enable_b;
      configured[2] = enable_c;
      configured[3] = enable_d;
      double targets[4] = {0.0, 0.0, 0.0, 0.0};
      double zone_lows[4] = {0.0, 0.0, 0.0, 0.0};
      double zone_highs[4] = {0.0, 0.0, 0.0, 0.0};
      module[0] = enable_a;
      targets[0] = first_extreme.price;
      zone_lows[0] = first_extreme.price;
      zone_highs[0] = first_extreme.price;

      int anchor_shift = -1;
      int engulf_shift = -1;
      for(int i = 2; i < ArraySize(rates) - 1; i++)
      {
         if(rates[i].time > first_extreme.pivot_time &&
            rates[i].time < last_extreme.pivot_time)
         {
            bool opposite_candle = (direction == KBLX_DIRECTION_BUY
                                    ? rates[i].close > rates[i].open
                                    : rates[i].close < rates[i].open);
            if(opposite_candle && anchor_shift < 0)
               anchor_shift = i;
            bool engulfed = (engulf_body_only
                             ? (direction == KBLX_DIRECTION_BUY
                                ? rates[i - 1].open >= rates[i].close &&
                                  rates[i - 1].close <= rates[i].open
                                : rates[i - 1].open <= rates[i].close &&
                                  rates[i - 1].close >= rates[i].open)
                             : (rates[i - 1].high >= rates[i].high &&
                                rates[i - 1].low <= rates[i].low));
            bool newer_candle_in_reversal = rates[i - 1].time < last_extreme.pivot_time;
            if(direction == KBLX_DIRECTION_BUY && newer_candle_in_reversal && engulfed &&
               rates[i].close > rates[i].open &&
               rates[i - 1].close < rates[i - 1].open &&
               engulfed)
               engulf_shift = i;
            if(direction == KBLX_DIRECTION_SELL && newer_candle_in_reversal && engulfed &&
               rates[i].close < rates[i].open &&
               rates[i - 1].close > rates[i - 1].open &&
               engulfed)
               engulf_shift = i;
         }
      }
      module[1] = enable_b && engulf_shift >= 1;
      if(module[1])
      {
         targets[1] = (direction == KBLX_DIRECTION_BUY
                       ? (rates[engulf_shift].open + rates[engulf_shift].close) * 0.5
                       : (rates[engulf_shift].open + rates[engulf_shift].close) * 0.5);
         zone_lows[1] = (engulf_body_only
                         ? MathMin(rates[engulf_shift].open, rates[engulf_shift].close)
                         : rates[engulf_shift].low);
         zone_highs[1] = (engulf_body_only
                          ? MathMax(rates[engulf_shift].open, rates[engulf_shift].close)
                          : rates[engulf_shift].high);
      }
      module[2] = enable_c && anchor_shift >= 1;
      if(module[2])
      {
         targets[2] = (direction == KBLX_DIRECTION_BUY
                       ? (rates[anchor_shift].open + rates[anchor_shift].close) * 0.5
                       : (rates[anchor_shift].open + rates[anchor_shift].close) * 0.5);
         zone_lows[2] = rates[anchor_shift].low;
         zone_highs[2] = rates[anchor_shift].high;
      }
      double fib_start = last_extreme.price;
      if(!fib_use_wicks && last_extreme.shift < ArraySize(rates))
         fib_start = (direction == KBLX_DIRECTION_BUY
                      ? MathMin(rates[last_extreme.shift].open, rates[last_extreme.shift].close)
                      : MathMax(rates[last_extreme.shift].open, rates[last_extreme.shift].close));
      double span = MathAbs(break_price - fib_start);
      module[3] = enable_d && fib_ratio > 0.0 && fib_ratio < 1.0 && span > 0.0;
      targets[3] = (direction == KBLX_DIRECTION_BUY
                    ? fib_start + span * fib_ratio
                    : fib_start - span * fib_ratio);
      zone_lows[3] = targets[3] - tolerance;
      zone_highs[3] = targets[3] + tolerance;

      int passes = 0;
      int selected = -1;
      for(int m = 0; m < 4; m++)
      {
         if(!module[m])
            continue;
         bool touched = false;
         if(m == 0)
         {
            touched = Touches(rates[1], targets[m], tolerance);
            if(break_confirmation != KBLX_CLOSE_ONLY)
               touched = touched || (direction == KBLX_DIRECTION_BUY
                                     ? tick.ask <= targets[m] + tolerance && tick.ask >= targets[m] - tolerance
                                     : tick.bid <= targets[m] + tolerance && tick.bid >= targets[m] - tolerance);
         }
         else if(m == 1 || m == 2)
            touched = Intersects(rates[1], zone_lows[m], zone_highs[m], tolerance);
         else
            touched = Touches(rates[1], targets[m], tolerance);
         if(touched)
         {
            passes++;
            if(selected < 0)
               selected = m;
         }
      }
      int enabled_count = 0;
      for(int m = 0; m < 4; m++)
         if(configured[m]) enabled_count++;
      if(enabled_count == 0)
         return false;
      bool retracement_pass = false;
      if(retrace_mode == KBLX_RETRACE_ALL)
         retracement_pass = (passes == enabled_count);
      else if(retrace_mode == KBLX_RETRACE_CONFLUENCE_REQUIRED)
         retracement_pass = (passes >= MathMax(1, required_retracements));
      else
         retracement_pass = (passes > 0);
      if(!retracement_pass || selected < 0)
         return false;
      if((retrace_mode == KBLX_RETRACE_PRIORITY || retrace_mode == KBLX_RETRACE_FIRST_VALID) &&
         !module[selected])
         return false;

      bool fib_gate = false;
      if(secondary_fib_ratio > 0.0 && secondary_fib_ratio < 1.0 && span > 0.0)
      {
         double gate_fib = (direction == KBLX_DIRECTION_BUY
                            ? fib_start + span * secondary_fib_ratio
                            : fib_start - span * secondary_fib_ratio);
         fib_gate = Touches(rates[1], gate_fib, tolerance);
      }
      bool zone_gate = (module[1] && Intersects(rates[1], zone_lows[1], zone_highs[1], tolerance)) ||
                       (module[2] && Intersects(rates[1], zone_lows[2], zone_highs[2], tolerance));
      bool trendline_gate = false;
      if(trendline_enabled && swing_count >= 4)
      {
         KBLXSwingPoint line1, line2;
         int line_count = 0;
         for(int i = swing_count - 1; i >= 0; i--)
            if(swings[i].type == (direction == KBLX_DIRECTION_BUY
                                  ? KBLX_SWING_LOW : KBLX_SWING_HIGH))
            {
               if(line_count == 0)
               {
                  line2 = swings[i];
                  line_count++;
               }
               else
               {
                  line1 = swings[i];
                  line_count++;
                  break;
               }
            }
         if(line_count == 2 && line1.pivot_time > 0 && line2.pivot_time > line1.pivot_time)
         {
            double slope = (line2.price - line1.price) /
                           (double)(line2.pivot_time - line1.pivot_time);
            double projected = line2.price + slope * (rates[1].time - line2.pivot_time);
            double width = MathMax(0.0, trendline_width_points) * point;
            if(rates[1].low <= projected + width && rates[1].high >= projected - width)
               trendline_gate = true;
         }
      }
      int gate_components = 1 + ((enable_b || enable_c) ? 1 : 0) +
                            (trendline_enabled ? 1 : 0);
      int gates_passed = (fib_gate ? 1 : 0) + (zone_gate ? 1 : 0) +
                         (trendline_gate ? 1 : 0);
      bool gate = (primary_gate_mode == KBLX_PRIMARY_GATE_ALL
                   ? gates_passed == gate_components : gates_passed > 0);
      if(primary_gate && !gate)
         return false;

      bool confirm_aligned = (direction == KBLX_DIRECTION_BUY
                              ? confirm_structure.trend == KBLX_TREND_UP
                              : confirm_structure.trend == KBLX_TREND_DOWN);
      if(!confirm_aligned)
         return false;
      signal.id = MakeSignalID(symbol, primary_tf, direction,
                               first_extreme.pivot_time, last_extreme.pivot_time);
      signal.symbol = symbol;
      signal.direction = direction;
      signal.primary_timeframe = primary_tf;
      signal.confirmation_timeframe = confirm_tf;
      signal.break_type = break_type;
      signal.retracement = (KBLXRetracement)(selected + 1);
      signal.zone.low = zone_lows[selected] - tolerance;
      signal.zone.high = zone_highs[selected] + tolerance;
      signal.zone.created = break_time;
      signal.zone.expires = break_time +
                            (datetime)(PeriodSeconds(primary_tf) * MathMax(1, zone_expiry_bars));
      signal.zone.valid = true;
      signal.entry = targets[selected];
      signal.invalidation = (direction == KBLX_DIRECTION_BUY
                             ? last_extreme.price : last_extreme.price);
      signal.target_reference = middle_pivot.price;
      signal.score = (50.0 + passes * 10.0 + (confirm_aligned ? 20.0 : 0.0)) *
                     MathMax(0.0, confirmation_weight);
      signal.created = break_time;
      signal.valid = true;
      return true;
   }
};

#endif
