#include <stdio.h>

#include <lua.h>
#include <lauxlib.h>

#include <plist/plist.h>

#include "springboard_api.h"
#include "springboard.h"

static const char RegKey = 'k';
static const char kNextRefKey[] = "__next_ref";

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
    lua_pushinteger(L, 1);
    lua_setfield(L, -2, kNextRefKey);
    lua_settable(L, LUA_REGISTRYINDEX);
    uncheckedGetItemStore(L); 
  }
  
  return 1;
}

static void pushNextItemRef(lua_State* L)
{
  char ref[32];
  int storeIdx;
  lua_Integer nextRef;

  storeIdx = lua_absindex(L, -1);
  lua_getfield(L, storeIdx, kNextRefKey);
  nextRef = lua_tointeger(L, -1);
  lua_pop(L, 1);

  lua_pushinteger(L, nextRef + 1);
  lua_setfield(L, storeIdx, kNextRefKey);

  snprintf(ref, sizeof(ref), "item:%lld", (long long)nextRef);
  lua_pushstring(L, ref);
}

void storeItemInRegistry(lua_State* L,
                         plist_t item) {
  const char* k;
  
  getItemStore(L);
  pushNextItemRef(L);
  if (lua_type(L, -2) != LUA_TTABLE) {
    luaL_error(L, "registry stack corruption before store");
  }
  k = lua_tostring(L, -1);
  lua_pushlightuserdata(L, (void *)item);
  lua_setfield(L, -3, k);
  lua_remove(L, -2); // remove item store, leave ref on stack
}

plist_t retrieveItemFromRegistry(lua_State* L,
                                 const char* ref) {
  plist_t node = NULL;
  
  getItemStore(L);
  lua_getfield(L, -1, ref);
  node = lua_touserdata(L, -1);
  lua_pop(L, 2); // pop off item, store

  return node;
}
