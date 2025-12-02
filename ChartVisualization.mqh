//+------------------------------------------------------------------+
//|                                        ChartVisualization.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "SwingDetection.mqh"
#include "SupportResistance.mqh"

//+------------------------------------------------------------------+
//| Chart Visualization Class                                        |
//+------------------------------------------------------------------+
class CChartVisualization {
private:
    string m_symbol;
    long m_chartID;
    string m_prefix;
    
    color m_buyColor;
    color m_sellColor;
    color m_supportColor;
    color m_resistanceColor;
    color m_slColor;
    color m_tpColor;
    
    int m_objectCount;
    
    // Private methods
    string GenerateObjectName(string type);
    void DeleteObjectsByPrefix(string prefix);
    bool CreateArrow(string name, datetime time, double price, int arrowCode, color clr);
    bool CreateHLine(string name, double price, color clr, int width, ENUM_LINE_STYLE style);
    bool CreateTrendLine(string name, datetime time1, double price1, datetime time2, double price2, color clr);
    bool CreateRectangle(string name, datetime time1, double price1, datetime time2, double price2, color clr);
    bool CreateText(string name, datetime time, double price, string text, color clr);
    
public:
    CChartVisualization(string symbol, long chartID = 0);
    ~CChartVisualization();
    
    void Initialize();
    void ClearAll();
    
    // Draw methods
    void DrawSwingPoints(CSwingDetection* swingDetector);
    void DrawSupportResistance(CSupportResistance* srManager);
    void DrawBuySignal(datetime time, double price, string comment = "");
    void DrawSellSignal(datetime time, double price, string comment = "");
    void DrawStopLoss(double price, string label = "");
    void DrawTakeProfit(double price, string label = "");
    void DrawBuyZone(datetime time1, double price1, datetime time2, double price2);
    void DrawSellZone(datetime time1, double price1, datetime time2, double price2);
    void DrawTradeBox(datetime entryTime, double entryPrice, double sl, double tp, bool isBuy);
    
