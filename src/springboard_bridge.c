#include <stdio.h>

#include <lua.h>
#include <lauxlib.h>

#include "springboard_api.h"
#include "comms.h"
#include "save_load.h"
#include "layout.h"
#include "springboard.h"

static const char* kLuaIndexMetaKey = "__index";

static const luaL_Reg bridge_methods[] = {
  { "connect", ios_connect }, 
  { "ios_errno", ios_errno }, 
  { "load_plist", ios_load_layout_plist },
  { NULL, NULL }
};

static const luaL_Reg item_store_methods[] = {
  { "__gc", itemStoreHandle_gc },
  { NULL, NULL }
};

static const luaL_Reg sbconn_methods[] = {
  { "disconnect", ios_disconnect }, 
  { "layout", ios_get_layout }, 
  { "get_layout", ios_get_layout }, 
  { "save_raw_layout_plist", ios_save_raw_layout_plist },
  { "set_layout", ios_set_layout }, 
  { "app_image", ios_app_imagedata },
  { "wallpaper", ios_wallpaper },
  { "devicename", ios_devicename },
  { "__tostring", conn_tostring }, 
  { NULL, NULL }
};

LUALIB_API int
luaopen_springboard_bridge(lua_State *L)
{
  luaL_newmetatable(L, kItemStoreHandleID);
  luaL_setfuncs(L, item_store_methods, 0);
  lua_pop(L, 1);

  luaL_newmetatable(L, kSpringboardConnID); // connection obj
  lua_pushstring(L, kLuaIndexMetaKey);
  lua_pushvalue(L, -2); /* pushes the metatable */
  lua_settable(L, -3);  /* metatable.__index = metatable */  
  luaL_setfuncs(L, sbconn_methods, 0); // 
  lua_pop(L, 1);  /* pop new metatable */

  luaL_newmetatable(L, kLibraryRegKey);
  luaL_newlib(L, bridge_methods);

  return 1;
}
