//+------------------------------------------------------------------+
//|                                             VisualIndicators.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Visual Indicators Class                                          |
//+------------------------------------------------------------------+
class CVisualIndicators {
private:
    string m_prefix;
    color m_supportColor;
    color m_resistanceColor;
    color m_buyZoneColor;
    color m_sellZoneColor;
    color m_trendLineColor;
    color m_entryColor;
    color m_exitColor;
    
public:
    CVisualIndicators(string prefix = "KAYB_");
    ~CVisualIndicators();
    
    // Configuration methods
    void SetColors(color support, color resistance, color buyZone, color sellZone);
    void SetTrendColors(color trendLine, color entry, color exit);
    
    // Level visualization methods
    void DrawSupportResistance(double supportLevels[], double resistanceLevels[], int count);
    void DrawSwingLevels(double swingHighs[], double swingLows[], int count);
    void DrawTrendStructure(double higherHighs[], double higherLows[], double lowerHighs[], double lowerLows[], int count);
    
    // Zone visualization methods
    void DrawBuyZones(double levels[], double proximity, int count);
    void DrawSellZones(double levels[], double proximity, int count);
    void DrawTradingZone(string name, double price1, double price2, color zoneColor, bool isBuyZone = true);
    
    // Pattern visualization methods
    void DrawPatternMarker(string patternName, int candleIndex, double price, color markerColor);
    void DrawEntrySignal(double price, bool isBuy, string reason = "");
    void DrawExitSignal(double price, bool wasProfit, string reason = "");
    
    // Fibonacci and trend visualization
    void DrawFibonacciRetracement(double highPrice, double lowPrice, datetime startTime, datetime endTime);
    void DrawTrendLine(string name, double price1, double price2, datetime time1, datetime time2, color lineColor);
    void DrawHorizontalLevel(string name, double price, color levelColor, int style = STYLE_SOLID, int width = 1);
    
    // Trade visualization methods
    void DrawTradeInfo(string symbol, double entryPrice, double stopLoss, double takeProfit, bool isBuy);
    void UpdateTradeStatus(string symbol, double currentPrice, double profit);
    
    // Information panels
    void DrawInfoPanel(string title, string info[], int count, int x = 10, int y = 50);
    void DrawTrendIndicator(int trend, int x = 10, int y = 10); // 1=Up, -1=Down, 0=Sideways
    void DrawVolatilityMeter(double atr, double avgAtr, int x = 10, int y = 80);
    
    // Cleanup methods
    void ClearAll();
    void ClearLevels();
    void ClearZones();
    void ClearPatterns();
    void ClearObjects(string namePattern);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CVisualIndicators::CVisualIndicators(string prefix = "KAYB_") {
    m_prefix = prefix;
    m_supportColor = clrBlue;
    m_resistanceColor = clrRed;
    m_buyZoneColor = clrLimeGreen;
    m_sellZoneColor = clrOrange;
    m_trendLineColor = clrYellow;
    m_entryColor = clrGreen;
    m_exitColor = clrMagenta;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CVisualIndicators::~CVisualIndicators(void) {
    ClearAll();
}

//+------------------------------------------------------------------+
//| Set color scheme                                                 |
//+------------------------------------------------------------------+
void CVisualIndicators::SetColors(color support, color resistance, color buyZone, color sellZone) {
    m_supportColor = support;
    m_resistanceColor = resistance;
    m_buyZoneColor = buyZone;
    m_sellZoneColor = sellZone;
}

//+------------------------------------------------------------------+
//| Set trend and signal colors                                      |
//+------------------------------------------------------------------+
void CVisualIndicators::SetTrendColors(color trendLine, color entry, color exit) {
    m_trendLineColor = trendLine;
    m_entryColor = entry;
    m_exitColor = exit;
}

//+------------------------------------------------------------------+
//| Draw support and resistance levels                               |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawSupportResistance(double supportLevels[], double resistanceLevels[], int count) {
    // Clear old levels first
    ClearLevels();
    
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 100;
    
    // Draw support levels
    for(int i = 0; i < count && i < ArraySize(supportLevels); i++) {
        if(supportLevels[i] > 0) {
            string objName = m_prefix + "Support_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, supportLevels[i], futureTime, supportLevels[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, m_supportColor);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "S[" + IntegerToString(i) + "] " + DoubleToString(supportLevels[i], _Digits));
        }
    }
    
    // Draw resistance levels
    for(int i = 0; i < count && i < ArraySize(resistanceLevels); i++) {
        if(resistanceLevels[i] > 0) {
            string objName = m_prefix + "Resistance_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, resistanceLevels[i], futureTime, resistanceLevels[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, m_resistanceColor);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "R[" + IntegerToString(i) + "] " + DoubleToString(resistanceLevels[i], _Digits));
        }
    }
}

//+------------------------------------------------------------------+
//| Draw swing levels                                                |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawSwingLevels(double swingHighs[], double swingLows[], int count) {
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 100;
    
