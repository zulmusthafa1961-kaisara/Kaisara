//+------------------------------------------------------------------+
//|  TestDrive_FileToDashboardEA.mq5                                |
//+------------------------------------------------------------------+
#property strict
#include "StationaryRectangles4Box.mqh"
#include "ZoneAnalyzer.mqh"

input string  InputFile       = "H1History.csv";
input int     ZonesToDisplay  = 4;
input int     BOX_W           = 50;
input int     BOX_H           = 30;
input int     BOX_GAP         = 10;
input int     LEFT_MARGIN     = 20;
input int     TOP_MARGIN      = 20;

CZoneAnalyzer             analyzer;
CStationaryRectangles4Box h1Boxes("H1_");

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   // 1) Init analyzer
   if(!analyzer.Initialize())
      return(INIT_FAILED);

   // 2) Read CSV and feed analyzer
   int fh = FileOpen(InputFile, FILE_READ|FILE_CSV);
   while(!FileIsEnding(fh))
   {
      datetime dt     = (datetime)FileReadInteger(fh);
      int      r      = FileReadInteger(fh);
      FileReadString(fh);
      analyzer.ProcessRegime((RegimeType)r, dt);
   }
   FileClose(fh);

   // 3) Setup strip in SW=1
   const int SW = 1;
   h1Boxes.SetSubWindow(SW);
   h1Boxes.SetBoxDimensions(BOX_W, BOX_H);
   h1Boxes.SetBoxGap(BOX_GAP);
   h1Boxes.SetLeftMargin(LEFT_MARGIN);
   h1Boxes.SetTopMargin(TOP_MARGIN);
   h1Boxes.Initialize();
   h1Boxes.ClearBoxes();
   h1Boxes.Create();

   // 4) Draw last ZonesToDisplay zones
   CArrayObj &zones = analyzer.ZoneHistory();
   int total = zones.Total(), start = MathMax(0, total - ZonesToDisplay);
   string labs[4]; color cols[4];
   for(int i = 0; i < ZonesToDisplay; i++)
   {
      CZoneInfo *z = (CZoneInfo*)zones.At(start + i);
      labs[i] = z.RegimeTag();
      cols[i] = (z.RegimeType()==REG_UP ? clrDodgerBlue
               : z.RegimeType()==REG_DOWN ? clrCrimson : clrSilver);
   }
   h1Boxes.UpdateLabels(labs[0],labs[1],labs[2],labs[3]);
   h1Boxes.UpdateColors(cols[0],cols[1],cols[2],cols[3]);

   return(INIT_SUCCEEDED);
}
