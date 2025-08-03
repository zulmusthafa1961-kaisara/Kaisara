#ifndef STRIPBUILDER_MQH
#define STRIPBUILDER_MQH

#include "StripVisual.mqh"

#include "UnifiedRegimeModulesmqh.mqh"
#include <Arrays/ArrayObj.mqh>

class CStripBuilder : public CObject
{

   private:
   CArrayObj *zones;
   RegimeType currentRegime;  // if used

public:
   void Build();  // 🔧 This builds the strips from source zones
   RegimeType GetActiveRegime();  // 🔍 Returns current regime
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
void RenderFinalMergedStrips(CArrayObj *fusedZones) {
   for (int i = 0; i < fusedZones.Total(); i++) {
      CZone *zone = (CZone*)fusedZones.At(i);
      if (zone == NULL) continue;

      double start = zone.GetStart();
      double end   = zone.GetEnd();
      RegimeType regime = zone.GetRegime();
      color zoneColor = clrOrange;

      if (regime == REGIME_SELL) zoneColor = clrTomato;
      else if (regime == REGIME_BUY) zoneColor = clrLime;

      zone.PlotZone((datetime)start, (datetime)end, zoneColor); // Typecast if needed
   }
}


void DispatchZones(CArrayObj *zoneList, RegimeType regime)
{
   static CStripDispatcher dispatcher;
   dispatcher.Dispatch(zoneList, regime);
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

   void SetSource(CArrayObj *sourceZones) {
    zones = sourceZones;
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

void AssignRenderIndex(CArrayObj &arr)
{
   for (int i = 0; i < arr.Total(); i++)
   {
      ((CStripVisual*) arr.At(i)).SetIndex(i);
   }
}


void Dispatch(CArrayObj *zones, RegimeType regime) {
   if (zones == NULL) {
      Print("❌ No zones to dispatch.");
      return;
   }



   int total = zones.Total();
   PrintFormat("🟢 Dispatching %d zone(s) for regime: %s", total, EnumToString(regime));

   for (int i = 0; i < total; i++) {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL || zone.ClassName() != "CZoneCSV") continue;

      PrintFormat("• Zone #%d | %s [%s] | t_start=%s | t_end=%s | Price Range=%.2f - %.2f",
                  i + 1,
                  zone.regime_tag,
                  zone.GetRegimeTypeName(),
                  TimeToString(zone.t_start),
                  TimeToString(zone.t_end),
                  zone.price_low,
                  zone.price_high);
   }
}



#endif
/*
void CStripBuilder::Build() {
  // Step 1: Determine active regime
  RegimeType regime = GetActiveRegime();
  Print("Building strips for regime: ", EnumToString(regime));

  // Step 2: Load zones from resource
  ZoneLoader loader;
  CArrayObj *zones = loader.LoadMergedZones(regime);  // abstracted loading per regime

  if (zones == NULL || zones.Total() == 0) {
    Print("No zones loaded for regime: ", EnumToString(regime));
    return;
  }

  // Step 3: Fusion if needed
  ZoneFusionManager fusionManager;
  CArrayObj *mergedZones = fusionManager.Fuse(zones, regime);  // respects regime merge logic

  // Step 4: Dispatch strips
  StripDispatcher dispatcher;
  dispatcher.Dispatch(mergedZones, regime);

  // Step 5: Visualize
  RegimeVisualizer visualizer;
  visualizer.Render(mergedZones, regime);

  // Step 6: Cleanup
  delete zones;
  delete mergedZones;
}
*/

/*
void CStripBuilder::Build() {
  RegimeType regime = GetActiveRegime();

 zones = LoadZonesFromEmbeddedCSV();

  CArrayObj *zones = loader.LoadMergedZones(regime);
  if (zones == NULL || zones.Total() == 0) return;

  StripDispatcher dispatcher;
  dispatcher.Dispatch(zones, regime);

  delete zones;
}
*/

void CStripBuilder::Build() {
   RegimeType regime = GetActiveRegime();

   zones = LoadZonesFromEmbeddedCSV();  // Uses embedded resource-based loader
   if (zones == NULL || zones.Total() == 0) return;

   CStripDispatcher dispatcher;  // Make sure StripDispatcher is properly included
   dispatcher.Dispatch(zones, regime);

   delete zones;
   zones = NULL;  // Prevent dangling pointer
}

RegimeType CStripBuilder::GetActiveRegime() {
   return currentRegime;
}
