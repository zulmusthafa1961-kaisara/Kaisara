//+------------------------------------------------------------------+
//|        TestDriveRectsWithClass_CenterSpacer.mq5                 |
//+------------------------------------------------------------------+
#property strict

//#resource "\\Files\\MergedH1Zones.csv" as uchar MergedZones[]   //This embeds the file as a byte array named MergedH1Zones[].
#resource "customindicator//AProfitFX-Gold-PreLoadH1.ex5"               
#resource "ProfitFX-TrendBoxSignal-Gold.ex5"                             
#resource "AProfitFX-Gold-PreLoadH1.ex5"

#include <Arrays/ArrayObj.mqh>  
#include "modules//ZoneResourceLoader.mqh"
#include "modules/UnifiedRegimeModulesmqh.mqh"
#include "modules/CSVutils.mqh"


#define BOX_W        50                            
#define BOX_H        30
#define BOX_GAP      10
#define STRIP_GAP   220
#define TOP_MARGIN   20
#define LEFT_MARGIN  20

CStationaryRectangles4Box leftBoxes("Left_"), rightBoxes("Right_");  //tested ok
CStationaryRectangles4Box *renderer;

CArrayObj regimeZones;         // Declare this at the top of your EA

int handleM5 = INVALID_HANDLE;
int handleH1 = INVALID_HANDLE;

//minimal user inputs
//input ENUM_ENV_OPERATION_MODE OperationMode        = ENUM_LIVE_ENV;
input string      RectPrefix                 = "DashRect_";
input int         RefreshIntervalSeconds     = 15;
input int         NoOfBars                   = 300;

bool           preloadDone = false;
CZoneAnalyzer analyzer;
//CArrayObj *pLoadedZones;
CArrayObj *pLoadedZones; // at top if needed, or just use directly



