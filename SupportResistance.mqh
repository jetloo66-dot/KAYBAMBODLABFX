//+------------------------------------------------------------------+
//|                                         SupportResistance.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "SwingDetection.mqh"

//+------------------------------------------------------------------+
//| Support/Resistance Level Structure                               |
//+------------------------------------------------------------------+
struct SRLevel {
    double price;
    datetime firstTouch;
    datetime lastTouch;
    int touchCount;
    int strength;
    bool isSupport;
    bool isResistance;
    bool isActive;
    string description;
};

//+------------------------------------------------------------------+
//| Support/Resistance Manager Class                                 |
//+------------------------------------------------------------------+
class CSupportResistance {
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    int m_maxLevels;
    double m_clusterDistance;
    
    SRLevel m_levels[];
    CSwingDetection* m_swingDetector;
    
    // Private methods
    void AddLevel(double price, bool isSupport, bool isResistance, int strength);
    void MergeLevels();
    void UpdateLevelStrength();
    void CleanInactiveLevels();
    bool IsNearLevel(double price, double tolerance);
    
public:
    CSupportResistance(string symbol, ENUM_TIMEFRAMES timeframe, int maxLevels = 10);
    ~CSupportResistance();
    
    bool Initialize(CSwingDetection* swingDetector);
    void Update();
    
    // Getters
    int GetLevelCount() { return ArraySize(m_levels); }
    bool GetLevel(int index, SRLevel &level);
    bool GetNearestSupport(double price, SRLevel &level);
    bool GetNearestResistance(double price, SRLevel &level);
    
