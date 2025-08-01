#ifndef __ZONEFUSIONMANAGER_MQH__
#define __ZONEFUSIONMANAGER_MQH__

#include "UnifiedRegimeModulesmqh.mqh"

class CZoneFusionManager
{
private:
   CZoneAnalyzer  analyzer;
   CStripBuilder *builder;
   CArrayObj      m_fusedZones;  // ✔ This holds the result of fusion
   int            handle;
   string         currentRegime;
   int            preloadBars;

public:
  void Fuse(CArrayObj *pLoadedZones);
  CArrayObj *GetFusedZones();

public:
   void Setup(CStripBuilder *builderRef, int bars = 300)
   {
      builder       = builderRef;
      preloadBars   = bars;
      currentRegime = "";
   }

   /*
   void UpdateZoneStrips(const double &zoneData[])
{
   // [1] Validate input data
   // [2] Clear existing strip visuals
   // [3] Apply zone merge logic
   // [4] Compute rendering coordinates
   // [5] Render updated strips
}
*/
/*
void UpdateZoneStrips(const double &zoneData[])
{
   if (ArraySize(zoneData) == 0)
   {
      Print("ZoneStrip Update skipped: Empty zoneData.");
      return;
   }

   // Optional: Check bounds or expected format if zoneData is structured
   // Example: if zoneData comes in pairs [start, end], validate pairs

   int count = ArraySize(zoneData);
   if (count % 2 != 0)
   {
      Print("ZoneStrip Update warning: Uneven data count — expected start/end pairs.");
      return;
   }

   Print("ZoneStrip Update initiated with ", count / 2, " zone(s).");
}
*/
/*
void UpdateZoneStrips(const double &zoneData[])
{
   if (ArraySize(zoneData) == 0 || ArraySize(zoneData) % 2 != 0)
   {
      Print("ZoneStrip Update skipped due to invalid input.");
      return;
   }

   // 🔄 Clear previous strip objects (e.g., graphical buffers, objects, etc.)
   const string prefix = "ZoneStrip_";
   int cleared = 0;

   for (int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if (StringFind(name, prefix) == 0)
      {
         ObjectDelete(name);
         cleared++;
      }
   }

   Print("ZoneStrip cleared: ", cleared, " old visuals removed.");

   // ✅ Ready for fresh render logic
}
*/
/*
void UpdateZoneStrips(const double &zoneData[])
{
   if (ArraySize(zoneData) == 0 || ArraySize(zoneData) % 2 != 0)
   {
      Print("ZoneStrip Update skipped due to invalid input.");
      return;
   }

   const string prefix = "ZoneStrip_";
   int cleared = 0;
   long chart_id = ChartID();

   for (int i = ObjectsTotal(chart_id) - 1; i >= 0; i--)
   {
      string name = ObjectName(chart_id, i);
      if (StringFind(name, prefix) == 0)
      {
         if (ObjectDelete(chart_id, name))
            cleared++;
      }
   }

   Print("ZoneStrip cleared: ", cleared, " old visuals removed.");
}
*/

int SortByStart(const CObject *a, const CObject *b)
{
   const CZone *za = (const CZone*)a;
   const CZone *zb = (const CZone*)b;
   if (za.start < zb.start) return -1;
   if (za.start > zb.start) return 1;
   return 0;
}


void MergeZones(const double &zoneData[], CArrayObj &merged)
{
   merged.Clear(); // Ensure it's fresh

   int count = ArraySize(zoneData) / 2;
   if (count == 0 || ArraySize(zoneData) % 2 != 0)
   {
      Print("MergeZones: Invalid input zoneData");
      return;
   }

   CArrayObj temp;

   for (int i = 0; i < count; i++)
   {
      double s = zoneData[i * 2];
      double e = zoneData[i * 2 + 1];
      temp.Add(new CZone(s, e));
   }

   //temp.Sort(SortByStart);

   temp.Sort();


   for (int i = 0; i < temp.Total(); i++)
   {
      CZone *current = (CZone*)temp.At(i);
      if (merged.Total() == 0)
      {
         merged.Add(new CZone(current.start, current.end));
         continue;
      }

      CZone *last = (CZone*)merged.At(merged.Total() - 1);
      if (current.start <= last.end)  // Overlap or touch
      {
         last.end = MathMax(last.end, current.end);
      }
      else
      {
         merged.Add(new CZone(current.start, current.end));
      }
   }

   Print("MergeZones: ", merged.Total(), " zones fused.");
}


