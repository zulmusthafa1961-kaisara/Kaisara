//+------------------------------------------------------------------+
//|        TestDriveRectsWithClass_CenterSpacer.mq5                 |
//+------------------------------------------------------------------+
#property strict
#include "modules/UnifiedRegimeModulesmqh.mqh"

#define BOX_W        50
#define BOX_H        30
#define BOX_GAP      10
#define STRIP_GAP   220
#define TOP_MARGIN  20
#define LEFT_MARGIN 20

CStationaryRectangles4Box leftBoxes("Left_"), rightBoxes("Right_");

int OnInit()
{
   const int SW = 1;
   int stripWidth  = 4*BOX_W + 3*BOX_GAP;
   int rightMargin = LEFT_MARGIN + stripWidth + STRIP_GAP;
   Print(">> rightMargin = ", rightMargin);

   // 1) Left strip
   leftBoxes.SetSubWindow(SW);
   leftBoxes.SetLeftMargin(LEFT_MARGIN);
   leftBoxes.SetBoxGap(BOX_GAP);
   leftBoxes.SetBoxDimensions(BOX_W, BOX_H);
   leftBoxes.SetTopMargin(TOP_MARGIN);
   leftBoxes.SetLabels("L3","L2","L1","L0");
   leftBoxes.Initialize();
   leftBoxes.ClearBoxes();
   leftBoxes.Create();
   leftBoxes.UpdateLabels("L3","L2","L1","L0");
   leftBoxes.UpdateColors(clrDodgerBlue,clrDodgerBlue,clrDodgerBlue,clrDodgerBlue);

   // 2) Right strip
   rightBoxes.SetSubWindow(SW);
   rightBoxes.SetLeftMargin(rightMargin);
   rightBoxes.SetBoxGap(BOX_GAP);
   rightBoxes.SetBoxDimensions(BOX_W, BOX_H);
   rightBoxes.SetTopMargin(TOP_MARGIN);
   rightBoxes.SetLabels("R3","R2","R1","R0");
   rightBoxes.Initialize();
   rightBoxes.ClearBoxes();
   rightBoxes.Create();
   rightBoxes.UpdateLabels("R3","R2","R1","R0");
   rightBoxes.UpdateColors(clrCrimson,clrCrimson,clrCrimson,clrCrimson);

   // 3) Center spacer
   {
      string spacer = "Center_Spacer";
      string text   = "⇄ CENTER ⇄";
      int fontSize  = 12;
      int textW     = StringLen(text) * (fontSize/2);
      int x = LEFT_MARGIN + stripWidth + (STRIP_GAP/2) - (textW/2);
      int y = TOP_MARGIN + (BOX_H/2)    - (fontSize/2);

      if(ObjectCreate(0, spacer, OBJ_LABEL, SW, 0, 0))
      {
         ObjectSetInteger(0, spacer, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
         ObjectSetInteger(0, spacer, OBJPROP_XDISTANCE, x);
         ObjectSetInteger(0, spacer, OBJPROP_YDISTANCE, y);
         ObjectSetString (0, spacer, OBJPROP_TEXT,       text);
         ObjectSetInteger(0, spacer, OBJPROP_COLOR,      clrGold);
         ObjectSetInteger(0, spacer, OBJPROP_FONTSIZE,   fontSize);
         ObjectSetInteger(0, spacer, OBJPROP_BACK,       false);
      }
   }

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   leftBoxes.ClearBoxes();
   rightBoxes.ClearBoxes();
   ObjectDelete(0,"Left_Spacer");   // if your class created one
   ObjectDelete(0,"Right_Spacer");
   ObjectDelete(0,"Center_Spacer");
}

