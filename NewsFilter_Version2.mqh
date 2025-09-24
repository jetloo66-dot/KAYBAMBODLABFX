//+------------------------------------------------------------------+
//|                                                   NewsFilter.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| News Event Structure                                             |
//+------------------------------------------------------------------+
struct NewsEvent {
    datetime eventTime;
    string currency;
    string eventName;
    int importance; // 1=Low, 2=Medium, 3=High
    string forecast;
    string previous;
};

//+------------------------------------------------------------------+
//| News Filter Class                                                |
//+------------------------------------------------------------------+
class CNewsFilter {
private:
    NewsEvent m_events[];
    int m_filterMinutes;
    bool m_enabled;
    datetime m_lastUpdate;
    
public:
    CNewsFilter(int filterMinutes = 30);
    ~CNewsFilter();
    
    void SetFilterMinutes(int minutes) { m_filterMinutes = minutes; }
    void SetEnabled(bool enabled) { m_enabled = enabled; }
    
    bool IsNewsTime();
    bool IsNewsTime(string currency);
    bool LoadNewsCalendar();
    void AddNewsEvent(datetime eventTime, string currency, string event, int importance);
    
private:
    bool IsEventAffectingSymbol(const NewsEvent &event, string symbol);
    string GetBaseCurrency(string symbol);
    string GetQuoteCurrency(string symbol);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewsFilter::CNewsFilter(int filterMinutes = 30) {
    m_filterMinutes = filterMinutes;
    m_enabled = true;
    m_lastUpdate = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CNewsFilter::~CNewsFilter() {
    ArrayFree(m_events);
}

//+------------------------------------------------------------------+
//| Check if it's news time                                          |
//+------------------------------------------------------------------+
bool CNewsFilter::IsNewsTime() {
    if(!m_enabled) return false;
    
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < ArraySize(m_events); i++) {
        datetime eventTime = m_events[i].eventTime;
        
        // Check if we're within the filter window
        if(MathAbs(currentTime - eventTime) <= m_filterMinutes * 60) {
            if(m_events[i].importance >= 2) { // Medium or High importance
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if it's news time for specific currency                   |
//+------------------------------------------------------------------+
bool CNewsFilter::IsNewsTime(string currency) {
    if(!m_enabled) return false;
    
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < ArraySize(m_events); i++) {
        if(m_events[i].currency == currency) {
            datetime eventTime = m_events[i].eventTime;
            
            if(MathAbs(currentTime - eventTime) <= m_filterMinutes * 60) {
                if(m_events[i].importance >= 2) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Load news calendar (simplified implementation)                   |
//+------------------------------------------------------------------+
bool CNewsFilter::LoadNewsCalendar() {
    // In a real implementation, this would load from an external source
    // For now, we'll add some common high-impact events
    
    datetime today = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(today, dt);
    
    // Clear existing events
    ArrayFree(m_events);
    
    // Add typical high-impact events (this is a simplified example)
    // In practice, you'd load this from a news calendar API
    
    return true;
}

//+------------------------------------------------------------------+
//| Add news event manually                                          |
//+------------------------------------------------------------------+
void CNewsFilter::AddNewsEvent(datetime eventTime, string currency, string event, int importance) {
    int size = ArraySize(m_events);
    ArrayResize(m_events, size + 1);
    
    m_events[size].eventTime = eventTime;
    m_events[size].currency = currency;
    m_events[size].eventName = event;
    m_events[size].importance = importance;
}

//+------------------------------------------------------------------+
//| Get base currency from symbol                                    |
//+------------------------------------------------------------------+
string CNewsFilter::GetBaseCurrency(string symbol) {
    if(StringLen(symbol) >= 3) {
        return StringSubstr(symbol, 0, 3);
    }
    return "";
}

//+------------------------------------------------------------------+
//| Get quote currency from symbol                                   |
//+------------------------------------------------------------------+
string CNewsFilter::GetQuoteCurrency(string symbol) {
    if(StringLen(symbol) >= 6) {
        return StringSubstr(symbol, 3, 3);
    }
    return "";
}