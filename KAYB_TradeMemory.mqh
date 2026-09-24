#property strict

string KAYB_MemoryFile()
{
   return "KAYBAMBODLABFX_trade_memory.csv";
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
   while(!FileIsEnding(h))
   {
      string closeTime = FileReadString(h);
      string rowSymbol = FileReadString(h);
      int rowMagic = (int)FileReadNumber(h);
      string rowSetup = FileReadString(h);
      string rowFilter = FileReadString(h);
      double profit = FileReadNumber(h);
      int dir = (int)FileReadNumber(h);
      row++;
      if(row == 1)
         continue;

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
   if(entryType != DEAL_ENTRY_OUT)
      return;

   if((int)HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != InpMagicNumber)
      return;

   KAYBTradeMemoryRecord rec;
   rec.closeTime = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);
   rec.symbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
   rec.magic = (int)HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   rec.profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT) + HistoryDealGetDouble(trans.deal, DEAL_SWAP) + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   rec.direction = (HistoryDealGetInteger(trans.deal, DEAL_TYPE) == DEAL_TYPE_BUY ? 1 : -1);

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
