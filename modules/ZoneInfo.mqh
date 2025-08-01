//+------------------------------------------------------------------+
//|                                                     ZoneInfo.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#ifndef __ZONEINFO_MQH__
#define __ZONEINFO_MQH__

#include "RegimeTypes.mqh"

/*
// Enum for regime types
enum RegimeType
{
   ZONE_BUY,
   ZONE_SELL,
   ZONE_CONSOLIDATE,
   ZONE_NEUTRAL,
   ZONE_NONE
};
*/

#include <Arrays\ArrayObj.mqh>
#include "ZoneType.mqh"
#include <Arrays\ArrayInt.mqh>  // For CArrayInt specifically
#include <Arrays\List.mqh>      // General array helpers

class CZoneInfo : public CObject
{

public:
   datetime t_start, t_end;
   double price_high, price_low;
   int rect_count;

   ZoneType zone_type;         // Directional zone info (Up/Down/etc.)
   string regime_tag;          // Semantic label for regime (Accumulation, Buy Bias, etc.)
   RegimeType regime_type;

   CArrayInt *rect_indices;    // Array of rect indices (must be pointer in MT5)
   int sorted_index;           // Chronological index after SortZonesByStartTime
   
   virtual int Compare(const CObject *a, const CObject *b) 
{
   const CZoneInfo *za = (const CZoneInfo *)a;
   const CZoneInfo *zb = (const CZoneInfo *)b;
   if (za == NULL || zb == NULL) return 0;

   return (int)(za.t_start - zb.t_start);
}

   // Constructor
   CZoneInfo()
   {
      rect_indices = new CArrayInt;
      rect_indices.Clear();
   }

   // Destructor
   ~CZoneInfo()
   {
      delete rect_indices;
      rect_indices = NULL;
   }

   // Accessors
   datetime TStart() const { return t_start; }
   datetime TEnd() const { return t_end; }
   double PriceHigh() const { return price_high; }
   double PriceLow() const { return price_low; }
   int Count() const { return rect_count; }

   string Tag() const { return regime_tag; }
   string RegimeTag() const { return regime_tag; }
   ZoneType GetZoneType() const { return zone_type; }
   RegimeType GetRegimeType() const { return regime_type; }

   // Setter
   void Set(datetime a, datetime b, double hi, double lo, int count, string tag, RegimeType rtype);
};

#endif  // Close include guard

// Function definition placed AFTER the #endif, which is allowed and will compile
void CZoneInfo::Set(datetime a, datetime b, double hi, double lo, int count, string tag, RegimeType rtype)
{
   t_start     = a;
   t_end       = b;
   price_high  = hi;
   price_low   = lo;
   rect_count  = count;
   regime_tag  = tag;
   regime_type = rtype;
}
