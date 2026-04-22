#ifndef SPRINGBOARD_H
#define SPRINGBOARD_H

#include <plist/plist.h>
#include <lua.h>
#include "comms.h"

static char *const kAppleBundleIdKey = "bundleIdentifier";
static char *const kAppleDisplayIDKey = "displayIdentifier";
static char *const kAppleDisplayNameKey = "displayName";
static char *const kAppleElementsKey = "elements";
static char *const kAppleElementTypeKey = "elementType";
static char *const kAppleContainerBundleIdKey = "containerBundleIdentifier";
static char *const kAppleGridSizeKey = "gridSize";
static char *const kAppleIconListKey = "iconLists";
static char *const kAppleIconTypeKey = "iconType";
static char *const kAppleWidgetIdKey = "widgetIdentifier";
static char *const kConnIDName = "connection";
static char *const kDockKey = "dock";
static char *const kElementsKey = "elements";
static char *const kFolderTypeKey = "springboard.folder";
static char *const kItemId = "id";
static char *const kItemName = "name";
static char *const kItemRef = "ref";
static char *const kStoreHandleKey = "__store";
static char *const kSourceKey = "__source";
static char *const kSourceDevice = "device";
static char *const kSourceFile = "file";
static char *const kItemsKey = "items";
static char *const kLayoutTypeKey = "springboard.layout";
static char *const kPageTypeKey = "springboard.page";
static char *const kPagesKey = "pages";
static char *const kAppTypeKey = "springboard.app";
static char *const kSmartStackTypeKey = "springboard.stack";
static char *const kWidgetTypeKey = "springboard.widget";
static char *const kUnknownTypeKey = "springboard.unknown";

int ios_plist_to_table(lua_State* L, plist_t layoutState, const char* source);
plist_t ios_table_to_plist(lua_State* L);

void pushItemStoreHandle(lua_State* L);
int itemStoreHandle_gc(lua_State* L);

void storeItemInRegistry(lua_State* L,
                         int handleIdx,
                         plist_t item);

plist_t retrieveItemFromRegistry(lua_State* L,
                                 int handleIdx,
                                 const char* ref);

#endif
