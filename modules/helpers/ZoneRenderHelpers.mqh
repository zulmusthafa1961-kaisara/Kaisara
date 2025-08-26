#ifndef __ZONE_RENDER_HELPERS__
#define __ZONE_RENDER_HELPERS__

#include "..\UnifiedRegimeModulesmqh.mqh"
#include "../StripVisual.mqh"


//#include <CZoneCSV.mqh>        // embedded via UnifiedRegimeModulesmqh.mqh
//#include <CStripVisual.mqh>    // embedded via UnifiedRegimeModulesmqh.mqh

//void RenderZonesToStrip(CArrayObj *zones, string prefix, int subwin, int mode)
void RenderZonesToStrip(CArrayObj *zones, string prefix, int subwin, StripMode mode)
{
   if (zones == NULL || zones.Total() == 0) return;

   for (int i = 0; i < zones.Total(); i++) {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      CStripVisual visual(prefix, 1, 0, mode);
      visual.RenderStrip(zone);
   }
}

#endif
