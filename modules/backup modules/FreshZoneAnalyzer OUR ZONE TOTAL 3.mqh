#ifndef __FRESHZONEANALYZER_MQH__
#define __FRESHZONEANALYZER_MQH__
#property strict

#include <Object.mqh>
#include "ZoneType.mqh"
#include "ZoneInfo.mqh"
#include "RegimeUtils.mqh"

int ZoneCompareByStartTime(const CObject *a, const CObject *b)
{
   const CZoneInfo *za = (const CZoneInfo *)a;
   const CZoneInfo *zb = (const CZoneInfo *)b;
   if (za == NULL || zb == NULL) return 0;

   return (int)(za.t_start - zb.t_start);
}
 int CompareZones(const CObject *a, const CObject *b)
{
   const CZoneInfo *za = (const CZoneInfo *)a;
   const CZoneInfo *zb = (const CZoneInfo *)b;
   if (za == NULL || zb == NULL) return 0;

   return (int)(za.t_start - zb.t_start);
}

/*
void SortZonesByStartTime(CArrayObj &zones)
{
   int count = zones.Total();
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = 0; j < count - i - 1; j++)
      {
         CZoneInfo *z1 = (CZoneInfo *)zones.At(j);
         CZoneInfo *z2 = (CZoneInfo *)zones.At(j + 1);
         if(z1 == NULL || z2 == NULL) continue;

         if(z1.t_start > z2.t_start)
         {
            // Swap logic using Remove and Insert
            zones.Remove(j);
            
            zones.Insert(z2, j);
            zones.Remove(j + 1);
            zones.Insert(z1, j + 1);
         }
      }
   }
}
*/
/*
void SortZonesByStartTime(CArrayObj &zones)
{
   int count = zones.Total();
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = 0; j < count - i - 1; j++)
      {
         CZoneInfo *z1 = (CZoneInfo *)zones.At(j);
         CZoneInfo *z2 = (CZoneInfo *)zones.At(j + 1);
         if(z1 == NULL || z2 == NULL) continue;

         if(z1.t_start > z2.t_start)
         {
            // Swap using casted calls to Remove and Insert
            ((CArrayObj &)zones).Remove(j);
            ((CArrayObj &)zones).Insert(z2, j);
            ((CArrayObj &)zones).Remove(j + 1);
            ((CArrayObj &)zones).Insert(z1, j + 1);
         }
      }
   }
}
*/

/*
void SortZonesByStartTime(CArrayObj &zones)
{
   int count = zones.Total();
   if(count <= 1) return;

   // Copy zones into temp array
   CArrayObj temp;
   for(int i = 0; i < count; i++)
      temp.Add(zones.At(i));

   // Clear original array
   zones.Clear();

   // Sort temp using classic bubble sort
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = 0; j < count - i - 1; j++)
      {
         CZoneInfo *z1 = (CZoneInfo *)temp.At(j);
         CZoneInfo *z2 = (CZoneInfo *)temp.At(j + 1);
         if(z1 == NULL || z2 == NULL) continue;

         if(z1.t_start > z2.t_start)
         {
            // Swap in temp
            temp.Set(j, z2);
            temp.Set(j + 1, z1);
         }
      }
   }

   // Rebuild sorted zones
   for(int k = 0; k < count; k++)
      zones.Add(temp.At(k));
}
*/

void SortZonesByStartTime(CArrayObj &zones)
{
   int count = zones.Total();
   if(count <= 1) return;

   for(int i = 0; i < count - 1; i++)
   {
      for(int j = 0; j < count - i - 1; j++)
      {
         CZoneInfo *z1 = (CZoneInfo *)zones.At(j);
         CZoneInfo *z2 = (CZoneInfo *)zones.At(j + 1);
         if(z1 == NULL || z2 == NULL) continue;

         if(z1.t_start > z2.t_start)
         {
            // Swap by removing and re-inserting — avoid Set()
            zones.Delete(j);
            zones.Insert(z2, j);
            zones.Delete(j + 1);
            zones.Insert(z1, j + 1);
         }
      }
   }
}



class CZoneAnalyzer : public CObject
{
private:
   CArrayObj rects;
   CArrayObj zones;
   CArrayObj mergedZones;
   string prefix;

public:
   CZoneAnalyzer() {}
      
/////////

//virtual int ZoneCompareByStartTime(const CObject *a, const CObject *b)
int Compare(const CObject *a, const CObject *b) 
{
   const CZoneInfo *za = (const CZoneInfo *)a;
   const CZoneInfo *zb = (const CZoneInfo *)b;
   if (za == NULL || zb == NULL) return 0;

   return (int)(za.t_start - zb.t_start);
}


/*
    virtual int Compare(const CObject* node, int mode=0) const override {
        const CZoneAnalyzer* other = (const CZoneAnalyzer*)node;
        if (this.t_start > other.t_start) {
            return 1;
        } else if (this.t_start < other.t_start) {
            return -1;
        } else {
            return 0;
        }
    }
*/

/////////////
      
      
   void SetPrefix(string p) { prefix = p; }
   string Prefix() const { return prefix; }

