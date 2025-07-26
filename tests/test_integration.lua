local aoc = require("aoc")

describe("aoc integration tests", function()
  local original_vim_api
  local original_vim_fn
  local user_commands = {}
  local input_responses = {}
  local output_messages = {}

  before_each(function()
    -- Reset state
    user_commands = {}
    input_responses = {}
    output_messages = {}

    -- Mock vim.api
    original_vim_api = vim.api
    vim.api = {
      nvim_create_user_command = function(name, callback, opts)
        user_commands[name] = {callback = callback, opts = opts}
      end,
      nvim_out_write = function(text)
        table.insert(output_messages, text)
      end
    }

    -- Mock vim.fn
    original_vim_fn = vim.fn
    vim.fn = {
      input = function(prompt)
        local response = input_responses[prompt]
        if response then
          return response
        end
        return ""
      end,
      expand = function(path)
        return path -- No expansion for tests
      end
    }

    -- Mock vim.tbl_deep_extend
    vim.tbl_deep_extend = function(behavior, ...)
      local result = {}
      local tables = {...}
      for _, tbl in ipairs(tables) do
        if type(tbl) == "table" then
          for k, v in pairs(tbl) do
            if type(v) == "table" and type(result[k]) == "table" then
              result[k] = vim.tbl_deep_extend(behavior, result[k], v)
            else
              result[k] = v
            end
          end
        end
      end
      return result
    end

    -- Mock vim.notify
    vim.notify = function(msg, level)
      -- Silent for integration tests
    end
  end)

  after_each(function()
    vim.api = original_vim_api
    vim.fn = original_vim_fn
  end)

  describe("plugin setup", function()
    it("should create all expected user commands", function()
      aoc.setup({})

      local expected_commands = {
        "AocGetPuzzleInput",
        "AocGetTodayPuzzleInput", 
        "AocClearCache",
        "AocInspectConfig",
        "AocReloadSessionToken"
      }

      for _, cmd in ipairs(expected_commands) do
        assert.is_not_nil(user_commands[cmd], "Command " .. cmd .. " should be created")
        assert.is_function(user_commands[cmd].callback, "Command " .. cmd .. " should have a callback function")
      end
    end)

    it("should setup with default configuration", function()
      aoc.setup()

      -- Verify commands are created (implying config was initialized)
      assert.is_not_nil(user_commands["AocGetPuzzleInput"])
    end)

    it("should setup with custom configuration", function()
      local custom_config = {
        session_filepath = "/custom/session.txt",
        puzzle_input = {
          filename = "input.txt"
        }
      }

      aoc.setup(custom_config)

      -- Verify commands are created
      assert.is_not_nil(user_commands["AocGetPuzzleInput"])
    end)
  end)

  describe("user command integration", function()
    before_each(function()
      -- Setup plugin
      aoc.setup({})
      
      -- Mock the modules that commands depend on
      package.loaded["aoc.api"] = {
        save_puzzle_input = function(day, year)
          table.insert(output_messages, "API called with day=" .. day .. ", year=" .. year)
        end,
        reload_session_token = function()
          table.insert(output_messages, "Session token reloaded")
        end
      }
      
      package.loaded["aoc.cache"] = {
        clear_cache = function()
          table.insert(output_messages, "Cache cleared")
          return true
        end
      }
      
      package.loaded["aoc.config"] = {
        debug = function()
          table.insert(output_messages, "Configuration displayed")
        end,
        options = {
          session_filepath = "/var/tmp/aoc.txt",
          puzzle_input = {
            filename = "puzzle.txt",
            save_to_current_dir = true
          }
        }
      }

      package.loaded["aoc.utils"] = {
        trim = function(s)
          return s:gsub("^%s*(.-)%s*$", "%1")
        end
      }
    end)

    describe("AocGetPuzzleInput command", function()
      it("should prompt for day and year, then call API", function()
        input_responses["Day: "] = "5"
        input_responses["Year: "] = "2023"

        user_commands["AocGetPuzzleInput"].callback()

        assert.are.equal("\n", output_messages[1]) -- nvim_out_write newline
        assert.are.equal("API called with day=5, year=2023", output_messages[2])
      end)

      it("should trim input whitespace", function()
        input_responses["Day: "] = "  10  "
        input_responses["Year: "] = "  2024  "

        user_commands["AocGetPuzzleInput"].callback()

        assert.are.equal("API called with day=10, year=2024", output_messages[2])
      end)

      it("should handle empty input", function()
        input_responses["Day: "] = ""
        input_responses["Year: "] = ""

        user_commands["AocGetPuzzleInput"].callback()

        -- Should still call API (validation happens in API layer)
        assert.are.equal("API called with day=, year=", output_messages[2])
      end)
    end)

    describe("AocGetTodayPuzzleInput command", function()
      it("should use current date", function()
        -- Mock os.date
        local original_os_date = os.date
        os.date = function(format)
          if format == "%d" then return "15" end
          if format == "%Y" then return "2024" end
          return "2024-12-15"
        end

        user_commands["AocGetTodayPuzzleInput"].callback()

        assert.are.equal("API called with day=15, year=2024", output_messages[1])

        os.date = original_os_date
      end)
    end)

    describe("AocClearCache command", function()
      it("should call cache clear function", function()
        user_commands["AocClearCache"].callback()

        assert.are.equal("Cache cleared", output_messages[1])
      end)
    end)

    describe("AocInspectConfig command", function()
      it("should call config debug function", function()
        user_commands["AocInspectConfig"].callback()

        assert.are.equal("Configuration displayed", output_messages[1])
      end)
    end)

    describe("AocReloadSessionToken command", function()
      it("should call session token reload", function()
        user_commands["AocReloadSessionToken"].callback()

        assert.are.equal("Session token reloaded", output_messages[1])
      end)
    end)
  end)

  describe("command options", function()
    before_each(function()
      aoc.setup({})
    end)

    it("should create commands with empty options table", function()
      for name, cmd in pairs(user_commands) do
        assert.is_table(cmd.opts, "Command " .. name .. " should have opts table")
        assert.are.equal(0, vim.tbl_count(cmd.opts), "Command " .. name .. " should have empty opts")
      end
    end)
  end)

  describe("error handling integration", function()
    it("should handle module loading errors gracefully", function()
      -- Remove a required module
      local original_cache = package.loaded["aoc.cache"]
      package.loaded["aoc.cache"] = nil

      -- This should not throw an error during setup
      assert.has_no.errors(function()
        aoc.setup({})
      end)

      -- Restore module
      package.loaded["aoc.cache"] = original_cache
    end)
  end)

  describe("module interaction", function()
    it("should pass configuration to config module", function()
      local config_init_called = false
      local config_args = nil

      -- Mock config module
      package.loaded["aoc.config"] = {
        init = function(args)
          config_init_called = true
          config_args = args
        end
      }

      local test_config = {
        session_filepath = "/test/session.txt"
      }

      aoc.setup(test_config)

      assert.is_true(config_init_called)
      assert.are.same(test_config, config_args)
    end)
  end)
end)