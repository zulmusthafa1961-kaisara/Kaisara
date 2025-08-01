//+------------------------------------------------------------------+
//|                                                 ZoneAnalyzer.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#ifndef __ZONEANALYZER_MQH__
#define __ZONEANALYZER_MQH__

#include "ZoneType.mqh"
#include "ZoneInfo.mqh"

string DescribeZoneType(ZoneType regime) {
   switch (regime) {
      case ZONE_UP:      return "UP";
      case ZONE_DOWN:    return "DOWN";
      case ZONE_NEUTRAL: return "NEUTRAL";
      default:           return "UNKNOWN";
   }
}

class CZoneAnalyzer
{
private:
   CArrayObj rects;
   string   prefix;
   double   tolerance;
   int      time_pad;

private:
   CArrayObj mergedZones;
   
public:
   //void BuildTaggedZones();  // ✅ Declare here
   CArrayObj *GetMergedZones() { return &mergedZones; }   

public:
   //ZoneInfo zones[];
   CArrayObj zones;  // Holds CZoneInfo* objects
   
   ZoneType ClassifyRegime(CRectInfo *rect);
   ZoneType GetCurrentH1ZoneType();
   
   void LoadRectangles();
   void MergeRects();
   
   string GetCurrentH1ZoneTypeString();
   
void CZoneAnalyzer::CheckRegimeTags()
{
   Print("🔎 Checking regime tags for merged zones...");

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneInfo *z = (CZoneInfo*)zones.At(i);

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

      // 2) optionally skip your own dashboard rects
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
             Normalize(p1),
             Normalize(p2),
             color_name);
      rects.Add(r);
      
      
      
   }

   // 5) sort by t1
   rects.Sort();
}