   void LogZoneSummary();
   bool ShouldMergeRects(const CRectInfo &current, const CZoneInfo &active);
   string ExplainMergeDecision(const CRectInfo &current, const CZoneInfo &active);
   void LoadFromChart(string p); // {}
   void MergeZones() ; //{}
   void BuildTaggedZones(); //{}
   void CheckRegimeTags(); // {}

   int RawZoneCount() const { return rects.Total(); }
   int MergedZoneCount() const { return zones.Total(); }
   int TaggedZoneCount() const { return mergedZones.Total(); }

   CArrayObj* GetTaggedZones() { return &mergedZones; }
   CArrayObj *CZoneAnalyzer::GetZones() { return &this.zones; }

};

#endif

   // Scan all OBJ_RECTANGLEs on chart 0 into rects[]
void CZoneAnalyzer::LoadFromChart(const string prefixFilter="")
{
   rects.Clear();
   int total = ObjectsTotal(0);

   // debugging
   Print("🧭 Found ", ObjectsTotal(0), " chart objects");
   for(int i = 0; i < ObjectsTotal(0); i++)
   {
      string name = ObjectName(0,i);
      if(StringFind(name, prefix) == 0)
         Print("→ Found rect object: ", name);
   }

   
   for(int i = 0; i < total; i++)
   {
      string nm = ObjectName(0, i);

      // 1) only rectangles
      if(ObjectGetInteger(0, nm, OBJPROP_TYPE, 0) != OBJ_RECTANGLE)
         continue;

      // 2) optionally skip your own dashboard rects            //Means: “Skip any object whose name starts with the prefix.”
      if(prefixFilter!="" && StringFind(nm, prefixFilter) == 0)
         continue;

      // 3) read corner times & prices (subwindow = 0)
      double p1 = ObjectGetDouble(0, nm, OBJPROP_PRICE, 0);
      double p2 = ObjectGetDouble(0, nm, OBJPROP_PRICE, 1);

      // inverting low to high
      double price_high = MathMax(p1, p2);
      double price_low  = MathMin(p1, p2);
  
      p1 = price_low;
      p2 = price_high;
      
      datetime t1i = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 0);
      datetime t2i = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 1);
      
      // rects were drawn from right to left, so invert 
      datetime t_start = MathMin(t1i, t2i);
      datetime t_end   = MathMax(t1i, t2i);
            
      // Convert times to readable strings
      t1i = t_start;
      t2i = t_end;
      
      string time1_str = TimeToString(t1i, TIME_DATE|TIME_MINUTES);
      string time2_str = TimeToString(t2i, TIME_DATE|TIME_MINUTES);
       
      // Get color name
      color rect_color = (color) ObjectGetInteger(0, nm, OBJPROP_COLOR); 
      
      // Get color name
      string color_name = GetColorName(rect_color);       
      
      // debug
      PrintFormat("→ Rect %s: %s → %s | %.2f → %.2f",
            nm,
            TimeToString(t1i),
            TimeToString(t2i),
            p1,
            p2);
      
      
      // 4) build your rect info
      CRectInfo *r = new CRectInfo;
      r.Set( (datetime)MathMin(t1i, t2i),
             (datetime)MathMax(t1i, t2i),
             Normalize(p1,_Digits),
             Normalize(p2,_Digits),
             color_name);
      rects.Add(r);
      
   }

   // 5) sort by t1
   rects.Sort();
}


