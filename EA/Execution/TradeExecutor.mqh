#ifndef KBLX_TRADE_EXECUTOR_MQH
#define KBLX_TRADE_EXECUTOR_MQH

#include <Trade\Trade.mqh>
#include "..\Risk\RiskManager.mqh"

class CKBLXTradeExecutor
{
private:
   CTrade m_trade;
   long m_magic;
   int m_max_positions_total;
   int m_max_positions_symbol;
   int m_max_pending;

   uint HashText(const string text)
   {
      uint hash = 2166136261;
      for(int i = 0; i < StringLen(text); i++)
         hash = (hash ^ (uint)StringGetCharacter(text, i)) * 16777619;
      return hash;
   }

   string SetupKey(const string id)
   {
      return StringFormat("KBLX_%I64d_%u", m_magic, HashText(id));
   }

   bool OrderTime(const string symbol, const datetime requested_expiry,
                  ENUM_ORDER_TYPE_TIME &time_type, datetime &expiry)
   {
      long modes = 0;
      if(!SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_MODE, modes))
         return false;
      if((modes & SYMBOL_EXPIRATION_SPECIFIED) != 0 &&
         requested_expiry > TimeTradeServer())
      {
         time_type = ORDER_TIME_SPECIFIED;
         expiry = requested_expiry;
         return true;
      }
      expiry = 0;
      if((modes & SYMBOL_EXPIRATION_GTC) != 0)
      {
         time_type = ORDER_TIME_GTC;
         return true;
      }
      if((modes & SYMBOL_EXPIRATION_DAY) != 0)
      {
         time_type = ORDER_TIME_DAY;
         return true;
      }
      return false;
   }

   int CountOwned(const string symbol, const bool pending_only)
   {
      int count = 0;
      if(!pending_only)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0 || !PositionSelectByTicket(ticket))
               continue;
            if(PositionGetInteger(POSITION_MAGIC) == m_magic &&
               (symbol == "" || PositionGetString(POSITION_SYMBOL) == symbol))
               count++;
         }
      }
      if(pending_only)
      {
         for(int i = OrdersTotal() - 1; i >= 0; i--)
         {
            ulong ticket = OrderGetTicket(i);
            if(ticket == 0)
               continue;
            if(OrderGetInteger(ORDER_MAGIC) == m_magic &&
               (symbol == "" || OrderGetString(ORDER_SYMBOL) == symbol))
               count++;
         }
      }
      return count;
   }

