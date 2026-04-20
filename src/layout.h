#ifndef LAYOUT_H
#define LAYOUT_H

struct lua_State;

static char *const kGetImageDataName = "imagedata";
static char *const kSavePlistMethodName = "save_plist";

int ios_get_layout(lua_State *L);
int ios_set_layout(lua_State *L);
int ios_app_imagedata(lua_State* L);
int ios_wallpaper(lua_State* L);

#endif
