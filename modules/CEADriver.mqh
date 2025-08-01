#include "FreshZoneAnalyzer.mqh"

class CEADriver
{
private:
   CZoneAnalyzer analyzer;

public:
   CEADriver(string prefix = "DashRect_")
   {
      analyzer.SetPrefix(prefix);
   }

   void Init()
   {
      analyzer.LoadFromChart(analyzer.Prefix());
      analyzer.MergeZones();
      analyzer.BuildTaggedZones();
      analyzer.CheckRegimeTags();

      PrintFormat("🔧 Loaded %d raw rects", analyzer.RawZoneCount());
      
      //PrintFormat("🧱 %d zones merged", analyzer.zones.Total());
      PrintFormat("🧱 %d zones merged", analyzer.MergedZoneCount());

      //PrintFormat("📐 %d zones tagged", analyzer.mergedZones.Total());
      PrintFormat("📐 %d zones tagged",analyzer.TaggedZoneCount());      
      

   }

   void ExportCSV(string filename = "MergedH1Zones.csv")
   {
      CArrayObj *zones = analyzer.GetTaggedZones();
      int fh = FileOpen(filename, FILE_WRITE|FILE_CSV);
      if(fh == INVALID_HANDLE)
      {
         Print("❌ Failed to open file: ", filename);
         return;
      }

      FileWrite(fh, "StartTS","EndTS","Start","End","Tag","High","Low","Count");

      for(int i = 0; i < zones.Total(); i++)
      {
         CZoneInfo *z = (CZoneInfo*)zones.At(i);
         FileWrite(fh,
            (long)z.TStart(),
            (long)z.TEnd(),
            TimeToString(z.TStart(), TIME_DATE|TIME_SECONDS),
            TimeToString(z.TEnd(),   TIME_DATE|TIME_SECONDS),
            z.Tag(),
            DoubleToString(z.PriceHigh(), _Digits),
            DoubleToString(z.PriceLow(),  _Digits),
            z.Count());
      }

      FileClose(fh);
      Print("✅ Exported ", zones.Total(), " zones to: ", filename);
   }

   void DrawDashboard()
   {
      // 📊 Placeholder for future visualization logic
      // For example: draw zone bands or regime indicators on subwindow
   }
};
