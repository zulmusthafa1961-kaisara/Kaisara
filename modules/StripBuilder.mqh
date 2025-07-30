#ifndef STRIPBUILDER_MQH
#define STRIPBUILDER_MQH

#include "UnifiedRegimeModulesmqh.mqh"
#include <Arrays/ArrayObj.mqh>

class CStripBuilder : public CObject
{

public:
    void AddZone(CZoneInfo *zone);
    void Refresh();

private:
   // Labeling + color logic
   static CStripVisual *ConvertToStripVisual(string timeframePrefix, string regimeTag, RegimeType regimeType, datetime t_start, datetime t_end) {
      CStripVisual* sv = new CStripVisual(timeframePrefix, 1);


      int durationMin = (int)((t_end - t_start) / 60);
      string regimeLabel = MapRegimeLabel(regimeType);
      color regimeColor  = MapRegimeColor(regimeType);

      sv.label   = StringFormat("%s-%s (%dm)", timeframePrefix, regimeLabel, durationMin);  // e.g., "H1-Up (22m)"
      sv.clr   = regimeColor;
      sv.t_start = t_start;
      sv.t_end   = t_end;

      return sv;
   }


public:
   // Build from CZoneCSV (used in strategy tester)
   static void BuildFromCSVZones(CArrayObj *source, CArrayObj *targetBoxes, string tfPrefix = "H1") {
      targetBoxes.Clear();
      const int count = MathMin(4, source.Total());

      for (int i = source.Total() - count; i < source.Total(); i++) {
         CZoneCSV *zone = dynamic_cast<CZoneCSV *>(source.At(i));
         if (!zone) continue;

         targetBoxes.Add(ConvertToStripVisual(tfPrefix, zone.regime_tag, zone.GetRegimeType(), zone.t_start, zone.t_end));
      }
   }

   // Build from CMergedZone (used in live environment)
   static void BuildFromMergedZones(CArrayObj *source, CArrayObj *targetBoxes, string tfPrefix = "M5") {
      targetBoxes.Clear();
      const int count = MathMin(4, source.Total());

      for (int i = source.Total() - count; i < source.Total(); i++) {
         CZoneCSV *zone = dynamic_cast<CZoneCSV *>(source.At(i));
         if (!zone) continue;

         targetBoxes.Add(ConvertToStripVisual(tfPrefix, zone.regime_tag, zone.GetRegimeType(), zone.t_start, zone.t_end));
      }
   }

   // Friendly regime label
   static string MapRegimeLabel(RegimeType regimeType) {
      switch(regimeType) {
         case REGIME_BUY:       return "Up";
         case REGIME_SELL:     return "Dn";
         //case REGIME_PULLBACK:       return "PB";
         //case REGIME_CONSOLIDATION:  return "Side";
         default:                    return "N/A";
      }
   }



   // Consistent regime colors
   static color MapRegimeColor(RegimeType regimeType) {
      switch(regimeType) {
         case REGIME_BUY:       return clrForestGreen;
         case REGIME_SELL:     return clrFireBrick;
         //case REGIME_PULLBACK:       return clrOrange;
         //case REGIME_CONSOLIDATION:  return clrGray;
         default:                    return clrSilver;
      }
   }
};

#endif