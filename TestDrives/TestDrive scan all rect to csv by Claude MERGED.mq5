//+------------------------------------------------------------------+
//|                                           Rectangle Scanner EA.mq5 |
//|                                  Copyright 2025, Your Name Here |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
#property copyright "Copyright 2025, Your Name Here"
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Input parameters
input bool ScanOnStartOnly = true;  // Scan only once when EA starts
input string CSVFileName = "rectangles_data.csv";  // CSV file name
input string GroupedCSVFileName = "grouped_rectangles.csv";  // Grouped CSV file name
input double PriceTolerancePoints = 10.0;  // Price tolerance in points for grouping
input int MaxTimeGapBars = 3;  // Maximum time gap in bars to consider contiguous
input int MinRectanglesInGroup = 1;  // Minimum rectangles required to form a group

//--- Structure to hold rectangle data
struct RectangleData
{
    string name;
    double price1;
    double price2;
    datetime time1;
    datetime time2;
    color rect_color;
    string color_name;
    double mid_price;  // Average of price1 and price2
    int time_order;    // Order in time sequence
};

//--- Structure to hold grouped rectangles
struct RectangleGroup
{
    string group_name;
    double min_price;
    double max_price;
    double avg_price;
    datetime start_time;
    datetime end_time;
    int rectangle_count;
    string member_names[];
    color dominant_color;
    string color_name;
    bool is_contiguous;
};

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
        GroupRectangles();
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
        GroupRectangles();
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
//| Function to group rectangles by price range and time contiguity |
//+------------------------------------------------------------------+
void GroupRectangles()
{
    RectangleData rectangles[];
    int rect_count = CollectRectangleData(rectangles);
    
    if(rect_count < MinRectanglesInGroup)
    {
        Print("Not enough rectangles to form groups. Found: ", rect_count);
        return;
    }
    
    // Sort rectangles by time
    SortRectanglesByTime(rectangles, rect_count);
    
    // Group rectangles
    RectangleGroup groups[];
    int group_count = CreatePriceGroups(rectangles, rect_count, groups);
    
    // Export grouped data
    ExportGroupedData(groups, group_count);
    
    Print("Grouping completed. Found ", group_count, " groups from ", rect_count, " rectangles.");
}

//+------------------------------------------------------------------+
//| Function to collect all rectangle data into array               |
//+------------------------------------------------------------------+
int CollectRectangleData(RectangleData &rectangles[])
{
    int total_objects = ObjectsTotal(0);
    int rect_count = 0;
    
    // Count rectangles first
    for(int i = 0; i < total_objects; i++)
    {
        string object_name = ObjectName(0, i);
        if(ObjectGetInteger(0, object_name, OBJPROP_TYPE) == OBJ_RECTANGLE)
            rect_count++;
    }
    
    if(rect_count == 0) return 0;
    
    // Resize array
    ArrayResize(rectangles, rect_count);
    
    // Collect rectangle data
    int index = 0;
    for(int i = 0; i < total_objects; i++)
    {
        string object_name = ObjectName(0, i);
        if(ObjectGetInteger(0, object_name, OBJPROP_TYPE) == OBJ_RECTANGLE)
        {
            rectangles[index].name = object_name;
            rectangles[index].price1 = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 0);
            rectangles[index].price2 = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 1);
            rectangles[index].time1 = (datetime)ObjectGetInteger(0, object_name, OBJPROP_TIME, 0);
            rectangles[index].time2 = (datetime)ObjectGetInteger(0, object_name, OBJPROP_TIME, 1);
            rectangles[index].rect_color = (color)ObjectGetInteger(0, object_name, OBJPROP_COLOR);
            rectangles[index].color_name = GetColorName(rectangles[index].rect_color);
            rectangles[index].mid_price = (rectangles[index].price1 + rectangles[index].price2) / 2.0;
            rectangles[index].time_order = index;
            index++;
        }
    }
    
    return rect_count;
}

