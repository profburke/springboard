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


print "Info on the left-most docked app:\n"
for k,v in pairs(layout.dock[1]) do print(string.format('%18s: %s', k, v)) end
