#include <stdio.h>

#include <lua.h>
#include <lauxlib.h>

#include <plist/plist.h>

#include "springboard_api.h"
#include "springboard.h"

static const char kNextRefKey[] = "__next_ref";

void pushItemStoreHandle(lua_State* L)
{
  lua_newuserdatauv(L, 0, 1);
  luaL_getmetatable(L, kItemStoreHandleID);
  lua_setmetatable(L, -2);

  lua_newtable(L);
  lua_pushinteger(L, 1);
  lua_setfield(L, -2, kNextRefKey);
  lua_setiuservalue(L, -2, 1);
}

int itemStoreHandle_gc(lua_State* L)
{
  if (lua_getiuservalue(L, 1, 1) != LUA_TTABLE) {
    lua_pop(L, 1);
    return 0;
  }

  lua_pushnil(L);
  while (lua_next(L, -2) != 0) {
    if (lua_islightuserdata(L, -1)) {
      plist_free((plist_t)lua_touserdata(L, -1));
    }
    lua_pop(L, 1);
  }

  lua_pop(L, 1);
  return 0;
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
                         int handleIdx,
                         plist_t item) {
  plist_t storedItem;
  const char* k;

  handleIdx = lua_absindex(L, handleIdx);
  if (lua_getiuservalue(L, handleIdx, 1) != LUA_TTABLE) {
    luaL_error(L, "invalid item store handle");
  }

  pushNextItemRef(L);
  if (lua_type(L, -2) != LUA_TTABLE) {
    luaL_error(L, "registry stack corruption before store");
  }
  k = lua_tostring(L, -1);
  storedItem = plist_copy(item);
  lua_pushlightuserdata(L, (void *)storedItem);
  lua_setfield(L, -3, k);
  lua_remove(L, -2); // remove item store, leave ref on stack
}

plist_t retrieveItemFromRegistry(lua_State* L,
                                 int handleIdx,
                                 const char* ref) {
  plist_t node = NULL;

  handleIdx = lua_absindex(L, handleIdx);
  if (lua_getiuservalue(L, handleIdx, 1) != LUA_TTABLE) {
    luaL_error(L, "invalid item store handle");
  }

  lua_getfield(L, -1, ref);
  node = lua_touserdata(L, -1);
  lua_pop(L, 2); // pop off item, store

  return node;
}
