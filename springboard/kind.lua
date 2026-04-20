local rawtype = type
local registry = setmetatable({}, { __mode = "k" })

local kind = {}

function kind.register(meta, name)
   assert(rawtype(meta) == "table", "meta must be a table")
   assert(rawtype(name) == "string" and #name > 0, "name must be a non-empty string")
   registry[meta] = name
   meta.__kind = name
   return meta
end

function kind.of(value)
   local meta = getmetatable(value)
   if meta and registry[meta] then
      return registry[meta]
   end

   return rawtype(value)
end

function kind.is(value, name)
   return kind.of(value) == name
end

return kind
