//+------------------------------------------------------------------+
//|                                                      Kaisara.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#resource "ProfitFX-TrendBoxSignal-Gold.ex5"

enum DebugLevel
  {
   DEBUG_NONE = 0,    // No debugging
   DEBUG_CRITICAL_ERROR = 1, //Critical error
   DEBUG_ERROR = 2,   // Only error messages
   DEBUG_WARNING = 3, // warnings
   DEBUG_INFO = 4,     // info messages
   DEBUG_VERBOSE = 5   //verbose
  };
input DebugLevel  debugLevelInput = DEBUG_INFO;
input bool        DebugEnabled = true;         // Declare a global variable to control debugging
  
  
struct Zone
{
   datetime t_start, t_end;
   double price_high, price_low;
   string regime;
   int rects;
};

Zone RecentZones[];
   
input bool        TradingCurrency = false;
input int         NoOfBars = 300;
int KaisaraIndicatorHandleM5, KaisaraIndicatorHandleM15, KaisaraIndicatorHandleH1, KaisaraIndicatorHandleH4, KaisaraIndicatorHandleD1;

double UpBufferM5[],UpBufferM15[],UpBufferH1[],UpBufferH4[],UpBufferD1[];
double DnBufferM5[],DnBufferM15[],DnBufferH1[],DnBufferH4[],DnBufferD1[];

