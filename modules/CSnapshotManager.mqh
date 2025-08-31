#ifndef __CSNAPSHOTMANAGER_MQH__
#define __CSNAPSHOTMANAGER_MQH__

#include "UnifiedRegimeModulesmqh.mqh"

class CSnapshotManager
{
private:
   CArrayObj *prevSnapshot;
   CArrayObj *lastSnapshot;
   datetime   lastTimestamp;

public:
   CSnapshotManager()
   {
      prevSnapshot   = NULL;
      lastSnapshot   = NULL;
      lastTimestamp  = 0;
   }

   ~CSnapshotManager()
   {
      Clear();
   }

   void Clear()
   {
      if (prevSnapshot != NULL) { delete prevSnapshot; prevSnapshot = NULL; }
      if (lastSnapshot != NULL) { delete lastSnapshot; lastSnapshot = NULL; }
      lastTimestamp = 0;
   }

   void Refresh(CArrayObj *newSnapshot, datetime newTimestamp)
   {
      // Delete previous snapshot
      if (prevSnapshot != NULL)
      {
         Print("🧹 Deleting previous snapshot with timestamp: ", TimeToString(lastTimestamp));
         delete prevSnapshot;
         prevSnapshot = NULL;
      }

      // Shift current to previous
      prevSnapshot   = lastSnapshot;
      lastTimestamp  = newTimestamp;

      // Assign new snapshot
      lastSnapshot   = newSnapshot;

      Print("📦 Snapshot updated: Prev=", TimeToString(lastTimestamp), " | Last=", TimeToString(newTimestamp));
   }

    bool HasValidSnapshot()
    {
    int ptrStatus = CheckPointer(lastSnapshot);
    if (ptrStatus != POINTER_DYNAMIC)
        return false;

    return (lastSnapshot.Total() > 0);
    }


   CArrayObj *GetSnapshot()
   {
      return lastSnapshot;
   }

   datetime GetTimestamp()
   {
      return lastTimestamp;
   }
};

#endif // __CSNAPSHOTMANAGER_MQH__