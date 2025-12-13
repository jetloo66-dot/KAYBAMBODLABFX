//+------------------------------------------------------------------+
//|                                        TelegramNotifications.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Telegram notification helper class                               |
//+------------------------------------------------------------------+
class CTelegramNotifications {
private:
    string m_botToken;
    string m_chatID;
    bool m_enabled;
    
public:
    CTelegramNotifications(string botToken, string chatID, bool enabled = true);
    ~CTelegramNotifications();
    
    void SetBotToken(string token) { m_botToken = token; }
    void SetChatID(string chatID) { m_chatID = chatID; }
    void SetEnabled(bool enabled) { m_enabled = enabled; }
    
    bool SendMessage(string message);
    bool SendTradeAlert(string symbol, string action, double price, double sl, double tp, double lot);
    bool SendMarketAnalysis(string symbol, string trend, string levels);
    bool SendPatternAlert(string symbol, string patterns);
    
private:
    bool MakeWebRequest(string message);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTelegramNotifications::CTelegramNotifications(string botToken, string chatID, bool enabled = true) {
    m_botToken = botToken;
    m_chatID = chatID;
    m_enabled = enabled;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTelegramNotifications::~CTelegramNotifications(void) {
    // Cleanup if needed
}

//+------------------------------------------------------------------+
//| Send generic message                                             |
//+------------------------------------------------------------------+
bool CTelegramNotifications::SendMessage(string message) {
    if(!m_enabled || m_botToken == "" || m_chatID == "") {
        return false;
    }
    
    return MakeWebRequest(message);
}

//+------------------------------------------------------------------+
//| Send trade alert                                                 |
//+------------------------------------------------------------------+
bool CTelegramNotifications::SendTradeAlert(string symbol, string action, double price, double sl, double tp, double lot) {
    string emoji = (action == "BUY") ? "🟢" : "🔴";
    string message = emoji + " " + action + " SIGNAL\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📊 Symbol: " + symbol + "\n";
    message += "💰 Price: " + DoubleToString(price, 5) + "\n";
    message += "🛑 Stop Loss: " + DoubleToString(sl, 5) + "\n";
    message += "🎯 Take Profit: " + DoubleToString(tp, 5) + "\n";
    message += "📈 Lot Size: " + DoubleToString(lot, 2) + "\n";
    message += "⏰ Time: " + TimeToString(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send market analysis                                             |
//+------------------------------------------------------------------+
bool CTelegramNotifications::SendMarketAnalysis(string symbol, string trend, string levels) {
    string trendEmoji = "📊";
    if(trend == "UPTREND") trendEmoji = "📈";
    else if(trend == "DOWNTREND") trendEmoji = "📉";
    
    string message = trendEmoji + " MARKET ANALYSIS\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📊 Symbol: " + symbol + "\n";
    message += "📈 Trend: " + trend + "\n";
    message += "🎯 Key Levels:\n" + levels + "\n";
    message += "⏰ Time: " + TimeToString(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send pattern alert                                               |
//+------------------------------------------------------------------+
bool CTelegramNotifications::SendPatternAlert(string symbol, string patterns) {
    string message = "🔍 PATTERN DETECTED\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "📊 Symbol: " + symbol + "\n";
    message += "🎯 Patterns:\n" + patterns + "\n";
    message += "⏰ Time: " + TimeToString(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Make web request to Telegram API                                 |
//+------------------------------------------------------------------+
bool CTelegramNotifications::MakeWebRequest(string message) {
    string url = "https://api.telegram.org/bot" + m_botToken + "/sendMessage";
    
    // URL encode the message
    string encodedMessage = message;
    StringReplace(encodedMessage, "\n", "%0A");
    StringReplace(encodedMessage, " ", "%20");
    StringReplace(encodedMessage, "━", "%E2%94%81");
    StringReplace(encodedMessage, "🟢", "%F0%9F%9F%A2");
    StringReplace(encodedMessage, "🔴", "%F0%9F%94%B4");
    StringReplace(encodedMessage, "📊", "%F0%9F%93%8A");
    StringReplace(encodedMessage, "📈", "%F0%9F%93%88");
    StringReplace(encodedMessage, "📉", "%F0%9F%93%89");
    StringReplace(encodedMessage, "💰", "%F0%9F%92%B0");
    StringReplace(encodedMessage, "🛑", "%F0%9F%9B%91");
    StringReplace(encodedMessage, "🎯", "%F0%9F%8E%AF");
    StringReplace(encodedMessage, "⏰", "%E2%8F%B0");
    StringReplace(encodedMessage, "🔍", "%F0%9F%94%8D");
    
    string payload = "chat_id=" + m_chatID + "&text=" + encodedMessage;
    
    char post[], result[];
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    
    StringToCharArray(payload, post, 0, StringLen(payload));
    
    int timeout = 5000; // 5 seconds timeout
    int res = WebRequest("POST", url, headers, timeout, post, result, headers);
    
    if(res == -1) {
        Print("Telegram notification failed: ", GetLastError());
        return false;
    }
    
    return true;
}