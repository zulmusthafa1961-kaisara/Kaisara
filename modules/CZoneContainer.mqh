#ifndef __CZONE_CONTAINER__MQH__
#define __CZONE_CONTAINER__MQH__

//#include <Arrays\ArrayObj.mqh>
#include "UnifiedRegimeModulesmqh.mqh"

class CZoneContainer {
 private:
  CArrayObj m_zones;
 public:
  void Add(CRectInfo *zone);
  CRectInfo *Get(int index);
  int Total();
  void Clear(); // Deletes all zones
  void PrintZones(); // Prints all zones to the log
};

void CZoneContainer::Clear() {
  for (int i = 0; i < m_zones.Total(); i++) {
    delete m_zones.At(i);
  }
  m_zones.Clear();
}

void CZoneContainer::PrintZones() {
  for (int i = 0; i < m_zones.Total(); i++) {
    CRectInfo *zone = m_zones.At(i);
    Print("Zone ", i, ": ", zone.ToString()); // Assuming ToString() exists
  }
}


/*
class CZoneContainer : public CObject
  {
private:
   CArrayObj m_data;
   string m_tag;

public:

CArrayObj *GetRaw()
  {
   return &m_data;
  }

 CZoneContainer *CreateSafeContainer()
  {
   CZoneContainer *container = new CZoneContainer;
   return container;
  }
 

   // Add object
   bool Add(CObject *obj)
     {
      return m_data.Add(obj);
     }

   // Get object at index
   CObject *At(const int index)
     {
      return m_data.At(index);
     }

   // Total count
   int Total() const
     {
      return m_data.Total();
     }

   // Clear and delete all objects
   void Clear()
     {
      for(int i = m_data.Total() - 1; i >= 0; i--)
         delete m_data.At(i);
      m_data.Clear();
      Print("Cleared container: ", m_tag);
     }

   // Destructor
   ~CZoneContainer()
     {
      Clear();
     }
  };
*/
  #endif
