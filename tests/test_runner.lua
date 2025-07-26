#!/usr/bin/env nvim -l

-- Test runner for aoc.nvim plugin
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h")
package.path = plugin_path .. "/lua/?.lua;" .. plugin_path .. "/tests/?.lua;" .. package.path

-- Load mock setup first
require("mock_setup")

-- Simple test framework
local TestRunner = {
   stats = {total = 0, passed = 0, failed = 0, errors = {}},
   current_describe = "",
   current_it = ""
}

-- Test framework functions
function describe(description, callback)
   TestRunner.current_describe = description
   print("● " .. description)
   if callback then callback() end
   TestRunner.current_describe = ""
end

function it(description, callback)
   TestRunner.current_it = description
   TestRunner.stats.total = TestRunner.stats.total + 1
   
   local success, err = pcall(callback)
   
   if success then
      TestRunner.stats.passed = TestRunner.stats.passed + 1
      print("  ✓ " .. description)
   else
      TestRunner.stats.failed = TestRunner.stats.failed + 1
      local full_name = TestRunner.current_describe .. " → " .. description
      table.insert(TestRunner.stats.errors, {name = full_name, error = err})
      print("  ✗ " .. description)
      print("    " .. tostring(err))
   end
   
   TestRunner.current_it = ""
end

function before_each(callback)
   _G._before_each = callback
end

function after_each(callback)
   _G._after_each = callback
end

-- Assertion library
assert = {}

assert.are = {
   equal = function(expected, actual)
      if expected ~= actual then
         error(string.format("Expected %s, got %s", tostring(expected), tostring(actual)))
      end
   end,
   same = function(expected, actual)
      local function compare_tables(t1, t2)
         if type(t1) ~= type(t2) then return false end
         if type(t1) ~= "table" then return t1 == t2 end
         
         for k, v in pairs(t1) do
            if not compare_tables(v, t2[k]) then return false end
         end
         for k, v in pairs(t2) do
            if not compare_tables(v, t1[k]) then return false end
         end
         return true
      end
      
      if not compare_tables(expected, actual) then
         error(string.format("Tables are not the same"))
      end
   end
}

assert.is = {
   ['true'] = function(value)
      if value ~= true then
         error("Expected true, got " .. tostring(value))
      end
   end,
   ['false'] = function(value) 
      if value ~= false then
         error("Expected false, got " .. tostring(value))
      end
   end,
   ['nil'] = function(value)
      if value ~= nil then
         error("Expected nil, got " .. tostring(value))
      end
   end,
   not_nil = function(value)
      if value == nil then
         error("Expected non-nil value")
      end
   end,
   ['function'] = function(value)
      if type(value) ~= "function" then
         error("Expected function, got " .. type(value))
      end
   end,
   table = function(value)
      if type(value) ~= "table" then
         error("Expected table, got " .. type(value))
      end
   end
}

function assert.is_true(value)
   assert.is['true'](value)
end

function assert.is_nil(value)
   assert.is['nil'](value)
end

function assert.is_not_nil(value)
   assert.is.not_nil(value)
end

assert.has_no = {
   errors = function(callback)
      local success, err = pcall(callback)
      if not success then
         error("Expected no errors, but got: " .. tostring(err))
      end
   end
}

-- Get test files to run
local function get_test_files(pattern)
   local test_files = {}
   local test_dir = plugin_path .. "/tests"
   
   if pattern then
      if pattern:match("%.lua$") then
         table.insert(test_files, test_dir .. "/" .. pattern)
      else
         table.insert(test_files, test_dir .. "/test_" .. pattern .. ".lua")
      end
   else
      -- All test files
      local handle = io.popen('find "' .. test_dir .. '" -name "test_*.lua" 2>/dev/null | sort')
      if handle then
         for file in handle:lines() do
            table.insert(test_files, file)
         end
         handle:close()
      end
   end
   
   return test_files
end

-- Run tests
local function run_tests()
   local pattern = arg and arg[1]
   local test_files = get_test_files(pattern)
   
   if #test_files == 0 then
      print("No test files found" .. (pattern and " matching: " .. pattern or ""))
      os.exit(1)
   end
   
   print("Running tests...\n")
   
   for _, test_file in ipairs(test_files) do
      local file_name = test_file:match("([^/]+)%.lua$")
      print("📁 " .. file_name)
      
      -- Execute callbacks if they exist
      if _G._before_each then 
         pcall(_G._before_each)
      end
      
      local success, err = pcall(dofile, test_file)
      if not success then
         print("  ✗ Failed to load test file: " .. tostring(err))
         TestRunner.stats.failed = TestRunner.stats.failed + 1
         TestRunner.stats.total = TestRunner.stats.total + 1
      end
      
      if _G._after_each then 
         pcall(_G._after_each) 
      end
      
      print("")
   end
   
   -- Print summary
   print("Test Results:")
   print("=============")
   print(string.format("Total: %d", TestRunner.stats.total))
   print(string.format("Passed: %d", TestRunner.stats.passed))
   print(string.format("Failed: %d", TestRunner.stats.failed))
   
   if #TestRunner.stats.errors > 0 then
      print("\nFailures:")
      for i, error_info in ipairs(TestRunner.stats.errors) do
         print(string.format("%d. %s", i, error_info.name))
         print("   " .. tostring(error_info.error))
      end
   end
   
   print("")
   
   if TestRunner.stats.failed > 0 then
      print("❌ Tests failed")
      os.exit(1)
   else
      print("✅ All tests passed!")
      os.exit(0)
   end
end

-- Run the tests
run_tests()