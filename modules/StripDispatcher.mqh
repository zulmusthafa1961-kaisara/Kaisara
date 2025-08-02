#ifndef __STRIPBUILDER_MQH__
#define __STRIPBUILDER_MQH__

//#include "StripBuilder.mqh"
#include "MapStringToPtr.mqh" // 🔁 Pull in explicitly to ensure type recognition
#include "UnifiedRegimeModulesmqh.mqh"

class CStripBuilder;  // forward declaration

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

    void RenderAll(CArrayObj &arr, bool rightAligned = false)
    {
    for (int i = 0; i < arr.Total(); i++)
    {
        ((CStripVisual*) arr.At(i)).RenderToChart(rightAligned);
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

void CStripDispatcher::Dispatch(CArrayObj *zones, RegimeType regime) {
   // TODO: Implement how zones get processed — this is a placeholder
   PrintFormat("Dispatching %d zones for regime: %s", zones.Total(), EnumToString(regime));
}
