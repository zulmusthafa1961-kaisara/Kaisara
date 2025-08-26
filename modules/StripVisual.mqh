#ifndef __STRIP_VISUAL_MQH__
#define __STRIP_VISUAL_MQH__

//+------------------------------------------------------------------+
//| StripVisual.mqh                                                  |
//| Manages regime strip creation via CStationaryRectangles4Box      |
//+------------------------------------------------------------------+
#property strict


#include "UnifiedRegimeModulesmqh.mqh"
class CRegimePhaseDetector;
class CStationaryRectangles4Box;



enum RegimePhase {
   PHASE_NONE,
   PHASE_BREAKOUT,
   PHASE_CHOPPY,
   PHASE_PULLBACK,
   PHASE_CONTINUATION
};

string RegimePhaseToString(RegimePhase phase)
{
   switch (phase) {
      case PHASE_BREAKOUT:     return "BRK";
      case PHASE_PULLBACK:     return "PBK";
      case PHASE_CONTINUATION: return "TRC";
      default:                 return "UNK";
   }
}


string StripModeToLabel(StripMode mode) {
   switch(mode) {
      case MODE_H1_ZONE:      return "H1 Zone";
      case MODE_M5_ZONE:      return "M5 Zone";
      case MODE_REGIME_PHASE: return "Regime Phase";
      default:                return "Unknown";
   }
}






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
   CStationaryRectangles4Box m_box;

private:
   //string prefix;
   int subwin;
   int chart_id;
   StripMode mode;
   int leftMargin;   

public:
   void SetLeftMargin(int px) {
   m_box.SetLeftMargin(px);
}

public:
   
   void RenderToChart(int renderIndex,
                      color zoneColor,
                      string zoneLabel,
                      datetime t_start,
                      datetime t_end);

   void RenderStrip(CZoneCSV *zone);  // ✅ Add this
   CArrayObj *FilterRecentValidZones(CArrayObj *zones);  // ✅ Must be here


public:
   void RenderBreakoutOverlay(CArrayObj *validZones);
   void RenderPullbackOverlay(CArrayObj *validZones);
   void RenderContinuationOverlay(CArrayObj *validZones);

public:
   CArrayObj *FilterRecentValidM5Zones(CArrayObj *pFusedZones);   

   // part was
   // Unified constructor with default values
   //CStripVisual(const string prefix, const int subwindow = 1, const int alignment = 0)
   //  : m_prefix(prefix), m_subwindow(subwindow), m_alignRight(alignment) {}

public:
   // change to :
   CStripVisual(string _prefix, int _subwin, int _chart_id, StripMode _mode) {
      m_prefix = _prefix;
      m_subwindow = _subwin;
      chart_id = _chart_id;
      mode = _mode;

      switch(mode) {
         case MODE_H1_ZONE:      leftMargin = 20; break;
         case MODE_M5_ZONE:      leftMargin = 350; break;
         case MODE_REGIME_PHASE:  leftMargin = 680; break;
      }
   }     


// new unified render method
void RenderOverlay(int phase, CArrayObj *pFusedZones, CRegimePhaseDetector &detector) {

   // ✅ Timestamp gating
   datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0); 
   if(currentBarTime > TimeCurrent()) {
      Print("⛔ Look-ahead violation blocked at ", TimeToString(currentBarTime));
      return;
   }

   // ✅ Confidence filtering
   double confidence = detector.BiasConfidence();
   if(confidence < 0.5) {
      Print("⚠️ Confidence too low (", DoubleToString(confidence, 2), ") — overlay suppressed");
      return;
   }

   // ✅ Zone filtering via CStripVisual
   CStripVisual stripRenderer("SR5_", 1, 0, MODE_M5_ZONE);
   CArrayObj *validZones = stripRenderer.FilterRecentValidM5Zones(pFusedZones);
   if(validZones == NULL || validZones.Total() == 0) {
      Print("🚫 No valid zones to render for phase ", phase);
      return;
   }

   // ✅ Audit logging
   Print("🖌️ Rendering overlay for phase ", phase, " with ", validZones.Total(), " zones");

   // ✅ Phase-specific rendering via unified dispatcher
   switch(phase) {
      case PHASE_BREAKOUT:
         //RenderZones(validZones, "Breakout");
         RenderZones(stripRegimeBox, validZones, "Breakout");

         break;
      case PHASE_PULLBACK:
         RenderZones(stripRegimeBox,validZones, "Pullback");
         break;
      case PHASE_CONTINUATION:
         RenderZones(stripRegimeBox,validZones, "Continuation");
         break;
      case PHASE_CHOPPY:
         RenderZones(stripRegimeBox,validZones, "Choppy");
         break;
   case PHASE_NONE:
      Print("⚠️ Phase is NONE — no overlay rendered");
      break;
   default:
      Print("⚠️ Unknown phase: ", phase);
   }
}

