#include <stdio.h>

#include <lua.h>
#include <lauxlib.h>

#include <plist/plist.h>

#include "springboard_api.h"

#define NEVER_NULL(S) (S == NULL) ? "" : S
static const char RegKey = 'k';

static int uncheckedGetItemStore(lua_State* L) {
  lua_pushlightuserdata(L, (void *)&RegKey);
  lua_gettable(L, LUA_REGISTRYINDEX);
  return 1;    
}

static int getItemStore(lua_State* L) {
  uncheckedGetItemStore(L);
  if (lua_isnoneornil(L, -1)) {
    lua_pop(L, 1); 
    lua_pushlightuserdata(L, (void *)&RegKey);
    lua_newtable(L);
    lua_settable(L, LUA_REGISTRYINDEX);
    uncheckedGetItemStore(L); 
  }
  
  return 1;
}

void makeItemRegistryKey(lua_State* L,
                         const char* name,
                         const char* id) {
  luaL_Buffer B;
  luaL_buffinit(L, &B);
  luaL_addstring(&B, NEVER_NULL((char*)name));
  luaL_addchar(&B, '.');
  luaL_addstring(&B, NEVER_NULL((char*)id));
  luaL_pushresult(&B);
}

void storeItemInRegistry(lua_State* L,
                         plist_t item,
                         const char* name,
                         const char* id) {
  const char* k;
  
  getItemStore(L);
  makeItemRegistryKey(L, name, id);
  k = lua_tostring(L, -1);
  lua_pushlightuserdata(L, (void *)item);
  lua_setfield(L, -3, k);
  lua_pop(L, 2); // pop off item store and RegKey
}

plist_t retrieveItemFromRegistry(lua_State* L,
                                 const char* name,
                                 const char* id) {
  plist_t node = NULL;
  
  getItemStore(L);
  makeItemRegistryKey(L, name, id);
  lua_getfield(L, -2, lua_tostring(L, -1));
  node = lua_touserdata(L, -1);
  lua_pop(L, 3); // pop off item, RegKey, store

  return node;
}
