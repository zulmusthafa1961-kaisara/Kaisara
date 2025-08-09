#ifndef ZONE_DIAGNOSTIC_MQH
#define ZONE_DIAGNOSTIC_MQH     

#include "UnifiedRegimeModulesmqh.mqh"

void PrepareZoneDispatch(CArrayObj *fusedZones, CArrayObj &DispatchedZones, datetime lastClosedH1)
{
   DispatchAudit(fusedZones, lastClosedH1); // 🔍 Audit before slicing

   CArrayObj slice;
   GetLastNZones(fusedZones, 4);
   TransferZoneInfos(slice, DispatchedZones);
}


void DispatchAudit(CArrayObj &fusedZones, datetime lastClosedH1)
{
   int eligible = 0, transferred = 0;

   for (int i = 0; i < fusedZones.Total(); i++)
   {
      CObject *obj = fusedZones.At(i);
      if (!CheckPointer(obj) || obj == NULL)
      {
         Print("❌ Zone[", i, "] pointer invalid");
         continue;
      }

      CZoneInfo *zone = (CZoneInfo *)obj;
      string className = zone.ClassName();
      string regime = zone.GetRegimeTypeName();
      //string type = zone.type;
      //int id = zone.id; // Optional: if you use zone.id for tracking

      if (className != "CZoneInfo" && className != "CZoneCSV")
      {
         Print("⚠️ Zone[", i, "] unexpected type: ", className);
         continue;
      }

      string status = (zone.t_end <= lastClosedH1) ? "✅ Eligible" : "⏸️ Open";
      string timeStr1 = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      string timeStr2 = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);

      Print("🔎 Zone[", i, "] ID=", i,
            " | t_start=", timeStr1,
            " | t_end=", timeStr2,
            " | regime=", regime,
            //" | type=", type,
            " | status=", status);

      if (zone.t_end <= lastClosedH1)
         eligible++;
   }

   Print("📊 DispatchAudit Summary: eligible=", eligible, " / total=", fusedZones.Total());
}


#endif