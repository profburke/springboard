local bridge = require "springboard.bridge"

local springboard = {
   connect = bridge.connect,
   ios_errno = bridge.ios_errno,
   load_plist = bridge.load_plist,

   bridge = bridge,

   kind = require "springboard.kind",
   layout = require "springboard.layout",
   page = require "springboard.page",
   app = require "springboard.app",
   folder = require "springboard.folder",
   widget = require "springboard.widget",
   stack = require "springboard.stack",
   unknown = require "springboard.unknown",
}

springboard.features = {
   cache = function()
      return require "springboard.features.cache"
   end,

   graphics = function()
      return require "springboard.features.graphics"
   end,

   image = function()
      return require "springboard.features.image"
   end,

   itunes = function()
      return require "springboard.features.itunes"
   end,
}

return springboard
