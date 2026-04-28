#
# Makefile
#

SRCS = comms.c layout.c util.c springboard_bridge.c sb_ios2lua.c sb_lua2ios.c sb_registry.c save_load.c
OBJS = comms.o layout.o util.o springboard_bridge.o sb_ios2lua.o sb_lua2ios.o sb_registry.o save_load.o
LFLAGS = -bundle -undefined dynamic_lookup -all_load
# CFLAGS = -O2 -fPIC -I/usr/local/include
# LIBS = -L/usr/local/lib -limobiledevice -lplist
CFLAGS = -O2 -fPIC -I/opt/homebrew/include -I/usr/local/include
LIBS = -L/opt/homebrew/lib -L/usr/local/lib -limobiledevice -lplist

CC = /usr/bin/llvm-gcc
CP = /bin/cp
RM = /bin/rm


springboard: $(OBJS)
	$(CC) $(LFLAGS) -o bridge.so $(OBJS) $(LIBS)
	$(CP) bridge.so ../springboard

.c.o:
	$(CC) $(CFLAGS) -c $<

.PHONY: clean
clean:
	-$(RM) -f *.o bridge.so
