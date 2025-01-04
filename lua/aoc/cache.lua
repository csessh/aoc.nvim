local cfg = require "aoc.config"

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
M.write_to_cache = function(day, year, content)
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
   else
      f:write(content)
   end

   f:close()
end

---Write puzzle input to user's cwd() or where they specify it otherwise
---@param day string|osdate
---@param year string|osdate
---@param content string
M.write_to_file = function(day, year, content)
   local filename = ""
   if cfg.options.puzzle_input.save_to_current_dir then
      filename = vim.uv.cwd() .. "/" .. cfg.options.puzzle_input.filename
   else
      filename = cfg.options.puzzle_input.alternative_filepath
   end

   ---@diagnostic disable-next-line: param-type-mismatch
   local f = io.open(filename, "w")
   if not f then
      vim.api.nvim_err_writeln("Unable to write puzzle input to file at " .. filename)
   else
      f:write(content)
      f:close()
   end

   vim.notify("Successfully downloaded puzzle input for Day " .. day .. " (" .. year .. ")")
end

return M
