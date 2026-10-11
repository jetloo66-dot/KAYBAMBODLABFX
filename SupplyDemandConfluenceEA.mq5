//+------------------------------------------------------------------+
//|                                    SupplyDemandConfluenceEA.mq5  |
//|                         Supply & Demand Confluence Zone Trader   |
//|                         Copyright 2025, KAYBAMBODLABFX          |
//|                                         https://www.mql5.com    |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property description "Supply & Demand Confluence Zone EA — trades when higher-timeframe and"
#property description "lower-timeframe supply/demand zones align, with Telegram notifications."

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_SD_ZONE_TYPE {
   ZONE_SUPPLY, // Supply
   ZONE_DEMAND  // Demand
};

enum ENUM_ENTRY_STATE {
   STATE_IDLE,    // Idle
   STATE_FVG,     // FVG detected
   STATE_BOS,     // BOS confirmed
   STATE_SWEEP,   // Liquidity Sweep
   STATE_PINBAR   // Pin Bar confirmation
};

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+

// ── General Settings ─────────────────────────────────────────────
input string InpGeneralGroup        = "══════ General Settings ══════";
input int    InpMagicNumber         = 20250506;  // Magic number
input int    InpMaxTrades           = 3;         // Max concurrent trades
input bool   InpEnableDebug         = false;     // Enable debug logging

// ── Timeframe Settings ────────────────────────────────────────────
input string         InpTFGroup     = "══════ Timeframe Settings ══════";
input ENUM_TIMEFRAMES InpHTF        = PERIOD_H1; // Higher timeframe (zone detection)
input ENUM_TIMEFRAMES InpLTF        = PERIOD_M5; // Lower timeframe (entry confirmation)

// ── Supply & Demand Zone Settings ────────────────────────────────
input string InpSDGroup             = "══════ Supply & Demand Settings ══════";
input int    InpZoneLookback        = 100;       // Bars to look back for zones
input int    InpZoneMinWidth        = 5;         // Minimum zone width (points)
input int    InpZoneMaxAge          = 500;       // Max zone age (bars) before discarding
input double InpConfluenceThreshold = 0.0010;   // Max price gap for HTF/LTF confluence (price units)
input bool   InpAlertOnConf         = true;      // Alert on new confluence zone
input bool   InpAlertOnTrade        = true;      // Alert on trade execution

// ── Trade Parameters ──────────────────────────────────────────────
input string InpTradeGroup          = "══════ Trade Parameters ══════";
input double InpLotSize             = 0.01;      // Fixed lot size
input bool   InpUseAutoLot          = false;     // Use auto lot sizing
input double InpRiskPercent         = 1.0;       // Risk % per trade (auto lot)
input int    InpSLPoints            = 100;       // Stop loss (points)
input int    InpTPPoints            = 300;       // Take profit (points)
input bool   InpUseZoneSL           = true;      // Place SL at zone boundary
input int    InpSlippage            = 10;        // Slippage (points)

// ── Telegram Settings ─────────────────────────────────────────────
// NOTE: Add https://api.telegram.org to MT5 allowed WebRequest URLs:
//       Tools → Options → Expert Advisors → Allow WebRequest for listed URLs
input string InpTelegramGroup       = "══════ Telegram Settings ══════";
input bool   InpUseTelegram         = false;     // Enable Telegram alerts
input string InpTelegramBotToken    = "";        // Telegram Bot Token (from @BotFather)
input string InpTelegramChatID      = "";        // Telegram Chat ID (user, group, or channel)
input bool   InpTelegramOnConf      = true;      // Send alert on new confluence zone detected
input bool   InpTelegramOnTrade     = true;      // Send alert on trade executed (buy/sell)
input bool   InpTelegramOnSequence  = false;     // Send alert on each entry sequence step

//+------------------------------------------------------------------+
//| Supply/Demand Zone Structure                                     |
//+------------------------------------------------------------------+
struct SDZone {
   ENUM_SD_ZONE_TYPE type;      // SUPPLY or DEMAND
   double            priceTop;  // Upper boundary
   double            priceBot;  // Lower boundary
   datetime          time;      // Time zone was formed
   ENUM_TIMEFRAMES   tf;        // Timeframe the zone belongs to
   bool              active;    // Still valid (not mitigated)
};

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade g_trade;

