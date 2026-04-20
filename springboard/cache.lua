local format = string.format
local execute = os.execute
local open = io.open
local popen = io.popen
local insert = table.insert

local cache = {}

-- add a function to get a list of keys
-- what about a protocol so that we can have caches with a backend other than the file system?
-- (then what about Lua FUSE?)


function cache.new(path, keytransform)
   assert(type(path) == 'string' and #path > 0, 'path must be a non-empty string')
   assert(type(keytransform) == 'nil' or type(keytransform) == 'function', 'keytransform must be a function')
   
   local c = { }
   
   _,_,rc = execute('test -d ' .. path)
   if rc == 1 then execute('mkdir -p ' .. path) end

   c.keytransform = keytransform or function(k) return k end
   c.key = function(k)
      local kprime = c.keytransform(k)
      if not kprime then return nil end
      return format('%s/%s', path, kprime)
   end
   
   c.get = function(k, generate)
      local data = nil
      local key = c.key(k)
      if not key then error('invalid key: ' .. tostring(k)) end
      
      local fd = open(key, "rb")
      if fd then data = fd:read("*all") ; fd:close() end
      if not data and type(generate) == "function" then
         data = generate(k)
         c.set(k, data)
      end
      return data        
   end
   
   c.set = function(k, v)
      local key = c.key(k)
      if not key then error('invalid key: ' .. tostring(k)) end
      
      local fd = open(key, "wb")
      fd:write(v)
      fd:close()
   end

   c.remove = function(k)
      local key = c.key(k)
      _,_,rc = execute('/bin/rm -f ' .. key)
      return rc
   end

   c.keys = function()
      local results = {}
      local p = popen('ls -1 ' .. path, 'r')
      for f in p:lines() do
         insert(results, f)
      end
      p:close()
      return results
   end
   
   setmetatable(c, {
                   __tostring = function() return "cache[" .. path .. "]" end,
                   })
   return c
end


return cache
