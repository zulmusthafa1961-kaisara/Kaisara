//+------------------------------------------------------------------+
//|               RectDumpByObjectsEA.mq5                           |
//+------------------------------------------------------------------+
#property strict

input string FileName = "RectDump.csv";

//+------------------------------------------------------------------+
//| Expert init: schedule one‐shot timer to let indicator paint      |
//+------------------------------------------------------------------+
int OnInit()
{
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| One‐shot timer: dump rectangles then remove EA                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   EventKillTimer();
   DumpAllRectangles();
   ExpertRemove();
}

//+------------------------------------------------------------------+
//| Loop all OBJ_RECTANGLEs → CSV                                    |
//+------------------------------------------------------------------+
void DumpAllRectangles()
{ 
    string filename = FileName;
    int fh;
    
    // Open file for writing
    fh = FileOpen(filename, FILE_WRITE|FILE_CSV);
    
    if(fh == INVALID_HANDLE)
    {
      Print(" Fail to open file");
    }  

   // Header
   FileWrite(fh,
             "Name",
             "Time1","Time2",
             "Price1","Price2",
             "Color");  

    int total = ObjectsTotal(0); 
   // Walk every object in main chart
   for(int i = 0; i < total; i++)
   {
      string nm = ObjectName(0, i);

      // 1) Must be a rectangle
      long typeVal;
      if(!ObjectGetInteger(0, nm, OBJPROP_TYPE,   0, typeVal)
      || typeVal != OBJ_RECTANGLE)
         continue;

      // 2) Skip your own dashboard shapes if you prefix them
      if(StringFind(nm, "DashRect_") == 0)
         continue;

      // 3) Read corner times (as integers) then cast
      //mql4 style
      //long t1i, t2i;
      //ObjectGetInteger(0, nm, OBJPROP_TIME1,  0, t1i);
      //ObjectGetInteger(0, nm, OBJPROP_TIME2,  0, t2i);
      //datetime t1 = (datetime)t1i;
      //datetime t2 = (datetime)t2i;
      
      //mql5 style
      datetime t1 = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 0);
      datetime t2 = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 1);

      // 4) Read corner prices
      //mql4 stlye 
      //double p1, p2;
      //ObjectGetDouble(0, nm, OBJPROP_PRICE1, 0, p1);
      //ObjectGetDouble(0, nm, OBJPROP_PRICE2, 0, p2);

      //mql5 style
      double p1 = ObjectGetDouble(0, nm, OBJPROP_PRICE, 0);
      double p2 = ObjectGetDouble(0, nm, OBJPROP_PRICE, 1);       

      // 5) Read color
      //long colVal = ObjectGetInteger(0, nm, OBJPROP_COLOR,0);
      color rect_color = (color) ObjectGetInteger(0, nm, OBJPROP_COLOR); 
      
      // Get color name
      string color_name = GetColorName(rect_color);      

      // 6) Write one CSV line
                      // Write rectangle data to CSV
                FileWrite(fh,
                         nm,
                         //(long)t1,
                         TimeToString(t1, TIME_DATE|TIME_SECONDS),
                         //(long)t2,
                         TimeToString(t2, TIME_DATE|TIME_SECONDS),
                         DoubleToString(p1, _Digits),
                         DoubleToString(p2, _Digits),
                         color_name
                         );
      
   }

   FileClose(fh);
   Print("Exported ", total, " objects to ", FileName);
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
    }
    return "color not red nor green";
}