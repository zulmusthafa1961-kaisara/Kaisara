//+------------------------------------------------------------------+
//|                                                  RegimeTypes.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#ifndef __REGIME_TYPES__
#define __REGIME_TYPES__

enum RegimeType
{
   REGIME_NONE = -1, // sentinel
   REGIME_BUY,
   REGIME_SELL,
   REGIME_NEUTRAL,
   REGIME_UNKNOWN
};



RegimeType ParseRegimeType(string name) {
   name = TrimString(name);
   StringToLower(name);  // modifies 'name' directly

   if (name == "buy")      return REGIME_BUY;
   if (name == "sell")     return REGIME_SELL;
   if (name == "neutral")  return REGIME_NEUTRAL;
   if (name == "none")     return REGIME_NONE;

   Print("⚠️ Unknown regime type in CSV: ", name);
   return REGIME_UNKNOWN;
}

/*
RegimeType MapRegimeType(string s) {
    //s = TrimString(s); // Remove leading/trailing spaces
    //s = StringTrimLeft(StringTrimRight(s)); // Remove leading/trailing spaces
    StringTrimLeft(s);  // Trims in place
    StringTrimRight(s); // Trims in place    
    if(s == "REGIME_BUY") return REGIME_BUY;
    if(s == "REGIME_SELL") return REGIME_SELL;
    if(s == "REGIME_NEUTRAL") return REGIME_NEUTRAL;
    if(s == "REGIME_UNKNOWN") return REGIME_UNKNOWN;
    return REGIME_NONE;
}
*/

RegimeType MapRegimeType(string s) {
    StringTrimLeft(s);  // Trims leading spaces in place
    StringTrimRight(s); // Trims trailing spaces in place
    if(s == "REGIME_BUY") return REGIME_BUY;
    if(s == "REGIME_SELL") return REGIME_SELL;
    if(s == "REGIME_NEUTRAL") return REGIME_NEUTRAL;
    if(s == "REGIME_UNKNOWN") return REGIME_UNKNOWN;
    return REGIME_NONE;
}



// Your enum
enum PhaseType {
   PHASE_TYPE_M5,
   PHASE_TYPE_H1
};


#endif

// Place this outside any class
string TrimString(string inputStr) {
   int start = 0;
   int end = StringLen(inputStr) - 1;

   while (start <= end && StringGetCharacter(inputStr, start) <= ' ')
      start++;

   while (end >= start && StringGetCharacter(inputStr, end) <= ' ')
      end--;

   return StringSubstr(inputStr, start, end - start + 1);
}

