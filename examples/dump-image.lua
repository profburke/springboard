#!/usr/bin/env lua

status, ios = pcall(require, 'springboard')
if (not status) then
   print "Could not find the 'springboard' library."
   print "Check to verify it was installed."
   os.exit(1)
end

status, conn = pcall(ios.connect)
if (not status) then
   print "Could not detect a connected iOS device."
   os.exit(1)
end

layout = conn:layout()
app = layout.dock[1]
img = conn:app_image(app)

f = io.open("leftdock.png", 'w')
f:write(img)
f:close()