color GetPhaseColor(string phaseLabel) {
   if (phaseLabel == "Breakout")      return clrDodgerBlue;
   if (phaseLabel == "Pullback")      return clrOrange;
   if (phaseLabel == "Continuation")  return clrLimeGreen;
   if (phaseLabel == "Choppy")        return clrRed;
   if (phaseLabel == "Neutral")       return clrSilver;
   return clrGray;
}

string GetPhaseStyle(string phaseLabel) {
   if (phaseLabel == "Breakout")      return "Solid";
   if (phaseLabel == "Pullback")      return "Dashed";
   if (phaseLabel == "Continuation")  return "Dotted";
   if (phaseLabel == "Choppy")        return "DashDot";
   if (phaseLabel == "Neutral")       return "DashDotDot";
   return "Default";
}

int StyleToInt(string style) {
   if (style == "Solid")       return STYLE_SOLID;
   if (style == "Dashed")      return STYLE_DASH;
   if (style == "Dotted")      return STYLE_DOT;
   if (style == "DashDot")     return STYLE_DASHDOT;
   if (style == "DashDotDot")  return STYLE_DASHDOTDOT;
   return STYLE_SOLID;
}

/*
void RenderZones(CArrayObj *zones, string phaseLabel) {
   if (zones == NULL || zones.Total() == 0) return;

   for (int i = 0; i < zones.Total(); i++) {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;
      if (zone.t_start <= 0 || zone.t_end <= zone.t_start) continue;

      // Style selection
      color zoneColor = GetPhaseColor(phaseLabel);
      string zoneStyle = GetPhaseStyle(phaseLabel);

      // Render zone
      stripRegime.Draw(name, time, stripColor, alignLeft);

   }
}
*/

void RenderZones(CStationaryRectangles4Box &box, CArrayObj *zones, string phaseLabel) {
   if (zones == NULL || zones.Total() == 0) return;

   for (int i = 0; i < zones.Total(); i++) {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;
      if (zone.t_start <= 0 || zone.t_end <= zone.t_start) continue;

      // Style selection
      color zoneColor = GetPhaseColor(phaseLabel);
      string zoneStyle = GetPhaseStyle(phaseLabel);

      // Define rendering parameters
      string name = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
              // or some identifier
      datetime time = zone.t_start;           // or midpoint
      color stripColor = zoneColor;
      bool alignLeft = true;                  // or based on phase logic

      // Render using external box
      box.Draw(name, time, stripColor, alignLeft);
   }
}


// Add other methods as needed...
};

