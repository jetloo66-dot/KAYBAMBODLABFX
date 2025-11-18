//+------------------------------------------------------------------+
//|                                         Utilities_Enhanced.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Enhanced Utility Functions Class                                |
//+------------------------------------------------------------------+
class CUtilitiesEnhanced {
public:
    CUtilitiesEnhanced();
    ~CUtilitiesEnhanced();
    
    // Price Conversion Utilities
    static double PipsToPoints(double pips, string symbol = "");
    static double PointsToPips(double points, string symbol = "");
    static double NormalizePrice(double price, string symbol = "");
    static double NormalizeLots(double lots, string symbol = "");
    
    // Time Utilities
    static string TimeToString(datetime time, int format = TIME_DATE|TIME_MINUTES);
    static datetime StringToTime(string timeStr);
    static bool IsWithinTradingHours(string symbol = "");
    static bool IsNewBar(ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "");
    static datetime GetBarTime(int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "");
    
    // Market Information
    static bool IsMarketOpen(string symbol = "");
    static double GetSpread(string symbol = "");
    static double GetSpreadInPips(string symbol = "");
    static long GetDigits(string symbol = "");
    static double GetPoint(string symbol = "");
    static double GetTickSize(string symbol = "");
    static double GetTickValue(string symbol = "");
    
    // Position and Order Utilities
    static int CountPositions(string symbol = "", int magic = -1);
    static int CountOrders(string symbol = "", int magic = -1);
    static double GetTotalVolume(string symbol = "", int magic = -1);
    static double GetTotalProfit(string symbol = "", int magic = -1);
    static bool CloseAllPositions(string symbol = "", int magic = -1, string reason = "Utility Close");
    
    // Price Analysis Utilities
    static double GetHighestHigh(int bars, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "");
    static double GetLowestLow(int bars, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "");
    static double GetAverageRange(int bars, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "");
    static bool IsPriceAboveMA(int maPeriod, ENUM_MA_METHOD maMethod = MODE_SMA, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "");
    static bool IsPriceBelowMA(int maPeriod, ENUM_MA_METHOD maMethod = MODE_SMA, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "");
    
    // Mathematical Utilities
    static double CalculateDistance(double price1, double price2);
    static double CalculatePercentageChange(double oldValue, double newValue);
    static double RoundToStep(double value, double step);
    static bool IsEqualDouble(double value1, double value2, double tolerance = 0.00001);
    static double GetAngleBetweenPoints(double x1, double y1, double x2, double y2);
    
    // String Utilities
    static string[] SplitString(string str, string delimiter);
    static string JoinStrings(string &array[], string delimiter);
    static string PadString(string str, int length, string padChar = " ", bool padRight = true);
    static string TrimString(string str);
    static bool ContainsString(string source, string search, bool caseSensitive = true);
    static string ReplaceString(string source, string search, string replace);
    
    // Array Utilities
    static void ArrayReverse(double &array[]);
    static void ArrayReverse(int &array[]);
    static double ArrayMedian(double &array[]);
    static double ArrayStandardDeviation(double &array[]);
    static int ArrayIndexOf(double &array[], double value, double tolerance = 0.00001);
    static bool ArrayContains(double &array[], double value, double tolerance = 0.00001);
    
    // Color and Display Utilities
    static color GetTrendColor(bool isUptrend);
    static color BlendColors(color color1, color color2, double ratio);
    static string ColorToString(color clr);
    static color StringToColor(string colorStr);
    
    // File and Data Utilities
    static bool SaveDataToFile(string fileName, string data, bool append = true);
    static string LoadDataFromFile(string fileName);
    static bool FileExists(string fileName);
    static bool DeleteFile(string fileName);
    static long GetFileSize(string fileName);
    
    // Symbol List Utilities
    static string[] GetMajorPairs();
    static string[] GetCryptoPairs();
    static string[] GetMetalPairs();
    static string[] ParseSymbolList(string symbolString);
    static bool IsForexPair(string symbol);
    static bool IsCryptoPair(string symbol);
    static bool IsMetalPair(string symbol);
    static bool IsIndexPair(string symbol);
    
