#ifndef __REGIME_VISUALIZER_MQH__
#define __REGIME_VISUALIZER_MQH__

#include "StationaryRectangles4Box.mqh"
#include "ZoneType.mqh"
#include "ZoneLoader.mqh"

class CZoneCSV;

class CRegimeVisualizer {
private:
   CStationaryRectangles4Box *leftBoxes;
   CStationaryRectangles4Box *rightBoxes;

public:
   CRegimeVisualizer() {
      leftBoxes = new CStationaryRectangles4Box("Left_");
      rightBoxes = new CStationaryRectangles4Box("Right_");
   }

   void Draw(CZoneCSV *zone) {
      if (!zone || zone.t_start > TimeCurrent() || zone.t_end < TimeCurrent())
         return;

      string stripName = "ZoneStrip_" + TimeToString(zone.t_start) + "_" + zone.regime_tag;
      color regimeColor = GetRegimeColor(zone.regime_type);

      bool alignLeft = ShouldDrawLeft(zone.regime_tag);
      if (alignLeft)
         leftBoxes.Draw(stripName, zone.t_start, regimeColor, true);
      else
         rightBoxes.Draw(stripName, zone.t_start, regimeColor, false);
   }

private:
   bool ShouldDrawLeft(string tag) {
      return (StringFind(tag, "Buy") >= 0 || StringFind(tag, "Green") >= 0);
   }

   color GetRegimeColor(int type) {
      switch (type) {
         case REGIME_BUY: return clrGreen;
         case REGIME_SELL: return clrRed;
         default: return clrGray;
      }
   }
};
#endif
