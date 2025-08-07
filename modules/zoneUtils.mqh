#ifndef __ZONE_UTILS_MODULES__
#define __ZONE_UTILS_MODULES__

#include "UnifiedRegimeModulesmqh.mqh"

bool TransferZoneInfos(const CArrayObj &src, CArrayObj &dest, bool verbose = true) {
   dest.Clear();  // always reset target container

   for (int i = 0; i < src.Total(); i++) {
      CObject *obj = src.At(i);

      if (obj != NULL && CheckPointer(obj) == POINTER_DYNAMIC && obj.ClassName() == "CZoneInfo") {
         CZoneInfo *zoneSrc = (CZoneInfo *)obj;
         CZoneInfo *zoneClone = new CZoneInfo();

         if (zoneClone != NULL ) {
            zoneClone.Assign(zoneSrc);
            dest.Add(zoneClone);
            if (verbose) Print("✅ Cloned CZoneInfo at index ", i);
         } else {
            if (verbose) Print("⚠️ Failed to clone or assign at index ", i);
            delete zoneClone;
         }
      } else {
         if (verbose) {
            string typeName = obj == NULL ? "NULL" : obj.ClassName();
            Print("❌ Skipped non-CZoneInfo at index ", i, ": Type = ", typeName);
         }
      }
   }

   return dest.Total() > 0;
}


CArrayObj *GetLastNZones(CArrayObj *source, int count)
{
   if (source == NULL || source.Total() == 0 || count <= 0)
      return NULL;

   datetime lastClosedH1 = iTime(NULL, PERIOD_H1, 1);
   int total = source.Total();

   CArrayObj *validZones = new CArrayObj;
   for (int i = 0; i < total; ++i)
   {
      CObject *zone = source.At(i);
      if (zone == NULL || CheckPointer(zone) == POINTER_INVALID)
         continue;

      CZoneCSV *csvZone = (CZoneCSV *)zone;
      if (csvZone.t_end <= lastClosedH1)
         validZones.Add(zone);
   }

   int validTotal = validZones.Total();
   int startIndex = MathMax(0, validTotal - count);

   CArrayObj *result = new CArrayObj;
   for (int i = startIndex; i < validTotal; ++i)
   {
      CObject *zone = validZones.At(i);
      if (zone != NULL && CheckPointer(zone) != POINTER_INVALID)
         result.Add(zone);
   }

   //delete validZones;
   //validZones = NULL;

   return result;
}
/*
bool TransferLastNZones(const CArrayObj &source, CArrayObj &dest, int count, const string typeName, bool verbose = true)
{
   dest.Clear();
   if (source.Total() == 0 || count <= 0)
      return false;

   datetime lastClosedH1 = iTime(NULL, PERIOD_H1, 1);

   CArrayObj validZones;
   for (int i = 0; i < source.Total(); ++i)
   {
      CObject *obj = source.At(i);
      if (obj == NULL || CheckPointer(obj) != POINTER_DYNAMIC || obj.ClassName() != typeName)
         continue;

      CZoneCSV *zone = (CZoneCSV *)obj;
      if (zone.t_end <= lastClosedH1)
         validZones.Add(zone);
   }

   int validTotal = validZones.Total();
   int startIndex = MathMax(0, validTotal - count);

   CArrayObj slice;
   for (int i = startIndex; i < validTotal; ++i)
      slice.Add(validZones.At(i));

   return Transfer(slice, dest, typeName, verbose);
}
*/
#endif