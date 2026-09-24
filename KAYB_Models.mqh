#property strict

enum ENUM_KAYBTrend
{
   KAYB_TREND_NONE = 0,
   KAYB_TREND_UP,
   KAYB_TREND_DOWN
};

enum ENUM_KAYBFilterMode
{
   KAYB_FILTER_ANY = 0,
   KAYB_FILTER_ALL = 1,
   KAYB_FILTER_PRIORITY = 2
};

enum ENUM_KAYBDistanceMode
{
   KAYB_DIST_AUTO = 0,
   KAYB_DIST_PIPS = 1,
   KAYB_DIST_POINTS = 2
};

enum ENUM_KAYBLimitMode
{
   KAYB_LIMIT_NONE = 0,
   KAYB_LIMIT_MINUTE = 1,
   KAYB_LIMIT_HOUR = 2,
   KAYB_LIMIT_SESSION = 3,
   KAYB_LIMIT_DAY = 4
};

enum ENUM_KAYBValueMode
{
   KAYB_VALUE_PERCENT = 0,
   KAYB_VALUE_MONEY = 1
};

enum ENUM_KAYBPartialTrigger
{
   KAYB_PARTIAL_AT_1R = 0,
   KAYB_PARTIAL_AT_HALF_R = 1
};

struct KAYBWorkflow
{
   bool enabled;
   ENUM_TIMEFRAMES analysisTf;
   ENUM_TIMEFRAMES confirmTf;
   string label;
};

struct KAYBSwing
{
   double price;
   datetime time;
   int index;
};

struct KAYBStructureState
{
   bool valid;
   ENUM_KAYBTrend trend;
   double hh[3];
   double hl[3];
   double ll[3];
   double lh[3];
   bool bosUp;
   bool bosDown;
   bool chochUp;
   bool chochDown;
   double lastBreakLevel;
   datetime lastBreakTime;
};

struct KAYBSetupSignal
{
   bool valid;
   bool isBuy;
   bool fromReversal;
   string setupTag;
   string filterTag;
   string workflowLabel;
   ENUM_TIMEFRAMES timeframe;
   datetime signalTime;
   double entry;
   double stop;
   double tp;
   double zoneLow;
   double zoneHigh;
   string reason;
};

struct KAYBTradeMemoryRecord
{
   datetime closeTime;
   string symbol;
   int magic;
   string setupTag;
   string filterTag;
   double profit;
   int direction;
};

struct KAYBLimitSnapshot
{
   datetime anchor;
   double startEquity;
   bool blocked;
   string reason;
};
