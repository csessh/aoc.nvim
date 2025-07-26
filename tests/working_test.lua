-- Working test suite for aoc.nvim
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h")
package.path = plugin_path .. "/lua/?.lua;" .. package.path

-- Set up all mocks before requiring any modules
local mock_time = 0
local cache_calls = {}
local http_calls = {}
local notifications = {}

-- Mock vim functions
vim.notify = function(msg, level) 
   table.insert(notifications, {msg, level})
end
vim.tbl_deep_extend = function(behavior, ...) return {} end
vim.fn = {expand = function(p) return p end}
vim.log = {levels = {ERROR = 1}}
vim.uv = {
   now = function() return mock_time end,
   cwd = function() return "/test/dir" end
}

-- Mock dependencies BEFORE requiring modules
package.preload["plenary.curl"] = function()
   return {
      get = function(opts)
         table.insert(http_calls, opts)
         return {status = 200, body = "test_input_data"}
      end
   }
end

package.preload["aoc.config"] = function()
   return {
      options = {
         session_filepath = "/tmp/test_session.txt",
         puzzle_input = {
            filename = "puzzle.txt",
            save_to_current_dir = true,
            alternative_filepath = nil
         }
      }
   }
end

package.preload["aoc.cache"] = function()
   return {
      get_cached_input_file = function(day, year)
         table.insert(cache_calls, {"cache_check", day, year})
         return nil -- No cache hit
      end,
      write_to_cache = function(day, year, content)
         table.insert(cache_calls, {"write_cache", day, year, content})
      end,
      write_to_file = function(day, year, content)
         table.insert(cache_calls, {"write_file", day, year, content})
      end
   }
end

-- Mock file system
io.open = function(filename, mode)
   if filename == "/tmp/test_session.txt" and mode == "r" then
      return {
         read = function() return "test_session_token" end,
         close = function() end
      }
   end
   return nil
end

-- Now load the API module
local api = require("aoc.api")

print("Testing aoc.nvim rate limiting...")
print(string.rep("=", 50))

local function reset_state()
   cache_calls = {}
   http_calls = {}
   notifications = {}
   api.session_id = nil
   api.request_timestamps = {}
end

local tests_passed = 0
local tests_total = 0

-- Test 1: Basic functionality
tests_total = tests_total + 1
reset_state()
mock_time = 1000

print("\nTest 1: Basic API call functionality")
api.save_puzzle_input("1", "2024")

local has_cache_check = false
local has_http_call = false
local has_cache_write = false
local has_file_write = false

for _, call in ipairs(cache_calls) do
   if call[1] == "cache_check" then has_cache_check = true end
   if call[1] == "write_cache" then has_cache_write = true end
   if call[1] == "write_file" then has_file_write = true end
end

has_http_call = #http_calls > 0

if has_cache_check and has_http_call and has_cache_write and has_file_write then
   tests_passed = tests_passed + 1
   print("✓ Basic API call flow works")
else
   print("✗ Basic API call flow failed")
   print("  Cache check: " .. tostring(has_cache_check))
   print("  HTTP call: " .. tostring(has_http_call))  
   print("  Cache write: " .. tostring(has_cache_write))
   print("  File write: " .. tostring(has_file_write))
end

-- Test 2: Rate limiting - allow under limit
tests_total = tests_total + 1
reset_state()

print("\nTest 2: Allow 5 requests under rate limit")
for i = 1, 5 do
   mock_time = i * 1000
   api.save_puzzle_input(tostring(i), "2024")
end

if #http_calls == 5 then
   tests_passed = tests_passed + 1
   print("✓ All 5 requests processed")
else
   print("✗ Expected 5 HTTP calls, got " .. #http_calls)
end

-- Test 3: Rate limiting - block over limit
tests_total = tests_total + 1
reset_state()

print("\nTest 3: Block 6th request (rate limit)")
-- Make 5 requests quickly
for i = 1, 5 do
   mock_time = i * 100 -- Small increments within rate window
   api.save_puzzle_input(tostring(i), "2024")
end

-- Try 6th request
local before_6th = #http_calls
mock_time = 600
api.save_puzzle_input("6", "2024")
local after_6th = #http_calls

-- Check for rate limit notification
local rate_limit_notified = false
for _, notif in ipairs(notifications) do
   if notif[1]:match("Rate limit exceeded") then
      rate_limit_notified = true
      break
   end
end

if before_6th == 5 and after_6th == 5 and rate_limit_notified then
   tests_passed = tests_passed + 1
   print("✓ 6th request blocked by rate limiter")
else
   print("✗ Rate limiting failed")
   print("  HTTP calls before 6th: " .. before_6th)
   print("  HTTP calls after 6th: " .. after_6th)  
   print("  Rate limit notified: " .. tostring(rate_limit_notified))
end

-- Test 4: Rate limiting - allow after window expires
tests_total = tests_total + 1
reset_state()

print("\nTest 4: Allow request after rate window expires")
-- Make 5 requests
for i = 1, 5 do
   mock_time = i * 1000
   api.save_puzzle_input(tostring(i), "2024")
end

-- Wait for window to expire (60+ seconds)
mock_time = 70000
api.save_puzzle_input("6", "2024")

if #http_calls == 6 then
   tests_passed = tests_passed + 1
   print("✓ Request allowed after rate window expired")
else
   print("✗ Request not allowed after window expiry")
   print("  HTTP calls: " .. #http_calls)
end

-- Test 5: Session token caching
tests_total = tests_total + 1
reset_state()

print("\nTest 5: Session token caching")
api.save_puzzle_input("1", "2024")
local first_token = api.session_id

api.save_puzzle_input("2", "2024")
local second_token = api.session_id

if first_token == "test_session_token" and second_token == first_token then
   tests_passed = tests_passed + 1
   print("✓ Session token cached correctly")
else
   print("✗ Session token caching failed")
   print("  First token: " .. tostring(first_token))
   print("  Second token: " .. tostring(second_token))
end

-- Summary
print("\n" .. string.rep("=", 50))
print("TEST SUMMARY")
print(string.rep("=", 50))
print(string.format("Tests passed: %d/%d", tests_passed, tests_total))

if tests_passed == tests_total then
   print("✅ All tests passed!")
   
   -- Show rate limiting is working
   print("\n📊 RATE LIMITING VERIFICATION:")
   print("• Maximum requests per minute: " .. api.max_requests_per_minute)
   print("• Rate limit window: " .. api.rate_limit_window_ms .. "ms")
   print("• ✓ Rate limiting successfully blocks excess requests")
   print("• ✓ Rate limiting allows requests after window expires")
   
   os.exit(0)
else
   print("❌ Some tests failed")
   os.exit(1)
end