//+------------------------------------------------------------------+
//| Unified Regime Dashboard EA                                      |
//+------------------------------------------------------------------+
#property strict
#include "\\modules\\UnifiedRegimeModulesmqh.mqh"

#resource "ProfitFX-TrendBoxSignal-Gold.ex5"

input bool ForceStrategyTesterMode = false;
input bool EnableDashboardToggle   = true;
input bool EnableObjectPurging     = true;
input bool ExportLiveH1Regime      = true;
input int  RefreshIntervalSeconds  = 10;
input int  NoOfBars                = 300;

//🌐 Environment flags
bool g_isTester;
bool activePhase = PHASE_TYPE_M5;

//🔧 Handles
int handleM5 = INVALID_HANDLE;
int handleH1 = INVALID_HANDLE;

//🧱 Core objects
CZoneAnalyzer    zoneAnalyzer;
RegimeDisplayRenderer displayRenderer;
RegimeDashboard        dashboard;
//CStationaryRectangles4Box *g_rectangles;  // declared in shared mql
//CStationaryRectangles4Box *g_rectangles = NULL;
CStationaryRectangles4Box  g_rectangles("Regime_");

//– Global instances for H1 and M5 strips
CStationaryRectangles4Box  h1Boxes("H1_");
CStationaryRectangles4Box  m5Boxes("M5_");

//🧠 Regime history
string g_m5_regime_history[20];
int    g_regime_index = 0;


ZoneInfo GetRegimeSnapshotH1()
{
   ZoneInfo snapshot;

   snapshot.t_start    = TimeCurrent();  // Optional: replace with recent H1 candle time
   snapshot.t_end      = TimeCurrent();
   snapshot.price_high = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   snapshot.price_low  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   snapshot.rect_count = 0;

   ZoneType regime = zoneAnalyzer.GetCurrentH1ZoneType();
   snapshot.regime_type = regime;
   snapshot.regime_tag  = DescribeZoneType(regime);

   return snapshot;
}


/*
int OnInit()
{
   g_isTester = MQLInfoInteger(MQL_TESTER) || ForceStrategyTesterMode;
   EventSetTimer(RefreshIntervalSeconds);

   //🧠 Print runtime status
   Print("🧭 EA running in ", (g_isTester ? "Strategy Tester" : "Live Mode"));

   //📈 Setup handles
   handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
   if(!g_isTester)
      handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);      

   ConfigureM5Renderer();
   ConfigureH1Renderer();
   SimulateH1RegimeStrip();       // draw static H1 history


   //📊 Zone engine init
   zoneAnalyzer = new CZoneAnalyzer("obj_rect", 0.0002, 600);
   zoneAnalyzer.LoadRectangles();
   zoneAnalyzer.MergeRects();
   zoneAnalyzer.BuildTaggedZones();

   //🖼️ Display setup
   displayRenderer.SetSpacing(12);
   displayRenderer.SetYOffset(20);
   dashboard.SetRenderer(displayRenderer);
   dashboard.SetPhaseAndHandles(activePhase, handleM5, handleH1);
   dashboard.Update();

   //🟩 Regime panel setup
   int actualWindow = ChartWindowFind(0, "RegimeM5");
   if(actualWindow < 0) actualWindow = 1;
   g_rectangles = new CStationaryRectangles4Box("RegimeDash_");
   g_rectangles.SetSubWindow(actualWindow);
   g_rectangles.SetBoxDimensions(150, 40);   //
   g_rectangles.SetBoxPosition(30);
   g_rectangles.SetLabels("M5[2]", "M5[1]", "M5[0]", "H1");
   g_rectangles.Initialize();
   g_rectangles.Create();

   //🧠 Initial snapshot feed
   FeedRegimeSnapshotToHistory();
   UpdateRegimePanelFromHistory();
   UpdateFullM5ZoneHistoryDisplay();

   return INIT_SUCCEEDED;
}
*/

