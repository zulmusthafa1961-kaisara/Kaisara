#ifndef STRIPVISUAL_MQH
#define STRIPVISUAL_MQH

//+------------------------------------------------------------------+
//| StripVisual.mqh                                                  |
//| Manages regime strip creation via CStationaryRectangles4Box      |
//+------------------------------------------------------------------+
#property strict


#include "UnifiedRegimeModulesmqh.mqh"

// CStripVisual must inherit from CObject
//original
/* 
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

void SetRenderIndex(int index)
{
   m_renderIndex = index;
}



void RenderToChart(bool rightAligned = false)
{
   Print(__FUNCTION__ + " RenderToChart() in process ...");

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


void RenderToChart(color zoneColor, string zoneLabel, bool rightAligned = false)
{
      Print(__FUNCTION__ + " RenderToChart() in process ...");

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
   DrawBoxStrip(box, leftMargin, zoneColor, zoneLabel,
                zoneLabel, zoneLabel, zoneLabel);
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
*/

// Constants for box rendering
//already defined somewhere
//#define BOX_W       80
//#define BOX_H       20
//#define BOX_GAP     10
//#define TOP_MARGIN  5

// Stateless CStripVisual Refactor
class CStripVisual : public CObject
{
private:
   string m_prefix;
   int    m_subwindow;
   int    m_alignRight;

public:
   // Unified constructor with default values
   CStripVisual(const string prefix, const int subwindow = 1, const int alignment = 0)
     : m_prefix(prefix), m_subwindow(subwindow), m_alignRight(alignment) {}

   // Diagnostic-only rendering (prints metadata)
   void RenderStrip(CZoneCSV *zone)
   {
      if (zone == NULL || CheckPointer(zone) != POINTER_DYNAMIC) return;

      PrintFormat("🖼️ Rendering zone: %s [%s → %s] Regime: %s",
                  zone.fingerprint(),
                  TimeToString(zone.t_start),
                  TimeToString(zone.t_end),
                  zone.regime);

      // Optional: actual chart rendering if zone has required fields
      RenderToChart(zone.csv_index, zone.GetColor(), zone.fingerprint(),
                    zone.t_start, zone.t_end); //, zone.alignRight);
   }

   // Chart rendering logic
   void RenderToChart(int renderIndex,
                      color zoneColor,
                      string zoneLabel,
                      datetime t_start,
                      datetime t_end)
                      //,bool rightAligned = false)
   {
      Print(__FUNCTION__ + " RenderToChart() in process ...");

      int spacing = BOX_W + BOX_GAP;
      int leftMargin;
      bool rightAligned = false;

      if (rightAligned)
      {
         long chartWidth;
         ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chartWidth);
         leftMargin = (int) chartWidth - ((renderIndex + 1) * spacing);
      }
      else
      {
         leftMargin = 10 + renderIndex * spacing;
      }

      CStationaryRectangles4Box box;
      DrawBoxStrip(box, leftMargin, zoneColor, zoneLabel,
                   "Regime", TimeToString(t_start), TimeToString(t_end));
   }


void CStripVisual::RenderRecentZones(CArrayObj *zones)
{
   if (zones == NULL || zones.Total() == 0) return;

   datetime currentTime = iTime(_Symbol, PERIOD_H1, 0);  // Current H1 candle close

   // Step 1: Filter zones by t_start ≤ currentTime
   CArrayObj *validZones = new CArrayObj;
   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;
      if (zone.t_start <= currentTime)
         validZones.Add(zone);
   }

   int total = validZones.Total();
   int start = MathMax(0, total - 4);

   // Step 2: Fingerprint gating
   static string lastFingerprintConcat = "";
   string currentFingerprintConcat = "";

   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;
      currentFingerprintConcat += zone.fingerprint();
   }

   if (currentFingerprintConcat == lastFingerprintConcat)
   {
      Print("🔁 No change in recent zone fingerprints. Skipping rendering.");
      return;
   }

   LogRecentZoneDiagnostics(currentTime, validZones, currentFingerprintConcat, lastFingerprintConcat);
   lastFingerprintConcat = currentFingerprintConcat;

   // Step 3: Clear previous rendering
   CStationaryRectangles4Box box;
   box.SetSubWindow(m_subwindow);
   box.SetLeftMargin(LEFT_MARGIN);
   box.SetBoxGap(BOX_GAP);
   box.SetBoxDimensions(BOX_W, BOX_H);
   box.SetTopMargin(TOP_MARGIN);
   box.Initialize();
   box.ClearBoxes();

   // Step 4: Render filtered zones
   int labelIndex = 0;
   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;

      string label     = "L" + IntegerToString(labelIndex);
      string startStr  = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      string endStr    = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);
      string priceStr  = StringFormat("low = %.2f | high = %.2f", zone.price_low, zone.price_high);
      string regimeStr = EnumToString(zone.GetRegime());

      color zoneColor = clrGray;
      if (zone.GetRegime() == REGIME_BUY) zoneColor = clrGreen;
      else if (zone.GetRegime() == REGIME_SELL) zoneColor = clrRed;

      box.Create();
      box.UpdateLabels(label, startStr, endStr, priceStr + " | " + regimeStr);
      box.UpdateColors(zoneColor, zoneColor, zoneColor, zoneColor);

      labelIndex++;
   }

   delete validZones;
}