    // Trading Session Utilities
    static bool IsAsianSession();
    static bool IsEuropeanSession();
    static bool IsAmericanSession();
    static string GetCurrentTradingSession();
    static bool IsHighImpactNewsTime(datetime checkTime);
    
    // Risk and Money Management Utilities
    static double CalculatePositionSize(double accountBalance, double riskPercent, double entryPrice, double stopLoss, string symbol = "");
    static double CalculateRiskRewardRatio(double entryPrice, double stopLoss, double takeProfit, bool isBuy = true);
    static double CalculatePotentialProfit(double entryPrice, double exitPrice, double volume, string symbol = "");
    static double CalculatePotentialLoss(double entryPrice, double stopLoss, double volume, bool isBuy, string symbol = "");
    
    // Chart and Object Utilities
    static bool CreateHorizontalLine(string name, double price, color lineColor = clrBlue, int lineWidth = 1, ENUM_LINE_STYLE lineStyle = STYLE_SOLID);
    static bool CreateVerticalLine(string name, datetime time, color lineColor = clrBlue, int lineWidth = 1, ENUM_LINE_STYLE lineStyle = STYLE_SOLID);
    static bool CreateTrendLine(string name, datetime time1, double price1, datetime time2, double price2, color lineColor = clrBlue, int lineWidth = 1);
    static bool CreateRectangle(string name, datetime time1, double price1, datetime time2, double price2, color rectColor = clrLightBlue, bool fill = true);
    static bool CreateText(string name, datetime time, double price, string text, color textColor = clrBlack, int fontSize = 10);
    static void CleanupChartObjects(string prefix = "");
    static int CountChartObjects(string prefix = "");
    
    // Performance Monitoring
    static ulong GetTickCount();
    static void StartTimer(string timerName);
    static ulong EndTimer(string timerName);
    static double GetMemoryUsage();
    static string GetPerformanceReport();
    
    // Error Handling Utilities
    static string GetErrorDescription(int errorCode);
    static void LogError(string function, int errorCode, string additionalInfo = "");
    static bool IsRetryableError(int errorCode);
    static void HandleTradingError(int errorCode, string operation);
    
    // Backup and Recovery
    static bool BackupEAState(string fileName);
    static bool RestoreEAState(string fileName);
    static bool SaveTradingHistory(string fileName, datetime fromDate, datetime toDate);
    
private:
    static datetime m_lastBarTime[];
    static ulong m_timers[];
    static string m_timerNames[];
    static int m_timerCount;
};

// Static member initialization
datetime CUtilitiesEnhanced::m_lastBarTime[];
ulong CUtilitiesEnhanced::m_timers[];
string CUtilitiesEnhanced::m_timerNames[];
int CUtilitiesEnhanced::m_timerCount = 0;

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CUtilitiesEnhanced::CUtilitiesEnhanced() {
    ArrayResize(m_lastBarTime, 100);
    ArrayResize(m_timers, 50);
    ArrayResize(m_timerNames, 50);
    ArrayInitialize(m_lastBarTime, 0);
    ArrayInitialize(m_timers, 0);
    m_timerCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CUtilitiesEnhanced::~CUtilitiesEnhanced() {
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Convert pips to points                                          |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::PipsToPoints(double pips, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    if(digits == 5 || digits == 3) {
        return pips * point * 10;
    } else {
        return pips * point;
    }
}

//+------------------------------------------------------------------+
//| Convert points to pips                                          |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::PointsToPips(double points, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    if(digits == 5 || digits == 3) {
        return points / (point * 10);
    } else {
        return points / point;
    }
}

//+------------------------------------------------------------------+
//| Normalize price to symbol digits                               |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::NormalizePrice(double price, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    return NormalizeDouble(price, digits);
}

//+------------------------------------------------------------------+
//| Normalize lot size to symbol requirements                      |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::NormalizeLots(double lots, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    lots = MathMax(lots, minLot);
    lots = MathMin(lots, maxLot);
    lots = MathRound(lots / lotStep) * lotStep;
    
    return lots;
}

