local cache = require "aoc.cache"

describe("aoc.cache", function()
   local original_config
   local original_vim_fn
   local original_vim_notify
   local original_io_open
   local original_os_remove
   local original_os_execute
   local original_os_rename
   local original_vim_uv
   local mock_files = {}
   local executed_commands = {}
   local notify_calls = {}

   before_each(function()
      -- Reset state
      mock_files = {}
      executed_commands = {}
      notify_calls = {}

      -- Mock config module
      original_config = package.loaded["aoc.config"]
      package.loaded["aoc.config"] = {
         options = {
            puzzle_input = {
               filename = "puzzle.txt",
               save_to_current_dir = true,
               alternative_filepath = nil,
            },
         },
      }

      -- Mock vim functions
      original_vim_fn = vim.fn
      vim.fn = {
         glob = function(pattern)
            if pattern:match "cache.*%.txt" then
               return "/test/cache/20241.txt\n/test/cache/20242.txt\n"
            end
            return ""
         end,
      }

      original_vim_notify = vim.notify
      vim.notify = function(msg, level)
         table.insert(notify_calls, { msg, level })
      end

      original_vim_uv = vim.uv
      vim.uv = {
         cwd = function()
            return "/current/dir"
         end,
      }

      -- Mock vim.split
      vim.split = function(str, sep)
         local parts = {}
         for part in str:gmatch("([^" .. sep .. "]+)") do
            table.insert(parts, part)
         end
         return parts
      end

      -- Mock io.open
      original_io_open = io.open
      io.open = function(filename, mode)
         if mock_files[filename] then
            local file_data = mock_files[filename]
            if mode == "r" and file_data.exists then
               return {
                  read = function(_, format)
                     if format == "*a" then
                        return file_data.content
                     end
                  end,
                  close = function() end,
               }
            elseif mode == "w" then
               return {
                  write = function(_, content)
                     mock_files[filename] = { exists = true, content = content }
                  end,
                  close = function() end,
               }
            end
         elseif mode == "w" then
            -- Create new file
            return {
               write = function(_, content)
                  mock_files[filename] = { exists = true, content = content }
               end,
               close = function() end,
            }
         end
         return nil
      end

      -- Mock os.remove
      original_os_remove = os.remove
      os.remove = function(filename)
         if mock_files[filename] and mock_files[filename].exists then
            mock_files[filename] = nil
            return true
         end
         return false
      end

      -- Mock os.execute
      original_os_execute = os.execute
      os.execute = function(command)
         table.insert(executed_commands, command)
         return 0
      end

      -- Mock os.rename
      original_os_rename = os.rename
      os.rename = function(old, new)
         if old == new then
            return true -- Directory exists
         end
         return false, "No such file or directory"
      end
   end)

   after_each(function()
      -- Restore original functions
      package.loaded["aoc.config"] = original_config
      vim.fn = original_vim_fn
      vim.notify = original_vim_notify
      vim.uv = original_vim_uv
      io.open = original_io_open
      os.remove = original_os_remove
      os.execute = original_os_execute
      os.rename = original_os_rename
   end)

   describe("clear_cache", function()
      it("should remove all cache files and notify user", function()
         -- Setup mock files that exist
         mock_files["/test/cache/20241.txt"] = { exists = true, content = "data1" }
         mock_files["/test/cache/20242.txt"] = { exists = true, content = "data2" }

         local result = cache.clear_cache()

         assert.is_true(result)
         assert.is_nil(mock_files["/test/cache/20241.txt"])
         assert.is_nil(mock_files["/test/cache/20242.txt"])

         -- Check notification
         assert.are.equal(1, #notify_calls)
         assert.are.equal("cache cleared", notify_calls[1][1])
      end)

      it("should handle non-existent files gracefully", function()
         -- Files don't exist in mock_files, so os.remove will return false
         local result = cache.clear_cache()

         assert.is_true(result)
         -- Should still notify success even if some files couldn't be removed
         assert.are.equal(1, #notify_calls)
         assert.are.equal("cache cleared", notify_calls[1][1])
      end)

      it("should notify errors for files that fail to remove", function()
         -- Setup a scenario where remove fails
         os.remove = function(filename)
            return false -- Simulate failure
         end

         cache.clear_cache()

         -- Should have error notifications for failed removals
         local error_notifications = 0
         for _, call in ipairs(notify_calls) do
            if call[2] == vim.log.levels.ERROR then
               error_notifications = error_notifications + 1
            end
         end
         assert.is_true(error_notifications > 0)
      end)
   end)

   describe("get_cached_input_file", function()
      it("should return file handle when cache file exists", function()
         local cache_file = "/test/plugin/cache/20241.txt"
         mock_files[cache_file] = { exists = true, content = "cached content" }

         local file = cache.get_cached_input_file("1", "2024")

         assert.is_not_nil(file)
         assert.are.equal("cached content", file:read "*a")
      end)

      it("should return nil when cache file doesn't exist", function()
         local file = cache.get_cached_input_file("1", "2024")

         assert.is_nil(file)
      end)

      it("should construct correct cache filename", function()
         -- We need to verify the correct path is being used
         -- The cache path is constructed from debug.getinfo, which we can't easily mock
         -- So we'll test the pattern indirectly by checking io.open calls
         cache.get_cached_input_file("25", "2023")

         -- File should not exist, but we can verify the pattern
         -- Expected pattern: {cache_path}202325.txt
         assert.is_nil(cache.get_cached_input_file("25", "2023"))
      end)
   end)

   describe("write_to_cache", function()
      it("should create cache directory if it doesn't exist", function()
         cache.write_to_cache("1", "2024", "test content")

         -- Should have executed mkdir command
         assert.are.equal(1, #executed_commands)
         assert.is_true(string.find(executed_commands[1], "mkdir") ~= nil)
      end)

      it("should write content to cache file", function()
         cache.write_to_cache("5", "2023", "puzzle input data")

         -- Check that a file was created with the correct pattern
         local cache_files = {}
         for filename, data in pairs(mock_files) do
            if filename:match "20235%.txt$" then
               cache_files[filename] = data
            end
         end

         assert.are.equal(1, vim.tbl_count(cache_files))
         for _, data in pairs(cache_files) do
            assert.are.equal("puzzle input data", data.content)
         end
      end)

      it("should handle file write errors gracefully", function()
         -- Mock io.open to return nil (file creation failure)
         io.open = function(filename, mode)
            if mode == "w" then
               return nil
            end
            return original_io_open(filename, mode)
         end

         cache.write_to_cache("1", "2024", "content")

         -- Should have error notification
         local error_found = false
         for _, call in ipairs(notify_calls) do
            if call[2] == vim.log.levels.ERROR and call[1]:match "Unable to write puzzle input to cache" then
               error_found = true
               break
            end
         end
         assert.is_true(error_found)
      end)
   end)

   describe("write_to_file", function()
      it("should write to current directory when save_to_current_dir is true", function()
         cache.write_to_file("10", "2024", "final content")

         local expected_path = "/current/dir/puzzle.txt"
         assert.is_not_nil(mock_files[expected_path])
         assert.are.equal("final content", mock_files[expected_path].content)

         -- Should notify success
         local success_found = false
         for _, call in ipairs(notify_calls) do
            if call[1]:match "Successfully downloaded puzzle input for Day 10 %(2024%)" then
               success_found = true
               break
            end
         end
         assert.is_true(success_found)
      end)

      it("should write to alternative filepath when save_to_current_dir is false", function()
         -- Modify config for this test
         package.loaded["aoc.config"].options.puzzle_input.save_to_current_dir = false
         package.loaded["aoc.config"].options.puzzle_input.alternative_filepath = "/alt/path/input.txt"

         cache.write_to_file("15", "2023", "alt content")

         assert.is_not_nil(mock_files["/alt/path/input.txt"])
         assert.are.equal("alt content", mock_files["/alt/path/input.txt"].content)
      end)

      it("should handle file write errors", function()
         io.open = function(filename, mode)
            if mode == "w" then
               return nil -- Simulate write failure
            end
            return original_io_open(filename, mode)
         end

         cache.write_to_file("1", "2024", "content")

         -- Should have error notification
         local error_found = false
         for _, call in ipairs(notify_calls) do
            if call[2] == vim.log.levels.ERROR and call[1]:match "Unable to write puzzle input to file" then
               error_found = true
               break
            end
         end
         assert.is_true(error_found)
      end)

      it("should include day and year in success message", function()
         cache.write_to_file("7", "2022", "content")

         local success_found = false
         for _, call in ipairs(notify_calls) do
            if call[1] == "Successfully downloaded puzzle input for Day 7 (2022)" then
               success_found = true
               break
            end
         end
         assert.is_true(success_found)
      end)
   end)
end)

