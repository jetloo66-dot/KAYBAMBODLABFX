//+------------------------------------------------------------------+
//|                                           TelegramNotifier.mqh |
//|                        Copyright 2024, KAYBAMBODLABFX            |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "KAYBAMBODLABFX"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Telegram Notifier Class                                          |
//+------------------------------------------------------------------+
class CTelegramNotifier {
private:
    string m_botToken;
    string m_chatID;
    bool m_enabled;
    datetime m_lastMessageTime;
    int m_messageInterval;  // Minimum seconds between messages
    
    string FormatPrice(double price, int digits);
    string FormatDateTime(datetime time);
    bool SendHTTPRequest(string message);
    
public:
    CTelegramNotifier(string botToken, string chatID, bool enabled = true);
    ~CTelegramNotifier();
    
    void SetEnabled(bool enabled) { m_enabled = enabled; }
    void SetBotToken(string token) { m_botToken = token; }
    void SetChatID(string chatID) { m_chatID = chatID; }
    void SetMessageInterval(int seconds) { m_messageInterval = seconds; }
    
    bool SendMessage(string message);
    bool SendSignalDetected(string symbol, string signalType, double price, string comment);
    bool SendTradeExecuted(string symbol, string orderType, double entryPrice, 
                          double sl, double tp, double lot, ulong ticket);
    bool SendTakeProfitHit(string symbol, ulong ticket, double profit);
    bool SendStopLossHit(string symbol, ulong ticket, double loss);
    bool SendTrailingStopTriggered(string symbol, ulong ticket, double newSL);
    bool SendError(string errorMessage);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTelegramNotifier::CTelegramNotifier(string botToken, string chatID, bool enabled) {
    m_botToken = botToken;
    m_chatID = chatID;
    m_enabled = enabled;
    m_lastMessageTime = 0;
    m_messageInterval = 5;  // 5 seconds minimum between messages
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTelegramNotifier::~CTelegramNotifier(void) {
}

//+------------------------------------------------------------------+
//| Send generic message                                             |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendMessage(string message) {
    if(!m_enabled) return false;
    
    // Rate limiting
    datetime currentTime = TimeCurrent();
    if(currentTime - m_lastMessageTime < m_messageInterval) {
        return false;
    }
    
    bool result = SendHTTPRequest(message);
    if(result) {
        m_lastMessageTime = currentTime;
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Send signal detected notification                                |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendSignalDetected(string symbol, string signalType, double price, string comment) {
    if(!m_enabled) return false;
    
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    string message = "🔔 *SIGNAL DETECTED*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "Symbol: " + symbol + "\n";
    message += "Type: " + signalType + "\n";
    message += "Price: " + FormatPrice(price, digits) + "\n";
    message += "Time: " + FormatDateTime(TimeCurrent()) + "\n";
    
    if(comment != "") {
        message += "Details: " + comment + "\n";
    }
    
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send trade executed notification                                 |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendTradeExecuted(string symbol, string orderType, double entryPrice,
                                         double sl, double tp, double lot, ulong ticket) {
    if(!m_enabled) return false;
    
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    string emoji = (orderType == "BUY") ? "🟢" : "🔴";
    string message = emoji + " *TRADE EXECUTED*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "Ticket: " + IntegerToString(ticket) + "\n";
    message += "Symbol: " + symbol + "\n";
    message += "Type: " + orderType + "\n";
    message += "Lot Size: " + DoubleToString(lot, 2) + "\n";
    message += "Entry: " + FormatPrice(entryPrice, digits) + "\n";
    message += "Stop Loss: " + FormatPrice(sl, digits) + "\n";
    message += "Take Profit: " + FormatPrice(tp, digits) + "\n";
    message += "Time: " + FormatDateTime(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send take profit hit notification                                |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendTakeProfitHit(string symbol, ulong ticket, double profit) {
    if(!m_enabled) return false;
    
    string message = "✅ *TAKE PROFIT HIT*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "Ticket: " + IntegerToString(ticket) + "\n";
    message += "Symbol: " + symbol + "\n";
    message += "Profit: $" + DoubleToString(profit, 2) + "\n";
    message += "Time: " + FormatDateTime(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send stop loss hit notification                                  |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendStopLossHit(string symbol, ulong ticket, double loss) {
    if(!m_enabled) return false;
    
    string message = "❌ *STOP LOSS HIT*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "Ticket: " + IntegerToString(ticket) + "\n";
    message += "Symbol: " + symbol + "\n";
    message += "Loss: $" + DoubleToString(loss, 2) + "\n";
    message += "Time: " + FormatDateTime(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send trailing stop triggered notification                        |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendTrailingStopTriggered(string symbol, ulong ticket, double newSL) {
    if(!m_enabled) return false;
    
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    string message = "📊 *TRAILING STOP TRIGGERED*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += "Ticket: " + IntegerToString(ticket) + "\n";
    message += "Symbol: " + symbol + "\n";
    message += "New SL: " + FormatPrice(newSL, digits) + "\n";
    message += "Time: " + FormatDateTime(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Send error notification                                          |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendError(string errorMessage) {
    if(!m_enabled) return false;
    
    string message = "⚠️ *ERROR*\n";
    message += "━━━━━━━━━━━━━━━━\n";
    message += errorMessage + "\n";
    message += "Time: " + FormatDateTime(TimeCurrent()) + "\n";
    message += "━━━━━━━━━━━━━━━━";
    
    return SendMessage(message);
}

//+------------------------------------------------------------------+
//| Format price with proper digits                                  |
//+------------------------------------------------------------------+
string CTelegramNotifier::FormatPrice(double price, int digits) {
    return DoubleToString(price, digits);
}

//+------------------------------------------------------------------+
//| Format datetime to readable string                               |
//+------------------------------------------------------------------+
string CTelegramNotifier::FormatDateTime(datetime time) {
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    string result = StringFormat("%04d.%02d.%02d %02d:%02d:%02d",
                                dt.year, dt.mon, dt.day,
                                dt.hour, dt.min, dt.sec);
    return result;
}

//+------------------------------------------------------------------+
//| Send HTTP request to Telegram API                                |
//+------------------------------------------------------------------+
bool CTelegramNotifier::SendHTTPRequest(string message) {
    if(m_botToken == "" || m_chatID == "") {
        Print("Telegram credentials not set");
        return false;
    }
    
    // URL encode the message
    string encodedMessage = message;
    StringReplace(encodedMessage, "\n", "%0A");
    StringReplace(encodedMessage, " ", "%20");
    StringReplace(encodedMessage, "*", "%2A");
    StringReplace(encodedMessage, "_", "%5F");
    StringReplace(encodedMessage, "|", "%7C");
    StringReplace(encodedMessage, ":", "%3A");
    StringReplace(encodedMessage, "$", "%24");
    
    string url = "https://api.telegram.org/bot" + m_botToken + 
                 "/sendMessage?chat_id=" + m_chatID + 
                 "&text=" + encodedMessage +
                 "&parse_mode=Markdown";
    
    // Initialize arrays for WebRequest
    char data[];      // Empty for GET request
    char result[];    // Will contain response
    string headers = ""; // No custom headers needed for GET
    
    ResetLastError();
    // WebRequest: method, url, cookie, referer, timeout, data, data_size, result, result_headers
    // For GET requests, we use NULL for data and 0 for data_size
    string cookie = NULL;
    string referer = NULL;
    int timeout = 5000;
    int res = WebRequest("GET", url, cookie, referer, timeout, data, 0, result, headers);
    
    if(res == -1) {
        int error = GetLastError();
        Print("WebRequest error: ", error);
        
        if(error == 4060) {
            Print("URL not allowed. Add 'https://api.telegram.org' to allowed URLs in MT5");
        }
        return false;
    }
    
    if(res != 200) {
        Print("HTTP error code: ", res);
        return false;
    }
    
    return true;
}
//+------------------------------------------------------------------+
