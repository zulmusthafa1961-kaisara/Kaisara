#property strict
#resource "ProfitFX-TrendBoxSignal-Gold.ex5"

#include <ZoneAnalyzer.mqh>
#include <ZoneType.mqh>
#include <ZoneInfo.mqh>
#include <RegimeTypes.mqh>

///
#include <RegimeDashboardBuilder.mqh>
#include <RegimeDisplayRenderer.mqh>   // Assuming it’s modularized too


PhaseType activePhase = PHASE_TYPE_M5;

// 🧱 Global objects
RegimeDashboardBuilder dashboard;
RegimeDisplayRenderer displayRenderer("RegimeBox", 1);  // Prefix + subwindow index

int handleM5 = INVALID_HANDLE;
int handleH1 = INVALID_HANDLE;
///


input int RefreshIntervalSeconds = 5;
input int NoOfBars = 300;

const int RegimeBufferIndex = 0;  // Or use 1, 2, etc. based on your indicator structure

string m5History[3];        // Last 3 regimes with timestamp
int historyIndex = 0;       // Rolling buffer index

CZoneAnalyzer *zoneAnalyzer;


int OnInit() {
   EventSetTimer(RefreshIntervalSeconds);
   handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);

   Print("🚀 Started with M5 regime.");
  
   zoneAnalyzer = new CZoneAnalyzer("obj_rect", 0.0002, 600);  // prefix, tolerance, padding
   zoneAnalyzer.LoadRectangles();       // fetch raw rectangles
   zoneAnalyzer.MergeRects();           // merge clusters
   zoneAnalyzer.BuildTaggedZones();     // classify regimes and tag them
   
   displayRenderer.SetSpacing(12);
   displayRenderer.SetYOffset(20); 
   
   dashboard.SetRenderer(displayRenderer);
   dashboard.SetPhaseAndHandles(activePhase, handleM5, handleH1);
   dashboard.Update();   // Optional: renders initial regime label immediately
   
   
   int actualWindow = ChartWindowFind(0, "RegimeM5");  // Match your regime buffer name here
   if (actualWindow < 0) actualWindow = 1;  // Fallback to subwindow 1
   
   RegimeDisplayRenderer displayRenderer("RegimeBox", actualWindow);
   
     
   
   return INIT_SUCCEEDED;
}



void OnDeinit(const int reason) {
   EventKillTimer();
   IndicatorRelease(handleM5);
   IndicatorRelease(handleH1);
  
/* not required if not a pointer   
   if (dashboard != NULL) {
      delete dashboard;
      dashboard = NULL;
   }
*/
   if (zoneAnalyzer != NULL) {
      delete zoneAnalyzer;
      zoneAnalyzer = NULL;
   }
}

void OnTimer() {
   Print("🔄 Toggling regime...");

   // ✂️ Phase 0: Clean slate
   IndicatorRelease(handleM5);
   IndicatorRelease(handleH1);
   PurgeAllObjects();
   Sleep(500);  // Optional delay for visual clarity

   // 🔁 Phase 1: Switch regime
   if (activePhase == PHASE_TYPE_M5) {
      handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
      activePhase = PHASE_TYPE_H1;
      Print("📈 H1 regime activated.");
   } else {
      handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
      activePhase = PHASE_TYPE_M5;
      Print("📉 M5 regime activated.");
   }
   Sleep(200);  // Give buffers time to populate
   dashboard.Update();
 
}

void PurgeAllObjects() {
   int total = ObjectsTotal(0);
   int purged = 0;

   for (int i = total - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if (ObjectDelete(0, name)) purged++;
   }

   Print("🧹 Purged", purged, "chart objects.");
}


// 🔁 Holds last 5 M5 regimes (oldest to newest)
//string M5History[5];
//int M5Index = 0;

string DescribeRegime(double regime) {
   if (!MathIsValidNumber(regime) || regime == EMPTY_VALUE)
      return "⛔️ Undecided";
   if (regime > 100) return "📈 Price Level (" + DoubleToString(regime, 2) + ")";
   if (regime == 1.0) return "Bullish";
   if (regime == -1.0) return "Bearish";
   if (regime == 0.0) return "Neutral";
   return "Unk(" + DoubleToString(regime, 2) + ")";
}


// 🚦 Determines which handle and buffer to query for regime
string GetRegimeSnapshot(PhaseType phase) {
   double buffer[1];
   int bufIndex = 0;  // Default to buffer 0

   if (phase == PHASE_TYPE_M5 && handleM5 != INVALID_HANDLE) {
   
      //CopyBuffer(handleM5, bufIndex, 0, 1, buffer);
      // to ensure CopyBuffer on the last candle close       
      int h1BarIndex = 0;
      datetime now = TimeCurrent();
      while (iTime(_Symbol, PERIOD_H1, h1BarIndex) > now && h1BarIndex < 100)
         h1BarIndex++;
      
      // Now safely read regime from last closed H1 bar
      CopyBuffer(handleH1, bufIndex, h1BarIndex, 1, buffer);
//      
      return DescribeRegime(buffer[0]);
   }

   if (phase == PHASE_TYPE_H1 && handleH1 != INVALID_HANDLE) {

      //CopyBuffer(handleH1, bufIndex, 0, 1, buffer);
//
      int h1BarIndex = 0;
      datetime now = TimeCurrent();
      while (iTime(_Symbol, PERIOD_H1, h1BarIndex) > now && h1BarIndex < 100)
         h1BarIndex++;
      
      // Now safely read regime from last closed H1 bar
      CopyBuffer(handleH1, bufIndex, h1BarIndex, 1, buffer);
//      
      
      
      return DescribeRegime(buffer[0]);
   }

   return "NoData";
}

/*
// 📋 Updates corner dashboard with regime data
void UpdateRegimeDashboard() {
   // 🟩 Get H1 regime snapshot
   string h1Text = "H1 Regime: " + GetRegimeSnapshot(PHASE_H1);

   // 🟨 Get current M5 regime & update history
   string currentM5 = GetRegimeSnapshot(PHASE_M5);
   M5History[M5Index % ArraySize(M5History)] = currentM5;
   M5Index++;

   // 📊 Compose horizontal M5 history (oldest ➜ newest)
   string m5Text = "M5 History: ";
   for (int i = 0; i < ArraySize(M5History); i++) {
      int pos = (M5Index + i) % ArraySize(M5History);  // Circular access
      m5Text += M5History[pos];
      if (i < ArraySize(M5History) - 1) m5Text += " | ";
   }

   // 🖥️ Display to top-left corner
   Comment("\n" +"\n" +"\n" +"\n" + h1Text + "\n" +  m5Text);
}
*/




int GetCurrentRegimeBufferIndex() {
if (activePhase == PHASE_TYPE_M5)  // 🧼 compiler is happy
      return 0;  // Use buffer 0 for M5 regime
   else
      return 1;  // Use buffer 1 for H1 regime (example)
}
