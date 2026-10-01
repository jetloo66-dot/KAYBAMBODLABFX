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
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT)
         return;
      string symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
      long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
      if(magic != expected_magic)
         return;
      datetime time = (datetime)HistoryDealGetInteger(deal_ticket, DEAL_TIME);
      double volume = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
      double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
      double commission = HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
      double swap = HistoryDealGetDouble(deal_ticket, DEAL_SWAP);
      int file = FileOpen(m_file_name, FILE_READ | FILE_WRITE | FILE_CSV |
                          FILE_SHARE_READ | FILE_SHARE_WRITE, ',');
      if(file == INVALID_HANDLE)
      {
         PrintFormat("KBLX trade memory could not open file (error %d)", GetLastError());
         return;
      }
      FileSeek(file, 0, SEEK_END);
      FileWrite(file, deal_ticket, time, symbol, magic, volume,
                profit, commission, swap, HistoryDealGetString(deal_ticket, DEAL_COMMENT));
      FileClose(file);
   }

   bool AllowsSymbol(const string symbol, const long magic, const int minimum_sample,
                     const double minimum_win_rate)
   {
      int file = FileOpen(m_file_name, FILE_READ | FILE_CSV |
                          FILE_SHARE_READ | FILE_SHARE_WRITE, ',');
      if(file == INVALID_HANDLE)
         return false;
      int samples = 0;
      int wins = 0;
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
         if(row_symbol != symbol || (long)StringToInteger(row_magic) != magic)
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
