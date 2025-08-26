#ifndef STRIPBUILDER_MQH
#define STRIPBUILDER_MQH

//#include "StripVisual.mqh"

#include "UnifiedRegimeModulesmqh.mqh"
#include <Arrays/ArrayObj.mqh>

class CStripVisual; 
class CRegimeSlice;  // Forward declaration

//Refactored Class Skeleton

/*
class CStripBuilder : public CObject
{
private:
   CArrayObj *zones;
   RegimeType currentRegime;
   private:
   CRegimeSlice *source;
   CStripVisual *m_renderer;


public:
   void Build();               // 🔧 Builds strips from zones
   void AddZone(CZoneInfo *zone);
   void Refresh();            // 🔁 Redraws all zones
   RegimeType GetActiveRegime();

   void SetSource(CRegimeSlice *_source)
   {
      this.source = _source;
   }

public:
   void SetRenderer(CStripVisual *renderer) {
      m_renderer = renderer;
   }

   void DispatchStrip(const SZoneMeta &meta) {
      if (m_renderer != NULL)
         m_renderer.Render(meta);
   }



private:
   void RenderZone(string timeframePrefix, string regimeTag, RegimeType regimeType, datetime t_start, datetime t_end, int index);
};
*/
class CRegimePhaseDetector;  // Forward declaration


// integration with stateless
class CStripBuilder : public CObject{
private:
   CStripVisual *m_renderer;

private:
   CArrayObj m_zones_csv;   // For H1 Tester mode
   CArrayObj m_zones_info;  // For M5 and Live mode
private:
   CRegimeSlice *m_source;

private:
   CArrayObj m_zones;

private:
   int m_activeRegime;

public:
   int GetActiveRegime();
   void SetActiveRegime(int regime);  // optional setter   

public:
   void SetRegimeSlice(CRegimeSlice *slice)
   {
      if (slice == NULL || CheckPointer(slice) != POINTER_DYNAMIC) return;
      m_source = slice;
   }

   CRegimeSlice *Source() { return m_source; }

public:
   void Build();   
   void RenderZone(CZoneCSV *zone); 
   void DispatchZones(CArrayObj *zones, RegimeType regime);

public:
   //void RenderOverlay(CZoneCSV *phase, CRegimePhaseDetector *detector);  // ← Must exist
   void RenderOverlay(string prefix, CZoneCSV *phase, CRegimePhaseDetector *detector);





void SetSource(CArrayObj *zones)
{
   if (zones == NULL || zones.Total() == 0) return;

   for (int i = 0; i < zones.Total(); i++)
   {
      CObject *obj = zones.At(i);
      if (obj == NULL || CheckPointer(obj) != POINTER_DYNAMIC) continue;

      string typeName = obj.ClassName();
      if (typeName == "CZoneCSV")
         AddZone((CZoneCSV *)obj);
      else if (typeName == "CZoneInfo")
         AddZone((CZoneInfo *)obj);
   }
}

void SetSource(CRegimeSlice *slice)
{
   if (slice == NULL) return;
   CArrayObj *zones = slice.GetZones();  // or however you access them
   SetSource(zones);  // reuse the existing method
}


public:
   void Refresh()
   {
      m_zones_csv.Clear();
      m_zones_info.Clear();
   }

   void AddZone(CZoneCSV *zone)
   {
      if (zone == NULL || CheckPointer(zone) != POINTER_DYNAMIC) return;
      m_zones_csv.Add(zone);
   }

   void AddZone(CZoneInfo *zone)
   {
      if (zone == NULL || CheckPointer(zone) != POINTER_DYNAMIC) return;
      m_zones_info.Add(zone);
   }      

public:
   void SetRenderer(CStripVisual *_renderer) {
      m_renderer = _renderer;
   }

   void RenderFinalMergedStrips(CArrayObj *zones) {
      if (m_renderer == NULL || zones == NULL) return;

      for (int i = 0; i < zones.Total(); ++i) {
         CZoneCSV *zone = (CZoneCSV *)zones.At(i);
         if (zone != NULL && CheckPointer(zone) == POINTER_DYNAMIC)
            m_renderer.RenderStrip(zone);  // Stateless rendering
      }
   }
};


void CStripBuilder::Build()
{
   // Example: iterate over zones and render strips
   for (int i = 0; i < m_zones.Total(); i++)
   {
      CObject *obj = m_zones.At(i);
      if (obj == NULL || CheckPointer(obj) != POINTER_DYNAMIC) continue;

      if (obj.ClassName() == "CZoneCSV")
      {
         CZoneCSV *zone = (CZoneCSV *)obj;
         RenderZone(zone);  // your rendering logic
      }
   }
}

void CStripBuilder::RenderZone(CZoneCSV *zone)
{
   if (zone == NULL) return;

   double priceLow = zone.price_low;
   double priceHigh = zone.price_high;
   datetime tStart = zone.t_start;
   datetime tEnd = zone.t_end;

   // Example rendering logic (replace with your own)
   PrintFormat("Rendering zone: %.2f–%.2f from %s to %s",
               priceLow, priceHigh,
               TimeToString(tStart), TimeToString(tEnd));

   // You could also call chart drawing functions here
}

