//+------------------------------------------------------------------+
//|                                            RectanglePlotterEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Input parameters
input color Rectangle1Color = clrRed;      // Color for Rectangle 1
input color Rectangle2Color = clrGreen;    // Color for Rectangle 2  
input color Rectangle3Color = clrGreen;    // Color for Rectangle 3
input int SubWindow = 1;                   // Sub-window number
input double Box1_Top = 0.8;               // Rectangle 1 Top Level
input double Box1_Bottom = 0.6;            // Rectangle 1 Bottom Level
input double Box2_Top = 0.4;               // Rectangle 2 Top Level
input double Box2_Bottom = 0.2;            // Rectangle 2 Bottom Level
input double Box3_Top = 0.0;               // Rectangle 3 Top Level
input double Box3_Bottom = -0.2;           // Rectangle 3 Bottom Level

// Global variables
string rect1_name = "Rectangle_1";
string rect2_name = "Rectangle_2";
string rect3_name = "Rectangle_3";
string dummy_indicator = "DummyIndicator";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Create dummy indicator in sub-window
    CreateDummyIndicator();
    
    // Create rectangles
    CreateRectangles();
    
    Print("Rectangle Plotter EA initialized successfully");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up rectangles
    ObjectDelete(0, rect1_name);
    ObjectDelete(0, rect2_name);
    ObjectDelete(0, rect3_name);
    
    // Clean up dummy indicator
    ObjectDelete(0, dummy_indicator);
    
    Print("Rectangle Plotter EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update rectangles if needed (extend to current time)
    UpdateRectangles();
}

//+------------------------------------------------------------------+
//| Create dummy indicator for sub-window                            |
//+------------------------------------------------------------------+
void CreateDummyIndicator()
{
    // Create a dummy label to establish the sub-window
    ObjectCreate(0, dummy_indicator, OBJ_LABEL, SubWindow, 0, 0);
    ObjectSetString(0, dummy_indicator, OBJPROP_TEXT, "Dummy Indicator");
    ObjectSetInteger(0, dummy_indicator, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, dummy_indicator, OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, dummy_indicator, OBJPROP_YDISTANCE, 10);
    ObjectSetInteger(0, dummy_indicator, OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, dummy_indicator, OBJPROP_FONTSIZE, 8);
}

//+------------------------------------------------------------------+
//| Create rectangles in sub-window                                  |
//+------------------------------------------------------------------+
void CreateRectangles()
{
    datetime current_time = TimeCurrent();
    datetime start_time = current_time - PeriodSeconds(PERIOD_CURRENT) * 50; // 50 bars back
    datetime end_time = current_time + PeriodSeconds(PERIOD_CURRENT) * 10;   // 10 bars forward
    
    // Create Rectangle 1
    ObjectCreate(0, rect1_name, OBJ_RECTANGLE, SubWindow, start_time, Box1_Top, end_time, Box1_Bottom);
    ObjectSetInteger(0, rect1_name, OBJPROP_COLOR, Rectangle1Color);
    ObjectSetInteger(0, rect1_name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, rect1_name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, rect1_name, OBJPROP_FILL, true);
    ObjectSetInteger(0, rect1_name, OBJPROP_BACK, true);
    ObjectSetString(0, rect1_name, OBJPROP_TOOLTIP, "Rectangle 1");
    
    // Create Rectangle 2
    ObjectCreate(0, rect2_name, OBJ_RECTANGLE, SubWindow, start_time, Box2_Top, end_time, Box2_Bottom);
    ObjectSetInteger(0, rect2_name, OBJPROP_COLOR, Rectangle2Color);
    ObjectSetInteger(0, rect2_name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, rect2_name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, rect2_name, OBJPROP_FILL, true);
    ObjectSetInteger(0, rect2_name, OBJPROP_BACK, true);
    ObjectSetString(0, rect2_name, OBJPROP_TOOLTIP, "Rectangle 2");
    
    // Create Rectangle 3
    ObjectCreate(0, rect3_name, OBJ_RECTANGLE, SubWindow, start_time, Box3_Top, end_time, Box3_Bottom);
    ObjectSetInteger(0, rect3_name, OBJPROP_COLOR, Rectangle3Color);
    ObjectSetInteger(0, rect3_name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, rect3_name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, rect3_name, OBJPROP_FILL, true);
    ObjectSetInteger(0, rect3_name, OBJPROP_BACK, true);
    ObjectSetString(0, rect3_name, OBJPROP_TOOLTIP, "Rectangle 3");
    
    // Refresh chart
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Update rectangles to extend with current time                    |
//+------------------------------------------------------------------+
void UpdateRectangles()
{
    datetime current_time = TimeCurrent();
    datetime end_time = current_time + PeriodSeconds(PERIOD_CURRENT) * 10;
    
    // Update Rectangle 1 end time
    ObjectSetInteger(0, rect1_name, OBJPROP_TIME, 1, end_time);
    
    // Update Rectangle 2 end time
    ObjectSetInteger(0, rect2_name, OBJPROP_TIME, 1, end_time);
    
    // Update Rectangle 3 end time
    ObjectSetInteger(0, rect3_name, OBJPROP_TIME, 1, end_time);
}

//+------------------------------------------------------------------+
//| Custom function to change rectangle colors                       |
//+------------------------------------------------------------------+
void ChangeRectangleColors(color color1, color color2, color color3)
{
    ObjectSetInteger(0, rect1_name, OBJPROP_COLOR, color1);
    ObjectSetInteger(0, rect2_name, OBJPROP_COLOR, color2);
    ObjectSetInteger(0, rect3_name, OBJPROP_COLOR, color3);
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Custom function to change rectangle positions                    |
//+------------------------------------------------------------------+
void ChangeRectanglePositions(double top1, double bottom1, double top2, double bottom2, double top3, double bottom3)
{
    ObjectSetDouble(0, rect1_name, OBJPROP_PRICE, 0, top1);
    ObjectSetDouble(0, rect1_name, OBJPROP_PRICE, 1, bottom1);
    
    ObjectSetDouble(0, rect2_name, OBJPROP_PRICE, 0, top2);
    ObjectSetDouble(0, rect2_name, OBJPROP_PRICE, 1, bottom2);
    
    ObjectSetDouble(0, rect3_name, OBJPROP_PRICE, 0, top3);
    ObjectSetDouble(0, rect3_name, OBJPROP_PRICE, 1, bottom3);
    
    ChartRedraw();
}