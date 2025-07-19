//+------------------------------------------------------------------+
//|                                           Rectangle Scanner EA.mq5 |
//|                                  Copyright 2025, Your Name Here |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Your Name Here"
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Input parameters
input bool ScanOnStartOnly = true;  // Scan only once when EA starts
input string CSVFileName = "rectangles_data.csv";  // CSV file name

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Rectangle Scanner EA initialized");
    
    // Scan rectangles on initialization
    if(ScanOnStartOnly)
    {
        ScanAndExportRectangles();
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Rectangle Scanner EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // If not scanning only on start, scan on every tick
    if(!ScanOnStartOnly)
    {
        ScanAndExportRectangles();
    }
}

//+------------------------------------------------------------------+
//| Function to scan all rectangles and export to CSV               |
//+------------------------------------------------------------------+
void ScanAndExportRectangles()
{
    string filename = CSVFileName;
    int file_handle;
    
    // Open file for writing
    file_handle = FileOpen(filename, FILE_WRITE|FILE_CSV);
    
    if(file_handle != INVALID_HANDLE)
    {
        // Write CSV header
        FileWrite(file_handle, "Name", "Price1", "Price2", "Time1", "Time2", "Time1_String", "Time2_String", "Color", "Color_Name");
        
        // Get total number of objects on chart
        int total_objects = ObjectsTotal(0);
        int rectangle_count = 0;
        
        Print("Total objects on chart: ", total_objects);
        
        // Loop through all objects
        for(int i = 0; i < total_objects; i++)
        {
            string object_name = ObjectName(0, i);
            
            // Check if object is a rectangle
            if(ObjectGetInteger(0, object_name, OBJPROP_TYPE) == OBJ_RECTANGLE)
            {
                rectangle_count++;
                
                // Get rectangle properties
                double price1 = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 0);
                double price2 = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 1);
                datetime time1 = (datetime)ObjectGetInteger(0, object_name, OBJPROP_TIME, 0);
                datetime time2 = (datetime)ObjectGetInteger(0, object_name, OBJPROP_TIME, 1);
                color rect_color = (color)ObjectGetInteger(0, object_name, OBJPROP_COLOR);
                
                // Convert times to readable strings
                string time1_str = TimeToString(time1, TIME_DATE|TIME_MINUTES);
                string time2_str = TimeToString(time2, TIME_DATE|TIME_MINUTES);
                
                // Get color name
                string color_name = GetColorName(rect_color);
                
                // Write rectangle data to CSV
                FileWrite(file_handle, 
                         object_name, 
                         DoubleToString(price1, _Digits), 
                         DoubleToString(price2, _Digits), 
                         (string)time1, 
                         (string)time2,
                         time1_str,
                         time2_str,
                         (string)rect_color,
                         color_name);
                
                // Print to terminal for verification
                Print("Rectangle: ", object_name, 
                      " | Price1: ", DoubleToString(price1, _Digits),
                      " | Price2: ", DoubleToString(price2, _Digits),
                      " | Time1: ", time1_str,
                      " | Time2: ", time2_str,
                      " | Color: ", color_name, " (", (string)rect_color, ")");
            }
        }
        
        // Close file
        FileClose(file_handle);
        
        Print("Rectangle scan completed. Found ", rectangle_count, " rectangles.");
        Print("Data exported to: ", filename);
        Print("File saved in: ", TerminalInfoString(TERMINAL_DATA_PATH), "\\MQL5\\Files\\");
    }
    else
    {
        Print("Error opening file: ", filename, " Error code: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Function to get color name from color value                     |
//+------------------------------------------------------------------+
string GetColorName(color clr)
{
    switch(clr)
    {
        case clrRed:        return "Red";
        case clrGreen:      return "Green";
        case clrBlue:       return "Blue";
        case clrYellow:     return "Yellow";
        case clrBlack:      return "Black";
        case clrGray:       return "Gray";
        case clrDarkGray:   return "DarkGray";
        case clrLightGray:  return "LightGray";
        case clrOrange:     return "Orange";
        case clrPink:       return "Pink";
        case clrBrown:      return "Brown";
        case clrGold:       return "Gold";
        case clrSilver:     return "Silver";
        case clrDarkBlue:   return "DarkBlue";
        case clrDarkGreen:  return "DarkGreen";
        case clrDarkRed:    return "DarkRed";
        case clrLime:       return "Lime";
        case clrNavy:       return "Navy";
        case clrPurple:     return "Purple";
        case clrTeal:       return "Teal";
        case clrMaroon:     return "Maroon";
        case clrOlive:      return "Olive";
        case clrAqua:       return "Aqua";
        case clrFuchsia:    return "Fuchsia";
        default:            return "RGB(" + 
                                   IntegerToString((clr & 0xFF)) + "," + 
                                   IntegerToString((clr >> 8) & 0xFF) + "," + 
                                   IntegerToString((clr >> 16) & 0xFF) + ")";
    }
}

//+------------------------------------------------------------------+
//| Function to manually trigger scan (can be called from script)    |
//+------------------------------------------------------------------+
void ManualScan()
{
    Print("Manual scan triggered");
    ScanAndExportRectangles();
}