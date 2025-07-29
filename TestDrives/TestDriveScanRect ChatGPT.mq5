//+------------------------------------------------------------------+
//|                                                RectScanner.mq5    |
//+------------------------------------------------------------------+
#property strict
#property version "1.02"

input string OutputFileName = "RectanglesData.csv";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!ScanRectanglesAndSave())
     {
      Print("Failed to scan and save rectangles.");
      return(INIT_FAILED);
     }
   Print("Rectangles scanned and saved successfully.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Scan rectangles and save to CSV                                  |
//+------------------------------------------------------------------+
bool ScanRectanglesAndSave()
  {
   // Get total rectangle objects on main chart window (0)
   int total_rects = ObjectsTotal(0, OBJ_RECTANGLE);
   PrintFormat("Total rectangle objects on main chart: %d", total_rects);

   // Open file for writing
   int file_handle = FileOpen(OutputFileName, FILE_WRITE|FILE_CSV|FILE_COMMON);
   if(file_handle == INVALID_HANDLE)
     {
      PrintFormat("Failed to open file %s, error %d", OutputFileName, GetLastError());
      return(false);
     }

   // Write header
   FileWrite(file_handle, "Name", "Price1", "Price2", "Time1", "Time2");

   // Loop over all rectangle objects on chart window 0
   for(int i=0; i<total_rects; i++)
     {
      // Get object name by index, type, and window (0)
      string name = ObjectNameByIndex(0, OBJ_RECTANGLE, i);
      if(name=="")
         continue; // skip if no name (should not happen)

      // Double check subwindow of object, must be 0 (main chart window)
      int obj_window = (int)ObjectGetInteger(0, name, OBJPROP_WINDOW);
      if(obj_window != 0)
         continue;

      // Get rectangle points coordinates (rectangles have 2 points)
      datetime time1 = ObjectGetTimeByValue(0, name, 0);    // first point time
      datetime time2 = ObjectGetTimeByValue(0, name, 1);    // second point time
      double price1  = ObjectGetPriceByValue(0, name, 0);   // first point price
      double price2  = ObjectGetPriceByValue(0, name, 1);   // second point price

      // Write data row
      FileWrite(file_handle, name,
                DoubleToString(price1,_Digits),
                DoubleToString(price2,_Digits),
                TimeToString(time1,TIME_DATE|TIME_SECONDS),
                TimeToString(time2,TIME_DATE|TIME_SECONDS));

      PrintFormat("Saved rectangle: %s, price1=%.5f, price2=%.5f, time1=%s, time2=%s",
                  name, price1, price2,
                  TimeToString(time1,TIME_DATE|TIME_SECONDS),
                  TimeToString(time2,TIME_DATE|TIME_SECONDS));
     }
   FileClose(file_handle);
   return(true);
  }

//+------------------------------------------------------------------+
//| Helper function: Get object name by index and type on chart      |
//+------------------------------------------------------------------+
string ObjectNameByIndex(const long chart_id, const ENUM_OBJECT obj_type, const int index)
  {
   // Loop through all objects, counting only those matching type and window=0
   int count=0;
   int total_all = ObjectsTotal(chart_id, -1);
   for(int i=0; i<total_all; i++)
     {
      string name = ObjectName(chart_id, i);
      ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(chart_id, name, OBJPROP_TYPE);
      if(type == obj_type)
        {
         int window = (int)ObjectGetInteger(chart_id, name, OBJPROP_WINDOW);
         if(window == 0)
           {
            if(count == index)
               return name;
            count++;
           }
        }
     }
   return("");
  }