    // Draw swing highs
    for(int i = 0; i < count && i < ArraySize(swingHighs); i++) {
        if(swingHighs[i] > 0) {
            string objName = m_prefix + "SwingHigh_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, swingHighs[i], futureTime, swingHighs[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrOrange);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "SH[" + IntegerToString(i) + "]");
        }
    }
    
    // Draw swing lows
    for(int i = 0; i < count && i < ArraySize(swingLows); i++) {
        if(swingLows[i] > 0) {
            string objName = m_prefix + "SwingLow_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, swingLows[i], futureTime, swingLows[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrCyan);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
            ObjectSetString(0, objName, OBJPROP_TEXT, "SL[" + IntegerToString(i) + "]");
        }
    }
}

//+------------------------------------------------------------------+
//| Draw trend structure levels                                      |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawTrendStructure(double higherHighs[], double higherLows[], double lowerHighs[], double lowerLows[], int count) {
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 50;
    
    // Draw Higher Highs
    for(int i = 0; i < count && i < ArraySize(higherHighs); i++) {
        if(higherHighs[i] > 0) {
            string objName = m_prefix + "HH_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, higherHighs[i], futureTime, higherHighs[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrLime);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetString(0, objName, OBJPROP_TEXT, "HH[" + IntegerToString(i) + "]");
        }
    }
    
    // Draw Higher Lows
    for(int i = 0; i < count && i < ArraySize(higherLows); i++) {
        if(higherLows[i] > 0) {
            string objName = m_prefix + "HL_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, higherLows[i], futureTime, higherLows[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGreen);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetString(0, objName, OBJPROP_TEXT, "HL[" + IntegerToString(i) + "]");
        }
    }
    
    // Draw Lower Highs
    for(int i = 0; i < count && i < ArraySize(lowerHighs); i++) {
        if(lowerHighs[i] > 0) {
            string objName = m_prefix + "LH_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, lowerHighs[i], futureTime, lowerHighs[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrRed);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetString(0, objName, OBJPROP_TEXT, "LH[" + IntegerToString(i) + "]");
        }
    }
    
    // Draw Lower Lows
    for(int i = 0; i < count && i < ArraySize(lowerLows); i++) {
        if(lowerLows[i] > 0) {
            string objName = m_prefix + "LL_" + IntegerToString(i);
            ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, lowerLows[i], futureTime, lowerLows[i]);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrMaroon);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
            ObjectSetString(0, objName, OBJPROP_TEXT, "LL[" + IntegerToString(i) + "]");
        }
    }
}

//+------------------------------------------------------------------+
//| Draw buy zones                                                   |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawBuyZones(double levels[], double proximity, int count) {
    for(int i = 0; i < count && i < ArraySize(levels); i++) {
        if(levels[i] > 0) {
            string zoneName = m_prefix + "BuyZone_" + IntegerToString(i);
            DrawTradingZone(zoneName, levels[i] - proximity, levels[i] + proximity, m_buyZoneColor, true);
        }
    }
}

//+------------------------------------------------------------------+
//| Draw sell zones                                                  |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawSellZones(double levels[], double proximity, int count) {
    for(int i = 0; i < count && i < ArraySize(levels); i++) {
        if(levels[i] > 0) {
            string zoneName = m_prefix + "SellZone_" + IntegerToString(i);
            DrawTradingZone(zoneName, levels[i] - proximity, levels[i] + proximity, m_sellZoneColor, false);
        }
    }
}

//+------------------------------------------------------------------+
//| Draw trading zone rectangle                                      |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawTradingZone(string name, double price1, double price2, color zoneColor, bool isBuyZone = true) {
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 100;
    
    ObjectCreate(0, name, OBJ_RECTANGLE, 0, currentTime, price1, futureTime, price2);
    ObjectSetInteger(0, name, OBJPROP_COLOR, zoneColor);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_FILL, true);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
    ObjectSetString(0, name, OBJPROP_TEXT, isBuyZone ? "BUY ZONE" : "SELL ZONE");
}

//+------------------------------------------------------------------+
//| Draw pattern marker                                              |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawPatternMarker(string patternName, int candleIndex, double price, color markerColor) {
    datetime candleTime = iTime(_Symbol, _Period, candleIndex);
    string objName = m_prefix + "Pattern_" + patternName + "_" + IntegerToString(candleIndex);
    
    ObjectCreate(0, objName, OBJ_ARROW_UP, 0, candleTime, price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, markerColor);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);
    ObjectSetString(0, objName, OBJPROP_TEXT, patternName);
}

//+------------------------------------------------------------------+
//| Draw entry signal                                                |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawEntrySignal(double price, bool isBuy, string reason = "") {
    datetime currentTime = TimeCurrent();
    string objName = m_prefix + "Entry_" + TimeToString(currentTime, TIME_SECONDS);
    
    ObjectCreate(0, objName, isBuy ? OBJ_ARROW_BUY : OBJ_ARROW_SELL, 0, currentTime, price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, m_entryColor);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 5);
    ObjectSetString(0, objName, OBJPROP_TEXT, (isBuy ? "BUY" : "SELL") + (reason != "" ? " - " + reason : ""));
}

