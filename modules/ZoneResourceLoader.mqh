//+------------------------------------------------------------------+
//| ZoneResourceLoader.mqh — loads CSV zones from embedded resource |
//+------------------------------------------------------------------+
#ifndef ZONE_RESOURCE_LOADER_MQH
#define  ZONE_RESOURCE_LOADER_MQH

#resource "\\Files\\mergedzones_H1_2025.07.25_10-01.csv" as uchar MergedZones[]   //This embeds the file as a byte array named MergedH1Zones[].

#include <Arrays//ArrayObj.mqh>
#include "UnifiedRegimeModulesmqh.mqh"


   CArrayObj* _LoadZonesFromResourceCSV() {
            string embeddedText = "";
         
            if (ArraySize(MergedZones) > 0) {
               uchar buffer[];
               ArrayCopy(buffer, MergedZones);
               embeddedText = CharArrayToString(buffer);
               Print("📦 Embedded TXT content:\n", embeddedText);
            } else {
               Print("❌ EmbeddedZones.txt resource is empty or missing.");
            }
         
         ////////////////////////////////////////////////////////////////// from zoneloader.mqh
            
            string Lines[]; //hold csv contents from embeddedText;
            //int linesCount = StringSplit(embeddedText,',',Lines);
            int linesCount = StringSplit(embeddedText, '\n', Lines); // <-- Use '\n' instead of ','
            
            CArrayObj* arrObjZones; 
            arrObjZones = new CArrayObj; 
               string parts[];
               ushort delimiter = ',';
                
               for(int i=1;i<linesCount;i++)   //i=1 skips the header 
                 {
                  string line = Lines[i];
                  if(StringLen(line)==0) continue;
                  
                  //split each line into different partsint PartCount = StringSplit(line, delimiter, parts);
                  int PartCount = StringSplit(line, delimiter, parts);
                  if(PartCount < 8) {
                     PrintFormat("Skipping invalid line# %d in csv file: %s",i+1,Lines[i]);     
                     continue; // <-- Add this line to skip invalid lines!
                  }
                          
                  datetime t_start = StringToTime(parts[1]);                           
                  datetime t_end   = StringToTime(parts[2]);
                  double price_low = StringToDouble(parts[3]);
                  double price_high= StringToDouble(parts[4]);
                  int rect_count   = (int)StringToInteger(parts[5]);
                  string regime_tag = parts[6];                         // Green/Red
                  string regime_type_s = parts[7];                      // REGIME_BUY/REGIME_SELL
                     
/*                            
                  PrintFormat("_Load: index=%d, start time = %s | row#%d→starttime:%s->endtime:%s->price %.2f–%.2f|Regime:%s|Tag:%s",
                              i,
                              TimeToString(t_start, TIME_DATE | TIME_MINUTES),
                              i,
                              TimeToString(t_start, TIME_DATE | TIME_MINUTES),
                              TimeToString(t_end, TIME_DATE | TIME_MINUTES),
                              price_low,
                              price_high,
                              regime_tag,            //Green/Red
                              regime_type_s);        //REGIME_BUY/REGIME_SELL
         
                  CZoneCSV *zone = new CZoneCSV;
                  zone.t_start = t_start;
                  zone.t_end   = t_end;
                  zone.price_low = price_low;
                  zone.price_high = price_high;
                  zone.SetRectCount(rect_count);
                                                       
                  color regimeColor = GetRegimeColor(zone.GetRegimeType());
*/                  
                  //PrintFormat("DEBUG: Creating zone with tag='%s', type='%s'", regime_tag, regime_type_s);    
                  arrObjZones.Add(CreateMergedZone(t_start, t_end, price_low, price_high, rect_count, regime_tag, regime_type_s)) ;        

         }
         return arrObjZones;
         
}


#endif