//+------------------------------------------------------------------+
//|                                          NewsFilterManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs_Version1.mqh"

//+------------------------------------------------------------------+
//| News Filter Manager Class                                        |
//| Integrates news event filtering with methods to block trading    |
//| during high-impact news events                                   |
//+------------------------------------------------------------------+
class CNewsFilterManager {
private:
    bool m_enabled;
    int m_filterMinutesBefore;
    int m_filterMinutesAfter;
    NewsEvent m_events[];
    int m_eventCount;
    datetime m_lastUpdate;
    int m_maxEvents;
    
    // Filtering settings
    int m_minImportance; // Minimum importance level to filter (1=Low, 2=Medium, 3=High)
    bool m_filterWeekends;
    bool m_filterHolidays;
    
public:
    // Constructor/Destructor
    CNewsFilterManager();
    ~CNewsFilterManager();
    
    // Initialization
    bool Initialize(int filterMinutes = 30, int minImportance = 2);
    void SetEnabled(bool enabled) { m_enabled = enabled; }
    bool IsEnabled() const { return m_enabled; }
    
    // Configuration
    void SetFilterMinutesBefore(int minutes) { m_filterMinutesBefore = minutes; }
    void SetFilterMinutesAfter(int minutes) { m_filterMinutesAfter = minutes; }
    void SetMinImportance(int importance);
    void SetFilterWeekends(bool filter) { m_filterWeekends = filter; }
    void SetFilterHolidays(bool filter) { m_filterHolidays = filter; }
    
    // Event management
    bool AddNewsEvent(datetime eventTime, string currency, string eventName, int importance);
    bool AddNewsEvent(const NewsEvent &event);
    bool RemoveEvent(int index);
    void ClearEvents();
    bool LoadNewsCalendar();
    
    // Filtering methods
    bool IsNewsTime();
    bool IsNewsTime(string symbol);
    bool IsNewsTime(string currency);
    bool IsHighImpactNewsTime();
    bool IsEventAffectingSymbol(const NewsEvent &event, string symbol);
    
    // Event queries
    int GetEventCount() const { return m_eventCount; }
    NewsEvent GetEvent(int index);
    NewsEvent GetNextEvent();
    NewsEvent GetNextEvent(string currency);
    datetime GetNextEventTime();
    datetime GetNextEventTime(string currency);
    
    // Time checks
    bool IsWeekend();
    bool IsHoliday();
    bool IsTradingHours();
    int GetMinutesUntilNextEvent();
    
