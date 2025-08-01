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
   void BuildTaggedZones();  // ✅ Declare here
   CArrayObj *GetMergedZones() { return &mergedZones; }   

public:
   ZoneInfo zones[];
   ZoneType ClassifyRegime(CRectInfo *rect);
   ZoneType GetCurrentH1ZoneType();
   
   void LoadRectangles();
   void MergeRects();
   
   string GetCurrentH1ZoneTypeString();

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


   void CollectFromNames(string &names[])   
   {
      rects.Clear();
      for (int i = 0; i < ArraySize(names); i++)
      {
         string name = names[i];
         datetime t1, t2;
         double p1, p2;

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
                  Normalize(p1), Normalize(p2));
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
      ArrayFree(zones);
      for (int i = 0; i < rects.Total(); i++)
      {
         CRectInfo *r = (CRectInfo *)rects.At(i);
         bool merged = false;

         for (int j = 0; j < ArraySize(zones); j++)
         {
            bool samePrice = IsSame(r.pHigh, zones[j].price_high) &&
                             IsSame(r.pLow,  zones[j].price_low);

            bool timeClose = MathAbs((int)(r.t1 - zones[j].t_end)) <= time_pad;

            if (samePrice && timeClose)
            {
               zones[j].t_end      = MathMax(zones[j].t_end, r.t2);
               zones[j].rect_count += 1;
               merged = true;
               break;
            }
         }

         if (!merged)
         {
            ZoneInfo z;
            z.t_start = r.t1;
            z.t_end   = r.t2;
            z.price_high = r.pHigh;
            z.price_low  = r.pLow;
            z.rect_count = 1;

            ArrayResize(zones, ArraySize(zones) + 1);
            zones[ArraySize(zones) - 1] = z;
         }
      }
   }

   void DebugPrint()
   {
      PrintFormat("🧱 Zones detected: %d", ArraySize(zones));
      for (int i = 0; i < ArraySize(zones); i++)
      {
         ZoneInfo z = zones[i];
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

/*
CArrayObj *CZoneAnalyzer::GetMergedZones() {
   return &mergedZones;  // ⬅️ Return address of internal member
}
*/


ZoneType CZoneAnalyzer::ClassifyRegime(CRectInfo *rect) {
   double spread = rect.pHigh - rect.pLow;

   if (spread > tolerance * 3.0)
      return ZONE_UP;
   if (spread < -tolerance * 3.0)
      return ZONE_DOWN;

   return ZONE_NEUTRAL;
}


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


#endif