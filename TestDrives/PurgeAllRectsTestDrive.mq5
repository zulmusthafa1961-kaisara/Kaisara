#property strict
#include <Object.mqh>

#resource "ProfitFX-TrendBoxSignal-Gold.ex5"
input int NoOfBars = 300; 
int handleH1 = INVALID_HANDLE;
int handleM5 = INVALID_HANDLE;

input int PurgeIntervalSeconds = 30;  // Frequency of purge cycle

int OnInit() {
   EventSetTimer(PurgeIntervalSeconds);
   Print("🧽 Rectangle purge cycle started: every", PurgeIntervalSeconds, "seconds.");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
   EventKillTimer();
}

void PurgeAllRects() {
   int total = ObjectsTotal(0);
   int purged = 0;

   for (int i = total - 1; i >= 0; i--) {
      string name = ObjectName(0,i);
      int type = (int)ObjectGetInteger(0, name, OBJPROP_TYPE);  // ✅ Correct way to get type
      if (type == OBJ_RECTANGLE || type == OBJ_RECTANGLE_LABEL) {
         ObjectDelete(0, name);
         purged++;
      }
   }

   Print("🧹 Purged", purged, "rectangle objects.");
}



void OnTimer() {
   ResetChartVisuals();
}


void ResetChartVisuals() {
   IndicatorRelease(handleM5);
   PurgeAllRects();
   handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
}
