// AnotherTestDriveEA using CEDriver.mqh
/*
#include "\modules\CEADriver.mqh"
CEADriver driver;

int OnInit()
{
   Print("✅ EA initialized");
   return INIT_SUCCEEDED;
}

void OnTick() {}
*/

/*
#include "modules\ZoneAnalyzer.mqh"
#include "modules\CEADriver.mqh"

CEADriver driver;

int OnInit()
{
   driver.Init();
   driver.ExportCSV();
   return INIT_SUCCEEDED;
}

void OnTick() {}
*/

// 🔧 Minimal EA that includes your driver and forces recognition
#property strict

#include "modules\ZoneAnalyzer.mqh"
#include "modules\CEADriver.mqh"

CEADriver driver;

int OnInit()
{
   Print("✅ EA initialized");
  // driver.Init();
  // driver.ExportCSV();
   return INIT_SUCCEEDED;
}

void OnTick() {}
