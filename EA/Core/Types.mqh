#ifndef KBLX_TYPES_MQH
#define KBLX_TYPES_MQH

enum KBLXDirection
{
   KBLX_DIRECTION_SELL = -1,
   KBLX_DIRECTION_NONE = 0,
   KBLX_DIRECTION_BUY = 1
};

enum KBLXSwingType
{
   KBLX_SWING_HIGH = 1,
   KBLX_SWING_LOW = -1
};

enum KBLXTrend
{
   KBLX_TREND_NEUTRAL = 0,
   KBLX_TREND_UP = 1,
   KBLX_TREND_DOWN = -1,
   KBLX_TREND_TRANSITION = 2
};

enum KBLXBreakType
{
   KBLX_BREAK_NONE = 0,
   KBLX_BREAK_BOS = 1,
   KBLX_BREAK_CHOCH = 2
};

enum KBLXRetracement
{
   KBLX_RETRACE_NONE = 0,
   KBLX_RETRACE_A = 1,
   KBLX_RETRACE_B = 2,
   KBLX_RETRACE_C = 3,
   KBLX_RETRACE_D = 4
};

enum KBLXBreakConfirmation
{
   KBLX_CLOSE_ONLY = 0,
   KBLX_INTRABAR = 1,
   KBLX_EITHER = 2
};

enum KBLXBreakSelection
{
   KBLX_CHOCH_ONLY = 0,
   KBLX_BOS_ONLY = 1,
   KBLX_CHOCH_OR_BOS = 2,
   KBLX_CHOCH_AND_BOS = 3
};

enum KBLXRetracementMode
{
   KBLX_RETRACE_ANY = 0,
   KBLX_RETRACE_ALL = 1,
   KBLX_RETRACE_FIRST_VALID = 2,
   KBLX_RETRACE_PRIORITY = 3,
   KBLX_RETRACE_CONFLUENCE_REQUIRED = 4
};

enum KBLXPrimaryGateMode
{
   KBLX_PRIMARY_GATE_ANY = 0,
   KBLX_PRIMARY_GATE_ALL = 1
};

enum KBLXMTFMode
{
   KBLX_MTF_SINGLE = 0,
   KBLX_MTF_MULTIPLE = 1,
   KBLX_MTF_ALL = 2
};

enum KBLXExecutionMode
{
   KBLX_MARKET_ONLY = 0,
   KBLX_PENDING_ONLY = 1,
   KBLX_MARKET_AND_PENDING = 2,
   KBLX_AUTO_EXECUTION = 3
};

enum KBLXSizingMode
{
   KBLX_FIXED_LOT = 0,
   KBLX_RISK_PERCENT = 1,
   KBLX_RISK_MONEY = 2,
   KBLX_DYNAMIC_RISK = 3
};

enum KBLXStopMode
{
   KBLX_SL_FIXED_DISTANCE = 0,
   KBLX_SL_ZONE_BASED = 1,
   KBLX_SL_SWING_BASED = 2,
   KBLX_SL_ATR_BASED = 3,
   KBLX_SL_MANUAL = 4,
   KBLX_SL_HYBRID = 5
};

enum KBLXTakeProfitMode
{
   KBLX_TP_RR = 0,
   KBLX_TP_STRUCTURE = 1,
   KBLX_TP_FIBONACCI = 2,
   KBLX_TP_MANUAL = 3
};

struct KBLXSwingPoint
{
   KBLXSwingType type;
   double price;
   datetime pivot_time;
   datetime confirmed_time;
   int shift;
};

struct KBLXZone
{
   double low;
   double high;
   datetime created;
   datetime expires;
   bool valid;
};

struct KBLXStructure
{
   double hh[5];
   double hl[5];
   double lh[5];
   double ll[5];
   datetime hh_time[5];
   datetime hl_time[5];
   datetime lh_time[5];
   datetime ll_time[5];
   int hh_count;
   int hl_count;
   int lh_count;
   int ll_count;
   double latest_high;
   double latest_low;
   datetime latest_high_time;
   datetime latest_low_time;
   KBLXTrend trend;
   bool valid;
};

struct KBLXSignal
{
   string id;
   string symbol;
   KBLXDirection direction;
   ENUM_TIMEFRAMES primary_timeframe;
   ENUM_TIMEFRAMES confirmation_timeframe;
   KBLXBreakType break_type;
   KBLXRetracement retracement;
   KBLXZone zone;
   double entry;
   double invalidation;
   double target_reference;
   double score;
   datetime created;
   bool valid;
};

#endif