//+------------------------------------------------------------------+
//| Check if it's a new bar                                        |
//+------------------------------------------------------------------+
static bool CUtilitiesEnhanced::IsNewBar(ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(symbol, timeframe, 0);
    
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if market is open                                         |
//+------------------------------------------------------------------+
static bool CUtilitiesEnhanced::IsMarketOpen(string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    MqlTick lastTick;
    if(!SymbolInfoTick(symbol, lastTick)) return false;
    
    datetime currentTime = TimeCurrent();
    return (currentTime - lastTick.time <= 60); // Market is open if last tick is within 1 minute
}

//+------------------------------------------------------------------+
//| Get spread in points                                            |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::GetSpread(string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    return SymbolInfoInteger(symbol, SYMBOL_SPREAD) * SymbolInfoDouble(symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Get spread in pips                                              |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::GetSpreadInPips(string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    double spreadPoints = GetSpread(symbol);
    return PointsToPips(spreadPoints, symbol);
}

//+------------------------------------------------------------------+
//| Count positions                                                 |
//+------------------------------------------------------------------+
static int CUtilitiesEnhanced::CountPositions(string symbol = "", int magic = -1) {
    int count = 0;
    
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i) == 0) continue;
        
        string posSymbol = PositionGetString(POSITION_SYMBOL);
        int posMagic = (int)PositionGetInteger(POSITION_MAGIC);
        
        if((symbol == "" || posSymbol == symbol) && (magic == -1 || posMagic == magic)) {
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get highest high over specified bars                           |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::GetHighestHigh(int bars, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    double high[];
    if(CopyHigh(symbol, timeframe, shift, bars, high) <= 0) return 0;
    
    return high[ArrayMaximum(high)];
}

//+------------------------------------------------------------------+
//| Get lowest low over specified bars                             |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::GetLowestLow(int bars, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    double low[];
    if(CopyLow(symbol, timeframe, shift, bars, low) <= 0) return 0;
    
    return low[ArrayMinimum(low)];
}

//+------------------------------------------------------------------+
//| Get average range over specified bars                          |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::GetAverageRange(int bars, int shift = 0, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    double high[], low[];
    if(CopyHigh(symbol, timeframe, shift, bars, high) <= 0 ||
       CopyLow(symbol, timeframe, shift, bars, low) <= 0) return 0;
    
    double totalRange = 0;
    for(int i = 0; i < ArraySize(high); i++) {
        totalRange += (high[i] - low[i]);
    }
    
    return totalRange / ArraySize(high);
}

//+------------------------------------------------------------------+
//| Calculate distance between two prices                          |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::CalculateDistance(double price1, double price2) {
    return MathAbs(price1 - price2);
}

//+------------------------------------------------------------------+
//| Calculate percentage change                                     |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::CalculatePercentageChange(double oldValue, double newValue) {
    if(oldValue == 0) return 0;
    return ((newValue - oldValue) / oldValue) * 100.0;
}

//+------------------------------------------------------------------+
//| Split string by delimiter                                       |
//+------------------------------------------------------------------+
static string[] CUtilitiesEnhanced::SplitString(string str, string delimiter) {
    string result[];
    int pos = 0;
    int nextPos = 0;
    int count = 0;
    
    // Count occurrences first
    string temp = str;
    while((pos = StringFind(temp, delimiter)) >= 0) {
        count++;
        temp = StringSubstr(temp, pos + StringLen(delimiter));
    }
    count++; // Add one for the last part
    
    ArrayResize(result, count);
    
    // Split the string
    pos = 0;
    int index = 0;
    while((nextPos = StringFind(str, delimiter, pos)) >= 0) {
        result[index] = StringSubstr(str, pos, nextPos - pos);
        pos = nextPos + StringLen(delimiter);
        index++;
    }
    result[index] = StringSubstr(str, pos); // Last part
    
    return result;
}

//+------------------------------------------------------------------+
//| Get major currency pairs                                        |
//+------------------------------------------------------------------+
static string[] CUtilitiesEnhanced::GetMajorPairs() {
    string pairs[];
    ArrayResize(pairs, 7);
    
    pairs[0] = "EURUSD";
    pairs[1] = "GBPUSD";
    pairs[2] = "USDJPY";
    pairs[3] = "USDCHF";
    pairs[4] = "AUDUSD";
    pairs[5] = "USDCAD";
    pairs[6] = "NZDUSD";
    
    return pairs;
}

