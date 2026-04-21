#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>

#include <plist/plist.h>

#include "springboard_api.h"
#include "layout.h"
#include "springboard.h"
#include "util.h"
#include "sb_ios2lua.h"

// Converts the passed in plist into a Layout table.
int ios_plist_to_table(lua_State* L, plist_t layoutState, const char* source) {
  int handleIdx, rootIdx, layoutIdx, pagesIdx;
  int pageCount, i;

  pushItemStoreHandle(L);
  handleIdx = lua_absindex(L, -1);
  lua_newtable(L);
  parseNode(L, layoutState, 0, handleIdx);
  lua_rawgeti(L, -1, 1);
  rootIdx = lua_absindex(L, -1);

  lua_newtable(L);
  addToTable(L, kLayoutTypeKey);
  layoutIdx = lua_absindex(L, -1);

  lua_rawgeti(L, rootIdx, 1);
  lua_setfield(L, layoutIdx, kDockKey);

  lua_newtable(L);
  pagesIdx = lua_absindex(L, -1);
  pageCount = lua_rawlen(L, rootIdx);
  for (i=2; i<pageCount+1; i++) {
    lua_rawgeti(L, rootIdx, i);
    lua_rawseti(L, pagesIdx, i - 1);
  }
  lua_setfield(L, layoutIdx, kPagesKey);

  lua_pushvalue(L, handleIdx);
  lua_setfield(L, layoutIdx, kStoreHandleKey);
  if (source != NULL) {
    lua_pushstring(L, source);
    lua_setfield(L, layoutIdx, kSourceKey);
  }

  lua_remove(L, rootIdx);
  lua_remove(L, handleIdx);
  lua_remove(L, -2);
  return 1;
}

void parseNode(lua_State* L, plist_t node, int depth, int handleIdx) {
  char* name, *id, *bundleId, *iconType;
  plist_t kids, elements;
  int hasKids, hasElements;
  int numChildren;
  int i;
  
  if (node == NULL) { return; }

  switch (nodeType(node)) {
  case PLIST_DICT:
    lua_newtable(L);
    
    iconType = getStringVal(node, kAppleIconTypeKey);
    id = getStringVal(node, kAppleDisplayIDKey);
    name = getStringVal(node, kAppleDisplayNameKey);
    bundleId = getStringVal(node, kAppleBundleIdKey);
    kids = dictEntry(node, kAppleIconListKey);
    elements = dictEntry(node, kAppleElementsKey);
    hasKids = groupSize(kids) > 0;
    hasElements = groupSize(elements) > 0;
    
    if (iconType != NULL && strcmp(iconType, "custom") == 0) {
      // Widgets and smart stacks are preserved as opaque items.
      addToTable(L, hasElements ? kSmartStackTypeKey : kWidgetTypeKey);
    } else if (hasKids) {
      addToTable(L, kFolderTypeKey);
    } else if (name != NULL || id != NULL || bundleId != NULL) {
      addToTable(L, kAppTypeKey);
    } else {
      addToTable(L, kUnknownTypeKey);
    }
    
    if (name != NULL) { SET_STRING(L, kItemName,name); }
    if (id != NULL) { SET_STRING(L, kItemId,id); }
    if (bundleId != NULL) { SET_STRING(L, kAppleBundleIdKey,bundleId); }
    storeItemInRegistry(L, handleIdx, node);
    if (lua_type(L, -2) != LUA_TTABLE) {
      luaL_error(L, "registry stack corruption before item ref set");
    }
    lua_setfield(L, -2, kItemRef);
    lua_pushvalue(L, handleIdx);
    lua_setfield(L, -2, kStoreHandleKey);

    // TODO: remove the duplication
    
    // If item is a folder, add the contained apps as a table.
    if (hasKids) {
      lua_newtable(L);
      flatPackArray(L, kids, depth+1, handleIdx);
      lua_setfield(L, -2, kItemsKey);
    }

    // Opaque policy: preserve widgets/stacks as single items for round-trip.
    // Their internals are intentionally not modeled yet.
    // TODO: "Siri Suggestions" doesn't contain a bundle ID, so
    // full stack parsing still needs null-safe element handling.
    // if (groupSize(elements) > 0) {
    // lua_newtable(L);
    //   flatPackArray(L, elements, depth+1);
    // lua_setfield(L, -2, kElementsKey);
    // }
break;
    
  case PLIST_ARRAY:
    lua_newtable(L);
    addToTable(L, depth == 0 ? kLayoutTypeKey : kPageTypeKey);
    
    numChildren = groupSize(node);
    for (i=0;i<numChildren;i++) {
      parseNode(L, arrayElem(node, i), depth+1, handleIdx);
    }
    
  default:
    break;
    
  case PLIST_BOOLEAN: break;
  case PLIST_UINT: break;
  case PLIST_REAL: break;
  case PLIST_STRING: break;
  case PLIST_DATE: break;
  case PLIST_DATA: break;
  case PLIST_KEY: break;
  case PLIST_UID: break;
  case PLIST_NONE: break;
  }
  
  // append to the end of our parent container
  lua_rawseti(L, -2, lua_rawlen(L, -2) + 1);
}

// unfortunately we get back all groups double wrapped, seems
// apple was preparing for something that never came, if that
// day does come this might need to go
void flatPackArray(lua_State* L, plist_t node, int depth, int handleIdx) {
  int i;
  
  if (nodeType(node) == PLIST_ARRAY) {
    for (i=0;i<groupSize(node);i++) {
      flatPackArray(L, arrayElem(node, i), depth, handleIdx);
    }      
  } else {
    parseNode(L, node, depth, handleIdx);
  }
}

char *getStringVal(plist_t dict, const char* key) {
  char* charVal = "";
  plist_t plistItem = dictEntry(dict, key);

  switch (nodeType(plistItem)) {
  case PLIST_STRING:
    stringVal(plistItem,&charVal);
    break;
  default: // fall through to empty val.
  case PLIST_NONE:
    charVal = NULL;
    break;
  }
  
  return charVal;
}
