#include <stdio.h>
#include <lua.h>
#include <lauxlib.h> 

#include <libimobiledevice/libimobiledevice.h>

#include "springboard_api.h"
#include "springboard.h"

int addPageIconsToPList(lua_State* L, plist_t page);
void addIconsToGroup(lua_State* L, plist_t group);

plist_t ios_table_to_plist(lua_State* L)
{
  plist_t layoutState, currentPage;
  int i;
  int len;

  layoutState = plist_new_array();

  if (lua_type(L, -1) != LUA_TTABLE) {
    luaL_error(L, "internal error! can't convert %s to layout", 
                  luaL_typename(L, -1));
  }

  lua_getfield(L, -1, kDockKey);
  if (lua_istable(L, -1)) {
    currentPage = plist_new_array();
    plist_array_append_item(layoutState, currentPage);
    addPageIconsToPList(L, currentPage);
  }
  lua_pop(L, 1);

  lua_getfield(L, -1, kPagesKey);
  len = lua_rawlen(L, -1);
  for (i=1; i< len+1; i++) {
    lua_rawgeti(L, -1, i);

    if (lua_istable(L, -1)) {
      currentPage = plist_new_array();
      plist_array_append_item(layoutState, currentPage);
      addPageIconsToPList(L, currentPage);
    }

    lua_pop(L, 1);
  }
  lua_pop(L, 1);

  return layoutState;
}

plist_t luaToStoredPListItem(lua_State* L)
{
  plist_t pageItem;
  const char* ref;
  int handleType;

  lua_getfield(L, -1, kItemRef);
  ref = lua_tostring(L, -1);
  lua_pop(L, 1);

  lua_getfield(L, -1, kItemStoreHandle);
  handleType = lua_type(L, -1);
  if (handleType != LUA_TUSERDATA) {
    luaL_error(L, "missing item store handle for ref=%s", ref);
  }
  
  pageItem = retrieveItemFromRegistry(L, -1, ref);
  lua_pop(L, 1);

  if (pageItem == NULL) 
  { 
    luaL_error(L, "%s (ref=%s)", 
                    kUnknownItemData, 
                    ref);
  }

  return pageItem;
}

int addPageIconsToPList(lua_State* L, plist_t page)
{
  plist_t pageItem;
  int i;

  int len = lua_rawlen(L, -1);
  for (i=1; i< len+1; i++) 
  {
    lua_rawgeti(L, -1, i); 
    pageItem = luaToStoredPListItem(L);

    // Under the opaque policy, only folders expose modeled child items here.
    // Widgets and stacks round-trip via their original stored plist node.
    lua_getfield(L, -1, kItemsKey);
    if (! lua_isnoneornil(L, -1)) 
    {
      pageItem = plist_copy(pageItem);
      addIconsToGroup(L, pageItem);
    } 
    lua_pop(L, 1);

    plist_array_append_item(page, pageItem);
    lua_pop(L,1); // pop page elem off
  }
  return 0;
}

void addIconsToGroup(lua_State* L, plist_t group)
{
  plist_t wasteful_format = plist_new_array();
  plist_t children = plist_new_array();
  plist_array_append_item(wasteful_format, children);
  int i;

  int len = lua_rawlen(L, -1);
  for (i=1; i< len+1; i++) 
  {
    lua_rawgeti(L, -1, i); 
    plist_array_append_item(children, luaToStoredPListItem(L));
    lua_pop(L,1); // pop page elem off    
  }
  plist_dict_set_item(group, kAppleIconListKey, wasteful_format);
}
