#ifndef STRIPVISUAL_MQH
#define STRIPVISUAL_MQH

//+------------------------------------------------------------------+
//| StripVisual.mqh                                                  |
//| Manages regime strip creation via CStationaryRectangles4Box      |
//+------------------------------------------------------------------+
#property strict


#include "UnifiedRegimeModulesmqh.mqh"

// CStripVisual must inherit from CObject
class CStripVisual : public CObject
{
private:
   string m_prefix;
   int    m_subwindow;
      int m_renderIndex;

public: 
   string   label;
   color clr;  // Instead of color color;
   datetime t_start;
   datetime t_end;   

public:
   CStripVisual(const string prefix, const int subwindow = 1)
     : m_prefix(prefix), m_subwindow(subwindow) {}

void SetIndex(int index) { m_renderIndex = index; }
int  GetIndex()          { return m_renderIndex; }   

   
void RenderToChart(bool rightAligned = false)
{
   int leftMargin;
   int spacing = BOX_W + BOX_GAP;

   if (rightAligned)
   {
      long chartWidth;
      //leftMargin = ChartGetInteger(CHART_WIDTH_IN_PIXELS) - ((m_renderIndex + 1) * spacing);
      leftMargin = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chartWidth) - ((m_renderIndex + 1) * spacing);
   }
   else
   {
      leftMargin = 10 + m_renderIndex * spacing;
   }

   CStationaryRectangles4Box box;
   DrawBoxStrip(box, leftMargin, clr, label,
                "Regime", TimeToString(t_start), TimeToString(t_end));
}


  
     void DrawBoxStrip(CStationaryRectangles4Box &boxObj,
                     int left, color col,
                     string a, string b, string c, string d)
   {
      boxObj.SetSubWindow(m_subwindow);
      boxObj.SetLeftMargin(left);
      boxObj.SetBoxGap(BOX_GAP);
      boxObj.SetBoxDimensions(BOX_W, BOX_H);
      boxObj.SetTopMargin(TOP_MARGIN);
      boxObj.SetLabels(a,b,c,d);
      boxObj.Initialize();
      boxObj.ClearBoxes();
      boxObj.Create();
      boxObj.UpdateLabels(a,b,c,d);
      boxObj.UpdateColors(col,col,col,col);
   }
};

#endif