int OnInit()
{

   bool bSucc = ValidateUserInput(); 
   if(!bSucc) return (INIT_FAILED);
   
   bool isTester = (MQLInfoInteger(MQL_TESTER) != 0);
   Print("📁 Terminal Common Path: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH));
   Print("📁 Terminal Data Path: ", TerminalInfoString(TERMINAL_DATA_PATH));

   
   switch(OperationMode)
     {
    
      case ENUM_TEST_ENV_PRELOAD_H1 :
         handleH1 = iCustom(_Symbol, PERIOD_H1, IndicatorFilename(), NoOfBars);
      // not a focus for now. 
      /*
                  if(!isTester) return INIT_FAILED;
                  handleH1 = iCustom(_Symbol, PERIOD_H1, IndicatorFilename(), NoOfBars);
                  
                  PrintFormat("Tester loaded %d H1 bars for %s", Bars(_Symbol, PERIOD_H1), _Symbol);
                  

                  //display message in main screen; Test Mode for populating H1 buffer is in progress
                  
                  // Because TEST_PRELOAD_H1 runs the indicator on ALL H1 bars
                  //    before OnInit, we can now grab *every* rectangle:
                  analyzer.LoadFromChart(""); 
                  //zoneAnalyzer.MergeZones();  //integrated into BuildTaggedZones()
                  analyzer.BuildTaggedZones();
                  preloadDone = true;
                  
                  // Export directly to CSV:
                  ExportMergedZonesCSV("MergedH1Zones.csv", analyzer.GetZones());               
       */  
         break;
         
      
      case ENUM_TEST_ENV_NORMAL :
                  //handleM5 = iCustom(_Symbol, PERIOD_M5, IndicatorFilename(), NoOfBars);
                   handleH1 = iCustom(_Symbol, PERIOD_H1, IndicatorFilename(), NoOfBars);

                        if (!preloadDone && OperationMode == ENUM_TEST_ENV_NORMAL) {
                          
 
                           pLoadedZones = _LoadZonesFromResourceCSV();                          
                           if (pLoadedZones == NULL) {
                                       return(INIT_FAILED);
                           }
                           
                           // print out loadedZones
                           for(int i=0;i<pLoadedZones.Total();i++)
                             {
                              CObject *pObj = pLoadedZones.At(i);
                              CZoneCSV *pZone = dynamic_cast<CZoneCSV *>(pObj);
                              
                                 if(pZone != NULL) {  
                                     //PrintFormat("DEBUG in EA : regime_type = '%s'", EnumToString(pZone.GetRegimeType())); 
                                 
                                     PrintFormat("EA:row#%d → starttime: %s->endtime: %s->price %.2f–%.2f | Tag: %s | Regime: %s",
                                         i,
                                         TimeToString(pZone.t_start, TIME_DATE | TIME_MINUTES),
                                         TimeToString(pZone.t_end, TIME_DATE | TIME_MINUTES),
                                         pZone.price_low, pZone.price_high,
                                         pZone.regime_tag, // Tag: Green
                                         EnumToString(pZone.GetRegimeType())); 
                                 }                                 
                                 else{
                                    Print("Object at index ", i, " is not a CZoneCSV");
                                       return(INIT_FAILED);
                                 }   
                             }
                             CheckZoneContinuity(pLoadedZones); 
                             preloadDone = true; 
                           }  
                           
                           
      break;   
      
      default :
                  EventSetTimer(RefreshIntervalSeconds);
                  handleM5 = iCustom(_Symbol, PERIOD_M5, IndicatorFilename(), NoOfBars);  // applies to ENUM_TEST_ENV_NORMAL
         break;                                                                           // and also ENUM_LIVE_ENV
     }
     
   
   //renderer = new CStationaryRectangles4Box();  
   //SetupInitialDisplaySW();  // Unify display setup so SetupInitialDisplaySW() handles all modes:  
      
   return(INIT_SUCCEEDED);
}

void SetupInitialDisplaySW(){
         const int SW = 1; // sub-window
         int stripWidth  = 4*BOX_W + 3*BOX_GAP;
         int rightMargin = LEFT_MARGIN + stripWidth + STRIP_GAP;
         Print(">> rightMargin = ", rightMargin);
      
         //ALWAYS SHOW LEFT STRIP(MEANT FOR H1 REGIME) WHEN OPERATING UNDER ANY OF THE ENVIRONMENT
         DrawStrip(leftBoxes, SW, LEFT_MARGIN, clrDodgerBlue, "L3","L2","L1","L0");
                  
         // DON'T SHOW RIGHT STRIP (MEANT FOR M5 REGIME) WHEN OPERATING UNDER ENUM_TEST_ENV_PRELOAD_H1
         // GO AHEAD SHOW RIGHT STRIP WHEN OPERATING UNDER ENUM_LIVE_ENV OR ENUM_TEST_ENV_NORMAL (OperationMode != ENUM_TEST_ENV_PRELOAD_H1)
         if(OperationMode != ENUM_TEST_ENV_PRELOAD_H1){               
               DrawStrip(rightBoxes, SW, rightMargin, clrCrimson, "R3","R2","R1","R0");
               // Center spacer – only when both strips exist               
               DrawCenterSpacer(SW);               
       }     
}


void DrawStrip(CStationaryRectangles4Box &boxObj,
               int sw, int left, color col,
               string a, string b, string c, string d)
{
   boxObj.SetSubWindow(sw);
   boxObj.SetLeftMargin(left);
   boxObj.SetBoxGap(BOX_GAP);
   boxObj.SetBoxDimensions(BOX_W, BOX_H);
   boxObj.SetTopMargin(TOP_MARGIN);
   boxObj.SetLabels(a,b,c,d);
   boxObj.Initialize();
   boxObj.ClearBoxes();
   boxObj.Create();
   boxObj.UpdateLabels(a,b,c,d);
   boxObj.UpdateColors(col,col,col,col);
}



void DrawCenterSpacer(int sw)
{
   string name   = "Center_Spacer";
   string text   = "⇄ CENTER ⇄";
   int stripWidth  = 4*BOX_W + 3*BOX_GAP;
   int    fs     = 12;
   int    textW  = StringLen(text) * (fs/2);
   int    x      = LEFT_MARGIN + stripWidth + (STRIP_GAP/2) - (textW/2);
   int    y      = TOP_MARGIN + (BOX_H/2) - (fs/2);

   if(ObjectCreate(0, name, OBJ_LABEL, sw, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString (0, name, OBJPROP_TEXT,       text);
      //ObjectSetInteger(0, name, OBJPROP_COLOR,      clrGold);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE,   fs);
      ObjectSetInteger(0, name, OBJPROP_BACK,       false);
   }
}


void OnDeinit(const int reason)
{
   leftBoxes.ClearBoxes();
   rightBoxes.ClearBoxes();
   ObjectDelete(0,"Left_Spacer");   // if your class created one
   ObjectDelete(0,"Right_Spacer");
   ObjectDelete(0,"Center_Spacer");
}

/*
void OnTimer() {
   if(OperationMode != ENUM_TEST_ENV_PRELOAD_H1){
         Print("🔄 Toggling regime..");
      
         // ✂️ Phase 0: Clean slate
         IndicatorRelease(handleM5);
         IndicatorRelease(handleH1);
      
         if( g_activePhase == PHASE_TYPE_M5) PurgeAllRectObjectsFromMainChart();   
         // in PHASE_TYPE_H1, there is no rects formed so need not to purge
         Sleep(1000);  // Optional delay for visual clarity
      
         // 🔁 Phase 1: Switch regime
         if (OperationMode == ENUM_LIVE_ENV && g_activePhase == PHASE_TYPE_M5) {
            //handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
            g_activePhase = PHASE_TYPE_H1;
            Print("📈 H1 regime activated - reading H1 buffer from file -> rendering H1 regime strip");
            // todo: function to populate H1 buffer (read file done during OnInit() 
         } else if((OperationMode == ENUM_LIVE_ENV || OperationMode == ENUM_TEST_ENV_NORMAL) && g_activePhase == PHASE_TYPE_H1) {
            handleM5 = iCustom(_Symbol, PERIOD_M5, IndicatorFilename(), NoOfBars);
            g_activePhase = PHASE_TYPE_M5;
            Print("📉 M5 regime activated --> purging");
         }
         
         Sleep(500);  // Give buffers time to populate
         //dashboard.Update();
   }
}
*/


void OnTimer()
{
   // 0) skip entirely if we’re just populating H1 once at init ; 
   // actually unnecessary because we're not using OnTimer() for ENUM_TEST_ENV_PRELOAD_H1 as defined in OnInit()
   // but it is ok to leave this code here to explicitly express the intention
   if(OperationMode == ENUM_TEST_ENV_PRELOAD_H1)
      return;   
   
   // 1) clear everything the indicator drew last pass
   PurgeAllRectObjectsFromMainChart();

   // 2) release whatever handle was active
   IndicatorRelease(handleM5);
   IndicatorRelease(handleH1);

   // 3) swap and reload
   if(g_activePhase == PHASE_TYPE_M5)
   {
      handleH1 = iCustom(_Symbol, PERIOD_H1, IndicatorFilename(), NoOfBars);
      g_activePhase = PHASE_TYPE_H1;
   }
   else
   {
      handleM5 = iCustom(_Symbol, PERIOD_M5, IndicatorFilename(), NoOfBars);
      g_activePhase = PHASE_TYPE_M5;
   }

   // 4) let buffers fill, then update our strips
   Sleep(200);
   //dashboard.Update();
}



void PurgeAllRectObjectsFromMainChart()
{
   string prefix = "obj_rect";              // or your actual prefix
   int total = ObjectsTotal(0);             // count in main chart

   // elegant solution: iterate backwards so deleting doesn't break the index order; no need cycling deletion process
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, prefix) == 0)  
         ObjectDelete(0, name);
   }
}


