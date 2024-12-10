local inspect = require "vim.inspect"
local curl = require "plenary.curl"
local opts = require("aoc.config").options
local cache = require "aoc.cache"
local popup = require "aoc.notification"

---@class APIWrapper
local M = {}

---@param day string
---@param year string
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

   if d < 1 or d > 31 then
      vim.api.nvim_err_writeln("Invalid day: " .. d)
      return false
   end

   if y < 2015 or y > os.date().year then
      vim.api.nvim_err_writeln("Invalid year: " .. year)
      return false
   end

   return true
end

-- Effectively send a curl request like so:
-- curl -X GET https://adventofcode.com/{year}/day/{day}/input -H "Cookie: session={session_token_path}"
-- Always check and validate cache before sending out requests. It's best to polite.
---@param day string
---@param year string
M.save_puzzle_input = function(day, year)
   if not validate_args(day, year) then
      return
   end

   if cache.does_cache_exist(day, year) then
      return
   end

   local f = io.open(opts.session_id.file_path, "r")
   if not f then
      vim.api.nvim_err_writeln "Advent Of Code session token is missing. :help aoc.nvim-toke"
      return
   end

   local sid = f:read "*a"
   io.close(f)

   local response = curl.get {
      url = "https://adventofcode.com/" .. year .. "/day/" .. day .. "/input",
      headers = {
         cookie = "session=" .. sid,
      },
   }

   if response.status == 200 then
      f = io.open(vim.uv.cwd() .. "/" .. opts.puzzle_input.filename, "w")
      if not f then
         vim.api.nvim_err_writeln("Unable to write puzzle input to file at " .. opts.puzzle_input.filename)
         return
      end

      f:write(response.body)
      io.close(f)

      popup.show(
         "Successfully downloaded puzzle input for Day " .. day .. " (" .. year .. ")",
         opts.popup_clear_after_s * 1000
      )
   else
      vim.api.nvim_err_writeln(response.body)
   end
end

return M
