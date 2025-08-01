//+------------------------------------------------------------------+
//|                                            RectanglePlotterEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Input parameters
input color Rectangle1Color = clrRed;      // Color for Rectangle 1 (Left)
input color Rectangle2Color = clrGreen;    // Color for Rectangle 2 (Middle)
input color Rectangle3Color = clrGreen;    // Color for Rectangle 3 (Right)
input double BoxHeight = 0.4;              // Height of rectangles
input double BoxTop = 0.6;                 // Top level for all rectangles
input int GapBetweenBoxes = 8;             // Gap between boxes (in bars)
input string Box1Label = "Left Box";       // Label for Rectangle 1
input string Box2Label = "Middle Box";     // Label for Rectangle 2
input string Box3Label = "Right Box";      // Label for Rectangle 3
input bool CreateSubWindow = true;         // Create sub-window for rectangles

// Global variables
string rect1_name = "EA_HorizontalRect_1";
string rect2_name = "EA_HorizontalRect_2";
string rect3_name = "EA_HorizontalRect_3";
string label1_name = "EA_HorizontalLabel_1";
string label2_name = "EA_HorizontalLabel_2";
string label3_name = "EA_HorizontalLabel_3";
string dummy_indicator_handle = "EA_DummyIndicator";
int target_subwindow = 1;
bool rectangles_created = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Rectangle Plotter EA starting initialization...");
    
    // Create or find sub-window
    if(CreateSubWindow)
    {
        CreateDummyIndicatorForSubWindow();
    }
    else
    {
        target_subwindow = 0; // Use main chart window
    }
    
    // Set timer to create rectangles after sub-window is ready
    EventSetTimer(2); // 2 second delay
    
    Print("Rectangle Plotter EA initialized - rectangles will appear in ", target_subwindow == 0 ? "main window" : "sub-window");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    EventKillTimer();
    
    // Clean up all objects
    ObjectDelete(0, rect1_name);
    ObjectDelete(0, rect2_name);
    ObjectDelete(0, rect3_name);
    ObjectDelete(0, label1_name);
    ObjectDelete(0, label2_name);
    ObjectDelete(0, label3_name);
    ObjectDelete(0, dummy_indicator_handle);
    
    ChartRedraw();
    Print("Rectangle Plotter EA deinitialized - reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // EA can perform other trading logic here
    // Rectangles are managed by timer
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(!rectangles_created)
    {
        CreateHorizontalRectangles();
        CreateLabels();
        rectangles_created = true;
        EventKillTimer(); // Stop timer after creating rectangles
        Print("Rectangles created successfully by EA");
    }
}

//+------------------------------------------------------------------+
//| Create dummy indicator to establish sub-window                   |
//+------------------------------------------------------------------+
void CreateDummyIndicatorForSubWindow()
{
    // Create a dummy line to establish sub-window
    ObjectCreate(0, dummy_indicator_handle, OBJ_HLINE, target_subwindow, 0, 0.5);
    ObjectSetInteger(0, dummy_indicator_handle, OBJPROP_COLOR, clrNONE);
    ObjectSetInteger(0, dummy_indicator_handle, OBJPROP_STYLE, STYLE_DOT);
    ObjectSetInteger(0, dummy_indicator_handle, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, dummy_indicator_handle, OBJPROP_BACK, true);
    ObjectSetString(0, dummy_indicator_handle, OBJPROP_TOOLTIP, "Sub-window Reference Line");
    
    Print("Sub-window setup completed");
}

