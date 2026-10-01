#ifndef KBLX_POSITION_MANAGER_MQH
#define KBLX_POSITION_MANAGER_MQH

#include <Trade\Trade.mqh>

class CKBLXPositionManager
{
private:
   CTrade m_trade;
   long m_magic;

   string RiskKey(const ulong ticket)
   {
      return StringFormat("KBLX_R_%I64u", ticket);
   }

   string PartialKey(const ulong ticket, const int stage)
   {
      return StringFormat("KBLX_P_%I64u_%d", ticket, stage);
   }

public:
   void Configure(const long magic)
   {
      m_magic = magic;
      m_trade.SetExpertMagicNumber(magic);
   }

   void Manage(const bool break_even_enabled, const double break_even_trigger_r,
               const double break_even_offset_points, const bool trailing_enabled,
               const double trailing_start_points, const double trailing_distance_points,
               const double trailing_step_points, const int take_profit_count,
               const double partial_close_percent)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket) ||
            PositionGetInteger(POSITION_MAGIC) != m_magic)
            continue;

         string symbol = PositionGetString(POSITION_SYMBOL);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
         double current_sl = PositionGetDouble(POSITION_SL);
         double current_tp = PositionGetDouble(POSITION_TP);
         double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
         long digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         if(point <= 0.0 || tick_size <= 0.0)
            continue;
         MqlTick tick;
         if(!SymbolInfoTick(symbol, tick))
            continue;
         double market = (type == POSITION_TYPE_BUY ? tick.bid : tick.ask);

         string risk_key = RiskKey(ticket);
         if(!GlobalVariableCheck(risk_key) && current_sl > 0.0)
            GlobalVariableSet(risk_key, MathAbs(open_price - current_sl));
         double initial_risk = (GlobalVariableCheck(risk_key)
                                ? GlobalVariableGet(risk_key) : 0.0);
         if(initial_risk > 0.0 && take_profit_count > 1 &&
            partial_close_percent > 0.0 &&
            partial_close_percent * (take_profit_count - 1) <= 100.0)
         {
            double progress = (type == POSITION_TYPE_BUY
                               ? market - open_price : open_price - market);
            for(int stage = 1; stage < take_profit_count; stage++)
            {
               string partial_key = PartialKey(ticket, stage);
               if(progress < initial_risk * stage || GlobalVariableCheck(partial_key))
                  continue;
               if(!PositionSelectByTicket(ticket))
                  break;
               double minimum = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
               double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
               double remaining = PositionGetDouble(POSITION_VOLUME);
               double close_volume = (step > 0.0
                                      ? MathFloor((remaining * partial_close_percent / 100.0) / step) * step
                                      : 0.0);
               close_volume = NormalizeDouble(close_volume, 8);
               if(close_volume < minimum || remaining - close_volume < minimum)
                  continue;
               bool close_sent = false;
               if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) ==
                  ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
                  close_sent = m_trade.PositionClosePartial(ticket, close_volume);
               else if(type == POSITION_TYPE_BUY)
                  close_sent = m_trade.Sell(close_volume, symbol, 0.0, 0.0, 0.0, "KBLX partial");
               else
                  close_sent = m_trade.Buy(close_volume, symbol, 0.0, 0.0, 0.0, "KBLX partial");
               uint close_retcode = m_trade.ResultRetcode();
               if(close_sent && (close_retcode == TRADE_RETCODE_DONE ||
                                 close_retcode == TRADE_RETCODE_DONE_PARTIAL))
                  GlobalVariableSet(partial_key, (double)TimeCurrent());
            }
         }
         double proposed_sl = current_sl;
         bool change = false;

         if(break_even_enabled && initial_risk > 0.0 && break_even_trigger_r > 0.0)
         {
            bool reached = (type == POSITION_TYPE_BUY
                            ? market - open_price >= initial_risk * break_even_trigger_r
                            : open_price - market >= initial_risk * break_even_trigger_r);
            if(reached)
            {
               double breakeven = open_price +
                  (type == POSITION_TYPE_BUY ? 1.0 : -1.0) * break_even_offset_points * point;
               if((type == POSITION_TYPE_BUY && (current_sl == 0.0 || breakeven > proposed_sl)) ||
                  (type == POSITION_TYPE_SELL && (current_sl == 0.0 || breakeven < proposed_sl)))
               {
                  proposed_sl = breakeven;
                  change = true;
               }
            }
         }

         if(trailing_enabled && trailing_start_points > 0.0 && trailing_distance_points > 0.0)
         {
            double profit_points = (type == POSITION_TYPE_BUY
                                    ? (market - open_price) / point
                                    : (open_price - market) / point);
            if(profit_points >= trailing_start_points)
            {
               double candidate = market +
                  (type == POSITION_TYPE_BUY ? -1.0 : 1.0) * trailing_distance_points * point;
               double step = MathMax(0.0, trailing_step_points) * point;
               bool improves = (type == POSITION_TYPE_BUY
                                ? (proposed_sl == 0.0 || candidate > proposed_sl + step)
                                : (proposed_sl == 0.0 || candidate < proposed_sl - step));
               if(improves)
               {
                  proposed_sl = candidate;
                  change = true;
               }
            }
         }

         if(!change)
            continue;
         proposed_sl = NormalizeDouble((type == POSITION_TYPE_BUY
                                        ? MathFloor(proposed_sl / tick_size + 1e-10)
                                        : MathCeil(proposed_sl / tick_size - 1e-10)) *
                                       tick_size, (int)digits);
         long stops_level = 0;
         SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL, stops_level);
         double minimum = stops_level * point;
         if(type == POSITION_TYPE_BUY && market - proposed_sl < minimum)
            continue;
         if(type == POSITION_TYPE_SELL && proposed_sl - market < minimum)
            continue;
         if(type == POSITION_TYPE_BUY && current_sl > 0.0 && proposed_sl <= current_sl)
            continue;
         if(type == POSITION_TYPE_SELL && current_sl > 0.0 && proposed_sl >= current_sl)
            continue;
         bool modified = m_trade.PositionModify(ticket, proposed_sl, current_tp);
         uint modify_retcode = m_trade.ResultRetcode();
         if(!modified || (modify_retcode != TRADE_RETCODE_DONE &&
                          modify_retcode != TRADE_RETCODE_NO_CHANGES))
            PrintFormat("KBLX position modification failed (%u): %s",
                        modify_retcode, m_trade.ResultRetcodeDescription());
      }
   }
};

#endif
