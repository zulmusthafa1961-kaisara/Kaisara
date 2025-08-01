//+------------------------------------------------------------------+
//|                                TestDriveMinimalist_Sub1.mq5      |
//|           Minimal EA: 4 left rects, gold spacer, 4 right rects  |
//|                            all in subwindow #1                  |
//+------------------------------------------------------------------+
#property strict

// layout constants
#define BOXW     50      // width in px
#define BOXH     30      // height in px
#define GAP      10      // gap in px
#define OFFSETX  20      // left margin in px
#define OFFSETY  20      // top margin in px

// draw our test rectangles + spacer into subwindow 1
void DrawTestRects_Sub1()
{
   int sw = 1; // target subwindow

   // 1) left 4 blue boxes
   for(int i=0; i<4; i++)
   {
      string name = "TestL"+(string)i;
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, sw, 0, 0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,  OFFSETX + i*(BOXW+GAP));
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,  OFFSETY);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,      BOXW);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,      BOXH);
      ObjectSetInteger(0,name,OBJPROP_COLOR,      clrDodgerBlue);
      ObjectSetInteger(0,name,OBJPROP_BACK,       true);
   }

   // 2) gold spacer
   {
      string name = "TestSpacer";
      ObjectCreate(0, name, OBJ_LABEL, sw, 0, 0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,  OFFSETX + 4*(BOXW+GAP));
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,  OFFSETY + BOXH/2 - 8);
      ObjectSetString (0,name,OBJPROP_TEXT,       "⇄");
      ObjectSetInteger(0,name,OBJPROP_COLOR,      clrGold);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,   16);
      ObjectSetInteger(0,name,OBJPROP_BACK,       false);
   }

   // 3) right 4 red boxes
   for(int i=0; i<4; i++)
   {
      string name = "TestR"+(string)i;
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, sw, 0, 0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,  OFFSETX + (5+i)*(BOXW+GAP));
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,  OFFSETY);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,      BOXW);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,      BOXH);
      ObjectSetInteger(0,name,OBJPROP_COLOR,      clrCrimson);
      ObjectSetInteger(0,name,OBJPROP_BACK,       true);
   }
}

// delete all objects created above
void DeleteTestRects_Sub1()
{
   for(int i=0;i<4;i++) ObjectDelete(0,"TestL"+(string)i);
   ObjectDelete(0,"TestSpacer");
   for(int i=0;i<4;i++) ObjectDelete(0,"TestR"+(string)i);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // draw into subwindow 1
   DrawTestRects_Sub1();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeleteTestRects_Sub1();
}

//+------------------------------------------------------------------+
//| Expert tick function (unused)                                    |
//+------------------------------------------------------------------+
void OnTick()
{
}