public:
   CKBLXTradeExecutor()
   {
      m_magic = 316316316;
      m_max_positions_total = 3;
      m_max_positions_symbol = 3;
      m_max_pending = 3;
   }

   void Configure(const long magic, const int max_positions_total,
                  const int max_positions_symbol, const int max_pending,
                  const ulong deviation)
   {
      m_magic = magic;
      m_max_positions_total = max_positions_total;
      m_max_positions_symbol = max_positions_symbol;
      m_max_pending = max_pending;
      m_trade.SetExpertMagicNumber(m_magic);
      m_trade.SetDeviationInPoints(deviation);
   }

   bool HasDuplicate(const string signal_id)
   {
      string key = SetupKey(signal_id);
      return GlobalVariableCheck(key);
   }

   bool Execute(const KBLXSignal &signal, CKBLXMarketData &data,
                CKBLXRiskManager &risk_manager, const KBLXSizingMode sizing_mode,
                const double fixed_lots, const double risk_percent, const double risk_money,
                const KBLXStopMode stop_mode, const double stop_points,
                const double stop_buffer_points, const double risk_reward,
                const double manual_stop, const int atr_period,
                const double atr_multiplier, const KBLXTakeProfitMode tp_mode,
                const double manual_target, const double fib_extension_ratio,
                const KBLXExecutionMode execution_mode,
                const bool prevent_duplicates, double &stop_result,
                double &target_result, double &volume_result)
   {
      stop_result = 0.0;
      target_result = 0.0;
      volume_result = 0.0;
      if(!signal.valid || (prevent_duplicates && HasDuplicate(signal.id)))
         return false;
      if(CountOwned("", false) >= m_max_positions_total ||
         CountOwned(signal.symbol, false) >= m_max_positions_symbol)
         return false;

      MqlTick tick;
      if(!SymbolInfoTick(signal.symbol, tick))
         return false;
      m_trade.SetTypeFillingBySymbol(signal.symbol);

      string comment = StringSubstr(signal.id, 0, 31);
      bool use_pending = (execution_mode == KBLX_PENDING_ONLY);
      if(execution_mode == KBLX_AUTO_EXECUTION && signal.entry > 0.0)
         use_pending = (signal.direction == KBLX_DIRECTION_BUY
                        ? signal.entry < tick.ask : signal.entry > tick.bid);
      if(use_pending && CountOwned(signal.symbol, true) >= m_max_pending)
         return false;
      if(execution_mode == KBLX_MARKET_AND_PENDING)
      {
         KBLXSignal market_signal = signal;
         market_signal.entry = (signal.direction == KBLX_DIRECTION_BUY ? tick.ask : tick.bid);
         double market_stop = 0.0, market_target = 0.0;
         if(!risk_manager.BuildStops(data, market_signal, stop_mode, stop_points,
                                     stop_buffer_points, risk_reward, manual_stop,
                                     atr_period, atr_multiplier, tp_mode,
                                     manual_target, fib_extension_ratio,
                                     market_stop, market_target))
            return false;
         double market_volume = risk_manager.CalculateVolume(
            signal.symbol, signal.direction, market_signal.entry, market_stop,
            sizing_mode, fixed_lots, risk_percent, risk_money);
         if(market_volume <= 0.0)
            return false;

         double pending_price = data.NormalizePrice(signal.symbol, signal.entry);
         datetime pending_expiry = 0;
         ENUM_ORDER_TYPE_TIME pending_time;
         bool pending_time_valid = OrderTime(signal.symbol, signal.zone.expires,
                                             pending_time, pending_expiry);
         KBLXSignal pending_signal = signal;
         pending_signal.entry = pending_price;
         double pending_stop = 0.0, pending_target = 0.0;
         double pending_volume = 0.0;
         bool pending_valid = (pending_time_valid &&
            CountOwned(signal.symbol, true) < m_max_pending) &&
            risk_manager.BuildStops(
            data, pending_signal, stop_mode, stop_points, stop_buffer_points,
            risk_reward, manual_stop, atr_period, atr_multiplier, tp_mode,
            manual_target, fib_extension_ratio, pending_stop, pending_target, true);
         if(pending_valid)
         {
            pending_volume = risk_manager.CalculateVolume(
               signal.symbol, signal.direction, pending_price, pending_stop,
               sizing_mode, fixed_lots, risk_percent, risk_money);
            pending_volume = risk_manager.NormalizeVolume(signal.symbol, pending_volume * 0.5);
         }
         double split_market_volume = risk_manager.NormalizeVolume(signal.symbol, market_volume * 0.5);
         bool split = (pending_valid && pending_volume > 0.0 && split_market_volume > 0.0);
         double final_market_volume = (split ? split_market_volume : market_volume);
         bool market_sent = (signal.direction == KBLX_DIRECTION_BUY
                             ? m_trade.Buy(final_market_volume, signal.symbol, 0.0,
                                           market_stop, market_target, comment)
                             : m_trade.Sell(final_market_volume, signal.symbol, 0.0,
                                            market_stop, market_target, comment));
         uint market_retcode = m_trade.ResultRetcode();
         bool market_accepted = market_sent &&
            (market_retcode == TRADE_RETCODE_DONE ||
             market_retcode == TRADE_RETCODE_DONE_PARTIAL);
         bool pending_accepted = false;
         uint pending_retcode = 0;
         if(split)
         {
            bool pending_sent = false;
            if(signal.direction == KBLX_DIRECTION_BUY && pending_price < tick.ask)
               pending_sent = m_trade.BuyLimit(pending_volume, pending_price, signal.symbol,
                                               pending_stop, pending_target,
                                               pending_time, pending_expiry, comment);
            else if(signal.direction == KBLX_DIRECTION_SELL && pending_price > tick.bid)
               pending_sent = m_trade.SellLimit(pending_volume, pending_price, signal.symbol,
                                                pending_stop, pending_target,
                                                pending_time, pending_expiry, comment);
            pending_retcode = m_trade.ResultRetcode();
            pending_accepted = pending_sent &&
               (pending_retcode == TRADE_RETCODE_PLACED ||
                pending_retcode == TRADE_RETCODE_DONE ||
                pending_retcode == TRADE_RETCODE_DONE_PARTIAL);
         }
         bool accepted_both_mode = market_accepted || pending_accepted;
         stop_result = market_stop;
         target_result = market_target;
         volume_result = final_market_volume;
         if(accepted_both_mode)
            GlobalVariableSet(SetupKey(signal.id), (double)TimeCurrent());
         else
            PrintFormat("KBLX market/pending orders rejected (%u/%u)",
                        market_retcode, pending_retcode);
         return accepted_both_mode;
      }

      KBLXSignal execution_signal = signal;
      execution_signal.entry = (use_pending
                                ? data.NormalizePrice(signal.symbol, signal.entry)
                                : signal.direction == KBLX_DIRECTION_BUY ? tick.ask : tick.bid);
      double stop = 0.0, target = 0.0;
      if(!risk_manager.BuildStops(data, execution_signal, stop_mode, stop_points,
                                  stop_buffer_points, risk_reward, manual_stop,
                                  atr_period, atr_multiplier, tp_mode,
                                  manual_target, fib_extension_ratio,
                                  stop, target, use_pending))
         return false;
      double volume = risk_manager.CalculateVolume(signal.symbol, signal.direction,
                                                   execution_signal.entry, stop,
                                                   sizing_mode, fixed_lots,
                                                   risk_percent, risk_money);
      if(volume <= 0.0)
         return false;
      stop_result = stop;
      target_result = target;
      volume_result = volume;
      bool sent = false;
      double pending_price = execution_signal.entry;
      if(use_pending)
      {
         datetime pending_expiry = 0;
         ENUM_ORDER_TYPE_TIME pending_time;
         if(!OrderTime(signal.symbol, signal.zone.expires, pending_time, pending_expiry))
            return false;
         if(signal.direction == KBLX_DIRECTION_BUY && pending_price < tick.ask)
            sent = m_trade.BuyLimit(volume, pending_price, signal.symbol, stop, target,
                                    pending_time, pending_expiry, comment);
         else if(signal.direction == KBLX_DIRECTION_SELL && pending_price > tick.bid)
            sent = m_trade.SellLimit(volume, pending_price, signal.symbol, stop, target,
                                     pending_time, pending_expiry, comment);
      }
      else if(signal.direction == KBLX_DIRECTION_BUY)
         sent = m_trade.Buy(volume, signal.symbol, 0.0, stop, target, comment);
      else
         sent = m_trade.Sell(volume, signal.symbol, 0.0, stop, target, comment);
      uint retcode = m_trade.ResultRetcode();
      bool accepted = sent && (retcode == TRADE_RETCODE_DONE ||
                               retcode == TRADE_RETCODE_PLACED ||
                               retcode == TRADE_RETCODE_DONE_PARTIAL);
      if(accepted)
         GlobalVariableSet(SetupKey(signal.id), (double)TimeCurrent());
      else
         PrintFormat("KBLX order rejected (%u): %s", retcode, m_trade.ResultRetcodeDescription());
      return accepted;
   }

};

#endif
