#ifndef __ZONETYPES_MQH__
#define __ZONETYPES_MQH__

#include <Arrays\ArrayObj.mqh>
#include "RegimeTypes.mqh"


enum ZoneType
{
   ZONE_BUY,
   ZONE_SELL,
   ZONE_NEUTRAL,
   ZONE_UNKNOWN
};


/*
enum ZoneType
{
   None = -1,  // Optional fallback
   Up,
   Down,
   Neutral,
   Bullish,
   Bearish
};
*/

// 🔸 Rectangle object info
class CRectInfo : public CObject
{
public:
   virtual string ClassName() const { return "CRectInfo"; }
   datetime t_start, t_end; //t1, t2;
   double price_high, price_low; //pHigh, pLow;
   
   string name;
   string colorname;
   
   ZoneType zone_type;       // Matches active.zone_type
   //int regime_type;          // Use enum if available
   RegimeType regime_type;
   string regime_tag;        // Replace tag   
   string tag;

   void Set(datetime a, datetime b, double hi, double lo, string clrstring)
   {
      t_start = a;
      t_end = b;
      price_high = hi;
      price_low  = lo;
      colorname = clrstring;
   }

   virtual int Compare(const CObject *node, const int mode = 0) const
   {
      const CRectInfo *other = (const CRectInfo *)node;
      if (t_start < other.t_start) return -1;
      if (t_start > other.t_start) return 1;
      return 0;
   }
};

// 🧠 Additional meta-info per zone
struct ZoneInfo
{
   datetime t_start, t_end;
   double price_high, price_low;
   int rect_count;
   string regime_tag;
   ZoneType regime_type;  // ➕ Add this for classification
};

#endif