// new
void RenderRegimePhaseOverlay(RegimePhase phase, double confidence) {
   const int subwin = 1;           // Subwindow 1 for diagnostic overlays
   const int leftMargin = 680;     // Right strip for regime phase
   string label[4] = {"BREAKOUT", "CHOPPY", "PULLBACK", "CONTINUATION"};
   string content[4];
   color boxColor[4] = {clrGray, clrGray, clrGray, clrGray};

   for(int i = 0; i < 4; i++) {
      content[i] = label[i] + "\nConfidence: " + DoubleToString(confidence, 2);
   }

   switch(phase) {
      case PHASE_BREAKOUT:      boxColor[0] = clrGreen; break;
      case PHASE_CHOPPY:        boxColor[1] = clrOrange; break;
      case PHASE_PULLBACK:      boxColor[2] = clrRed; break;
      case PHASE_CONTINUATION:  boxColor[3] = clrBlue; break;
   }

   CStationaryRectangles4Box box;
   box.SetSubWindow(subwin);
   box.SetLeftMargin(leftMargin);
   box.SetBoxGap(BOX_GAP);
   box.SetBoxDimensions(BOX_W, BOX_H);
   box.SetTopMargin(TOP_MARGIN);
   box.Initialize();
   box.ClearBoxes();
   box.Create();
   box.UpdateLabels(content[0], content[1], content[2], content[3]);
   box.UpdateColors(boxColor[0], boxColor[1], boxColor[2], boxColor[3]);
}


// Diagnostic-only rendering (prints metadata)
   void CStripVisual::RenderStrip(CZoneCSV *zone)
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
void CStripVisual:: RenderToChart(int renderIndex,
                   color zoneColor,
                   string zoneLabel,
                   datetime t_start,
                   datetime t_end)
{
   Print(__FUNCTION__ + " RenderToChart() in process ...");

   int spacing = BOX_W + BOX_GAP;
   int _leftMargin;  // ✅ Declare here
   bool rightAligned = false;

   if (rightAligned)
   {
      long chartWidth;
      ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chartWidth);
      _leftMargin = (int) chartWidth - ((renderIndex + 1) * spacing);
   }
   else
   {
      _leftMargin = 10 + renderIndex * spacing;
   }

   CStationaryRectangles4Box box;
   DrawBoxStrip(box, _leftMargin, zoneColor, zoneLabel,
                "Regime", TimeToString(t_start), TimeToString(t_end));
}


///////////////////////////////////////////////////
// FilterRecentValidZones
///////////////////////////////////////////////////
CArrayObj *CStripVisual::FilterRecentValidZones(CArrayObj *zones)
{
   if (zones == NULL || zones.Total() == 0)
      return NULL;

   datetime anchorTime = iTime(_Symbol, PERIOD_H1, 0); // Most recent H1 close
   CArrayObj *filtered = new CArrayObj;

   // Traverse from end to start to get most recent zones
   for (int i = zones.Total() - 1; i >= 0 && filtered.Total() < 4; i--)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      // Look-ahead filter: only include zones that start after H1 close
      if (zone.t_start <= anchorTime)
         filtered.Add(zone);
   }

   // Optional: restore chronological order
   filtered.Sort(); // If available

   return filtered;
}

///////////////////////////////////////////////////
// FilterRecentValidZones
///////////////////////////////////////////////////

///////////////////////////////////////////////////
// FilterRecentValidZones
///////////////////////////////////////////////////
CArrayObj *CStripVisual::FilterRecentValidM5Zones(CArrayObj *zones)
{
   if (zones == NULL || zones.Total() == 0)
      return NULL;

   datetime anchorTime = iTime(_Symbol, PERIOD_M5, 0); // Most recent H1 close
   CArrayObj *filtered = new CArrayObj;

   // Traverse from end to start to get most recent zones
   for (int i = zones.Total() - 1; i >= 0 && filtered.Total() < 4; i--)
   {
      CZoneCSV *zone = (CZoneCSV *)zones.At(i);
      if (zone == NULL) continue;

      // Look-ahead filter: only include zones that start after H1 close
      if (zone.t_start <= anchorTime)
         filtered.Add(zone);
   }

   // Optional: restore chronological order
   filtered.Sort(); // If available

   return filtered;
}


