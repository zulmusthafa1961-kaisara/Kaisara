#ifndef __ZONE_UTILS_MODULES__
#define __ZONE_UTILS_MODULES__

#include "UnifiedRegimeModulesmqh.mqh"


//This version will give you full visibility into what’s being cloned, skipped, or rejected — perfect for validating zone dispatch pipeline.
bool TransferZoneInfos(const CArrayObj &src, CArrayObj &dest, bool verbose = true)
{
   dest.Clear();  // Always reset target container

   int total = src.Total();
   if (verbose)
      Print("🔄 TransferZoneInfos: Starting transfer of ", total, " objects");

   for (int i = 0; i < total; ++i)
   {
      CObject *obj = src.At(i);

      if (obj == NULL)
      {
         if (verbose) Print("❌ Skipped NULL object at index ", i);
         continue;
      }

      if (CheckPointer(obj) != POINTER_DYNAMIC)
      {
         if (verbose) Print("⚠️ Invalid pointer at index ", i, " — Type = ", obj.ClassName());
         continue;
      }

      if (obj.ClassName() != "CZoneInfo")
      {
         if (verbose) Print("❌ Skipped non-CZoneInfo at index ", i, " — Type = ", obj.ClassName());
         continue;
      }

      CZoneInfo *zoneSrc = (CZoneInfo *)obj;
      CZoneInfo *zoneClone = new CZoneInfo;

      if (zoneClone == NULL)
      {
         if (verbose) Print("⚠️ Failed to allocate clone at index ", i);
         continue;
      }

      zoneClone.Assign(zoneSrc);
      dest.Add(zoneClone);

      if (verbose)
      {
         Print("✅ Cloned CZoneInfo at index ", i,
               " | t_start=", TimeToString(zoneClone.t_start),
               " | t_end=", TimeToString(zoneClone.t_end));
      }
   }

   if (verbose)
      Print("📦 Transfer complete: ", dest.Total(), " zones dispatched");

   return dest.Total() > 0;
}


/*
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
*/

// refactor GetLastNZones() to use TransferZoneInfos() ; deep copy
CArrayObj *GetLastNZones(CArrayObj *source, int count)
{
   if (source == NULL || source.Total() == 0 || count <= 0)
      return NULL;

   datetime lastClosedH1 = iTime(NULL, PERIOD_H1, 1);
   int total = source.Total();

   CArrayObj *validZones = new CArrayObj;
   for (int i = 0; i < total; ++i)
   {
      CZoneCSV *zone = (CZoneCSV *)source.At(i);
      if (zone == NULL || CheckPointer(zone) == POINTER_INVALID)
         continue;

      if (zone.t_end <= lastClosedH1)
         validZones.Add(zone);
   }

   // Slice last N zones
   int validTotal = validZones.Total();
   int startIndex = MathMax(0, validTotal - count);

   CArrayObj *slice = new CArrayObj;
   for (int i = startIndex; i < validTotal; ++i)
   {
      slice.Add(validZones.At(i)); // Shallow copy
   }

   // Deep clone into dispatched container
   CArrayObj *DispatchedZones = new CArrayObj;
   TransferZoneInfos(*slice, *DispatchedZones, false);

   //delete validZones;
   //delete slice;

   return DispatchedZones;
}


//tailored version of TransferZoneCSV() that deep-clones CZoneCSV objects from one container to another
bool TransferZoneCSV(const CArrayObj &src, CArrayObj &dest, bool verbose = true) {
   dest.Clear();  // always reset target container

   for (int i = 0; i < src.Total(); i++) {
      CObject *obj = src.At(i);

      if (obj != NULL && CheckPointer(obj) == POINTER_DYNAMIC && obj.ClassName() == "CZoneCSV") {
         CZoneCSV *zoneSrc = (CZoneCSV *)obj;
         CZoneCSV *zoneClone = new CZoneCSV();

         if (zoneClone != NULL) {
            zoneClone.Assign(zoneSrc);
            dest.Add(zoneClone);
            if (verbose) Print("✅ Cloned CZoneCSV at index ", i);
         } else {
            if (verbose) Print("⚠️ Failed to clone or assign at index ", i);
            delete zoneClone;
         }
      } else {
         if (verbose) {
            string typeName = obj == NULL ? "NULL" : obj.ClassName();
            Print("❌ Skipped non-CZoneCSV at index ", i, ": Type = ", typeName);
         }
      }
   }

   return dest.Total() > 0;
}