//intermediate
/*
int OnInit()
{
   g_isTester = MQLInfoInteger(MQL_TESTER) || ForceStrategyTesterMode;
   EventSetTimer(RefreshIntervalSeconds);

   Print("🧭 EA running in ", (g_isTester ? "Strategy Tester" : "Live Mode"));

   handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
   if(!g_isTester)
      handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);

   ConfigureM5Renderer();         // now contains box init + layout config
   ConfigureH1Renderer();         // H1 layout placeholder
   SimulateH1RegimeStrip();       // static data layout
   
   // 1) Configure your H1 strip:
   h1Boxes = CStationaryRectangles4Box("H1_", 1, 4);
   h1Boxes.SetBoxDimensions(150, 40, 20, 30);
   h1Boxes.SetLabels("H1[3]","H1[2]","H1[1]","H1[0]","","");
   h1Boxes.Create();                          // draw H1 boxes
   h1Boxes.DrawSpacer("⇄ H1 vs M5 ⇄", 2);      // ← spacer between box#2 & #3

   // 2) Later when you build/render M5:
   m5Boxes = CStationaryRectangles4Box("M5_", 1, 4);
   m5Boxes.SetBoxDimensions(150, 40, 20, 30);
   m5Boxes.SetLabels("M5[3]","M5[2]","M5[1]","M5[0]","","");
   m5Boxes.Create();                          // draw M5 boxes
   m5Boxes.DrawSpacer("⇄ H1 vs M5 ⇄", 2);     // optional, if you want a second spacer   
   
   rectangles.Create();                     // draws your 4 boxes
   rectangles.DrawSpacer("⇄ H1 vs M5 ⇄",2);  // draws the divider   

   zoneAnalyzer = new CZoneAnalyzer("obj_rect", 0.0002, 600);
   zoneAnalyzer.LoadRectangles();
   zoneAnalyzer.MergeRects();
   zoneAnalyzer.BuildTaggedZones();

   displayRenderer.SetSpacing(12);
   displayRenderer.SetYOffset(20);
   dashboard.SetRenderer(displayRenderer);
   dashboard.SetPhaseAndHandles(activePhase, handleM5, handleH1);
   dashboard.Update();

   FeedRegimeSnapshotToHistory();
   UpdateRegimePanelFromHistory();
   UpdateFullM5ZoneHistoryDisplay();

   return INIT_SUCCEEDED;
}
*/

//not clean due to mix ?
/*
int OnInit()
{
   g_isTester = MQLInfoInteger(MQL_TESTER) || ForceStrategyTesterMode;
   EventSetTimer(RefreshIntervalSeconds);

   Print("🧭 EA running in ", g_isTester ? "Strategy Tester" : "Live");

   // your existing custom-indicator handles...
   ConfigureM5Renderer();
   ConfigureH1Renderer();
   SimulateH1RegimeStrip();  // draws H1 boxes if inside, else skip this

   // 1) H1 strip
   h1Boxes = CStationaryRectangles4Box("H1_", 1, 4);
   h1Boxes.SetBoxDimensions(150, 40, 20, 30);
   h1Boxes.SetLabels("H1[3]","H1[2]","H1[1]","H1[0]","","");
   h1Boxes.ClearBoxes();      // optional: ensure fresh
   h1Boxes.Create();          // draw H1 boxes
   h1Boxes.DrawSpacer("⇄ H1 vs M5 ⇄", 2);

   // 2) M5 strip
   m5Boxes = CStationaryRectangles4Box("M5_", 1, 4);
   m5Boxes.SetBoxDimensions(150, 40, 20, 30);
   m5Boxes.SetLabels("M5[3]","M5[2]","M5[1]","M5[0]","","");
   m5Boxes.ClearBoxes();
   m5Boxes.Create();          // draw M5 boxes

   // if you want a second spacer between M5 and next strip:
   // m5Boxes.DrawSpacer("⇄ M5 vs Next ⇄", 2);

   // Zone analyzer setup...
   zoneAnalyzer = new CZoneAnalyzer("obj_rect", 0.0002, 600);
   zoneAnalyzer.LoadRectangles();
   zoneAnalyzer.MergeRects();
   zoneAnalyzer.BuildTaggedZones();

   displayRenderer.SetSpacing(12);
   displayRenderer.SetYOffset(20);
   dashboard.SetRenderer(displayRenderer);
   dashboard.SetPhaseAndHandles(activePhase, handleM5, handleH1);
   dashboard.Update();

   FeedRegimeSnapshotToHistory();
   UpdateRegimePanelFromHistory();
   UpdateFullM5ZoneHistoryDisplay();
   return(INIT_SUCCEEDED);
}
*/


