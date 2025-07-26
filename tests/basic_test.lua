-- Basic functionality test for aoc.nvim
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h")
package.path = plugin_path .. "/lua/?.lua;" .. package.path

-- Mock required dependencies
package.preload["plenary.curl"] = function()
   return {
      get = function(opts)
         return {status = 200, body = "test_input_data"}
      end
   }
end

-- Test utils module
print("Testing aoc.utils...")
local utils = require("aoc.utils")

-- Test trim function
local test_cases = {
   {"  hello  ", "hello"},
   {" test ", "test"},
   {"no_spaces", "no_spaces"},
   {"  ", ""},
   {"", ""}
}

local utils_passed = 0
local utils_total = #test_cases

for i, case in ipairs(test_cases) do
   local input, expected = case[1], case[2]
   local result = utils.trim(input)
   if result == expected then
      utils_passed = utils_passed + 1
      print("✓ trim('" .. input .. "') = '" .. result .. "'")
   else
      print("✗ trim('" .. input .. "') = '" .. result .. "', expected '" .. expected .. "'")
   end
end

-- Test config module
print("\nTesting aoc.config...")
local config = require("aoc.config")

-- Mock vim.tbl_deep_extend
vim.tbl_deep_extend = function(behavior, ...)
   local result = {}
   local tables = {...}
   for _, tbl in ipairs(tables) do
      if type(tbl) == "table" then
         for k, v in pairs(tbl) do
            if type(v) == "table" and type(result[k]) == "table" then
               for k2, v2 in pairs(v) do
                  if not result[k] then result[k] = {} end
                  result[k][k2] = v2
               end
            else
               result[k] = v
            end
         end
      end
   end
   return result
end

vim.fn = vim.fn or {}
vim.fn.expand = function(path) return path end

local config_passed = 0
local config_total = 3

-- Test 1: Default initialization
config.init()
if config.options and config.options.session_filepath == "/var/tmp/aoc.txt" then
   config_passed = config_passed + 1
   print("✓ Default initialization works")
else
   print("✗ Default initialization failed")
end

-- Test 2: Custom config
config.init({session_filepath = "/custom/path.txt"})
if config.options and config.options.session_filepath == "/custom/path.txt" then
   config_passed = config_passed + 1
   print("✓ Custom config works")
else
   print("✗ Custom config failed")
end

-- Test 3: Debug function exists
if type(config.debug) == "function" then
   config_passed = config_passed + 1
   print("✓ Debug function exists")
else
   print("✗ Debug function missing")
end

-- Test cache module (basic functionality)
print("\nTesting aoc.cache...")
local cache = require("aoc.cache")

local cache_passed = 0
local cache_total = 2

-- Test 1: Module loads
if cache then
   cache_passed = cache_passed + 1
   print("✓ Cache module loads")
else
   print("✗ Cache module failed to load")
end

-- Test 2: Functions exist
if type(cache.clear_cache) == "function" and 
   type(cache.get_cached_input_file) == "function" and
   type(cache.write_to_cache) == "function" and
   type(cache.write_to_file) == "function" then
   cache_passed = cache_passed + 1
   print("✓ Cache functions exist")
else
   print("✗ Cache functions missing")
end

-- Test API module (basic functionality)
print("\nTesting aoc.api...")
local api = require("aoc.api")

local api_passed = 0
local api_total = 2

-- Test 1: Module loads
if api then
   api_passed = api_passed + 1
   print("✓ API module loads")
else
   print("✗ API module failed to load")
end

-- Test 2: Functions exist
if type(api.save_puzzle_input) == "function" and
   type(api.reload_session_token) == "function" then
   api_passed = api_passed + 1
   print("✓ API functions exist")
else
   print("✗ API functions missing")
end

-- Test main module
print("\nTesting aoc (main module)...")
local aoc = require("aoc.init")

local main_passed = 0
local main_total = 2

-- Test 1: Module loads
if aoc then
   main_passed = main_passed + 1
   print("✓ Main module loads")
else
   print("✗ Main module failed to load")
end

-- Test 2: Setup function exists
if type(aoc.setup) == "function" then
   main_passed = main_passed + 1
   print("✓ Setup function exists")
else
   print("✗ Setup function missing")
end

-- Summary
print("\n" .. string.rep("=", 50))
print("TEST SUMMARY")
print(string.rep("=", 50))
print(string.format("Utils:  %d/%d passed", utils_passed, utils_total))
print(string.format("Config: %d/%d passed", config_passed, config_total))
print(string.format("Cache:  %d/%d passed", cache_passed, cache_total))
print(string.format("API:    %d/%d passed", api_passed, api_total))
print(string.format("Main:   %d/%d passed", main_passed, main_total))

local total_passed = utils_passed + config_passed + cache_passed + api_passed + main_passed
local total_tests = utils_total + config_total + cache_total + api_total + main_total

print(string.format("\nOVERALL: %d/%d tests passed", total_passed, total_tests))

if total_passed == total_tests then
   print("✅ All basic tests passed!")
   os.exit(0)
else
   print("❌ Some tests failed")
   os.exit(1)
end