#property strict

bool KAYB_IsForexStyleSymbol(const string symbol)
{
   string s = StringUpper(symbol);
   if(StringFind(s, "XAU") >= 0 || StringFind(s, "XAG") >= 0 || StringFind(s, "BTC") >= 0 || StringFind(s, "ETH") >= 0)
      return false;
   return true;
}

double KAYB_UnitSize(const string symbol, ENUM_KAYBDistanceMode mode)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(mode == KAYB_DIST_POINTS)
      return point;
   if(mode == KAYB_DIST_PIPS)
   {
      if(digits == 3 || digits == 5)
         return point * 10.0;
      return point;
   }

   // AUTO mode
   if(!KAYB_IsForexStyleSymbol(symbol))
      return point;

   if(digits == 3 || digits == 5)
      return point * 10.0;
   return point;
}

double KAYB_UnitsToPrice(const string symbol, double units, ENUM_KAYBDistanceMode mode)
{
   return units * KAYB_UnitSize(symbol, mode);
}

bool KAYB_IsLowerOrEqualTF(ENUM_TIMEFRAMES higher, ENUM_TIMEFRAMES lower)
{
   int h = PeriodSeconds(higher);
   int l = PeriodSeconds(lower);
   if(h <= 0 || l <= 0)
      return false;
   return l <= h;
}

string KAYB_TfToString(ENUM_TIMEFRAMES tf)
{
   return EnumToString(tf);
}

string KAYB_SideToString(bool isBuy)
{
   return isBuy ? "BUY" : "SELL";
}

double KAYB_NormalizeVolume(const string symbol, double lots)
{
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = 0.01;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   lots = MathFloor(lots / step) * step;
   return NormalizeDouble(lots, 2);
}

int KAYB_OpenedPositionsByMagic(const string symbol, int magic)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == symbol && (int)PositionGetInteger(POSITION_MAGIC) == magic)
         count++;
   }
   return count;
}

int KAYB_PendingOrdersByMagic(const string symbol, int magic)
{
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; --i)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(!OrderSelect(ticket))
         continue;
      if(OrderGetString(ORDER_SYMBOL) == symbol && (int)OrderGetInteger(ORDER_MAGIC) == magic)
         count++;
   }
   return count;
}
