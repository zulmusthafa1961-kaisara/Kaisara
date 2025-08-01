#ifndef __ZONELOADER_MQH__
#define __ZONELOADER_MQH__

#include <Arrays/ArrayObj.mqh>
#include "UnifiedRegimeModulesmqh.mqh"   // includes  CStationaryRectangles4Box

class CZoneCSV : public CRectInfo {

private:
   int rect_count;
      RegimeType local_regime_type;
public:
   void SetRegimeType(RegimeType value) { local_regime_type = value; }  // { regime_type = value; }
   virtual string ClassName() const { return "CZoneCSV"; }
   bool isFromCSV;
   void SetRectCount(int value) { rect_count = value; }
   CZoneCSV() { isFromCSV = true; }
   int GetRectCount() const {return rect_count;}

   
   //RegimeType GetRegimeType() const { return local_regime_type; }
   RegimeType GetRegimeType() {
      return local_regime_type;
   }

   CZoneCSV *GetZoneCSV(CArrayObj *zones, int i) {
      CObject *obj = zones.At(i);
      if (obj == NULL || obj.ClassName() != "CZoneCSV") return NULL;
      return (CZoneCSV *)obj;
   }


string GetRegimeTypeName() {
   switch (regime_type) {
      case REGIME_BUY:      return "Buy";
      case REGIME_SELL:     return "Sell";
      case REGIME_NEUTRAL:  return "Neutral";
      case REGIME_UNKNOWN:  return "Unknown";
      case REGIME_NONE:     return "None";
      default:              return "Invalid";
   }
}



   
   void DrawStrip(datetime currentTime) {
      if (t_start > currentTime || t_end < currentTime) return;
   
      // Compose a unique name for the strip
      string stripName = "ZoneStrip_" + TimeToString(t_start) + "_" + regime_tag;
   
      color regimeColor = GetRegimeColor(local_regime_type);

   }
};



CArrayObj *LoadZonesFromMergedCSV(string fileName) {
   CArrayObj *_regimeZones = new CArrayObj;


   int handle = FileOpen(fileName, FILE_CSV | FILE_READ | FILE_ANSI);
   if (handle == INVALID_HANDLE) return NULL;

   FileReadString(handle); // skip header

   while (!FileIsEnding(handle)) {
      string line = FileReadString(handle);
      string parts[];
      ushort delimiter = ',';
      StringSplit(line, delimiter, parts);

      datetime t_start = StringToTime(parts[1]);
      datetime t_end   = StringToTime(parts[2]);
      double price_low = StringToDouble(parts[3]);
      double price_high= StringToDouble(parts[4]);
      int rect_count   = (int)StringToInteger(parts[5]);
      string regime_tag = parts[6];
      string regime_type_s = parts[7];

      CZoneCSV *zone = new CZoneCSV;
      zone.t_start = t_start;
      zone.t_end   = t_end;
      zone.price_low = price_low;
      zone.price_high = price_high;
      zone.SetRectCount(rect_count);
      

      RegimeType rtype = MapRegimeType(regime_type_s);
      zone.SetRegimeType(rtype);  // This is valid outside the class

      //RegimeType rtype = (regime_type_s == "REGIME_BUY") ? REGIME_BUY :
      //             (regime_type_s == "REGIME_SELL") ? REGIME_SELL : REGIME_UNKNOWN;
      //zone.SetRegimeType(rtype);
                
                         
                         
      color regimeColor = GetRegimeColor(zone.GetRegimeType());
                   

      _regimeZones.Add(zone);
   }

   FileClose(handle);
   return _regimeZones;
}

inline CZoneCSV *CreateMergedZone(datetime t_start, datetime t_end,
                                  double price_low, double price_high,
                                  int rect_count, string regime_tag, string regime_type_s) {
   CZoneCSV *zone = new CZoneCSV();
   if (zone == NULL) return NULL;

   zone.t_start = t_start;
   zone.t_end = t_end;
   zone.price_low = price_low;
   zone.price_high = price_high;
   zone.SetRectCount(rect_count);  
   zone.regime_tag = regime_tag;
   
   RegimeType rtype = MapRegimeType(regime_type_s);
   zone.SetRegimeType(rtype);   // ADD THIS TO RESOLVE INCORRECT ACCESS OF REGIME TYPE.     
   
   //PrintFormat("DEBUG: Within CreateMergedZone zone with tag='%s', regime-str type='%s', regime-enum type= %s", regime_tag, regime_type_s, EnumToString(zone.GetRegimeType()));

   return zone;
}

#endif 


/*
color GetRegimeColor(int type) {
   switch (type) {
      case REGIME_BUY: return clrGreen;
      case REGIME_SELL: return clrRed;
      default: return clrGray;
   }
}
*/

color GetRegimeColor(RegimeType type) {
   switch (type) {
      case REGIME_BUY: return clrGreen;
      case REGIME_SELL: return clrRed;
      default: return clrGray;
   }
}


/*
RegimeType MapRegimeType(string regime_type_s) {
   if (regime_type_s == "REGIME_BUY") return REGIME_BUY;
   if (regime_type_s == "REGIME_SELL") return REGIME_SELL;
   return REGIME_UNKNOWN;
}
*/