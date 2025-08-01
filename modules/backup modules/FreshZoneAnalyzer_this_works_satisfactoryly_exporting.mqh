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

public:
   void ExportZonesToCSV();
   void ExportH1MergedZonesToCSV();
   string BuildCSVRow(int zoneIndex);  // 👈 Add declaration here
      
/////////

//virtual int ZoneCompareByStartTime(const CObject *a, const CObject *b)
virtual int Compare(const CObject *a, const CObject *b) 
{
   const CZoneInfo *za = (const CZoneInfo *)a;
   const CZoneInfo *zb = (const CZoneInfo *)b;
   if (za == NULL || zb == NULL) return 0;

   return (int)(za.t_start - zb.t_start);
}
      
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

   // 5) sort by t1. VERY IMPORTANT. ZONE SEQUENCE WILL FOLLOW RECT SEQUENCE, i think. TEHEREFORE NO NEED TO SORT THE MERGEDZONES, UNLESS NECESSARY.  
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
      
      // added :        
      string clr = r.colorname;
      
      // DEBUG
      PrintFormat("🔍 Rect #%d → color: %s", i, r.colorname);      
      /*
      // DEBUG      
      if (r.colorname == "clrGreen")   r.zone_type = ZONE_BUY;
      else if (r.colorname == "clrRed") r.zone_type = ZONE_SELL;
      else                              r.zone_type = ZONE_NEUTRAL;
      */
      
      if (r.colorname == "Green")      r.zone_type = ZONE_BUY;
      else if (r.colorname == "Red")   r.zone_type = ZONE_SELL;
      else                             r.zone_type = ZONE_NEUTRAL;
      
      
      PrintFormat("🧱 Rect #%d assigned zone_type: %s", i, ZoneTypeToLabel((ZoneType)r.zone_type));

      // Decide regime based on color tally
      r.tag = (r.zone_type == ZONE_BUY) ? "Green" : (r.zone_type == ZONE_SELL) ? "Red" :"Gray";
      r.regime_type = (RegimeType)r.regime_type;
                   
      if (active == NULL)
      {
         active = new CZoneInfo;
         active.t_start     = r.t_start;
         active.t_end       = r.t_end;
         active.price_low   = rLow;
         active.price_high  = rHigh;
         active.zone_type   = r.zone_type;   // (ZoneType) ZoneTypeToString(r.zone_type);  //ZONE_UP or ZONE_DOWN
         active.regime_tag  = r.tag;   //Green or Red
         
         //active.regime_type = r.regime_type;  // implicit enum conversion warning
         
         // fixing implicit enum conversion warning
         ZoneType ztype = (ZoneType)r.regime_type;
         active.regime_type = ConvertZoneTypeToRegimeType(ztype);

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
   // at this point we got all zones and rect already in proper order !     <-- update 13/7 11:57 am
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

         // FIXING WRONG LOG ABOVE
         // THIS LOG SAME RECT 0 FOR EACH ZONE WHICH IS WRONG TOO
         CZoneInfo *zone = (CZoneInfo *)zones.At(i);
         if (zone == NULL) return;

         for (int r = 0; r < zone.rect_indices.Total(); r++)
         {
             int rect_index = zone.rect_indices.At(r);  // ✅ Index from zone's mapped rects
             CRectInfo *rect = (CRectInfo *)rects.At(rect_index);
             if (rect == NULL) continue;
         
             PrintFormat("   └ Rect #%d → zone_type: %s", rect_index, ZoneTypeToLabel((ZoneType)rect.zone_type));
         }

   
   }
 
   
// removed this part because at this point we got all zones and rect already in proper order !   
/*
   zones.Sort();
   PrintFormat("🔧 MergeZones Complete: Merged %d rect(s) → %d zone(s)", rects.Total(), zones.Total()); 
   
   LogZoneSummary();    
*/

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


/*
void CZoneAnalyzer::LogZoneSummary()
{
 
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
  
}
*/


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
      //RegimeType regType = ZONE_NEUTRAL;   // warning implicit conversion from 'enum ZoneType' to 'enum RegimeType'	FreshZoneAnalyzer.mqh	558	28
      //'RegimeType::REGIME_NEUTRAL' will be used instead of 'ZoneType::ZONE_NEUTRAL'	RegimeTypes.mqh	13	4
     
      // fixing warning by doing conversion from zonetype to regimetype
      RegimeType regType = ConvertZoneTypeToRegimeType((ZoneType)ZONE_NEUTRAL);

      // fixing warning by doing this conversion from tag to regime
      regType = ConvertTagToRegimeType(tag); 
      //if (tag == "Green") regType = ZONE_BUY;
      //else if (tag == "Red") regType = ZONE_SELL; 

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
   Print("🔎 Called by BuildTaggedZones\\CheckRegimeTags():Checking regime tags for merged zones...");

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *zone = (CZoneInfo *)zones.At(i);
      if (zone == NULL) continue;

   int up_count = 0, down_count = 0;
   for (int r = 0; r < zone.rect_indices.Total(); r++)
   {
      int rect_index = zone.rect_indices.At(r);
      CRectInfo *rect = (CRectInfo *)rects.At(rect_index);
      if (rect == NULL) continue;
   
      if (rect.zone_type == ZONE_BUY) up_count++;
      else if (rect.zone_type == ZONE_SELL) down_count++;
   }
   
   // log prior voting
   PrintFormat("🧩 Zone %d Rect Vote → Up: %d | Down: %d", i, up_count, down_count);
   
   if (up_count > down_count)
   {
      zone.zone_type  = ZONE_BUY;
      zone.regime_tag = "Green";
   }
   else if (down_count > up_count)
   {
      zone.zone_type  = ZONE_SELL;
      zone.regime_tag = "Red";
   }
   else
   {
      zone.zone_type  = ZONE_NEUTRAL;
      zone.regime_tag = "Gray";
   }
   
   // cannot convert enum
   // zone.regime_type = zone.zone_type; // Enum value used in CSV
   // resolve by using conversion
   zone.regime_type = ConvertZoneTypeToRegimeType(zone.zone_type); // ✅ no ambiguity now
   
   for (int i = 0; i < mergedZones.Total(); i++)
   {
      CZoneInfo *m = mergedZones.At(i);
      CZoneInfo *z = zones.At(i);  // Assuming same index order
   
      if (m == NULL || z == NULL) continue;
   
      m.regime_tag  = z.regime_tag;
      m.regime_type = z.regime_type;

      PrintFormat("🔁 Synced MergedZone #%d → Tag: %s | Regime: %s",
                  i, m.regime_tag, EnumToString(m.regime_type));
                  
   }
   
 }    
   
}
   
   
   
