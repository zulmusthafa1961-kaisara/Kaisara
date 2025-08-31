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


// new
void RenderRegimePhaseOverlay(RegimePhase phase, double confidence) {
   const int subwin = 1;           // Subwindow 1 for diagnostic overlays
   const int leftMargin = 680;     // Right strip for regime phase
   string label[4] = {"BREAKOUT", "CHOPPY", "PULLBACK", "CONTINUATION"};
   string content[4];
   color boxColor[4] = {clrGray, clrGray, clrGray, clrGray};

   for(int i = 0; i < 4; i++) {
      content[i] = label[i] + "\nConfidence: " + DoubleToString(confidence, 2);
   }

   switch(phase) {
      case PHASE_BREAKOUT:      boxColor[0] = clrGreen; break;
      case PHASE_CHOPPY:        boxColor[1] = clrOrange; break;
      case PHASE_PULLBACK:      boxColor[2] = clrRed; break;
      case PHASE_CONTINUATION:  boxColor[3] = clrBlue; break;
   }

   CStationaryRectangles4Box box;
   box.SetSubWindow(subwin);
   box.SetLeftMargin(leftMargin);
   box.SetBoxGap(BOX_GAP);
   box.SetBoxDimensions(BOX_W, BOX_H);
   box.SetTopMargin(TOP_MARGIN);
   box.Initialize();
   box.ClearBoxes();
   box.Create();
   box.UpdateLabels(content[0], content[1], content[2], content[3]);
   box.UpdateColors(boxColor[0], boxColor[1], boxColor[2], boxColor[3]);
}

void SafeDelete(CArrayObj *&zoneArray, string label)
{
   if (zoneArray != NULL)
   {
      Print("🧹 SafeDelete: ", label, " count before delete = ", zoneArray.Total());
      delete zoneArray;
      zoneArray = NULL;
      Print("✅ SafeDelete: ", label, " deleted and nulled");
   }
   else
   {
      Print("⚠️ SafeDelete: ", label, " was already NULL");
   }
}


#endif
