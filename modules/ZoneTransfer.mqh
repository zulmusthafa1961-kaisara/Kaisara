//+------------------------------------------------------------------+
//| ZoneTransfer.mqh — Modular zone cloning and dispatch             |
//+------------------------------------------------------------------+
#ifndef __ZONE_TRANSFER__
#define __ZONE_TRANSFER__

#include <Arrays\ArrayObj.mqh>
//#include "CZoneCSV.mqh"
#include "ZoneInfo.mqh"
#include "UnifiedRegimeModulesmqh.mqh"



namespace ZoneTransfer
{
   // Factory method for zone cloning
   CObject *CreateZoneClone(const string typeName)
   {
      if (typeName == "CZoneCSV") return new CZoneCSV();
      if (typeName == "CZoneInfo") return new CZoneInfo();
      // Extend with more types as needed
      return NULL;
   }

   // Polymorphic zone transfer
   bool Transfer(const CArrayObj &src, CArrayObj &dest, const string expectedType, bool verbose = true)
   {
      dest.Clear();

      for (int i = 0; i < src.Total(); i++)
      {
         CObject *obj = src.At(i);

         if (obj != NULL && CheckPointer(obj) == POINTER_DYNAMIC && obj.ClassName() == expectedType)
         {
                        
                        CObject *zoneSrc = obj;
                        CObject *zoneClone = CreateZoneClone(expectedType);

                        if (zoneClone != NULL)
                        {
                            if (expectedType == "CZoneCSV")
                            {
                                CZoneCSV *typedClone = (CZoneCSV *)zoneClone;
                                CZoneCSV *typedSrc   = (CZoneCSV *)zoneSrc;
                                typedClone.Assign(typedSrc);
                            }
                            else if (expectedType == "CZoneInfo")
                            {
                                CZoneInfo *typedClone = (CZoneInfo *)zoneClone;
                                CZoneInfo *typedSrc   = (CZoneInfo *)zoneSrc;
                                typedClone.Assign(typedSrc);
                            }
                            // Add more types here if needed

                            dest.Add(zoneClone);
                            if (verbose) Print("✅ Cloned ", expectedType, " at index ", i);
                        }
        
        }
         else
         {
            if (verbose)
            {
               string typeName = obj == NULL ? "NULL" : obj.ClassName();
               Print("❌ Skipped non-", expectedType, " at index ", i, ": Type = ", typeName);
            }
         }
      }

      return dest.Total() > 0;
   }
}

#endif
