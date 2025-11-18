//+------------------------------------------------------------------+
//|                                             TelegramManager.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

#include "Structs_Version1.mqh"

//+------------------------------------------------------------------+
//| Telegram Manager Class                                           |
//| Handles all Telegram notification logic with queueing and        |
//| rate-limiting                                                    |
//+------------------------------------------------------------------+
class CTelegramManager {
private:
    string m_botToken;
    string m_chatID;
    bool m_enabled;
    
    // Rate limiting
    int m_maxMessagesPerMinute;
    datetime m_messageTimestamps[];
    int m_messageCount;
    
    // Message queue
    TelegramMessage m_messageQueue[];
    int m_queueSize;
    int m_maxQueueSize;
    
    // Error tracking
    int m_failedAttempts;
    int m_maxRetries;
    datetime m_lastFailure;
    
public:
    // Constructor/Destructor
    CTelegramManager();
    ~CTelegramManager();
    
    // Initialization
    bool Initialize(string botToken, string chatID, bool enabled = true);
    void SetBotToken(string token) { m_botToken = token; }
    void SetChatID(string chatID) { m_chatID = chatID; }
    void SetEnabled(bool enabled) { m_enabled = enabled; }
    bool IsEnabled() const { return m_enabled; }
    
    // Core messaging
    bool SendMessage(string text);
    bool SendFormattedMessage(string text, string parseMode = "Markdown");
    bool QueueMessage(string text, bool priority = false);
    bool ProcessQueue();
    
    // Specialized notifications
    bool SendTradeNotification(string action, string symbol, double price, double sl, double tp, double lot);
    bool SendSignalNotification(const SignalInfo &signal);
    bool SendPatternNotification(string symbol, ENUM_CANDLE_PATTERN pattern, double strength);
    bool SendMarketAnalysis(string symbol, ENUM_TREND_DIRECTION trend, string analysis);
    bool SendRiskAlert(const RiskData &riskData);
    bool SendErrorNotification(string errorMessage, int errorCode);
    bool SendPerformanceReport(int totalTrades, int winners, double profitLoss);
    
    // Rate limiting
    bool CanSendMessage();
    void CleanupTimestamps();
    void SetMaxMessagesPerMinute(int maxMessages) { m_maxMessagesPerMinute = maxMessages; }
    int GetQueueSize() const { return m_queueSize; }
    
    // Queue management
    void ClearQueue();
    int GetPendingMessages() const { return m_queueSize; }
    
    // Error handling
    int GetFailedAttempts() const { return m_failedAttempts; }
    void ResetFailedAttempts() { m_failedAttempts = 0; }
    
