//+------------------------------------------------------------------+
//| StationaryRectangles4Box.mqh                                     |
//| Reusable class for 4 fixed pixel-aligned rectangles              |
//+------------------------------------------------------------------+
#ifndef __STATIONARYRECTANGLES4BOXPLUS_MQH__
#define __STATIONARYRECTANGLES4BOXPLUS_MQH__
//longer version works but without spacer

#include <Arrays\ArrayObj.mqh>
#include "UnifiedRegimeModulesmqh.mqh"

class CStationaryRectangles4Box
{
private:
   // Configuration
   int m_subwindow;
   int m_box_gap, m_box_width, m_box_height, m_top_margin;
   int boxWidth, boxHeight;
   int m_yOffset;
   string m_labels[4];
   color m_colors[4];
   string m_prefix;
   string m_rect_names[4], m_label_names[4];
   bool m_initialized;
   int m_fontSize;
   string prefix;  
   
private:
   int m_leftMargin; // new horizontal offset

public:
   // Draw the 4 text labels underneath each box
   void CreateTextLabels(int y_base);

   // call this before Create()/DrawSpacer()
   void SetLeftMargin(int px) { m_leftMargin = px; }
 
private:
   void GenerateNames()
   {
      for(int i = 0; i < 4; i++)
      {
         m_rect_names[i]  = m_prefix + "Rect" + IntegerToString(i+1);
         m_label_names[i] = m_prefix + "Label" + IntegerToString(i+1);
      }
   }

   void CleanupObjects()
   {
      for(int i = 0; i < 4; i++)
      {
         ObjectDelete(0, m_rect_names[i]);
         ObjectDelete(0, m_label_names[i]);
      }
   }


public:
   void Draw(string name, datetime time, color stripColor, bool alignLeft) {
         string fullName = prefix + name;
   
         if (!ObjectFind(0, fullName)) {
            ObjectCreate(0, fullName, OBJ_RECTANGLE_LABEL, 0, time, 0);
            ObjectSetInteger(0, fullName, OBJPROP_COLOR, stripColor);
            ObjectSetInteger(0, fullName, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, fullName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, fullName, OBJPROP_HIDDEN, true);
            ObjectSetInteger(0, fullName, OBJPROP_CORNER, alignLeft ? CORNER_LEFT_UPPER : CORNER_RIGHT_UPPER);
         }
      }


public:
   int subWindowID;  // Subwindow ID for drawing rectangles

   void SetSubWindow(int windowID)
   {
      subWindowID = windowID;
   }
   
public:
   // returns the user-supplied prefix (e.g. "Left_")
   string GetPrefix() const { return m_prefix; }
   
   
   
public:
   void ClearBoxes()
   {
      for(int i=0;i<4;i++)
         ObjectDelete(0, m_rect_names[i]);
      for(int i=0;i<4;i++)
         ObjectDelete(0, m_label_names[i]);
      ObjectDelete(0, m_prefix + "Spacer");
   }
    

   void SetBoxDimensions(int width, int height)
   {
      m_box_width  = width;
      m_box_height = height;
   }

   void SetBoxGap(int gap)
   {
      m_box_gap = gap;
   }

   void SetTopMargin(int margin)
   {
      m_top_margin = margin;
   }
      
   void SetBoxPosition(int pos)      
   {
      m_top_margin = pos;
   }
   
   
 public:
/*
   CStationaryRectangles4Box(string _prefix) {
      prefix = _prefix;
   } 
*/    
   CStationaryRectangles4Box(string Prefix = "SR4_")
   {
      m_prefix = Prefix;
      m_subwindow = 1;
      m_box_gap = 20;
      m_box_width = 150;
      m_box_height = 40;
      m_top_margin = 30;
      m_labels[0] = "Box1"; m_labels[1] = "Box2"; m_labels[2] = "Box3"; m_labels[3] = "Box4";
      m_colors[0] = clrRed; m_colors[1] = clrGreen; m_colors[2] = clrGreen; m_colors[3] = clrGray;
      //m_prefix = prefix;
      m_initialized = false;
      GenerateNames();
   }

bool CStationaryRectangles4Box::Initialize()
{
   if(m_box_width <= 0 || m_box_height <= 0 || m_subwindow < 0)
      return(false);

   m_initialized = true;
   //m_leftMargin  = 0;
   m_fontSize    = 12;    // pick a default here

   return(true);
}

