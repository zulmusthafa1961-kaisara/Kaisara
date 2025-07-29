//+------------------------------------------------------------------+
//| StationaryRectangles4Box.mqh                                     |
//| Reusable class for 4 fixed pixel-aligned rectangles              |
//+------------------------------------------------------------------+
class CStationaryRectangles4Box
{
private:
   // Configuration
   int m_target_subwindow;
   int m_box_gap, m_box_width, m_box_height, m_top_margin;
   string m_labels[4];
   color m_colors[4];
   string m_prefix;
   string m_rect_names[4], m_label_names[4];
   bool m_initialized;
   int subWindowID;  // Subwindow ID for drawing rectangles


   void GenerateNames()
   {
      for(int i = 0; i < 4; i++)
      {
         m_rect_names[i]  = m_prefix + "Rect" + IntegerToString(i+1);
         m_label_names[i] = m_prefix + "Label" + IntegerToString(i+1);
      }
   }

   void SetSubWindow(int windowID)
   {
      subWindowID = windowID;
   }
   
   void CleanupObjects()
   {
      for(int i = 0; i < 4; i++)
      {
         ObjectDelete(0, m_rect_names[i]);
         ObjectDelete(0, m_label_names[i]);
      }
   }
   
   void CreateTextLabels(int &x[], int y_base)
   {
      int label_y = y_base + 10;
      for(int i = 0; i < 4; i++)
      {
         if(ObjectCreate(0, m_label_names[i], OBJ_LABEL, m_target_subwindow, 0, 0))
         {
            ObjectSetInteger(0, m_label_names[i], OBJPROP_XDISTANCE, x[i] + m_box_width/2 - 25);
            ObjectSetInteger(0, m_label_names[i], OBJPROP_YDISTANCE, label_y);
            ObjectSetString(0, m_label_names[i], OBJPROP_TEXT, m_labels[i]);
            ObjectSetInteger(0, m_label_names[i], OBJPROP_COLOR, clrWhite);
            ObjectSetInteger(0, m_label_names[i], OBJPROP_FONTSIZE, 10);
            ObjectSetString(0, m_label_names[i], OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, m_label_names[i], OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, m_label_names[i], OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
            ObjectSetInteger(0, m_label_names[i], OBJPROP_BACK, false);
            ObjectSetInteger(0, m_label_names[i], OBJPROP_HIDDEN, true);
         }
      }
   }

public:

   CStationaryRectangles4Box(string prefix = "SR4_")
   {
      m_target_subwindow = 1;
      m_box_gap = 20;
      m_box_width = 150;
      m_box_height = 40;
      m_top_margin = 30;
      m_labels[0] = "Box1"; m_labels[1] = "Box2"; m_labels[2] = "Box3"; m_labels[3] = "Box4";
      m_colors[0] = clrRed; m_colors[1] = clrGreen; m_colors[2] = clrGreen; m_colors[3] = clrGray;
      m_prefix = prefix;
      m_initialized = false;
      GenerateNames();
   }

   bool Initialize()
   {
      if(m_box_width <= 0 || m_box_height <= 0 || m_target_subwindow < 0)
         return false;
      m_initialized = true;
      return true;
   }

   bool Create()
   {
      if(!m_initialized) return false;
      CleanupObjects();

      int start_x = 20;
      int x[4];
      for(int i = 0; i < 4; i++)
         x[i] = start_x + i * (m_box_width + m_box_gap);
      int y1 = m_top_margin;
      int y2 = y1 + m_box_height;

      for(int i = 0; i < 4; i++)
      {
         if(ObjectCreate(0, m_rect_names[i], OBJ_RECTANGLE_LABEL, m_target_subwindow, 0, 0))
         {
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_XDISTANCE, x[i]);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_YDISTANCE, y1);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_XSIZE, m_box_width);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_YSIZE, m_box_height);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BGCOLOR, m_colors[i]);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_COLOR, clrBlack);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BORDER_COLOR, clrBlack);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BORDER_TYPE, BORDER_FLAT);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BACK, false);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_HIDDEN, true);
            ObjectSetString(0, m_rect_names[i], OBJPROP_TOOLTIP, "Regime Box - " + m_labels[i]);
         }
      }

      CreateTextLabels(x, y2);
      ChartRedraw();
      return true;
   }

   void Destroy()
   {
      CleanupObjects();
      ChartRedraw();
      m_initialized = false;
   }

   void UpdateLabels(string l1, string l2, string l3, string l4)
   {
      m_labels[0] = l1; m_labels[1] = l2; m_labels[2] = l3; m_labels[3] = l4;
      for(int i = 0; i < 4; i++)
      {
         ObjectSetString(0, m_label_names[i], OBJPROP_TEXT, m_labels[i]);
         ObjectSetString(0, m_rect_names[i], OBJPROP_TOOLTIP, "Regime Box - " + m_labels[i]);
      }
      ChartRedraw();
   }

   void UpdateColors(color c1, color c2, color c3, color c4)
   {
      m_colors[0] = c1; m_colors[1] = c2; m_colors[2] = c3; m_colors[3] = c4;
      for(int i = 0; i < 4; i++)
         ObjectSetInteger(0, m_rect_names[i], OBJPROP_BGCOLOR, m_colors[i]);
      ChartRedraw();
   }

   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      if(id == CHARTEVENT_CHART_CHANGE && m_initialized)
         Create();
   }
};
