#property strict

string KAYB_MemoryFile()
{
   return "KAYBAMBODLABFX_trade_memory.csv";
}



bool KAYB_ReadMemoryRow(const int handle,
                        string &c0,string &c1,string &c2,string &c3,string &c4,string &c5,string &c6)
{
   if(FileIsEnding(handle)) return false;
   c0 = FileReadString(handle); if(FileIsEnding(handle) && c0 == "") return false;
   if(FileIsEnding(handle)) return false; c1 = FileReadString(handle);
   if(FileIsEnding(handle)) return false; c2 = FileReadString(handle);
   if(FileIsEnding(handle)) return false; c3 = FileReadString(handle);
   if(FileIsEnding(handle)) return false; c4 = FileReadString(handle);
   if(FileIsEnding(handle)) return false; c5 = FileReadString(handle);
   if(FileIsEnding(handle)) return false; c6 = FileReadString(handle);
   return true;
}

int KAYB_PositionDirectionById(long positionId)
{
   if(!HistorySelect(0, TimeCurrent()))
      return 0;

   int total = HistoryDealsTotal();
   datetime bestTime = 0;
   int direction = 0;
   for(int i = 0; i < total; ++i)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0)
         continue;
      if((long)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) != positionId)
         continue;
      long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN)
         continue;
      datetime t = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
      if(t >= bestTime)
      {
         bestTime = t;
         long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
         direction = (dealType == DEAL_TYPE_BUY) ? 1 : -1;
      }
   }
   return direction;
}

void KAYB_ResetTradeMemoryIfNeeded()
{
   if(!InpTradeMemoryEnabled || !InpTradeMemoryResetOnInit)
      return;
   int h = FileOpen(KAYB_MemoryFile(), FILE_WRITE | FILE_CSV | FILE_COMMON);
   if(h != INVALID_HANDLE)
   {
      FileWrite(h, "close_time", "symbol", "magic", "setup", "filter", "profit", "direction");
      FileClose(h);
   }
}

void KAYB_EnsureMemoryFile()
{
   if(!InpTradeMemoryEnabled)
      return;
   int h = FileOpen(KAYB_MemoryFile(), FILE_READ | FILE_CSV | FILE_COMMON);
   if(h == INVALID_HANDLE)
   {
      h = FileOpen(KAYB_MemoryFile(), FILE_WRITE | FILE_CSV | FILE_COMMON);
      if(h != INVALID_HANDLE)
      {
         FileWrite(h, "close_time", "symbol", "magic", "setup", "filter", "profit", "direction");
         FileClose(h);
      }
      return;
   }
   FileClose(h);
   KAYB_PruneMemoryIfNeeded();
}


void KAYB_PruneMemoryIfNeeded()
{
   if(!InpTradeMemoryEnabled || InpTradeMemoryMaxRows <= 0)
      return;

   int h = FileOpen(KAYB_MemoryFile(), FILE_READ | FILE_CSV | FILE_COMMON);
   if(h == INVALID_HANDLE)
      return;

   string rows[];
   string c0,c1,c2,c3,c4,c5,c6;
   while(KAYB_ReadMemoryRow(h, c0,c1,c2,c3,c4,c5,c6))
   {
      string row = c0 + "," + c1 + "," + c2 + "," + c3 + "," + c4 + "," + c5 + "," + c6;
      int n = ArraySize(rows);
      ArrayResize(rows, n + 1);
      rows[n] = row;
   }
   FileClose(h);

   if(ArraySize(rows) <= InpTradeMemoryMaxRows + 1)
      return;

   int start = ArraySize(rows) - (InpTradeMemoryMaxRows + 1);
   if(start < 1)
      start = 1;

   int w = FileOpen(KAYB_MemoryFile(), FILE_WRITE | FILE_CSV | FILE_COMMON);
   if(w == INVALID_HANDLE)
      return;

   FileWrite(w, "close_time", "symbol", "magic", "setup", "filter", "profit", "direction");
   for(int i = start; i < ArraySize(rows); ++i)
   {
      string parts[];
      int pc = StringSplit(rows[i], ',', parts);
      if(pc >= 7)
         FileWrite(w, parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]);
   }
   FileClose(w);
}

void KAYB_AppendMemoryRecord(const KAYBTradeMemoryRecord &rec)
{
   if(!InpTradeMemoryEnabled)
      return;
   KAYB_EnsureMemoryFile();

   int h = FileOpen(KAYB_MemoryFile(), FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);
   if(h == INVALID_HANDLE)
      return;

   FileSeek(h, 0, SEEK_END);
   FileWrite(h,
             TimeToString(rec.closeTime, TIME_DATE | TIME_SECONDS),
             rec.symbol,
             rec.magic,
             rec.setupTag,
             rec.filterTag,
             DoubleToString(rec.profit, 2),
             rec.direction);
   FileClose(h);
   KAYB_PruneMemoryIfNeeded();
}

bool KAYB_GetMemoryScore(const string symbol, int magic, const string setupTag, const string filterTag, double &score, int &samples)
{
   score = 0.0;
   samples = 0;
   if(!InpTradeMemoryEnabled)
      return false;

   int h = FileOpen(KAYB_MemoryFile(), FILE_READ | FILE_CSV | FILE_COMMON);
   if(h == INVALID_HANDLE)
      return false;

   int row = 0;
   int wins = 0;
   string closeTime,rowSymbol,rowMagicStr,rowSetup,rowFilter,profitStr,dirStr;
   while(KAYB_ReadMemoryRow(h, closeTime,rowSymbol,rowMagicStr,rowSetup,rowFilter,profitStr,dirStr))
   {
      row++;
      if(row == 1)
         continue;

      int rowMagic = (int)StringToInteger(rowMagicStr);
      double profit = StringToDouble(profitStr);

      if(rowSymbol != symbol || rowMagic != magic)
         continue;
      if(rowSetup != setupTag)
         continue;
      if(filterTag != "" && rowFilter != filterTag)
         continue;

      samples++;
      if(profit > 0.0)
         wins++;
   }
   FileClose(h);

   if(samples == 0)
      return false;
   score = (double)wins / (double)samples;
   return true;
}

void KAYB_CaptureDealToMemory(const MqlTradeTransaction &trans)
{
   if(!InpTradeMemoryEnabled)
      return;
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;

   if(!HistoryDealSelect(trans.deal))
      return;

   long entryType = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_OUT_BY)
      return;

   if((int)HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != InpMagicNumber)
      return;

   KAYBTradeMemoryRecord rec;
   rec.closeTime = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);
   rec.symbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
   rec.magic = (int)HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   rec.profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) + HistoryDealGetDouble(trans.deal, DEAL_SWAP) + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   long positionId = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
   rec.direction = KAYB_PositionDirectionById(positionId);

   string comment = HistoryDealGetString(trans.deal, DEAL_COMMENT);
   rec.setupTag = comment;
   rec.filterTag = "";
   int sp = StringFind(comment, " ");
   if(sp > 0)
   {
      rec.setupTag = StringSubstr(comment, 0, sp);
      rec.filterTag = StringSubstr(comment, sp + 1);
   }

   KAYB_AppendMemoryRecord(rec);
}
