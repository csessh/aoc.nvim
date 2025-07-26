local cache = require "aoc.cache"
local curl = require "plenary.curl"
local cfg = require "aoc.config"

---@class APIWrapper
local M = {}
M.session_id = nil
M.user_agent = "<github.com/csessh/aoc.nvim> by csessh@hey.com"

-- Rate limiting: 5 requests per minute
M.request_timestamps = {}
M.max_requests_per_minute = 5
M.rate_limit_window_ms = 60000

---@param day string|osdate
---@param year string|osdate
local validate_args = function(day, year)
   if day == nil or day == "" then
      vim.notify("Day is not valid or is not specified", vim.log.levels.ERROR)
      return false
   end

   if year == nil or year == "" then
      vim.notify("Year is not valid of is not specified", vim.log.levels.ERROR)
      return false
   end

   local d = tonumber(day)
   local y = tonumber(year)

   if not d or d < 1 or d > 31 then
      vim.notify("Invalid day: " .. day, vim.log.levels.ERROR)
      return false
   end

   if not y and y < 2015 or y > tonumber(os.date "%Y") then
      vim.notify("Invalid year: " .. year, vim.log.levels.ERROR)
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
      vim.notify("Unable to open session file" .. cfg.options.session_filepath, vim.log.levels.ERROR)
      return nil
   end

   local sid = f:read "*a"
   M.session_id = sid
   f:close()

   return sid
end

---Check if we can make a request without exceeding rate limit
---@return boolean
local can_make_request = function()
   local current_time = vim.uv.now()
   local cutoff_time = current_time - M.rate_limit_window_ms

   -- Remove timestamps older than 1 minute
   local recent_timestamps = {}
   for _, timestamp in ipairs(M.request_timestamps) do
      if timestamp > cutoff_time then
         table.insert(recent_timestamps, timestamp)
      end
   end
   M.request_timestamps = recent_timestamps

   return #M.request_timestamps < M.max_requests_per_minute
end

---Record a new request timestamp
local record_request = function()
   table.insert(M.request_timestamps, vim.uv.now())
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

      cache.write_to_file(day, year, content)
      return
   end

   -- Check rate limit before making request
   if not can_make_request() then
      vim.notify(
         "Rate limit exceeded. Please wait before making another request (max "
            .. M.max_requests_per_minute
            .. " requests per minute)",
         vim.log.levels.ERROR
      )
      return
   end

   -- Proceed to send GET request to AOC server for the puzzle input
   local sid = get_session_id()
   if not sid then
      vim.notify("Advent Of Code session token is missing. See :help aoc.nvim-requirements", vim.log.levels.ERROR)
      return
   end

   -- Record the request timestamp
   record_request()

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
      vim.notify(response.body, vim.log.levels.ERROR)
   end
end

M.reload_session_token = function()
   M.session_id = get_session_id()
   if M.session_id then
      vim.notify "Session token reloaded"
   end
end

return M