    // Color setters
    void SetBuyColor(color clr) { m_buyColor = clr; }
    void SetSellColor(color clr) { m_sellColor = clr; }
    void SetSupportColor(color clr) { m_supportColor = clr; }
    void SetResistanceColor(color clr) { m_resistanceColor = clr; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CChartVisualization::CChartVisualization(string symbol, long chartID = 0) {
    m_symbol = symbol;
    m_chartID = (chartID == 0) ? ChartID() : chartID;
    m_prefix = "SwingEA_";
    
    m_buyColor = clrLime;
    m_sellColor = clrRed;
    m_supportColor = clrDodgerBlue;
    m_resistanceColor = clrOrangeRed;
    m_slColor = clrRed;
    m_tpColor = clrGreen;
    
    m_objectCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CChartVisualization::~CChartVisualization(void) {
}

//+------------------------------------------------------------------+
//| Initialize visualization                                         |
//+------------------------------------------------------------------+
void CChartVisualization::Initialize(void) {
    ClearAll();
}

//+------------------------------------------------------------------+
//| Clear all objects                                                |
//+------------------------------------------------------------------+
void CChartVisualization::ClearAll(void) {
    DeleteObjectsByPrefix(m_prefix);
    m_objectCount = 0;
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Generate unique object name                                      |
//+------------------------------------------------------------------+
string CChartVisualization::GenerateObjectName(string type) {
    m_objectCount++;
    return m_prefix + type + "_" + IntegerToString(m_objectCount) + "_" + IntegerToString(GetTickCount());
}

//+------------------------------------------------------------------+
//| Delete objects by prefix                                         |
//+------------------------------------------------------------------+
void CChartVisualization::DeleteObjectsByPrefix(string prefix) {
    int total = ObjectsTotal(m_chartID);
    
    for(int i = total - 1; i >= 0; i--) {
        string name = ObjectName(m_chartID, i);
        if(StringFind(name, prefix) == 0) {
            ObjectDelete(m_chartID, name);
        }
    }
}

//+------------------------------------------------------------------+
//| Create arrow                                                     |
//+------------------------------------------------------------------+
bool CChartVisualization::CreateArrow(string name, datetime time, double price, int arrowCode, color clr) {
    if(ObjectCreate(m_chartID, name, OBJ_ARROW, 0, time, price)) {
        ObjectSetInteger(m_chartID, name, OBJPROP_ARROWCODE, arrowCode);
        ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(m_chartID, name, OBJPROP_WIDTH, 3);
        ObjectSetInteger(m_chartID, name, OBJPROP_BACK, false);
        ObjectSetInteger(m_chartID, name, OBJPROP_SELECTABLE, false);
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Create horizontal line                                           |
//+------------------------------------------------------------------+
bool CChartVisualization::CreateHLine(string name, double price, color clr, int width, ENUM_LINE_STYLE style) {
    if(ObjectCreate(m_chartID, name, OBJ_HLINE, 0, 0, price)) {
        ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(m_chartID, name, OBJPROP_WIDTH, width);
        ObjectSetInteger(m_chartID, name, OBJPROP_STYLE, style);
        ObjectSetInteger(m_chartID, name, OBJPROP_BACK, false);
        ObjectSetInteger(m_chartID, name, OBJPROP_SELECTABLE, false);
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Create trend line                                                |
//+------------------------------------------------------------------+
bool CChartVisualization::CreateTrendLine(string name, datetime time1, double price1, 
                                         datetime time2, double price2, color clr) {
    if(ObjectCreate(m_chartID, name, OBJ_TREND, 0, time1, price1, time2, price2)) {
        ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(m_chartID, name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(m_chartID, name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(m_chartID, name, OBJPROP_BACK, true);
        ObjectSetInteger(m_chartID, name, OBJPROP_SELECTABLE, false);
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Create rectangle                                                 |
//+------------------------------------------------------------------+
bool CChartVisualization::CreateRectangle(string name, datetime time1, double price1, 
                                         datetime time2, double price2, color clr) {
    if(ObjectCreate(m_chartID, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2)) {
        ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(m_chartID, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(m_chartID, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(m_chartID, name, OBJPROP_FILL, true);
        ObjectSetInteger(m_chartID, name, OBJPROP_BACK, true);
        ObjectSetInteger(m_chartID, name, OBJPROP_SELECTABLE, false);
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Create text                                                      |
//+------------------------------------------------------------------+
bool CChartVisualization::CreateText(string name, datetime time, double price, string text, color clr) {
    if(ObjectCreate(m_chartID, name, OBJ_TEXT, 0, time, price)) {
        ObjectSetString(m_chartID, name, OBJPROP_TEXT, text);
        ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(m_chartID, name, OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(m_chartID, name, OBJPROP_BACK, false);
        ObjectSetInteger(m_chartID, name, OBJPROP_SELECTABLE, false);
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Draw swing points                                                |
//+------------------------------------------------------------------+
void CChartVisualization::DrawSwingPoints(CSwingDetection* swingDetector) {
    if(swingDetector == NULL) return;
    
    // Draw swing highs
    int highCount = swingDetector.GetSwingHighCount();
    for(int i = 0; i < highCount; i++) {
        SwingPoint point;
        if(swingDetector.GetSwingHigh(i, point)) {
            string name = GenerateObjectName("SwingHigh");
            CreateArrow(name, point.time, point.price, 234, clrOrangeRed);
            
            // Add label
            string label = "";
            if(point.type == SWING_HH) label = "HH";
            else if(point.type == SWING_LH) label = "LH";
            
            if(label != "") {
                string textName = GenerateObjectName("SwingHighText");
                CreateText(textName, point.time, point.price, label, clrOrangeRed);
            }
        }
    }
    
    // Draw swing lows
    int lowCount = swingDetector.GetSwingLowCount();
    for(int i = 0; i < lowCount; i++) {
        SwingPoint point;
        if(swingDetector.GetSwingLow(i, point)) {
            string name = GenerateObjectName("SwingLow");
            CreateArrow(name, point.time, point.price, 233, clrDodgerBlue);
            
            // Add label
            string label = "";
            if(point.type == SWING_HL) label = "HL";
            else if(point.type == SWING_LL) label = "LL";
            
            if(label != "") {
                string textName = GenerateObjectName("SwingLowText");
                CreateText(textName, point.time, point.price, label, clrDodgerBlue);
            }
        }
    }
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw support and resistance levels                               |
//+------------------------------------------------------------------+
void CChartVisualization::DrawSupportResistance(CSupportResistance* srManager) {
    if(srManager == NULL) return;
    
    int levelCount = srManager.GetLevelCount();
    for(int i = 0; i < levelCount; i++) {
        SRLevel level;
        if(srManager.GetLevel(i, level)) {
            string name = GenerateObjectName("SRLevel");
            color clr = level.isSupport ? m_supportColor : m_resistanceColor;
            
            CreateHLine(name, level.price, clr, 1, STYLE_DOT);
            
            // Add description
            string textName = GenerateObjectName("SRText");
            CreateText(textName, TimeCurrent(), level.price, level.description, clr);
        }
    }
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw buy signal                                                  |
//+------------------------------------------------------------------+
void CChartVisualization::DrawBuySignal(datetime time, double price, string comment = "") {
    string name = GenerateObjectName("BuySignal");
    CreateArrow(name, time, price, 233, m_buyColor);  // Up arrow
    
    if(comment != "") {
        string textName = GenerateObjectName("BuyText");
        CreateText(textName, time, price, "BUY", m_buyColor);
    }
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw sell signal                                                 |
//+------------------------------------------------------------------+
void CChartVisualization::DrawSellSignal(datetime time, double price, string comment = "") {
    string name = GenerateObjectName("SellSignal");
    CreateArrow(name, time, price, 234, m_sellColor);  // Down arrow
    
    if(comment != "") {
        string textName = GenerateObjectName("SellText");
        CreateText(textName, time, price, "SELL", m_sellColor);
    }
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw stop loss line                                              |
//+------------------------------------------------------------------+
void CChartVisualization::DrawStopLoss(double price, string label = "") {
    string name = GenerateObjectName("SL");
    CreateHLine(name, price, m_slColor, 2, STYLE_SOLID);
    
    if(label == "") label = "SL";
    ObjectSetString(m_chartID, name, OBJPROP_TEXT, label);
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw take profit line                                            |
//+------------------------------------------------------------------+
void CChartVisualization::DrawTakeProfit(double price, string label = "") {
    string name = GenerateObjectName("TP");
    CreateHLine(name, price, m_tpColor, 2, STYLE_SOLID);
    
    if(label == "") label = "TP";
    ObjectSetString(m_chartID, name, OBJPROP_TEXT, label);
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw buy zone                                                    |
//+------------------------------------------------------------------+
void CChartVisualization::DrawBuyZone(datetime time1, double price1, datetime time2, double price2) {
    string name = GenerateObjectName("BuyZone");
    color zoneColor = C'0,100,0';  // Dark green with transparency
    CreateRectangle(name, time1, price1, time2, price2, zoneColor);
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw sell zone                                                   |
//+------------------------------------------------------------------+
void CChartVisualization::DrawSellZone(datetime time1, double price1, datetime time2, double price2) {
    string name = GenerateObjectName("SellZone");
    color zoneColor = C'100,0,0';  // Dark red with transparency
    CreateRectangle(name, time1, price1, time2, price2, zoneColor);
    
    ChartRedraw(m_chartID);
}

//+------------------------------------------------------------------+
//| Draw trade box showing entry, SL, and TP                         |
//+------------------------------------------------------------------+
void CChartVisualization::DrawTradeBox(datetime entryTime, double entryPrice, double sl, double tp, bool isBuy) {
    datetime currentTime = TimeCurrent();
    
    // Draw entry line
    string entryName = GenerateObjectName("Entry");
    CreateTrendLine(entryName, entryTime, entryPrice, currentTime, entryPrice, clrYellow);
    
    // Draw SL
    DrawStopLoss(sl);
    
    // Draw TP
    DrawTakeProfit(tp);
    
    // Draw zone
    if(isBuy) {
        DrawBuyZone(entryTime, sl, currentTime, tp);
    } else {
        DrawSellZone(entryTime, tp, currentTime, sl);
    }
    
    ChartRedraw(m_chartID);
}
//+------------------------------------------------------------------+
