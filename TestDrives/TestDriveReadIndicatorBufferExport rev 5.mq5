//+------------------------------------------------------------------+
//|               RectDumpByObjectsEA.mq5                           |
//+------------------------------------------------------------------+
#property strict

input string FileName = "RectDump.csv";

//--- numeric IDs for rectangle properties
#define OP_TYPE    0    // OBJPROP_TYPE
#define OP_TIME1  60    // OBJPROP_TIME1
#define OP_TIME2  61    // OBJPROP_TIME2
#define OP_PRICE1 62    // OBJPROP_PRICE1
#define OP_PRICE2 63    // OBJPROP_PRICE2
#define OP_COLOR  14    // OBJPROP_COLOR

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   // Give the indicator time to draw its shapes
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| One-shot timer: dump & exit                                      |
//+------------------------------------------------------------------+
void OnTimer()
{
   EventKillTimer();
   DumpAllRectangles();
   ExpertRemove();
}

//+------------------------------------------------------------------+
//| Dump every OBJ_RECTANGLE in subwindow=0 to CSV                   |
//+------------------------------------------------------------------+
void DumpAllRectangles()
{
   int total = ObjectsTotal(0);  
   int fh    = FileOpen(FileName, FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(fh == INVALID_HANDLE)
   {
      Print("Cannot open file ", FileName);
      return;
   }

   // Write CSV header
   FileWrite(fh,
             "Name",
             "Time1","Time2",
             "Price1","Price2",
             "Color");

   // Iterate all objects on main chart
   for(int i = 0; i < total; i++)
   {
      string nm = ObjectName(0, i);

      // 1) Must be a rectangle
      if(ObjectGetInteger(0, nm, OP_TYPE, 0) != OBJ_RECTANGLE)
         continue;

      // 2) Skip your own dashboard boxes (if prefixed "DashRect_")
      if(StringFind(nm, "DashRect_") == 0)
         continue;

      // 3) Read corner times & prices and the color
      datetime t1 = (datetime)ObjectGetInteger(0, nm, OP_TIME1,  0);
      datetime t2 = (datetime)ObjectGetInteger(0, nm, OP_TIME2,  0);
      double   p1 =             ObjectGetDouble (0, nm, OP_PRICE1, 0);
      double   p2 =             ObjectGetDouble (0, nm, OP_PRICE1, 1);
      uint     c  = (uint)     ObjectGetInteger(0, nm, OP_COLOR,  0);

      // 4) Write one line
      FileWrite(fh,
                nm,
                (long)t1,
                TimeToString(t1, TIME_DATE|TIME_SECONDS),
                (long)t2,
                TimeToString(t2, TIME_DATE|TIME_SECONDS),
                DoubleToString(p1, _Digits),
                DoubleToString(p2, _Digits),
                StringFormat("0x%06X", c & 0xFFFFFF)
      );
   }

   FileClose(fh);
   Print("Exported ", total, " objects to ", FileName);
}
