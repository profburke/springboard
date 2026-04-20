#ifndef IOS_ICONS_H
#define IOS_ICONS_H

struct lua_State;

static char *const kLibraryRegKey = "iOS.springboard";
static char *const kSpringboardConnID = "idevice_conn";
static const char* kClientId = "springboard";
static const char* kConnectFail = "error communicating with device. ";
static const char* kFailNoConnection = "failed! no connection.";
static const char* kSetIconsErr = "error setting layout";
static const char* kSpringboardInfoVersion = "2";
static const char* kSpringboardServices = "com.apple.springboardservices";
static const char* kUnknownIconData = "unable to find item in stored layout!";

extern int idevice_errno;

#endif