    // Analysis
    bool IsPriceAtSupport(double price, double tolerance = 0);
    bool IsPriceAtResistance(double price, double tolerance = 0);
    double GetStrongestSupport();
    double GetStrongestResistance();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSupportResistance::CSupportResistance(string symbol, ENUM_TIMEFRAMES timeframe, int maxLevels) {
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_maxLevels = maxLevels;
    m_swingDetector = NULL;
    
    // Cluster distance is 20 pips
    m_clusterDistance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 200;
    
    ArrayResize(m_levels, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSupportResistance::~CSupportResistance(void) {
    ArrayFree(m_levels);
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CSupportResistance::Initialize(CSwingDetection* swingDetector) {
    if(swingDetector == NULL) {
        Print("Error: Swing detector is NULL");
        return false;
    }
    
    m_swingDetector = swingDetector;
    Update();
    return true;
}

//+------------------------------------------------------------------+
//| Update support/resistance levels                                 |
//+------------------------------------------------------------------+
void CSupportResistance::Update(void) {
    if(m_swingDetector == NULL) return;
    
    // Get swing points from detector
    int highCount = m_swingDetector.GetSwingHighCount();
    int lowCount = m_swingDetector.GetSwingLowCount();
    
    // Add swing highs as potential resistance
    for(int i = 0; i < highCount; i++) {
        SwingPoint point;
        if(m_swingDetector.GetSwingHigh(i, point)) {
            AddLevel(point.price, false, true, point.strength);
        }
    }
    
    // Add swing lows as potential support
    for(int i = 0; i < lowCount; i++) {
        SwingPoint point;
        if(m_swingDetector.GetSwingLow(i, point)) {
            AddLevel(point.price, true, false, point.strength);
        }
    }
    
    // Merge close levels and update strength
    MergeLevels();
    UpdateLevelStrength();
    CleanInactiveLevels();
}

//+------------------------------------------------------------------+
//| Add a new level                                                  |
//+------------------------------------------------------------------+
void CSupportResistance::AddLevel(double price, bool isSupport, bool isResistance, int strength) {
    // Check if level already exists nearby
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(MathAbs(m_levels[i].price - price) < m_clusterDistance) {
            // Update existing level
            m_levels[i].touchCount++;
            m_levels[i].lastTouch = TimeCurrent();
            m_levels[i].strength = MathMax(m_levels[i].strength, strength);
            m_levels[i].isSupport = m_levels[i].isSupport || isSupport;
            m_levels[i].isResistance = m_levels[i].isResistance || isResistance;
            m_levels[i].isActive = true;
            return;
        }
    }
    
    // Add new level
    int size = ArraySize(m_levels);
    ArrayResize(m_levels, size + 1);
    
    m_levels[size].price = price;
    m_levels[size].firstTouch = TimeCurrent();
    m_levels[size].lastTouch = TimeCurrent();
    m_levels[size].touchCount = 1;
    m_levels[size].strength = strength;
    m_levels[size].isSupport = isSupport;
    m_levels[size].isResistance = isResistance;
    m_levels[size].isActive = true;
    
    if(isSupport && isResistance)
        m_levels[size].description = "Support/Resistance";
    else if(isSupport)
        m_levels[size].description = "Support";
    else
        m_levels[size].description = "Resistance";
}

//+------------------------------------------------------------------+
//| Merge close levels                                               |
//+------------------------------------------------------------------+
void CSupportResistance::MergeLevels(void) {
    int size = ArraySize(m_levels);
    if(size < 2) return;
    
    for(int i = 0; i < size - 1; i++) {
        if(!m_levels[i].isActive) continue;
        
        for(int j = i + 1; j < size; j++) {
            if(!m_levels[j].isActive) continue;
            
            if(MathAbs(m_levels[i].price - m_levels[j].price) < m_clusterDistance) {
                // Merge j into i
                m_levels[i].price = (m_levels[i].price * m_levels[i].touchCount + 
                                     m_levels[j].price * m_levels[j].touchCount) /
                                    (m_levels[i].touchCount + m_levels[j].touchCount);
                m_levels[i].touchCount += m_levels[j].touchCount;
                m_levels[i].strength = MathMax(m_levels[i].strength, m_levels[j].strength);
                m_levels[i].isSupport = m_levels[i].isSupport || m_levels[j].isSupport;
                m_levels[i].isResistance = m_levels[i].isResistance || m_levels[j].isResistance;
                m_levels[j].isActive = false;
            }
        }
    }
    
    // Remove inactive levels
    SRLevel temp[];
    int tempCount = 0;
    
    // Count active levels
    for(int i = 0; i < size; i++) {
        if(m_levels[i].isActive) {
            tempCount++;
        }
    }
    
    // Resize and copy active levels manually (ArrayCopy doesn't work with structures containing strings)
    ArrayResize(temp, tempCount);
    int tempIndex = 0;
    for(int i = 0; i < size; i++) {
        if(m_levels[i].isActive) {
            temp[tempIndex].price = m_levels[i].price;
            temp[tempIndex].firstTouch = m_levels[i].firstTouch;
            temp[tempIndex].lastTouch = m_levels[i].lastTouch;
            temp[tempIndex].touchCount = m_levels[i].touchCount;
            temp[tempIndex].strength = m_levels[i].strength;
            temp[tempIndex].isSupport = m_levels[i].isSupport;
            temp[tempIndex].isResistance = m_levels[i].isResistance;
            temp[tempIndex].isActive = m_levels[i].isActive;
            temp[tempIndex].description = m_levels[i].description;
            tempIndex++;
        }
    }
    
    // Replace m_levels with temp
    ArrayResize(m_levels, tempCount);
    for(int i = 0; i < tempCount; i++) {
        m_levels[i] = temp[i];
    }
}

//+------------------------------------------------------------------+
//| Update level strength based on touches and age                   |
//+------------------------------------------------------------------+
void CSupportResistance::UpdateLevelStrength(void) {
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < ArraySize(m_levels); i++) {
        // Strength increases with touch count
        m_levels[i].strength = m_levels[i].touchCount * 10;
        
        // Reduce strength if level is old and hasn't been touched recently
        int daysSinceLastTouch = (int)((currentTime - m_levels[i].lastTouch) / 86400);
        if(daysSinceLastTouch > 30) {
            m_levels[i].strength = (int)(m_levels[i].strength * 0.5);
        }
        
        // Bonus strength if it's both support and resistance
        if(m_levels[i].isSupport && m_levels[i].isResistance) {
            m_levels[i].strength = (int)(m_levels[i].strength * 1.5);
        }
    }
}

//+------------------------------------------------------------------+
//| Clean inactive or weak levels                                    |
//+------------------------------------------------------------------+
void CSupportResistance::CleanInactiveLevels(void) {
    // Keep only the strongest levels up to m_maxLevels
    if(ArraySize(m_levels) <= m_maxLevels) return;
    
    // Sort by strength (descending)
    for(int i = 0; i < ArraySize(m_levels) - 1; i++) {
        for(int j = i + 1; j < ArraySize(m_levels); j++) {
            if(m_levels[j].strength > m_levels[i].strength) {
                SRLevel temp = m_levels[i];
                m_levels[i] = m_levels[j];
                m_levels[j] = temp;
            }
        }
    }
    
    // Keep only top levels
    ArrayResize(m_levels, m_maxLevels);
}

//+------------------------------------------------------------------+
//| Check if price is near a level                                   |
//+------------------------------------------------------------------+
bool CSupportResistance::IsNearLevel(double price, double tolerance) {
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(MathAbs(m_levels[i].price - price) <= tolerance) {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get level by index                                               |
//+------------------------------------------------------------------+
bool CSupportResistance::GetLevel(int index, SRLevel &level) {
    if(index < 0 || index >= ArraySize(m_levels)) return false;
    level = m_levels[index];
    return true;
}

//+------------------------------------------------------------------+
//| Get nearest support below price                                  |
//+------------------------------------------------------------------+
bool CSupportResistance::GetNearestSupport(double price, SRLevel &level) {
    double nearestPrice = 0;
    int nearestIndex = -1;
    
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(m_levels[i].isSupport && m_levels[i].price < price) {
            if(nearestPrice == 0 || m_levels[i].price > nearestPrice) {
                nearestPrice = m_levels[i].price;
                nearestIndex = i;
            }
        }
    }
    
    if(nearestIndex >= 0) {
        level = m_levels[nearestIndex];
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get nearest resistance above price                               |
//+------------------------------------------------------------------+
bool CSupportResistance::GetNearestResistance(double price, SRLevel &level) {
    double nearestPrice = 0;
    int nearestIndex = -1;
    
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(m_levels[i].isResistance && m_levels[i].price > price) {
            if(nearestPrice == 0 || m_levels[i].price < nearestPrice) {
                nearestPrice = m_levels[i].price;
                nearestIndex = i;
            }
        }
    }
    
    if(nearestIndex >= 0) {
        level = m_levels[nearestIndex];
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is at support                                     |
//+------------------------------------------------------------------+
bool CSupportResistance::IsPriceAtSupport(double price, double tolerance = 0) {
    if(tolerance == 0) {
        tolerance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10;
    }
    
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(m_levels[i].isSupport && MathAbs(m_levels[i].price - price) <= tolerance) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is at resistance                                  |
//+------------------------------------------------------------------+
bool CSupportResistance::IsPriceAtResistance(double price, double tolerance = 0) {
    if(tolerance == 0) {
        tolerance = SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10;
    }
    
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(m_levels[i].isResistance && MathAbs(m_levels[i].price - price) <= tolerance) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get strongest support level                                      |
//+------------------------------------------------------------------+
double CSupportResistance::GetStrongestSupport(void) {
    double strongestPrice = 0;
    int maxStrength = 0;
    
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(m_levels[i].isSupport && m_levels[i].strength > maxStrength) {
            maxStrength = m_levels[i].strength;
            strongestPrice = m_levels[i].price;
        }
    }
    
    return strongestPrice;
}

//+------------------------------------------------------------------+
//| Get strongest resistance level                                   |
//+------------------------------------------------------------------+
double CSupportResistance::GetStrongestResistance(void) {
    double strongestPrice = 0;
    int maxStrength = 0;
    
    for(int i = 0; i < ArraySize(m_levels); i++) {
        if(m_levels[i].isResistance && m_levels[i].strength > maxStrength) {
            maxStrength = m_levels[i].strength;
            strongestPrice = m_levels[i].price;
        }
    }
    
    return strongestPrice;
}
//+------------------------------------------------------------------+
