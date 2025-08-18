#ifndef __CREGIME_PHASE_DETECTOR_MQH__
#define __CREGIME_PHASE_DETECTOR_MQH__

enum RegimePhase {
   PHASE_NONE,
   PHASE_BREAKOUT,
   PHASE_CHOPPY,
   PHASE_PULLBACK,
   PHASE_CONTINUATION
};

#include "UnifiedRegimeModulesmqh.mqh"

class CRegimePhaseDetector {
private:
   string h1Bias; // "BULLISH", "BEARISH", "NEUTRAL"
   int m5AlignedCount;
   int m5CounterCount;
   bool isBreakout;
   bool isChoppy;

public:
   //RegimePhase Detect(CArrayObj *h1Zones, CArrayObj *m5Zones);
   string Bias() const { return h1Bias; }
   int AlignedCount() const { return m5AlignedCount; }
   int CounterCount() const { return m5CounterCount; }
   bool IsBreakout() const { return isBreakout; }
   bool IsChoppy() const { return isChoppy; }

public:
   CRegimePhaseDetector() {
      h1Bias = "NEUTRAL";
      m5AlignedCount = 0;
      m5CounterCount = 0;
   }

   void Analyze(CArrayObj *h1Zones, CArrayObj *m5Zones) {
      Print(__FUNCTION__ + " Analyze() in process ...");
      h1Bias = "NEUTRAL";
      m5AlignedCount = 0;
      m5CounterCount = 0;

      if(h1Zones == NULL || h1Zones.Total() < 2) return;
      //if(m5Zones == NULL || m5Zones.Total() < 4) return;

 if(m5Zones == NULL) {
   Print("⚠️ M5validZones is NULL");
   return;
}

if(CheckPointer(m5Zones) != POINTER_DYNAMIC) {
   Print("❌ M5validZones is not a valid dynamic pointer");
   return;
}

if(m5Zones.Total() < 4) {
   Print("⚠️ M5validZones has insufficient zones: ", m5Zones.Total());
}
     

      // Step 1: Determine H1 bias
      int h1Buy = 0, h1Sell = 0;
      for(int i = h1Zones.Total() - 2; i < h1Zones.Total(); i++) {
         CZoneCSV *z = (CZoneCSV *)h1Zones.At(i);
         if(z == NULL) continue;
         if(z.GetRegime() == REGIME_BUY) h1Buy++;
         else if(z.GetRegime() == REGIME_SELL) h1Sell++;
      }

      if(h1Buy >= 2) h1Bias = "BULLISH";
      else if(h1Sell >= 2) h1Bias = "BEARISH";

      // Step 2: Count M5 alignment vs opposition
      for(int i = m5Zones.Total() - 4; i < m5Zones.Total(); i++) {
         CZoneCSV *z = (CZoneCSV *)m5Zones.At(i);
         if(z == NULL) continue;

         if(h1Bias == "BULLISH") {
            if(z.GetRegime() == REGIME_BUY) m5AlignedCount++;
            else if(z.GetRegime() == REGIME_SELL) m5CounterCount++;
         }
         else if(h1Bias == "BEARISH") {
            if(z.GetRegime() == REGIME_SELL) m5AlignedCount++;
            else if(z.GetRegime() == REGIME_BUY) m5CounterCount++;
         }
      }

      // Step 3: Log for validation
      Print("📊 RegimePhaseDetector:");
      Print("   H1 Bias = ", h1Bias);
      Print("   M5 Aligned = ", m5AlignedCount);
      Print("   M5 Counter = ", m5CounterCount);
   }

   RegimePhase Detect(CArrayObj *h1Zones, CArrayObj *m5Zones) {
   Analyze(h1Zones, m5Zones);

   if(h1Bias == "NEUTRAL") return PHASE_CHOPPY;

   if(m5AlignedCount == 4) return PHASE_CONTINUATION;
   if(m5AlignedCount >= 2 && m5CounterCount >= 2) return PHASE_CHOPPY;
   if(m5CounterCount == 4) return PHASE_PULLBACK;

   if(m5AlignedCount >= 3 && m5CounterCount == 0) return PHASE_BREAKOUT;

   return PHASE_NONE;
}


   //int Aligned() const { return m5AlignedCount; }
   //int Counter() const { return m5CounterCount; }
};





#endif // __CREGIME_PHASE_DETECTOR_MQH__