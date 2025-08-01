//+------------------------------------------------------------------+
//|                                          Kaisara-MultiCharts.mq5 |
//+------------------------------------------------------------------+
#resource "ProfitFX-TrendBoxSignal-Gold.ex5"

input int NoOfBars = 300; 
int handleH1 = INVALID_HANDLE;
int handleM5 = INVALID_HANDLE;


enum RegimePhase { NONE, PULLBACK, CONTINUATION };
RegimePhase DetectM5Phase(double up, double dn) {
   if (up > dn) return CONTINUATION;
   if (up < dn) return PULLBACK;
   return NONE;
}

int OnInit() {

   handleH1 = INVALID_HANDLE;
   handleM5 = INVALID_HANDLE;

   handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);
   handleM5 = iCustom(_Symbol, PERIOD_M5, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars);

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

   
}
   

/*
void OnTick()  {
   static double prevUpM5 = 0;
   static double prevDnM5 = 0;

   double upH1 = GetRegimeValue(_Symbol, PERIOD_H1, 0, 0);
   double dnH1 = GetRegimeValue(_Symbol, PERIOD_H1, 1, 0);
   
   double upM5 = GetRegimeValue(_Symbol, PERIOD_M5, 0, 0);
   double dnM5 = GetRegimeValue(_Symbol, PERIOD_M5, 1, 0);
   
   // validate buffer
   if (upH1 == EMPTY_VALUE || upM5 == EMPTY_VALUE) return;
   if (dnH1 == EMPTY_VALUE || dnM5 == EMPTY_VALUE) return; 
   
   Print("Regime: H1[", upH1, "/", dnH1, "] M5[", upM5, "/", dnM5, "]");
     
   static RegimePhase prevPhase = NONE;
   RegimePhase currentPhase = DetectM5Phase(upM5, dnM5);
   
   bool transitionConfirmed = (prevPhase == PULLBACK && currentPhase == CONTINUATION);
 
   bool regimeConfirmed = (upH1 > dnH1 && upM5 > dnM5);
   bool signalReady = ValidateSetup(prevUpM5, prevDnM5, upM5, dnM5, regimeConfirmed);
   
   if (signalReady) {
   
   
       // Read snapshot zones
       // Tag regime context
       // Evaluate signal strength or entry criteria
   }
     

   // keep at the end of tick func
   prevUpM5 = upM5;
   prevDnM5 = dnM5;
   prevPhase = currentPhase;   
}
*/

void OnTick() {
   // 1. Historical values for pullback tracking
   static double prevUpM5 = 0;
   static double prevDnM5 = 0;
   static RegimePhase prevPhase = NONE;

   // 2. Read regime buffers
   double upH1 = GetRegimeValue(PERIOD_H1, 0, 0);
   double dnH1 = GetRegimeValue(PERIOD_H1, 1, 0);
   double upM5 = GetRegimeValue(PERIOD_M5, 0, 0);
   double dnM5 = GetRegimeValue(PERIOD_M5, 1, 0);

   // 3. Buffer sanity check
   if (upH1 == EMPTY_VALUE || dnH1 == EMPTY_VALUE || upM5 == EMPTY_VALUE || dnM5 == EMPTY_VALUE) return;

   // 4. Regime and phase logic
   bool regimeConfirmed = (upH1 > dnH1 && upM5 > dnM5);
   RegimePhase currentPhase = DetectM5Phase(upM5, dnM5);
   bool transitionConfirmed = (prevPhase == PULLBACK && currentPhase == CONTINUATION);

   // ✅ 5. This is where you place the continuation trigger
   if (regimeConfirmed && transitionConfirmed) {
      // 🌟 CONTINUATION setup detected
      // You can now plug in zone overlap, signal filters, execution flags
   }

   // 6. Optional: ValidateSetup() for combined logic (if used separately)
   // bool signalReady = ValidateSetup(...);

   // 7. Update tracking vars at end
   prevUpM5 = upM5;
   prevDnM5 = dnM5;
   prevPhase = currentPhase;
}

/*
double GetRegimeValue(string symbol, ENUM_TIMEFRAMES tf, int bufferIndex, int shift) {
   return iCustom(symbol, tf, "::ProfitFX-TrendBoxSignal-Gold.ex5", NoOfBars, bufferIndex, shift);
}
*/

double GetRegimeValue(int handle, int bufferIndex, int shift) {
   double buffer[];
   if (CopyBuffer(handle, bufferIndex, shift, 1, buffer) != 1) {
      return EMPTY_VALUE;
   }
   return buffer[0];
}



bool ValidateSetup(double previousUpM5, double previousDnM5, double upM5, double dnM5, bool regimeConfirmed) {
   bool pullbackResolved = (previousUpM5 < previousDnM5) && (upM5 > dnM5);
   return (regimeConfirmed && pullbackResolved);
}

