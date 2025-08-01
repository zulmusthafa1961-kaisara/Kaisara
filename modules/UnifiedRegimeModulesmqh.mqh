//+------------------------------------------------------------------+
//| UnifiedRegimeModules.mqh - Master Include                        |
//| Bundles all modules used by Regime Dashboard EA                  |
//+------------------------------------------------------------------+

#ifndef __UNIFIED_REGIME_MODULES__
#define __UNIFIED_REGIME_MODULES__

class CStationaryRectangles4Box;

// Order matters! ✅ Lower-level types first
#include "enumOperationMode.mqh"
//ENUM_ENV_OPERATION_MODE g_enumOpMode;
input ENUM_ENV_OPERATION_MODE OperationMode = ENUM_LIVE_ENV;


#include "RegimeTypes.mqh"
PhaseType g_activePhase; // current EA phase (setup, scan, trade)
#include "FreshZoneAnalyzer.mqh"
//#include "ZoneType.mqh"   // included in ZoneAnalyzer.mqh
//#include "ZoneInfo.mqh"   // included in ZoneAnalyzer.mqh
#include "RegimeDisplayRenderer.mqh"
#include "StationaryRectangles4Box.mqh"
#include "RegimeDashboardBuilder.mqh"
#include "RegimeUtils.mqh"
#include "ZoneResourceLoader.mqh"
#include "ZoneLoader.mqh"
#include "RegimeVisualizer.mqh"

//#include "modules\FreshZoneAnalyzer.mqh"
//#include "modules\RegimeUtils.mqh"
//#include "modules\ZoneLoader.mqh"



#endif


