local inspect = require "vim.inspect"

---@class PuzzleCache
local M = {}

local plugin_installation_path = debug.getinfo(1).source:sub(2):match "(.*/).*/.*/"
local cache_path = plugin_installation_path .. "/cache/"

---Clear all cache
---@return boolean
M.clear_cache = function()
   local paths = vim.split(vim.fn.glob(cache_path .. "*.txt"), "\n")
   for _, file in pairs(paths) do
      if file ~= "" and not os.remove(file) then
         vim.api.nvim_err_writeln("Failed to remove " .. file)
      end
   end

   vim.notify "cache cleared"
   return true
end

---Check cache for already downloaded puzzle input to prevent unnecessary requests to AOC server
---@param day string|osdate
---@param year string|osdate
---@return file*?
M.get_cached_input_file = function(day, year)
   local f = io.open(cache_path .. year .. day .. ".txt")

   if not f then
      return nil
   end

   return f
end

---Write cached content to file
---@param day string|osdate
---@param year string|osdate
---@return boolean
M.write = function(day, year, content)
   -- Create a cache directory if one doesn't exist
   -- Quite a clevery hacky way to check if a directory exists without relying on external packages
   local ok, err = os.rename(cache_path, cache_path)
   if not ok then
      os.execute("mkdir " .. cache_path)
   end

   -- Cache filenames follow this template: {year}{day}.txt
   local filename = cache_path .. year .. day .. ".txt"
   local f = io.open(filename, "w")
   if not f then
      vim.api.nvim_err_writeln("Unable to write puzzle input to cache at " .. filename)
      return false
   end

   f:write(content)
   f:close()

   return true
end

return M