int CStripBuilder::GetActiveRegime()
{
   return m_activeRegime;
}

void CStripBuilder::SetActiveRegime(int regime)
{
   m_activeRegime = regime;
}

void CStripBuilder::DispatchZones(CArrayObj *zones, RegimeType regime)
{
   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      zone.SetRegime(regime);  // assuming this method exists
      m_zones.Add(zone);       // or dispatch to chart, etc.
   }
}

//void CStripBuilder::RenderOverlay(CZoneCSV *phase, CRegimePhaseDetector *detector)
void CStripBuilder::RenderOverlay(string prefix, CZoneCSV *phase, CRegimePhaseDetector *detector)
{
   if (phase == NULL || detector == NULL) return;

   // Example rendering logic — customize as needed
   string _prefix = prefix;   //phase.GetPrefix();  // assuming CZoneCSV has this
   int subwin = 1;
   int offset = 0;
   StripMode mode = MODE_REGIME_PHASE;

   CStripVisual visual(_prefix, subwin, offset, mode);
   visual.RenderStrip(phase);  // or RenderToChart, depending on your overlay logic
}

/*
class CStripBuilder : public CObject
{

   private:
   CStripVisual *renderer;
   CArrayObj *zones;
   RegimeType currentRegime;  // if used

public:
   void Build();  // 🔧 This builds the strips from source zones
   RegimeType GetActiveRegime();  // 🔍 Returns current regime
   void AddZone(CZoneInfo *zone);
   void Refresh();


void SetRenderer(CStripVisual *visual) {
      renderer = visual;
 }   

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

// convert using stateless CStripVisual
void RenderZone(string timeframePrefix, string regimeTag, RegimeType regimeType, datetime t_start, datetime t_end, int index)
{
   int durationMin = (int)((t_end - t_start) / 60);
   string regimeLabel = MapRegimeLabel(regimeType);
   color regimeColor  = MapRegimeColor(regimeType);

   string label = StringFormat("%s-%s (%dm)", timeframePrefix, regimeLabel, durationMin);

   CStripVisual renderer(timeframePrefix, 1);
   renderer.RenderToChart(index, regimeColor, label, t_start, t_end);
}

public:   

void RenderFinalMergedStrips(CArrayObj *fusedZones) {
      static CStripDispatcher dispatcher;

      Print(__FUNCTION__ + " RenderFinalMergedStrips() in process ...");
      for (int i = 0; i < fusedZones.Total(); i++) {
         CZoneCSV *zone = (CZoneCSV*)fusedZones.At(i);
         if (zone == NULL) continue;

         zone.SetRenderIndex(i);
         zone.SetRenderLabel("Regime");

         RegimeType regime = zone.GetRegime();
         //dispatcher.Dispatch(fusedZones, regime);
         //renderer.RenderToChart(zone);  // ✅ Now valid
         //renderer.RenderToChart();  // ✅ Now valid
      }
      renderer.RenderToChart();  // ✅ Now valid  RENDER ONCE ONLY
   }

//use this one   
void RenderFinalMergedStrips(CArrayObj *fusedZones)
{
   Print(__FUNCTION__ + " RenderFinalMergedStrips() in process ...");

   for (int i = 0; i < fusedZones.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV*)fusedZones.At(i);
      if (zone == NULL || CheckPointer(zone) != POINTER_DYNAMIC)
      {
         Print("⚠️ Skipping invalid zone at index ", i);
         continue;
      }

      // Prepare rendering metadata
      zone.SetRenderIndex(i);

      string label = zone.GetLabel();       // e.g. "Zone 3 [BUY]"
      color zoneColor = zone.GetColor();    // e.g. clrLime

      PrintFormat("🖼️ Rendering Zone[%d]: %s | Color=%s", i, label, ColorToString(zoneColor));

      // Render this zone
      renderer.SetRenderIndex(i);  // if renderer tracks index
      renderer.RenderToChart(zoneColor, label);
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
      Print(__FUNCTION__ + " SetSource() in process ...it just assign: zones = sourceZones"); 
      
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

*/

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


/*
void CStripBuilder::Build() {   // BUGGY BECAUSE IT DOES LoadZonesFromEmbeddedCSV() !
   
   Print(__FUNCTION__ + " Build() in process ...");
   RegimeType regime = GetActiveRegime();

   zones = LoadZonesFromEmbeddedCSV();  // Uses embedded resource-based loader
   if (zones == NULL || zones.Total() == 0) return;

   //CStripDispatcher dispatcher;  // Make sure StripDispatcher is properly included
   //dispatcher.Dispatch(zones, regime);

   delete zones;
   zones = NULL;  // Prevent dangling pointer
}

RegimeType CStripBuilder::GetActiveRegime() {
   return currentRegime;
}
*/