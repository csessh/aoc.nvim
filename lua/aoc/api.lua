local cache = require "aoc.cache"
local curl = require "plenary.curl"
local cfg = require "aoc.config"

---@class APIWrapper
local M = {}

---@param day string|osdate
---@param year string|osdate
local validate_args = function(day, year)
   if day == nil or day == "" then
      vim.api.nvim_err_writeln "Missing day"
      return false
   end

   if year == nil or year == "" then
      vim.api.nvim_err_writeln "Missing year"
      return false
   end

   local d = tonumber(day)
   local y = tonumber(year)

   if not d or d < 1 or d > 31 then
      vim.api.nvim_err_writeln("Invalid day: " .. day)
      return false
   end

   if not y and y < 2015 or y > tonumber(os.date "%Y") then
      vim.api.nvim_err_writeln("Invalid year: " .. year)
      return false
   end

   return true
end

-- Effectively send a curl request like so:
-- curl -X GET https://adventofcode.com/{year}/day/{day}/input -H "Cookie: session={session_token_path}"
-- Always check and validate cache before sending out requests. It's best to polite.
---@param day string|osdate
---@param year string|osdate
M.save_puzzle_input = function(day, year)
   if not validate_args(day, year) then
      return
   end

   -- Check if puzzle input for this particular day has been previously cached
   local cf = cache.get_cached_input_file(day, year)
   if cf then
      local content = cf:read "*a"
      cf:close()

      local f = io.open(vim.uv.cwd() .. "/" .. cfg.options.puzzle_input.filename, "w")
      if not f then
         vim.api.nvim_err_writeln("Unable to write puzzle input to file at " .. cfg.options.puzzle_input.filename)
         return
      end

      f:write(content)
      f:close()

      vim.notify("Successfully retrieved puzzle input for Day " .. day .. " (" .. year .. ")")
      return
   end

   -- Proceed to send GET request to AOC server for the puzzle input
   local f = io.open(cfg.options.session_filepath, "r")
   if not f then
      vim.api.nvim_err_writeln "Advent Of Code session token is missing. See :help aoc.nvim-requirements"
      return
   end

   local sid = f:read "*a"
   f:close()

   local response = curl.get {
      url = "https://adventofcode.com/" .. year .. "/day/" .. day .. "/input",
      headers = {
         cookie = "session=" .. sid,
      },
   }

   if response.status == 200 then
      -- Cache the puzzle input for future use
      cache.write(day, year, response.body)

      -- Write puzzle input to user's cwd() or where they specify it otherwise
      local filename = ""
      if cfg.options.puzzle_input.save_to_current_dir then
         filename = vim.uv.cwd() .. "/" .. cfg.options.puzzle_input.filename
      else
         filename = cfg.options.puzzle_input.alternative_filepath
      end

      ---@diagnostic disable-next-line: param-type-mismatch
      f = io.open(filename, "w")
      if not f then
         vim.api.nvim_err_writeln("Unable to write puzzle input to file at " .. filename)
         return
      end

      f:write(response.body)
      f:close()

      vim.notify("Successfully downloaded puzzle input for Day " .. day .. " (" .. year .. ")")
   else
      vim.api.nvim_err_writeln(response.body)
   end
end

return M