CZoneCSV *TagZoneWithConfidence(CRegimePhaseDetector &detector, const CZoneCSV &validatedZone)
{
   CZoneCSV *zone = new CZoneCSV();
   if (zone == NULL) return NULL;

   // Preserve validated timestamps and metadata
   zone.t_start    = validatedZone.t_start;
   zone.t_end      = validatedZone.t_end;
   zone.csv_index  = validatedZone.csv_index;
   zone.regime     = validatedZone.regime;

   // Enrich with detector metadata (non-invasive)
   zone.confidence = detector.BiasConfidence();  // Optional: regime-specific confidence

   // Optional: carry over fingerprint if precomputed
   zone.SetFingerprint(validatedZone.fingerprint());

   return zone;
}


CArrayObj *FilterRecentM5ZonesNew(CArrayObj *source) {
   if(source == NULL || source.Total() == 0) return NULL;

   CArrayObj *filtered = new CArrayObj;

   for(int i = 0; i < source.Total(); i++) {
      CZoneCSV *z = (CZoneCSV *)source.At(i);
      if(z == NULL) continue;
      if(z.t_end <= TimeCurrent()) {
         filtered.Add(z);
      }
   }

   return filtered;
}


void RenderBreakoutOverlay(CArrayObj *validZones) {
   if(validZones == NULL || validZones.Total() < 4) return;

   // Optional: filter zones tagged as breakout
   CArrayObj *filtered = new CArrayObj;
   for(int i = 0; i < validZones.Total(); i++) {
      CZoneCSV *z = (CZoneCSV *)validZones.At(i);
      if(z == NULL) continue;
      if(z.GetPhase() == PHASE_BREAKOUT) filtered.Add(z);
   }

   RenderRecentZones(filtered);
   delete filtered;
}

void RenderPullbackOverlay(CArrayObj *validZones) {
   if(validZones == NULL || validZones.Total() < 4) return;

   // Optional: filter zones tagged as breakout
   CArrayObj *filtered = new CArrayObj;
   for(int i = 0; i < validZones.Total(); i++) {
      CZoneCSV *z = (CZoneCSV *)validZones.At(i);
      if(z == NULL) continue;
      if(z.GetPhase() == PHASE_PULLBACK) filtered.Add(z);
   }

   RenderRecentZones(filtered);
   delete filtered;
}

void RenderContinuationOverlay(CArrayObj *validZones) {
   if(validZones == NULL || validZones.Total() < 4) return;

   // Optional: filter zones tagged as breakout
   CArrayObj *filtered = new CArrayObj;
   for(int i = 0; i < validZones.Total(); i++) {
      CZoneCSV *z = (CZoneCSV *)validZones.At(i);
      if(z == NULL) continue;
      if(z.GetPhase() == PHASE_CONTINUATION) filtered.Add(z);
   }

   RenderRecentZones(filtered);
   delete filtered;
}




