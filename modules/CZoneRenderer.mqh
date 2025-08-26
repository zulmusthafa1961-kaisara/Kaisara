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
   if (zones == NULL || zones.Total() == 0)
   {
      Print("⚠️ No zones to render.");
      return;
   }
   
   CStripVisual stripRenderer("Z", 1, 0, MODE_M5_ZONE);  // Prefix, subwindow, alignment

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      stripRenderer.RenderStrip(zone);
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