    // Utility
    void PrintStatus();
    
private:
    bool MakeWebRequest(string message);
    string EncodeMessage(string message);
    bool AddToQueue(const TelegramMessage &message);
    TelegramMessage GetNextMessage();
    bool RemoveFromQueue(int index);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CTelegramManager::CTelegramManager() {
    m_botToken = "";
    m_chatID = "";
    m_enabled = false;
    m_maxMessagesPerMinute = 20; // Telegram limit is 30/second, we use 20/minute for safety
    m_messageCount = 0;
    m_queueSize = 0;
    m_maxQueueSize = 100;
    m_failedAttempts = 0;
    m_maxRetries = 3;
    m_lastFailure = 0;
    
    ArrayResize(m_messageTimestamps, 0);
    ArrayResize(m_messageQueue, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CTelegramManager::~CTelegramManager() {
    ArrayFree(m_messageTimestamps);
    ArrayFree(m_messageQueue);
}

//+------------------------------------------------------------------+
//| Initialize Telegram manager                                      |
//+------------------------------------------------------------------+
bool CTelegramManager::Initialize(string botToken, string chatID, bool enabled = true) {
    m_botToken = botToken;
    m_chatID = chatID;
    m_enabled = enabled;
    
    if(m_enabled && (m_botToken == "" || m_chatID == "")) {
        Print("Warning: Telegram enabled but bot token or chat ID not set");
        m_enabled = false;
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Send message with rate limiting                                  |
//+------------------------------------------------------------------+
bool CTelegramManager::SendMessage(string text) {
    if(!m_enabled || m_botToken == "" || m_chatID == "") {
        return false;
    }
    
    // Check rate limiting
    if(!CanSendMessage()) {
        // Queue message if rate limit reached
        return QueueMessage(text);
    }
    
    bool result = MakeWebRequest(text);
    
    if(result) {
        // Track successful send
        int size = ArraySize(m_messageTimestamps);
        ArrayResize(m_messageTimestamps, size + 1);
        m_messageTimestamps[size] = TimeCurrent();
        m_messageCount++;
        m_failedAttempts = 0;
    } else {
        m_failedAttempts++;
        m_lastFailure = TimeCurrent();
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Send formatted message                                           |
//+------------------------------------------------------------------+
bool CTelegramManager::SendFormattedMessage(string text, string parseMode = "Markdown") {
    // For now, just send as regular message
    // Full implementation would add parse_mode parameter to API call
    return SendMessage(text);
}

//+------------------------------------------------------------------+
//| Queue message for later sending                                  |
//+------------------------------------------------------------------+
bool CTelegramManager::QueueMessage(string text, bool priority = false) {
    if(m_queueSize >= m_maxQueueSize) {
        Print("Telegram queue full, message dropped");
        return false;
    }
    
    TelegramMessage msg;
    msg.chatID = m_chatID;
    msg.text = text;
    msg.parseMode = "";
    msg.disableWebPagePreview = false;
    msg.disableNotification = false;
    msg.messageID = 0;
    msg.sent = false;
    msg.timestamp = TimeCurrent();
    
    return AddToQueue(msg);
}

//+------------------------------------------------------------------+
//| Process queued messages                                          |
//+------------------------------------------------------------------+
bool CTelegramManager::ProcessQueue() {
    if(m_queueSize == 0) {
        return true;
    }
    
    CleanupTimestamps();
    
    // Process messages while rate limit allows
    while(m_queueSize > 0 && CanSendMessage()) {
        TelegramMessage msg = GetNextMessage();
        
        if(SendMessage(msg.text)) {
            RemoveFromQueue(0);
        } else {
            // Failed to send, leave in queue for next attempt
            break;
        }
    }
    
    return m_queueSize == 0;
}

//+------------------------------------------------------------------+
//| Check if we can send message (rate limiting)                     |
//+------------------------------------------------------------------+
bool CTelegramManager::CanSendMessage() {
    CleanupTimestamps();
    
    int recentMessages = ArraySize(m_messageTimestamps);
    return (recentMessages < m_maxMessagesPerMinute);
}

//+------------------------------------------------------------------+
//| Cleanup old timestamps (older than 1 minute)                     |
//+------------------------------------------------------------------+
void CTelegramManager::CleanupTimestamps() {
    datetime cutoffTime = TimeCurrent() - 60; // 1 minute ago
    int validCount = 0;
    
    // Count valid timestamps
    for(int i = 0; i < ArraySize(m_messageTimestamps); i++) {
        if(m_messageTimestamps[i] > cutoffTime) {
            validCount++;
        }
    }
    
    // Create new array with only valid timestamps
    if(validCount < ArraySize(m_messageTimestamps)) {
        datetime validTimestamps[];
        ArrayResize(validTimestamps, validCount);
        
        int index = 0;
        for(int i = 0; i < ArraySize(m_messageTimestamps); i++) {
            if(m_messageTimestamps[i] > cutoffTime) {
                validTimestamps[index++] = m_messageTimestamps[i];
            }
        }
        
        ArrayFree(m_messageTimestamps);
        m_messageTimestamps = validTimestamps;
    }
}

//+------------------------------------------------------------------+
//| Send trade notification                                          |
//+------------------------------------------------------------------+
bool CTelegramManager::SendTradeNotification(string action, string symbol, double price, double sl, double tp, double lot) {
    string emoji = (action == "BUY") ? "🟢" : "🔴";
    string message = emoji + " *" + action + " SIGNAL*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📊 Symbol: `" + symbol + "`\n";
    message += "💰 Price: `" + DoubleToString(price, 5) + "`\n";
    message += "🛑 Stop Loss: `" + DoubleToString(sl, 5) + "`\n";
    message += "🎯 Take Profit: `" + DoubleToString(tp, 5) + "`\n";
    message += "📈 Lot Size: `" + DoubleToString(lot, 2) + "`\n";
    message += "⏰ Time: `" + TimeToString(TimeCurrent()) + "`\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send signal notification                                         |
//+------------------------------------------------------------------+
bool CTelegramManager::SendSignalNotification(const SignalInfo &signal) {
    string emoji = (signal.direction == SIGNAL_BUY) ? "🟢" : "🔴";
    string direction = (signal.direction == SIGNAL_BUY) ? "BUY" : "SELL";
    
    string message = emoji + " *" + direction + " SIGNAL*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📊 Symbol: `" + signal.symbol + "`\n";
    message += "💰 Entry: `" + DoubleToString(signal.entryPrice, 5) + "`\n";
    message += "🛑 SL: `" + DoubleToString(signal.stopLoss, 5) + "`\n";
    message += "🎯 TP: `" + DoubleToString(signal.takeProfit, 5) + "`\n";
    message += "💪 Strength: `" + DoubleToString(signal.patternStrength, 2) + "`\n";
    message += "📈 Trend: `" + EnumToString(signal.trend) + "`\n";
    message += "⏰ Time: `" + TimeToString(signal.timestamp) + "`\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send pattern notification                                        |
//+------------------------------------------------------------------+
bool CTelegramManager::SendPatternNotification(string symbol, ENUM_CANDLE_PATTERN pattern, double strength) {
    string message = "🔍 *PATTERN DETECTED*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📊 Symbol: `" + symbol + "`\n";
    message += "🎯 Pattern: `" + EnumToString(pattern) + "`\n";
    message += "💪 Strength: `" + DoubleToString(strength, 2) + "`\n";
    message += "⏰ Time: `" + TimeToString(TimeCurrent()) + "`\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send market analysis notification                                |
//+------------------------------------------------------------------+
bool CTelegramManager::SendMarketAnalysis(string symbol, ENUM_TREND_DIRECTION trend, string analysis) {
    string trendEmoji = "📊";
    if(trend == TREND_UP) trendEmoji = "📈";
    else if(trend == TREND_DOWN) trendEmoji = "📉";
    
    string message = trendEmoji + " *MARKET ANALYSIS*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📊 Symbol: `" + symbol + "`\n";
    message += "📈 Trend: `" + EnumToString(trend) + "`\n";
    message += "📝 Analysis:\n" + analysis + "\n";
    message += "⏰ Time: `" + TimeToString(TimeCurrent()) + "`\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send risk alert                                                  |
//+------------------------------------------------------------------+
bool CTelegramManager::SendRiskAlert(const RiskData &riskData) {
    string message = "⚠️ *RISK ALERT*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "💰 Balance: `" + DoubleToString(riskData.accountBalance, 2) + "`\n";
    message += "📊 Equity: `" + DoubleToString(riskData.accountEquity, 2) + "`\n";
    message += "📉 Drawdown: `" + DoubleToString(riskData.currentDrawdown, 2) + "%`\n";
    message += "⚠️ Risk: `" + DoubleToString(riskData.riskPercent, 2) + "%`\n";
    message += "📈 Daily P&L: `" + DoubleToString(riskData.dailyPnL, 2) + "`\n";
    message += "⏰ Time: `" + TimeToString(TimeCurrent()) + "`\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send error notification                                          |
//+------------------------------------------------------------------+
bool CTelegramManager::SendErrorNotification(string errorMessage, int errorCode) {
    string message = "❌ *ERROR NOTIFICATION*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "Error Code: `" + IntegerToString(errorCode) + "`\n";
    message += "Message: `" + errorMessage + "`\n";
    message += "⏰ Time: `" + TimeToString(TimeCurrent()) + "`\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send performance report                                          |
//+------------------------------------------------------------------+
bool CTelegramManager::SendPerformanceReport(int totalTrades, int winners, double profitLoss) {
    double winRate = (totalTrades > 0) ? (double)winners / totalTrades * 100.0 : 0.0;
    
    string message = "📊 *PERFORMANCE REPORT*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📈 Total Trades: `" + IntegerToString(totalTrades) + "`\n";
    message += "✅ Winners: `" + IntegerToString(winners) + "`\n";
    message += "📉 Win Rate: `" + DoubleToString(winRate, 1) + "%`\n";
    message += "💰 P&L: `" + DoubleToString(profitLoss, 2) + "`\n";
    message += "⏰ Time: `" + TimeToString(TimeCurrent()) + "`\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Make web request to Telegram API                                 |
//+------------------------------------------------------------------+
bool CTelegramManager::MakeWebRequest(string message) {
    string url = "https://api.telegram.org/bot" + m_botToken + "/sendMessage";
    string encodedMessage = EncodeMessage(message);
    string payload = "chat_id=" + m_chatID + "&text=" + encodedMessage;
    
    char post[], result[];
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    
    StringToCharArray(payload, post, 0, StringLen(payload));
    
    int timeout = 5000; // 5 seconds timeout
    int res = WebRequest("POST", url, headers, timeout, post, result, headers);
    
    if(res == -1) {
        int error = GetLastError();
        Print("Telegram notification failed. Error: ", error);
        return false;
    }
    
    return (res == 200);
}

//+------------------------------------------------------------------+
//| URL encode message                                               |
//+------------------------------------------------------------------+
string CTelegramManager::EncodeMessage(string message) {
    string encoded = message;
    
    // Basic URL encoding
    StringReplace(encoded, "\n", "%0A");
    StringReplace(encoded, " ", "%20");
    StringReplace(encoded, "*", "%2A");
    StringReplace(encoded, "`", "%60");
    StringReplace(encoded, "_", "%5F");
    
    return encoded;
}

//+------------------------------------------------------------------+
//| Add message to queue                                             |
//+------------------------------------------------------------------+
bool CTelegramManager::AddToQueue(const TelegramMessage &message) {
    int size = ArraySize(m_messageQueue);
    if(ArrayResize(m_messageQueue, size + 1) > 0) {
        m_messageQueue[size] = message;
        m_queueSize++;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get next message from queue                                      |
//+------------------------------------------------------------------+
TelegramMessage CTelegramManager::GetNextMessage() {
    if(m_queueSize > 0) {
        return m_messageQueue[0];
    }
    TelegramMessage empty = {0};
    return empty;
}

//+------------------------------------------------------------------+
//| Remove message from queue                                        |
//+------------------------------------------------------------------+
bool CTelegramManager::RemoveFromQueue(int index) {
    if(index < 0 || index >= m_queueSize) {
        return false;
    }
    
    // Shift remaining messages
    for(int i = index; i < m_queueSize - 1; i++) {
        m_messageQueue[i] = m_messageQueue[i + 1];
    }
    
    m_queueSize--;
    ArrayResize(m_messageQueue, m_queueSize);
    
    return true;
}

//+------------------------------------------------------------------+
//| Clear message queue                                              |
//+------------------------------------------------------------------+
void CTelegramManager::ClearQueue() {
    ArrayResize(m_messageQueue, 0);
    m_queueSize = 0;
}

//+------------------------------------------------------------------+
//| Print Telegram manager status                                    |
//+------------------------------------------------------------------+
void CTelegramManager::PrintStatus() {
    Print("=== Telegram Manager Status ===");
    Print("Enabled: ", m_enabled ? "Yes" : "No");
    Print("Messages Sent: ", m_messageCount);
    Print("Queue Size: ", m_queueSize);
    Print("Failed Attempts: ", m_failedAttempts);
    Print("Can Send: ", CanSendMessage() ? "Yes" : "No");
    Print("===============================");
}
