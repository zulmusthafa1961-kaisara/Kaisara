//+------------------------------------------------------------------+
//|                                             testFileResource.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property strict
//#resource "\\Files\\MergedZones.txt" as uchar MergedZones[]
#resource "\\Files\\MergedH1Zones.csv" as uchar MergedZones[]   //This embeds the file as a byte array named MergedZones[].

void OnTick() {
   string embeddedText = "";

   if (ArraySize(MergedZones) > 0) {
      uchar buffer[];
      ArrayCopy(buffer, MergedZones);
      embeddedText = CharArrayToString(buffer);
      Print("📦 Embedded TXT content:\n", embeddedText);
   } else {
      Print("❌ EmbeddedZones.txt resource is empty or missing.");
   }

}






/*

//+------------------------------------------------------------------+
//|                                             testFileResource.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
//int handle = FileOpen("sandbox_test.txt", FILE_READ | FILE_TXT | FILE_ANSI);
int handle = FileOpen("MergedZones.txt", FILE_READ | FILE_CSV | FILE_ANSI);
if (handle != INVALID_HANDLE) {
   string line = FileReadString(handle);
   Print("✅ File content: ", line);
   FileClose(handle);
} else {
   Print("❌ Unable to open sandbox_test.txt");
}

   
  }
//+------------------------------------------------------------------+
*/