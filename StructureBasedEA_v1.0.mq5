#property strict

input double RiskPercentage = 1.0;  // Risk percentage for each trade
input string TelegramToken = "YOUR_TELEGRAM_BOT_TOKEN";  // Replace with your Telegram bot token
input long ChatID = YOUR_CHAT_ID;  // Replace with your chat ID

// Function to send message to Telegram
void SendTelegramMessage(string message) {
    string url = "https://api.telegram.org/bot" + TelegramToken + "/sendMessage";
    char post[] = "chat_id=" + IntegerToString(ChatID) + "&text=" + message;
    ResetLastError();
    int res = WebRequest("POST", url, post);
    if(res == -1) {
        Print("Error sending message: " + GetLastError());
    }
}

// Structure detection logic
void DetectMarketStructure() {
    double lastHigh = iHigh(NULL, 0, 1);
    double lastLow = iLow(NULL, 0, 1);
    double currentHigh = iHigh(NULL, 0, 0);
    double currentLow = iLow(NULL, 0, 0);

    if(currentHigh > lastHigh) {
        // Higher Highs detected
        SendTelegramMessage("New Higher High detected!");
    }
    if(currentLow < lastLow) {
        // Lower Lows detected
        SendTelegramMessage("New Lower Low detected!");
    }
}

// Risk management logic
double CalculateLotSize(double riskAmount) {
    double accountRisk = AccountBalance() * RiskPercentage / 100;
    return NormalizeDouble(accountRisk / riskAmount, 2);
}

// Main trading logic
void OnTick() {
    // Call market structure detection
    DetectMarketStructure();

    // Example of trade execution logic (to be defined based on your strategy)
    if(/* condition to buy */) {
        double lotSize = CalculateLotSize(/* risk amount */);
        SendTelegramMessage("Buying with lot size: " + DoubleToString(lotSize));
        // OrderSend(...);
    }
    if(/* condition to sell */) {
        double lotSize = CalculateLotSize(/* risk amount */);
        SendTelegramMessage("Selling with lot size: " + DoubleToString(lotSize));
        // OrderSend(...);
    }
}