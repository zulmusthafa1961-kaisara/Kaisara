#ifndef __ZONECACHE_MQH__
#define __ZONECACHE_MQH__

#include "UnifiedRegimeModulesmqh.mqh"

class CZoneCache {
private:
   CArrayObj *h1Snapshot;
   datetime lastRefreshTime;

public:
   CZoneCache() {
      h1Snapshot = NULL;
      lastRefreshTime = 0;
   }

   void RefreshH1(CArrayObj *newZones) {
      
      //if (TimeCurrent() < lastRefreshTime) {
      //   Print("⚠️ Attempt to refresh with older timestamp. Ignored.");
      //   return;
      // }
    
      datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);
      if (currentBarTime < lastRefreshTime) {
         Print("⚠️ Attempt to refresh with older bar time. Ignored.");
         return;
      }

      PrintFormat("🕒 RefreshH1: SystemTime=%s | BarTime=%s | LastRefresh=%s",
            TimeToString(TimeCurrent()),
            TimeToString(currentBarTime),
            TimeToString(lastRefreshTime));

      if (newZones == NULL || newZones.Total() == 0) {
         Print("⚠️ RefreshH1 aborted: newZones is NULL or empty");
         return;
      }

      if (h1Snapshot != NULL) delete h1Snapshot;
      h1Snapshot = new CArrayObj;
      for (int i = 0; i < newZones.Total(); i++) {
         h1Snapshot.Add(newZones.At(i));  // shallow copy; clone if needed
      }

      lastRefreshTime = TimeCurrent();

      PrintFormat("✅ ZoneCache: H1 snapshot refreshed @ %s | Zones = %d",
                  TimeToString(lastRefreshTime), h1Snapshot.Total());
   }

   CArrayObj *GetH1Snapshot() {
      if (CheckPointer(h1Snapshot) != POINTER_DYNAMIC) {
         Print("❌ ZoneCache: H1 snapshot pointer invalid");
         return NULL;
      }

      PrintFormat("📦 Snapshot check: Pointer=%d | Zones=%d | LastRefresh=%s",
            CheckPointer(h1Snapshot),
            h1Snapshot != NULL ? h1Snapshot.Total() : -1,
            TimeToString(lastRefreshTime));


      PrintFormat("📦 ZoneCache: Retrieved H1 snapshot | Zones = %d", h1Snapshot.Total());
      PrintFormat("📦 Snapshot check: Pointer=%d | Zones=%d | LastRefresh=%s",
                  CheckPointer(h1Snapshot), h1Snapshot.Total(), TimeToString(lastRefreshTime));

      return h1Snapshot;
   }


   bool HasValidSnapshot() {
      int zoneCount = -1;
      int ptrStatus = CheckPointer(h1Snapshot);

      if (ptrStatus == POINTER_DYNAMIC)
         zoneCount = h1Snapshot.Total();

      PrintFormat("🔍 HasValidSnapshot: Pointer=%d | Zones=%d", ptrStatus, zoneCount);

      return (ptrStatus == POINTER_DYNAMIC && zoneCount > 0);
   }


   datetime LastRefreshTime() {
      return lastRefreshTime;
   }
};

#endif
