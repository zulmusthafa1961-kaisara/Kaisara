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


#endif