//Usage Example :  use this in zone dispatch logic
//CArrayObj *DispatchedZones = new CArrayObj;
//TransferZoneCSV(*slice, *DispatchedZones, true);


//polymorphic zone transfer dispatcher that handles any zone type by name, without duplicating logic.
bool TransferZonesByType(const CArrayObj &src, CArrayObj &dest, const string expectedType, bool verbose = true) {
   dest.Clear();  // always reset target container

   for (int i = 0; i < src.Total(); i++) {
            CObject *obj = src.At(i);

            if (obj != NULL && CheckPointer(obj) == POINTER_DYNAMIC && obj.ClassName() == expectedType) 
            {
                  CObject *zoneSrc = obj;
                  CObject *zoneClone = CreateZoneClone(expectedType);
  
                  if (zoneClone != NULL) {
                     if (expectedType == "CZoneCSV") {
                        CZoneCSV *typedClone = (CZoneCSV *)zoneClone;
                        CZoneCSV *typedSrc   = (CZoneCSV *)zoneSrc;
                        typedClone.Assign(typedSrc);
                     }
                     else if (expectedType == "CZoneInfo") {
                        CZoneInfo *typedClone = (CZoneInfo *)zoneClone;
                        CZoneInfo *typedSrc   = (CZoneInfo *)zoneSrc;
                        typedClone.Assign(typedSrc);
                     }
                     // Add more types here if needed

                     dest.Add(zoneClone);
                     if (verbose) Print("✅ Cloned ", expectedType, " at index ", i);
                  }

            } 
            
            else {
               if (verbose) {
                  string typeName = obj == NULL ? "NULL" : obj.ClassName();
                  Print("❌ Skipped non-", expectedType, " at index ", i, ": Type = ", typeName);
               }
            }
   }

   return dest.Total() > 0;
}

// usage of polymorphic transfer

//Helper: CreateZoneClone()
CObject *CreateZoneClone(const string typeName) {
   if (typeName == "CZoneCSV") return new CZoneCSV();
   if (typeName == "CZoneInfo") return new CZoneInfo();
   // Add more types here if needed
   return NULL;
}

// Usage example
//CArrayObj *DispatchedZones = new CArrayObj;
//TransferZonesByType(*slice, *DispatchedZones, "CZoneCSV", true);




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

bool Transfer(const CArrayObj &src, CArrayObj &dest, const string typeName, bool verbose = true) {
   dest.Clear();  // always reset target container

   for (int i = 0; i < src.Total(); i++) {
      CObject *obj = src.At(i);

      if (obj != NULL && CheckPointer(obj) == POINTER_DYNAMIC && obj.ClassName() == typeName) {
         CObject *zoneClone = CreateZoneClone(typeName);
         if (zoneClone != NULL) {
            if (typeName == "CZoneCSV") {
               CZoneCSV *typedClone = (CZoneCSV *)zoneClone;
               CZoneCSV *typedSrc   = (CZoneCSV *)obj;
               typedClone.Assign(typedSrc);
            } else if (typeName == "CZoneInfo") {
               CZoneInfo *typedClone = (CZoneInfo *)zoneClone;
               CZoneInfo *typedSrc   = (CZoneInfo *)obj;
               typedClone.Assign(typedSrc);
            }
            // Add more types here if needed

            dest.Add(zoneClone);
            if (verbose) Print("✅ Cloned ", typeName, " at index ", i);
         } else {
            if (verbose) Print("⚠️ Failed to clone or assign at index ", i);
            delete zoneClone;
         }
      } else {
         if (verbose) {
            string typeNameObj = obj == NULL ? "NULL" : obj.ClassName();
            Print("❌ Skipped non-", typeName, " at index ", i, ": Type = ", typeNameObj);
         }
      }
   }

   return dest.Total() > 0;
}
#endif