   CArrayObj* LoadRegimeZones(string tf)
   {
      //do not purge in Tester mode
      if(OperationMode == ENUM_LIVE_ENV){
         analyzer.PurgeAllRects(); // 🧹 clear chart rectangles
      }

      //analyzer.PurgeAllRects(); // 🧹 clear chart rectangles

      if(OperationMode == ENUM_LIVE_ENV){
         ENUM_TIMEFRAMES tfEnum = (tf == "M5") ? PERIOD_M5 : PERIOD_H1;
         handle = iCustom(_Symbol, tfEnum, IndicatorFilename(), preloadBars);
      }   

      analyzer.LoadFromChart(tf);    // 🧲 pick up rectangles
      analyzer.BuildTaggedZones();   // 🏷️ tag them appropriately

      currentRegime = tf;
      return analyzer.GetZones();    // 📦 return merged & tagged zones
   }

   void RefreshRegime(string tf)
   {
      CArrayObj *pZones = LoadRegimeZones(tf);
      if (pZones == NULL || pZones.Total() < 4) return;

      CArrayObj sliced;
      for (int i = pZones.Total() - 4; i < pZones.Total(); i++)
         sliced.Add(pZones.At(i));

      builder.SetSource(&sliced); // 🎯 send to renderer
   }

   void MergeHourEndZones()
   {
      analyzer.PurgeAllRects();

      CArrayObj *m5Zones = LoadRegimeZones("M5");
      CArrayObj *h1Zones = LoadRegimeZones("H1");

      CArrayObj fused;
      if (m5Zones != NULL)
         for (int i = 0; i < m5Zones.Total(); i++) fused.Add(m5Zones.At(i));
      if (h1Zones != NULL)
         for (int i = 0; i < h1Zones.Total(); i++) fused.Add(h1Zones.At(i));

      CArrayObj recent;
      for (int i = fused.Total() - 4; i < fused.Total(); i++)
         recent.Add(fused.At(i));

      builder.SetSource(&recent); // 🚀 unified fusion strip update
   }

   string ActiveRegime() { return currentRegime; }
};

#endif


/*
  // Optionally: Sort or filter internal zone array post-fusion
void CZoneFusionManager::Fuse(CArrayObj *zonesToFuse) {
  if (zonesToFuse == NULL || zonesToFuse.Total() == 0) return;

  for (int i = 0; i < zonesToFuse.Total(); ++i) {
    //CZoneAnalyzer *zone = (CZoneAnalyzer *)zonesToFuse.At(i);
    CZoneAnalyzer *zone = dynamic_cast<CZoneAnalyzer *>(zonesToFuse.At(i));
    if (zone == NULL) continue;

    zone.MergeZones();  // 💡 Replaces MergeZone(zone)
  }
}
*/

void CZoneFusionManager::Fuse(CArrayObj *zonesToFuse) {
  if (zonesToFuse == NULL || zonesToFuse.Total() == 0) return;

for (int i = 0; i < zonesToFuse.Total(); ++i)
{
   CObject *obj = zonesToFuse.At(i);
   if (obj == NULL)
   {
      Print("❌ Null object at index ", i);
      continue;
   }

   Print("🔍 Zone type at index ", i, ": ", obj.ClassName());

   CZoneAnalyzer *zone = dynamic_cast<CZoneAnalyzer *>(obj);
   if (zone == NULL)
   {
      Print("⚠️ Skipping non-CZoneAnalyzer object(s) at index ", i);
      continue;
   }

   // ✅ Safe to use 'zone' here as a fully valid CZoneAnalyzer

   datetime start = zone.GetStartTime(i);     
   datetime end   = zone.GetEndTime(i);
   color zoneColor = clrOrange;

   RegimeType regime = zone.GetRegimeType(i);
   if (regime == REGIME_SELL)
      zoneColor = clrTomato;
   else if (regime == REGIME_BUY)
      zoneColor = clrLime;

   string label = "RAWZONE_" + IntegerToString(i);
   zone.PlotZone(start, end, zoneColor);  // ✅ dispatch directly via zone instance
}


}


CArrayObj* CZoneFusionManager::GetFusedZones() {
  return &m_fusedZones;
}

