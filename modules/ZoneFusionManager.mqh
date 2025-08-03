#ifndef __ZONEFUSIONMANAGER_MQH__
#define __ZONEFUSIONMANAGER_MQH__

#include "UnifiedRegimeModulesmqh.mqh"
#include <Arrays/Array.mqh>


class CZoneFusionManager
{
private:
   CArrayObj regimeSlice;
   CZoneAnalyzer  *analyzer;
   CStripBuilder *builder;
   CArrayObj      m_fusedZones;  // ✔ This holds the result of fusion
   int            handle;
   string         currentRegime;
   int            preloadBars;

   datetime fusedZones[];

public:
  void Fuse(CArrayObj *pLoadedZones);
  CArrayObj *GetFusedZones();
  CArrayObj *GetSlice() { return &regimeSlice; }


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

int SortByStart(const CObject *a, const CObject *b)
{
   const CZone *za = (const CZone*)a;
   const CZone *zb = (const CZone*)b;

   if (za.GetStart() < zb.GetStart()) return -1;
   if (za.GetStart() > zb.GetStart()) return 1;
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
         merged.Add(new CZone(current.GetStart(), current.GetEnd()));
         continue;
      }

      CZone *last = (CZone*)merged.At(merged.Total() - 1);
      if (current.GetStart() <= last.GetEnd())  // Overlap or touch
      {
         last.SetEnd(MathMax(last.GetEnd(), current.GetEnd()));
      }
      else
      {
         merged.Add(new CZone(current.GetStart(), current.GetEnd()));
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


 /*  
   void RefreshRegime(string tf)
   {
      CArrayObj *pZones = LoadRegimeZones(tf);
      if (pZones == NULL || pZones.Total() < 4) return;



      if (!TransferZoneInfos(sourceZones, targetZones)) {
         Print("🚫 No valid zones transferred — regimeSlice not updated.");
         return;
      }

      Print("✅ Zone transfer successful. zones.Total() = ", this.zones.Total());

      // 🔁 Step 1: Prepare regimeSlice – clear old contents
      regimeSlice.Clear();

      // 🔁 Step 2: Deep copy zones from pZones
      for (int i = 0; i < pZones.Total(); i++) {
         CObject *baseObj = pZones.At(i);

         if (baseObj == NULL || CheckPointer(baseObj) != POINTER_DYNAMIC) {
            Print("❌ Invalid pointer or object at index ", i);
            continue;
         }

         // 🔍 Confirm the object is actually a CZone
         if (baseObj.ClassName() != "CZone") {
            Print("❌ Object at index ", i, " is not a CZone (found ", baseObj.ClassName(), ")");
            continue;
         }

         CZone *origZone = (CZone *)baseObj;  // ✅ Now we're confident it's safe

         CZone *copyZone = new CZone();
         copyZone.Assign(origZone);
         regimeSlice.Add(copyZone);
      }

      // 🧪 Step 3: Diagnostic check before passing
      Print("🧪 Checking regimeSlice integrity before SetSource");
      for (int j = 0; j < regimeSlice.Total(); j++) {
         CObject *z = regimeSlice.At(j);
         if (z == NULL)
            Print("❌ NULL inside regimeSlice at index ", j);
         else {
            CZone *zoneObj = (CZone *)z;
            //Print("✅ regimeSlice[", j, "] = Zone ID: ", zoneObj.Id());
            Print("✅ regimeSlice[", j, "] = Zone: ", zoneObj.ToString());

         }
      }

      // 🚀 Step 4: Safe assignment to builder
      builder.SetSource(&regimeSlice);
   }
*/
void RefreshRegime(string tf)
{
   if (analyzer == NULL) {
      Print("❌ No analyzer linked. Cannot proceed with regime refresh.");
      return;
   }

   //const CArrayObj &sourceZones = analyzer.GetMergedZones();
   CArrayObj *sourceZones = analyzer.GetMergedZones();

   CArrayObj *zones = analyzer.GetZones();  // ✅ pointer assignment


   if (!TransferZoneInfos(sourceZones, &this.regimeSlice)) {
      Print("🚫 Zone transfer failed. Regime sync aborted.");
      return;
   }

   CArrayObj *pZones = LoadRegimeZones(tf);
   if (pZones == NULL || pZones.Total() < 4) return;

   regimeSlice.Clear();

   for (int i = 0; i < pZones.Total(); i++) {
      CZone *orig = dynamic_cast<CZone *>(pZones.At(i));
      if (!orig) {
         Print("❌ Invalid or non-CZone object at index ", i);
         continue;
      }

      CZone *copy = new CZone();
      copy.Assign(orig);
      regimeSlice.Add(copy);
   }

  // 🧪 Step 3: Diagnostic check before passing
      Print("🧪 Checking regimeSlice integrity before SetSource");
      for (int j = 0; j < regimeSlice.Total(); j++) {
         CObject *z = regimeSlice.At(j);
         if (z == NULL)
            Print("❌ NULL inside regimeSlice at index ", j);
         else {
            CZone *zoneObj = (CZone *)z;
            //Print("✅ regimeSlice[", j, "] = Zone ID: ", zoneObj.Id());
            Print("✅ regimeSlice[", j, "] = Zone: ", zoneObj.ToString());

         }
      }   

   Print("🧪 RegimeSlice loaded: ", regimeSlice.Total(), " zones");
   builder.SetSource(&regimeSlice);
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


void CZoneFusionManager::Fuse(CArrayObj *zonesToFuse) {
  if (zonesToFuse == NULL || zonesToFuse.Total() == 0) return;

  //ArraySort(zonesToFuse, WHOLE_ARRAY, 0, MODE_ASCEND);  // Sort by t_start  
  zonesToFuse.Sort(); //(CompareZonesByStart);

// Raw plotting loop (already handled)

   // 💡 Add after raw fusion
   if (builder != NULL)
      builder.RenderFinalMergedStrips(&m_fusedZones);  


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

/*
int CompareZonesByStart(CObject *a, CObject *b) {
   CZone *zoneA = (CZone *)a;
   CZone *zoneB = (CZone *)b;
   return zoneA.TimeStart() < zoneB.TimeStart() ? -1 :
          zoneA.TimeStart() > zoneB.TimeStart() ? 1 : 0;
}
*/