//+------------------------------------------------------------------+
//| Draw exit signal                                                 |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawExitSignal(double price, bool wasProfit, string reason = "") {
    datetime currentTime = TimeCurrent();
    string objName = m_prefix + "Exit_" + TimeToString(currentTime, TIME_SECONDS);
    
    ObjectCreate(0, objName, OBJ_ARROW, 0, currentTime, price);
    ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, 251); // Close arrow
    ObjectSetInteger(0, objName, OBJPROP_COLOR, wasProfit ? clrGreen : clrRed);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 4);
    ObjectSetString(0, objName, OBJPROP_TEXT, (wasProfit ? "PROFIT" : "LOSS") + (reason != "" ? " - " + reason : ""));
}

//+------------------------------------------------------------------+
//| Draw Fibonacci retracement                                       |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawFibonacciRetracement(double highPrice, double lowPrice, datetime startTime, datetime endTime) {
    string objName = m_prefix + "Fibonacci";
    ObjectDelete(0, objName);
    
    ObjectCreate(0, objName, OBJ_FIBO, 0, startTime, lowPrice, endTime, highPrice);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, m_trendLineColor);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
}

//+------------------------------------------------------------------+
//| Draw trend line                                                  |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawTrendLine(string name, double price1, double price2, datetime time1, datetime time2, color lineColor) {
    string objName = m_prefix + name;
    ObjectDelete(0, objName);
    
    ObjectCreate(0, objName, OBJ_TREND, 0, time1, price1, time2, price2);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
}

//+------------------------------------------------------------------+
//| Draw horizontal level                                            |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawHorizontalLevel(string name, double price, color levelColor, int style = STYLE_SOLID, int width = 1) {
    string objName = m_prefix + name;
    ObjectDelete(0, objName);
    
    datetime currentTime = TimeCurrent();
    datetime futureTime = currentTime + PeriodSeconds() * 100;
    
    ObjectCreate(0, objName, OBJ_TREND, 0, currentTime, price, futureTime, price);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, levelColor);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, style);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
}

//+------------------------------------------------------------------+
//| Draw trade information                                           |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawTradeInfo(string symbol, double entryPrice, double stopLoss, double takeProfit, bool isBuy) {
    // This would create a comprehensive trade info panel
    // Implementation depends on specific requirements
}

//+------------------------------------------------------------------+
//| Draw trend indicator                                             |
//+------------------------------------------------------------------+
void CVisualIndicators::DrawTrendIndicator(int trend, int x = 10, int y = 10) {
    string objName = m_prefix + "TrendIndicator";
    ObjectDelete(0, objName);
    
    string trendText = "";
    color trendColor = clrWhite;
    
    switch(trend) {
        case 1:
            trendText = "UPTREND ↗";
            trendColor = clrLime;
            break;
        case -1:
            trendText = "DOWNTREND ↘";
            trendColor = clrRed;
            break;
        default:
            trendText = "SIDEWAYS ↔";
            trendColor = clrYellow;
            break;
    }
    
    ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
    ObjectSetString(0, objName, OBJPROP_TEXT, trendText);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, trendColor);
    ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 12);
}

//+------------------------------------------------------------------+
//| Clear all visual objects                                         |
//+------------------------------------------------------------------+
void CVisualIndicators::ClearAll() {
    ClearObjects(m_prefix);
}

//+------------------------------------------------------------------+
//| Clear level objects                                              |
//+------------------------------------------------------------------+
void CVisualIndicators::ClearLevels() {
    ClearObjects(m_prefix + "Support_");
    ClearObjects(m_prefix + "Resistance_");
    ClearObjects(m_prefix + "SwingHigh_");
    ClearObjects(m_prefix + "SwingLow_");
    ClearObjects(m_prefix + "HH_");
    ClearObjects(m_prefix + "HL_");
    ClearObjects(m_prefix + "LH_");
    ClearObjects(m_prefix + "LL_");
}

//+------------------------------------------------------------------+
//| Clear zone objects                                               |
//+------------------------------------------------------------------+
void CVisualIndicators::ClearZones() {
    ClearObjects(m_prefix + "BuyZone_");
    ClearObjects(m_prefix + "SellZone_");
}

//+------------------------------------------------------------------+
//| Clear pattern objects                                            |
//+------------------------------------------------------------------+
void CVisualIndicators::ClearPatterns() {
    ClearObjects(m_prefix + "Pattern_");
}

//+------------------------------------------------------------------+
//| Clear objects by name pattern                                    |
//+------------------------------------------------------------------+
void CVisualIndicators::ClearObjects(string namePattern) {
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        if(StringFind(objName, namePattern) >= 0) {
            ObjectDelete(0, objName);
        }
    }
}