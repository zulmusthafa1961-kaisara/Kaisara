#ifndef __STRIPDISPATCHER_MQH__
#define __STRIPDISPATCHER_MQH__

//#include "StripBuilder.mqh"
#include "MapStringToPtr.mqh" // 🔁 Pull in explicitly to ensure type recognition
#include "UnifiedRegimeModulesmqh.mqh"

class CStripBuilder;  // forward declaration

//utility function
color MapRegimeColor(RegimeType regime)
{
   switch(regime)
   {
      case REGIME_BUY:    return clrLime;
      case REGIME_SELL:    return clrRed;
      case REGIME_NEUTRAL: return clrGray;
      default:             return clrWhite;
   }
}

string MapRegimeLabel(RegimeType regime)
{
   switch(regime)
   {
      case REGIME_BUY:     return "BUY";
      case REGIME_SELL:    return "SELL";
      case REGIME_NEUTRAL: return "NEUTRAL";
      default:             return "UNKNOWN";
   }
}


class CStripDispatcher
{
private:
    CMapStringToPtr builderMap;
    string keys[];

public:
   void Dispatch(CArrayObj *zones, RegimeType regime);      

public:
    void RegisterBuilder(const string &key, CStripBuilder *builder)
    {
        builderMap.Add(key, builder);
        int n = ArraySize(keys);
        ArrayResize(keys, n + 1);
        keys[n] = key;
    }

    CStripBuilder *GetBuilderByKey(const string &key)
    {
        return (CStripBuilder *)builderMap.Get(key);
    }

    /*
    void RenderAll(CArrayObj &arr, bool rightAligned = false)
    {
    for (int i = 0; i < arr.Total(); i++)
    {
        ((CStripVisual*) arr.At(i)).RenderToChart(i, zone.GetColor(), zone.GetLabel());

    }
    }
    */

    // stateless 
    void RenderAll(CArrayObj &arr, bool rightAligned = false)
{
   for (int i = 0; i < arr.Total(); i++)
   {
      CZoneInfo *zone = (CZoneInfo *)arr.At(i);
      if (zone == NULL) continue;

      datetime t_start = zone.t_start;
      datetime t_end   = zone.t_end;
      int durationMin  = (int)((t_end - t_start) / 60);

      RegimeType regime = zone.GetRegimeType();  // ✅ Replace with actual accessor
      string regimeLabel = EnumToString(regime); // ✅ Built-in enum-to-string
      color regimeColor  = MapRegimeColor(regime); // ✅ You still need to define this

    //  string label = StringFormat("%s-%s (%dm)", zone.timeframePrefix, regimeLabel, durationMin);
      string label = StringFormat("%s-%s (%dm)", zone.GetPrefix(), regimeLabel, durationMin);


      CStripVisual visual(zone.GetPrefix(), rightAligned ? 1 : 0);
      visual.RenderToChart(i, regimeColor, label, t_start, t_end);
   }
}



    void DispatchZones(CArrayObj &zones)
    {
        for(int i = 0; i < zones.Total(); i++)
        {
            CZoneInfo *zone = (CZoneInfo *)zones.At(i);
            if(zone == NULL) continue;

            string prefix = zone.Prefix(); // Ensure this method exists

            for(int j = 0; j < ArraySize(keys); j++)
            {
                string key = keys[j];
                if(StringFind(prefix, key) >= 0)
                {
                    CStripBuilder *builder = GetBuilderByKey(key);
                    if(builder != NULL)
                        builder.AddZone(zone);  // Must exist in CStripBuilder
                    break;
                }
            }
        }

        for(int j = 0; j < ArraySize(keys); j++)
        {
            CStripBuilder *builder = GetBuilderByKey(keys[j]);
            if(builder != NULL)
                builder.Refresh();  // Must exist in CStripBuilder
        }
    }
};

#endif
/*
void CStripDispatcher::Dispatch(CArrayObj *zones, RegimeType regime) {
   // TODO: Implement how zones get processed — this is a placeholder
   PrintFormat("Dispatching %d zones for regime: %s", zones.Total(), EnumToString(regime));
}
*/
void CStripDispatcher::Dispatch(CArrayObj *zones, RegimeType regime) {
   PrintFormat("Dispatching %d zones for regime: %s", zones.Total(), EnumToString(regime));

   for (int i = 0; i < zones.Total(); i++) {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;


      zone.SetRenderIndex(i);
      zone.SetRenderLabel("Regime");

      // Log for debugging
      PrintFormat("Zone #%d | %s [%s] | t_start=%s | t_end=%s | Price Range=%.2f - %.2f",
                  i + 1,
                  zone.regime_tag,
                  zone.GetRegimeTypeName(),
                  TimeToString(zone.t_start),
                  TimeToString(zone.t_end),
                  zone.price_low,
                  zone.price_high);

   }
}