//////////////////////////////////////////////////////
// clean up rendering box   ; render once only
//////////////////////////////////////////////////////
void RenderRecentM5Zones(CArrayObj *validZones)
{
   //  Step 1: uses validZones which already Filter zones by t_start ≤ currentTime 
   
   if (validZones == NULL || validZones.Total() < 4)
      return;

   string label[4], startStr[4], endStr[4], priceStr[4], regimeStr[4];
   color zoneColor[4];


   // Step 2: Collect all info from zones
   for (int i = 0; i < 4; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;

      label[i]     = "L" + IntegerToString(i);
      startStr[i]  = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      endStr[i]    = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);
      priceStr[i]  = StringFormat("low = %.2f | high = %.2f", zone.price_low, zone.price_high);
      regimeStr[i] = EnumToString(zone.GetRegime());

      zoneColor[i] = clrGray;
      if (zone.GetRegime() == REGIME_BUY)  zoneColor[i] = clrGreen;
      else if (zone.GetRegime() == REGIME_SELL) zoneColor[i] = clrRed;
   }

   // Step 3: Fingerprint gating
   static string lastFingerprintConcat = "";
   string currentFingerprintConcat = "";

   for (int i = 0; i < 4; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;
      currentFingerprintConcat += zone.fingerprint();
   }

   datetime currentTime = iTime(_Symbol, PERIOD_M5, 0);  // Current H1 candle close
   LogRecentZoneDiagnostics(PERIOD_M5,currentTime, validZones, currentFingerprintConcat, lastFingerprintConcat);

   if (currentFingerprintConcat == lastFingerprintConcat)
   {
      //Print("🔁 No change in recent zone fingerprints. Skipping rendering.");
      return;
   }

   lastFingerprintConcat = currentFingerprintConcat;


   // Step 4: Clear previous rendering
   CStationaryRectangles4Box boxM5("SR5_");
   int m_subwindow = 1;
   boxM5.SetSubWindow(m_subwindow);
   boxM5.SetLeftMargin(LEFT_MARGIN_MIDDLE_STRIP);
   boxM5.SetBoxGap(BOX_GAP);
   boxM5.SetBoxDimensions(BOX_W, BOX_H);
   boxM5.SetTopMargin(TOP_MARGIN);
   boxM5.Initialize();
   boxM5.ClearBoxes();

   // Step 5: Render once
   boxM5.Create();
   boxM5.UpdateLabels(
      label[0] + "\n" + startStr[0] + "\n" + endStr[0] + "\n" + priceStr[0] + "\n" + regimeStr[0],
      label[1] + "\n" + startStr[1] + "\n" + endStr[1] + "\n" + priceStr[1] + "\n" + regimeStr[1],
      label[2] + "\n" + startStr[2] + "\n" + endStr[2] + "\n" + priceStr[2] + "\n" + regimeStr[2],
      label[3] + "\n" + startStr[3] + "\n" + endStr[3] + "\n" + priceStr[3] + "\n" + regimeStr[3]
   );

   boxM5.UpdateColors(zoneColor[0], zoneColor[1], zoneColor[2], zoneColor[3]);

   // Step 6: Clean up
   delete validZones;
}

/*
void CStripVisual::RenderOverlay(int phase, CRegimePhaseDetector &detector) {
   // ✅ Timestamp gating
   datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0); 
   if(currentBarTime > TimeCurrent()) {
      Print("⛔ Look-ahead violation blocked at ", TimeToString(currentBarTime));
      return;
   }

   // ✅ Confidence filtering
   double confidence = detector.BiasConfidence();
   if(confidence < 0.5) {
      Print("⚠️ Confidence too low (", DoubleToString(confidence, 2), ") — overlay suppressed");
      return;
   }

   // ✅ Audit logging
   Print("🖌️ Rendering overlay for phase ", phase, " at ", TimeToString(currentBarTime));

   // ✅ Phase dispatch
   switch(phase) {
      case PHASE_BREAKOUT:
         RenderBreakoutOverlay();
         break;
      case PHASE_PULLBACK:
         RenderPullbackOverlay();
         break;
      case PHASE_CONTINUATION:
         RenderContinuationOverlay();
         break;
      default:
         Print("❓ Unknown phase ", phase, " — no overlay rendered");
         break;
   }

}
*/

///////////////////////////////////////////////////////////////////////////
// working with several passes 
///////////////////////////////////////////////////////////////////////////

/*
void CStripVisual::RenderRecentZonesWorkingButNotElegant(CArrayObj *zones)
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

   LogRecentZoneDiagnostics(PERIOD_H1,currentTime, validZones, currentFingerprintConcat, lastFingerprintConcat);

   if (currentFingerprintConcat == lastFingerprintConcat)
   {
      //Print("🔁 No change in recent zone fingerprints. Skipping rendering.");
      return;
   }

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
    string label[4];
    string startStr[4];
    string endStr[4];
    string priceStr[4];
    string regimeStr[4];
    color zoneColor[4];


   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;

      label[i-start]     = "L" + IntegerToString(labelIndex);
      startStr[i-start]  = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      endStr[i-start]    = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);
      priceStr[i-start]  = StringFormat("low = %.2f | high = %.2f", zone.price_low, zone.price_high);
      regimeStr[i-start] = EnumToString(zone.GetRegime());

      zoneColor[i-start] = clrGray;
      if (zone.GetRegime() == REGIME_BUY) zoneColor[i-start] = clrGreen;
      else if (zone.GetRegime() == REGIME_SELL) zoneColor[i-start] = clrRed;

      box.Create();
      box.UpdateLabels(label[0], startStr[0], endStr[0], priceStr[0] + " | " + regimeStr[0]);
      box.UpdateColors(zoneColor[0], zoneColor[1], zoneColor[2], zoneColor[3]);

      labelIndex++;
   }
      //box.Create();
      //box.UpdateLabels(label, startStr, endStr, priceStr + " | " + regimeStr);
      //box.UpdateColors(zoneColor, zoneColor, zoneColor, zoneColor);

   delete validZones;
}
*/

