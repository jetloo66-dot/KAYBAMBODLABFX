// StructureBasedEA_Complete_v2.0.mq5
// This Expert Advisor implements structure detection, 
// risk management, multi-timeframe confirmation, 
// telegram integration, and advanced trade logic.

#property strict

// Input parameters for the EA
input double TakeProfit = 50; // Take profit in points
input double StopLoss = 30; // Stop loss in points
input double RiskPercent = 2; // Risk percentage of account balance

// Telegram integration
string telegram_chat_id = "your_chat_id";
string telegram_token = "your_bot_token";

// Function to send message to Telegram
void SendTelegramMessage(string text) {
    string url = "https://api.telegram.org/bot" + telegram_token + "/sendMessage";
    string data = "{\"chat_id\":\"