// with regime color 
void CZoneAnalyzer::BuildTaggedZones()
{
   mergedZones.Clear();

   // (a) group raw rects → primitive zones[]:
   MergeZones();

   // (b) now wrap each merged zone into a CZoneInfo,
   //     but pull tag/type from the FIRST rect in that zone:
      
   //for(int i=0; i<ArraySize(zones); i++)
   for(int i = 0; i < zones.Total(); i++)   
   {
      //ZoneInfo zi = zones[i];
      //CArrayObj zones;  // dynamic array of CZoneInfo objects

      CZoneInfo *zi = new CZoneInfo;
      // populate zi...
      zones.Add(zi);



      // find the first rect in this merged block:
      // assume rects are sorted by time and
      // that you’ve stored the original rect index
      // (you may need to track it in ZoneInfo, or instead:)
      // as a quick hack, just peek at rects[i]:
      CRectInfo *firstRect = (CRectInfo*)rects.At(i);

      // extract the color‐based tag:
      // chg from this :
      // string tag  = firstRect.ColorName();
      
      // to :      
      int bullish = 0, bearish = 0;
      for(int j=0; j<zi.rect_indices.Total(); j++)
      {
         CRectInfo *r = (CRectInfo*)rects.At(zi.rect_indices[j]);
         if(r.ColorName() == "clrDodgerBlue") bullish++;
         else if(r.ColorName() == "clrCrimson") bearish++;
      }
      string tag = (bullish > bearish) ? "clrDodgerBlue" :
                   (bearish > bullish) ? "clrCrimson" : "clrGray";
      


      // map that tag string back to your enum if desired:
      ZoneType type = ZONE_NEUTRAL;
      if(tag == "clrDodgerBlue")    type = ZONE_UP;
      else if(tag == "clrCrimson")  type = ZONE_DOWN;
      // …or add more mappings as you need…

      // build the CZoneInfo
      CZoneInfo *cz = new CZoneInfo;
      cz.Set( zi.t_start,
              zi.t_end,
              zi.price_high,
              zi.price_low,
              zi.rect_count,
              tag,       // use the color name as the regime tag
              type);     // and the mapped enum
      mergedZones.Add(cz);
   }
   CheckRegimeTags();  // ✅ Validate each zone's regime logic
}

   
/*   
//ori
void CZoneAnalyzer::BuildTaggedZones() {
   mergedZones.Clear();  // Optional: reset previous zones

   for (int i = 0; i < rects.Total(); i++) {
      CObject *obj = rects.At(i);
      if (obj == NULL) continue;

      CRectInfo *rect = (CRectInfo *)obj;

      // ✅ Compute regime classification (stub logic here — replace with yours)
      ZoneType regime = ClassifyRegime(rect);         // Custom method
      string tag      = DescribeZoneType(regime);     // Converts enum to string

      // ✅ Create CZoneInfo and populate it
      CZoneInfo *zi = new CZoneInfo;
      zi.Set(rect.t1, rect.t2,
             rect.pHigh, rect.pLow,
             1,           // You can count aggregated rectangles here
             tag, regime);

      mergedZones.Add(zi);
   }
}   
*/

   CZoneAnalyzer(string rectPrefix = "obj_rect", double tol = 0.0001, int padSecs = 600)
   {
      prefix = rectPrefix;
      tolerance = tol;
      time_pad = padSecs;
   }
      

   CArrayObj *GetTaggedZones()
   {
      return &mergedZones; // Exposes full regime history to EA or renderer
   }

   ZoneInfo GetRegimeSnapshotH1()
   {
      ZoneInfo snapshot;
      snapshot.t_start    = TimeCurrent();         // or recent H1 candle time
      snapshot.t_end      = TimeCurrent();         // adjust if needed
      snapshot.price_high = SymbolInfoDouble(_Symbol, SYMBOL_ASK);  // optional
      snapshot.price_low  = SymbolInfoDouble(_Symbol, SYMBOL_BID);  // optional
      snapshot.rect_count = 0;
   
      //ZoneType regime     = zoneAnalyzer.GetCurrentH1ZoneType();    
      ZoneType regime = GetCurrentH1ZoneType();  // ✅ direct method call inside the class

      snapshot.regime_type = regime;
      snapshot.regime_tag  = DescribeZoneType(regime);               // e.g., "UP", "NEUTRAL", etc.
   
      return snapshot;
   }


   // FUNCTION NOT USED
   void CollectFromNames(string &names[])   
   {
      rects.Clear();
      for (int i = 0; i < ArraySize(names); i++)
      {
         string name = names[i];
         datetime t1, t2;
         double p1, p2;
         string colorstring;

         if (ObjectGetInteger(0, name, OBJPROP_TIME, 0, t1) &&
             ObjectGetInteger(0, name, OBJPROP_TIME, 1, t2) &&
             ObjectGetDouble(0, name, OBJPROP_PRICE, 0, p1) &&
             ObjectGetDouble(0, name, OBJPROP_PRICE, 1, p2))
         {
            datetime tNow = TimeCurrent();
            datetime tCutoff = tNow - 24 * 60 * 60;
         
            if (MathMax(t1, t2) < tCutoff)
               continue;
         
            CRectInfo *r = new CRectInfo;
            r.Set(MathMin(t1, t2), MathMax(t1, t2),
                  Normalize(p1), Normalize(p2),colorstring);
            rects.Add(r);
         
            PrintFormat("📏 RECT: %s | %s → %s | %.2f → %.2f",
                        name,
                        TimeToString(r.t1), TimeToString(r.t2),
                        r.pHigh, r.pLow);
         }

      }

      rects.Sort();
   }

   void MergeZones()
   {
      //ArrayFree(zones);
      zones.Clear();  // Removes all stored objects (doesn't delete them)

      for (int i = 0; i < rects.Total(); i++)
      {
         CRectInfo *r = (CRectInfo *)rects.At(i);
         bool merged = false;

         for (int j = 0; j < zones.Total(); j++)
         {
            CZoneInfo *zj = (CZoneInfo*)zones.At(j);
            bool samePrice = IsSame(r.pHigh, zj.price_high) &&
                 IsSame(r.pLow,  zj.price_low);
            
//            ool samePrice = IsSame(r.pHigh, zones[j].price_high) &&
 //                            IsSame(r.pLow,  zones[j].price_low);

            //bool timeClose = MathAbs((int)(r.t1 - zones[j].t_end)) <= time_pad;
            bool timeClose = MathAbs((int)(r.t1 - zj.t_end)) <= time_pad;

            if (samePrice && timeClose)
            {
               //zones[j].t_end      = MathMax(zones[j].t_end, r.t2);
               zj.t_end      = MathMax(zj.t_end, r.t2);
               //zones[j].rect_count += 1;
               zj.rect_count += 1;
               merged = true;
               break;
            }
         }

         if (!merged)
         {
            CZoneInfo *zi = new CZoneInfo;
         
            zi.t_start     = r.t1;
            zi.t_end       = r.t2;
            zi.price_high  = r.pHigh;
            zi.price_low   = r.pLow;
            zi.rect_count  = 1;
         
            zones.Add(zi);  // ✅ Add the fully populated zone
         }

      }
//      PrintFormat("🔗 Rects loaded: %d", za.RawZoneCount());
      PrintFormat("🔗 Rects loaded: %d", raw_zone_data.Total());

      PrintFormat("🧱 Zones merged: %d", za.zones.Total());
   }

   void DebugPrint()
   {
      //PrintFormat("🧱 Zones detected: %d", ArraySize(zones));
      PrintFormat("🧱 Zones detected: %d", zones.Total());
    
      //for (int i = 0; i < ArraySize(zones); i++)
      for (int i = 0; i < zones.Total(); i++)
      {
         //ZoneInfo z = zones[i];
         CZoneInfo *z = (CZoneInfo*)zones.At(i);

         PrintFormat("🧱 Zone %d: %s → %s | Price: %.2f → %.2f | Rects: %d",
                     i + 1, TimeToString(z.t_start), TimeToString(z.t_end),
                     z.price_high, z.price_low, z.rect_count);
      }
   }