static const int MAX_ZONES = 50;
SDZone g_htfZones[MAX_ZONES];
SDZone g_ltfZones[MAX_ZONES];
int    g_htfZoneCount = 0;
int    g_ltfZoneCount = 0;

ENUM_ENTRY_STATE g_entryState      = STATE_IDLE;
ENUM_SD_ZONE_TYPE g_entryDirection = ZONE_DEMAND; // Current setup direction
double            g_fvgTop         = 0;
double            g_fvgBot         = 0;
datetime          g_lastBarTime    = 0;

//+------------------------------------------------------------------+
//| URL-encode a string for use in HTTP POST body                   |
//| Encodes space as %20, and encodes <, >, &, #, %, \n, +          |
//+------------------------------------------------------------------+
string UrlEncode(string text)
{
   string result = text;
   // Encode percent-sign first to avoid double-encoding
   StringReplace(result, "%",  "%25");
   StringReplace(result, "&",  "%26");
   StringReplace(result, "#",  "%23");
   StringReplace(result, "+",  "%2B");
   StringReplace(result, "<",  "%3C");
   StringReplace(result, ">",  "%3E");
   StringReplace(result, "\n", "%0A");
   StringReplace(result, "\r", "%0D");
   // Encode space as %20 (not +) to avoid collision with the literal + → %2B encoding above
   StringReplace(result, " ",  "%20");
   return result;
}

//+------------------------------------------------------------------+
//| Send a Telegram message via Bot API (HTML parse mode)           |
//| Requires https://api.telegram.org to be whitelisted in MT5:     |
//|   Tools → Options → Expert Advisors → Allow WebRequest for      |
//|   listed URLs                                                    |
//+------------------------------------------------------------------+
void SendTelegramMessage(string message)
{
   if(!InpUseTelegram)
      return;
   if(InpTelegramBotToken == "" || InpTelegramChatID == "")
      return;

   string url = "https://api.telegram.org/bot" + InpTelegramBotToken + "/sendMessage";

   string encodedText = UrlEncode(message);
   string body = "chat_id=" + InpTelegramChatID +
                 "&text=" + encodedText +
                 "&parse_mode=HTML";

   char   post[];
   char   response[];
   string responseHeaders = "";
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";

   StringToCharArray(body, post, 0, StringLen(body));

   int httpCode = WebRequest("POST", url, headers, 5000, post, response, responseHeaders);

   if(httpCode != 200)
   {
      string responseBody = CharArrayToString(response);
      Print("SendTelegramMessage: unexpected HTTP response code ", httpCode,
            " (error ", GetLastError(), ") — response: ", responseBody);
   }
}

//+------------------------------------------------------------------+
//| Utility: count open positions for this EA                       |
//+------------------------------------------------------------------+
int CountOpenPositions(ENUM_POSITION_TYPE posType)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC)  == InpMagicNumber &&
            PositionGetInteger(POSITION_TYPE)   == posType)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Utility: calculate lot size based on risk                       |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPoints)
{
   if(!InpUseAutoLot || slPoints <= 0)
      return InpLotSize;

   double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double balance    = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskAmount = balance * InpRiskPercent / 100.0;

   double lotStep    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double lotMin     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double lotMax     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(tickValue <= 0 || tickSize <= 0)
      return InpLotSize;

   double lot = riskAmount / (slPoints * tickValue / tickSize);
   lot = MathFloor(lot / lotStep) * lotStep;
   lot = MathMax(lotMin, MathMin(lotMax, lot));
   return lot;
}

