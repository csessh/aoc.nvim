local config = require "aoc.config"

describe("aoc.config", function()
   local original_fn_expand

   before_each(function()
      -- Reset config state
      config.options = nil

      -- Mock vim.fn.expand
      original_fn_expand = vim.fn.expand
      vim.fn.expand = function(path)
         if path == "~/test.txt" then
            return "/home/user/test.txt"
         elseif path == "~/alt.txt" then
            return "/home/user/alt.txt"
         else
            return path
         end
      end
   end)

   after_each(function()
      vim.fn.expand = original_fn_expand
   end)

   describe("init", function()
      it("should initialize with default options when no args provided", function()
         config.init()

         assert.is_not_nil(config.options)
         assert.are.equal("/var/tmp/aoc.txt", config.options.session_filepath)
         assert.are.equal("puzzle.txt", config.options.puzzle_input.filename)
         assert.are.equal(true, config.options.puzzle_input.save_to_current_dir)
         assert.is_nil(config.options.puzzle_input.alternative_filepath)
      end)

      it("should initialize with empty table when args is empty", function()
         config.init {}

         assert.is_not_nil(config.options)
         assert.are.equal("/var/tmp/aoc.txt", config.options.session_filepath)
         assert.are.equal("puzzle.txt", config.options.puzzle_input.filename)
         assert.are.equal(true, config.options.puzzle_input.save_to_current_dir)
         assert.is_nil(config.options.puzzle_input.alternative_filepath)
      end)

      it("should merge user options with defaults", function()
         local user_opts = {
            session_filepath = "~/test.txt",
            puzzle_input = {
               filename = "input.txt",
               save_to_current_dir = false,
            },
         }

         config.init(user_opts)

         assert.are.equal("/home/user/test.txt", config.options.session_filepath)
         assert.are.equal("input.txt", config.options.puzzle_input.filename)
         assert.are.equal(false, config.options.puzzle_input.save_to_current_dir)
         assert.is_nil(config.options.puzzle_input.alternative_filepath)
      end)

      it("should expand session_filepath with vim.fn.expand", function()
         config.init { session_filepath = "~/test.txt" }

         assert.are.equal("/home/user/test.txt", config.options.session_filepath)
      end)

      it("should expand alternative_filepath when provided", function()
         local user_opts = {
            puzzle_input = {
               alternative_filepath = "~/alt.txt",
            },
         }

         config.init(user_opts)

         assert.are.equal("/home/user/alt.txt", config.options.puzzle_input.alternative_filepath)
      end)

      it("should not expand alternative_filepath when nil", function()
         config.init()

         assert.is_nil(config.options.puzzle_input.alternative_filepath)
      end)

      it("should preserve other default values when partially overriding", function()
         local user_opts = {
            session_filepath = "/custom/path.txt",
         }

         config.init(user_opts)

         -- User override
         assert.are.equal("/custom/path.txt", config.options.session_filepath)

         -- Preserved defaults
         assert.are.equal("puzzle.txt", config.options.puzzle_input.filename)
         assert.are.equal(true, config.options.puzzle_input.save_to_current_dir)
         assert.is_nil(config.options.puzzle_input.alternative_filepath)
      end)

      it("should handle deep nested option overrides", function()
         local user_opts = {
            puzzle_input = {
               filename = "custom.txt",
               -- save_to_current_dir not specified, should keep default
            },
         }

         config.init(user_opts)

         assert.are.equal("custom.txt", config.options.puzzle_input.filename)
         assert.are.equal(true, config.options.puzzle_input.save_to_current_dir) -- default preserved
         assert.is_nil(config.options.puzzle_input.alternative_filepath)
      end)
   end)

   describe("debug", function()
      local original_print
      local printed_output

      before_each(function()
         original_print = print
         printed_output = ""
         print = function(...)
            printed_output = printed_output .. table.concat({ ... }, "\t") .. "\n"
         end

         -- Mock vim.inspect to return a simple string representation
         vim.inspect = function(obj)
            if type(obj) == "table" then
               local result = "{\n"
               for k, v in pairs(obj) do
                  if type(v) == "table" then
                     result = result .. "  " .. k .. " = {...},\n"
                  else
                     result = result .. "  " .. k .. " = " .. tostring(v) .. ",\n"
                  end
               end
               result = result .. "}"
               return result
            else
               return tostring(obj)
            end
         end
      end)

      after_each(function()
         print = original_print
      end)

      it("should print current options", function()
         config.init {
            session_filepath = "/test/path.txt",
            puzzle_input = {
               filename = "test.txt",
            },
         }

         config.debug()

         assert.is_true(string.find(printed_output, "session_filepath") ~= nil)
         assert.is_true(string.find(printed_output, "puzzle_input") ~= nil)
      end)

      it("should work when options is nil", function()
         config.options = nil

         -- Should not error
         assert.has_no.errors(function()
            config.debug()
         end)
      end)
   end)
end)

