//+------------------------------------------------------------------+
//|  TestDrive_ReadBufferToFileEA.mq5                               |
//+------------------------------------------------------------------+
#property strict
#resource "ProfitFX-TrendBoxSignal-Gold.ex5"


input string   OutputFile   = "H1History2.csv";
input int      BarsToExport = 20;
int            handleH1;
double         bufferUp[];
double         bufferDn[];

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   ArraySetAsSeries(bufferUp,true);
   ArraySetAsSeries(bufferDn,true);
   
   // 1) Load H1 indicator handle
   handleH1 = iCustom(_Symbol, PERIOD_H1, "::ProfitFX-TrendBoxSignal-Gold.ex5", BarsToExport);
   if(handleH1==INVALID_HANDLE)
   {
      Print("Failed to load H1 indicator");
      return(INIT_FAILED);
   }

   // 2) Copy its primary buffer
   double bufferUp[];
   if(CopyBuffer(handleH1, 1, 0, BarsToExport, bufferUp) <= 0)
   {
      Print("CopyBuffer failed");
      return(INIT_FAILED);
   }

   double bufferDn[];
   if(CopyBuffer(handleH1, 0, 0, BarsToExport, bufferDn) <= 0)
   {
      Print("CopyBuffer failed");
      return(INIT_FAILED);
   }   

   // 3) Write CSV: timestamp, regimeInt
   int fh = FileOpen(OutputFile, FILE_WRITE|FILE_CSV);
   for(int i = BarsToExport-1; i >= 0; i--)
   {
      datetime t = iTime(_Symbol, PERIOD_H1, i);
      double   upbuf = (double)bufferUp[i];
      double   dnbuf = (double)bufferDn[i];
      FileWrite(fh, (long)t, TimeToString(t), upbuf, dnbuf);
   }
   FileClose(fh);
   
   Print("Exported ", BarsToExport, " H1 bars to ", OutputFile);
   return(INIT_SUCCEEDED);
}

   
//HHistory1.csv
/*                                                     actual buffer read (data window)               
datetime        datetime         BufUp BufDn timeline  BufUp   BufDn
15 1752026400	2025.07.09 02:00	3300	3289    0100hr  3300    3311   (wrong number logged) 
14 1752030000	2025.07.09 03:00	3300	3289    0200hr  3300    3311   (wrong number logged)
13 1752033600	2025.07.09 04:00	3300	3289    0300hr  3300    3311   (wrong number logged)
12 1752037200	2025.07.09 05:00	3300	3289    0400hr  3300    3311   (wrong number logged)
11 1752040800	2025.07.09 06:00	3300	3289    0500hr  3289    3300   (wrongly logged, reversed up/dn)
10 1752044400	2025.07.09 07:00	3300	3289    0600hr  3289    3300   (wrongly logged, reversed up/dn)
9  1752048000	2025.07.09 08:00	3300	3289    0700hr  3289    3300   (wrongly logged, reversed up/dn)
8  1752051600	2025.07.09 09:00	3300	3289    0800hr  3289    3300   (wrongly logged, reversed up/dn)
7  1752055200	2025.07.09 10:00	3300	3289    0900hr  3289    3300   (wrongly logged, reversed up/dn)
6  1752058800	2025.07.09 11:00	3300	3289   1000hr   3289    3300   (wrongly logged, reversed up/dn)
5  1752062400	2025.07.09 12:00	3300	3289   1100hr   3289    3300   (wrongly logged, reversed up/dn)
4  1752066000	2025.07.09 13:00	3300	3289   1200hr   3289    3300   (wrongly logged, reversed up/dn)
3  1752069600	2025.07.09 14:00	3300	3289   1300hr   3289    3300   (wrongly logged, reversed up/dn)
2  1752073200	2025.07.09 15:00	3300	3289   1400hr   3289    3300   (wrongly logged, reversed up/dn)
1  1752076800	2025.07.09 16:00	3300	3289   1500hr   3289    3300   (wrongly logged, reversed up/dn)
(no 1 is the last candle close at 16:00)
(server Symbol Watch @ 16:20 while 
 unfinished candle still run @ timeline 16hr)
 this candle is due to close at server 17:00, timeline 1600hr
 
switched buffer no in order to swap buffer up and down due to wrongly logged; reversed up/down buffer value
chg from:
   if(CopyBuffer(handleH1, 0, 0, BarsToExport, bufferUp) <= 0)
   if(CopyBuffer(handleH1, 1, 0, BarsToExport, bufferDn) <= 0) 
      
chg to :
   if(CopyBuffer(handleH1, 1, 0, BarsToExport, bufferUp) <= 0) 
   if(CopyBuffer(handleH1, 0, 0, BarsToExport, bufferDn) <= 0)
   
//HHistory2.csv   
result after switching buffer no: 
                                                    actual buffer read (data window)               
datetime     datetime         BufUp BufDn timeline  BufUp   BufDn  
15 1752026400	2025.07.09 02:00	3289	3300   0100hr  3300    3311 (wrongly logged) <-- timeline at BOD
14 1752030000	2025.07.09 03:00	3289	3300   0200hr  3300    3311 (wrongly logged)
13 1752033600	2025.07.09 04:00	3289	3300   0300hr  3300    3311 (wrongly logged)
12 1752037200	2025.07.09 05:00	3289	3300   0400hr  3300    3311 (wrongly logged)
11 1752040800	2025.07.09 06:00	3289	3300   0500hr  3289    3300 (correctly logged)
10 1752044400	2025.07.09 07:00	3289	3300   0600hr  3289    3300 (correctly logged)
9  1752048000	2025.07.09 08:00	3289	3300   0700hr  3289    3300 (correctly logged)
8  1752051600	2025.07.09 09:00	3289	3300   0800hr  3289    3300 (correctly logged)
7  1752055200	2025.07.09 10:00	3289	3300   0900hr  3289    3300 (correctly logged)
6  1752058800	2025.07.09 11:00	3289	3300  1000hr   3289    3300 (correctly logged)
5  1752062400	2025.07.09 12:00	3289	3300  1100hr   3289    3300 (correctly logged)
4  1752066000	2025.07.09 13:00	3289	3300  1200hr   3289    3300 (correctly logged)
3  1752069600	2025.07.09 14:00	3289	3300  1300hr   3289    3300 (correctly logged)
2  1752073200	2025.07.09 15:00	3289	3300  1400hr   3289    3300 (correctly logged) 
1  1752076800	2025.07.09 16:00	3289	3300  1500hr   3289    3300 (correctly logged)

Note:
Because the value of BufDn is higher than BufUp, the regime is colored as Red (Bearish/Down regime)
The last 11 candles now have BufUp and BufDn correctly recorder and they are all form a big long
stretch of Down regime box. 
 
   
CRITICAL ERROR OBSERVED:
The most recent rects where logging is done for 20 bars (NoOfBar) after running this TestDrive
changed to become a long stretch flat rectangle for all 20 H1 candles where logged is done !!!
 
Reload the blank template and the indicator to show the actual rects for recording actual as tabulated. 

Original rects before running this test drive:
            actual BufUp  actual BufDn
candle 15   3300          3311
.........   ....          ....
candle 12   3300          3311                           
candle 11   3289          3300  
.........   ....          ....
candle 1    3289          3300

After running this test drive:
            actual BufUp  actual BufDn
candle 15   3289          3300     <-- wrongly formed rect (extended from candle 11) and buffer value
.........   ....          ....     
candle 12   3289          3300     <-- wrongly formed rect (extended from candle 11) and buffer value                 
candle 11   3289          3300     <-- correctly colored rects and buffer value
.........   ....          ....
candle 1    3289          3300     <-- correctly colored rects and buffer value
    
*/
   
