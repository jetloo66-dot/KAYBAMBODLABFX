#ifndef KBLX_TRADE_MEMORY_MQH
#define KBLX_TRADE_MEMORY_MQH

struct KBLXMemoryRecord
{
   string position_id;
   string time;
   string symbol;
   string magic;
   string volume;
   string profit;
   string commission;
   string swap;
   string comment;
};

class CKBLXTradeMemory
{
private:
   string m_file_name;
   KBLXMemoryRecord m_records[];
   bool m_loaded;

   string SafeCsvField(string value)
   {
      StringReplace(value, ",", " ");
      StringReplace(value, "\r", " ");
      StringReplace(value, "\n", " ");
      return value;
   }

   bool ReadRecord(const int file, KBLXMemoryRecord &record)
   {
      if(FileIsEnding(file))
         return false;
      record.position_id = FileReadString(file);
      if(record.position_id == "" && FileIsEnding(file))
         return false;
      record.time = FileReadString(file);
      record.symbol = FileReadString(file);
      record.magic = FileReadString(file);
      record.volume = FileReadString(file);
      record.profit = FileReadString(file);
      record.commission = FileReadString(file);
      record.swap = FileReadString(file);
      record.comment = FileReadString(file);
      return true;
   }

   void LoadRecords()
   {
      if(m_loaded)
         return;
      int file = FileOpen(m_file_name, FILE_READ | FILE_CSV |
                          FILE_SHARE_READ | FILE_SHARE_WRITE, ',');
      if(file != INVALID_HANDLE)
      {
         KBLXMemoryRecord record;
         while(ReadRecord(file, record))
         {
            int size = ArraySize(m_records);
            if(ArrayResize(m_records, size + 1) != size + 1)
               break;
            m_records[size] = record;
         }
         FileClose(file);
      }
      m_loaded = true;
   }

   bool HasPositionRecord(const ulong position_id)
   {
      for(int i = 0; i < ArraySize(m_records); i++)
         if((ulong)StringToInteger(m_records[i].position_id) == position_id)
            return true;
      return false;
   }

public:
   CKBLXTradeMemory()
   {
      m_file_name = "KBLX_trade_memory.csv";
      m_loaded = false;
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
      LoadRecords();
      if(HasPositionRecord(position_id))
         return;
      symbol = SafeCsvField(symbol);
      comment = SafeCsvField(comment);
      int file = FileOpen(m_file_name, FILE_READ | FILE_WRITE | FILE_CSV |
                          FILE_SHARE_READ | FILE_SHARE_WRITE, ',');
      if(file == INVALID_HANDLE)
      {
         PrintFormat("KBLX trade memory could not open file (error %d)", GetLastError());
         return;
      }
      FileSeek(file, 0, SEEK_END);
      uint written = FileWrite(file, position_id, time, symbol, magic, volume,
                               profit, commission, swap, comment);
      FileClose(file);
      if(written == 0)
         return;
      KBLXMemoryRecord record;
      record.position_id = (string)position_id;
      record.time = (string)time;
      record.symbol = symbol;
      record.magic = (string)magic;
      record.volume = DoubleToString(volume, 8);
      record.profit = DoubleToString(profit, 8);
      record.commission = DoubleToString(commission, 8);
      record.swap = DoubleToString(swap, 8);
      record.comment = comment;
      int size = ArraySize(m_records);
      if(ArrayResize(m_records, size + 1) == size + 1)
         m_records[size] = record;
   }

   bool AllowsSetup(const string symbol, const long magic, const char direction,
                    const int timeframe, const int minimum_sample,
                    const double minimum_win_rate)
   {
      LoadRecords();
      int samples = 0;
      int wins = 0;
      string setup_prefix = StringFormat("KBLX%c_%d_", direction, timeframe);
      for(int i = 0; i < ArraySize(m_records); i++)
      {
         if(m_records[i].symbol != symbol ||
            (long)StringToInteger(m_records[i].magic) != magic ||
            StringFind(m_records[i].comment, setup_prefix) != 0)
            continue;
         double net = StringToDouble(m_records[i].profit) +
                      StringToDouble(m_records[i].commission) +
                      StringToDouble(m_records[i].swap);
         samples++;
         if(net > 0.0)
            wins++;
      }
      if(samples < MathMax(1, minimum_sample))
         return true;
      return ((double)wins * 100.0 / samples >= minimum_win_rate);
   }
};

#endif
