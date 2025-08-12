#ifndef __CREGIMESLICE_MQH__
#define __CREGIMESLICE_MQH__

#include "UnifiedRegimeModulesmqh.mqh"


class CRegimeSlice : public CObject
{
public:
   datetime start;
   datetime end;
   string regime;       // Enum: Bullish, Bearish, Neutral, etc.
   string fingerprint;      // Unique ID or hash
   string label;            // Optional: for diagnostics

   private:
   CArrayObj m_zones;  // or whatever your zone container is

public:
   CArrayObj *GetZones() { return &m_zones; }

   CRegimeSlice() {}

   static CRegimeSlice *FuseSlices(CArrayObj *slices);

   CRegimeSlice(datetime _start, datetime _end, RegimeType _regime, string _fingerprint)
   {
      start = _start;
      end = _end;
      regime = RegimeToString(_regime);
      fingerprint = _fingerprint;
   }

   string GetLabel() const
   {
      return label;
   }

   void SetLabel(string _label)
   {
      label = _label;
   }

   bool Contains(datetime ts) const
   {
      return (ts >= start && ts <= end);
   }

   static string EnumToString(RegimeType r)
   {
      switch(r)
      {
         case REGIME_BUY: return "Bullish";
         case REGIME_SELL: return "Bearish";
         case REGIME_NEUTRAL: return "Neutral";
         default:            return "Unknown";
      }
   }
};
#endif

CRegimeSlice *CRegimeSlice::FuseSlices(CArrayObj *slices) {
   if (slices == NULL || slices.Total() == 0) return NULL;

   datetime minStart = LONG_MAX;
   datetime maxEnd   = 0;
   string combinedFingerprint = "";
   string dominantRegime = "";

   string regimes[];
   int counts[];

   for (int i = 0; i < slices.Total(); i++) {
      CRegimeSlice *slice = (CRegimeSlice *)slices.At(i);
      if (slice == NULL) continue;

      if (slice.start < minStart) minStart = slice.start;
      if (slice.end   > maxEnd)   maxEnd   = slice.end;

      combinedFingerprint += slice.fingerprint + "|";

      // Manual regime counting
      //int index = ArrayFind(regimes, slice.regime);
      int index = -1;
      for (int j = 0; j < ArraySize(regimes); j++) {
      if (regimes[j] == slice.regime) {
         index = j;
         break;
        }
      }

      if (index == -1) {
         ArrayResize(regimes, ArraySize(regimes) + 1);
         ArrayResize(counts, ArraySize(counts));
         regimes[ArraySize(regimes) - 1] = slice.regime;
         counts[ArraySize(counts) - 1] = 1;
      } else {
         counts[index]++;
      }
   }

   // Find dominant regime
   int maxCount = 0;
   for (int i = 0; i < ArraySize(regimes); i++) {
      if (counts[i] > maxCount) {
         maxCount = counts[i];
         dominantRegime = regimes[i];
      }
   }

   // Create fused slice
   CRegimeSlice *fused = new CRegimeSlice;
   fused.start = minStart;
   fused.end   = maxEnd;
   fused.fingerprint = combinedFingerprint;
   fused.regime = dominantRegime;

   return fused;
}