void LogRecentZoneDiagnostics(datetime currentTime,
                              CArrayObj *validZones,
                              string currentFingerprintConcat,
                              string lastFingerprintConcat)
{
   Print("📍 Diagnostic: RenderRecentZones()");
   Print("🕒 Current H1 candle close: ", TimeToString(currentTime, TIME_DATE | TIME_MINUTES));
   Print("🔍 Current Fingerprint Concat: ", currentFingerprintConcat);
   Print("🔍 Last Fingerprint Concat: ", lastFingerprintConcat);

   if (validZones == NULL || validZones.Total() == 0)
   {
      Print("⚠️ No valid zones to render.");
      return;
   }

   ///////////////////
   int total = validZones.Total();
   int start = MathMax(0, total - 4);

   PrintFormat("🧪 Most recent %d valid zones (t_start ≤ %s):", total - start, TimeToString(currentTime, TIME_DATE | TIME_MINUTES));
   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;

      PrintFormat("  └─ Zone[%d] FP=%s Regime=%s Start=%s End=%s Low=%.2f High=%.2f",
                     i,
                     zone.fingerprint(),
                     EnumToString(zone.GetRegime()),
                     TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES),
                     TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES),
                     zone.price_low,
                     zone.price_high);
   }

   //////////////////


   if (currentFingerprintConcat == lastFingerprintConcat)
      Print("🔁 No change in recent zone fingerprints. Skipping rendering.");
   else
      Print("🆕 Zone composition changed. Proceeding with rendering.");
}



/*   
void CStripVisual::RenderRecentZones(CArrayObj *zones)
{
   if (zones == NULL || zones.Total() == 0) return;

   datetime currentTime = iTime(_Symbol, PERIOD_H1, 0);  // Current H1 candle close

   CArrayObj *validZones = new CArrayObj;

   for (int i = 0; i < zones.Total(); i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      if (zone.t_start <= currentTime)
         validZones.Add(zone);
   }

   int total = validZones.Total();
   int start = MathMax(0, total - 4);

   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      // render zone
   }


   static string lastFingerprintConcat = "";

   int total = zones.Total();
   int start = MathMax(0, total - 4);

   string currentFingerprintConcat = "";

   Print("🧪 Validating last 4 zones:");
   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      PrintFormat("Zone[%d] FP=%s Regime=%s Start=%s End=%s Low=%.2f High=%.2f",
                  i,
                  zone.fingerprint(),
                  EnumToString(zone.GetRegime()),
                  TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES),
                  TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES),
                  zone.price_low,
                  zone.price_high);
   }


   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      currentFingerprintConcat += zone.fingerprint();
   }

   Print("🔍 Current Fingerprint Concat: ", currentFingerprintConcat);
   Print("🔍 Last Fingerprint Concat: ", lastFingerprintConcat);

   if (currentFingerprintConcat == lastFingerprintConcat)
   {
      Print("🔁 No change in recent zone fingerprints. Skipping rendering.");
      return;
   }

   lastFingerprintConcat = currentFingerprintConcat;

   // Clear previous rendering
   CStationaryRectangles4Box box;
   box.SetSubWindow(m_subwindow);
   box.SetLeftMargin(LEFT_MARGIN);
   box.SetBoxGap(BOX_GAP);
   box.SetBoxDimensions(BOX_W, BOX_H);
   box.SetTopMargin(TOP_MARGIN);
   box.Initialize();
   box.ClearBoxes();

   // Render recent zones
   int labelIndex = 0;
   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      string label = "L" + IntegerToString(labelIndex);
      string startStr = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      string endStr   = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);
      string priceStr = StringFormat("low = %.2f | high = %.2f", zone.price_low, zone.price_high);

      color zoneColor = (zone.GetRegime() == REGIME_BUY) ? clrGreen : clrRed;

      box.Create();
      box.UpdateLabels(label, startStr, endStr, priceStr);
      box.UpdateColors(zoneColor, zoneColor, zoneColor, zoneColor);

      labelIndex++;
   }
   // Future: insert separator for M5 right strip
   // box.DrawSeparator(STRIP_GAP);  // placeholder
}
*/


   // Stateless box drawing
   void DrawBoxStrip(CStationaryRectangles4Box &boxObj,
                     int left, color col,
                     string a, string b, string c, string d)
   {
      boxObj.SetSubWindow(m_subwindow);
      boxObj.SetLeftMargin(left);
      boxObj.SetBoxGap(BOX_GAP);
      boxObj.SetBoxDimensions(BOX_W, BOX_H);
      boxObj.SetTopMargin(TOP_MARGIN);
      boxObj.SetLabels(a, b, c, d);
      boxObj.Initialize();
      boxObj.ClearBoxes();
      boxObj.Create();
      boxObj.UpdateLabels(a, b, c, d);
      boxObj.UpdateColors(col, col, col, col);
   }
};



#endif