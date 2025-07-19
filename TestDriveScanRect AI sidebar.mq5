//+------------------------------------------------------------------+
//|                                                   ScanRectangles.mq5 |
//|                                              Fully functional version   |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

int OnInit()
  {
   PrintRectanglesOnChart(0);
   return(INIT_SUCCEEDED);
  }

void PrintRectanglesOnChart(long chart_id)
  {
   int total_objects = ObjectsTotal(chart_id);
   for(int i=0; i<total_objects; i++)
     {
      string name = ObjectName(chart_id, i);

      if(ObjectType(chart_id, name) == OBJ_RECTANGLE)
        {
         Print("Rectangle found: ", name);

         long time1=0, time2=0;
         double price1=0.0, price2=0.0;

         // Get properties (success boolean)
         bool success = true;
         success &= ObjectGetInteger(chart_id, name, OBJPROP_TIME1, time1);
         success &= ObjectGetInteger(chart_id, name, OBJPROP_TIME2, time2);
         success &= ObjectGetDouble(chart_id, name, OBJPROP_PRICE1, price1);
         success &= ObjectGetDouble(chart_id, name, OBJPROP_PRICE2, price2);

         if(success)
           {
             PrintFormat("Coords: Time1=%s, Price1=%.2f, Time2=%s, Price2=%.2f",
                         TimeToString(time1), price1, TimeToString(time2), price2);
           }
         else
           {
             Print("Failed to get rectangle coordinates: ", name);
           }
        }
     }
  }