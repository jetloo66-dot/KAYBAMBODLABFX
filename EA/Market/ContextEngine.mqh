#ifndef KBLX_CONTEXT_ENGINE_MQH
#define KBLX_CONTEXT_ENGINE_MQH

#include "StructureEngine.mqh"

class CKBLXContextEngine
{
public:
   bool Build(CKBLXMarketData &data, const string symbol,
              const ENUM_TIMEFRAMES timeframe, const KBLXStructure &structure,
              const int lookback_bars, const double zone_buffer_points,
              const int volume_bin_points, KBLXMarketContext &context)
   {
      context.valid = false;
      context.demand.valid = false;
      context.supply.valid = false;
      context.volume_zone.valid = false;
      context.volume_price = 0.0;
      context.average_volume = 0.0;
      context.trend = structure.trend;

      MqlRates rates[];
      int requested = MathMax(lookback_bars, 20);
      if(!data.GetRates(symbol, timeframe, requested, rates) ||
         ArraySize(rates) < 10)
         return false;

      double point = data.PointSize(symbol);
      if(point <= 0.0)
         return false;
      double buffer = MathMax(0.0, zone_buffer_points) * point;
      double highest_low = 0.0;
      double lowest_high = 0.0;
      int low_shift = -1;
      int high_shift = -1;
      int limit = MathMin(lookback_bars, ArraySize(rates) - 2);
      for(int shift = 3; shift <= limit; shift++)
      {
         bool pivot_low = true;
         bool pivot_high = true;
         for(int side = 1; side <= 2; side++)
         {
            if(rates[shift].low >= rates[shift - side].low ||
               rates[shift].low >= rates[shift + side].low)
               pivot_low = false;
            if(rates[shift].high <= rates[shift - side].high ||
               rates[shift].high <= rates[shift + side].high)
               pivot_high = false;
         }
         if(pivot_low && (low_shift < 0 || rates[shift].time > rates[low_shift].time))
            low_shift = shift;
         if(pivot_high && (high_shift < 0 || rates[shift].time > rates[high_shift].time))
            high_shift = shift;
      }

      if(low_shift >= 0)
      {
         context.demand.low = rates[low_shift].low - buffer;
         context.demand.high = rates[low_shift].high + buffer;
         context.demand.created = rates[low_shift].time;
         context.demand.expires = rates[low_shift].time +
                                 (datetime)(PeriodSeconds(timeframe) * lookback_bars);
         context.demand.valid = true;
      }
      if(high_shift >= 0)
      {
         context.supply.low = rates[high_shift].low - buffer;
         context.supply.high = rates[high_shift].high + buffer;
         context.supply.created = rates[high_shift].time;
         context.supply.expires = rates[high_shift].time +
                                 (datetime)(PeriodSeconds(timeframe) * lookback_bars);
         context.supply.valid = true;
      }

      double min_price = rates[1].low;
      double max_price = rates[1].high;
      for(int i = 1; i <= limit; i++)
      {
         min_price = MathMin(min_price, rates[i].low);
         max_price = MathMax(max_price, rates[i].high);
         context.average_volume += (double)rates[i].tick_volume;
      }
      context.average_volume /= MathMax(1, limit);
      double bin_width = MathMax(1, volume_bin_points) * point;
      int bins = (int)MathCeil((max_price - min_price) / bin_width) + 1;
      bins = MathMax(1, MathMin(bins, 512));
      double volumes[];
      ArrayResize(volumes, bins);
      ArrayInitialize(volumes, 0.0);
      for(int i = 1; i <= limit; i++)
      {
         double typical = (rates[i].high + rates[i].low + rates[i].close) / 3.0;
         int bin = (int)MathFloor((typical - min_price) / bin_width);
         bin = MathMax(0, MathMin(bin, bins - 1));
         volumes[bin] += (double)rates[i].tick_volume;
      }
      double maximum_volume = 0.0;
      int max_bin = 0;
      for(int i = 0; i < bins; i++)
         if(volumes[i] > maximum_volume)
         {
            maximum_volume = volumes[i];
            max_bin = i;
         }
      context.volume_price = min_price + (max_bin + 0.5) * bin_width;
      context.volume_zone.low = min_price + max_bin * bin_width;
      context.volume_zone.high = context.volume_zone.low + bin_width;
      context.volume_zone.created = rates[limit].time;
      context.volume_zone.expires = rates[1].time;
      context.volume_zone.valid = (maximum_volume > 0.0);
      context.valid = true;
      return true;
   }
};

#endif