//+------------------------------------------------------------------+
//| Get crypto pairs                                               |
//+------------------------------------------------------------------+
static string[] CUtilitiesEnhanced::GetCryptoPairs() {
    string pairs[];
    ArrayResize(pairs, 5);
    
    pairs[0] = "BTCUSD";
    pairs[1] = "ETHUSD";
    pairs[2] = "LTCUSD";
    pairs[3] = "XRPUSD";
    pairs[4] = "BCHUSD";
    
    return pairs;
}

//+------------------------------------------------------------------+
//| Get metal pairs                                                |
//+------------------------------------------------------------------+
static string[] CUtilitiesEnhanced::GetMetalPairs() {
    string pairs[];
    ArrayResize(pairs, 4);
    
    pairs[0] = "XAUUSD";
    pairs[1] = "XAGUSD";
    pairs[2] = "XPTUSD";
    pairs[3] = "XPDUSD";
    
    return pairs;
}

//+------------------------------------------------------------------+
//| Parse symbol list from string                                  |
//+------------------------------------------------------------------+
static string[] CUtilitiesEnhanced::ParseSymbolList(string symbolString) {
    return SplitString(symbolString, ",");
}

//+------------------------------------------------------------------+
//| Check if symbol is forex pair                                  |
//+------------------------------------------------------------------+
static bool CUtilitiesEnhanced::IsForexPair(string symbol) {
    string majorPairs[] = GetMajorPairs();
    
    for(int i = 0; i < ArraySize(majorPairs); i++) {
        if(symbol == majorPairs[i]) return true;
    }
    
    // Check other common forex pairs
    return (StringLen(symbol) == 6 && 
            StringFind(symbol, "USD") >= 0 || StringFind(symbol, "EUR") >= 0 || 
            StringFind(symbol, "GBP") >= 0 || StringFind(symbol, "JPY") >= 0);
}

//+------------------------------------------------------------------+
//| Check if symbol is crypto pair                                 |
//+------------------------------------------------------------------+
static bool CUtilitiesEnhanced::IsCryptoPair(string symbol) {
    return (StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 || 
            StringFind(symbol, "LTC") >= 0 || StringFind(symbol, "XRP") >= 0 ||
            StringFind(symbol, "BCH") >= 0 || StringFind(symbol, "ADA") >= 0);
}

//+------------------------------------------------------------------+
//| Check if symbol is metal pair                                  |
//+------------------------------------------------------------------+
static bool CUtilitiesEnhanced::IsMetalPair(string symbol) {
    return (StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "XAG") >= 0 || 
            StringFind(symbol, "XPT") >= 0 || StringFind(symbol, "XPD") >= 0);
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk                          |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::CalculatePositionSize(double accountBalance, double riskPercent, double entryPrice, double stopLoss, string symbol = "") {
    if(symbol == "") symbol = _Symbol;
    
    double riskAmount = accountBalance * (riskPercent / 100.0);
    double stopLossPoints = MathAbs(entryPrice - stopLoss);
    
    if(stopLossPoints <= 0) return 0;
    
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * (SymbolInfoDouble(symbol, SYMBOL_POINT) / tickSize);
    
    double lotSize = riskAmount / (stopLossPoints * pointValue);
    
    return NormalizeLots(lotSize, symbol);
}

//+------------------------------------------------------------------+
//| Calculate risk-reward ratio                                     |
//+------------------------------------------------------------------+
static double CUtilitiesEnhanced::CalculateRiskRewardRatio(double entryPrice, double stopLoss, double takeProfit, bool isBuy = true) {
    double risk = MathAbs(entryPrice - stopLoss);
    double reward;
    
    if(isBuy) {
        reward = takeProfit - entryPrice;
    } else {
        reward = entryPrice - takeProfit;
    }
    
    if(risk <= 0) return 0;
    
    return reward / risk;
}

//+------------------------------------------------------------------+
//| Create horizontal line on chart                                |
//+------------------------------------------------------------------+
static bool CUtilitiesEnhanced::CreateHorizontalLine(string name, double price, color lineColor = clrBlue, int lineWidth = 1, ENUM_LINE_STYLE lineStyle = STYLE_SOLID) {
    if(ObjectFind(0, name) >= 0) {
        ObjectDelete(0, name);
    }
    
    if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price)) {
        return false;
    }
    
    ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, lineWidth);
    ObjectSetInteger(0, name, OBJPROP_STYLE, lineStyle);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
    
    return true;
}

