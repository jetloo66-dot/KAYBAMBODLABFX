#ifndef KBLX_ALERT_ENGINE_MQH
#define KBLX_ALERT_ENGINE_MQH

#include "..\Core\Types.mqh"

class CKBLXAlertEngine
{
private:
   string m_token;
   string m_chat_id;
   bool m_enabled;

   string UrlEncode(const string value)
   {
      uchar bytes[];
      int length = StringToCharArray(value, bytes, 0, WHOLE_ARRAY, CP_UTF8);
      string encoded = "";
      for(int i = 0; i < length - 1; i++)
      {
         uchar c = bytes[i];
         if((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') || c == '-' || c == '_' || c == '.' || c == '~')
            encoded += CharToString(c);
         else
            encoded += StringFormat("%%%02X", c);
      }
      return encoded;
   }

public:
   void Configure(const bool enabled, const string token, const string chat_id)
   {
      m_enabled = enabled;
      m_token = token;
      m_chat_id = chat_id;
   }

   void Notify(const string message, const bool push_enabled)
   {
      Alert(message);
      if(push_enabled)
         SendNotification(message);
      if(!m_enabled || m_token == "" || m_chat_id == "")
         return;

      string url = "https://api.telegram.org/bot" + m_token + "/sendMessage";
      string body = "chat_id=" + UrlEncode(m_chat_id) + "&text=" + UrlEncode(message);
      char data[];
      char result[];
      string result_headers;
      int length = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
      if(length <= 1)
         return;
      ArrayResize(data, length - 1);
      string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
      ResetLastError();
      int status = WebRequest("POST", url, headers, 5000, data, result, result_headers);
      if(status < 200 || status >= 300)
         PrintFormat("KBLX Telegram request failed; HTTP status %d, error %d", status, GetLastError());
   }

   void NotifySignal(const KBLXSignal &signal, const double stop, const double target,
                     const double volume, const bool push_enabled)
   {
      string message = StringFormat("KBLX %s %s %s | entry %.*f SL %.*f TP %.*f volume %.2f setup %s",
                       signal.direction == KBLX_DIRECTION_BUY ? "BUY" : "SELL",
                       signal.symbol, EnumToString(signal.primary_timeframe),
                       (int)SymbolInfoInteger(signal.symbol, SYMBOL_DIGITS), signal.entry,
                       (int)SymbolInfoInteger(signal.symbol, SYMBOL_DIGITS), stop,
                       (int)SymbolInfoInteger(signal.symbol, SYMBOL_DIGITS), target,
                       volume, signal.id);
      Notify(message, push_enabled);
   }
};

#endif
