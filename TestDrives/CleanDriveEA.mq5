//  CleanDriveEA.mq5 

#include "modules\CEADriver.mqh"

analyzer.LoadFromChart("obj_rect001");      // or whatever your prefix is
analyzer.MergeZones();
analyzer.BuildTaggedZones();
ExportMergedZonesCSV("MergedH1Zones.csv", analyzer.GetTaggedZones());


int OnInit() { Print("✅ EA compiles"); return INIT_SUCCEEDED; }

void OnTick() {}

void ExportMergedZonesCSV(string filename, CArrayObj *zones)
{
   int file = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI);
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

      FileWrite(file,
         TimeToString(z.t_start, TIME_DATE|TIME_MINUTES),
         TimeToString(z.t_end, TIME_DATE|TIME_MINUTES),
         DoubleToString(z.price_low, _Digits),
         DoubleToString(z.price_high, _Digits),
         z.rect_count,
         z.regime_tag,
         ZoneTypeToString(z.regime_type)  // make sure this is included from RegimeUtils
      );
   }

   FileClose(file);
   Print("✅ Zone CSV written: ", filename);
}
