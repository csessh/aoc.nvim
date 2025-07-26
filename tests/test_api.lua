local api = require "aoc.api"

describe("aoc.api", function()
   local original_cache
   local original_cfg
   local original_curl
   local original_io_open
   local original_vim_notify
   local original_vim_uv
   local original_os_date
   local mock_session_file_content
   local cache_calls = {}
   local notify_calls = {}
   local curl_calls = {}
   local current_time

   before_each(function()
      -- Reset state
      api.session_id = nil
      api.request_timestamps = {}
      cache_calls = {}
      notify_calls = {}
      curl_calls = {}
      current_time = 1000000
      mock_session_file_content = "mock_session_token_12345"

      -- Mock cache module
      original_cache = package.loaded["aoc.cache"]
      package.loaded["aoc.cache"] = {
         get_cached_input_file = function(day, year)
            table.insert(cache_calls, { "get_cached_input_file", day, year })
            return nil -- Default: no cache
         end,
         write_to_cache = function(day, year, content)
            table.insert(cache_calls, { "write_to_cache", day, year, content })
         end,
         write_to_file = function(day, year, content)
            table.insert(cache_calls, { "write_to_file", day, year, content })
         end,
      }

      -- Mock config module
      original_cfg = package.loaded["aoc.config"]
      package.loaded["aoc.config"] = {
         options = {
            session_filepath = "/tmp/test_session.txt",
         },
      }

      -- Mock plenary.curl
      original_curl = package.loaded["plenary.curl"]
      package.loaded["plenary.curl"] = {
         get = function(opts)
            table.insert(curl_calls, { "get", opts })
            return {
               status = 200,
               body = "mock_puzzle_input_content",
            }
         end,
      }

      -- Mock io.open
      original_io_open = io.open
      io.open = function(filename, mode)
         if filename == "/tmp/test_session.txt" and mode == "r" then
            return {
               read = function(_, format)
                  if format == "*a" then
                     return mock_session_file_content
                  end
               end,
               close = function() end,
            }
         end
         return nil
      end

      -- Mock vim.notify
      original_vim_notify = vim.notify
      vim.notify = function(msg, level)
         table.insert(notify_calls, { msg, level })
      end

      -- Mock vim.uv.now for rate limiting
      original_vim_uv = vim.uv
      vim.uv = {
         now = function()
            return current_time
         end,
      }

      -- Mock os.date
      original_os_date = os.date
      os.date = function(format)
         if format == "%d" then
            return "15"
         elseif format == "%Y" then
            return "2024"
         end
         return "2024-12-15"
      end
   end)

   after_each(function()
      -- Restore original modules
      package.loaded["aoc.cache"] = original_cache
      package.loaded["aoc.config"] = original_cfg
      package.loaded["plenary.curl"] = original_curl
      io.open = original_io_open
      vim.notify = original_vim_notify
      vim.uv = original_vim_uv
      os.date = original_os_date
   end)

   describe("save_puzzle_input", function()
      describe("input validation", function()
         it("should reject nil day", function()
            api.save_puzzle_input(nil, "2024")

            assert.are.equal(1, #notify_calls)
            assert.are.equal("Day is not valid or is not specified", notify_calls[1][1])
            assert.are.equal(vim.log.levels.ERROR, notify_calls[1][2])
         end)

         it("should reject empty day", function()
            api.save_puzzle_input("", "2024")

            assert.are.equal(1, #notify_calls)
            assert.are.equal("Day is not valid or is not specified", notify_calls[1][1])
         end)

         it("should reject nil year", function()
            api.save_puzzle_input("1", nil)

            assert.are.equal(1, #notify_calls)
            assert.are.equal("Year is not valid of is not specified", notify_calls[1][1])
         end)

         it("should reject invalid day range", function()
            api.save_puzzle_input("0", "2024")

            assert.are.equal(1, #notify_calls)
            assert.are.equal("Invalid day: 0", notify_calls[1][1])

            notify_calls = {}
            api.save_puzzle_input("32", "2024")

            assert.are.equal(1, #notify_calls)
            assert.are.equal("Invalid day: 32", notify_calls[1][1])
         end)

         it("should reject invalid year", function()
            api.save_puzzle_input("1", "2014")

            assert.are.equal(1, #notify_calls)
            assert.are.equal("Invalid year: 2014", notify_calls[1][1])
         end)

         it("should accept valid inputs", function()
            api.save_puzzle_input("1", "2024")

            -- Should not have validation errors
            local error_count = 0
            for _, call in ipairs(notify_calls) do
               if call[2] == vim.log.levels.ERROR and (call[1]:match "Invalid" or call[1]:match "not valid") then
                  error_count = error_count + 1
               end
            end
            assert.are.equal(0, error_count)
         end)
      end)

      describe("cache handling", function()
         it("should use cached content when available", function()
            -- Setup cache to return content
            package.loaded["aoc.cache"].get_cached_input_file = function(day, year)
               table.insert(cache_calls, { "get_cached_input_file", day, year })
               return {
                  read = function(_, format)
                     return "cached_content"
                  end,
                  close = function() end,
               }
            end

            api.save_puzzle_input("1", "2024")

            -- Should check cache
            assert.are.equal(1, #cache_calls)
            assert.are.same({ "get_cached_input_file", "1", "2024" }, cache_calls[1])

            -- Should write cached content to file
            assert.are.equal(2, #cache_calls)
            assert.are.same({ "write_to_file", "1", "2024", "cached_content" }, cache_calls[2])

            -- Should not make HTTP request
            assert.are.equal(0, #curl_calls)
         end)

         it("should make HTTP request when cache miss", function()
            api.save_puzzle_input("2", "2024")

            -- Should check cache first
            assert.are.equal(1, #cache_calls)
            assert.are.same({ "get_cached_input_file", "2", "2024" }, cache_calls[1])

            -- Should make HTTP request
            assert.are.equal(1, #curl_calls)
            assert.are.equal("get", curl_calls[1][1])

            local request_opts = curl_calls[1][2]
            assert.are.equal("https://adventofcode.com/2024/day/2/input", request_opts.url)
            assert.are.equal("session=mock_session_token_12345", request_opts.headers.cookie)
            assert.are.equal("<github.com/csessh/aoc.nvim> by csessh@hey.com", request_opts.headers.user_agent)
         end)
      end)

      describe("rate limiting", function()
         it("should allow requests under rate limit", function()
            for i = 1, 5 do
               current_time = i * 1000
               api.save_puzzle_input(tostring(i), "2024")
            end

            -- All 5 requests should go through
            assert.are.equal(5, #curl_calls)

            -- No rate limit errors
            local rate_limit_errors = 0
            for _, call in ipairs(notify_calls) do
               if call[1]:match "Rate limit exceeded" then
                  rate_limit_errors = rate_limit_errors + 1
               end
            end
            assert.are.equal(0, rate_limit_errors)
         end)

         it("should block requests over rate limit", function()
            -- Make 5 requests quickly
            for i = 1, 5 do
               current_time = i * 100 -- Small time increments
               api.save_puzzle_input(tostring(i), "2024")
            end

            -- Try 6th request
            current_time = 600
            api.save_puzzle_input("6", "2024")

            -- Should have 5 successful requests
            assert.are.equal(5, #curl_calls)

            -- Should have rate limit error for 6th request
            local rate_limit_found = false
            for _, call in ipairs(notify_calls) do
               if call[1]:match "Rate limit exceeded" and call[2] == vim.log.levels.ERROR then
                  rate_limit_found = true
                  break
               end
            end
            assert.is_true(rate_limit_found)
         end)

         it("should allow requests after rate limit window expires", function()
            -- Make 5 requests
            for i = 1, 5 do
               current_time = i * 1000
               api.save_puzzle_input(tostring(i), "2024")
            end

            -- Wait for rate limit window to expire (60+ seconds)
            current_time = 70000
            api.save_puzzle_input("6", "2024")

            -- Should have 6 successful requests
            assert.are.equal(6, #curl_calls)
         end)
      end)

      describe("session token handling", function()
         it("should load session token from file", function()
            api.save_puzzle_input("1", "2024")

            assert.are.equal(1, #curl_calls)
            local request_opts = curl_calls[1][2]
            assert.are.equal("session=mock_session_token_12345", request_opts.headers.cookie)
         end)

         it("should cache session token in memory", function()
            api.save_puzzle_input("1", "2024")
            api.save_puzzle_input("2", "2024")

            -- Session should be cached after first load
            assert.are.equal("mock_session_token_12345", api.session_id)
         end)

         it("should handle missing session file", function()
            io.open = function(filename, mode)
               return nil -- File doesn't exist
            end

            api.save_puzzle_input("1", "2024")

            -- Should have error notification
            local error_found = false
            for _, call in ipairs(notify_calls) do
               if call[1]:match "Unable to open session file" and call[2] == vim.log.levels.ERROR then
                  error_found = true
                  break
               end
            end
            assert.is_true(error_found)

            -- Should not make HTTP request
            assert.are.equal(0, #curl_calls)
         end)
      end)

      describe("HTTP response handling", function()
         it("should handle successful response", function()
            api.save_puzzle_input("1", "2024")

            -- Should write to cache and file
            assert.are.equal(3, #cache_calls)
            assert.are.same({ "write_to_cache", "1", "2024", "mock_puzzle_input_content" }, cache_calls[2])
            assert.are.same({ "write_to_file", "1", "2024", "mock_puzzle_input_content" }, cache_calls[3])
         end)

         it("should handle error response", function()
            package.loaded["plenary.curl"].get = function(opts)
               table.insert(curl_calls, { "get", opts })
               return {
                  status = 404,
                  body = "Puzzle not found",
               }
            end

            api.save_puzzle_input("1", "2024")

            -- Should have error notification
            local error_found = false
            for _, call in ipairs(notify_calls) do
               if call[1] == "Puzzle not found" and call[2] == vim.log.levels.ERROR then
                  error_found = true
                  break
               end
            end
            assert.is_true(error_found)

            -- Should not write to cache or file
            assert.are.equal(1, #cache_calls) -- Only the initial cache check
         end)
      end)
   end)

   describe("reload_session_token", function()
      it("should reload session token and notify success", function()
         api.session_id = "old_token"

         api.reload_session_token()

         assert.are.equal("mock_session_token_12345", api.session_id)
         assert.are.equal(1, #notify_calls)
         assert.are.equal("Session token reloaded", notify_calls[1][1])
      end)

      it("should handle missing session file gracefully", function()
         io.open = function(filename, mode)
            return nil
         end

         api.reload_session_token()

         assert.is_nil(api.session_id)
         -- Should not notify success when token loading fails
         local success_notifications = 0
         for _, call in ipairs(notify_calls) do
            if call[1] == "Session token reloaded" then
               success_notifications = success_notifications + 1
            end
         end
         assert.are.equal(0, success_notifications)
      end)
   end)
end)