bool ShouldDrawLeft(string tag) {
   return tag == "H1";  // Or whatever tag you use for left-side regimes
}

void OnTick()
{
   if (!preloadDone || pLoadedZones == NULL) return;

   //int activeRow = -1;
   //int regimeType = FindActiveZoneCSV(pLoadedZones, PERIOD_H1, activeRow);
   //int regimeType = FindActiveZoneCSV(pLoadedZones, PERIOD_M5, activeRow);
   static int previousRegimeM5 = -1;
   LogRegimeTransitionM5(previousRegimeM5);
   int activeRow = 0;
   int regimeType = FindActiveZoneCSV(pLoadedZones, PERIOD_M5, activeRow);

   // Use regimeType to drive behavior
}



extern CArrayObj *pLoadedZones; // at top if needed, or just use directly
//void LogRegimeTransitionM5(CArrayObj *pLoadedZones, int &previousRegime)
void LogRegimeTransitionM5(int &previousRegime)
{
/*   
   Print("Entering LogRegimeTransitionM5");
   int fileHandle = FileOpen("RegimeTransitions_M5.csv", FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON);

   if (fileHandle != INVALID_HANDLE)
   {
      FileWrite(fileHandle, "Time", "CurrentRegime", "PreviousRegime"); // Header
      FileFlush(fileHandle);  // Ensures data hits disk
      FileClose(fileHandle);  // Properly releases handle
      Print("✅ RegimeTransitions_M5.csv written successfully in tester sandbox.");
   }
   else
   {
      Print("⚠️ Failed to open RegimeTransitions_M5.csv for writing.");
   }
*/


   // Prepare a valid reference for activeRow (required by FindActiveZoneCSV)
   int activeRow = 0;
   int regimeType = FindActiveZoneCSV(pLoadedZones, PERIOD_M5, activeRow);
   // Log only on regime change
   int currentRegime = regimeType;  // Assuming regimeType reflects the latest value
   if (regimeType != previousRegime)
   {
      string fileName = "RegimeTransitions_M5.csv";
      string header = "Time,CurrentRegime,PreviousRegime";
      string row = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES) + "," + IntegerToString(currentRegime) + "," + IntegerToString(previousRegime);
      WriteCSVLog(fileName, header, row);
   }

   previousRegime = regimeType;
}


