local image = {}

local cache = require "ios-icons.cache"
cache = cache.new("./.ios-icon-colors", function(icon)
    return icon.id .. ".rgb"
end)

local dark_cutoff = 100

-- eyeballed to within an inch of... whatever
local function hsv_to_color(h,s,v)
    if v < 60 then return "black" 
    elseif s < 0.1 then return "gray"
    elseif h < 15 then return "red"
    elseif h < 45 then return "orange"
    elseif h < 80 then return "yellow"
    elseif h < 150 then return "green"
    elseif h < 250 then return "blue"
    else return "red"
    end
end


local function rgb_to_hsv(r, g, b)
    local sorted, min, max, v, delta, h, s, v
    
    sorted = { r, g, b }
    table.sort(sorted)
    min = sorted[1]
    max = sorted[3]
    v = max

    delta = max - min
    if max == 0 then
        s = 0
        h = -1
        return h,s,v
    else
        s = delta / max 
    end

    if r == max then
        h = (g - b) / delta
    elseif g == max then
        h = 2 + (b - r) / delta
    else
        h = 4 + (r - g) / delta
    end

    h = h * 60
    if h < 0 then h = h + 360 end

    return h,s,v
end

local function graphics_magick(m_args)
    local cmdline = "gm " .. m_args
    local _,_,rc = os.execute(cmdline)
    if not rc == 0 then error("subprocess failed!"
                              .. " - command was "
                              .. cmdline) end
end

-- TODO: need to identify webapps and cope with the fact that
-- springboard will not return icons for them

-- returns pseudo image object for provided icon
function image.new(icon)
    return {
        -- write png to disk
        save = function(path)
            local fd = io.open(path, "wb")
            fd:write(icon.imagedata())
            fd:flush()
            fd:close() 
        end,
        rgb = function() 
            local data = cache.get(icon, icon.image.make_rgb)
            local r,g,b = string.byte(data,1,3)
            return r,g,b
        end,
        -- use (gm)magick to generate average rgb for icon image
        make_rgb = function()
            local pngfile = os.tmpname() .. ".png"
            local rgbfile = os.tmpname() .. ".rgb"
            icon.image.save(pngfile)

            graphics_magick("convert " .. pngfile 
                                       .. " -colors 16"
                                       .. " -resize '1x1!'"
                                       .. " RGB:" .. rgbfile)

            local data  = io.open(rgbfile, "rb"):read("*all")
            os.remove(pngfile)
            os.remove(rgbfile)
            return data
        end,
        -- not the ute.
        hsv = function()
            local r,g,b = icon.image.rgb()
            return rgb_to_hsv(r,g,b)
        end,
        color = function()
            local h,s,v = icon.image.hsv()
            local result = hsv_to_color(h,s,v)
            -- cache for next lookup
            icon.image.color = function() return result end
            return result
        end,
        is_dark = function()
            local h,s,v = icon.image.hsv()
            return v < dark_cutoff
        end,
    }
end

return image