   bool Create()
   {
      Print(m_prefix,": Create() start → subwin=",m_subwindow,
            " leftMargin=",m_leftMargin);
      
      
      if(!m_initialized) return false;
      //CleanupObjects();
      
      int bottomY = m_top_margin + m_box_height;
      CreateTextLabels(bottomY);
      

      int start_x = 20;
      int x[4];
      for(int i = 0; i < 4; i++)
         x[i] = start_x + i * (m_box_width + m_box_gap);
      int y1 = m_top_margin;
      int y2 = y1 + m_box_height;

      for(int i = 0; i < 4; i++)
      {
         int x = m_leftMargin + i*(m_box_width + m_box_gap);
         Print(m_prefix,":  Slot#",i," name=",m_rect_names[i]," x=",x);
      
         if(ObjectCreate(0, m_rect_names[i], OBJ_RECTANGLE_LABEL, m_subwindow, 0, 0))
         {
                  
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_HIDDEN, false);
            
            //ObjectSetInteger(0, m_rect_names[i], OBJPROP_XDISTANCE, x[i]);
            //int x = i*(m_boxW + m_boxGap);
            //ObjectSetInteger(0, m_rect_names[i], OBJPROP_XDISTANCE, x);
            int x = m_leftMargin + i*(m_box_width + m_box_gap);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_XDISTANCE, x);
        
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_YDISTANCE, y1);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_XSIZE, m_box_width);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_YSIZE, m_box_height);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BGCOLOR, m_colors[i]);
            //ObjectSetInteger(0, m_rect_names[i], OBJPROP_COLOR, clrBlack);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BORDER_COLOR, clrBlack);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BORDER_TYPE, BORDER_FLAT);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
            ObjectSetInteger(0, m_rect_names[i], OBJPROP_BACK, false);
            //ObjectSetInteger(0, m_rect_names[i], OBJPROP_HIDDEN, false);
            ObjectSetString(0, m_rect_names[i], OBJPROP_TOOLTIP, "Regime Box - " + m_labels[i]);
         }
      }

      CreateTextLabels(y2);
      ChartRedraw();
      return true;
   }

   void SetLabels(string l0, string l1, string l2, string l3)
      {
         m_labels[0] = l0;
         m_labels[1] = l1;
         m_labels[2] = l2;
         m_labels[3] = l3;
      }

   string GetLabel(int index)
   {
      return (index >= 0 && index < 4) ? m_labels[index] : "";
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

void UpdateBoxes(CArrayObj *history)
{
   if(history == NULL || history.Total() == 0)
      return;

   int boxCount = MathMin(history.Total(), 4);

   for(int i = 0; i < boxCount; i++)
   {
      //CZoneInfo *zone = (CZoneInfo *)history.At(boxCount - 1 - i);  // incorrect casting of pointers
      CObject *obj = history.At(boxCount - 1 - i);
      CZoneInfo *zone = dynamic_cast<CZoneInfo *>(obj);
      if (zone == NULL) {
         Print("⚠️ Zone at index ", i, " is not a valid CZoneInfo object.");
         continue; // skip invalid entry
      }
      
      string boxName = m_prefix + "Box_" + IntegerToString(i);

      int regimeType = zone.GetRegimeType();           // 🧠 your getter method
      string labelText = GetLabel(i) + "\n" + zone.RegimeTag();

      color boxColor = regimeType == REGIME_SELL ? clrRed :
                       regimeType == REGIME_BUY   ? clrLime : clrSlateGray;

      bool success = ObjectCreate(0, boxName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      if (!success)
         PrintFormat("❌ Failed to create box [%s]", boxName);
      else
         PrintFormat("✅ Created box [%s]", boxName);


      ObjectSetInteger(0, boxName, OBJPROP_XDISTANCE, m_box_gap + i * (m_box_width + m_box_gap));
      ObjectSetInteger(0, boxName, OBJPROP_YDISTANCE, m_yOffset);
      ObjectSetInteger(0, boxName, OBJPROP_WIDTH, m_box_width);
      ObjectSetInteger(0, boxName, OBJPROP_YSIZE, m_box_height); // ✅ valid

      //ObjectSetInteger(0, boxName, OBJPROP_COLOR, boxColor);
      ObjectSetString(0, boxName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, boxName, OBJPROP_CORNER, CORNER_LEFT_UPPER);

      //AUDIT THIS
      /*
      ObjectSetInteger(0, boxName, OBJPROP_XSIZE, m_box_width);
      ObjectSetInteger(0, boxName, OBJPROP_YSIZE, m_box_height);
      ObjectSetInteger(0, boxName, OBJPROP_XDISTANCE, 10 + i * 130);  // Spread across
      ObjectSetInteger(0, boxName, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(0, boxName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, boxName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, boxName, OBJPROP_COLOR, ColorToARGB(zoneColor));  // Define zoneColor earlier
      ObjectSetInteger(0, boxName, OBJPROP_HIDDEN, false);
      */


   }
}


//+------------------------------------------------------------------+
//| Draw a pixel-anchored label between box index `betweenSlot–1`   |
//| and `betweenSlot`.                                              |
//+------------------------------------------------------------------+
void DrawSpacer(string text = "⇄ H1 vs M5 ⇄", int betweenSlot = 2)
{
   // Build the object name
   string spacerName = m_prefix + "Spacer";

   // 1) Compute text width (approximate via font size & characters)
   int fontSize = m_fontSize;          
   int textW    = StringLen(text) * (fontSize / 2);  

   // 2) X-position = your leftMargin + betweenSlot * slotWidth – half text
   int slotWidth = m_box_width + m_box_gap;
   int x = m_leftMargin 
         + betweenSlot * slotWidth 
         - (textW / 2);
   int y     = m_top_margin + m_box_height + 10;  // just below labels

   // six-param ObjectCreate for pixel objects
   if(ObjectCreate(
         0,
         spacerName,
         OBJ_LABEL,
         m_subwindow,
         TimeCurrent(),
         0
      ))
   {
      ObjectSetInteger(0, spacerName, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, spacerName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, spacerName, OBJPROP_YDISTANCE, y);
      ObjectSetString (0, spacerName, OBJPROP_TEXT,      text);
      //ObjectSetInteger(0, spacerName, OBJPROP_COLOR,     clrGold);
      ObjectSetInteger(0, spacerName, OBJPROP_FONTSIZE,  12);
      ObjectSetInteger(0, spacerName, OBJPROP_BACK,      false);
   }
}





   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
      if(id == CHARTEVENT_CHART_CHANGE && m_initialized)
         Create();
   }
};

//+------------------------------------------------------------------+
//| Draw the 4 text labels underneath each box                       |
//+------------------------------------------------------------------+
void CStationaryRectangles4Box::CreateTextLabels(int y_base)
{
   // vertical position for all labels
   int labelY = y_base + 10;

   for(int i = 0; i < 4; i++)
   {
      // pull the object name from your array
      string labelName = m_label_names[i];

      // create it (or reposition if it already exists)
      if(ObjectCreate(0, labelName, OBJ_LABEL, m_subwindow, 0, 0))
      {
         // set font size before measuring
         ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, m_fontSize);

         // compute the box’s left-X
         int rectX = m_leftMargin + i * (m_box_width + m_box_gap);

         // measure text width (approx)
         int textW = StringLen(m_labels[i]) * (m_fontSize / 2);

         // center text inside the box
         int labelX = rectX + (m_box_width - textW) / 2;

         ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, labelX);
         ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, labelY);
         ObjectSetString (0, labelName, OBJPROP_TEXT,       m_labels[i]);
         //ObjectSetInteger(0, labelName, OBJPROP_COLOR,      clrWhite);
         ObjectSetInteger(0, labelName, OBJPROP_BACK,       false);
      }
   }
}



#endif