int OnInit()
{
   //--- Tester vs Live mode flag
   bool isTester = (MQLInfoInteger(MQL_TESTER) != 0);
   Print("🧭 EA running in ", isTester ? "Strategy Tester" : "Live Mode");

   EventSetTimer(RefreshIntervalSeconds);

   //--- Load your custom-indicator handles
   handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
   if(!isTester)
      handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);

   //--- 1) Configure & draw H1 strip
   h1Boxes.SetSubWindow(1);                // draw into subwindow #1
   h1Boxes.SetBoxGap(20);                  // 20px between boxes
   h1Boxes.SetBoxDimensions(150, 40);      // 150px wide, 40px tall
   h1Boxes.SetTopMargin(30);               // 30px down from top
   h1Boxes.SetLabels(                       // exactly 4 labels
      "H1[3]", "H1[2]", "H1[1]", "H1[0]"
   );
   h1Boxes.ClearBoxes();                   // remove any old H1 objects
   h1Boxes.Create();                       // draw the 4 H1 boxes
   h1Boxes.DrawSpacer("⇄ H1 vs M5 ⇄", 2);  // spacer between box#2 & #3

   //--- 2) Configure & draw M5 strip
   m5Boxes.SetSubWindow(1);
   m5Boxes.SetBoxGap(20);
   m5Boxes.SetBoxDimensions(150, 40);
   m5Boxes.SetTopMargin(30);
   m5Boxes.SetLabels(
      "M5[3]", "M5[2]", "M5[1]", "M5[0]"
   );
   m5Boxes.ClearBoxes();
   m5Boxes.Create();                       // draw the 4 M5 boxes
   // (no spacer needed unless you want another divider)

   //--- 3) Zone analyzer & dashboard setup
   zoneAnalyzer = new CZoneAnalyzer("obj_rect", 0.0002, 600);
   zoneAnalyzer.LoadRectangles();
   zoneAnalyzer.MergeRects();
   zoneAnalyzer.BuildTaggedZones();

   // instantiate the dashboard object
   g_rectangles = new CStationaryRectangles4Box("RegimeDash_");
   g_rectangles.SetSubWindow(1);
   g_rectangles.SetBoxGap(20);
   g_rectangles.SetBoxDimensions(150,40);
   g_rectangles.SetTopMargin(30);
   g_rectangles.SetLabels("R0","R1","R2","H1");
   g_rectangles.ClearBoxes();
   g_rectangles.Create();
   g_rectangles.DrawSpacer("⇄ H1 vs M5 ⇄",2);


   //--- 4) Initial update of your panels
   FeedRegimeSnapshotToHistory();
   UpdateRegimePanelFromHistory();
   UpdateFullM5ZoneHistoryDisplay();

   return(INIT_SUCCEEDED);
}


//original
/*
void OnTimer()
{
   if(g_isTester)
   {
      FeedRegimeSnapshotToHistory();
      UpdateRegimePanelFromHistory();
      return;
   }

   if(EnableObjectPurging)
   {
      IndicatorRelease(handleM5);
      IndicatorRelease(handleH1);
      PurgeAllObjects();
      Sleep(500);
   }

   if(EnableDashboardToggle)
   {
      if(activePhase == PHASE_TYPE_M5)
      {
         handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
         activePhase = PHASE_TYPE_H1;
         Print("📈 Switched to H1 regime.");
      }
      else
      {
         handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
         activePhase = PHASE_TYPE_M5;
         Print("📉 Switched to M5 regime.");
      }
   }

   if(ExportLiveH1Regime)
      ExportH1RegimeToFile();

   dashboard.Update();
}
*/