// this version has built in diagnostic and has helper function ShouldMergeRects() to filter merging criteria
void CZoneAnalyzer::MergeZones()
{
   zones.Clear();

   CZoneInfo *active = NULL;

   for (int i = 0; i < rects.Total(); i++)
   {
      CRectInfo *r = (CRectInfo *)rects.At(i);
      if (r == NULL) continue;

      // Normalize prices
      double rLow  = NormalizeDouble(MathMin(r.price_low, r.price_high), _Digits);
      double rHigh = NormalizeDouble(MathMax(r.price_low, r.price_high), _Digits);
      r.price_low  = rLow;
      r.price_high = rHigh;

      if (active == NULL)
      {
         active = new CZoneInfo;
         active.t_start     = r.t_start;
         active.t_end       = r.t_end;
         active.price_low   = rLow;
         active.price_high  = rHigh;
         active.zone_type   = r.zone_type;
         active.regime_type = (RegimeType)r.regime_type;
         active.regime_tag  = r.tag;
         active.rect_indices.Add(i);
         active.rect_count  = 1;
         zones.Add(active);

         PrintFormat("🟢 Starting first zone with Rect #%d → Time: %s–%s | Price: %.2f–%.2f | Regime: %s | Tag: %s",
                     i,
                     TimeToString(r.t_start, TIME_DATE | TIME_MINUTES),
                     TimeToString(r.t_end, TIME_DATE | TIME_MINUTES),
                     rLow, rHigh,
                     EnumToString(active.regime_type),
                     active.regime_tag);
         continue;
      }

// daignostic on comparison 
string decision = ExplainMergeDecision(*r, *active);
PrintFormat("🔍 Rect #%d vs Active → Decision: %s", i, decision);
                  

      if (ShouldMergeRects(*r, *active))
      {
         active.t_end        = MathMax(active.t_end, r.t_end);
         active.price_low    = MathMin(active.price_low, rLow);
         active.price_high   = MathMax(active.price_high, rHigh);
         active.rect_indices.Add(i);
         active.rect_count   = active.rect_indices.Total();
         Print("    ✅ Merged with active zone");
      }
      else
      {
         active = new CZoneInfo;
         active.t_start     = r.t_start;
         active.t_end       = r.t_end;
         active.price_low   = rLow;
         active.price_high  = rHigh;
         active.zone_type   = r.zone_type;
         active.regime_type = (RegimeType)r.regime_type;
         active.regime_tag  = r.tag;
         active.rect_indices.Add(i);
         active.rect_count  = 1;
         zones.Add(active);
         Print("    🧱 Split → Starting new regime zone");
      }
   }


   ////// ADDITIONAL CHK RIGHT AFTER MERGE
   PrintFormat("🧪 Zones Total: %d", zones.Total());
   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *z = (CZoneInfo *)zones.At(i);
      if (z == NULL)
      {
         PrintFormat("❌ NULL Zone at index %d", i);
         continue;
      }
   
      PrintFormat("✅ Zone %d → Rects: %d | Start: %s",
                  i,
                  z.rect_indices.Total(),
                  TimeToString(z.t_start, TIME_DATE | TIME_MINUTES));
   
      for (int r = 0; r < z.rect_indices.Total(); r++)
         PrintFormat("   └ Rect #%d", z.rect_indices.At(r));
   }
   

   zones.Sort();
   PrintFormat("🔧 MergeZones Complete: Merged %d rect(s) → %d zone(s)", rects.Total(), zones.Total()); 
   
   LogZoneSummary();    
}


bool CZoneAnalyzer::ShouldMergeRects(const CRectInfo &current, const CZoneInfo &active)
{
   const int tolerance_seconds = PeriodSeconds();     // Exact time adjacency
   const double price_tolerance = 0.01;               // Float tolerance for price match

   // Check time adjacency
   bool time_matches = MathAbs(current.t_start - active.t_end) <= tolerance_seconds;

   // Check enum alignment
   bool zone_type_matches   = current.zone_type == active.zone_type;
   bool regime_type_matches = current.regime_type == active.regime_type;

   // Check price structure agreement
   bool price_high_matches = MathAbs(current.price_high - active.price_high) < price_tolerance;
   bool price_low_matches  = MathAbs(current.price_low  - active.price_low)  < price_tolerance;

   return time_matches && zone_type_matches && regime_type_matches &&
          price_high_matches && price_low_matches;
}


//final : include logging prices chg on ALL comparison 
string CZoneAnalyzer::ExplainMergeDecision(const CRectInfo &current, const CZoneInfo &active)
{
   const int tolerance_seconds = PeriodSeconds();
   const double price_tolerance = 0.01;

   bool time_adjacent   = MathAbs(current.t_start - active.t_end) <= tolerance_seconds;
   bool zone_match      = current.zone_type == active.zone_type;
   bool regime_match    = current.regime_type == active.regime_type;

   bool high_match      = MathAbs(current.price_high - active.price_high) < price_tolerance;
   bool low_match       = MathAbs(current.price_low  - active.price_low)  < price_tolerance;

   string details = StringFormat("→ Rect [%.2f–%.2f] vs Zone [%.2f–%.2f]",
                                 current.price_low, current.price_high,
                                 active.price_low,  active.price_high);

   if (!time_adjacent)
      return "❌ Time mismatch " + details;
   if (!zone_match)
      return "❌ Zone type mismatch " + details;
   if (!regime_match)
      return "❌ Regime type mismatch " + details;
   if (!high_match || !low_match)
      return "❌ Price mismatch " + details;

   return "✅ Merge " + details;
}


