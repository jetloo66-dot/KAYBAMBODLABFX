//+------------------------------------------------------------------+
//|                                    AdvancedZoneStructureEA.mq5 |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                          Advanced Multi-Phase Zone-Based Trading |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Advanced Multi-Phase Zone-Based Trading EA"
#property description "Combines swing detection, support/resistance zones, candle patterns, and market structure"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                      |
//+------------------------------------------------------------------+
enum ENUM_STRUCTURE_TYPE {
    STRUCTURE_NONE = 0,
    STRUCTURE_HH,          // Higher High
    STRUCTURE_HL,          // Higher Low
    STRUCTURE_LH,          // Lower High
    STRUCTURE_LL           // Lower Low
};

enum ENUM_PATTERN_TYPE {
    PATTERN_NONE = 0,
    PATTERN_PIN_BAR_BULLISH,
    PATTERN_PIN_BAR_BEARISH,
    PATTERN_ENGULFING_BULLISH,
    PATTERN_ENGULFING_BEARISH,
    PATTERN_INSIDE_BAR,
    PATTERN_REJECTION_BULLISH,
    PATTERN_REJECTION_BEARISH
};

enum ENUM_TREND_STATE {
    TREND_RANGING = 0,
    TREND_UPTREND,
    TREND_DOWNTREND
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Grouped by Phase                              |
//+------------------------------------------------------------------+

// === ZONE DETECTION ===
input group "=== ZONE DETECTION ==="
input int    ZoneLookbackBars = 100;           // Bars to scan for zones
input int    ZoneFractalRadius = 2;            // Fractal detection radius
input int    ZoneMinTouches = 2;               // Minimum touches for valid zone
input int    ZoneThicknessPoints = 50;         // Zone thickness in points
input int    ZoneRecalcBars = 5;               // Recalculate zones every N bars
input int    ZoneProximityPoints = 10;         // Price proximity to zone for entry

// === STRUCTURE ANALYSIS ===
input group "=== STRUCTURE ANALYSIS ==="
input int    StructureSwingBars = 5;           // Bars for swing detection
input int    StructureConfirmBars = 3;         // Bars to confirm structure
input bool   RequireHHForBuy = false;          // Require HH for buy signals
input bool   RequireHLForBuy = true;           // Require HL for buy signals
input bool   RequireLHForSell = true;          // Require LH for sell signals
input bool   RequireLLForSell = false;         // Require LL for sell signals

// === PATTERN DETECTION ===
input group "=== PATTERN DETECTION ==="
input bool   EnablePinBars = true;             // Enable pin bar detection
input bool   EnableEngulfing = true;           // Enable engulfing detection
input double PinBarRatio = 0.66;               // Pin bar wick/body ratio
input double EngulfingRatio = 1.1;             // Engulfing size ratio
input bool   RequirePatternAtZone = true;      // Pattern must form at zone

// === ENTRY LOGIC ===
input group "=== ENTRY LOGIC ==="
input bool   EnableStrategyA = true;           // Zone Touch + Structure
input bool   EnableStrategyB = true;           // BOS + Retracement
input bool   EnableStrategyC = true;           // Pattern + Zone Confluence
input int    MinConfluenceScore = 70;          // Minimum confluence score (0-100)

// === TRADE MANAGEMENT ===
input group "=== TRADE MANAGEMENT ==="
input double LotSize = 0.1;                    // Fixed lot size
input bool   UseRiskPercent = false;           // Use % risk position sizing
input double RiskPercent = 1.0;                // Risk per trade (%)
input int    SLPoints = 100;                   // Stop loss in points
input int    TPPoints = 300;                   // Take profit in points
input bool   UseDynamicSL = true;              // SL based on zone/pattern
input bool   UseDynamicTP = true;              // TP based on next zone
input double RiskRewardRatio = 3.0;            // Risk:Reward ratio
input int    TrailingStopPoints = 50;          // Trailing stop distance
input int    BreakEvenPoints = 150;            // Profit to trigger BE
input int    BreakEvenOffsetPoints = 10;       // BE offset

// === RISK MANAGEMENT ===
input group "=== RISK MANAGEMENT ==="
input int    MaxPositions = 3;                 // Max open positions
input double MaxDailyLossPercent = 5.0;        // Max daily loss %
input int    MaxSpreadPoints = 30;             // Max allowed spread
input bool   OneTradePerBar = true;            // One signal per bar
input bool   TradeOnNewBarOnly = true;         // Trade only on new bar

// === SESSION FILTER ===
input group "=== SESSION FILTER ==="
input bool   UseSessionFilter = false;         // Enable session filter
input int    SessionStartHour = 0;             // Trading start hour
input int    SessionEndHour = 23;              // Trading end hour
input bool   TradeMon = true;                  // Trade on Monday
input bool   TradeTue = true;                  // Trade on Tuesday
input bool   TradeWed = true;                  // Trade on Wednesday
input bool   TradeThu = true;                  // Trade on Thursday
input bool   TradeFri = true;                  // Trade on Friday

// === VISUALIZATION ===
input group "=== VISUALIZATION ==="
input bool   ShowZones = true;                 // Show zones on chart
input bool   ShowStructure = true;             // Show structure points
input bool   ShowPatterns = true;              // Show patterns
input bool   ShowTradeInfo = true;             // Show trade info panel
input color  SupportColor = clrDodgerBlue;     // Support zone color
input color  ResistanceColor = clrCrimson;     // Resistance zone color

// === NOTIFICATIONS ===
input group "=== NOTIFICATIONS ==="
input bool   EnableTelegram = false;           // Enable Telegram
input string TelegramToken = "";               // Bot token
input string TelegramChatID = "";              // Chat ID

// === SYSTEM ===
input group "=== SYSTEM ==="
input int    MagicNumber = 999888;             // Magic number

//+------------------------------------------------------------------+
//| STRUCTURES                                                        |
//+------------------------------------------------------------------+

// Zone Structure
struct TradingZone {
    double topPrice;          // Zone upper boundary
    double bottomPrice;       // Zone lower boundary
    datetime firstTouch;      // First time price touched this zone
    datetime lastTouch;       // Most recent touch
    int touchCount;           // Number of times price touched zone
    int strength;             // Zone strength score (0-100)
    bool isSupport;           // Is this a support zone?
    bool isResistance;        // Is this a resistance zone?
    bool isActive;            // Is zone still valid?
    int barIndex;             // Bar where zone formed
};
// Structure Point
struct StructurePoint {
    datetime time;
    double price;
    int barIndex;
    ENUM_STRUCTURE_TYPE type;  // HH, HL, LH, LL
    bool isHigh;               // Is this a swing high?
    int strength;              // Swing strength
};

// Candle Pattern
struct CandlePattern {
    ENUM_PATTERN_TYPE type;    // Pattern type
    bool isBullish;
    bool isBearish;
    double patternHigh;
    double patternLow;
    int barIndex;
    int strength;              // Pattern strength (0-100)
    bool atZone;               // Did pattern form at a zone?
};

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                  |
//+------------------------------------------------------------------+

CTrade trade;

// Zone arrays - Top 3 for each type
TradingZone supportZones[3];
TradingZone resistanceZones[3];

// Structure tracking
StructurePoint structurePoints[10];  // Last 10 structure points
int structurePointCount = 0;

// Current market state
ENUM_TREND_STATE currentTrend = TREND_RANGING;
bool bosOccurred = false;
bool bosIsBullish = false;
datetime bosTime = 0;

// Trade tracking
datetime lastBarTime = 0;
datetime lastTradeBarTime = 0;
double dailyStartBalance = 0;
double dailyLoss = 0;
datetime currentDay = 0;

// Visualization object names prefix
string objPrefix = "AZSE_";

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit() {
    // Initialize trade object
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetDeviationInPoints(10);
    trade.SetTypeFilling(ORDER_FILLING_FOK);
    
    // Initialize daily tracking
    dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    currentDay = TimeCurrent();
    
    // Initialize zones
    for(int i = 0; i < 3; i++) {
        supportZones[i].isActive = false;
        resistanceZones[i].isActive = false;
    }
    
    // Initialize structure points
    for(int i = 0; i < 10; i++) {
        structurePoints[i].type = STRUCTURE_NONE;
    }
    
    Print("Advanced Zone Structure EA initialized successfully");
    Print("Magic Number: ", MagicNumber);
    Print("Symbol: ", _Symbol);
    Print("Timeframe: ", EnumToString(_Period));
    
    // Initial zone detection
    Phase1_DetectZones();
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Remove all visualization objects
    ObjectsDeleteAll(0, objPrefix);
    
    Print("Advanced Zone Structure EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    // Check if new bar has formed
    bool isNewBar = IsNewBar();
    
    // Update daily tracking
    UpdateDailyTracking();
    
    // Phase 1: Update zones periodically
    if(isNewBar) {
        static int barCounter = 0;
        barCounter++;
        if(barCounter >= ZoneRecalcBars) {
            Phase1_DetectZones();
            barCounter = 0;
        }
    }
    
    // Phase 2: Analyze market structure
    if(isNewBar) {
        Phase2_AnalyzeStructure();
    }
    
    // Phase 3: Detect patterns
    CandlePattern currentPattern;
    if(isNewBar) {
        currentPattern = Phase3_DetectPatterns();
    }
    
    // Phase 4: Generate signals (only on new bar if required)
    if(!TradeOnNewBarOnly || isNewBar) {
        Phase4_GenerateSignals();
    }
    
    // Phase 5: Manage open trades
    Phase5_ManageTrades();
    
    // Update visualization
    if(ShowZones) DrawZones();
    if(ShowStructure) DrawStructure();
    if(ShowTradeInfo) DrawTradeInfo();
}

//+------------------------------------------------------------------+
//| PHASE 1: ZONE DETECTION & MANAGEMENT                             |
//+------------------------------------------------------------------+

void Phase1_DetectZones() {
    // Detect fractal-based support/resistance zones
    
    // Temporary arrays to store all detected zones
    TradingZone tempSupport[];
    TradingZone tempResistance[];
    ArrayResize(tempSupport, 0);
    ArrayResize(tempResistance, 0);
    
    // Scan for fractal pivots
    for(int i = ZoneFractalRadius; i < ZoneLookbackBars; i++) {
        // Check for swing high (resistance)
        if(IsSwingHigh(i, ZoneFractalRadius)) {
            TradingZone zone;
            zone.topPrice = iHigh(_Symbol, _Period, i) + ZoneThicknessPoints * _Point;
            zone.bottomPrice = iHigh(_Symbol, _Period, i);
            zone.firstTouch = iTime(_Symbol, _Period, i);
            zone.lastTouch = iTime(_Symbol, _Period, i);
            zone.touchCount = 1;
            zone.isSupport = false;
            zone.isResistance = true;
            zone.isActive = true;
            zone.barIndex = i;
            zone.strength = CalculateZoneStrength(zone, false);
            
            // Count touches
            zone.touchCount = CountZoneTouches(zone);
            
            // Only add if meets minimum touches
            if(zone.touchCount >= ZoneMinTouches) {
                int size = ArraySize(tempResistance);
                ArrayResize(tempResistance, size + 1);
                tempResistance[size] = zone;
            }
        }
        
        // Check for swing low (support)
        if(IsSwingLow(i, ZoneFractalRadius)) {
            TradingZone zone;
            zone.topPrice = iLow(_Symbol, _Period, i);
            zone.bottomPrice = iLow(_Symbol, _Period, i) - ZoneThicknessPoints * _Point;
            zone.firstTouch = iTime(_Symbol, _Period, i);
            zone.lastTouch = iTime(_Symbol, _Period, i);
            zone.touchCount = 1;
            zone.isSupport = true;
            zone.isResistance = false;
            zone.isActive = true;
            zone.barIndex = i;
            zone.strength = CalculateZoneStrength(zone, true);
            
            // Count touches
            zone.touchCount = CountZoneTouches(zone);
            
            // Only add if meets minimum touches
            if(zone.touchCount >= ZoneMinTouches) {
                int size = ArraySize(tempSupport);
                ArrayResize(tempSupport, size + 1);
                tempSupport[size] = zone;
            }
        }
    }
    
    // Rank and select top 3 support zones
    RankZones(tempSupport, true);
    for(int i = 0; i < 3 && i < ArraySize(tempSupport); i++) {
        supportZones[i] = tempSupport[i];
    }
    
    // Rank and select top 3 resistance zones
    RankZones(tempResistance, false);
    for(int i = 0; i < 3 && i < ArraySize(tempResistance); i++) {
        resistanceZones[i] = tempResistance[i];
    }
    
    Print("Zones detected - Support: ", ArraySize(tempSupport), " Resistance: ", ArraySize(tempResistance));
}

bool IsSwingHigh(int index, int radius) {
    double centerHigh = iHigh(_Symbol, _Period, index);
    
    for(int i = 1; i <= radius; i++) {
        if(iHigh(_Symbol, _Period, index - i) >= centerHigh) return false;
        if(iHigh(_Symbol, _Period, index + i) >= centerHigh) return false;
    }
    
    return true;
}

bool IsSwingLow(int index, int radius) {
    double centerLow = iLow(_Symbol, _Period, index);
    
    for(int i = 1; i <= radius; i++) {
        if(iLow(_Symbol, _Period, index - i) <= centerLow) return false;
        if(iLow(_Symbol, _Period, index + i) <= centerLow) return false;
    }
    
    return true;
}

int CountZoneTouches(TradingZone &zone) {
    int touches = 0;
    
    for(int i = 0; i < ZoneLookbackBars; i++) {
        double high = iHigh(_Symbol, _Period, i);
        double low = iLow(_Symbol, _Period, i);
        
        // Check if price touched the zone
        if(zone.isSupport) {
            if(low <= zone.topPrice && low >= zone.bottomPrice) {
                touches++;
                zone.lastTouch = iTime(_Symbol, _Period, i);
            }
        } else {
            if(high >= zone.bottomPrice && high <= zone.topPrice) {
                touches++;
                zone.lastTouch = iTime(_Symbol, _Period, i);
            }
        }
    }
    
    return touches;
}

int CalculateZoneStrength(TradingZone &zone, bool isSupport) {
    int strength = 0;
    
    // Base strength from touches (up to 40 points)
    strength += MathMin(zone.touchCount * 10, 40);
    
    // Recency bonus (up to 30 points)
    int barsSinceTouch = Bars(_Symbol, _Period, zone.lastTouch, TimeCurrent());
    if(barsSinceTouch < 10) strength += 30;
    else if(barsSinceTouch < 50) strength += 20;
    else if(barsSinceTouch < 100) strength += 10;
    
    // Age factor (up to 30 points) - older zones are stronger
    int barsSinceCreation = zone.barIndex;
    if(barsSinceCreation > 80) strength += 30;
    else if(barsSinceCreation > 50) strength += 20;
    else if(barsSinceCreation > 20) strength += 10;
    
    return MathMin(strength, 100);
}

void RankZones(TradingZone &zones[], bool isSupport) {
    int size = ArraySize(zones);
    
    // Simple bubble sort by strength
    for(int i = 0; i < size - 1; i++) {
        for(int j = 0; j < size - i - 1; j++) {
            if(zones[j].strength < zones[j + 1].strength) {
                TradingZone temp = zones[j];
                zones[j] = zones[j + 1];
                zones[j + 1] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| PHASE 2: MARKET STRUCTURE ANALYSIS                               |
//+------------------------------------------------------------------+

void Phase2_AnalyzeStructure() {
    // Detect swing points and structure
    
    // Look for swing highs and lows
    for(int i = StructureSwingBars; i < StructureSwingBars + 50; i++) {
        // Check for swing high
        if(IsSwingHigh(i, StructureSwingBars)) {
            double swingHigh = iHigh(_Symbol, _Period, i);
            ENUM_STRUCTURE_TYPE type = DetermineStructureType(swingHigh, true);
            
            if(type != STRUCTURE_NONE) {
                AddStructurePoint(iTime(_Symbol, _Period, i), swingHigh, i, type, true);
            }
        }
        
        // Check for swing low
        if(IsSwingLow(i, StructureSwingBars)) {
            double swingLow = iLow(_Symbol, _Period, i);
            ENUM_STRUCTURE_TYPE type = DetermineStructureType(swingLow, false);
            
            if(type != STRUCTURE_NONE) {
                AddStructurePoint(iTime(_Symbol, _Period, i), swingLow, i, type, false);
            }
        }
    }
    
    // Determine current trend
    currentTrend = DetermineTrend();
    
    // Check for Break of Structure
    CheckForBOS();
}

ENUM_STRUCTURE_TYPE DetermineStructureType(double price, bool isHigh) {
    // Find last relevant structure point
    StructurePoint lastHigh, lastLow;
    bool foundHigh = false, foundLow = false;
    
    for(int i = 0; i < structurePointCount; i++) {
        if(structurePoints[i].isHigh && !foundHigh) {
            lastHigh = structurePoints[i];
            foundHigh = true;
        }
        if(!structurePoints[i].isHigh && !foundLow) {
            lastLow = structurePoints[i];
            foundLow = true;
        }
        if(foundHigh && foundLow) break;
    }
    
    if(isHigh) {
        if(!foundHigh) return STRUCTURE_HH;  // First high
        
        if(price > lastHigh.price) return STRUCTURE_HH;  // Higher High
        else return STRUCTURE_LH;  // Lower High
    } else {
        if(!foundLow) return STRUCTURE_HL;  // First low
        
        if(price > lastLow.price) return STRUCTURE_HL;  // Higher Low
        else return STRUCTURE_LL;  // Lower Low
    }
}

void AddStructurePoint(datetime time, double price, int barIdx, ENUM_STRUCTURE_TYPE type, bool isHigh) {
    // Check if point already exists
    for(int i = 0; i < structurePointCount; i++) {
        if(structurePoints[i].barIndex == barIdx) return;  // Already recorded
    }
    
    // Shift array and add new point at beginning
    for(int i = 9; i > 0; i--) {
        structurePoints[i] = structurePoints[i - 1];
    }
    
    structurePoints[0].time = time;
    structurePoints[0].price = price;
    structurePoints[0].barIndex = barIdx;
    structurePoints[0].type = type;
    structurePoints[0].isHigh = isHigh;
    structurePoints[0].strength = 50;  // Base strength
    
    if(structurePointCount < 10) structurePointCount++;
}

ENUM_TREND_STATE DetermineTrend() {
    int hhCount = 0, hlCount = 0, lhCount = 0, llCount = 0;
    
    for(int i = 0; i < MathMin(structurePointCount, 6); i++) {
        switch(structurePoints[i].type) {
            case STRUCTURE_HH: hhCount++; break;
            case STRUCTURE_HL: hlCount++; break;
            case STRUCTURE_LH: lhCount++; break;
            case STRUCTURE_LL: llCount++; break;
        }
    }
    
    // Uptrend: More HH and HL
    if(hhCount >= 2 && hlCount >= 1) return TREND_UPTREND;
    
    // Downtrend: More LH and LL
    if(lhCount >= 2 && llCount >= 1) return TREND_DOWNTREND;
    
    return TREND_RANGING;
}

void CheckForBOS() {
    // Break of Structure occurs when price breaks a key level
    
    if(structurePointCount < 2) return;
    
    double currentClose = iClose(_Symbol, _Period, 0);
    
    // Check for bullish BOS (close above last LH)
    for(int i = 0; i < structurePointCount; i++) {
        if(structurePoints[i].type == STRUCTURE_LH) {
            if(currentClose > structurePoints[i].price && 
               iClose(_Symbol, _Period, 1) <= structurePoints[i].price) {
                bosOccurred = true;
                bosIsBullish = true;
                bosTime = TimeCurrent();
                Print("Bullish BOS detected at price: ", currentClose);
                return;
            }
        }
    }
    
    // Check for bearish BOS (close below last HL)
    for(int i = 0; i < structurePointCount; i++) {
        if(structurePoints[i].type == STRUCTURE_HL) {
            if(currentClose < structurePoints[i].price && 
               iClose(_Symbol, _Period, 1) >= structurePoints[i].price) {
                bosOccurred = true;
                bosIsBullish = false;
                bosTime = TimeCurrent();
                Print("Bearish BOS detected at price: ", currentClose);
                return;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| PHASE 3: CANDLE PATTERN RECOGNITION                              |
//+------------------------------------------------------------------+

CandlePattern Phase3_DetectPatterns() {
    CandlePattern pattern;
    pattern.type = PATTERN_NONE;
    pattern.isBullish = false;
    pattern.isBearish = false;
    pattern.barIndex = 1;
    pattern.strength = 0;
    pattern.atZone = false;
    
    int barIndex = 1;  // Check completed bar
    
    // Check if price is at a zone
    bool atSupportZone = IsPriceAtZone(true, barIndex);
    bool atResistanceZone = IsPriceAtZone(false, barIndex);
    
    if(RequirePatternAtZone && !atSupportZone && !atResistanceZone) {
        return pattern;  // No pattern if not at zone and required
    }
    
    // Detect Pin Bars
    if(EnablePinBars) {
        if(IsPinBar(barIndex, true)) {
            pattern.type = PATTERN_PIN_BAR_BULLISH;
            pattern.isBullish = true;
            pattern.strength = CalculatePatternStrength(pattern.type, barIndex);
            pattern.atZone = atSupportZone;
            pattern.patternHigh = iHigh(_Symbol, _Period, barIndex);
            pattern.patternLow = iLow(_Symbol, _Period, barIndex);
            return pattern;
        }
        
        if(IsPinBar(barIndex, false)) {
            pattern.type = PATTERN_PIN_BAR_BEARISH;
            pattern.isBearish = true;
            pattern.strength = CalculatePatternStrength(pattern.type, barIndex);
            pattern.atZone = atResistanceZone;
            pattern.patternHigh = iHigh(_Symbol, _Period, barIndex);
            pattern.patternLow = iLow(_Symbol, _Period, barIndex);
            return pattern;
        }
    }
    
    // Detect Engulfing
    if(EnableEngulfing) {
        if(IsEngulfing(barIndex, true)) {
            pattern.type = PATTERN_ENGULFING_BULLISH;
            pattern.isBullish = true;
            pattern.strength = CalculatePatternStrength(pattern.type, barIndex);
            pattern.atZone = atSupportZone;
            pattern.patternHigh = iHigh(_Symbol, _Period, barIndex);
            pattern.patternLow = iLow(_Symbol, _Period, barIndex);
            return pattern;
        }
        
        if(IsEngulfing(barIndex, false)) {
            pattern.type = PATTERN_ENGULFING_BEARISH;
            pattern.isBearish = true;
            pattern.strength = CalculatePatternStrength(pattern.type, barIndex);
            pattern.atZone = atResistanceZone;
            pattern.patternHigh = iHigh(_Symbol, _Period, barIndex);
            pattern.patternLow = iLow(_Symbol, _Period, barIndex);
            return pattern;
        }
    }
    
    // Detect Inside Bar
    if(IsInsideBar(barIndex)) {
        pattern.type = PATTERN_INSIDE_BAR;
        pattern.strength = CalculatePatternStrength(pattern.type, barIndex);
        pattern.atZone = atSupportZone || atResistanceZone;
        pattern.patternHigh = iHigh(_Symbol, _Period, barIndex);
        pattern.patternLow = iLow(_Symbol, _Period, barIndex);
        return pattern;
    }
    
    return pattern;
}

bool IsPinBar(int index, bool bullish) {
    double open = iOpen(_Symbol, _Period, index);
    double close = iClose(_Symbol, _Period, index);
    double high = iHigh(_Symbol, _Period, index);
    double low = iLow(_Symbol, _Period, index);
    
    double body = MathAbs(close - open);
    double range = high - low;
    
    if(range == 0 || body == 0) return false;
    
    if(bullish) {
        double lowerWick = MathMin(open, close) - low;
        double upperWick = high - MathMax(open, close);
        
        // Bullish pin: long lower wick, small body
        return (lowerWick / body >= PinBarRatio && upperWick < body && close > open);
    } else {
        double upperWick = high - MathMax(open, close);
        double lowerWick = MathMin(open, close) - low;
        
        // Bearish pin: long upper wick, small body
        return (upperWick / body >= PinBarRatio && lowerWick < body && close < open);
    }
}

bool IsEngulfing(int index, bool bullish) {
    double open1 = iOpen(_Symbol, _Period, index);
    double close1 = iClose(_Symbol, _Period, index);
    double open2 = iOpen(_Symbol, _Period, index + 1);
    double close2 = iClose(_Symbol, _Period, index + 1);
    
    double body1 = MathAbs(close1 - open1);
    double body2 = MathAbs(close2 - open2);
    
    if(body2 == 0) return false;
    
    if(bullish) {
        // Bullish engulfing: current bullish candle engulfs previous bearish
        return (close1 > open1 && close2 < open2 && 
                close1 > open2 && open1 < close2 &&
                body1 / body2 >= EngulfingRatio);
    } else {
        // Bearish engulfing: current bearish candle engulfs previous bullish
        return (close1 < open1 && close2 > open2 && 
                close1 < open2 && open1 > close2 &&
                body1 / body2 >= EngulfingRatio);
    }
}

bool IsInsideBar(int index) {
    double high1 = iHigh(_Symbol, _Period, index);
    double low1 = iLow(_Symbol, _Period, index);
    double high2 = iHigh(_Symbol, _Period, index + 1);
    double low2 = iLow(_Symbol, _Period, index + 1);
    
    // Current bar is inside previous bar
    return (high1 < high2 && low1 > low2);
}

bool IsPriceAtZone(bool checkSupport, int index) {
    double price = checkSupport ? iLow(_Symbol, _Period, index) : iHigh(_Symbol, _Period, index);
    double proximity = ZoneProximityPoints * _Point;
    
    if(checkSupport) {
        for(int i = 0; i < 3; i++) {
            if(supportZones[i].isActive) {
                if(price >= supportZones[i].bottomPrice - proximity && 
                   price <= supportZones[i].topPrice + proximity) {
                    return true;
                }
            }
        }
    } else {
        for(int i = 0; i < 3; i++) {
            if(resistanceZones[i].isActive) {
                if(price >= resistanceZones[i].bottomPrice - proximity && 
                   price <= resistanceZones[i].topPrice + proximity) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

int CalculatePatternStrength(ENUM_PATTERN_TYPE patternType, int index) {
    int strength = 50;  // Base strength
    
    // Pattern-specific strength adjustments
    switch(patternType) {
        case PATTERN_PIN_BAR_BULLISH:
        case PATTERN_PIN_BAR_BEARISH:
            strength = 70;  // Pin bars are strong
            break;
        case PATTERN_ENGULFING_BULLISH:
        case PATTERN_ENGULFING_BEARISH:
            strength = 80;  // Engulfing very strong
            break;
        case PATTERN_INSIDE_BAR:
            strength = 40;  // Inside bars weaker
            break;
    }
    
    // Boost if at a zone
    if(IsPriceAtZone(true, index) || IsPriceAtZone(false, index)) {
        strength += 20;
    }
    
    return MathMin(strength, 100);
}

//+------------------------------------------------------------------+
//| PHASE 4: SIGNAL GENERATION (Multi-Confirmation Entry Logic)      |
//+------------------------------------------------------------------+

void Phase4_GenerateSignals() {
    // Check risk before generating signals
    if(!Phase6_CheckRisk()) return;
    
    // Check session filter
    if(UseSessionFilter && !IsWithinSession()) return;
    
    // Check one trade per bar
    if(OneTradePerBar && lastTradeBarTime == iTime(_Symbol, _Period, 0)) return;
    
    // Strategy A: Zone Touch + Structure
    if(EnableStrategyA) {
        CheckStrategyA();
    }
    
    // Strategy B: BOS + Retracement
    if(EnableStrategyB) {
        CheckStrategyB();
    }
    
    // Strategy C: Pattern + Zone Confluence
    if(EnableStrategyC) {
        CheckStrategyC();
    }
}

void CheckStrategyA() {
    // Buy: Price touches support zone AND (HH formed OR HL detected)
    // Sell: Price touches resistance zone AND (LL formed OR LH detected)
    
    double currentPrice = iClose(_Symbol, _Period, 0);
    double lastClose = iClose(_Symbol, _Period, 1);
    
    // Check for buy signal
    bool atSupport = IsPriceAtZone(true, 1);
    bool hasStructure = false;
    
    if(atSupport) {
        for(int i = 0; i < structurePointCount; i++) {
            if((RequireHHForBuy && structurePoints[i].type == STRUCTURE_HH) ||
               (RequireHLForBuy && structurePoints[i].type == STRUCTURE_HL)) {
                hasStructure = true;
                break;
            }
        }
        
        // Confirm with bearish to bullish reversal
        bool reversalConfirm = lastClose < iOpen(_Symbol, _Period, 1) && 
                               currentPrice > iOpen(_Symbol, _Period, 0);
        
        if(hasStructure && reversalConfirm) {
            int confluence = CalculateConfluenceScore(true, true, false);
            if(confluence >= MinConfluenceScore) {
                ExecuteTrade(ORDER_TYPE_BUY, "Strategy A: Zone+Structure", confluence);
            }
        }
    }
    
    // Check for sell signal
    bool atResistance = IsPriceAtZone(false, 1);
    hasStructure = false;
    
    if(atResistance) {
        for(int i = 0; i < structurePointCount; i++) {
            if((RequireLHForSell && structurePoints[i].type == STRUCTURE_LH) ||
               (RequireLLForSell && structurePoints[i].type == STRUCTURE_LL)) {
                hasStructure = true;
                break;
            }
        }
        
        // Confirm with bullish to bearish reversal
        bool reversalConfirm = lastClose > iOpen(_Symbol, _Period, 1) && 
                               currentPrice < iOpen(_Symbol, _Period, 0);
        
        if(hasStructure && reversalConfirm) {
            int confluence = CalculateConfluenceScore(false, true, false);
            if(confluence >= MinConfluenceScore) {
                ExecuteTrade(ORDER_TYPE_SELL, "Strategy A: Zone+Structure", confluence);
            }
        }
    }
}

void CheckStrategyB() {
    // Buy: After BOS buy, wait for retracement to HL region, then enter on bullish candle
    // Sell: After BOS sell, wait for retracement to LH region, then enter on bearish candle
    
    if(!bosOccurred) return;
    
    // Check if BOS is recent (within last 20 bars)
    int barsSinceBOS = Bars(_Symbol, _Period, bosTime, TimeCurrent());
    if(barsSinceBOS > 20) return;
    
    double currentClose = iClose(_Symbol, _Period, 0);
    double lastClose = iClose(_Symbol, _Period, 1);
    
    if(bosIsBullish) {
        // Find last HL for retracement target
        double hlPrice = 0;
        for(int i = 0; i < structurePointCount; i++) {
            if(structurePoints[i].type == STRUCTURE_HL) {
                hlPrice = structurePoints[i].price;
                break;
            }
        }
        
        if(hlPrice > 0) {
            double proximity = ZoneProximityPoints * _Point * 2;
            bool atRetracement = currentClose >= hlPrice - proximity && 
                                currentClose <= hlPrice + proximity;
            bool bullishCandle = currentClose > iOpen(_Symbol, _Period, 0);
            
            if(atRetracement && bullishCandle) {
                int confluence = CalculateConfluenceScore(true, true, true);
                if(confluence >= MinConfluenceScore) {
                    ExecuteTrade(ORDER_TYPE_BUY, "Strategy B: BOS+Retracement", confluence);
                }
            }
        }
    } else {
        // Find last LH for retracement target
        double lhPrice = 0;
        for(int i = 0; i < structurePointCount; i++) {
            if(structurePoints[i].type == STRUCTURE_LH) {
                lhPrice = structurePoints[i].price;
                break;
            }
        }
        
        if(lhPrice > 0) {
            double proximity = ZoneProximityPoints * _Point * 2;
            bool atRetracement = currentClose >= lhPrice - proximity && 
                                currentClose <= lhPrice + proximity;
            bool bearishCandle = currentClose < iOpen(_Symbol, _Period, 0);
            
            if(atRetracement && bearishCandle) {
                int confluence = CalculateConfluenceScore(false, true, true);
                if(confluence >= MinConfluenceScore) {
                    ExecuteTrade(ORDER_TYPE_SELL, "Strategy B: BOS+Retracement", confluence);
                }
            }
        }
    }
}

void CheckStrategyC() {
    // Buy: Bullish pin bar OR bullish engulfing forms AT support zone
    // Sell: Bearish pin bar OR bearish engulfing forms AT resistance zone
    
    CandlePattern pattern = Phase3_DetectPatterns();
    
    if(pattern.type == PATTERN_NONE) return;
    
    // Buy patterns at support
    if(pattern.isBullish && pattern.atZone) {
        int confluence = CalculateConfluenceScore(true, false, true);
        if(confluence >= MinConfluenceScore) {
            ExecuteTrade(ORDER_TYPE_BUY, "Strategy C: Pattern+Zone", confluence);
        }
    }
    
    // Sell patterns at resistance
    if(pattern.isBearish && pattern.atZone) {
        int confluence = CalculateConfluenceScore(false, false, true);
        if(confluence >= MinConfluenceScore) {
            ExecuteTrade(ORDER_TYPE_SELL, "Strategy C: Pattern+Zone", confluence);
        }
    }
}

int CalculateConfluenceScore(bool isBuy, bool hasStructure, bool hasPattern) {
    int score = 0;
    
    // Zone strength (0-30 points)
    if(isBuy) {
        for(int i = 0; i < 3; i++) {
            if(supportZones[i].isActive && IsPriceAtZone(true, 1)) {
                score += (supportZones[i].strength * 30) / 100;
                break;
            }
        }
    } else {
        for(int i = 0; i < 3; i++) {
            if(resistanceZones[i].isActive && IsPriceAtZone(false, 1)) {
                score += (resistanceZones[i].strength * 30) / 100;
                break;
            }
        }
    }
    
    // Structure alignment (0-25 points)
    if(hasStructure) {
        score += 25;
    }
    
    // Pattern strength (0-25 points)
    if(hasPattern) {
        CandlePattern pattern = Phase3_DetectPatterns();
        score += (pattern.strength * 25) / 100;
    }
    
    // Trend direction (0-10 points)
    if(isBuy && currentTrend == TREND_UPTREND) score += 10;
    if(!isBuy && currentTrend == TREND_DOWNTREND) score += 10;
    
    // Recent touches (0-10 points)
    if(isBuy) {
        for(int i = 0; i < 3; i++) {
            if(supportZones[i].isActive) {
                int barsSince = Bars(_Symbol, _Period, supportZones[i].lastTouch, TimeCurrent());
                if(barsSince < 10) score += 10;
                else if(barsSince < 30) score += 5;
                break;
            }
        }
    } else {
        for(int i = 0; i < 3; i++) {
            if(resistanceZones[i].isActive) {
                int barsSince = Bars(_Symbol, _Period, resistanceZones[i].lastTouch, TimeCurrent());
                if(barsSince < 10) score += 10;
                else if(barsSince < 30) score += 5;
                break;
            }
        }
    }
    
    return MathMin(score, 100);
}

//+------------------------------------------------------------------+
//| Execute Trade with Dynamic SL/TP                                 |
//+------------------------------------------------------------------+

void ExecuteTrade(ENUM_ORDER_TYPE orderType, string comment, int confluenceScore) {
    double price = (orderType == ORDER_TYPE_BUY) ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    double sl = 0, tp = 0;
    
    // Calculate lot size
    double lots = CalculateLotSize();
    
    // Calculate SL and TP
    if(orderType == ORDER_TYPE_BUY) {
        if(UseDynamicSL) {
            // SL below support zone or pattern low
            sl = price - (SLPoints * _Point);
            for(int i = 0; i < 3; i++) {
                if(supportZones[i].isActive) {
                    sl = supportZones[i].bottomPrice - (10 * _Point);
                    break;
                }
            }
        } else {
            sl = price - (SLPoints * _Point);
        }
        
        if(UseDynamicTP) {
            // TP at next resistance zone
            tp = sl + (MathAbs(price - sl) * RiskRewardRatio);
            for(int i = 0; i < 3; i++) {
                if(resistanceZones[i].isActive && resistanceZones[i].bottomPrice > price) {
                    tp = resistanceZones[i].bottomPrice;
                    break;
                }
            }
        } else {
            tp = price + (TPPoints * _Point);
        }
    } else {
        if(UseDynamicSL) {
            // SL above resistance zone or pattern high
            sl = price + (SLPoints * _Point);
            for(int i = 0; i < 3; i++) {
                if(resistanceZones[i].isActive) {
                    sl = resistanceZones[i].topPrice + (10 * _Point);
                    break;
                }
            }
        } else {
            sl = price + (SLPoints * _Point);
        }
        
        if(UseDynamicTP) {
            // TP at next support zone
            tp = sl - (MathAbs(sl - price) * RiskRewardRatio);
            for(int i = 0; i < 3; i++) {
                if(supportZones[i].isActive && supportZones[i].topPrice < price) {
                    tp = supportZones[i].topPrice;
                    break;
                }
            }
        } else {
            tp = price - (TPPoints * _Point);
        }
    }
    
    // Normalize prices
    sl = NormalizeDouble(sl, _Digits);
    tp = NormalizeDouble(tp, _Digits);
    lots = NormalizeDouble(lots, 2);
    
    // Execute trade
    string fullComment = comment + " | Score: " + IntegerToString(confluenceScore);
    
    if(orderType == ORDER_TYPE_BUY) {
        if(trade.Buy(lots, _Symbol, price, sl, tp, fullComment)) {
            Print("BUY order opened: ", fullComment, " SL:", sl, " TP:", tp);
            lastTradeBarTime = iTime(_Symbol, _Period, 0);
        } else {
            Print("Failed to open BUY order. Error: ", GetLastError());
        }
    } else {
        if(trade.Sell(lots, _Symbol, price, sl, tp, fullComment)) {
            Print("SELL order opened: ", fullComment, " SL:", sl, " TP:", tp);
            lastTradeBarTime = iTime(_Symbol, _Period, 0);
        } else {
            Print("Failed to open SELL order. Error: ", GetLastError());
        }
    }
}

double CalculateLotSize() {
    if(!UseRiskPercent) {
        return LotSize;
    }
    
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double riskAmount = accountBalance * (RiskPercent / 100.0);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double slPoints = SLPoints;
    
    if(tickValue == 0 || slPoints == 0) return LotSize;
    
    double lots = riskAmount / (slPoints * tickValue);
    
    // Check min/max lot sizes
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    lots = MathMax(lots, minLot);
    lots = MathMin(lots, maxLot);
    lots = MathFloor(lots / lotStep) * lotStep;
    
    return lots;
}

//+------------------------------------------------------------------+
//| PHASE 5: TRADE MANAGEMENT                                        |
//+------------------------------------------------------------------+

void Phase5_ManageTrades() {
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0) continue;
        
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        
        double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double posSL = PositionGetDouble(POSITION_SL);
        double posTP = PositionGetDouble(POSITION_TP);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        
        double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                              SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                              SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        double profit = currentPrice - posOpenPrice;
        if(posType == POSITION_TYPE_SELL) profit = posOpenPrice - currentPrice;
        
        double profitPoints = profit / _Point;
        
        // Break-even logic
        if(profitPoints >= BreakEvenPoints && posSL != posOpenPrice) {
            double newSL = posOpenPrice + (BreakEvenOffsetPoints * _Point);
            if(posType == POSITION_TYPE_SELL) {
                newSL = posOpenPrice - (BreakEvenOffsetPoints * _Point);
            }
            
            newSL = NormalizeDouble(newSL, _Digits);
            
            if(trade.PositionModify(ticket, newSL, posTP)) {
                Print("Position moved to break-even: ", ticket);
            }
        }
        
        // Trailing stop logic
        if(TrailingStopPoints > 0 && profitPoints > TrailingStopPoints) {
            double newSL = 0;
            
            if(posType == POSITION_TYPE_BUY) {
                newSL = currentPrice - (TrailingStopPoints * _Point);
                if(newSL > posSL) {
                    newSL = NormalizeDouble(newSL, _Digits);
                    if(trade.PositionModify(ticket, newSL, posTP)) {
                        Print("Trailing stop updated for BUY: ", ticket, " New SL: ", newSL);
                    }
                }
            } else {
                newSL = currentPrice + (TrailingStopPoints * _Point);
                if(newSL < posSL || posSL == 0) {
                    newSL = NormalizeDouble(newSL, _Digits);
                    if(trade.PositionModify(ticket, newSL, posTP)) {
                        Print("Trailing stop updated for SELL: ", ticket, " New SL: ", newSL);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| PHASE 6: RISK & POSITION MANAGEMENT                              |
//+------------------------------------------------------------------+

bool Phase6_CheckRisk() {
    // Check max positions
    int openPositions = 0;
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionGetTicket(i) > 0) {
            if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
                openPositions++;
            }
        }
    }
    
    if(openPositions >= MaxPositions) {
        return false;
    }
    
    // Check daily loss limit
    if(dailyLoss >= (dailyStartBalance * MaxDailyLossPercent / 100.0)) {
        Print("Daily loss limit reached: ", dailyLoss);
        return false;
    }
    
    // Check spread
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    if(spread > MaxSpreadPoints) {
        return false;
    }
    
    return true;
}

void UpdateDailyTracking() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    datetime today = StringToTime(IntegerToString(dt.year) + "." + 
                                   IntegerToString(dt.mon) + "." + 
                                   IntegerToString(dt.day));
    
    if(today != currentDay) {
        // New day - reset tracking
        currentDay = today;
        dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        dailyLoss = 0;
    } else {
        // Update daily loss
        double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        if(currentBalance < dailyStartBalance) {
            dailyLoss = dailyStartBalance - currentBalance;
        }
    }
}

bool IsWithinSession() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Check day of week
    bool tradingDay = false;
    switch(dt.day_of_week) {
        case 1: tradingDay = TradeMon; break;
        case 2: tradingDay = TradeTue; break;
        case 3: tradingDay = TradeWed; break;
        case 4: tradingDay = TradeThu; break;
        case 5: tradingDay = TradeFri; break;
    }
    
    if(!tradingDay) return false;
    
    // Check hour
    if(dt.hour < SessionStartHour || dt.hour > SessionEndHour) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| UTILITY FUNCTIONS                                                 |
//+------------------------------------------------------------------+

bool IsNewBar() {
    datetime currentBarTime = iTime(_Symbol, _Period, 0);
    if(currentBarTime != lastBarTime) {
        lastBarTime = currentBarTime;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| VISUALIZATION FUNCTIONS                                           |
//+------------------------------------------------------------------+

void DrawZones() {
    // Draw support zones
    for(int i = 0; i < 3; i++) {
        if(supportZones[i].isActive) {
            string name = objPrefix + "Support_" + IntegerToString(i);
            
            if(ObjectFind(0, name) < 0) {
                ObjectCreate(0, name, OBJ_RECTANGLE, 0, 
                           supportZones[i].firstTouch, supportZones[i].topPrice,
                           TimeCurrent() + PeriodSeconds(_Period) * 50, supportZones[i].bottomPrice);
                ObjectSetInteger(0, name, OBJPROP_COLOR, SupportColor);
                ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
                ObjectSetInteger(0, name, OBJPROP_BACK, true);
                ObjectSetInteger(0, name, OBJPROP_FILL, true);
                ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            } else {
                ObjectSetInteger(0, name, OBJPROP_TIME, 1, TimeCurrent() + PeriodSeconds(_Period) * 50);
            }
        }
    }
    
    // Draw resistance zones
    for(int i = 0; i < 3; i++) {
        if(resistanceZones[i].isActive) {
            string name = objPrefix + "Resistance_" + IntegerToString(i);
            
            if(ObjectFind(0, name) < 0) {
                ObjectCreate(0, name, OBJ_RECTANGLE, 0, 
                           resistanceZones[i].firstTouch, resistanceZones[i].topPrice,
                           TimeCurrent() + PeriodSeconds(_Period) * 50, resistanceZones[i].bottomPrice);
                ObjectSetInteger(0, name, OBJPROP_COLOR, ResistanceColor);
                ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
                ObjectSetInteger(0, name, OBJPROP_BACK, true);
                ObjectSetInteger(0, name, OBJPROP_FILL, true);
                ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            } else {
                ObjectSetInteger(0, name, OBJPROP_TIME, 1, TimeCurrent() + PeriodSeconds(_Period) * 50);
            }
        }
    }
}

void DrawStructure() {
    for(int i = 0; i < structurePointCount; i++) {
        string name = objPrefix + "Structure_" + IntegerToString(i);
        string label = "";
        color clr = clrWhite;
        
        switch(structurePoints[i].type) {
            case STRUCTURE_HH:
                label = "HH";
                clr = clrLime;
                break;
            case STRUCTURE_HL:
                label = "HL";
                clr = clrGreen;
                break;
            case STRUCTURE_LH:
                label = "LH";
                clr = clrOrange;
                break;
            case STRUCTURE_LL:
                label = "LL";
                clr = clrRed;
                break;
        }
        
        if(ObjectFind(0, name) < 0) {
            ObjectCreate(0, name, OBJ_TEXT, 0, structurePoints[i].time, structurePoints[i].price);
            ObjectSetString(0, name, OBJPROP_TEXT, label);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        }
    }
}

void DrawTradeInfo() {
    string name = objPrefix + "TradeInfo";
    
    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
    }
    
    string info = "Advanced Zone Structure EA\n";
    info += "Trend: " + EnumToString(currentTrend) + "\n";
    info += "Support Zones: ";
    for(int i = 0; i < 3; i++) {
        if(supportZones[i].isActive) {
            info += IntegerToString(supportZones[i].strength) + "% ";
        }
    }
    info += "\nResistance Zones: ";
    for(int i = 0; i < 3; i++) {
        if(resistanceZones[i].isActive) {
            info += IntegerToString(resistanceZones[i].strength) + "% ";
        }
    }
    info += "\nOpen Positions: " + IntegerToString(PositionsTotal());
    info += "\nDaily Loss: " + DoubleToString(dailyLoss, 2);
    
    ObjectSetString(0, name, OBJPROP_TEXT, info);
}

//+------------------------------------------------------------------+
