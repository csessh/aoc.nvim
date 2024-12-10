---@class PuzzleCache
local M = {}

---Clear all caches
M.clear_cache = function()
   print "Clearing cache..."
end

---Validate cache
---@param day integer|string 
---@param year integer|string 
---@return boolean
M.does_cache_exist = function(day, year)
   print("Checking cache for day " .. day .. " (" .. year .. ")")
end

---Write cached content to file
---@param day integer|string 
---@param year integer|string 
---@return boolean
M.write = function(day, year)
   print("Writing cache for day " .. day .. " (" .. year .. ")")
end

return M