void CZoneAnalyzer::LogZoneSummary()
{
   //zones.Sort(ZoneCompareByStartTime);  
   //zones.Sort(CompareZones);
   //zones.Sort(CompareZones);
   //SortObjArray(zones, CompareZones);
 
   //zones.Sort();
   SortZonesByStartTime(zones);
   Print("🔍 Validating Sorted Zone Sequence:");
   
   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *zone = (CZoneInfo *)zones.At(i);
      if (zone == NULL) continue;
   
      PrintFormat("Zone %d → t_start: %s", i, TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES));
   }
   
   
   
   Print("📊 Regime Zone Summary");
   
   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *zone = (CZoneInfo *)zones.At(i);
      if (zone == NULL) continue;
      
      zone.sorted_index = i; // ✅ Lock in chronological position
   
      string label       = StringFormat("Zone %d →", i); // ✅ Chronological index
      string regimeLabel = zone.regime_tag == "" ? "(null)" : zone.regime_tag;
      string timeStart   = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      string timeEnd     = TimeToString(zone.t_end,   TIME_DATE | TIME_MINUTES);
   
      PrintFormat("%s Regime: %s | Rects: %d | Time: %s → %s",
                  label, regimeLabel, zone.rect_count, timeStart, timeEnd);
   
      for (int r = 0; r < zone.rect_indices.Total(); r++)
         PrintFormat("   └ Rect #%d", zone.rect_indices.At(r));
   }


/*   
   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *zone = (CZoneInfo *)zones.At(i);
      if (zone == NULL) continue;
   
      string label = StringFormat("Zone %d →", i); // ✅ i now reflects sorted position
   
      string regimeLabel = zone.regime_tag == "" ? "(null)" : zone.regime_tag;
      string timeStart   = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      string timeEnd     = TimeToString(zone.t_end,   TIME_DATE | TIME_MINUTES);
   
      PrintFormat("%s Regime: %s | Rects: %d | Time: %s → %s", label, regimeLabel, zone.rect_count, timeStart, timeEnd);
   
      for (int r = 0; r < zone.rect_indices.Total(); r++)
         PrintFormat("   └ Rect #%d", zone.rect_indices.At(r));
   }
*/   
}



void CZoneAnalyzer::BuildTaggedZones()
{
   mergedZones.Clear();

   // Step 1: Generate merged zones from raw rectangles
   MergeZones();

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *zi = (CZoneInfo *)zones.At(i);
      if (zi == NULL) continue;

      int bullish = 0, bearish = 0;

      // Scan constituent rectangles in this zone
      for (int j = 0; j < zi.rect_indices.Total(); j++)
      {
         int rectIdx = zi.rect_indices.At(j);
         CRectInfo *r = (CRectInfo *)rects.At(rectIdx);
         if (r == NULL) continue;

         // tally up rectangle colors like "Green" and "Red" to decide the regime bias for each merged zone
         string clr = r.colorname;
         if (clr == "clrGreen")      bullish++;
         else if (clr == "clrRed")    bearish++;
      }

      // Decide regime based on color tally
      string tag = (bullish > bearish) ? "Green" :
                   (bearish > bullish) ? "Red" :"Gray";

      // mapping to a ZoneType:
      //ZoneType ztype = zone_NEUTRAL;
      RegimeType regType = ZONE_NEUTRAL;
      
      if (tag == "Green") regType = ZONE_BUY;
      else if (tag == "Red") regType = ZONE_SELL; 
      


      //regime tag is stored when building the CZoneInfo object:
      // Create final zone object
      CZoneInfo *cz = new CZoneInfo;
      cz.Set(
         zi.t_start,
         zi.t_end,
         zi.price_high,
         zi.price_low,
         zi.Count(),
         tag,
         regType
      );

      mergedZones.Add(cz);
   }

   // Optional post-check logic
   CheckRegimeTags();
}


void CZoneAnalyzer::CheckRegimeTags()
{
   Print("🔎 Checking regime tags for merged zones...");

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *z = (CZoneInfo*)zones.At(i);
   
      if (z == NULL) continue;   //to ensure invalid pointer
      string tag = z.regime_tag;
      
      int count = z.rect_indices.Total();

      PrintFormat("Zone %d → Regime: %s | Rects: %d | Time: %s → %s",
                  i,
                  tag,
                  count,
                  TimeToString(z.t_start),
                  TimeToString(z.t_end));

      // Optional: Print each contributing rectangle index
      for (int j = 0; j < count; j++)
         PrintFormat("   └ Rect #%d", z.rect_indices.At(j));
   }
}
   
   
 

//+------------------------------------------------------------------+
//| Function to get color name from color value                     |
//+------------------------------------------------------------------+
string GetColorName(color clr)
{
   if (clr == clrBlue) return "Blue";
   if (clr == clrRed) return "Red";
   if (clr == clrGreen) return "Green";
   if (clr == clrGold) return "Gold";
   return "Unknown";
}

double Normalize(double val, int digits)
{
   return NormalizeDouble(val, digits);
}
