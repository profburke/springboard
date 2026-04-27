local grid = {}

local aliases = {
   small = "small",
   medium = "medium",
   large = "large",
   xtralarge = "extraLarge",
   extralarge = "extraLarge",
   extraLarge = "extraLarge",
}

local sizes = {
   small = { width = 2, height = 2, slots = 4 },
   medium = { width = 4, height = 2, slots = 8 },
   large = { width = 4, height = 4, slots = 16 },
   extraLarge = { width = 4, height = 6, slots = 24 },
}

function grid.normalize(value)
   if type(value) ~= "string" then
      return nil
   end

   return aliases[value]
end

function grid.size(value)
   return sizes[grid.normalize(value)]
end

return grid
