//+------------------------------------------------------------------+
//|                                                  RegimeUtils.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "zoneinfo.mqh"

#ifndef __REGIMEUTILS_MQH__
#define __REGIMEUTILS_MQH__

#include "ZoneInfo.mqh"
#include "ZoneType.mqh"  // Ensure this enum is available

string DescribeRegime(CZoneInfo &zone)
{
   return zone.Tag();  // or zone.regime_tag
}

string ZoneTypeToString(ZoneType zt)
{
   switch (zt)
   {
      case ZONE_BUY:      return "Up";
      case ZONE_SELL:    return "Down";
      case ZONE_NEUTRAL: return "Neutral";
   }
   return "Unknown";
}

RegimeType ConvertZoneTypeToRegimeType(ZoneType ztype)
{
   switch (ztype)
   {
      case ZONE_BUY:      return REGIME_BUY;
      case ZONE_SELL:     return REGIME_SELL;
      case ZONE_NEUTRAL:  return REGIME_NEUTRAL;
      default:            return REGIME_NEUTRAL;
   }
}

RegimeType ConvertTagToRegimeType(string tag)
{
   if (tag == "Green") return REGIME_BUY;
   if (tag == "Red")   return REGIME_SELL;
   return REGIME_NEUTRAL;
}

string ZoneTypeToLabel(ZoneType type)
{
   switch (type)
   {
      case ZONE_BUY:      return "Buy";
      case ZONE_SELL:     return "Sell";
      case ZONE_NEUTRAL:  return "Neutral";
      default:            return "(Unknown)";
   }
}



#endif
