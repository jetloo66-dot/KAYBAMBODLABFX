#ifndef KBLX_RISK_MANAGER_MQH
#define KBLX_RISK_MANAGER_MQH

#include "..\Core\MarketData.mqh"

class CKBLXRiskManager
{
private:
   int VolumeDigits(const double step)
   {
      for(int digits = 0; digits <= 8; digits++)
         if(MathAbs(NormalizeDouble(step, digits) - step) < 1e-10)
            return digits;
      return 8;
   }

   bool IsCurrencyCode(const string code)
   {
      string codes = " USD EUR GBP JPY CHF CAD AUD NZD SEK NOK DKK PLN CZK HUF TRY ZAR MXN SGD HKD CNY CNH INR THB BRL KRW RUB ";
      return StringFind(codes, " " + code + " ") >= 0;
   }

public:
   double DistancePrice(const string symbol, const double distance,
                        const KBLXDistanceUnitMode mode)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(point <= 0.0 || distance < 0.0)
         return -1.0;
      if(mode == KBLX_UNITS_POINTS)
         return distance * point;
      bool forex = false;
      if(StringLen(symbol) >= 6)
      {
         string base = StringSubstr(symbol, 0, 3);
         string quote = StringSubstr(symbol, 3, 3);
         forex = IsCurrencyCode(base) && IsCurrencyCode(quote);
      }
      if(mode == KBLX_UNITS_PIPS && !forex)
         return -1.0;
      if(mode == KBLX_UNITS_AUTO && !forex)
         return distance * point;
      long digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double pip = ((digits == 3 || digits == 5) ? point * 10.0 : point);
      return distance * pip;
   }

   double NormalizeVolume(const string symbol, const double requested)
   {
      double minimum = 0.0, maximum = 0.0, step = 0.0;
      if(!SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN, minimum) ||
         !SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX, maximum) ||
         !SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP, step) ||
         minimum <= 0.0 || maximum < minimum || step <= 0.0)
         return 0.0;

      if(requested < minimum)
         return 0.0;
      double volume = MathMin(requested, maximum);
      volume = MathFloor(volume / step + 1e-9) * step;
      if(volume < minimum)
         return 0.0;
      return NormalizeDouble(volume, VolumeDigits(step));
   }

   double CalculateVolume(const string symbol, const KBLXDirection direction,
                          const double entry, const double stop,
                          const KBLXSizingMode mode, const double fixed_lots,
                          const double risk_percent, const double risk_money)
   {
      if(mode == KBLX_FIXED_LOT)
         return NormalizeVolume(symbol, fixed_lots);
      double cash_risk = risk_money;
      if(mode == KBLX_RISK_PERCENT || mode == KBLX_DYNAMIC_RISK)
      {
         double equity = AccountInfoDouble(ACCOUNT_EQUITY);
         cash_risk = equity * MathMax(0.0, risk_percent) / 100.0;
      }
      if(cash_risk <= 0.0 || entry <= 0.0 || stop <= 0.0 ||
         MathAbs(entry - stop) <= 0.0)
         return 0.0;

      double one_lot_profit = 0.0;
      ENUM_ORDER_TYPE order_type = (direction == KBLX_DIRECTION_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      if(!OrderCalcProfit(order_type, symbol, 1.0, entry, stop, one_lot_profit))
         return 0.0;
      double loss_per_lot = MathAbs(one_lot_profit);
      if(loss_per_lot <= 0.0)
         return 0.0;
      return NormalizeVolume(symbol, cash_risk / loss_per_lot);
   }

   bool BuildStops(CKBLXMarketData &data, const KBLXSignal &signal,
                   const KBLXStopMode mode, const double fixed_points,
                   const double buffer_points, const double rr,
                   const double manual_stop, const int atr_period,
                   const double atr_multiplier, const KBLXTakeProfitMode tp_mode,
                   const double manual_target, const double fib_extension_ratio,
                   double &stop, double &target,
                   const KBLXDistanceUnitMode distance_units = KBLX_UNITS_AUTO,
                   const bool pending_entry = false)
   {
      string symbol = signal.symbol;
      double point = data.PointSize(symbol);
      double entry = signal.entry;
      if(point <= 0.0 || entry <= 0.0)
         return false;
      double stop_distance = DistancePrice(symbol, fixed_points, distance_units);
      double buffer_distance = DistancePrice(symbol, buffer_points, distance_units);
      if(buffer_distance < 0.0 ||
         (mode == KBLX_SL_FIXED_DISTANCE && stop_distance <= 0.0) ||
         (stop_distance < 0.0))
         return false;

      if(mode == KBLX_SL_MANUAL)
         stop = manual_stop;
      else if(mode == KBLX_SL_ZONE_BASED)
         stop = (signal.direction == KBLX_DIRECTION_BUY
                 ? signal.zone.low - buffer_distance
                 : signal.zone.high + buffer_distance);
      else if(mode == KBLX_SL_SWING_BASED)
         stop = (signal.direction == KBLX_DIRECTION_BUY
                 ? signal.invalidation - buffer_distance
                 : signal.invalidation + buffer_distance);
      else if(mode == KBLX_SL_HYBRID)
         stop = (signal.direction == KBLX_DIRECTION_BUY
                 ? MathMin(signal.invalidation, signal.zone.low) - buffer_distance
                 : MathMax(signal.invalidation, signal.zone.high) + buffer_distance);
      else if(mode == KBLX_SL_ATR_BASED)
      {
         if(atr_period < 1 || atr_multiplier <= 0.0)
            return false;
         MqlRates rates[];
         if(!data.GetRates(symbol, signal.primary_timeframe, atr_period + 2, rates))
            return false;
         double atr = 0.0;
         for(int i = 1; i <= atr_period; i++)
         {
            double range = MathMax(rates[i].high - rates[i].low,
                                   MathAbs(rates[i].high - rates[i + 1].close));
            range = MathMax(range, MathAbs(rates[i].low - rates[i + 1].close));
            atr += range;
         }
         atr /= atr_period;
         stop = (signal.direction == KBLX_DIRECTION_BUY
                 ? entry - atr * atr_multiplier - buffer_distance
                 : entry + atr * atr_multiplier + buffer_distance);
      }
      else
         stop = (signal.direction == KBLX_DIRECTION_BUY
                 ? entry - stop_distance
                 : entry + stop_distance);

      double tick_size = data.TickSize(symbol);
      if(tick_size <= 0.0)
         return false;
      if(signal.direction == KBLX_DIRECTION_BUY)
         stop = NormalizeDouble(MathCeil(stop / tick_size - 1e-10) * tick_size, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
      else
         stop = NormalizeDouble(MathFloor(stop / tick_size + 1e-10) * tick_size, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
      if(stop <= 0.0 ||
         (signal.direction == KBLX_DIRECTION_BUY && stop >= entry) ||
         (signal.direction == KBLX_DIRECTION_SELL && stop <= entry))
         return false;
      double risk_distance = MathAbs(entry - stop);
      if(risk_distance <= 0.0 || rr <= 0.0)
         return false;
      double raw_target = 0.0;
      if(tp_mode == KBLX_TP_MANUAL)
         raw_target = manual_target;
      else if(tp_mode == KBLX_TP_STRUCTURE)
         raw_target = signal.target_reference;
      else if(tp_mode == KBLX_TP_FIBONACCI)
      {
         if(fib_extension_ratio <= 0.0)
            return false;
         raw_target = (signal.direction == KBLX_DIRECTION_BUY
                       ? entry + risk_distance * fib_extension_ratio
                       : entry - risk_distance * fib_extension_ratio);
      }
      else
         raw_target = (signal.direction == KBLX_DIRECTION_BUY
                       ? entry + risk_distance * rr : entry - risk_distance * rr);
      if((signal.direction == KBLX_DIRECTION_BUY && raw_target <= entry) ||
         (signal.direction == KBLX_DIRECTION_SELL && raw_target >= entry))
         return false;
      target = NormalizeDouble((signal.direction == KBLX_DIRECTION_BUY
                                ? MathCeil(raw_target / tick_size - 1e-10)
                                : MathFloor(raw_target / tick_size + 1e-10)) *
                                tick_size, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));

      long stops_level = 0, freeze_level = 0;
      SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL, stops_level);
      SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL, freeze_level);
      double minimum_distance = MathMax(stops_level, freeze_level) * point;
      MqlTick tick;
      if(!SymbolInfoTick(symbol, tick))
         return false;
      if(pending_entry)
      {
         if(signal.direction == KBLX_DIRECTION_BUY &&
            (entry >= tick.ask || tick.ask - entry < minimum_distance ||
             entry - stop < minimum_distance || target - entry < minimum_distance))
            return false;
         if(signal.direction == KBLX_DIRECTION_SELL &&
            (entry <= tick.bid || entry - tick.bid < minimum_distance ||
             stop - entry < minimum_distance || entry - target < minimum_distance))
            return false;
      }
      else
      {
         if(signal.direction == KBLX_DIRECTION_BUY &&
            (tick.bid - stop < minimum_distance || target - tick.bid < minimum_distance))
            return false;
         if(signal.direction == KBLX_DIRECTION_SELL &&
            (stop - tick.ask < minimum_distance || tick.ask - target < minimum_distance))
            return false;
      }
      return true;
   }
};

#endif
