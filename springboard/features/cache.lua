local lfs_ok, lfs = pcall(require, "lfs")

local cache = {}

local function ensure_dir(path)
   if lfs_ok then
      local attr = lfs.attributes(path)
      if attr then
         assert(attr.mode == "directory", path .. " exists and is not a directory")
         return
      end

      local current = path:sub(1, 1) == "/" and "/" or ""
      for part in path:gmatch("[^/]+") do
         if part ~= "." then
            if current == "" or current == "/" then
               current = current .. part
            else
               current = current .. "/" .. part
            end

            local current_attr = lfs.attributes(current)
            if not current_attr then
               assert(lfs.mkdir(current))
            else
               assert(current_attr.mode == "directory", current .. " exists and is not a directory")
            end
         end
      end
      return
   end

   local ok = os.rename(path, path)
   if not ok then
      error("cache directory does not exist and LuaFileSystem is unavailable: " .. path)
   end
end

local function list_dir(path)
   if not lfs_ok then
      error("cache key listing requires LuaFileSystem")
   end

   local results = {}
   for name in lfs.dir(path) do
      if name ~= "." and name ~= ".." then
         results[#results + 1] = name
      end
   end
   table.sort(results)
   return results
end

function cache.new(path, keytransform)
   assert(type(path) == "string" and #path > 0, "path must be a non-empty string")
   assert(type(keytransform) == "nil" or type(keytransform) == "function", "keytransform must be a function")

   ensure_dir(path)

   local c = {}
   c.path = path
   c.keytransform = keytransform or function(k) return k end

   c.key = function(k)
      local kprime = c.keytransform(k)
      if not kprime then return nil end
      assert(not tostring(kprime):find("/", 1, true), "cache keys may not contain path separators")
      return string.format("%s/%s", path, kprime)
   end

   c.get = function(k, generate)
      local data = nil
      local key = c.key(k)
      if not key then error("invalid key: " .. tostring(k)) end

      local fd = io.open(key, "rb")
      if fd then
         data = fd:read("*all")
         fd:close()
      end

      if not data and type(generate) == "function" then
         data = generate(k)
         c.set(k, data)
      end

      return data
   end

   c.set = function(k, v)
      local key = c.key(k)
      if not key then error("invalid key: " .. tostring(k)) end

      local fd = assert(io.open(key, "wb"))
      fd:write(v)
      fd:close()
   end

   c.remove = function(k)
      local key = c.key(k)
      if not key then error("invalid key: " .. tostring(k)) end
      return os.remove(key)
   end

   c.keys = function()
      return list_dir(path)
   end

   setmetatable(c, {
      __tostring = function() return "cache[" .. path .. "]" end,
   })

   return c
end

return cache