//+------------------------------------------------------------------+
//| Function to sort rectangles by time                             |
//+------------------------------------------------------------------+
void SortRectanglesByTime(RectangleData &rectangles[], int count)
{
    for(int i = 0; i < count - 1; i++)
    {
        for(int j = 0; j < count - i - 1; j++)
        {
            if(rectangles[j].time1 > rectangles[j + 1].time1)
            {
                RectangleData temp = rectangles[j];
                rectangles[j] = rectangles[j + 1];
                rectangles[j + 1] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Function to create price-based groups                           |
//+------------------------------------------------------------------+
int CreatePriceGroups(RectangleData &rectangles[], int rect_count, RectangleGroup &groups[])
{
    bool used[];
    ArrayResize(used, rect_count);
    ArrayInitialize(used, false);
    
    int group_count = 0;
    double price_tolerance = PriceTolerancePoints * Point();
    
    Print("Price tolerance: ", price_tolerance, " points");
    
    for(int i = 0; i < rect_count; i++)
    {
        if(used[i]) continue;
        
        Print("Starting new group with rectangle ", i, ": ", rectangles[i].name, 
              " Price1: ", rectangles[i].price1, " Price2: ", rectangles[i].price2,
              " Mid price: ", rectangles[i].mid_price);
        
        // Start a new group
        RectangleGroup current_group;
        current_group.group_name = "Group_" + IntegerToString(group_count + 1);
        
        // Initialize with actual price bounds, not mid-price
        current_group.min_price = MathMin(rectangles[i].price1, rectangles[i].price2);
        current_group.max_price = MathMax(rectangles[i].price1, rectangles[i].price2);
        current_group.start_time = rectangles[i].time1;
        current_group.end_time = rectangles[i].time2;
        current_group.rectangle_count = 0;
        current_group.dominant_color = rectangles[i].rect_color;
        current_group.color_name = rectangles[i].color_name;
        current_group.is_contiguous = true;
        
        string member_names_temp[];
        ArrayResize(member_names_temp, rect_count);
        
        // Add current rectangle to group
        member_names_temp[current_group.rectangle_count] = rectangles[i].name;
        current_group.rectangle_count++;
        used[i] = true;
        
        // Find other rectangles in similar price range
        for(int j = 0; j < rect_count; j++)
        {
            if(used[j] || j == i) continue;
            
            double price_diff = MathAbs(rectangles[j].mid_price - rectangles[i].mid_price);
            
            Print("Checking rectangle ", j, ": ", rectangles[j].name, 
                  " Price1: ", rectangles[j].price1, " Price2: ", rectangles[j].price2,
                  " Mid price: ", rectangles[j].mid_price, 
                  " Price diff: ", price_diff, 
                  " Tolerance: ", price_tolerance);
            
            // Check price similarity
            if(price_diff <= price_tolerance)
            {
                Print("Price match! Checking time contiguity...");
                
                // Check time contiguity - simplified check
                bool is_contiguous = IsTimeContiguousSimple(rectangles, rect_count, current_group, j);
                
                if(is_contiguous)
                {
                    Print("Time contiguous! Adding to group.");
                    member_names_temp[current_group.rectangle_count] = rectangles[j].name;
                    current_group.rectangle_count++;
                    used[j] = true;
                    
                    // Update group bounds with actual price ranges
                    double rect_min = MathMin(rectangles[j].price1, rectangles[j].price2);
                    double rect_max = MathMax(rectangles[j].price1, rectangles[j].price2);
                    
                    if(rect_min < current_group.min_price)
                        current_group.min_price = rect_min;
                    if(rect_max > current_group.max_price)
                        current_group.max_price = rect_max;
                    if(rectangles[j].time1 < current_group.start_time)
                        current_group.start_time = rectangles[j].time1;
                    if(rectangles[j].time2 > current_group.end_time)
                        current_group.end_time = rectangles[j].time2;
                }
                else
                {
                    Print("Not time contiguous, skipping.");
                }
            }
            else
            {
                Print("Price difference too large, skipping.");
            }
        }
        
        // Only add group if it has minimum required members
        if(current_group.rectangle_count >= MinRectanglesInGroup)
        {
            current_group.avg_price = (current_group.min_price + current_group.max_price) / 2.0;
            
            // Copy member names
            ArrayResize(current_group.member_names, current_group.rectangle_count);
            for(int k = 0; k < current_group.rectangle_count; k++)
            {
                current_group.member_names[k] = member_names_temp[k];
            }
            
            // Add group to array
            ArrayResize(groups, group_count + 1);
            groups[group_count] = current_group;
            group_count++;
            
            Print("Group ", current_group.group_name, " created with ", current_group.rectangle_count, " rectangles");
            Print("Final group price range: ", current_group.min_price, " to ", current_group.max_price);
        }
        else
        {
            Print("Group discarded - only ", current_group.rectangle_count, " rectangles (minimum required: ", MinRectanglesInGroup, ")");
        }
    }
    
    return group_count;
}

//+------------------------------------------------------------------+
//| Function to check if rectangle is time contiguous with group    |
//+------------------------------------------------------------------+
bool IsTimeContiguousSimple(RectangleData &rectangles[], int count, RectangleGroup &group, int rect_index)
{
    // For simplicity, check if rectangle time is within reasonable range of group timeframe
    datetime rect_time = rectangles[rect_index].time1;
    
    // Check if rectangle time falls within or close to the group's time range
    datetime time_diff_start = MathAbs(rect_time - group.start_time);
    datetime time_diff_end = MathAbs(rect_time - group.end_time);
    
    // Convert to hours for easier understanding
    int hours_from_start = (int)(time_diff_start / 3600);
    int hours_from_end = (int)(time_diff_end / 3600);
    
    // Allow up to MaxTimeGapBars hours gap (simplified)
    bool is_contiguous = (hours_from_start <= MaxTimeGapBars) || (hours_from_end <= MaxTimeGapBars) || 
                        (rect_time >= group.start_time && rect_time <= group.end_time);
    
    Print("Rectangle time: ", TimeToString(rect_time, TIME_DATE|TIME_MINUTES), 
          " Group start: ", TimeToString(group.start_time, TIME_DATE|TIME_MINUTES),
          " Group end: ", TimeToString(group.end_time, TIME_DATE|TIME_MINUTES),
          " Hours from start: ", hours_from_start,
          " Hours from end: ", hours_from_end,
          " Is contiguous: ", is_contiguous);
    
    return is_contiguous;
}

//+------------------------------------------------------------------+
//| Function to export grouped data to CSV                          |
//+------------------------------------------------------------------+
void ExportGroupedData(RectangleGroup &groups[], int group_count)
{
    string filename = GroupedCSVFileName;
    int file_handle = FileOpen(filename, FILE_WRITE|FILE_CSV);
    
    if(file_handle != INVALID_HANDLE)
    {
        // Write CSV header
        FileWrite(file_handle, "Group_Name", "Rectangle_Count", "Min_Price", "Max_Price", "Avg_Price", 
                 "Start_Time", "End_Time", "Duration_Hours", "Price_Range", "Dominant_Color", "Member_Names");
        
        for(int i = 0; i < group_count; i++)
        {
            // Calculate duration and price range
            int duration_hours = (int)((groups[i].end_time - groups[i].start_time) / 3600);
            double price_range = groups[i].max_price - groups[i].min_price;
            
            // Create member names string
            string members_str = "";
            for(int j = 0; j < groups[i].rectangle_count; j++)
            {
                if(j > 0) members_str += ";";
                members_str += groups[i].member_names[j];
            }
            
            // Write group data
            FileWrite(file_handle,
                     groups[i].group_name,
                     IntegerToString(groups[i].rectangle_count),
                     DoubleToString(groups[i].min_price, _Digits),
                     DoubleToString(groups[i].max_price, _Digits),
                     DoubleToString(groups[i].avg_price, _Digits),
                     TimeToString(groups[i].start_time, TIME_DATE|TIME_MINUTES),
                     TimeToString(groups[i].end_time, TIME_DATE|TIME_MINUTES),
                     IntegerToString(duration_hours),
                     DoubleToString(price_range, _Digits),
                     groups[i].color_name,
                     members_str);
            
            // Print group info
            Print("Group ", groups[i].group_name, ": ", groups[i].rectangle_count, " rectangles, ",
                  "Price range: ", DoubleToString(groups[i].min_price, _Digits), " - ", 
                  DoubleToString(groups[i].max_price, _Digits), ", Duration: ", duration_hours, " hours");
        }
        
        FileClose(file_handle);
        Print("Grouped data exported to: ", filename);
    }
    else
    {
        Print("Error opening grouped file: ", filename);
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