void WriteCSVLog(string fileName, string header, string dataRow)
{
   int fileHandle = FileOpen(fileName, FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);
   if (fileHandle != INVALID_HANDLE)
   {
      if (FileSize(fileHandle) == 0)
      {
         FileWrite(fileHandle, header); // Write header only if file is empty
      }
      FileSeek(fileHandle, 0, SEEK_END);  // Append mode
      FileWrite(fileHandle, dataRow);
      FileFlush(fileHandle);
      FileClose(fileHandle);
   }
   else
   {
      Print("❌ Failed to open ", fileName);
   }
}




bool ValidateUserInput(){
   // chk # 1: chart in live , user correctly selected ENUM_LIVE_ENV but did not set M5  
   if (!MQLInfoInteger(MQL_TESTER) && (OperationMode == ENUM_LIVE_ENV) && Period()!=PERIOD_M5) {
      Print("Wrong TimeFrame selected in live environment");
      return false;
   }     
   

   if (MQLInfoInteger(MQL_TESTER) && OperationMode == ENUM_LIVE_ENV) {
      Print("Wrong environment selected in Strategy Tester  - err type 1");
      return false;
   }
   

   // chart in live but user wrongly not selected ENUM_LIVE_ENV
   if (!MQLInfoInteger(MQL_TESTER) && (OperationMode != ENUM_LIVE_ENV)) {
      Print("Wrong environment selected in Live environment - err type 2");
      return false;
   }   
   
/*   
   // chart in strategy tester, user correctly selected ENUM_TEST_ENV_PRELOAD_H1 but did not set H1 TF in strategy tester   
   if (MQLInfoInteger(MQL_TESTER) && (OperationMode == ENUM_TEST_ENV_PRELOAD_H1) && Period()!=PERIOD_H1) {
      Print("Wrong TimeFrame selected in Strategy Tester for collecting H1 buffer");
      return false;
   }     
*/   
//#include "RegimeVisualizer.mqh"

CRegimeVisualizer regimePainter;
   for (int i = 0; i < regimeZones.Total(); i++) {
      CZoneCSV *zone = (CZoneCSV *)regimeZones.At(i);
      regimePainter.Draw(zone);
   }

   
   
   return true;
}


string IndicatorFilename()
{
   switch(OperationMode)
   {
      case ENUM_LIVE_ENV:
         return "::ProfitFX-TrendBoxSignal-Gold.ex5";
      
      case ENUM_TEST_ENV_PRELOAD_H1:
         return "::AProfitFX-Gold-PreLoadH1.ex5";  
      
      default: // ENUM_TEST_ENV_NORMAL OR ENUM_LIVE_ENV
         return "::ProfitFX-TrendBoxSignal-Gold.ex5";
       
   }
}


