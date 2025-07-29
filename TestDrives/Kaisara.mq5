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
  
input bool        TradingCurrency = false;
input int         NoOfBars = 300;
int KaisaraIndicatorHandleM5, KaisaraIndicatorHandleM15, KaisaraIndicatorHandleH1, KaisaraIndicatorHandleH4, KaisaraIndicatorHandleD1;

double UpBufferM5[],UpBufferM15[],UpBufferH1[],UpBufferH4[],UpBufferD1[];
double DnBufferM5[],DnBufferM15[],DnBufferH1[],DnBufferH4[],DnBufferD1[];

int OnInit() {
   KaisaraIndicatorHandleM5 = iCustom(_Symbol,PERIOD_M5,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
   KaisaraIndicatorHandleM15 = iCustom(_Symbol,PERIOD_M15,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
   KaisaraIndicatorHandleH1 = iCustom(_Symbol,PERIOD_H1,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
   KaisaraIndicatorHandleH4 = iCustom(_Symbol,PERIOD_H4,"::ProfitFX-TrendBoxSignal-Gold.ex5",NoOfBars);
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
   IndicatorRelease(KaisaraIndicatorHandleM15);
   IndicatorRelease(KaisaraIndicatorHandleH1);
   IndicatorRelease(KaisaraIndicatorHandleH4);
   if(TradingCurrency) IndicatorRelease(KaisaraIndicatorHandleD1);            
}

void OnTick() {
   if(!IsNewBar()) return;

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
      string trendstrM5 = "";
      if(UpBufferM5[0] > DnBufferM5[0]) {
         trendstrM5 = "UP";
      }
      else if(UpBufferM5[0] < DnBufferM5[0]) {
         trendstrM5 = "DOWN";
      }   
      PrintDebug(DEBUG_INFO, "Trend @ M5 is: " + trendstrM5);
   }
   
   string trendstrM15 = "";
   if(UpBufferM15[0] > DnBufferM15[0]) {
      trendstrM15 = "UP";
   }
   else if(UpBufferM15[0] < DnBufferM15[0]) {
      trendstrM15 = "DOWN";
   }   
   PrintDebug(DEBUG_INFO, "Trend @ M15 is: " + trendstrM15);   
   
   string trendstrH1 = "";
   if(UpBufferH1[0] > DnBufferH1[0]) {
      trendstrH1 = "UP";
   }
   else if(UpBufferH1[0] < DnBufferH1[0]) {
      trendstrH1 = "DOWN";
   }   
   PrintDebug(DEBUG_INFO, "Trend @ H1 is: " + trendstrH1);   
 
   string trendstrH4 = "";
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