private:
   double Normalize(double price)
   {
      return NormalizeDouble(price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
   }

   bool IsSame(double a, double b)
   {
      return MathAbs(a - b) < tolerance;
   }
};


ZoneType CZoneAnalyzer::ClassifyRegime(CRectInfo *rect) {
   double spread = rect.pHigh - rect.pLow;

   if (spread > tolerance * 3.0)
      return ZONE_UP;
   if (spread < -tolerance * 3.0)
      return ZONE_DOWN;

   return ZONE_NEUTRAL;
}


string CZoneAnalyzer::GetCurrentH1ZoneTypeString() {
   ZoneType regime = GetCurrentH1ZoneType();   // 🔸 Replace with your actual verdict retrieval logic
   return DescribeZoneType(regime);            // Converts enum to string label
}

ZoneType CZoneAnalyzer::GetCurrentH1ZoneType() {
   // Stub logic — replace with actual regime decision later
   return ZONE_NEUTRAL;
}

void CZoneAnalyzer::LoadRectangles() {
   // TODO: Implement logic to pull raw rectangles from chart or object list
   Print("Loading rectangles...");
}

void CZoneAnalyzer::MergeRects() {
   // TODO: Implement logic to group and merge nearby rectangles
   Print("Merging rectangles...");
}

//+------------------------------------------------------------------+
//| Function to get color name from color value                     |
//+------------------------------------------------------------------+
string GetColorName(color clr)
{
    switch(clr)
    {
        case clrRed:        return "Red";
        case clrGreen:      return "Green";

        default:            return "RGB(" + 
                                   IntegerToString((clr & 0xFF)) + "," + 
                                   IntegerToString((clr >> 8) & 0xFF) + "," + 
                                   IntegerToString((clr >> 16) & 0xFF) + ")";
    }
}


#endif