//+------------------------------------------------------------------+
//| Detect Supply/Demand zones on a given timeframe                 |
//| Zones are formed by base candles (small body) preceded/followed |
//| by strong impulse moves.                                         |
//+------------------------------------------------------------------+
void DetectZones(ENUM_TIMEFRAMES tf, SDZone &zones[], int &zoneCount)
{
   zoneCount = 0;
   MqlRates rates[];
   int bars = InpZoneLookback + 5;
   if(CopyRates(_Symbol, tf, 0, bars, rates) < bars)
      return;

   for(int i = 2; i < bars - 2 && zoneCount < MAX_ZONES; i++)
   {
      double bodySize    = MathAbs(rates[i].close - rates[i].open);
      double candleRange = rates[i].high - rates[i].low;
      if(candleRange <= 0) continue;

      double bodyRatio = bodySize / candleRange;
      // Base candle: small body (<=40% of range)
      if(bodyRatio > 0.40) continue;
      // Zone must be wide enough
      if(candleRange < InpZoneMinWidth * _Point) continue;

      // Check for impulse move after (demand) or before (supply)
      double impulseNext = MathAbs(rates[i-1].close - rates[i-1].open); // newer bar
      double impulsePrev = MathAbs(rates[i+1].close - rates[i+1].open); // older bar

      bool impulseUp   = (impulseNext > candleRange * 1.5) && (rates[i-1].close > rates[i-1].open);
      bool impulseDown = (impulseNext > candleRange * 1.5) && (rates[i-1].close < rates[i-1].open);
      bool originUp    = (impulsePrev > candleRange * 1.5) && (rates[i+1].close > rates[i+1].open);
      bool originDown  = (impulsePrev > candleRange * 1.5) && (rates[i+1].close < rates[i+1].open);

      ENUM_SD_ZONE_TYPE ztype;
      if(impulseUp || originDown)
         ztype = ZONE_DEMAND;
      else if(impulseDown || originUp)
         ztype = ZONE_SUPPLY;
      else
         continue;

      // Verify zone has not been mitigated (price did not fully close through it)
      double top = rates[i].high;
      double bot = rates[i].low;
      bool mitigated = false;
      for(int j = i - 1; j >= 0; j--)
      {
         if(ztype == ZONE_DEMAND && rates[j].close < bot) { mitigated = true; break; }
         if(ztype == ZONE_SUPPLY && rates[j].close > top) { mitigated = true; break; }
      }
      if(mitigated) continue;

      // Check zone age
      int age = i; // index from current bar (0 = newest)
      if(age > InpZoneMaxAge) continue;

      // Validate boundaries
      if(top <= bot) continue;

      zones[zoneCount].type     = ztype;
      zones[zoneCount].priceTop = top;
      zones[zoneCount].priceBot = bot;
      zones[zoneCount].time     = rates[i].time;
      zones[zoneCount].tf       = tf;
      zones[zoneCount].active   = true;
      zoneCount++;
   }
}

