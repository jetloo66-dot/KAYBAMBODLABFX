#ifndef KBLX_SIGNAL_ENGINE_MQH
#define KBLX_SIGNAL_ENGINE_MQH

#include "..\Market\StructureEngine.mqh"

class CKBLXSignalEngine
{
private:
   bool Touches(const MqlRates &bar, const double level, const double tolerance)
   {
      return bar.low <= level + tolerance && bar.high >= level - tolerance;
   }

   bool Intersects(const MqlRates &bar, const double low, const double high,
                   const double tolerance)
   {
      return bar.low <= high + tolerance && bar.high >= low - tolerance;
   }

   string MakeSignalID(const string symbol, const ENUM_TIMEFRAMES timeframe,
                       const KBLXDirection direction, const datetime first_pivot,
                       const datetime last_pivot)
   {
      return StringFormat("%s:%d:%d:%I64d:%I64d", symbol, (int)timeframe,
                          (int)direction, (long)first_pivot, (long)last_pivot);
   }

public:
   bool Analyze(CKBLXMarketData &data, CKBLXStructureEngine &engine,
                const string symbol, const ENUM_TIMEFRAMES timeframe,
                const KBLXStructure &structure, const int history_bars,
                const KBLXBreakSelection break_selection,
                const bool require_liquidity_sweep,
                const double liquidity_sweep_tolerance_points,
                const bool enable_b, const bool enable_c, const bool enable_d,
                const KBLXRetracementMode retrace_mode,
                const int required_retracements, const double tolerance_points,
                const double fib_ratio, const bool fib_use_wicks,
                const bool require_primary_gate,
                const KBLXPrimaryGateMode primary_gate_mode,
                const int maximum_setup_age, const int zone_expiry_bars,
                const bool engulf_body_only, const double fib_gate_ratio,
                const bool enable_trendline, const double trendline_width_points,
                const bool require_closed_retrace,
                const KBLXStructure &confirmation_structure,
                const bool require_confirmation,
                const double confirmation_weight, KBLXSignal &signal)
   {
      signal.valid = false;
      if(!structure.valid)
         return false;

      KBLXSwingPoint swings[];
      ArrayResize(swings, engine.SwingCount());
      int swing_count = engine.GetSwings(swings, engine.SwingCount());
      if(swing_count < 5)
         return false;

      int ll2_index = -1, lh2_index = -1, ll1_index = -1;
      int hh2_index = -1, hl2_index = -1, hh1_index = -1;
      for(int last = swing_count - 1; last >= 2; last--)
      {
         if(swings[last].type != KBLX_SWING_LOW)
            continue;
         for(int first = last - 2; first >= 0; first--)
         {
            if(swings[first].type != KBLX_SWING_LOW)
               continue;
            int middle = -1;
            for(int candidate = last - 1; candidate > first; candidate--)
               if(swings[candidate].type == KBLX_SWING_HIGH)
               {
                  middle = candidate;
                  break;
               }
            if(middle >= 0 && swings[last].price < swings[first].price &&
               swings[first].price < swings[middle].price)
            {
               ll2_index = first;
               lh2_index = middle;
               ll1_index = last;
               break;
            }
         }
         if(ll1_index >= 0)
            break;
      }
      for(int last = swing_count - 1; last >= 2; last--)
      {
         if(swings[last].type != KBLX_SWING_HIGH)
            continue;
         for(int first = last - 2; first >= 0; first--)
         {
            if(swings[first].type != KBLX_SWING_HIGH)
               continue;
            int middle = -1;
            for(int candidate = last - 1; candidate > first; candidate--)
               if(swings[candidate].type == KBLX_SWING_LOW)
               {
                  middle = candidate;
                  break;
               }
            if(middle >= 0 && swings[last].price > swings[first].price &&
               swings[first].price > swings[middle].price)
            {
               hh2_index = first;
               hl2_index = middle;
               hh1_index = last;
               break;
            }
         }
         if(hh1_index >= 0)
            break;
      }

      KBLXDirection direction = KBLX_DIRECTION_NONE;
      int first_index = -1, middle_index = -1, last_index = -1;
      if(ll1_index >= 0)
      {
         direction = KBLX_DIRECTION_BUY;
         first_index = ll2_index;
         middle_index = lh2_index;
         last_index = ll1_index;
      }
      else if(hh1_index >= 0)
      {
         direction = KBLX_DIRECTION_SELL;
         first_index = hh2_index;
         middle_index = hl2_index;
         last_index = hh1_index;
      }
      if(direction == KBLX_DIRECTION_NONE)
         return false;

      KBLXSwingPoint first_pivot = swings[first_index];
      KBLXSwingPoint middle_pivot = swings[middle_index];
      KBLXSwingPoint last_pivot = swings[last_index];

      MqlRates rates[];
      int requested = MathMax(history_bars, 100);
      if(!data.GetRates(symbol, timeframe, requested, rates))
         return false;
      int first_rate_shift = -1;
      int last_rate_shift = -1;
      for(int shift = 1; shift < ArraySize(rates); shift++)
      {
         if(rates[shift].time == first_pivot.pivot_time)
            first_rate_shift = shift;
         if(rates[shift].time == last_pivot.pivot_time)
            last_rate_shift = shift;
      }
      if(first_rate_shift < 1 || last_rate_shift < 1 ||
         (maximum_setup_age > 0 && last_rate_shift > maximum_setup_age))
         return false;

      int break_shift = -1;
      int oldest_after_pivot = MathMin(last_rate_shift - 1, ArraySize(rates) - 2);
      for(int shift = oldest_after_pivot; shift >= 1; shift--)
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
      if(break_shift < 1)
         return false;

      KBLXBreakType break_type = ((direction == KBLX_DIRECTION_BUY &&
                                   structure.trend == KBLX_TREND_UP) ||
                                  (direction == KBLX_DIRECTION_SELL &&
                                   structure.trend == KBLX_TREND_DOWN)
                                  ? KBLX_BREAK_BOS : KBLX_BREAK_CHOCH);
      if(break_selection == KBLX_CHOCH_ONLY && break_type != KBLX_BREAK_CHOCH)
         return false;
      if(break_selection == KBLX_BOS_ONLY && break_type != KBLX_BREAK_BOS)
         return false;

      int age_since_break = break_shift - 1;
      if(maximum_setup_age > 0 && age_since_break > maximum_setup_age)
         return false;
      int second_confirmation_shift = first_rate_shift;
      bool zone_touch = false;
      datetime retrace_time = 0;
      double zone_low = rates[first_rate_shift].low;
      double zone_high = rates[first_rate_shift].high;
      double point = data.PointSize(symbol);
      double tolerance = MathMax(0.0, tolerance_points) * point;
      double sweep_tolerance = MathMax(0.0, liquidity_sweep_tolerance_points) * point;
      if(require_liquidity_sweep &&
         ((direction == KBLX_DIRECTION_BUY &&
           first_pivot.price - last_pivot.price < sweep_tolerance) ||
          (direction == KBLX_DIRECTION_SELL &&
           last_pivot.price - first_pivot.price < sweep_tolerance)))
         return false;
      MqlTick tick;
      if(!SymbolInfoTick(symbol, tick) || point <= 0.0)
         return false;
      double live_price = (direction == KBLX_DIRECTION_BUY ? tick.ask : tick.bid);
      if(require_closed_retrace)
      {
         int shift = 1;
         bool beyond_invalidation =
            (direction == KBLX_DIRECTION_BUY
            ? rates[shift].low <= last_pivot.price
            : rates[shift].high >= last_pivot.price);
         if(shift < break_shift && !beyond_invalidation &&
            Touches(rates[shift],
                    direction == KBLX_DIRECTION_BUY ? zone_low : zone_high,
                    tolerance))
         {
            zone_touch = true;
            retrace_time = rates[shift].time;
            second_confirmation_shift = shift;
         }
      }
      else if((direction == KBLX_DIRECTION_BUY
               ? live_price <= zone_low + tolerance &&
                 live_price > last_pivot.price
               : live_price >= zone_high - tolerance &&
                 live_price < last_pivot.price))
      {
         zone_touch = true;
         retrace_time = rates[0].time;
         second_confirmation_shift = 0;
      }
      if(!zone_touch || retrace_time <= rates[break_shift].time)
         return false;

      bool module[4];
      module[0] = true;
      module[1] = false;
      module[2] = false;
      module[3] = false;
      double targets[4];
      targets[0] = first_pivot.price;
      targets[1] = 0.0;
      targets[2] = 0.0;
      targets[3] = 0.0;
      double zone_lows[4];
      double zone_highs[4];
      zone_lows[0] = zone_low;
      zone_highs[0] = zone_high;
      zone_lows[1] = 0.0; zone_highs[1] = 0.0;
      zone_lows[2] = 0.0; zone_highs[2] = 0.0;
      zone_lows[3] = 0.0; zone_highs[3] = 0.0;
      int anchor_shift = -1;
      int engulf_shift = -1;
      for(int i = 2; i < ArraySize(rates) - 1; i++)
      {
         if(rates[i].time <= first_pivot.pivot_time ||
            rates[i].time >= last_pivot.pivot_time)
            continue;
         bool opposite = (direction == KBLX_DIRECTION_BUY
                          ? rates[i].close > rates[i].open
                          : rates[i].close < rates[i].open);
         if(opposite && anchor_shift < 0)
            anchor_shift = i;
         bool engulf = (engulf_body_only
                        ? (direction == KBLX_DIRECTION_BUY
                           ? rates[i - 1].open >= rates[i].close &&
                             rates[i - 1].close <= rates[i].open
                           : rates[i - 1].open <= rates[i].close &&
                             rates[i - 1].close >= rates[i].open)
                        : (rates[i - 1].high >= rates[i].high &&
                           rates[i - 1].low <= rates[i].low));
         if(engulf && rates[i - 1].time < last_pivot.pivot_time &&
            ((direction == KBLX_DIRECTION_BUY && rates[i].close > rates[i].open &&
              rates[i - 1].close < rates[i - 1].open) ||
             (direction == KBLX_DIRECTION_SELL && rates[i].close < rates[i].open &&
              rates[i - 1].close > rates[i - 1].open)))
            engulf_shift = i;
      }

      module[1] = enable_b && engulf_shift >= 1;
      if(module[1])
      {
         zone_lows[1] = (engulf_body_only
                         ? MathMin(rates[engulf_shift].open, rates[engulf_shift].close)
                         : rates[engulf_shift].low);
         zone_highs[1] = (engulf_body_only
                          ? MathMax(rates[engulf_shift].open, rates[engulf_shift].close)
                          : rates[engulf_shift].high);
         targets[1] = (zone_lows[1] + zone_highs[1]) * 0.5;
      }
      module[2] = enable_c && anchor_shift >= 1;
      if(module[2])
      {
         zone_lows[2] = rates[anchor_shift].low;
         zone_highs[2] = rates[anchor_shift].high;
         targets[2] = (zone_lows[2] + zone_highs[2]) * 0.5;
      }
      double fib_start = last_pivot.price;
      if(!fib_use_wicks)
         fib_start = (direction == KBLX_DIRECTION_BUY
                      ? MathMin(rates[last_rate_shift].open, rates[last_rate_shift].close)
                      : MathMax(rates[last_rate_shift].open, rates[last_rate_shift].close));
      double break_price = rates[break_shift].close;
      double span = MathAbs(break_price - fib_start);
      module[3] = enable_d && fib_ratio > 0.0 && fib_ratio < 1.0 && span > 0.0;
      targets[3] = direction == KBLX_DIRECTION_BUY
                   ? fib_start + span * fib_ratio : fib_start - span * fib_ratio;
      zone_lows[3] = targets[3] - tolerance;
      zone_highs[3] = targets[3] + tolerance;

      int configured = 1 + (enable_b ? 1 : 0) + (enable_c ? 1 : 0) + (enable_d ? 1 : 0);
      int passes = 1;
      bool zone_confluence = false;
      for(int m = 1; m < 4; m++)
      {
         if(!module[m])
         {
            if(retrace_mode == KBLX_RETRACE_ALL &&
               ((m == 1 && enable_b) || (m == 2 && enable_c) || (m == 3 && enable_d)))
               return false;
            continue;
         }
         if(Intersects(rates[second_confirmation_shift], zone_lows[m],
                       zone_highs[m], tolerance))
         {
            passes++;
            if(m == 1 || m == 2)
               zone_confluence = true;
         }
         else if(retrace_mode == KBLX_RETRACE_ALL)
            return false;
      }
      if(retrace_mode == KBLX_RETRACE_CONFLUENCE_REQUIRED &&
         passes < MathMax(1, required_retracements))
         return false;
      if(configured == 0 || (retrace_mode == KBLX_RETRACE_ALL && passes != configured))
         return false;

      bool fib_gate = false;
      if(fib_gate_ratio > 0.0 && fib_gate_ratio < 1.0 && span > 0.0)
      {
         double fib_level = (direction == KBLX_DIRECTION_BUY
                             ? fib_start + span * fib_gate_ratio
                             : fib_start - span * fib_gate_ratio);
         fib_gate = Touches(rates[second_confirmation_shift], fib_level, tolerance);
      }
      bool zone_gate = zone_confluence;
      bool trendline_gate = false;
      if(enable_trendline && swing_count >= 4)
      {
         KBLXSwingPoint line1, line2;
         line1 = swings[0];
         line2 = swings[0];
         int lines = 0;
         for(int i = first_index - 1; i >= 0; i--)
         {
            if(swings[i].type != (direction == KBLX_DIRECTION_BUY
                                  ? KBLX_SWING_LOW : KBLX_SWING_HIGH))
               continue;
            if(lines == 0)
            {
               line2 = swings[i];
               lines++;
            }
            else
            {
               line1 = swings[i];
               lines++;
               break;
            }
         }
         if(lines == 2 && line2.pivot_time > line1.pivot_time)
         {
            double elapsed = (double)line2.pivot_time - (double)line1.pivot_time;
            if(elapsed <= 0.0)
               return false;
            double slope = (line2.price - line1.price) / elapsed;
            double projected = line2.price +
                               slope * ((double)retrace_time -
                                        (double)line2.pivot_time);
            double retracement_price = (require_closed_retrace
                                        ? rates[second_confirmation_shift].close
                                        : live_price);
            trendline_gate = (retracement_price >= projected - trendline_width_points * point &&
                              retracement_price <= projected + trendline_width_points * point);
         }
      }
      if(require_primary_gate && primary_gate_mode == KBLX_PRIMARY_GATE_ALL &&
         (!fib_gate || !zone_gate || (enable_trendline && !trendline_gate)))
         return false;
      if(require_primary_gate && primary_gate_mode == KBLX_PRIMARY_GATE_ANY &&
         !fib_gate && !zone_gate && !trendline_gate)
         return false;

      bool confirmation_aligned = (direction == KBLX_DIRECTION_BUY
                                   ? confirmation_structure.trend == KBLX_TREND_UP
                                   : confirmation_structure.trend == KBLX_TREND_DOWN);
      if(require_confirmation && !confirmation_aligned)
         return false;

      signal.id = MakeSignalID(symbol, timeframe, direction,
                               first_pivot.pivot_time, last_pivot.pivot_time);
      signal.symbol = symbol;
      signal.direction = direction;
      signal.primary_timeframe = timeframe;
      signal.confirmation_timeframe = PERIOD_CURRENT;
      signal.break_type = break_type;
      signal.retracement = KBLX_RETRACE_A;
      signal.zone.low = zone_low - tolerance;
      signal.zone.high = zone_high + tolerance;
      signal.zone.created = first_pivot.pivot_time;
      signal.zone.expires = rates[break_shift].time +
                            (datetime)(PeriodSeconds(timeframe) * MathMax(1, zone_expiry_bars));
      signal.zone.valid = true;
      signal.entry = (direction == KBLX_DIRECTION_BUY ? zone_low : zone_high);
      signal.invalidation = last_pivot.price;
      signal.target_reference = middle_pivot.price;
      signal.first_pivot_time = first_pivot.pivot_time;
      signal.middle_pivot_time = middle_pivot.pivot_time;
      signal.last_pivot_time = last_pivot.pivot_time;
      signal.break_time = rates[break_shift].time;
      signal.retracement_time = retrace_time;
      signal.first_pivot_price = first_pivot.price;
      signal.middle_pivot_price = middle_pivot.price;
      signal.last_pivot_price = last_pivot.price;
      signal.score = (50.0 + passes * 10.0 +
                      (confirmation_aligned ? 20.0 : 0.0)) *
                     MathMax(0.0, confirmation_weight);
      signal.created = retrace_time;
      signal.valid = true;
      return true;
   }
};

#endif
