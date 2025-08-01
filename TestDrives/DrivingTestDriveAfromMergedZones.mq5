//DrivingTestDriveAfromMergedZones.mq5

#include "modules\ZoneAnalyzer.mqh"
int OnInit()
{
   Print("🔧 EA Init....");
   
   CZoneAnalyzer za("DashRect_");
   za.LoadFromChart("DashRect_");
   za.DebugPrint();

   za.MergeZones();           // fills za.zones[]
   za.BuildTaggedZones();     // fills za.mergedZones[]
   
   Print("🔧 EA Initialized.");
   Print("🔧 EA Started. Zones will be exported...");


   CArrayObj *mz = za.GetTaggedZones();
   int fh = FileOpen("MergedH1Zones.csv",
                     FILE_WRITE|FILE_CSV);
   FileWrite(fh,
             "StartTS","EndTS",
             "Start","End",
             "Tag","High","Low","Count");

   for(int i=0; i<mz.Total(); i++)
   {
      CZoneInfo *z = (CZoneInfo*)mz.At(i);
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

   Print("Exported ", mz.Total(), " merged H1 zones.");
   return INIT_SUCCEEDED;
}
