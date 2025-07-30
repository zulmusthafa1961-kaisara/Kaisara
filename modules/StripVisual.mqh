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

public: 
   string   label;
   color clr;  // Instead of color color;
   datetime t_start;
   datetime t_end;   

public:
   CStripVisual(const string prefix, const int subwindow = 1)
     : m_prefix(prefix), m_subwindow(subwindow) {}

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