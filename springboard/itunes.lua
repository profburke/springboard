local itunes = {
    -- sleep between itunes http reqs
    pause_between_downloads = 0.5,
}

local cache = require 'springboard.cache'
local io = require "io"
local json = require "json"
local socket = require "socket"
local http = require "socket.http"
http.USERAGENT = "LuaSocket - ios springboard client" 


local function sleep(sec)
    socket.select(nil, nil, sec)
end

-- sadly had to use a private api here, 
-- apple's official one doesn't (atow tbomk)
-- support lookup by bundleID
local itunes_url = function(app)
    return ("http://itunes.apple.com/" .. "lookup?bundleId=" .. app.id)
end

-- json cache store. * I have no idea if apple own a 
-- banstick or under what conditons said banstick would be
-- used * (although I expect they do and barrier for entry 
-- would be low)
itunes.cache = cache.new('./.iTunesJson', function(i)
                            if not i or not i.id then return nil end
                            return i.id .. '_itunes.json' end)


local rate_limit = function()
    local last_fetch = itunes.last_fetch
    if not last_fetch then last_fetch = -100 end
    if (os.clock() - last_fetch) < 1 then
        sleep(itunes.pause_between_downloads)
    end
    itunes.last_fetch = os.clock()
end

local add_itunes_data = function(app)
    local raw = nil ; local cache = itunes.cache
    if cache then raw = cache.get(app) end

    if not raw then
        rate_limit()
        local url = itunes_url(app)
        raw = http.request(itunes_url(app))
        if cache then cache.set(app, raw) end
    end

    if raw then
        data = json.decode(raw) 
        if data.results and #data.results == 1 then
            app.data = data.results[1]
        end
    end
    return data
end

-- adds itunes data to ALL apps for which it can.
-- this is likely to be time consuming on the first run
-- (expect ~2 seconds per app)
local add_itunes_to_all = function(layout, on_process)
    layout:visit(function(app)
        app:add_itunes_data()
        if on_process then on_process(app) end
    end)
end


function itunes.on_layout(layout)
    if not layout then error("no layout provided!") end
    if not layout.visit then error("unexpected value found for layout!") end

    layout:visit(function(app)
        if app["id"] then 
            app.add_itunes_data = add_itunes_data
        else
            app.add_itunes_data = function() end
        end
    end)
    layout.add_itunes_data = add_itunes_to_all

    layout.itunes_cache = function() return itunes.cache end
end

return itunes
