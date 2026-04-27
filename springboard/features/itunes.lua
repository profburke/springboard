local itunes = {
   pause_between_downloads = 0.5,
}

local cache = require "springboard.features.cache"
local json = require "json"
local socket = require "socket"
local http = require "socket.http"
http.USERAGENT = "LuaSocket - springboard client"

local function sleep(sec)
   socket.select(nil, nil, sec)
end

local function itunes_url(app)
   return "http://itunes.apple.com/lookup?bundleId=" .. app.id
end

itunes.cache = cache.new("./.iTunesJson", function(app)
   if not app or not app.id then return nil end
   return app.id .. "_itunes.json"
end)

local function rate_limit()
   local last_fetch = itunes.last_fetch
   if not last_fetch then last_fetch = -100 end
   if (os.clock() - last_fetch) < 1 then
      sleep(itunes.pause_between_downloads)
   end
   itunes.last_fetch = os.clock()
end

local function add_itunes_data(app)
   local raw = itunes.cache and itunes.cache.get(app)

   if not raw then
      rate_limit()
      raw = http.request(itunes_url(app))
      if itunes.cache then itunes.cache.set(app, raw) end
   end

   if raw then
      local data = json.decode(raw)
      if data.results and #data.results == 1 then
         app.data = data.results[1]
      end
      return data
   end

   return nil
end

local function add_itunes_to_all(layout, on_process)
   layout:visit(function(app)
      app:add_itunes_data()
      if on_process then on_process(app) end
   end)
end

function itunes.attach(layout)
   if not layout then error("layout must be provided") end
   if not layout.visit then error("unexpected value found for layout") end

   layout:visit(function(app)
      if app.id then
         app.add_itunes_data = add_itunes_data
      else
         app.add_itunes_data = function() end
      end
   end)

   layout.add_itunes_data = add_itunes_to_all
   layout.itunes_cache = function() return itunes.cache end
   return layout
end

itunes.on_layout = itunes.attach

return itunes