string CZoneAnalyzer::BuildCSVRow(int zoneIndex)
{
   CZoneInfo *zone = zones.At(zoneIndex);
   if (zone == NULL) return "";

   string timeStart = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
   string timeEnd   = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);
   string regimeTag = zone.regime_tag;
   string regimeType = EnumToString(zone.regime_type);  // Optional

   return StringFormat("%d,%s,%s,%.2f,%.2f,%d,%s,%s",
                       zoneIndex,
                       timeStart,
                       timeEnd,
                       zone.price_low,
                       zone.price_high,
                       zone.rect_count,
                       regimeTag,
                       regimeType);
}


void CZoneAnalyzer::ExportZonesToCSV()
{
   string filename = GetTimestampedFilename();

   // Open with FILE_WRITE | FILE_CSV | FILE_ANSI for UTF-8
   int handle = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if (handle == INVALID_HANDLE)
   {
      Print("❌ Failed to open file: " + filename);
      return;
   }

   // Optionally write UTF-8 BOM header
   FileWriteString(handle, "\xEF\xBB\xBF"); // UTF-8 BOM

   // Write column headers
   FileWrite(handle, "Index", "Start Time", "End Time", "Low", "High", "Rect Count", "Tag", "Regime");

   for (int i = 0; i < zones.Total(); i++)
   {
      string row = BuildCSVRow(i);
      FileWriteString(handle, row + "\n");  // Clean row write
   }

   FileClose(handle);
   PrintFormat("📁 CSV export complete: %s", filename);
}
   
void ExportMergedZonesCSV(string filename, CArrayObj *zones)
{
   int file = FileOpen(filename, FILE_WRITE | FILE_CSV);
   if (file == INVALID_HANDLE)
   {
      Print("❌ Failed to open file for writing: ", filename);
      return;
   }

   FileWrite(file, "t_start", "t_end", "price_low", "price_high", "rect_count", "regime_tag", "regime_type");

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *z = (CZoneInfo *)zones.At(i);
      if (z == NULL) continue;
   
      string t_start  = TimeToString(z.t_start, TIME_DATE | TIME_MINUTES);
      string t_end    = TimeToString(z.t_end,   TIME_DATE | TIME_MINUTES);
      string regime   = z.regime_tag == "" ? "Gray" : z.regime_tag;
      
      //string type     = z.regime_type == "" ? "(null)" : EnumToString(z.regime_type);   // implicit conversion from 'RegimeType' to 'string'	CSVutils.mqh	50	27
      // fixing this implicit conversion
      string type = (z.regime_type == REGIME_NONE) ? "(null)" : EnumToString(z.regime_type);

   
      FileWrite(file,t_start, t_end, z.price_low, z.price_high, z.rect_count, regime, type);
   }
   
      FileClose(file);
      Print("✅ Zone CSV written: ", filename);
   }
 

void CZoneAnalyzer::ExportH1MergedZonesToCSV()
{
   string filename = "mergedzones_H1_" + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) + ".csv";
   StringReplace(filename, ":", "-");
   StringReplace(filename, " ", "_");

   int handle = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI);
   if (handle == INVALID_HANDLE)
   {
      Print("❌ Failed to open file: " + filename);
      return;
   }


   // Header line manually written
   FileWriteString(handle, "Index,Start,End,Low,High,RectCount,Tag,Regime\n");

   for (int i = 0; i < mergedZones.Total(); i++)
   {
      CZoneInfo *zone = (CZoneInfo *)mergedZones.At(i);
      if (zone == NULL) continue;

      if (PeriodSeconds() != 3600) continue; // Filter for H1 only
     
       string row = StringFormat("%d,%s,%s,%.2f,%.2f,%d,%s,%s", i,
                                      TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES),
                                      TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES),
                                      zone.price_low,
                                      zone.price_high,
                                      zone.rect_count,
                                      zone.regime_tag,
                                      EnumToString(zone.regime_type));
      FileWriteString(handle, row + "\n"); 
   }

   FileClose(handle);
   PrintFormat("✅ CSV (H1 only) export complete: %s", filename);
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


string GetTimestampedFilename()
{
   datetime now = TimeCurrent();
   string timestamp = TimeToString(now, TIME_DATE | TIME_MINUTES);
   StringReplace(timestamp, ":", "-"); // Avoid colon for file names
   StringReplace(timestamp, " ", "_"); // Optional: underscore for clarity
   return "zone_export_" + timestamp + ".csv";
}


bool IsH1Zone(const CZoneInfo *zone)
{
   return PeriodSeconds() == 3600;  // 1-hour bars
}


