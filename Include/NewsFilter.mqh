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
    bool IsEnabled() { return m_enabled; }
    
    bool IsNewsTime();
    bool IsNewsTime(string currency);
    bool LoadNewsCalendar();
    void AddNewsEvent(datetime eventTime, string currency, string event, int importance);
    int GetUpcomingEvents(NewsEvent &events[], int maxEvents = 10);
    string GetNextHighImpactEvent();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewsFilter::CNewsFilter(int filterMinutes = 30) {
    m_filterMinutes = filterMinutes;
    m_enabled = true;
    m_lastUpdate = 0;
    ArrayResize(m_events, 0);
    
    // Load initial news calendar data
    LoadNewsCalendar();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CNewsFilter::~CNewsFilter(void) {
    ArrayFree(m_events);
}

//+------------------------------------------------------------------+
//| Check if it's news time (any currency)                          |
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
    
    // Add NFP (first Friday of each month at 8:30 EST)
    datetime nfpTime = today + 86400; // Tomorrow as example
    AddNewsEvent(nfpTime, "USD", "Non-Farm Payrolls", 3);
    
    // Add FOMC meetings (example)
    datetime fomcTime = today + 7 * 86400; // Next week as example
    AddNewsEvent(fomcTime, "USD", "FOMC Meeting", 3);
    
    // Add ECB meetings (example)
    datetime ecbTime = today + 14 * 86400; // Two weeks as example
    AddNewsEvent(ecbTime, "EUR", "ECB Meeting", 3);
    
    m_lastUpdate = TimeCurrent();
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
//| Get upcoming high-impact events                                  |
//+------------------------------------------------------------------+
int CNewsFilter::GetUpcomingEvents(NewsEvent &events[], int maxEvents = 10) {
    ArrayFree(events);
    datetime currentTime = TimeCurrent();
    int count = 0;
    
    for(int i = 0; i < ArraySize(m_events) && count < maxEvents; i++) {
        if(m_events[i].eventTime > currentTime && m_events[i].importance >= 2) {
            ArrayResize(events, count + 1);
            events[count] = m_events[i];
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Get next high-impact event description                          |
//+------------------------------------------------------------------+
string CNewsFilter::GetNextHighImpactEvent() {
    datetime currentTime = TimeCurrent();
    datetime nextEventTime = 0;
    string nextEvent = "No upcoming high-impact events";
    
    for(int i = 0; i < ArraySize(m_events); i++) {
        if(m_events[i].eventTime > currentTime && m_events[i].importance >= 3) {
            if(nextEventTime == 0 || m_events[i].eventTime < nextEventTime) {
                nextEventTime = m_events[i].eventTime;
                nextEvent = m_events[i].currency + " " + m_events[i].eventName + " at " + TimeToString(nextEventTime);
            }
        }
    }
    
    return nextEvent;
}