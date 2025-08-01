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

   CArrayObj* LoadRegimeZones(string tf)
   {
      analyzer.PurgeAllRects(); // 🧹 clear chart rectangles


      ENUM_TIMEFRAMES tfEnum = (tf == "M5") ? PERIOD_M5 : PERIOD_H1;
      handle = iCustom(_Symbol, tfEnum, IndicatorFilename(), preloadBars);

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
      Print("⚠️ Skipping non-CZoneAnalyzer object at index ", i);
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