void OnTimer()
{
   // 1) Tester mode: only update your snapshot & panel  
   if(g_isTester)
   {
      FeedRegimeSnapshotToHistory();
      UpdateRegimePanelFromHistory();
      // Optionally redraw your boxes in tester too:
      h1Boxes.ClearBoxes();
      h1Boxes.Create();
      h1Boxes.DrawSpacer("⇄ H1 vs M5 ⇄",2);
      m5Boxes.ClearBoxes();
      m5Boxes.Create();
      return;
   }

   // 2) Optional object purging  
   if(EnableObjectPurging)
   {
      IndicatorRelease(handleM5);
      IndicatorRelease(handleH1);
      PurgeAllObjects();
      Sleep(500);
   }

   // 3) Dashboard toggling between M5/H1 indicator  
   if(EnableDashboardToggle)
   {
      if(activePhase == PHASE_TYPE_M5)
      {
         handleH1     = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
         activePhase  = PHASE_TYPE_H1;
         Print("📈 Switched to H1 regime.");
      }
      else
      {
         handleM5     = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
         activePhase  = PHASE_TYPE_M5;
         Print("📉 Switched to M5 regime.");
      }
   }

   // 4) Optional export  
   if(ExportLiveH1Regime)
      ExportH1RegimeToFile();

   // 5) Rebuild your snapshot & zones  
   FeedRegimeSnapshotToHistory();
   UpdateRegimePanelFromHistory();
   UpdateFullM5ZoneHistoryDisplay();

   // 6) Redraw H1 & its spacer  
   h1Boxes.ClearBoxes();
   h1Boxes.Create();
   h1Boxes.DrawSpacer("⇄ H1 vs M5 ⇄",2);

   // 7) Redraw M5  
   m5Boxes.ClearBoxes();
   m5Boxes.Create();

   // 8) Finally update the rest of your dashboard  
   dashboard.Update();
}



void OnDeinit(const int reason)
{
   EventKillTimer();
   /*
   if(g_rectangles != NULL)
   {
      g_rectangles.Destroy();
      delete g_rectangles;
   }
   */
}

ZoneInfo GetRegimeSnapshot()
   {
      if (ArraySize(zoneAnalyzer.zones) == 0)
         return ZoneInfo();  // empty fallback
   
      return zoneAnalyzer.zones[ArraySize(zoneAnalyzer.zones) - 1];
   }

//✨ Snapshot feeder
void FeedRegimeSnapshotToHistory()
{
   ZoneInfo snapshot = GetRegimeSnapshot();
   //string regime_description = DescribeRegime(snapshot);

   CZoneInfo *zoneObj = new CZoneInfo();
   zoneObj.Set(snapshot.t_start, snapshot.t_end, snapshot.price_high, snapshot.price_low,
               snapshot.rect_count, snapshot.regime_tag, snapshot.regime_type);
   string regime_description = DescribeRegime(*zoneObj);
   
   
   if(g_regime_index == 0 || regime_description != g_m5_regime_history[g_regime_index - 1])
   {
      g_m5_regime_history[g_regime_index++] = regime_description;
      if(g_regime_index >= ArraySize(g_m5_regime_history))
      {
         for(int i = 1; i < ArraySize(g_m5_regime_history); i++)
            g_m5_regime_history[i - 1] = g_m5_regime_history[i];
         g_regime_index = ArraySize(g_m5_regime_history) - 1;
      }
   }
}

//🧠 Extract last 3 regimes
void GetLast3M5Regimes(string &r0, string &r1, string &r2)
{
   int n = g_regime_index - 1;
   r0 = (n >= 2) ? g_m5_regime_history[n - 2] : "...";
   r1 = (n >= 1) ? g_m5_regime_history[n - 1] : "...";
   r2 = (n >= 0) ? g_m5_regime_history[n]     : "...";
}

//📊 Panel updater
void UpdateRegimePanelFromHistory()
{
   string r0, r1, r2;
   GetLast3M5Regimes(r0, r1, r2);

   //string h1_regime = g_isTester ? ReadH1RegimeFromFile() : DescribeRegime(GetRegimeSnapshotH1());
   string h1_regime = g_isTester
                   ? ReadH1RegimeFromFile()
                   : zoneAnalyzer.GetCurrentH1ZoneTypeString();


   g_rectangles.UpdateLabels(r0, r1, r2, h1_regime);
   g_rectangles.UpdateColors(MapColor(r0), MapColor(r1), MapColor(r2), MapColor(h1_regime));
}

//📎 File reader
string ReadH1RegimeFromFile()
{
   string regime = "...";
   int file = FileOpen("H1Regime.txt", FILE_READ | FILE_TXT);
   if(file != INVALID_HANDLE)
   {
      regime = FileReadString(file);
      FileClose(file);
   }
   return regime;
}