    // Utility
    void PrintUpcomingEvents();
    void PrintEventSchedule();
    string GetCurrencyFromSymbol(string symbol);
    
private:
    bool IsWithinFilterWindow(datetime eventTime);
    void SortEventsByTime();
    void RemoveOldEvents();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CNewsFilterManager::CNewsFilterManager() {
    m_enabled = true;
    m_filterMinutesBefore = 30;
    m_filterMinutesAfter = 30;
    m_eventCount = 0;
    m_lastUpdate = 0;
    m_maxEvents = 500;
    m_minImportance = 2; // Medium and High impact
    m_filterWeekends = true;
    m_filterHolidays = false;
    
    ArrayResize(m_events, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CNewsFilterManager::~CNewsFilterManager() {
    ArrayFree(m_events);
}

//+------------------------------------------------------------------+
//| Initialize news filter manager                                   |
//+------------------------------------------------------------------+
bool CNewsFilterManager::Initialize(int filterMinutes, int minImportance) {
    m_filterMinutesBefore = filterMinutes;
    m_filterMinutesAfter = filterMinutes;
    m_minImportance = minImportance;
    
    // Load calendar if available
    LoadNewsCalendar();
    
    return true;
}

//+------------------------------------------------------------------+
//| Set minimum importance level                                     |
//+------------------------------------------------------------------+
void CNewsFilterManager::SetMinImportance(int importance) {
    if(importance >= 1 && importance <= 3) {
        m_minImportance = importance;
    }
}

//+------------------------------------------------------------------+
//| Add news event                                                   |
//+------------------------------------------------------------------+
bool CNewsFilterManager::AddNewsEvent(datetime eventTime, string currency, string eventName, int importance) {
    NewsEvent event;
    event.eventTime = eventTime;
    event.currency = currency;
    event.eventName = eventName;
    event.importance = importance;
    event.forecast = "";
    event.previous = "";
    event.actual = "";
    event.affectsSymbol = false;
    
    return AddNewsEvent(event);
}

//+------------------------------------------------------------------+
//| Add news event (full structure)                                  |
//+------------------------------------------------------------------+
bool CNewsFilterManager::AddNewsEvent(const NewsEvent &event) {
    if(m_eventCount >= m_maxEvents) {
        RemoveOldEvents();
    }
    
    int size = ArraySize(m_events);
    if(ArrayResize(m_events, size + 1) > 0) {
        m_events[size] = event;
        m_eventCount++;
        SortEventsByTime();
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Remove event by index                                            |
//+------------------------------------------------------------------+
bool CNewsFilterManager::RemoveEvent(int index) {
    if(index < 0 || index >= m_eventCount) {
        return false;
    }
    
    // Shift remaining events
    for(int i = index; i < m_eventCount - 1; i++) {
        m_events[i] = m_events[i + 1];
    }
    
    m_eventCount--;
    ArrayResize(m_events, m_eventCount);
    
    return true;
}

//+------------------------------------------------------------------+
//| Clear all events                                                 |
//+------------------------------------------------------------------+
void CNewsFilterManager::ClearEvents() {
    ArrayResize(m_events, 0);
    m_eventCount = 0;
}

//+------------------------------------------------------------------+
//| Load news calendar (placeholder for actual calendar integration) |
//+------------------------------------------------------------------+
bool CNewsFilterManager::LoadNewsCalendar() {
    // In a real implementation, this would:
    // 1. Load from MQL5 economic calendar
    // 2. Load from external API/file
    // 3. Parse and populate events array
    
    // For now, add some common high-impact events as examples
    datetime today = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(today, dt);
    
    // Example: Add typical NFP event (first Friday of month at 8:30 EST)
    // This is a simplified example - real implementation would use actual calendar data
    
    return true;
}

//+------------------------------------------------------------------+
//| Check if it's news time (any currency)                           |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsNewsTime() {
    if(!m_enabled) return false;
    
    // Check weekend
    if(m_filterWeekends && IsWeekend()) {
        return true;
    }
    
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < m_eventCount; i++) {
        if(m_events[i].importance >= m_minImportance) {
            if(IsWithinFilterWindow(m_events[i].eventTime)) {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if it's news time for specific symbol                      |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsNewsTime(string symbol) {
    if(!m_enabled) return false;
    
    datetime currentTime = TimeCurrent();
    string baseCurrency = GetCurrencyFromSymbol(symbol);
    string quoteCurrency = "";
    
    if(StringLen(symbol) >= 6) {
        quoteCurrency = StringSubstr(symbol, 3, 3);
    }
    
    for(int i = 0; i < m_eventCount; i++) {
        if(m_events[i].importance >= m_minImportance) {
            // Check if event affects this symbol's currencies
            if(m_events[i].currency == baseCurrency || 
               m_events[i].currency == quoteCurrency) {
                if(IsWithinFilterWindow(m_events[i].eventTime)) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if it's high impact news time                              |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsHighImpactNewsTime() {
    if(!m_enabled) return false;
    
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < m_eventCount; i++) {
        if(m_events[i].importance == 3) { // High impact only
            if(IsWithinFilterWindow(m_events[i].eventTime)) {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if event affects symbol                                    |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsEventAffectingSymbol(const NewsEvent &event, string symbol) {
    string baseCurrency = GetCurrencyFromSymbol(symbol);
    string quoteCurrency = "";
    
    if(StringLen(symbol) >= 6) {
        quoteCurrency = StringSubstr(symbol, 3, 3);
    }
    
    return (event.currency == baseCurrency || event.currency == quoteCurrency);
}

//+------------------------------------------------------------------+
//| Get event by index                                               |
//+------------------------------------------------------------------+
NewsEvent CNewsFilterManager::GetEvent(int index) {
    if(index >= 0 && index < m_eventCount) {
        return m_events[index];
    }
    NewsEvent empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get next upcoming event                                          |
//+------------------------------------------------------------------+
NewsEvent CNewsFilterManager::GetNextEvent() {
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < m_eventCount; i++) {
        if(m_events[i].eventTime > currentTime) {
            return m_events[i];
        }
    }
    
    NewsEvent empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get next event for specific currency                             |
//+------------------------------------------------------------------+
NewsEvent CNewsFilterManager::GetNextEvent(string currency) {
    datetime currentTime = TimeCurrent();
    
    for(int i = 0; i < m_eventCount; i++) {
        if(m_events[i].eventTime > currentTime && 
           m_events[i].currency == currency) {
            return m_events[i];
        }
    }
    
    NewsEvent empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Get time of next event                                           |
//+------------------------------------------------------------------+
datetime CNewsFilterManager::GetNextEventTime() {
    NewsEvent nextEvent = GetNextEvent();
    return nextEvent.eventTime;
}

//+------------------------------------------------------------------+
//| Get time of next event for currency                              |
//+------------------------------------------------------------------+
datetime CNewsFilterManager::GetNextEventTime(string currency) {
    NewsEvent nextEvent = GetNextEvent(currency);
    return nextEvent.eventTime;
}

//+------------------------------------------------------------------+
//| Check if it's weekend                                            |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsWeekend() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    return (dt.day_of_week == 0 || dt.day_of_week == 6);
}

//+------------------------------------------------------------------+
//| Check if it's a holiday                                          |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsHoliday() {
    // Simple implementation - can be enhanced with actual holiday calendar
    return false;
}

//+------------------------------------------------------------------+
//| Check if within trading hours                                    |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsTradingHours() {
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Basic trading hours check (can be customized)
    if(dt.day_of_week == 0 || dt.day_of_week == 6) return false; // Weekend
    if(dt.hour < 1 || dt.hour >= 23) return false; // Outside main hours
    
    return true;
}

//+------------------------------------------------------------------+
//| Get minutes until next event                                     |
//+------------------------------------------------------------------+
int CNewsFilterManager::GetMinutesUntilNextEvent() {
    datetime nextEventTime = GetNextEventTime();
    if(nextEventTime == 0) return -1;
    
    datetime currentTime = TimeCurrent();
    return (int)((nextEventTime - currentTime) / 60);
}

//+------------------------------------------------------------------+
//| Check if within filter window                                    |
//+------------------------------------------------------------------+
bool CNewsFilterManager::IsWithinFilterWindow(datetime eventTime) {
    datetime currentTime = TimeCurrent();
    int minutesBeforeEvent = (int)((eventTime - currentTime) / 60);
    int minutesAfterEvent = (int)((currentTime - eventTime) / 60);
    
    // Check if we're before the event (within filter window)
    if(minutesBeforeEvent >= 0 && minutesBeforeEvent <= m_filterMinutesBefore) {
        return true;
    }
    
    // Check if we're after the event (within filter window)
    if(minutesAfterEvent >= 0 && minutesAfterEvent <= m_filterMinutesAfter) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Sort events by time                                              |
//+------------------------------------------------------------------+
void CNewsFilterManager::SortEventsByTime() {
    // Simple bubble sort - adequate for small arrays
    for(int i = 0; i < m_eventCount - 1; i++) {
        for(int j = 0; j < m_eventCount - i - 1; j++) {
            if(m_events[j].eventTime > m_events[j + 1].eventTime) {
                NewsEvent temp = m_events[j];
                m_events[j] = m_events[j + 1];
                m_events[j + 1] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Remove old events (past events)                                  |
//+------------------------------------------------------------------+
void CNewsFilterManager::RemoveOldEvents() {
    datetime currentTime = TimeCurrent();
    datetime cutoffTime = currentTime - (m_filterMinutesAfter * 60);
    
    int validCount = 0;
    
    // Count valid events
    for(int i = 0; i < m_eventCount; i++) {
        if(m_events[i].eventTime >= cutoffTime) {
            validCount++;
        }
    }
    
    // Create new array with only valid events
    if(validCount < m_eventCount) {
        NewsEvent validEvents[];
        ArrayResize(validEvents, validCount);
        
        int index = 0;
        for(int i = 0; i < m_eventCount; i++) {
            if(m_events[i].eventTime >= cutoffTime) {
                validEvents[index++] = m_events[i];
            }
        }
        
        // Use ArrayCopy to properly transfer data
        ArrayResize(m_events, validCount);
        ArrayCopy(m_events, validEvents, 0, 0, validCount);
        m_eventCount = validCount;
    }
}

//+------------------------------------------------------------------+
//| Get currency from symbol                                         |
//+------------------------------------------------------------------+
string CNewsFilterManager::GetCurrencyFromSymbol(string symbol) {
    if(StringLen(symbol) >= 3) {
        return StringSubstr(symbol, 0, 3);
    }
    return "";
}

//+------------------------------------------------------------------+
//| Print upcoming events                                            |
//+------------------------------------------------------------------+
void CNewsFilterManager::PrintUpcomingEvents() {
    Print("=== Upcoming News Events ===");
    Print("Total Events: ", m_eventCount);
    
    datetime currentTime = TimeCurrent();
    int upcomingCount = 0;
    
    for(int i = 0; i < m_eventCount; i++) {
        if(m_events[i].eventTime > currentTime) {
            Print("Event: ", m_events[i].eventName,
                  " | Currency: ", m_events[i].currency,
                  " | Time: ", TimeToString(m_events[i].eventTime),
                  " | Importance: ", m_events[i].importance);
            upcomingCount++;
            
            if(upcomingCount >= 10) break; // Show max 10 upcoming events
        }
    }
    
    Print("============================");
}

//+------------------------------------------------------------------+
//| Print event schedule                                             |
//+------------------------------------------------------------------+
void CNewsFilterManager::PrintEventSchedule() {
    Print("=== News Filter Schedule ===");
    Print("Enabled: ", m_enabled ? "Yes" : "No");
    Print("Filter Before: ", m_filterMinutesBefore, " minutes");
    Print("Filter After: ", m_filterMinutesAfter, " minutes");
    Print("Min Importance: ", m_minImportance);
    Print("Filter Weekends: ", m_filterWeekends ? "Yes" : "No");
    Print("Total Events: ", m_eventCount);
    Print("Minutes Until Next Event: ", GetMinutesUntilNextEvent());
    Print("============================");
}
