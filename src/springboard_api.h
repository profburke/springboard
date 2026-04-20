#ifndef SPRINGBOARD_API_H
#define SPRINGBOARD_API_H

struct lua_State;

static char *const kLibraryRegKey = "springboard.registry";
static char *const kItemStoreHandleID = "springboard.item_store";
static char *const kSpringboardConnID = "idevice_conn";
static const char* kClientId = "springboard";
static const char* kConnectFail = "error communicating with device. ";
static const char* kFailNoConnection = "failed! no connection.";
static const char* kSetLayoutErr = "error setting layout";
static const char* kSpringboardInfoVersion = "2";
static const char* kSpringboardServices = "com.apple.springboardservices";
static const char* kUnknownItemData = "unable to find item in stored layout!";

extern int idevice_errno;

#endif
