#ifndef __ZONEANALYZER_MQH__
#define __ZONEANALYZER_MQH__

#include "ZoneType.mqh"
#include "ZoneInfo.mqh"

class CZoneAnalyzer
{
//new
class CZoneAnalyzer : public CObject
{
private:
   CArrayObj rects;         // Raw rectangles from chart
   CArrayObj zones;         // Merged zone candidates
   CArrayObj mergedZones;   // Final tagged zones
   string prefix;

public:
   void SetPrefix(string p) { prefix = p; }
   string Prefix() const { return prefix; }
   void LoadFromChart(string p);       // Must be declared
   void MergeZones();                  // Must be declared
   void BuildTaggedZones();            // Must be declared
   void CheckRegimeTags();             // Must be declared
   CZoneAnalyzer() {}

   int RawZoneCount() const { return rects.Total(); }
   int MergedZoneCount() const { return zones.Total(); }
   int TaggedZoneCount() const { return mergedZones.Total(); }

   CArrayObj* GetTaggedZones() { return &mergedZones; }


   void LoadAllRectangles()
   {
      rects.Clear();

      int total = ObjectsTotal(0);
      PrintFormat("📋 Scanning %d chart objects...", total);

      for (int i = 0; i < total; i++)
      {
         string name = ObjectName(0,i);
         //if (ObjectType(0,name) != OBJ_RECTANGLE)
         if (ObjectGetInteger(0, name, OBJPROP_TYPE) != OBJ_RECTANGLE)
            continue;
            
            
         datetime t1 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 0);
         datetime t2 = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME, 1);
         double p1 = ObjectGetDouble(0, name, OBJPROP_PRICE, 0);
         double p2 = ObjectGetDouble(0, name, OBJPROP_PRICE, 1);    

         datetime t_start = MathMin(t1, t2);
         datetime t_end   = MathMax(t1, t2);
         double price_low  = MathMin(p1, p2);
         double price_high = MathMax(p1, p2);

         CRectInfo *ri = new CRectInfo;
         ri.name       = name;
         ri.t1         = t_start;
         ri.t2         = t_end;
         ri.pLow       = price_low;
         ri.pHigh      = price_high;

         rects.Add(ri);

         PrintFormat("→ Rect %s: %s → %s | %.2f → %.2f",
                     name,
                     TimeToString(t_start),
                     TimeToString(t_end),
                     price_low,
                     price_high);
      }

      PrintFormat("✅ Loaded %d rectangles", rects.Total());
   }

   // ... other methods: MergeZones(), BuildTaggedZones(), CheckRegimeTags(), etc.
};

#endif