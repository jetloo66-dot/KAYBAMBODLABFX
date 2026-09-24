#property strict

#include <Trade/Trade.mqh>

double KAYB_CalcLotsFromRisk(const KAYBSetupSignal &sig)
{
   if(!InpUseRiskPercent)
      return KAYB_NormalizeVolume(_Symbol, InpLotSize);

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * (InpRiskPercent / 100.0);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0.0 || tickSize <= 0.0)
      return KAYB_NormalizeVolume(_Symbol, InpLotSize);

   double slDistance = MathAbs(sig.entry - sig.stop);
   if(slDistance <= 0.0)
      return KAYB_NormalizeVolume(_Symbol, InpLotSize);

   double valuePerPrice = tickValue / tickSize;
   double lots = riskMoney / (slDistance * valuePerPrice);
   return KAYB_NormalizeVolume(_Symbol, lots);
}

bool KAYB_CanPlaceTrade(const KAYBSetupSignal &sig, int magic, bool asPending, double execPrice, string &reason)
{
   reason = "";
   if(KAYB_OpenedPositionsByMagic(_Symbol, magic) >= InpMaxPositions)
   {
      reason = "max positions reached";
      return false;
   }
   if(KAYB_PendingOrdersByMagic(_Symbol, magic) >= InpMaxPendingOrders)
   {
      reason = "max pending orders reached";
      return false;
   }

   double spreadPoints = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(spreadPoints > InpMaxSpreadPoints)
   {
      reason = "spread too high";
      return false;
   }

   int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStop = stopLevel * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double basis = asPending ? sig.entry : execPrice;
   if(MathAbs(basis - sig.stop) < minStop || MathAbs(sig.tp - basis) < minStop)
   {
      reason = "stop level restriction";
      return false;
   }

   return true;
}

bool KAYB_PlaceSignal(CTrade &trade, const KAYBSetupSignal &sig, int magic)
{
   string reason;

   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(InpDeviationPoints);

   double lots = KAYB_CalcLotsFromRisk(sig);
   bool ok = false;

   if(InpEnablePendingOrders && InpUsePendingOrders)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      bool usePending = (sig.isBuy && sig.entry < ask) || (!sig.isBuy && sig.entry > bid);
      if(usePending)
      {
         if(!KAYB_CanPlaceTrade(sig, magic, true, sig.entry, reason))
         {
            Print("KAYB place blocked: ", reason);
            return false;
         }
         if(sig.isBuy)
            ok = trade.BuyLimit(lots, NormalizeDouble(sig.entry, _Digits), _Symbol, NormalizeDouble(sig.stop, _Digits), NormalizeDouble(sig.tp, _Digits), 0, sig.setupTag + " " + sig.filterTag);
         else
            ok = trade.SellLimit(lots, NormalizeDouble(sig.entry, _Digits), _Symbol, NormalizeDouble(sig.stop, _Digits), NormalizeDouble(sig.tp, _Digits), 0, sig.setupTag + " " + sig.filterTag);
      }
      else if(InpEnableMarketOrders)
      {
         double marketPrice = sig.isBuy ? ask : bid;
         if(!KAYB_CanPlaceTrade(sig, magic, false, marketPrice, reason))
         {
            Print("KAYB place blocked: ", reason);
            return false;
         }
         if(sig.isBuy)
            ok = trade.Buy(lots, _Symbol, 0.0, NormalizeDouble(sig.stop, _Digits), NormalizeDouble(sig.tp, _Digits), sig.setupTag + " " + sig.filterTag);
         else
            ok = trade.Sell(lots, _Symbol, 0.0, NormalizeDouble(sig.stop, _Digits), NormalizeDouble(sig.tp, _Digits), sig.setupTag + " " + sig.filterTag);
      }
   }
   else if(InpEnableMarketOrders)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double marketPrice = sig.isBuy ? ask : bid;
      if(!KAYB_CanPlaceTrade(sig, magic, false, marketPrice, reason))
      {
         Print("KAYB place blocked: ", reason);
         return false;
      }
      if(sig.isBuy)
         ok = trade.Buy(lots, _Symbol, 0.0, NormalizeDouble(sig.stop, _Digits), NormalizeDouble(sig.tp, _Digits), sig.setupTag + " " + sig.filterTag);
      else
         ok = trade.Sell(lots, _Symbol, 0.0, NormalizeDouble(sig.stop, _Digits), NormalizeDouble(sig.tp, _Digits), sig.setupTag + " " + sig.filterTag);
   }

   if(!ok)
   {
      Print("KAYB order failed retcode=", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      return false;
   }

   return true;
}

void KAYB_ManageOpenPositions(CTrade &trade, int magic)
{
   static ulong partialTickets[];
   static int partialStage[];
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != magic)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      bool isBuy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double current = isBuy ? bid : ask;
      double risk = MathAbs(open - sl);
      if(risk <= SymbolInfoDouble(_Symbol, SYMBOL_POINT))
         continue;

      double moveR = isBuy ? (current - open) / risk : (open - current) / risk;

      // Staged partial closes using TP1..TP5 settings
      double stageR[5] = { InpTP1_R, InpTP2_R, InpTP3_R, InpTP4_R, InpTP5_R };
      double stagePct[5] = { InpTP1_PartialPercent, InpTP2_PartialPercent, InpTP3_PartialPercent, InpTP4_PartialPercent, InpTP5_PartialPercent };
      bool stageEnabled[5] = { InpTP1Enabled, InpTP2Enabled, InpTP3Enabled, InpTP4Enabled, InpTP5Enabled };

      int idx = -1;
      for(int pd = 0; pd < ArraySize(partialTickets); ++pd)
      {
         if(partialTickets[pd] == ticket)
         {
            idx = pd;
            break;
         }
      }
      if(idx < 0)
      {
         idx = ArraySize(partialTickets);
         ArrayResize(partialTickets, idx + 1);
         ArrayResize(partialStage, idx + 1);
         partialTickets[idx] = ticket;
         partialStage[idx] = 0;
      }

      for(int stage = partialStage[idx]; stage < 5; ++stage)
      {
         if(!stageEnabled[stage])
         {
            partialStage[idx] = stage + 1;
            continue;
         }
         if(moveR < stageR[stage])
            break;

         double vol = PositionGetDouble(POSITION_VOLUME);
         double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
         double closeVol = KAYB_NormalizeVolume(_Symbol, vol * (stagePct[stage] / 100.0));
         double remainder = vol - closeVol;
         if(closeVol >= minLot && remainder >= minLot)
            trade.PositionClosePartial(ticket, closeVol);

         partialStage[idx] = stage + 1;
      }

      if(InpUseBreakEven && moveR >= InpBreakEvenTriggerR)
      {
         double be = open;
         if(isBuy && (sl < be || sl == 0.0))
            trade.PositionModify(ticket, NormalizeDouble(be, _Digits), tp);
         if(!isBuy && (sl > be || sl == 0.0))
            trade.PositionModify(ticket, NormalizeDouble(be, _Digits), tp);
      }

      if(InpUseTrailing && moveR >= InpTrailActivationR)
      {
         double distance = KAYB_UnitsToPrice(_Symbol, InpTrailDistanceUnits, InpDistanceMode);
         double step = KAYB_UnitsToPrice(_Symbol, InpTrailStepUnits, InpDistanceMode);
         if(isBuy)
         {
            double newSL = current - distance;
            if(newSL > sl + step)
               trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), tp);
         }
         else
         {
            double newSL = current + distance;
            if(newSL < sl - step || sl == 0.0)
               trade.PositionModify(ticket, NormalizeDouble(newSL, _Digits), tp);
         }
      }
   }
}
