-- Rate limiting test for aoc.nvim
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h")
package.path = plugin_path .. "/lua/?.lua;" .. package.path

-- Mock dependencies
package.preload["plenary.curl"] = function()
   return {
      get = function(opts)
         return {status = 200, body = "test_input_data"}
      end
   }
end

-- Mock vim functions
vim.notify = function(msg, level) 
   print("NOTIFY: " .. msg .. " (level: " .. tostring(level) .. ")")
end
vim.tbl_deep_extend = function(behavior, ...) return {} end
vim.fn = {expand = function(p) return p end}
vim.log = {levels = {ERROR = 1}}

-- Mock time for rate limiting tests
local mock_time = 0
vim.uv = {
   now = function() return mock_time end,
   cwd = function() return "/test/dir" end
}

-- Mock config first (before loading API)
package.loaded["aoc.config"] = {
   options = {
      session_filepath = "/tmp/test_session.txt",
      puzzle_input = {
         filename = "puzzle.txt",
         save_to_current_dir = true,
         alternative_filepath = nil
      }
   }
}

-- Load API module
local api = require("aoc.api")

-- Mock cache
local cache_calls = {}
package.loaded["aoc.cache"] = {
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

print("Testing rate limiting functionality...")
print(string.rep("=", 50))

-- Reset API state
api.session_id = nil
api.request_timestamps = {}

local tests_passed = 0
local tests_total = 0

-- Test 1: Should allow requests under rate limit
tests_total = tests_total + 1
cache_calls = {}
mock_time = 1000

print("\nTest 1: Allow requests under limit")
for i = 1, 5 do
   mock_time = i * 1000
   api.save_puzzle_input(tostring(i), "2024")
end

if #cache_calls == 15 then -- 5 requests * 3 calls each (cache_check, write_cache, write_file)
   tests_passed = tests_passed + 1
   print("✓ All 5 requests processed successfully")
else
   print("✗ Expected 15 cache calls, got " .. #cache_calls)
end

-- Test 2: Should block 6th request due to rate limit
tests_total = tests_total + 1
cache_calls = {}

print("\nTest 2: Block request over limit")
local original_notify = vim.notify
local notifications = {}
vim.notify = function(msg, level)
   if msg:match("Rate limit exceeded") then
      table.insert(notifications, {msg, level})
   end
end

mock_time = 6000 -- Still within rate limit window
api.save_puzzle_input("6", "2024")

vim.notify = original_notify

if #notifications == 1 and #cache_calls == 1 then -- Only cache check, no write operations
   tests_passed = tests_passed + 1
   print("✓ 6th request blocked by rate limiter")
else
   print("✗ 6th request was not properly blocked")
   print("  Notifications: " .. #notifications)
   print("  Cache calls: " .. #cache_calls)
end

-- Test 3: Should allow request after rate limit window expires
tests_total = tests_total + 1
cache_calls = {}

print("\nTest 3: Allow request after window expires")
mock_time = 70000 -- 70 seconds later, window expired
api.save_puzzle_input("7", "2024")

if #cache_calls == 3 then -- cache_check, write_cache, write_file
   tests_passed = tests_passed + 1
   print("✓ Request allowed after rate limit window expired")
else
   print("✗ Request after window expiry failed")
   print("  Cache calls: " .. #cache_calls)
end

-- Test 4: Verify rate limit configuration
tests_total = tests_total + 1
if api.max_requests_per_minute == 5 and api.rate_limit_window_ms == 60000 then
   tests_passed = tests_passed + 1
   print("\nTest 4: ✓ Rate limit configuration correct (5 requests per 60 seconds)")
else
   print("\nTest 4: ✗ Rate limit configuration incorrect")
   print("  Max requests: " .. tostring(api.max_requests_per_minute))
   print("  Window: " .. tostring(api.rate_limit_window_ms))
end

-- Test 5: Session token caching
tests_total = tests_total + 1
api.session_id = nil -- Reset
api.save_puzzle_input("1", "2024")

if api.session_id == "test_session_token" then
   tests_passed = tests_passed + 1
   print("\nTest 5: ✓ Session token cached correctly")
else
   print("\nTest 5: ✗ Session token not cached")
   print("  Expected: test_session_token")
   print("  Got: " .. tostring(api.session_id))
end

-- Summary
print("\n" .. string.rep("=", 50))
print("RATE LIMITING TEST SUMMARY")
print(string.rep("=", 50))
print(string.format("Tests passed: %d/%d", tests_passed, tests_total))

if tests_passed == tests_total then
   print("✅ All rate limiting tests passed!")
   os.exit(0)
else
   print("❌ Some rate limiting tests failed")
   os.exit(1)
end