//+------------------------------------------------------------------+
//|                                        TestDriveREALLYMEANEA.mq5 |
//+------------------------------------------------------------------+
   #property strict 
   
   #include "modules\FreshZoneAnalyzer.mqh"
   #include "modules\RegimeUtils.mqh"
   #include "modules\CSVutils.mqh"
   #include "modules\ZoneLoader.mqh"

   CZoneAnalyzer analyzer;  




   int OnInit()
   {
   
      analyzer.LoadFromChart("");      // or whatever your prefix is   
      //analyzer.MergeZones();         // integrated in BuildTaggedZones(). if not commented out => duplicate logs  
      analyzer.BuildTaggedZones();
      PrintFormat("📦 Tagged Zones Count: %d", analyzer.GetTaggedZones().Total());
      
      //retired
      //ExportMergedZonesCSV("MergedH1Zones.csv", analyzer.GetZones());             // CZoneInfo *z = (CZoneInfo *)zones.At(i);
      //replaced by:
      
      if (PeriodSeconds() == 3600)  // ✅ Export only for H1 timeframe
      {
          analyzer.ExportH1MergedZonesToCSV();  // 👈 New integrated method;        // CZoneInfo *zone = (CZoneInfo *)mergedZones.At(i);
      }
      
      return INIT_SUCCEEDED;
   }


// working with utf-8 format

//+------------------------------------------------------------------+
//|                                        TestDriveREALLYMEANEA.mq5 |
//+------------------------------------------------------------------+


/*

int OnInit() {
   analyzer.LoadFromChart("");       // Load zones from embedded chart objects or prefix
   analyzer.BuildTaggedZones();      // Merge + tag zones (assumes MergeZones is inside)
   PrintFormat("📦 Tagged Zones Count: %d", analyzer.GetTaggedZones().Total());

   SaveMergedZonesWithTimestamp(analyzer.GetZones());  // 🧠 Full export with timestamp

   return INIT_SUCCEEDED;
}
*/