//💾 File writer
void ExportH1RegimeToFile()
{
   //ZoneInfo h1 = GetRegimeSnapshotH1();
   //string regime = DescribeRegime(h1);
   ZoneInfo h1 = GetRegimeSnapshotH1();  // This creates the missing identifier
   CZoneInfo *h1obj = new CZoneInfo();
   h1obj.Set(h1.t_start, h1.t_end, h1.price_high, h1.price_low, 
             h1.rect_count, h1.regime_tag, h1.regime_type);
   
   string regime = DescribeRegime(*h1obj);
   
   

   int file = FileOpen("H1Regime.txt", FILE_WRITE | FILE_TXT);
   if(file != INVALID_HANDLE)
   {
      FileWrite(file, regime);
      FileClose(file);
   }
}

//🎨 Color mapper
color MapColor(string regime)
{
   if(StringFind(regime, "BUY") >= 0 || regime == "UP")
      return clrLime;
   if(StringFind(regime, "SELL") >= 0 || regime == "DOWN")
      return clrTomato;
   if(regime == "NEUTRAL")
      return clrDarkGray;
   return clrGray;
}


//EA utility function
void UpdateFullM5ZoneHistoryDisplay(int maxZones = 20)
{
   string zoneLabels[];
   ArrayResize(zoneLabels, 0);

   CArrayObj *zoneArray = zoneAnalyzer.GetTaggedZones();
   if(zoneArray == NULL || zoneArray.Total() == 0) return;

   // 🔽 Start index to only grab last 'maxZones' items
   int startIdx = MathMax(0, zoneArray.Total() - maxZones);

   for(int i = startIdx; i < zoneArray.Total(); i++)
   {
      CZoneInfo *zone = (CZoneInfo *)zoneArray.At(i);
      if(zone == NULL) continue;

      string tstamp = TimeToString(zone.t_start, TIME_MINUTES);
      string label  = DescribeRegime(*zone);

      string entry = tstamp + ":" + label;
      ArrayResize(zoneLabels, ArraySize(zoneLabels) + 1);
      zoneLabels[ArraySize(zoneLabels) - 1] = entry;
   }

   //displayRenderer.DrawRegimeBoxes(zoneLabels);  // Only recent zones get drawn
}


void SimulateH1RegimeStrip()
{
   CArrayObj *mockH1History = new CArrayObj;

   mockH1History.Add(new CZoneInfo());
   mockH1History.Add(new CZoneInfo());
   mockH1History.Add(new CZoneInfo());

   ((CZoneInfo*)mockH1History.At(0)).Set(TimeCurrent(), TimeCurrent(), 1.0, 1.0, 0, "DOWN", ZONE_DOWN);
   ((CZoneInfo*)mockH1History.At(1)).Set(TimeCurrent(), TimeCurrent(), 1.0, 1.0, 0, "UP", ZONE_UP);
   ((CZoneInfo*)mockH1History.At(2)).Set(TimeCurrent(), TimeCurrent(), 1.0, 1.0, 0, "UP", ZONE_UP);

   //displayRenderer.DrawH1RegimeBoxes(mockH1History);
   g_rectangles.UpdateBoxes(mockH1History);
}

void ConfigureM5Renderer()
{
   g_rectangles = new CStationaryRectangles4Box("RegimeDash_");
   int actualWindow = ChartWindowFind(0, "RegimeM5");
   if(actualWindow < 0) actualWindow = 1;
   g_rectangles.SetSubWindow(actualWindow);

   g_rectangles.SetBoxDimensions(150, 40);
   g_rectangles.SetBoxPosition(30);
   g_rectangles.SetLabels("M5[2]", "M5[1]", "M5[0]", "H1");

   g_rectangles.Initialize();
   g_rectangles.Create();
}

void ConfigureH1Renderer()
{
   // Placeholder for future H1 renderer setup
   // Will later set dimensions, box position, and labels for H1 regime boxes
}

void PurgeAllObjects()
{
   int total = ObjectsTotal(0);

   for(int i = total - 1; i >= 0; i--)
   {
      string objName = ObjectName(0,i);
      ObjectDelete(0, objName);
   }
}