//+------------------------------------------------------------------+
//| Create trend line on chart                                     |
//+------------------------------------------------------------------+
static bool CUtilitiesEnhanced::CreateTrendLine(string name, datetime time1, double price1, datetime time2, double price2, color lineColor = clrBlue, int lineWidth = 1) {
    if(ObjectFind(0, name) >= 0) {
        ObjectDelete(0, name);
    }
    
    if(!ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2)) {
        return false;
    }
    
    ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, lineWidth);
    ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);
    
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup chart objects with prefix                              |
//+------------------------------------------------------------------+
static void CUtilitiesEnhanced::CleanupChartObjects(string prefix = "") {
    for(int i = ObjectsTotal(0) - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        if(prefix == "" || StringFind(objName, prefix) >= 0) {
            ObjectDelete(0, objName);
        }
    }
}

//+------------------------------------------------------------------+
//| Get error description                                           |
//+------------------------------------------------------------------+
static string CUtilitiesEnhanced::GetErrorDescription(int errorCode) {
    switch(errorCode) {
        case 0: return "No error";
        case 4: return "No memory for function call stack";
        case 5: return "Recursive stack overflow";
        case 6: return "Not enough stack for parameter";
        case 7: return "No memory for parameter string";
        case 8: return "Not initialized string";
        case 9: return "Not initialized string in array";
        case 10: return "No memory for array string";
        case 11: return "Too long string";
        case 12: return "Remainder from zero divide";
        case 13: return "Zero divide";
        case 14: return "Unknown command";
        case 15: return "Wrong jump";
        case 16: return "Not initialized array";
        case 17: return "DLL calls are not allowed";
        case 18: return "Cannot load library";
        case 19: return "Cannot call function";
        case 20: return "Expert function calls are not allowed";
        case 21: return "Not enough memory for temp string returned from function";
        case 22: return "System is busy";
        case 4000: return "No error";
        case 4001: return "Wrong function pointer";
        case 4002: return "Array index is out of range";
        case 4003: return "No memory for function call stack";
        case 4004: return "Recursive stack overflow";
        case 4005: return "Not enough stack for parameter";
        case 4006: return "No memory for parameter string";
        case 4007: return "No memory for temp string";
        case 4008: return "Not initialized string";
        case 4009: return "Not initialized string in array";
        case 4010: return "No memory for array string";
        case 4011: return "Too long string";
        case 4012: return "Remainder from zero divide";
        case 4013: return "Zero divide";
        case 4014: return "Unknown command";
        case 4015: return "Wrong jump";
        case 4016: return "Not initialized array";
        case 4017: return "DLL calls are not allowed";
        case 4018: return "Cannot load library";
        case 4019: return "Cannot call function";
        case 4020: return "Expert function calls are not allowed";
        case 4021: return "Not enough memory for temp string returned from function";
        case 4022: return "System is busy";
        case 4050: return "Invalid function parameters count";
        case 4051: return "Invalid function parameter value";
        case 4052: return "String function internal error";
        case 4053: return "Some array error";
        case 4054: return "Incorrect series array using";
        case 4055: return "Custom indicator error";
        case 4056: return "Arrays are incompatible";
        case 4057: return "Global variables processing error";
        case 4058: return "Global variable not found";
        case 4059: return "Function is not allowed in testing mode";
        case 4060: return "Function is not confirmed";
        case 4061: return "Send mail error";
        case 4062: return "String parameter expected";
        case 4063: return "Integer parameter expected";
        case 4064: return "Double parameter expected";
        case 4065: return "Array as parameter expected";
        case 4066: return "History data update error";
        case 4067: return "Some error in trading function";
        case 4068: return "End of file";
        case 4069: return "Some file error";
        case 4070: return "Wrong file name";
        case 4071: return "Too many opened files";
        case 4072: return "Cannot open file";
        case 4073: return "Cannot write file";
        case 4074: return "Cannot read file";
        case 4075: return "Object is already exist";
        case 4076: return "Unknown object property";
        case 4077: return "Object is not exist";
        case 4078: return "Unknown object type";
        case 4079: return "No object name";
        case 4080: return "Object coordinates error";
        case 4081: return "No specified subwindow";
        case 4082: return "Graphical object error";
        case 4083: return "Chart not found";
        case 4084: return "Chart subwindow not found";
        case 4085: return "Chart indicator not found";
        case 4086: return "Symbol select error";
        case 4087: return "Notification error";
        case 4088: return "Notification parameter error";
        case 4089: return "Notification settings error";
        case 4090: return "Notification send error";
        case 4091: return "Notification parameter too long";
        case 4092: return "History not found";
        case 4099: return "End of file";
        case 4100: return "Some file error";
        case 4101: return "Wrong file name";
        case 4102: return "Too many opened files";
        case 4103: return "Cannot open file";
        case 4104: return "Incompatible access to a file";
        case 4105: return "No order selected";
        case 4106: return "Unknown symbol";
        case 4107: return "Invalid price parameter for trade function";
        case 4108: return "Invalid ticket";
        case 4109: return "Trade is not allowed in the expert properties";
        case 4110: return "Longs are not allowed in the expert properties";
        case 4111: return "Shorts are not allowed in the expert properties";
        case 10004: return "Requote";
        case 10006: return "Request rejected";
        case 10007: return "Request canceled by trader";
        case 10008: return "Order placed";
        case 10009: return "Order accepted";
        case 10010: return "Request processing";
        case 10011: return "Request canceled by timeout";
        case 10012: return "Invalid request";
        case 10013: return "Invalid volume in the request";
        case 10014: return "Invalid price in the request";
        case 10015: return "Invalid stops in the request";
        case 10016: return "Trade is disabled";
        case 10017: return "Market is closed";
        case 10018: return "There is not enough money to complete the request";
        case 10019: return "Price changed";
        case 10020: return "There are no quotes to process the request";
        case 10021: return "Invalid order expiration date in the request";
        case 10022: return "Order state changed";
        case 10023: return "Too frequent requests";
        case 10024: return "No changes in request";
        case 10025: return "Autotrading disabled by server";
        case 10026: return "Autotrading disabled by client terminal";
        case 10027: return "Request locked for processing";
        case 10028: return "Order or position frozen";
        case 10029: return "Invalid order filling type";
        case 10030: return "No connection to trade server";
        case 10031: return "Operation is allowed only for live accounts";
        case 10032: return "The number of pending orders has reached the limit";
        case 10033: return "The volume of orders and positions for the symbol has reached the limit";
        case 10034: return "Incorrect or prohibited order type";
        case 10035: return "Position with the specified POSITION_IDENTIFIER has already been closed";
        case 10036: return "A close volume exceeds the current position volume";
        case 10038: return "A close volume is too small";
        case 10039: return "The position specified in the request is not found";
        case 10040: return "The specified filling mode is incompatible with the current position";
        case 10041: return "Trading is disabled";
        case 10042: return "Trading for this symbol is disabled";
        case 10043: return "Requests are too frequent";
        default: return "Unknown error " + IntegerToString(errorCode);
    }
}

//+------------------------------------------------------------------+
//| Start performance timer                                         |
//+------------------------------------------------------------------+
static void CUtilitiesEnhanced::StartTimer(string timerName) {
    if(m_timerCount < ArraySize(m_timers)) {
        m_timerNames[m_timerCount] = timerName;
        m_timers[m_timerCount] = GetTickCount();
        m_timerCount++;
    }
}

//+------------------------------------------------------------------+
//| End performance timer and return elapsed time                  |
//+------------------------------------------------------------------+
static ulong CUtilitiesEnhanced::EndTimer(string timerName) {
    for(int i = 0; i < m_timerCount; i++) {
        if(m_timerNames[i] == timerName) {
            ulong elapsed = GetTickCount() - m_timers[i];
            
            // Remove timer from array
            for(int j = i; j < m_timerCount - 1; j++) {
                m_timerNames[j] = m_timerNames[j + 1];
                m_timers[j] = m_timers[j + 1];
            }
            m_timerCount--;
            
            return elapsed;
        }
    }
    
    return 0;
}

//+------------------------------------------------------------------+