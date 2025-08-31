#ifndef __ZONECACHE_MQH__
#define __ZONECACHE_MQH__

#include "UnifiedRegimeModulesmqh.mqh"

class CZoneCache {
private:
   CArrayObj *h1Snapshot;
   datetime lastH1Refresh;

public:
   CZoneCache() {
      h1Snapshot = NULL;
      lastH1Refresh = 0;
   }

   void RefreshH1(CArrayObj *newZones) {
      if(CheckPointer(newZones) != POINTER_DYNAMIC || newZones.Total() == 0) {
         Print("⚠️ ZoneCache: Invalid H1 zone snapshot");
         return;
      }

      if(h1Snapshot != NULL) delete h1Snapshot;
      h1Snapshot = newZones;
      lastH1Refresh = TimeCurrent();

      PrintFormat("✅ ZoneCache: H1 snapshot refreshed @ %s | Zones = %d",
                  TimeToString(lastH1Refresh), h1Snapshot.Total());
   }

   CArrayObj *GetH1Snapshot() {
      if(CheckPointer(h1Snapshot) != POINTER_DYNAMIC) {
         Print("❌ ZoneCache: H1 snapshot pointer invalid");
         return NULL;
      }
      return h1Snapshot;
   }

   datetime LastRefreshTime() {
      return lastH1Refresh;
   }
};
#endif