#ifndef SPRINGBOARD_H
#define SPRINGBOARD_H

#include <plist/plist.h>
#include <lua.h>
#include "comms.h"

static char *const kAppleBundleIdKey = "bundleIdentifier";
static char *const kAppleDisplayIDKey = "displayIdentifier";
static char *const kAppleDisplayNameKey = "displayName";
static char *const kAppleElementsKey = "elements";
static char *const kAppleIconListKey = "iconLists";
static char *const kAppleIconTypeKey = "iconType";
static char *const kConnIDName = "connection";
static char *const kDockKey = "dock";
static char *const kElementsKey = "elements";
static char *const kFolderTypeKey = "springboard.folder";
static char *const kItemId = "id";
static char *const kItemName = "name";
static char *const kItemsKey = "items";
static char *const kLayoutTypeKey = "springboard.layout";
static char *const kPageTypeKey = "springboard.page";
static char *const kPagesKey = "pages";
static char *const kAppTypeKey = "springboard.app";
static char *const kSmartStackTypeKey = "springboard.stack";
static char *const kWidgetTypeKey = "springboard.widget";

int ios_plist_to_table(lua_State* L, plist_t iconState);
plist_t ios_table_to_plist(lua_State* L);

void storeIconInRegistry(lua_State* L,
                         plist_t icon,
                         const char* name,
                         const char* id);

plist_t retrieveIconFromRegistry(lua_State* L,
                                 const char* name,
                                 const char* id);

#endif
