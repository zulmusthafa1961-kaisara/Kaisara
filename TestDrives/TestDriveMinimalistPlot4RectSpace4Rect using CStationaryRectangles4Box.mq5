//+------------------------------------------------------------------+
//|              TestDriveRectsWithClassLabels_Fixed.mq5            |
//| Minimal EA: left 4 boxes + spacer + right 4 boxes in subwindow1 |
//|   using CStationaryRectangles4Box, with labels/colors applied   |
//+------------------------------------------------------------------+
#property strict

#include "modules\StationaryRectangles4Box.mqh"

// layout
#define BOX_W       50     // width (px)
#define BOX_H       30     // height (px)
#define BOX_GAP     10     // gap (px)
#define TOP_MARGIN  20     // y-offset (px)

CStationaryRectangles4Box  leftBoxes("Left_"), rightBoxes("Right_");

int OnInit()
{
   const int SW = 1;  // draw into subwindow #1

   //— Configure Left —
   leftBoxes.SetSubWindow(SW);
   leftBoxes.SetBoxGap(BOX_GAP);
   leftBoxes.SetBoxDimensions(BOX_W, BOX_H);
   leftBoxes.SetTopMargin(TOP_MARGIN);
   // these labels will end up inside the rectangles
   leftBoxes.SetLabels("L3","L2","L1","L0");

   leftBoxes.Initialize();     // must initialize internal arrays
   leftBoxes.ClearBoxes();     // remove any leftovers
   leftBoxes.Create();         // draws 4 empty rects

   // now actually place text & color
   leftBoxes.UpdateLabels("L3","L2","L1","L0");
   leftBoxes.UpdateColors(
      clrDodgerBlue, clrDodgerBlue, clrDodgerBlue, clrDodgerBlue
   );

   //— Spacer between slot #2 & #3 —
   leftBoxes.DrawSpacer("⇄ Center ⇄", 2);

   //— Configure Right —
   rightBoxes.SetSubWindow(SW);
   rightBoxes.SetBoxGap(BOX_GAP);
   rightBoxes.SetBoxDimensions(BOX_W, BOX_H);
   rightBoxes.SetTopMargin(TOP_MARGIN);
   rightBoxes.SetLabels("R3","R2","R1","R0");

   rightBoxes.Initialize();
   rightBoxes.ClearBoxes();
   rightBoxes.Create();

   rightBoxes.UpdateLabels("R3","R2","R1","R0");
   rightBoxes.UpdateColors(
      clrCrimson, clrCrimson, clrCrimson, clrCrimson
   );

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   // wipe out everything
   leftBoxes.ClearBoxes();
   ObjectDelete(0, "Left_Spacer");
   rightBoxes.ClearBoxes();
}

void OnTick() { }
