#property strict

string KAYB_MemoryFile()
{
   return "KAYBAMBODLABFX_trade_memory.csv";
}

bool KAYB_ReadMemoryRow(const int handle,
                        string &c0, string &c1, string &c2, string &c3, string &c4, string &c5, string &c6)
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

void KAYB_PruneMemoryIfNeeded()
{
   if(!InpTradeMemoryEnabled || InpTradeMemoryMaxRows <= 0)
      return;

   int h = FileOpen(KAYB_MemoryFile(), FILE_READ | FILE_CSV | FILE_COMMON);
   if(h == INVALID_HANDLE)
      return;

   string c0s[], c1s[], c2s[], c3s[], c4s[], c5s[], c6s[];
   string c0, c1, c2, c3, c4, c5, c6;
   while(KAYB_ReadMemoryRow(h, c0, c1, c2, c3, c4, c5, c6))
   {
      int n = ArraySize(c0s);
      ArrayResize(c0s, n + 1); ArrayResize(c1s, n + 1); ArrayResize(c2s, n + 1);
      ArrayResize(c3s, n + 1); ArrayResize(c4s, n + 1); ArrayResize(c5s, n + 1); ArrayResize(c6s, n + 1);
      c0s[n] = c0; c1s[n] = c1; c2s[n] = c2; c3s[n] = c3; c4s[n] = c4; c5s[n] = c5; c6s[n] = c6;
   }
   FileClose(h);

   int totalRows = ArraySize(c0s);
   if(totalRows <= InpTradeMemoryMaxRows + 1)
      return;

   int startRow = totalRows - (InpTradeMemoryMaxRows + 1);
   if(startRow < 1)
      startRow = 1;

   int w = FileOpen(KAYB_MemoryFile(), FILE_WRITE | FILE_CSV | FILE_COMMON);
   if(w == INVALID_HANDLE)
      return;

   FileWrite(w, "close_time", "symbol", "magic", "setup", "filter", "profit", "direction");
   for(int i = startRow; i < totalRows; ++i)
      FileWrite(w, c0s[i], c1s[i], c2s[i], c3s[i], c4s[i], c5s[i], c6s[i]);
   FileClose(w);
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

int KAYB_PositionDirectionById(long positionId)
{
   if(!HistorySelect(TimeCurrent() - 31536000, TimeCurrent()))
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

double KAYB_PositionAggregateProfit(long positionId)
{
   if(!HistorySelect(TimeCurrent() - 31536000, TimeCurrent()))
      return 0.0;

   double totalProfit = 0.0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; ++i)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0)
         continue;
      if((long)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) != positionId)
         continue;

      long entry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      totalProfit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT)
                  +  HistoryDealGetDouble(dealTicket, DEAL_SWAP)
                  +  HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
   }
   return totalProfit;
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
   string closeTime, rowSymbol, rowMagicStr, rowSetup, rowFilter, profitStr, dirStr;
   while(KAYB_ReadMemoryRow(h, closeTime, rowSymbol, rowMagicStr, rowSetup, rowFilter, profitStr, dirStr))
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

   long positionId = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
   if(PositionSelectByTicket((ulong)positionId))
      return; // still open, likely partial close

   KAYBTradeMemoryRecord rec;
   rec.closeTime = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);
   rec.symbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
   rec.magic = (int)HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   rec.profit = KAYB_PositionAggregateProfit(positionId);
   int dir = KAYB_PositionDirectionById(positionId);
   rec.direction = dir > 0 ? "BUY" : (dir < 0 ? "SELL" : "UNKNOWN");

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
