#ifndef __MAPSTRINGTOPTR_MQH__
#define __MAPSTRINGTOPTR_MQH__

#include "UnifiedRegimeModulesmqh.mqh"
#include <Arrays\ArrayString.mqh>


class CMapStringToPtr {
private:
  CArrayString keys;
  CArrayObj    values; // values must inherit from CObject

public:
  void Add(const string key, CObject* value) {
    keys.Add(key);
    values.Add(value);
  }

  CObject* Get(const string key) {
    for (int i = 0; i < keys.Total(); i++) {
      if (keys.At(i) == key) return values.At(i);

    }
    return NULL;
  }
};



#endif