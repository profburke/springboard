#include <stdio.h>
#include <stdlib.h>

#include <lua.h>
#include <lauxlib.h>

#include <plist/plist.h>

#include <libimobiledevice/sbservices.h>

#include "springboard_api.h"
#include "comms.h"
#include "springboard.h"
#include "save_load.h"
#include "layout.h"

static const int kPullRetries = 3;

// pops (and checks) sb connection from top of stack
SBConnection* popConnection(lua_State* L)
{
  SBConnection* c = (SBConnection*)luaL_checkudata(L, -1, kSpringboardConnID);
  if (c->sbClient == NULL) { luaL_error(L, kFailNoConnection); }
  return c;
}

int ios_get_layout(lua_State *L)
{
  int rc, i, connIdx;
  plist_t layoutState;

  SBConnection* c = popConnection(L);
  connIdx = lua_absindex(L, -1);
  
  rc = -1;
  for (i=0; rc != SBSERVICES_E_SUCCESS; i++)
  {
    rc = sbservices_get_icon_state(
          c->sbClient, &layoutState,
          kSpringboardInfoVersion);
    if (i == kPullRetries) { luaL_error(L, "connect error %d", rc); }
  }
  
  if ( (rc = ios_plist_to_table(L, layoutState)) != 1) {
    luaL_error(L, "convert error %d", rc);
  }
  
  // add save plist to layout as a convenience
  lua_pushcfunction(L, ios_save_layout_plist);
  lua_setfield(L, -2, kSavePlistMethodName);

  return rc;
}

int ios_set_layout(lua_State *L)
{
  int rc;
  plist_t layoutState;

  // grab connection info (param 2)
  luaL_checkudata(L, -2, kSpringboardConnID);
  lua_pushvalue(L, -2);
  SBConnection* c = popConnection(L);
  lua_pop(L, 1);
  lua_remove(L, -2); // leaving layout still at top

  layoutState = ios_table_to_plist(L);
  rc = sbservices_set_icon_state(c->sbClient, layoutState);

  if (rc != SBSERVICES_E_SUCCESS) {
    luaL_error(L, "%s, code=%d", kSetLayoutErr, rc);
  }

  lua_pop(L, 1); // conn
  return 0;
}

int
ios_app_imagedata(lua_State* L)
{
  char* pngdata;
  uint64_t pngsize;
  int rc;

  if (lua_isnoneornil(L, -1)) { luaL_error(L, "missing app reference"); }

  lua_getfield(L, -1, kAppleBundleIdKey);
  const char* bundleID = luaL_checkstring(L, -1);
  lua_pop(L, 1);
  lua_pop(L, 1);

  SBConnection* c = popConnection(L);
  lua_pop(L, 1);

  // fprintf(stderr, "loading app image for %s, using %p\n", bundleID, c);
  if ((rc = sbservices_get_icon_pngdata(c->sbClient, 
                                        bundleID, 
                                        &pngdata, 
                                        &pngsize)) 
        != SBSERVICES_E_SUCCESS) { luaL_error(L, "error %d fetching"
                                                 " image", rc); }

  lua_pushlstring(L, pngdata, pngsize);
  free(pngdata);

  return 1;
}


int
ios_wallpaper(lua_State* L)
{
  char *pngdata;
  uint64_t pngsize;
  int rc;

  SBConnection *c = popConnection(L);
  lua_pop(L, 1);

  if ((rc = sbservices_get_home_screen_wallpaper_pngdata(c->sbClient,
                                                         &pngdata,
                                                         &pngsize))
      != SBSERVICES_E_SUCCESS) {
    luaL_error(L, "error %d fetching wallpaper", rc);
  }

  lua_pushlstring(L, pngdata, pngsize);
  free(pngdata);

  return 1;
}

