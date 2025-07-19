//+------------------------------------------------------------------+
//|                                            enumOperationMode.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#ifndef __ENUMOPERATIONMODE__
#define __ENUMOPERATIONMODE__

enum ENUM_ENV_OPERATION_MODE {
   ENUM_LIVE_ENV,
   ENUM_TEST_ENV_NORMAL,
   ENUM_TEST_ENV_PRELOAD_H1   
   // for preloading H1 regime, use dedicated test drive for preloading H1 data into csv. 
   // specify no of bars enough for testing 
   // note 50k is good for 2019-2025 for 6 years. set it manually ?                                   
};

#endif

