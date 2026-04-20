#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <lauxlib.h>

#include <plist/plist.h>

#include "springboard.h"

void
raise_lua_stdio_err(lua_State *L)
{
  if (errno == 0) { lua_pushstring(L, "unknown error!"); }  
  else { lua_pushstring(L, strerror(errno) ); }
  lua_error(L);
}

void
raise_lua_nomem(lua_State *L)
{
  lua_pushstring(L, "ENOMEM");
  lua_error(L);
}

int
savePList(plist_t* layoutState, const char* path)
{
  char* xml = NULL;
  uint32_t len = 0;
  FILE* fd;

  fd = fopen(path, "w");
  if (fd == NULL) { return 1; }

  plist_to_xml(layoutState, &xml, &len);

  fwrite(xml, sizeof(char), len, fd);
  fflush(fd);
  fclose(fd);
  free(xml);

  return 0;
}

int 
ios_save_layout_plist(lua_State *L)
{
  plist_t layoutState;
  const char* path;

  path = luaL_checkstring(L, -1);
  lua_pop(L, 1);
  layoutState = ios_table_to_plist(L); 
  lua_pop(L, 1);

  if (savePList(layoutState, path))
  {
    luaL_error(L, "failed to save: %s", 
                  strerror(errno));
  }

  return 0;
}

char*
fslurp(const char* path)
{
  char* data = NULL;
  uint32_t len = 0;
  size_t read_len;
  struct stat st;
  FILE* fd;

  if (stat(path, &st)) { return NULL; }
  len = st.st_size;

  fd = fopen(path, "r");
  if (fd == NULL) { return NULL; }

  data = malloc(sizeof(char) * (len + 1));
  if (data == NULL) { return NULL; }

  read_len = fread(data, sizeof(char), len, fd);
  fclose(fd);
  if (read_len != len) {
    free(data);
    errno = EIO;
    return NULL;
  }

  data[len] = '\0';
  return data;
}

int 
ios_load_layout_plist(lua_State *L)
{
  plist_t layoutState = NULL;
  char* xml = NULL;
  const char* path;

  path = lua_tostring(L, -1);
  xml = fslurp(path);
  if (xml == NULL)
  { 
    luaL_error(L, "failed to read file: %s", 
                  strerror(errno));
  }

  plist_from_xml(xml, strlen(xml), &layoutState);
  free(xml);

  lua_pop(L, 1);

  return ios_plist_to_table(L, layoutState);
}
