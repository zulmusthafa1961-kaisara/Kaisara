#property strict
#include <Object.mqh>

#resource "ProfitFX-TrendBoxSignal-Gold.ex5" 

#property strict

input int RefreshIntervalSeconds = 5;
input int NoOfBars = 300;

int handleM5 = INVALID_HANDLE;
bool indicatorAttached = false;

int OnInit() {
   EventSetTimer(RefreshIntervalSeconds);
   Print("🧽 Test drive EA started. Blank chart → Visual toggle every", RefreshIntervalSeconds, "seconds.");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   EventKillTimer();
   if (handleM5 != INVALID_HANDLE) IndicatorRelease(handleM5);
}

// 🔄 Cycle: attach → purge → blank → reattach
void OnTimer() {
   if (!indicatorAttached) {
      // Phase 1: Attach M5 indicator
      handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
      indicatorAttached = true;
      Print("📥 M5 indicator attached.");
   } else {
      // Phase 2: Release and purge all visuals
      IndicatorRelease(handleM5);
      handleM5 = INVALID_HANDLE;
      indicatorAttached = false;

      PurgeAllObjects();
      Print("📴 M5 indicator released. Chart objects purged.");
   }
}

// 🧹 Clear all chart objects
void PurgeAllObjects() {
   int total = ObjectsTotal(0);
   int purged = 0;

   for (int i = total - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if (ObjectDelete(0, name)) purged++;
   }

   Print("🧹 Purged", purged, "objects.");
}