/*
// already debugged but not elegant enough because renderining 4 passess
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

   LogRecentZoneDiagnostics(currentTime, validZones, currentFingerprintConcat, lastFingerprintConcat);

   if (currentFingerprintConcat == lastFingerprintConcat)
   {
      Print("🔁 No change in recent zone fingerprints. Skipping rendering.");
      return;
   }

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
    string label[4];
    string startStr[4];
    string endStr[4];
    string priceStr[4];
    string regimeStr[4];
    color zoneColor[4];


   for (int i = start; i < total; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;

      label[i-start]     = "L" + IntegerToString(labelIndex);
      startStr[i-start]  = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      endStr[i-start]    = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);
      priceStr[i-start]  = StringFormat("low = %.2f | high = %.2f", zone.price_low, zone.price_high);
      regimeStr[i-start] = EnumToString(zone.GetRegime());

      zoneColor[i-start] = clrGray;
      if (zone.GetRegime() == REGIME_BUY) zoneColor[i-start] = clrGreen;
      else if (zone.GetRegime() == REGIME_SELL) zoneColor[i-start] = clrRed;

      box.Create();
      box.UpdateLabels(label[0], startStr[0], endStr[0], priceStr[0] + " | " + regimeStr[0]);
      box.UpdateColors(zoneColor[0], zoneColor[1], zoneColor[2], zoneColor[3]);

      labelIndex++;
   }
      //box.Create();
      //box.UpdateLabels(label, startStr, endStr, priceStr + " | " + regimeStr);
      //box.UpdateColors(zoneColor, zoneColor, zoneColor, zoneColor);

   delete validZones;
}
*/

