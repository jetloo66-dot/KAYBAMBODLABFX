#ifndef KBLX_POSITION_MANAGER_MQH
#define KBLX_POSITION_MANAGER_MQH

#include <Trade\Trade.mqh>
#include "..\Risk\RiskManager.mqh"

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

   string InitialVolumeKey(const ulong ticket)
   {
      return StringFormat("KBLX_V_%I64u", ticket);
   }

   double InitialRiskFromHistory(const ulong identifier, const double open_price,
                                 const double current_sl)
   {
      ulong opening_order = 0;
      datetime earliest = 0;
      if(HistorySelectByPosition(identifier))
      {
         for(int i = 0; i < HistoryDealsTotal(); i++)
         {
            ulong deal = HistoryDealGetTicket(i);
            if(deal == 0 || HistoryDealGetInteger(deal, DEAL_MAGIC) != m_magic)
               continue;
            ENUM_DEAL_ENTRY entry =
               (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
            if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT)
               continue;
            datetime deal_time = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
            if(earliest == 0 || deal_time < earliest)
            {
               earliest = deal_time;
               opening_order = (ulong)HistoryDealGetInteger(deal, DEAL_ORDER);
            }
         }
      }
      if(opening_order > 0 && HistoryOrderSelect(opening_order))
      {
         double original_stop = HistoryOrderGetDouble(opening_order, ORDER_SL);
         if(original_stop > 0.0 && MathAbs(open_price - original_stop) > 0.0)
            return MathAbs(open_price - original_stop);
      }
      return (current_sl > 0.0 ? MathAbs(open_price - current_sl) : 0.0);
   }

   void CleanupOrphanedState()
   {
      for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
      {
         string name = GlobalVariableName(i);
         bool risk_key = StringFind(name, "KBLX_R_") == 0;
         bool partial_key = StringFind(name, "KBLX_P_") == 0;
         bool volume_key = StringFind(name, "KBLX_V_") == 0;
         if(!risk_key && !partial_key && !volume_key)
            continue;
         int separator = StringFind(name, "_", 7);
         if((risk_key || volume_key) && separator >= 0)
            continue;
         if(partial_key &&
            (separator < 8 || StringFind(name, "_", separator + 1) >= 0 ||
             StringToInteger(StringSubstr(name, separator + 1)) < 0 ||
             StringToInteger(StringSubstr(name, separator + 1)) > 4))
            continue;
         string ticket_text = (separator < 0
                               ? StringSubstr(name, 7)
                               : StringSubstr(name, 7, separator - 7));
         ulong ticket = (ulong)StringToInteger(ticket_text);
         if(ticket == 0 || !PositionSelectByTicket(ticket))
            GlobalVariableDel(name);
      }
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
               const double trailing_step_points, const KBLXDistanceUnitMode units,
               const KBLXTradePlan &plan, CKBLXRiskManager &risk_manager)
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
         if(!GlobalVariableCheck(risk_key))
         {
            ulong identifier = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
            double historical_risk = InitialRiskFromHistory(
               identifier, open_price, current_sl);
            if(historical_risk > 0.0)
               GlobalVariableSet(risk_key, historical_risk);
         }
         double initial_risk = (GlobalVariableCheck(risk_key)
                                ? GlobalVariableGet(risk_key) : 0.0);
         string initial_volume_key = InitialVolumeKey(ticket);
         if(!GlobalVariableCheck(initial_volume_key))
            GlobalVariableSet(initial_volume_key, PositionGetDouble(POSITION_VOLUME));
         double initial_volume = GlobalVariableGet(initial_volume_key);
         if(initial_risk > 0.0 && plan.count > 1)
         {
            double progress = (type == POSITION_TYPE_BUY
                               ? market - open_price : open_price - market);
            for(int stage = 0; stage < plan.count - 1; stage++)
            {
               string partial_key = PartialKey(ticket, stage);
               if(progress < initial_risk * plan.target_r[stage] ||
                  GlobalVariableCheck(partial_key) ||
                  plan.partial_percent[stage] <= 0.0)
                  continue;
               if(!PositionSelectByTicket(ticket))
                  break;
               double minimum = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
               double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
               double remaining = PositionGetDouble(POSITION_VOLUME);
               double close_volume = (step > 0.0
                                      ? MathFloor((initial_volume * plan.partial_percent[stage] / 100.0) / step) * step
                                      : 0.0);
               close_volume = NormalizeDouble(close_volume, 8);
               if(close_volume < minimum && remaining >= 2.0 * minimum)
                  close_volume = minimum;
               if(close_volume < minimum || remaining - close_volume < minimum)
               {
                  PrintFormat("KBLX partial target %d skipped for %s: volume %.8f cannot be split",
                              stage + 1, symbol, remaining);
                  GlobalVariableSet(partial_key, (double)TimeCurrent());
                  continue;
               }
               if(!PositionSelectByTicket(ticket) ||
                  PositionGetInteger(POSITION_MAGIC) != m_magic ||
                  PositionGetString(POSITION_SYMBOL) != symbol ||
                  (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != type ||
                  PositionGetDouble(POSITION_VOLUME) < close_volume + minimum)
                  break;
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
         double break_even_offset = risk_manager.DistancePrice(symbol, break_even_offset_points, units);
         double trailing_start = risk_manager.DistancePrice(symbol, trailing_start_points, units);
         double trailing_distance = risk_manager.DistancePrice(symbol, trailing_distance_points, units);
         double trailing_step = risk_manager.DistancePrice(symbol, trailing_step_points, units);
         if(break_even_offset < 0.0 || trailing_start < 0.0 ||
            trailing_distance < 0.0 || trailing_step < 0.0)
            continue;
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
                  (type == POSITION_TYPE_BUY ? 1.0 : -1.0) * break_even_offset;
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
                                    ? market - open_price
                                    : open_price - market);
            if(profit_points >= trailing_start)
            {
               double candidate = market +
                  (type == POSITION_TYPE_BUY ? -1.0 : 1.0) * trailing_distance;
               double step = MathMax(0.0, trailing_step);
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
      CleanupOrphanedState();
   }
};

#endif