//+------------------------------------------------------------------+
//| Find confluence zones (HTF zone aligns with LTF zone)           |
//| Sends Telegram alert when InpAlertOnConf and InpTelegramOnConf  |
//+------------------------------------------------------------------+
bool FindConfluenceZones(ENUM_SD_ZONE_TYPE &outType, double &outTop, double &outBot)
{
   DetectZones(InpHTF, g_htfZones, g_htfZoneCount);
   DetectZones(InpLTF, g_ltfZones, g_ltfZoneCount);

   for(int h = 0; h < g_htfZoneCount; h++)
   {
      for(int l = 0; l < g_ltfZoneCount; l++)
      {
         if(g_htfZones[h].type != g_ltfZones[l].type)
            continue;

         // Check overlap within threshold.
         // gapOrOverlap > 0 means zones overlap; < 0 means there is a gap between them.
         // We allow up to InpConfluenceThreshold of gap to still consider zones confluent.
         double gapOrOverlap = MathMin(g_htfZones[h].priceTop, g_ltfZones[l].priceTop) -
                               MathMax(g_htfZones[h].priceBot, g_ltfZones[l].priceBot);
         if(gapOrOverlap < -InpConfluenceThreshold)
            continue;

         outType = g_htfZones[h].type;
         outTop  = MathMax(g_htfZones[h].priceTop, g_ltfZones[l].priceTop);
         outBot  = MathMin(g_htfZones[h].priceBot, g_ltfZones[l].priceBot);

         if(InpAlertOnConf)
         {
            string typeStr = (outType == ZONE_SUPPLY) ? "SUPPLY" : "DEMAND";
            string htfName = EnumToString(InpHTF);
            string ltfName = EnumToString(InpLTF);
            StringReplace(htfName, "PERIOD_", "");
            StringReplace(ltfName, "PERIOD_", "");

            string alertMsg = StringFormat(
               "SD Confluence EA | CONFLUENCE DETECTED | %s | %s | Zone: %.5f - %.5f | TFs: %s + %s | %s",
               _Symbol, typeStr, outBot, outTop, htfName, ltfName,
               TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
            Alert(alertMsg);

            if(InpTelegramOnConf)
            {
               string tgMsg = StringFormat(
                  "🔔 <b>SD Confluence EA</b>\n"
                  "📍 <b>CONFLUENCE DETECTED</b>\n"
                  "Symbol: %s\n"
                  "Type: %s\n"
                  "Zone: %.5f – %.5f\n"
                  "Timeframes: %s + %s\n"
                  "Time: %s",
                  _Symbol, typeStr, outBot, outTop, htfName, ltfName,
                  TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
               SendTelegramMessage(tgMsg);
            }
         }
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Execute a BUY trade                                              |
//| Sends Telegram alert when InpAlertOnTrade and InpTelegramOnTrade |
//+------------------------------------------------------------------+
bool ExecuteBuyTrade(double zoneTop, double zoneBot)
{
   if(CountOpenPositions(POSITION_TYPE_BUY) >= InpMaxTrades)
      return false;

   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double slPts = InpUseZoneSL ? (ask - zoneBot) / _Point : (double)InpSLPoints;
   double sl   = InpUseZoneSL ? zoneBot : ask - InpSLPoints * _Point;
   double tp   = ask + InpTPPoints * _Point;
   double lot  = CalculateLotSize(slPts);

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippage);

   bool ok = g_trade.Buy(lot, _Symbol, ask, sl, tp, "SD Confluence EA — BUY");
   if(!ok)
   {
      Print("ExecuteBuyTrade failed: ", g_trade.ResultRetcodeDescription());
      return false;
   }

   if(InpAlertOnTrade)
   {
      string alertMsg = StringFormat(
         "SD Confluence EA — BUY | %s | Lots: %.2f | Entry: %.5f | SL: %.5f | TP: %.5f | %s",
         _Symbol, lot, ask, sl, tp,
         TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
      Alert(alertMsg);

      if(InpTelegramOnTrade)
      {
         string tgMsg = StringFormat(
            "✅ <b>SD Confluence EA — BUY</b>\n"
            "Symbol: %s\n"
            "Lots: %.2f\n"
            "Entry: %.5f\n"
            "SL: %.5f\n"
            "TP: %.5f\n"
            "Time: %s",
            _Symbol, lot, ask, sl, tp,
            TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
         SendTelegramMessage(tgMsg);
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Execute a SELL trade                                             |
//| Sends Telegram alert when InpAlertOnTrade and InpTelegramOnTrade |
//+------------------------------------------------------------------+
bool ExecuteSellTrade(double zoneTop, double zoneBot)
{
   if(CountOpenPositions(POSITION_TYPE_SELL) >= InpMaxTrades)
      return false;

   double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double slPts = InpUseZoneSL ? (zoneTop - bid) / _Point : (double)InpSLPoints;
   double sl   = InpUseZoneSL ? zoneTop : bid + InpSLPoints * _Point;
   double tp   = bid - InpTPPoints * _Point;
   double lot  = CalculateLotSize(slPts);

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippage);

   bool ok = g_trade.Sell(lot, _Symbol, bid, sl, tp, "SD Confluence EA — SELL");
   if(!ok)
   {
      Print("ExecuteSellTrade failed: ", g_trade.ResultRetcodeDescription());
      return false;
   }

   if(InpAlertOnTrade)
   {
      string alertMsg = StringFormat(
         "SD Confluence EA — SELL | %s | Lots: %.2f | Entry: %.5f | SL: %.5f | TP: %.5f | %s",
         _Symbol, lot, bid, sl, tp,
         TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
      Alert(alertMsg);

      if(InpTelegramOnTrade)
      {
         string tgMsg = StringFormat(
            "❌ <b>SD Confluence EA — SELL</b>\n"
            "Symbol: %s\n"
            "Lots: %.2f\n"
            "Entry: %.5f\n"
            "SL: %.5f\n"
            "TP: %.5f\n"
            "Time: %s",
            _Symbol, lot, bid, sl, tp,
            TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
         SendTelegramMessage(tgMsg);
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Process entry sequence: FVG → BOS → Sweep → PinBar             |
//| Sends Telegram alert at each state transition when               |
//| InpTelegramOnSequence is true                                    |
//+------------------------------------------------------------------+
void ProcessEntrySequence(ENUM_SD_ZONE_TYPE confluenceType, double zoneTop, double zoneBot)
{
   MqlRates rates[];
   if(CopyRates(_Symbol, InpLTF, 0, 5, rates) < 5)
      return;

   string dirStr = (confluenceType == ZONE_DEMAND) ? "BUY" : "SELL";

   // ── Step 1: Detect FVG (Fair Value Gap) ─────────────────────────
   if(g_entryState == STATE_IDLE)
   {
      // FVG (bullish): gap between candle[2].high and candle[0].low
      // FVG (bearish): gap between candle[2].low  and candle[0].high
      bool fvgBull = (confluenceType == ZONE_DEMAND) &&
                     (rates[2].high < rates[0].low);
      bool fvgBear = (confluenceType == ZONE_SUPPLY) &&
                     (rates[2].low  > rates[0].high);

      if(fvgBull || fvgBear)
      {
         g_fvgTop = fvgBull ? rates[0].low  : rates[2].low;
         g_fvgBot = fvgBull ? rates[2].high : rates[0].high;
         g_entryState      = STATE_FVG;
         g_entryDirection  = confluenceType;

         if(InpEnableDebug)
            Print("ProcessEntrySequence: FVG detected, direction=", dirStr);

         if(InpTelegramOnSequence)
         {
            string tgMsg = StringFormat(
               "🔍 <b>SD Confluence EA</b>\n"
               "Step: FVG ✓ detected\n"
               "Direction: %s\n"
               "Symbol: %s\n"
               "Time: %s",
               dirStr, _Symbol,
               TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
            SendTelegramMessage(tgMsg);
         }
      }
      return;
   }

   // ── Step 2: Detect BOS (Break of Structure) ──────────────────────
   if(g_entryState == STATE_FVG)
   {
      bool bosBull = (confluenceType == ZONE_DEMAND) &&
                     (rates[0].close > rates[2].high);
      bool bosBear = (confluenceType == ZONE_SUPPLY) &&
                     (rates[0].close < rates[2].low);

      if(bosBull || bosBear)
      {
         g_entryState = STATE_BOS;

         if(InpEnableDebug)
            Print("ProcessEntrySequence: BOS confirmed, direction=", dirStr);

         if(InpTelegramOnSequence)
         {
            string tgMsg = StringFormat(
               "🔍 <b>SD Confluence EA</b>\n"
               "Step: BOS ✓ confirmed\n"
               "Direction: %s\n"
               "Symbol: %s\n"
               "Time: %s",
               dirStr, _Symbol,
               TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
            SendTelegramMessage(tgMsg);
         }
      }
      return;
   }

   // ── Step 3: Detect Liquidity Sweep ───────────────────────────────
   if(g_entryState == STATE_BOS)
   {
      // Sweep: price wicks below zone (demand) or above zone (supply) then closes back inside
      bool sweepDemand = (confluenceType == ZONE_DEMAND) &&
                         (rates[0].low  < zoneBot) &&
                         (rates[0].close > zoneBot);
      bool sweepSupply = (confluenceType == ZONE_SUPPLY) &&
                         (rates[0].high > zoneTop) &&
                         (rates[0].close < zoneTop);

      if(sweepDemand || sweepSupply)
      {
         g_entryState = STATE_SWEEP;

         if(InpEnableDebug)
            Print("ProcessEntrySequence: Sweep detected, direction=", dirStr);

         if(InpTelegramOnSequence)
         {
            string tgMsg = StringFormat(
               "🔍 <b>SD Confluence EA</b>\n"
               "Step: Sweep ✓ detected\n"
               "Direction: %s\n"
               "Symbol: %s\n"
               "Time: %s",
               dirStr, _Symbol,
               TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
            SendTelegramMessage(tgMsg);
         }
      }
      return;
   }

   // ── Step 4: Detect PinBar confirmation ───────────────────────────
   if(g_entryState == STATE_SWEEP)
   {
      double bodySize  = MathAbs(rates[0].close - rates[0].open);
      double totalRange = rates[0].high - rates[0].low;
      if(totalRange <= 0) return;

      double upperWick = rates[0].high - MathMax(rates[0].open, rates[0].close);
      double lowerWick = MathMin(rates[0].open, rates[0].close) - rates[0].low;

      // Bullish pinbar: long lower wick, small body near top
      bool pinBull = (confluenceType == ZONE_DEMAND) &&
                     (lowerWick >= totalRange * 0.60) &&
                     (bodySize  <= totalRange * 0.30);
      // Bearish pinbar: long upper wick, small body near bottom
      bool pinBear = (confluenceType == ZONE_SUPPLY) &&
                     (upperWick >= totalRange * 0.60) &&
                     (bodySize  <= totalRange * 0.30);

      if(pinBull || pinBear)
      {
         g_entryState = STATE_PINBAR;

         if(InpEnableDebug)
            Print("ProcessEntrySequence: PinBar confirmed, direction=", dirStr);

         if(InpTelegramOnSequence)
         {
            string tgMsg = StringFormat(
               "🔍 <b>SD Confluence EA</b>\n"
               "Step: PinBar ✓ confirmed\n"
               "Direction: %s\n"
               "Symbol: %s\n"
               "Time: %s",
               dirStr, _Symbol,
               TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
            SendTelegramMessage(tgMsg);
         }

         // All steps complete → execute trade
         if(confluenceType == ZONE_DEMAND)
            ExecuteBuyTrade(zoneTop, zoneBot);
         else
            ExecuteSellTrade(zoneTop, zoneBot);

         // Reset state machine
         g_entryState = STATE_IDLE;
         g_fvgTop = g_fvgBot = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetMarginMode();
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetDeviationInPoints(InpSlippage);

   // ── Telegram validation ─────────────────────────────────────────
   if(InpUseTelegram)
   {
      // Remind the user to whitelist the Telegram API URL
      Print("SupplyDemandConfluenceEA: Telegram alerts enabled. "
            "Ensure https://api.telegram.org is whitelisted in "
            "Tools → Options → Expert Advisors → Allow WebRequest for listed URLs.");

      if(InpTelegramBotToken == "")
         Print("SupplyDemandConfluenceEA WARNING: InpUseTelegram is true but "
               "InpTelegramBotToken is empty — Telegram alerts will not be sent.");

      if(InpTelegramChatID == "")
         Print("SupplyDemandConfluenceEA WARNING: InpUseTelegram is true but "
               "InpTelegramChatID is empty — Telegram alerts will not be sent.");
   }

   Print("SupplyDemandConfluenceEA initialized on ", _Symbol,
         " | HTF: ", EnumToString(InpHTF),
         " | LTF: ", EnumToString(InpLTF));

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("SupplyDemandConfluenceEA deinitialized, reason: ", reason);
}

//+------------------------------------------------------------------+
//| OnTick — main logic                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Run logic only on new bar of the lower timeframe
   datetime currentBarTime = iTime(_Symbol, InpLTF, 0);
   if(currentBarTime == g_lastBarTime)
      return;
   g_lastBarTime = currentBarTime;

   // Scan for confluence zones
   ENUM_SD_ZONE_TYPE confType;
   double confTop = 0, confBot = 0;

   bool confluenceFound = FindConfluenceZones(confType, confTop, confBot);

   if(!confluenceFound)
      return;

   // If we already have an active sequence for the same direction,
   // continue processing it; otherwise start fresh.
   if(g_entryState != STATE_IDLE && g_entryDirection != confType)
   {
      // Direction changed — reset
      g_entryState = STATE_IDLE;
      g_fvgTop = g_fvgBot = 0;
   }

   ProcessEntrySequence(confType, confTop, confBot);
}
//+------------------------------------------------------------------+
