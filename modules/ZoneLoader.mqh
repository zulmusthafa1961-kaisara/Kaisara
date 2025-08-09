#ifndef __ZONELOADER_MQH__
#define __ZONELOADER_MQH__

#include <Arrays/ArrayObj.mqh>
#include "UnifiedRegimeModulesmqh.mqh"   // includes  CStationaryRectangles4Box

class CZoneCSV : public CRectInfo {

private:
   int rect_count;
   RegimeType local_regime_type;
   int renderIndex;
   string renderLabel;

//copied from CZoneAnalyzer
private:
   //CArrayObj rects;
   //CArrayObj zones;
   CArrayObj mergedZones;  
   string prefix;
   string typeId; 

   static int nextId;
   int instanceId;   

   public:   
   //double price_top, price_bottom;
   //double price_high, price_low;

public:
   //using CRectInfo::Assign;  // ✅ Unhide base method

public:
   //datetime t_start;
   //datetime t_end;
   int regime;
   int zoneID;
   int csv_index;  // Original index from CSV
   // Add other relevant fields...

   virtual string ToString() const override
{
   return "Zone[" + IntegerToString(regime) + "] " +
          DoubleToString(price_low, 5) + " → " +
          DoubleToString(price_high, 5) + " @ " +
          TimeToString(t_start) + " → " +
          TimeToString(t_end);
} 

/*)
   virtual CZoneCSV *Clone() override
     {
      CZoneCSV *copy = new CZoneCSV;
      copy.Assign(this);  // ✅ 'this' is a pointer
      return copy;
     }
*/
   void Assign(CZoneCSV *other)
   {
      if (other == NULL) return;

      this.t_start = other.t_start;
      this.t_end   = other.t_end;
      this.regime  = other.regime;
      this.zoneID  = other.zoneID;

      // Copy other fields as needed
   }   

public:
   string Fingerprint()
   {
      return prefix + "|" +
             typeId + "|" +
             IntegerToString(rect_count) + "|" +
             EnumToString(local_regime_type) + "|" +
             IntegerToString(renderIndex) + "|" +
             renderLabel;
   }

string GetType() { return typeId; }

public:   
   CArrayObj *GetMergedZones() {
      return &this.mergedZones;
   }   

public:
   void SetRenderIndex(int index) {
      renderIndex = index;
   }
   int GetRenderIndex() const {
      return renderIndex;
   }

   void SetRenderLabel(string label) {
      renderLabel = label;
   }
   string GetRenderLabel() const {
      return renderLabel;
   }

   void SetRegime(RegimeType r) {
      local_regime_type = r;
   }
   RegimeType GetRegime() const {
      return local_regime_type;
   }   

public:   
void Regime(RegimeType r) {
   local_regime_type = r;
}

public:
   CZoneCSV() { 
      instanceId = nextId++;
      isFromCSV = true; 
      typeId = "CSV";
   }

   // Override ClassName for type identification

public:
   void SetRegimeType(RegimeType value) { local_regime_type = value; }  // { regime_type = value; }
   virtual string ClassName() const { return "CZoneCSV"; }   
   bool isFromCSV;
   void SetRectCount(int value) { rect_count = value; }

   int GetRectCount() const {return rect_count;}

   
   //RegimeType GetRegimeType() const { return local_regime_type; }
   RegimeType GetRegimeType() const{
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

/*  
   void DrawStrip(datetime currentTime) {
      if (t_start > currentTime || t_end < currentTime) return;
   
      // Compose a unique name for the strip
      string stripName = "ZoneStrip_" + TimeToString(t_start) + "_" + regime_tag;
   
      color regimeColor = GetRegimeColor(local_regime_type);

   }
*/
void DrawStrip(datetime currentTime) {
   if (this.t_start > currentTime || this.t_end < currentTime)
      return;

   string regimeTag = EnumToString(this.local_regime_type);  // Assuming you want regime name
   string stripName = "ZoneStrip_" + TimeToString(this.t_start) + "_" + regimeTag;

   color regimeColor = GetRegimeColor(this.local_regime_type);

   // You can now use stripName and regimeColor to draw your strip
}

};
int CZoneCSV::nextId = 0;


inline CZoneCSV *CreateMergedZone(datetime start, datetime end,
                                  double price_low, double price_high,
                                  int rect_count, string regime_tag, string regime_type_s) {
   CZoneCSV *zone = new CZoneCSV();
   if (zone == NULL) return NULL;

   zone.t_start = start;
   zone.t_end = end;
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


CArrayObj *LoadZonesFromEmbeddedCSV() {
   CArrayObj *_regimeZones = new CArrayObj;

   string embeddedText = "";
   if (ArraySize(MergedZones) > 0) {
      uchar buffer[];
      ArrayCopy(buffer, MergedZones);
      embeddedText = CharArrayToString(buffer);
   } else {
      Print("❌ Embedded resource is empty.");
      return NULL;
   }

   string Lines[];
   int lineCount = StringSplit(embeddedText, '\n', Lines);
   for (int i = 1; i < lineCount; i++) {
      string line = Lines[i];
      if (StringLen(line) == 0) continue;

      string parts[];
      if (StringSplit(line, ',', parts) < 8) continue;

      datetime t_start = StringToTime(parts[1]);
      datetime t_end   = StringToTime(parts[2]);
      datetime startTime = StringToTime(parts[1]);
      datetime endTime   = StringToTime(parts[2]);


      double price_low = StringToDouble(parts[3]);
      double price_high= StringToDouble(parts[4]);
      int rect_count   = (int)StringToInteger(parts[5]);
      string regime_tag = parts[6];
      string regime_type_s = parts[7];

      CZoneCSV *zone = CreateMergedZone(t_start, t_end, price_low, price_high,
                                        rect_count, regime_tag, regime_type_s);
      if (zone != NULL) _regimeZones.Add(zone);
   }
   return _regimeZones;
}


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