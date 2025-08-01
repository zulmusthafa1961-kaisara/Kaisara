//+------------------------------------------------------------------+
//|  TestDrive_ReadBufferToFileEA.mq5                                |
//+------------------------------------------------------------------+
#property strict
#resource "ProfitFX-TrendBoxSignal-Gold.ex5"

input string  OutputFile   = "H1History4.csv";
input int     BarsToExport = 20;

int    handleH1;
double bufferUp[];
double bufferDn[];

// will fire once, after OnInit
void OnTimer()
{
   // 1) stop the timer so this only runs once
   EventKillTimer();

   // 2) give the indicator a moment to calc
   Sleep(300);

   // 3) prepare arrays
   ArrayResize(bufferUp,  BarsToExport);
   ArrayResize(bufferDn,  BarsToExport);

   // 4) copy only closed bars (shift = 1)
   int gotUp = CopyBuffer(handleH1, 1, 1, BarsToExport, bufferUp);
   int gotDn = CopyBuffer(handleH1, 0, 1, BarsToExport, bufferDn);
   if(gotUp != BarsToExport || gotDn != BarsToExport)
   {
      Print("CopyBuffer mismatch: Up=",gotUp," Dn=",gotDn);
      ExpertRemove();
      return;
   }

   // 5) release handle
   IndicatorRelease(handleH1);

   // 6) write CSV
   int fh = FileOpen(OutputFile,
                     FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(fh==INVALID_HANDLE)
   {
      Print("Cannot open ",OutputFile);
      ExpertRemove();
      return;
   }

   // buffer[k] → the k’th most-recent closed H1 bar
   for(int k=0; k<BarsToExport; k++)
   {
      datetime t = iTime(_Symbol, PERIOD_H1, k+1);
      FileWrite(fh,
                (long)t,
                TimeToString(t,TIME_DATE|TIME_SECONDS),
                bufferUp[k],
                bufferDn[k]);
   }
   FileClose(fh);

   Print("Exported ",BarsToExport," closed H1 bars to ",OutputFile);
   ExpertRemove();
}

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   // 1) create the handle asking for one extra bar 
   handleH1 = iCustom(_Symbol, PERIOD_H1,
                      "::ProfitFX-TrendBoxSignal-Gold.ex5",
                      BarsToExport + 1);
   if(handleH1 == INVALID_HANDLE)
   {
      Print("Failed to load H1 indicator");
      return(INIT_FAILED);
   }

   // 2) schedule our one-shot timer in 1 second
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}
