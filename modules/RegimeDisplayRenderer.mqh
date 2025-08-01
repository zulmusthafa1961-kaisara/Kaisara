//+------------------------------------------------------------------+
//|                                        RegimeDisplayRenderer.mqh |
//| Minimal regime renderer for EA visual spacing                    |
//+------------------------------------------------------------------+
#ifndef __REGIMEDISPLAYRENDERER_MQH__
#define __REGIMEDISPLAYRENDERER_MQH__

class RegimeDisplayRenderer {
private:
   int m_spacing;
   int m_yOffset;

public:
   RegimeDisplayRenderer() {
      m_spacing = 10;
      m_yOffset = 10;
   }

   void SetSpacing(int spacing) {
      m_spacing = spacing;
   }

   void SetYOffset(int yOffset) {
      m_yOffset = yOffset;
   }

   int GetSpacing() const {
      return m_spacing;
   }

   int GetYOffset() const {
      return m_yOffset;
   }
};

#endif
