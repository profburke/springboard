#ifndef SAVE_LOAD_H
#define SAVE_LOAD_H

#include <lua.h>

int ios_save_layout_plist(lua_State *L);
int ios_load_layout_plist(lua_State *L);

int savePList(plist_t* layoutState, const char* path);

#endif
