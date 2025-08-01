//+------------------------------------------------------------------+
//|                                       RegimeDashboardBuilder.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#ifndef __REGIMEDASHBOARDBUILDER_MQH__
#define __REGIMEDASHBOARDBUILDER_MQH__


#include "UnifiedRegimeModulesmqh.mqh"

//+------------------------------------------------------------------+
//|             RegimeDashboardBuilder.mqh                           |
//+------------------------------------------------------------------+

class RegimeDashboard  {
private:
   // 🔁 Regime control
   int handleM5;
   int handleH1;

   // 🧠 History tracking
   string m5History[3];   // Size can be adjusted
   int historyIndex;
   
   //PhaseType activePhase;

   // 🎨 Visual renderer
   RegimeDisplayRenderer displayRenderer;


public:
   // 🔧 Constructor
   RegimeDashboard () {
      historyIndex = 0;
      
      //ArrayInitialize(m5History, "");
      for (int i = 0; i < ArraySize(m5History); i++)
         m5History[i] = "";
   }

   // 🔌 Inject regime handles and phase
   void SetPhaseAndHandles(int phase, int hM5, int hH1) {
      g_activePhase = (PhaseType) phase;
      handleM5 = hM5;
      handleH1 = hH1;
   }

   // 🎨 Inject renderer reference
   void SetRenderer(RegimeDisplayRenderer &_renderer) {
      displayRenderer = _renderer;
   }

   // 🎯 Core updater — buffer read + regime build + draw
   void Update() {
      double upBuf[1], dnBuf[1];
      bool bufferOK = false;

      if (g_activePhase == PHASE_TYPE_M5 && handleM5 != INVALID_HANDLE) {
         if (CopyBuffer(handleM5, 0, 1, 1, upBuf) > 0 &&
             CopyBuffer(handleM5, 1, 1, 1, dnBuf) > 0) {
            bufferOK = true;
         }
      }

      if (!bufferOK) {
         Print("❌ Buffer read failed — M5 indicator inactive or not ready.");
         return;
      }

      string trendStrM5 = "Unknown";
      if (MathIsValidNumber(upBuf[0]) && MathIsValidNumber(dnBuf[0])) {
         if (upBuf[0] > dnBuf[0])
            trendStrM5 = "UP";
         else if (upBuf[0] < dnBuf[0])
            trendStrM5 = "DOWN";
         else
            trendStrM5 = "NEUTRAL";
      }

      string timeStr = TimeToString(iTime(_Symbol, PERIOD_M5, 1), TIME_MINUTES);
      string fullLabel = timeStr + ": " + trendStrM5;

      m5History[historyIndex % ArraySize(m5History)] = fullLabel;
      historyIndex++;

      // 🧪 Debug trace
      string debugStr = "M5 Regime History → ";
      for (int i = 0; i < ArraySize(m5History); i++) {
         int pos = (historyIndex + i) % ArraySize(m5History);
         debugStr += m5History[pos];
         if (i < ArraySize(m5History) - 1) debugStr += " | ";
      }
      Print(debugStr);

      // 🖼️ Subwindow rendering
      //displayRenderer.Clear();
      //g_rectangles.ClearBoxes();  // if you defined this
   }
};

#endif