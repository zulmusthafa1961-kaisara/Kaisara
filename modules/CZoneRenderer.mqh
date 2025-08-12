#ifndef __CZONE_RENDERER_MQH__
#define __CZONE_RENDERER_MQH__

#include "UnifiedRegimeModulesmqh.mqh"

class CZoneRenderer
{
public:
   void RenderZones(CArrayObj *zones, int chartId, ENUM_TIMEFRAMES tf);
   void CleanupZones(CArrayObj *zones, int chartId);
};

#endif
 

void CZoneRenderer::RenderZones(CArrayObj *zones, int chartId, ENUM_TIMEFRAMES tf)
   {
      for (int i = 0; i < zones.Total(); i++)
      {
         CZoneCSV *zone = (CZoneCSV *)zones.At(i);
         if (zone == NULL) continue;

         string objName = zone.fingerprint();  // unique ID
         datetime tStart = zone.t_start;
         datetime tEnd   = zone.t_end;
         double priceLow = zone.price_low; 
         double priceHigh = zone.price_high;
         color zoneColor  = zone.GetRegimeColor(zone.GetRegime());

         ObjectCreate(chartId, objName, OBJ_RECTANGLE, 0, tStart, priceLow, tEnd, priceHigh);
         ObjectSetInteger(chartId, objName, OBJPROP_COLOR, zoneColor);
         ObjectSetInteger(chartId, objName, OBJPROP_WIDTH, 2);
         ObjectSetInteger(chartId, objName, OBJPROP_STYLE, STYLE_SOLID);
      }
   }


   void CZoneRenderer::CleanupZones(CArrayObj *zones, int chartId)
{
   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      string objName = zone.fingerprint();
      ObjectDelete(chartId, objName);
   }
}