//+------------------------------------------------------------------+
//| CSV export helper                                               |
//+------------------------------------------------------------------+
void ExportMergedZonesToCSV(const string filename)
{
   CArrayObj *mz = analyzer.GetTaggedZones();
   int count = mz.Total();

   // Open as a true comma‐delimited CSV
   int fh = FileOpen(filename,
                     FILE_WRITE | FILE_CSV);
                     //',');
   if(fh == INVALID_HANDLE)
   {
      Print("ExportMergedZones: unable to open ", filename);
      return;
   }

   // Header
   FileWrite(fh,
             "StartTS","EndTS","Start","End",
             "Tag","High","Low","Count");

   // Data
   for(int i = 0; i < count; i++)
   {
      CZoneInfo *z = (CZoneInfo*)mz.At(i);
      FileWrite(fh,
                (long)z.TStart(),
                (long)z.TEnd(),
                TimeToString(z.TStart(), TIME_DATE|TIME_SECONDS),
                TimeToString(z.TEnd(),   TIME_DATE|TIME_SECONDS),
                z.Tag(),
                DoubleToString(z.PriceHigh(), _Digits),
                DoubleToString(z.PriceLow(),  _Digits),
                z.Count());
   }
   FileClose(fh);

   PrintFormat("✅ TestDrive-A: exported %d merged zones to %s",
               count, filename);
}


void ZoneDebugView(CArrayObj &zones) {
   Print("📊 ZoneDebugView → Total Zones: ", zones.Total());

   for (int i = 0; i < zones.Total(); i++) {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (!zone) continue;

      string side = ShouldDrawLeft(zone.tag) ? "LEFT" : "RIGHT";
      string regimeName = zone.GetRegimeTypeName();  // Optional helper if available
      PrintFormat("🟦 [%02d] %s | Tag: %s | Type: %s | Start: %s",
                  i,
                  side,
                  zone.tag,
                  regimeName,
                  TimeToString(zone.t_start));
   }
}

int FindActiveZoneCSV(CArrayObj *zones, ENUM_TIMEFRAMES tf, int &activeIndex)
{
   if (zones == NULL) return -1;

   datetime now = iTime(_Symbol, tf, 0);
   activeIndex = -1;

   static int lastActiveIndex = -1;

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneCSV *zone = dynamic_cast<CZoneCSV *>(zones.At(i));
      if (zone == NULL) continue;

      // Strict alignment on regime timing
      if (now >= zone.t_start && now < zone.t_end)
      {
         activeIndex = i;

         if (lastActiveIndex != i)
         {
            PrintFormat("🎯 Regime ACTIVE at row %d | Price: %s-%s — Tag: %s | Type: %s",
                        i, DoubleToString(zone.price_low,2), DoubleToString(zone.price_high,2), zone.regime_tag, EnumToString(zone.GetRegimeType()));
            lastActiveIndex = i;
         }
         return zone.GetRegimeType();  // Returns enum RegimeType
      }
   }

   // Log regime exit only once
   if (lastActiveIndex != -1)
   {
      PrintFormat("🔕 Regime exited at candle: %s",
                  TimeToString(now, TIME_DATE | TIME_MINUTES));
      lastActiveIndex = -1;
   }

   return -1;  // No regime active
}

void CheckZoneContinuity(CArrayObj *zones)
{
   if (zones == NULL || zones.Total() < 2)
   {
      Print("⚠️ Zone continuity check skipped: Not enough entries.");
      return;
   }

   for (int i = 0; i < zones.Total() - 1; i++)
   {
      CZoneCSV *curr = (CZoneCSV *)zones.At(i);
      CZoneCSV *next = (CZoneCSV *)zones.At(i + 1);

      if (curr == NULL || next == NULL) continue;

      datetime curr_end = curr.t_end;
      datetime next_start = next.t_start;

      // Detect overlap
      if (curr_end > next_start)
      {
         PrintFormat("❌ Overlap: row %d ends at %s, next row %d starts at %s",
                     i, TimeToString(curr_end), i + 1, TimeToString(next_start));
      }
      // Detect gap
      else if (curr_end < next_start)
      {
         PrintFormat("⚠️ Gap detected: row %d ends at %s, row %d starts at %s",
                     i, TimeToString(curr_end), i + 1, TimeToString(next_start));
      }
      // Perfect continuity
      else
      {
         PrintFormat("✅ Seamless: row %d → row %d at %s",
                     i, i + 1, TimeToString(curr_end));
      }
   }
}
