local inspect = require "vim.inspect"
local cache = require "aoc.cache"
local curl = require "plenary.curl"
local cfg = require "aoc.config"

---@class APIWrapper
local M = {}
M.session_id = nil
M.user_agent = "<github.com/csessh/aoc.nvim> by csessh@hey.com"
M.request_timestamps = {}

---@param day string|osdate
---@param year string|osdate
local validate_args = function(day, year)
   if day == nil or day == "" then
      vim.api.nvim_err_writeln "Day is not valid or is not specified"
      return false
   end

   if year == nil or year == "" then
      vim.api.nvim_err_writeln "Year is not valid of is not specified"
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

---Load session token from file
---@return string?
local get_session_id = function()
   if M.session_id then
      return M.session_id
   end

   local f = io.open(cfg.options.session_filepath, "r")
   if not f then
      vim.api.nvim_err_writeln("Unable to open session file" .. cfg.options.session_filepath)
      return nil
   end

   local sid = f:read "*a"
   M.session_id = sid
   f:close()

   return sid
end

local rate_limit_reached = function()
   local now = os.time()
   for i = #M.request_timestamps, 1, -1 do
      if now - M.request_timestamps[i] > 60 then
         table.remove(M.request_timestamps, i)
      end
   end

   if #M.request_timestamps >= cfg.options.requests_per_minute then
      return true
   end

   table.insert(M.request_timestamps, now)
   return false
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

   if rate_limit_reached() then
      vim.api.nvim_err_writeln "Too many requests, please wait a moment"
      return
   end

   -- Check if puzzle input for this particular day has been previously cached
   local cf = cache.get_cached_input_file(day, year)
   if cf then
      local content = cf:read "*a"
      cf:close()

      cache.write_to_file(day, year, content)
      return
   end

   -- Proceed to send GET request to AOC server for the puzzle input
   local sid = get_session_id()
   if not sid then
      vim.api.nvim_err_writeln "Advent Of Code session token is missing. See :help aoc.nvim-requirements"
      return
   end

   local response = curl.get {
      url = "https://adventofcode.com/" .. year .. "/day/" .. day .. "/input",
      headers = {
         cookie = "session=" .. sid,
         user_agent = M.user_agent,
      },
   }

   if response.status == 200 then
      cache.write_to_cache(day, year, response.body)
      cache.write_to_file(day, year, response.body)
   else
      vim.api.nvim_err_writeln(response.body)
   end
end

M.reload_session_token = function()
   M.session_id = get_session_id()
   if M.session_id then
      vim.notify "Session token reloaded"
   end
end

return M
