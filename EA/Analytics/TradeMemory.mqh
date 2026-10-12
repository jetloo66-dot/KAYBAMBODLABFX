#ifndef KBLX_TRADE_MEMORY_MQH
#define KBLX_TRADE_MEMORY_MQH

class CKBLXTradeMemory
{
private:
   string m_file_name;

public:
   CKBLXTradeMemory()
   {
      m_file_name = "KBLX_trade_memory.csv";
   }

   void RecordDeal(const ulong deal_ticket, const bool enabled, const long expected_magic)
   {
      if(!enabled || deal_ticket == 0 || !HistoryDealSelect(deal_ticket))
         return;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY &&
         entry != DEAL_ENTRY_INOUT)
         return;
      string symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
      long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(magic != expected_magic)
         return;
      ulong position_id = (ulong)HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong position_ticket = PositionGetTicket(i);
         if(position_ticket > 0 && PositionSelectByTicket(position_ticket) &&
            (ulong)PositionGetInteger(POSITION_IDENTIFIER) == position_id)
            return;
      }
      if(!HistorySelectByPosition(position_id))
         return;
      datetime time = 0;
      double volume = 0.0;
      double profit = 0.0;
      double commission = 0.0;
      double swap = 0.0;
      string comment = "";
      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong history_ticket = HistoryDealGetTicket(i);
         if(history_ticket == 0 ||
            (ulong)HistoryDealGetInteger(history_ticket, DEAL_POSITION_ID) != position_id ||
            HistoryDealGetInteger(history_ticket, DEAL_MAGIC) != expected_magic)
            continue;
         time = (datetime)MathMax((long)time,
                  HistoryDealGetInteger(history_ticket, DEAL_TIME));
         profit += HistoryDealGetDouble(history_ticket, DEAL_PROFIT);
         commission += HistoryDealGetDouble(history_ticket, DEAL_COMMISSION);
         swap += HistoryDealGetDouble(history_ticket, DEAL_SWAP);
         ENUM_DEAL_ENTRY history_entry =
            (ENUM_DEAL_ENTRY)HistoryDealGetInteger(history_ticket, DEAL_ENTRY);
         if(history_entry == DEAL_ENTRY_IN || history_entry == DEAL_ENTRY_INOUT)
         {
            volume = HistoryDealGetDouble(history_ticket, DEAL_VOLUME);
            comment = HistoryDealGetString(history_ticket, DEAL_COMMENT);
         }
      }
      int file = FileOpen(m_file_name, FILE_READ | FILE_WRITE | FILE_CSV |
                          FILE_SHARE_READ | FILE_SHARE_WRITE, ',');
      if(file == INVALID_HANDLE)
      {
         PrintFormat("KBLX trade memory could not open file (error %d)", GetLastError());
         return;
      }
      while(!FileIsEnding(file))
      {
         string saved_position = FileReadString(file);
         if(FileIsEnding(file) && saved_position == "")
            break;
         for(int field = 0; field < 8 && !FileIsEnding(file); field++)
            FileReadString(file);
         if((ulong)StringToInteger(saved_position) == position_id)
         {
            FileClose(file);
            return;
         }
      }
      FileSeek(file, 0, SEEK_END);
      FileWrite(file, position_id, time, symbol, magic, volume,
                profit, commission, swap, comment);
      FileClose(file);
   }

   bool AllowsSetup(const string symbol, const long magic, const char direction,
                    const int timeframe, const int minimum_sample,
                    const double minimum_win_rate)
   {
      int file = FileOpen(m_file_name, FILE_READ | FILE_CSV |
                          FILE_SHARE_READ | FILE_SHARE_WRITE, ',');
      if(file == INVALID_HANDLE)
         return false;
      int samples = 0;
      int wins = 0;
      string setup_prefix = StringFormat("KBLX%c%d", direction, timeframe);
      while(!FileIsEnding(file))
      {
         string ticket = FileReadString(file);
         if(FileIsEnding(file) && ticket == "")
            break;
         string time = FileReadString(file);
         string row_symbol = FileReadString(file);
         string row_magic = FileReadString(file);
         string volume = FileReadString(file);
         string profit = FileReadString(file);
         string commission = FileReadString(file);
         string swap = FileReadString(file);
         string comment = FileReadString(file);
         if(row_symbol != symbol || (long)StringToInteger(row_magic) != magic ||
            StringFind(comment, setup_prefix) != 0)
            continue;
         double net = StringToDouble(profit) + StringToDouble(commission) +
                      StringToDouble(swap);
         samples++;
         if(net > 0.0)
            wins++;
      }
      FileClose(file);
      if(samples < MathMax(1, minimum_sample))
         return false;
      return ((double)wins * 100.0 / samples >= minimum_win_rate);
   }
};

#endif
