#ifndef ZONE_DIAGNOSTIC_MQH
#define ZONE_DIAGNOSTIC_MQH     

#include "UnifiedRegimeModulesmqh.mqh"

/*
void PrepareZoneDispatch(CArrayObj *fusedZones, CArrayObj &DispatchedZones, datetime lastClosedH1)
{
   DispatchAudit(fusedZones, lastClosedH1); // 🔍 Audit before slicing

   CArrayObj slice;
   GetLastNZones(fusedZones, 4);
   TransferZoneInfos(slice, DispatchedZones);
}
*/
void PrepareZoneDispatch(CArrayObj *sourceZones, CArrayObj *dispatchedZones, datetime lastClosedH1)
{
   if (sourceZones == NULL || sourceZones.Total() == 0)
   {
      Print("⚠️ PrepareZoneDispatch: sourceZones is empty");
      return;
   }

   CArrayObj eligibleZones;
   for (int i = 0; i < sourceZones.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV *)sourceZones.At(i);
      if (zone == NULL || CheckPointer(zone) != POINTER_DYNAMIC)
         continue;

      if (zone.t_end <= lastClosedH1)
         eligibleZones.Add(zone);
   }

   int totalEligible = eligibleZones.Total();
   if (totalEligible == 0)
   {
      Print("⚠️ No eligible zones to dispatch");
      return;
   }

   int startIndex = MathMax(0, totalEligible - 4); // Get last 4 eligible zones
   CArrayObj slice;
   for (int i = startIndex; i < totalEligible; i++)
      slice.Add(eligibleZones.At(i));

   Print("📦 Dispatching ", slice.Total(), " eligible zones from index ", startIndex, " to ", totalEligible - 1);

   //TransferZoneInfos(slice, *dispatchedZones);
if (slice.Total() > 0)
{
   int totalEligible = slice.Total();
   int start = MathMax(0, totalEligible - 4);
   int end   = totalEligible - 1;

   CZoneCSV *first = (CZoneCSV *)slice.At(0);
   if (first != NULL && CheckPointer(first) == POINTER_DYNAMIC)
      Print(TimeToString(first.t_start), "   📦 Dispatching ", slice.Total(), " eligible zones from index ", start, " to ", end);

   // 🔍 Diagnostic loop: full fidelity logging
   for (int i = 0; i < slice.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV *)slice.At(i);
      if (zone != NULL && CheckPointer(zone) == POINTER_DYNAMIC)
      {
         Print("📦 Zone[", i, "] CSVIndex=", zone.csv_index,
               " | Start=", TimeToString(zone.t_start),
               " | End=", TimeToString(zone.t_end),
               " | High=", DoubleToString(zone.price_high, 5),
               " | Low=", DoubleToString(zone.price_low, 5),
               " | Regime=", zone.regime_tag);
      }
   }

   TransferCSVZones(slice, *dispatchedZones);
}



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

     // CZoneInfo *zone = (CZoneInfo *)obj; // <-- runtime err: incorrect casting of pointers
                                            // because it assume  that obj is of type CZoneInfo
      CZoneCSV *zone = (CZoneCSV *)obj;     // in reality , sourcezones (aka fusedZones) contains objects of type CZoneCSV

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