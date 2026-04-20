# springboard - scripted iPhone/iOS layout arrangement
---

springboard is a [lua](http://www.lua.org/) module enabling communication 
with iPhone/iPod/iPad device(s) over usb for the purposes of icon arrangement.

## Usage

![demo repl session](caps/dock-set.gif)

### basics

`ios.connect` returns a connection for read / set operations.

    bash# lua
    Lua 5.2.3  Copyright (C) 1994-2013 Lua.org, PUC-Rio
    > ios = require "springboard"
    > conn = ios.connect()
    > icons = conn:get_icons()

`conn:get_icons()` returns a table model of the current 
icons as arranged on device (by page then (icon or group/icon). 

    > -- how many (springboard) pages do I have?
    > print(#icons)
    12

as well as the model objects, icons contains a bunch of utility methods,
like `flatten`, `find`, `visit` ...

    > -- how many icons do I have overall?
    > print(#icons:flatten())
    222

### updating the device

The simplest update you can make swaps two icon positions

    > print(icons:dock())
    pr0nz, Mail, 1Password, Safari
    >
    > -- wait - err, how'd that get there!
    > icons:swap(icons[1][1], icons:find("Messages"))
    > conn:set_icons(icons)
    >
    > print(conn:get_icons()[1])
    Messages, Mail, 1Password, Safari

see [example_sort](example_sort/README.md) and [source](lib) for more details.

## Requirements and Installation

Communication is via usb, using the excellent 
[libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) and
[libplist](https://github.com/libimobiledevice/libplist) libraries **both of
which are required to build**. 

#### osx install:


    brew install lua --with-completion
    brew install luarocks libimobiledevice libplist
    luarocks install springboard


**NOTE: The luarocks command above will not work.** ()*It will pull code from the original repository. If the original repository built properly,
I wouldn't have had to make this fork.*)

Instead, run make as follows:

    make
    
Then run the sample app:

    ./try_me.lua
    
Make sure `try_me.lua` has execute permission. If that doesn't mean anything to you, you
can also try

    lua try_me.lua

The result should be a listing of info related to whatever app is first in your dock. For example,
on my iPhone, I get the following output:

    matt@stormageddon:~/Matt/Projects/ios-icons $ ./try_me.lua 
    Info on the left-most docked app:

      bundleIdentifier: com.agilebits.onepassword-ios
                    id: com.agilebits.onepassword-ios
                  role: icon
                  name: 1Password

    
    
The `makefile` assumes the following:

1. You have the build tools installed (make, llvm, etc.)
2. You have successfully installed `Lua`, `libimobiledevice` and 'libplist`.

By the way, if you're curious about the `makefile`, I'm using the same compiler and linker
flags that `luarocks` would use&mdash;I'm not certain they're the best choices, but I haven't
really dug into it. As I mention above, push requests welcome!

**As for Linux installs, try the following, but you're on your own. I haven't had time to try installing on Linux.**

#### linux install:

As well as osx I've tested on ubuntu (14.4) but the install was 
significantly more complicated due to incompatible libimobiledevice
versions in apt. 

I can't ascertain the politics or technical details of why 
libimobiledevice-2 exists, nor where it's source is hosted
online but it appears quite incompatible with the version of the lib
I've used, and the header files unfortunately conflict.

To work around this I built libimobiledevice, libplist and libusbmuxd from 
source, installed each with checkinstall. *Tread careful if you decide
to follow in my footsteps here - I don't use any of the Linux ios tooling
so may have broken rhythmbox/syncing/whatever the kids use these days and
I wouldn't even know.*

I used lua5.2 from apt and build luarocks from source (although I've since
forgotten what failure prompted the manual rocks build).