void LogRecentZoneDiagnostics(ENUM_TIMEFRAMES tf,
                              datetime currentTime,
                              CArrayObj *validZones,
                              string currentFingerprintConcat,
                              string lastFingerprintConcat)
{
   Print("📍 Diagnostic: RenderRecentZones()");
   Print(EnumToString(tf) + " 🕒 Current candle close: ", TimeToString(currentTime, TIME_DATE | TIME_MINUTES));
   Print(EnumToString(tf) + " 🔍 Current Fingerprint Concat: ", currentFingerprintConcat);
   Print(EnumToString(tf) + " 🔍 Last Fingerprint Concat: ", lastFingerprintConcat);

   if (validZones == NULL || validZones.Total() == 0)
   {
      Print("⚠️ No valid zones to render.");
      return;
   }

   ///////////////////
   int total = validZones.Total();
   int start = MathMax(0, total - 4);

   PrintFormat("%s 🧪 most recent %d valid zones (t_start ≤ %s):", EnumToString(tf),total - start,  TimeToString(currentTime, TIME_DATE | TIME_MINUTES));
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
      Print(EnumToString(tf) + " : No change in recent zone fingerprints. Skipping rendering.");
   else
      Print(EnumToString(tf) + " : Zone composition changed. Proceeding with rendering.");
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
      int m_subwindow = 1;
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
//}

/*
CArrayObj *CStripVisual::FilterRecentValidM5Zones(CArrayObj *pFusedZones) {
   if(pFusedZones == NULL || pFusedZones.Total() == 0) {
      Print("🚫 No fused zones provided");
      return NULL;
   }

   CArrayObj *validZones = new CArrayObj;
   datetime now = TimeCurrent();

   for(int i = 0; i < pFusedZones.Total(); i++) {
      CZoneCSV *zone = (CZoneCSV *)pFusedZones.At(i);
      if(zone == NULL) continue;

      if(zone.t_start >= TimeCurrent()) continue; // ⛔ Look-ahead gating

      if(zone.Confidence() < 0.5) continue;           // ⚠️ Confidence filtering

      validZones.Add(zone);
   }

   Print("✅ Filtered ", validZones.Total(), " valid M5 zones");
   return validZones;
}
*/


#endif


//////////////////////////////////////////////////////
// clean up rendering box   ; render once only
//////////////////////////////////////////////////////
// This is a helper function. 
void RenderRecentZones(CArrayObj *validZones)
{
   //  Step 1: uses validZones which already Filter zones by t_start ≤ currentTime 
   
   if (validZones == NULL || validZones.Total() < 4)
      return;

   string label[4], startStr[4], endStr[4], priceStr[4], regimeStr[4];
   color zoneColor[4];


   // Step 2: Collect all info from zones
   for (int i = 0; i < 4; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;

      label[i]     = "L" + IntegerToString(i);
      startStr[i]  = TimeToString(zone.t_start, TIME_DATE | TIME_MINUTES);
      endStr[i]    = TimeToString(zone.t_end, TIME_DATE | TIME_MINUTES);
      priceStr[i]  = StringFormat("low = %.2f | high = %.2f", zone.price_low, zone.price_high);
      regimeStr[i] = EnumToString(zone.GetRegime());

      zoneColor[i] = clrGray;
      if (zone.GetRegime() == REGIME_BUY)  zoneColor[i] = clrGreen;
      else if (zone.GetRegime() == REGIME_SELL) zoneColor[i] = clrRed;
   }

   // Step 3: Fingerprint gating
   static string lastFingerprintConcat = "";
   string currentFingerprintConcat = "";

   for (int i = 0; i < 4; i++)
   {
      CZoneCSV *zone = (CZoneCSV *)validZones.At(i);
      if (zone == NULL) continue;
      currentFingerprintConcat += zone.fingerprint();
   }

   datetime currentTime = iTime(_Symbol, PERIOD_H1, 0);  // Current H1 candle close
   LogRecentZoneDiagnostics(PERIOD_H1, currentTime, validZones, currentFingerprintConcat, lastFingerprintConcat);

   if (currentFingerprintConcat == lastFingerprintConcat)
   {
      //Print("🔁 No change in recent zone fingerprints. Skipping rendering.");
      return;
   }

   lastFingerprintConcat = currentFingerprintConcat;


   // Step 4: Clear previous rendering
   CStationaryRectangles4Box box;
   int subwindow = 1; 
   box.SetSubWindow(subwindow);
   box.SetLeftMargin(LEFT_MARGIN);
   box.SetBoxGap(BOX_GAP);
   box.SetBoxDimensions(BOX_W, BOX_H);
   box.SetTopMargin(TOP_MARGIN);
   box.Initialize();
   box.ClearBoxes();

   // Step 5: Render once
   box.Create();
   box.UpdateLabels(
      label[0] + "\n" + startStr[0] + "\n" + endStr[0] + "\n" + priceStr[0] + "\n" + regimeStr[0],
      label[1] + "\n" + startStr[1] + "\n" + endStr[1] + "\n" + priceStr[1] + "\n" + regimeStr[1],
      label[2] + "\n" + startStr[2] + "\n" + endStr[2] + "\n" + priceStr[2] + "\n" + regimeStr[2],
      label[3] + "\n" + startStr[3] + "\n" + endStr[3] + "\n" + priceStr[3] + "\n" + regimeStr[3]
   );

   box.UpdateColors(zoneColor[0], zoneColor[1], zoneColor[2], zoneColor[3]);

   // Step 6: Clean up
   //delete validZones;
}
