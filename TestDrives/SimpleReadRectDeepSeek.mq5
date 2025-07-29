//+------------------------------------------------------------------+
//|                     EA to Check Rectangle Properties             |
//+------------------------------------------------------------------+
#property strict
input string RectangleName = "obj_rect0012025.06.23 03:00:00"; // Set your rectangle name here

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   CheckRectangleProperties(RectangleName);
   return(INIT_SUCCEEDED);
}

/*
//+------------------------------------------------------------------+
//| Check rectangle properties                                       |
//+------------------------------------------------------------------+
void CheckRectangleProperties(string object_name)
{
   long obj_type = ObjectGetInteger(0, object_name, OBJPROP_TYPE);
   if(obj_type == OBJ_RECTANGLE)
   {
      long color_value;
      if(ObjectGetInteger(0, object_name, OBJPROP_COLOR, 0, color_value))
      {
         color rect_color = (color)color_value;
         Print("Rectangle '", object_name, "' color: ", rect_color);
      }
      else Print("Error: Failed to get color for ", object_name);
   }
   else Print("Error: Object '", object_name, "' is not a rectangle.");
}
*/


void CheckRectangleProperties(string object_name)
{
   // Explicitly use the built-in function with ::
   long obj_type = ::ObjectGetInteger(0, object_name, OBJPROP_TYPE);
   if(obj_type == OBJ_RECTANGLE)
   {
      long color_value;
      if(::ObjectGetInteger(0, object_name, OBJPROP_COLOR, 0, color_value)) // Use ::
      {
         color rect_color = (color)color_value;
         Print("Rectangle '", object_name, "' color: ", rect_color);
      }
      else Print("Error: Failed to get color for ", object_name);
   }
   else Print("Error: Object '", object_name, "' is not a rectangle.");
}