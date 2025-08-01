//+------------------------------------------------------------------+
//|                                                     CSVutils.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Object.mqh>
#include "zoneinfo.mqh"
#include "RegimeUtils.mqh"
#include "ZoneLoader.mqh"

/*
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
*/

// Utility: Save zones to UTF-8 file with timestamp
void SaveMergedZonesWithTimestamp(CArrayObj *zones) {
   if (zones == NULL || zones.Total() == 0) {
      Print("⚠️ No zones to export.");
      return;
   }

   // 1. Build CSV-style string
   string content = "t_start,t_end,price_low,price_high,rect_count,regime_tag,regime_type\n";
 
/* 
   for (int i = 0; i < zones.Total(); i++) {
      CObject *base = zones.At(i);
      CZoneCSV *zone = (CZoneCSV *)base;
            
      content +=
         TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES) + "," +
         TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES) + "," +
         DoubleToString(zone.price_low, 2) + "," +
         DoubleToString(zone.price_high, 2) + "," +
         IntegerToString(IntegerToString(zone.GetRectCount())) + "," +
         zone.regime_tag + "," +
         zone.regime_type + "\n";
   }
*/

   // replace risky cast with :
   for (int i = 0; i < zones.Total(); i++) {
      CZoneCSV *zone = SafeGetZoneCSV(zones, i);
      if (zone == NULL) {
         PrintFormat("⚠️ Skipping zone[%d] — cast failed", i);
         continue;
      }
   
      content +=
         TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES) + "," +
         TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES) + "," +
         DoubleToString(zone.price_low, 2) + "," +
         DoubleToString(zone.price_high, 2) + "," +
         IntegerToString(zone.GetRectCount()) + "," +
         zone.regime_tag + "," +
         zone.regime_type + "\n";
   }
   

   // 2. Build timestamped filename
   string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES);
   timestamp = StringReplace(timestamp, ".", "");
   timestamp = (string) StringReplace(timestamp, ":", "");
   timestamp = StringReplace(timestamp, " ", "_");
   string filename = "MergedH1Zones_" + timestamp + ".txt";

   // 3. Save as UTF-8 encoded file
   int handle = FileOpen(filename, FILE_WRITE | FILE_BIN);
   if (handle == INVALID_HANDLE) {
      Print("❌ Failed to open file for writing: ", filename);
      return;
   }

   uchar buffer[];
   StringToCharArray(content, buffer, CP_UTF8);
   FileWriteArray(handle, buffer, 0, ArraySize(buffer));
   FileClose(handle);

   Print("✅ Saved zones to UTF-8 file: ", filename);
}

//usage: for multiple merged zones, build up the full file content before writing, rather than appending line-by-line during export.
/*
string zoneText =
   "t_start,t_end,price_low,price_high,rect_count,regime_tag,regime_type\n";

for (int i = 0; i < ArraySize(mergedZones); i++) {
   CZoneCSV *zone = mergedZones[i];
   zoneText +=
      TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES) + "," +
      TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES) + "," +
      DoubleToString(zone.price_low, 2) + "," +
      DoubleToString(zone.price_high, 2) + "," +
      IntegerToString(zone.rect_count) + "," +
      zone.regime_tag + "," +
      zone.regime_type + "\n";
}
*/

// Safe casting helper — only return CZoneCSV if valid
CZoneCSV *SafeGetZoneCSV(CArrayObj *arr, int index) {
   if (arr == NULL || index < 0 || index >= arr.Total()) return NULL;

   CObject *obj = arr.At(index);
   if (obj == NULL) return NULL;

   // ClassName-based type check (requires ClassName() defined in CZoneCSV and its base)
   if (obj.ClassName() == "CZoneCSV")
      return (CZoneCSV *)obj;

   return NULL;
}

void ValidateZoneArray(CArrayObj *arr) {
   if (arr == NULL) {
      Print("⚠️ Zone array is NULL.");
      return;
   }

   for (int i = 0; i < arr.Total(); i++) {
      CObject *obj = arr.At(i);
      string name = obj != NULL ? obj.ClassName() : "NULL";
      PrintFormat("🔍 Zone[%d]: %s", i, name);
   }
}


