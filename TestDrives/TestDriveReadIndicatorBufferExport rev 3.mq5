//+------------------------------------------------------------------+
//|               RectDumpByObjectsEA.mq5                           |
//+------------------------------------------------------------------+
#property strict

struct SRegimeRect
{
   string   name;
   datetime t1, t2;
   double   p1, p2;
   color    col;
};

void ExportRectsToCSV(string filename);
void CollectIndicatorRects(SRegimeRect &list[]);

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   // wait a moment for the indicator to paint (if needed)
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Timer: one‐shot export                                          |
//+------------------------------------------------------------------+
void OnTimer()
{
   EventKillTimer();
   ExportRectsToCSV("RectDump.csv");
   ExpertRemove();  // detach EA when done
}

//+------------------------------------------------------------------+
//| Gather all OBJ_RECTANGLEs except your own dashboard ones         |
//+------------------------------------------------------------------+
void CollectIndicatorRects(SRegimeRect &arr[])
{
   int total = ObjectsTotal(0);  // count all objects in main chart
   for(int idx = 0; idx < total; idx++)
   {
      string nm = ObjectName(0, idx);
      
      // Only rectangles
      long type = ObjectGetInteger(0, nm, OBJPROP_TYPE);
      if(type != OBJ_RECTANGLE) 
         continue;

      // Skip your own dashboard objects if they start with "DashRect_"
      if(StringFind(nm, "DashRect_") == 0)
         continue;

      SRegimeRect rec;
      rec.name = nm;
      rec.t1   = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME1);
      rec.t2   = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME2);
      rec.p1   =  ObjectGetDouble(0, nm, OBJPROP_PRICE1);
      rec.p2   =  ObjectGetDouble(0, nm, OBJPROP_PRICE2);
      rec.col  = (color)ObjectGetInteger(0, nm, OBJPROP_COLOR);

      // Prepend so newest appear first
      ArrayInsert(arr, 0, rec);
   }
}

//+------------------------------------------------------------------+
//| Write the collected rectangles to CSV                           |
//+------------------------------------------------------------------+
void ExportRectsToCSV(string filename)
{
   SRegimeRect list[];  
   CollectIndicatorRects(list);

   int fh = FileOpen(filename,
                     FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(fh == INVALID_HANDLE)
   {
      Print("Cannot open ", filename);
      return;
   }

   // Optional header
   FileWrite(fh, "Name",
                "Time1","Time2",
                "Price1","Price2","Color");

for(int i = 0; i < ArraySize(list); i++)
{
   SRegimeRect rec = list[i];
   FileWrite(fh,
             rec.name,
             (long)rec.t1,
             TimeToString(rec.t1, TIME_DATE|TIME_MINUTES),
             (long)rec.t2,
             TimeToString(rec.t2, TIME_DATE|TIME_MINUTES),
             DoubleToString(rec.p1, _Digits),
             DoubleToString(rec.p2, _Digits),
             StringFormat("0x%06X",(uint)rec.col & 0xFFFFFF)
   );
}

   FileClose(fh);
   Print("Exported ", ArraySize(list), " rectangles to ", filename);
}