//+------------------------------------------------------------------+
//| Create horizontal rectangles                                     |
//+------------------------------------------------------------------+
void CreateHorizontalRectangles()
{
    // Clean up existing rectangles first
    ObjectDelete(0, rect1_name);
    ObjectDelete(0, rect2_name);
    ObjectDelete(0, rect3_name);
    
    // Get current chart info
    int total_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
    if(total_bars < 30) total_bars = 50; // Minimum width
    
    datetime current_time = TimeCurrent();
    int box_width = (total_bars - 2 * GapBetweenBoxes) / 3;
    
    // Calculate time positions for horizontal layout
    datetime start_time = current_time - PeriodSeconds(PERIOD_CURRENT) * total_bars;
    
    // Box 1 (Left)
    datetime box1_start = start_time;
    datetime box1_end = start_time + PeriodSeconds(PERIOD_CURRENT) * box_width;
    
    // Box 2 (Middle)  
    datetime box2_start = box1_end + PeriodSeconds(PERIOD_CURRENT) * GapBetweenBoxes;
    datetime box2_end = box2_start + PeriodSeconds(PERIOD_CURRENT) * box_width;
    
    // Box 3 (Right)
    datetime box3_start = box2_end + PeriodSeconds(PERIOD_CURRENT) * GapBetweenBoxes;
    datetime box3_end = box3_start + PeriodSeconds(PERIOD_CURRENT) * box_width;
    
    double box_bottom = BoxTop - BoxHeight;
    
    // Create Rectangle 1 (Left - Red)
    if(ObjectCreate(0, rect1_name, OBJ_RECTANGLE, target_subwindow, box1_start, BoxTop, box1_end, box_bottom))
    {
        ObjectSetInteger(0, rect1_name, OBJPROP_COLOR, Rectangle1Color);
        ObjectSetInteger(0, rect1_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, rect1_name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, rect1_name, OBJPROP_FILL, true);
        ObjectSetInteger(0, rect1_name, OBJPROP_BACK, false);
        ObjectSetString(0, rect1_name, OBJPROP_TOOLTIP, "Left Rectangle - " + Box1Label);
        Print("✓ Created Rectangle 1 (Left-Red) in window ", target_subwindow);
    }
    else
    {
        Print("✗ Failed to create Rectangle 1");
    }
    
    // Create Rectangle 2 (Middle - Green)
    if(ObjectCreate(0, rect2_name, OBJ_RECTANGLE, target_subwindow, box2_start, BoxTop, box2_end, box_bottom))
    {
        ObjectSetInteger(0, rect2_name, OBJPROP_COLOR, Rectangle2Color);
        ObjectSetInteger(0, rect2_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, rect2_name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, rect2_name, OBJPROP_FILL, true);
        ObjectSetInteger(0, rect2_name, OBJPROP_BACK, false);
        ObjectSetString(0, rect2_name, OBJPROP_TOOLTIP, "Middle Rectangle - " + Box2Label);
        Print("✓ Created Rectangle 2 (Middle-Green) in window ", target_subwindow);
    }
    else
    {
        Print("✗ Failed to create Rectangle 2");
    }
    
    // Create Rectangle 3 (Right - Green)
    if(ObjectCreate(0, rect3_name, OBJ_RECTANGLE, target_subwindow, box3_start, BoxTop, box3_end, box_bottom))
    {
        ObjectSetInteger(0, rect3_name, OBJPROP_COLOR, Rectangle3Color);
        ObjectSetInteger(0, rect3_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, rect3_name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, rect3_name, OBJPROP_FILL, true);
        ObjectSetInteger(0, rect3_name, OBJPROP_BACK, false);
        ObjectSetString(0, rect3_name, OBJPROP_TOOLTIP, "Right Rectangle - " + Box3Label);
        Print("✓ Created Rectangle 3 (Right-Green) in window ", target_subwindow);
    }
    else
    {
        Print("✗ Failed to create Rectangle 3");
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create labels below rectangles                                   |
//+------------------------------------------------------------------+
void CreateLabels()
{
    // Clean up existing labels
    ObjectDelete(0, label1_name);
    ObjectDelete(0, label2_name);
    ObjectDelete(0, label3_name);
    
    // Get chart info
    int total_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
    if(total_bars < 30) total_bars = 50;
    
    datetime current_time = TimeCurrent();
    int box_width = (total_bars - 2 * GapBetweenBoxes) / 3;
    
    datetime start_time = current_time - PeriodSeconds(PERIOD_CURRENT) * total_bars;
    
    // Calculate center positions for labels
    datetime box1_center = start_time + PeriodSeconds(PERIOD_CURRENT) * (box_width / 2);
    datetime box2_center = start_time + PeriodSeconds(PERIOD_CURRENT) * (box_width + GapBetweenBoxes + box_width / 2);
    datetime box3_center = start_time + PeriodSeconds(PERIOD_CURRENT) * (2 * box_width + 2 * GapBetweenBoxes + box_width / 2);
    
    double label_level = BoxTop - BoxHeight - 0.05;
    
    // Create Label 1 (Left)
    if(ObjectCreate(0, label1_name, OBJ_TEXT, target_subwindow, box1_center, label_level))
    {
        ObjectSetString(0, label1_name, OBJPROP_TEXT, Box1Label);
        ObjectSetInteger(0, label1_name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, label1_name, OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, label1_name, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, label1_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
        Print("✓ Created Label 1: ", Box1Label);
    }
    
    // Create Label 2 (Middle)
    if(ObjectCreate(0, label2_name, OBJ_TEXT, target_subwindow, box2_center, label_level))
    {
        ObjectSetString(0, label2_name, OBJPROP_TEXT, Box2Label);
        ObjectSetInteger(0, label2_name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, label2_name, OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, label2_name, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, label2_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
        Print("✓ Created Label 2: ", Box2Label);
    }
    
    // Create Label 3 (Right)
    if(ObjectCreate(0, label3_name, OBJ_TEXT, target_subwindow, box3_center, label_level))
    {
        ObjectSetString(0, label3_name, OBJPROP_TEXT, Box3Label);
        ObjectSetInteger(0, label3_name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, label3_name, OBJPROP_FONTSIZE, 9);
        ObjectSetString(0, label3_name, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, label3_name, OBJPROP_ANCHOR, ANCHOR_CENTER);
        Print("✓ Created Label 3: ", Box3Label);
    }
    
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Function to manually refresh rectangles (call from EA logic)     |
//+------------------------------------------------------------------+
void RefreshRectangles()
{
    rectangles_created = false;
    CreateHorizontalRectangles();
    CreateLabels();
    rectangles_created = true;
}

//+------------------------------------------------------------------+
//| Function to change rectangle colors dynamically                  |
//+------------------------------------------------------------------+
void ChangeRectangleColors(color color1, color color2, color color3)
{
    ObjectSetInteger(0, rect1_name, OBJPROP_COLOR, color1);
    ObjectSetInteger(0, rect2_name, OBJPROP_COLOR, color2);
    ObjectSetInteger(0, rect3_name, OBJPROP_COLOR, color3);
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Function to update rectangle labels                              |
//+------------------------------------------------------------------+
void UpdateRectangleLabels(string label1, string label2, string label3)
{
    ObjectSetString(0, label1_name, OBJPROP_TEXT, label1);
    ObjectSetString(0, label2_name, OBJPROP_TEXT, label2);
    ObjectSetString(0, label3_name, OBJPROP_TEXT, label3);
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Sample EA trading logic - you can add your trading code here     |
//+------------------------------------------------------------------+
void PerformTradingLogic()
{
    // Example: Change rectangle colors based on market conditions
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    static double last_price = 0;
    
    if(last_price > 0)
    {
        if(current_price > last_price)
        {
            // Market going up - make all green
            ChangeRectangleColors(clrGreen, clrGreen, clrGreen);
        }
        else if(current_price < last_price)
        {
            // Market going down - make all red
            ChangeRectangleColors(clrRed, clrRed, clrRed);
        }
    }
    
    last_price = current_price;
}