int OnInit() {
   TesterHideIndicators(true);



   KaisaraIndicatorHandleM5 = iCustom(_Symbol,PERIOD_M5,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
   //KaisaraIndicatorHandleM15 = iCustom(_Symbol,PERIOD_M15,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
   KaisaraIndicatorHandleH1 = iCustom(_Symbol,PERIOD_H1,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
   //KaisaraIndicatorHandleH4 = iCustom(_Symbol,PERIOD_H4,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
   if(TradingCurrency) KaisaraIndicatorHandleD1 = iCustom(_Symbol,PERIOD_D1,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);

   ArraySetAsSeries(UpBufferM5,true);  ArraySetAsSeries(DnBufferM5,true);
   ArraySetAsSeries(UpBufferM15,true); ArraySetAsSeries(DnBufferM15,true);
   ArraySetAsSeries(UpBufferH1,true);  ArraySetAsSeries(DnBufferH1,true);
   ArraySetAsSeries(UpBufferH4,true);  ArraySetAsSeries(DnBufferH4,true);  
   if(TradingCurrency) ArraySetAsSeries(UpBufferD1,true);  ArraySetAsSeries(DnBufferD1,true);    
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   IndicatorRelease(KaisaraIndicatorHandleM5);
   //IndicatorRelease(KaisaraIndicatorHandleM15);
   IndicatorRelease(KaisaraIndicatorHandleH1);
   //IndicatorRelease(KaisaraIndicatorHandleH4);
   if(TradingCurrency) IndicatorRelease(KaisaraIndicatorHandleD1);            
}

void OnTick() {

/*
High-Level Integration Plan
To group rectangles and interpret their regimes from the most recent 100 candles, you’ll need to do this once per new bar, 
ideally before making trading decisions:

if (!IsNewBar()) return;

// 🧱 Step 1: Extract most recent 100 rectangles from chart
// 🧲 Step 2: Group them into zones based on exact price range & time overlap
// 🟢🔴 Step 3: Tag each zone with regime using GetBoxRegime()
// 🧠 Step 4: Store or evaluate those zones as context for entry/exit decisions

Right after this point:
// For this scalping strategy on Gold, we'll be using Trend @ H1 as Trend Bias. 
if(trendstrH1=="UP" && trendstrM5=="UP"){
...

You can inject a new function call like:
AnalyzeRecentZones();  // 🔍 Extract, group, and tag zones here

What AnalyzeRecentZones() Could Look Like
You can modularize the previous zone grouping logic into a helper function that:

Scans objects named "obj_rect" on the chart*

Keeps the last 100 based on time

Groups them into clean zones

Calls GetBoxRegime() on each zone using the buffer + time logic

Optionally, logs zones or returns them into a global struct/array for EA use

💡 Why This Is Powerful
Once integrated:

Your EA knows if the most recent confirmed box was “DOWN” but now the current buffer says “UP” → potential regime shift.

You can skip entries during no-zone / overlapping regimes

On higher timeframes, you can track zone continuity across candles to filter fakeouts

*/

   string trendstrM5 = "";
   string trendstrM15 = "";
   string trendstrH1 = "";
   string trendstrH4 = "";
   string trendstrD1 = "";   
   
   if(!IsNewBar()) return;
   ChartSaveTemplate(0,"! Fast Pair GOLD XAUUSD - Entry BOX SIGNAL");

   if(!TradingCurrency) CopyBuffer(KaisaraIndicatorHandleM5,0,0,1,UpBufferM5); CopyBuffer(KaisaraIndicatorHandleM5,1,0,1,DnBufferM5);
   CopyBuffer(KaisaraIndicatorHandleM15,0,0,1,UpBufferM15); CopyBuffer(KaisaraIndicatorHandleM15,1,0,1,DnBufferM15);
   CopyBuffer(KaisaraIndicatorHandleH1,0,0,1,UpBufferH1); CopyBuffer(KaisaraIndicatorHandleH1,1,0,1,DnBufferH1);
   CopyBuffer(KaisaraIndicatorHandleH4,0,0,1,UpBufferH4); CopyBuffer(KaisaraIndicatorHandleH4,1,0,1,DnBufferH4);
   if(TradingCurrency) CopyBuffer(KaisaraIndicatorHandleD1,0,0,1,UpBufferD1); CopyBuffer(KaisaraIndicatorHandleD1,1,0,1,DnBufferD1); 
   
   if(!TradingCurrency){
      if(UpBufferM5[0]>0) PrintDebug(DEBUG_INFO, "UpBuffer @ M5 value: " + DoubleToString(UpBufferM5[0]));  // Print("UpBuffer value: ", UpBuffer[0]);
      if(DnBufferM5[0]>0) PrintDebug(DEBUG_INFO, "DnBuffer @ M5 value: " + DoubleToString(DnBufferM5[0]));  //Print("UpBuffer value: ", DnBuffer[0]);
   }

   if(UpBufferM15[0]>0) PrintDebug(DEBUG_INFO, "UpBuffer @ M15 value: " + DoubleToString(UpBufferM15[0]));  // Print("UpBuffer value: ", UpBuffer[0]);
   if(DnBufferM15[0]>0) PrintDebug(DEBUG_INFO, "DnBuffer @ M15 value: " + DoubleToString(DnBufferM15[0]));  //Print("UpBuffer value: ", DnBuffer[0]);

   if(UpBufferH1[0]>0) PrintDebug(DEBUG_INFO, "UpBuffer @ H1 value: " + DoubleToString(UpBufferH1[0]));  // Print("UpBuffer value: ", UpBuffer[0]);
   if(DnBufferH1[0]>0) PrintDebug(DEBUG_INFO, "DnBuffer @ H1 value: " + DoubleToString(DnBufferH1[0]));  //Print("UpBuffer value: ", DnBuffer[0]);

   if(UpBufferH4[0]>0) PrintDebug(DEBUG_INFO, "UpBuffer @ H4 value: " + DoubleToString(UpBufferH4[0]));  // Print("UpBuffer value: ", UpBuffer[0]);
   if(DnBufferH4[0]>0) PrintDebug(DEBUG_INFO, "DnBuffer @ H4 value: " + DoubleToString(DnBufferH4[0]));  //Print("UpBuffer value: ", DnBuffer[0]);

   if(TradingCurrency){
      if(UpBufferD1[0]>0) PrintDebug(DEBUG_INFO, "UpBuffer @ D1 value: " + DoubleToString(UpBufferD1[0]));  // Print("UpBuffer value: ", UpBuffer[0]);
      if(DnBufferD1[0]>0) PrintDebug(DEBUG_INFO, "DnBuffer @ D1 value: " + DoubleToString(DnBufferD1[0]));  //Print("UpBuffer value: ", DnBuffer[0]);
   }
   
   if(!TradingCurrency) {
      if(UpBufferM5[0] > DnBufferM5[0]) {
         trendstrM5 = "UP";
      }
      else if(UpBufferM5[0] < DnBufferM5[0]) {
         trendstrM5 = "DOWN";
      }   
      PrintDebug(DEBUG_INFO, "Trend @ M5 is: " + trendstrM5);
   }
   
   if(UpBufferM15[0] > DnBufferM15[0]) {
      trendstrM15 = "UP";
   }
   else if(UpBufferM15[0] < DnBufferM15[0]) {
      trendstrM15 = "DOWN";
   }   
   PrintDebug(DEBUG_INFO, "Trend @ M15 is: " + trendstrM15);   
   
   if(UpBufferH1[0] > DnBufferH1[0]) {
      trendstrH1 = "UP";
   }
   else if(UpBufferH1[0] < DnBufferH1[0]) {
      trendstrH1 = "DOWN";
   }   
   PrintDebug(DEBUG_INFO, "Trend @ H1 is: " + trendstrH1);   
 
   if(UpBufferH4[0] > DnBufferH4[0]) {
      trendstrH4 = "UP";
   }
   else if(UpBufferH4[0] < DnBufferH4[0]) {
      trendstrH4 = "DOWN";
   }   
   PrintDebug(DEBUG_INFO, "Trend @ H4 is: " + trendstrH4);   
 
   if(TradingCurrency){   
      string trendstrD1 = "";
      if(UpBufferD1[0] > DnBufferD1[0]) {
         trendstrD1 = "UP";
      }
      else if(UpBufferD1[0] < DnBufferD1[0]) {
         trendstrD1 = "DOWN";
      }   
      PrintDebug(DEBUG_INFO, "Trend @ D1 is: " + trendstrD1);    
   }


   // TEMP: Test zone grouping directly ////////////////////////////////////////////////////////////////////////////////////////////
   AnalyzeRecentZones();


   // For this scalping strategy on Gold, we'll be using Trend @ H1 as Trend Bias. 
   if(trendstrH1 == "UP" && trendstrM5 == "UP")
   {
      AnalyzeRecentZones();
   
      if(ArraySize(RecentZones) > 0 && RecentZones[0].regime == "DOWN")
      {
         Print("📈 Long setup: Trend UP, last box was RED → Breakout potential");
         // You can go further and place Buy conditions here
      }
   }  
   //ObjectsDeleteAll(0,0);        
   //https://www.mql5.com/en/code/11922
   applytemplate();
}

/*
string GetBoxRegime(int handle, ENUM_TIMEFRAMES tf, datetime rectTime, double rectHigh, double rectLow)
{
   int shift = iBarShift(_Symbol, tf, rectTime, true);
   if(shift < 0) return "UNKNOWN";

   double bufUp[], bufDn[];
   if(CopyBuffer(handle, 0, shift, 1, bufUp) < 1 || 
      CopyBuffer(handle, 1, shift, 1, bufDn) < 1)
      return "UNKNOWN";

   // Box regime logic
   if(bufUp[0] == rectHigh)
      return "UP";   // Green zone
   else if(bufUp[0] == rectLow)
      return "DOWN"; // Red zone
   else
      return "UNKNOWN";
}
*/

//too many unknown
/*
string GetBoxRegime(int handle, ENUM_TIMEFRAMES tf, datetime tRef, double priceHigh, double priceLow)
{
   int idx = iBarShift(_Symbol, tf, tRef, true);
   if(idx < 0) return "UNKNOWN";

   double bufUp[], bufDn[];
   if(CopyBuffer(handle, 0, idx, 1, bufUp) < 1 ||
      CopyBuffer(handle, 1, idx, 1, bufDn) < 1)
      return "UNKNOWN";

   if(bufUp[0] == priceHigh)
      return "UP";
   if(bufUp[0] == priceLow)
      return "DOWN";

   return "UNKNOWN";
}
*/

string GetBoxRegime(int handle, ENUM_TIMEFRAMES tf, datetime tRef, double priceHigh, double priceLow)
{
   const int window = 3; // check ±5 candles
   int center = iBarShift(_Symbol, tf, tRef, true);
   if(center < 0) return "UNKNOWN";

   double bufUp[], bufDn[];

   for(int i = -window; i <= window; i++)
   {
      int idx = center + i;
      if(idx < 0) continue;

      if(CopyBuffer(handle, 0, idx, 1, bufUp) < 1 ||
         CopyBuffer(handle, 1, idx, 1, bufDn) < 1)
         continue;

      if(bufUp[0] == priceHigh)
         return "UP";
      if(bufUp[0] == priceLow)
         return "DOWN";
   }

   return "UNKNOWN";
}




// we’re not drawing anything in AnalyzeRecentZones() — it’s read-only by design.
void AnalyzeRecentZones()
{
   ArrayFree(RecentZones);  // Clear previous zones

   int total = ObjectsTotal(ChartID());
   const int MaxRects = 100;

   struct RectInfo { datetime t1, t2; double pHigh, pLow; };
   RectInfo rects[];
   int collected = 0;

   // 🔍 Step 1: Read rectangles without modifying them
   for(int i = total - 1; i >= 0 && collected < MaxRects; i--)
   {
      string name = ObjectName(ChartID(), i);
      if(StringFind(name, "obj_rect") != 0) continue; // Adjust prefix if needed

      datetime t1, t2;
      double p1, p2;

      if(ObjectGetInteger(0, name, OBJPROP_TIME, 0, t1) &&
         ObjectGetInteger(0, name, OBJPROP_TIME, 1, t2) &&
         ObjectGetDouble(0, name, OBJPROP_PRICE, 0, p1) &&
         ObjectGetDouble(0, name, OBJPROP_PRICE, 1, p2))
      {
         RectInfo r;
         r.t1 = MathMin(t1, t2);
         r.t2 = MathMax(t1, t2);
         r.pHigh = MathMax(p1, p2);
         r.pLow  = MathMin(p1, p2);

         ArrayResize(rects, collected + 1);
         rects[collected++] = r;

//         Print("🧲 Rect: ", name, " | ", TimeToString(r.t1), " → ", TimeToString(r.t2),
//               " | Price: ", DoubleToString(r.pHigh, _Digits), " → ", DoubleToString(r.pLow, _Digits));
      }
   }

   // 🧠 Step 2: Group by exact price range and overlapping time
   for(int i = 0; i < ArraySize(rects); i++)
   {
      bool merged = false;

      for(int j = 0; j < ArraySize(RecentZones); j++)
      {
         bool samePrice = rects[i].pHigh == RecentZones[j].price_high &&
                          rects[i].pLow == RecentZones[j].price_low;

         bool timeOverlap = (rects[i].t1 <= RecentZones[j].t_end &&
                             rects[i].t2 >= RecentZones[j].t_start);

         if(samePrice && timeOverlap)
         {
            RecentZones[j].t_start = MathMin(RecentZones[j].t_start, rects[i].t1);
            RecentZones[j].t_end   = MathMax(RecentZones[j].t_end, rects[i].t2);
            RecentZones[j].rects++;
            merged = true;
            break;
         }
      }

      if(!merged)
      {
         Zone z;
         z.t_start = rects[i].t1;
         z.t_end   = rects[i].t2;
         z.price_high = rects[i].pHigh;
         z.price_low  = rects[i].pLow;
         z.rects = 1;

         // 🟢🔴 Regime detection from your indicator buffers
         z.regime = GetBoxRegime(KaisaraIndicatorHandleM5, PERIOD_M5, z.t_start, z.price_high, z.price_low);

         ArrayResize(RecentZones, ArraySize(RecentZones) + 1);
         RecentZones[ArraySize(RecentZones) - 1] = z;

         Print("🧱 Zone: ", TimeToString(z.t_start), " → ", TimeToString(z.t_end),
               " | Price: ", DoubleToString(z.price_high, _Digits), " → ", DoubleToString(z.price_low, _Digits),
               " | Rects: ", z.rects, " | Regime: ", z.regime);
      }
   }

   Print("✅ Zone analysis complete. Zones found: ", ArraySize(RecentZones));
}





// Function to print debug messages based on the selected level
void PrintDebug(DebugLevel level, string message)
  {
   if(level <= debugLevelInput)
     {
      Print(message);
     }
  }

bool IsNewBar(){
   static datetime previousTime=0;
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   if(previousTime!=currentTime){
   
      //we got new bar
      previousTime=currentTime;   
      return true;
   }
   
   return false;   

}

void applytemplate()
  {
//--- example of applying template, located in \MQL5\Files
   if(FileIsExist("! Fast Pair GOLD XAUUSD - Entry BOX SIGNAL.tpl"))
     {
      Print("The file my_template.tpl found in \\Files'");
      //--- apply template
      if(ChartApplyTemplate(0,"\\Files\\! Fast Pair GOLD XAUUSD - Entry BOX SIGNAL.tpl"))
        {
         Print("The template 'my_template.tpl' applied successfully");
         //--- redraw chart
         ChartRedraw();
        }
      else
         Print("Failed to apply 'my_template.tpl', error code ",GetLastError());
     }
   else
     {
      Print("File 'my_template.tpl' not found in "
            +TerminalInfoString(TERMINAL_PATH)+"\\MQL5\\Files");
     }
  }