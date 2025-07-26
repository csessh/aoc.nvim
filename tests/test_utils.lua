local utils = require("aoc.utils")

describe("aoc.utils", function()
  describe("trim", function()
    it("should remove leading and trailing whitespaces", function()
      assert.are.equal("hello", utils.trim("  hello  "))
      assert.are.equal("hello world", utils.trim(" hello world "))
      assert.are.equal("", utils.trim("   "))
      assert.are.equal("", utils.trim(""))
    end)

    it("should handle strings with only leading whitespace", function()
      assert.are.equal("hello", utils.trim("  hello"))
    end)

    it("should handle strings with only trailing whitespace", function()
      assert.are.equal("hello", utils.trim("hello  "))
    end)

    it("should handle strings with no whitespace", function()
      assert.are.equal("hello", utils.trim("hello"))
    end)

    it("should handle strings with internal whitespace", function()
      assert.are.equal("hello world test", utils.trim("  hello world test  "))
    end)

    it("should handle strings with tabs and newlines", function()
      assert.are.equal("hello", utils.trim("\t\nhello\t\n"))
    end)
  end)

  describe("popup", function()
    local original_api
    local mock_calls = {}

    before_each(function()
      mock_calls = {}
      original_api = vim.api
      
      vim.api = {
        nvim_create_buf = function(listed, scratch)
          table.insert(mock_calls, {"nvim_create_buf", listed, scratch})
          return 1 -- mock buffer id
        end,
        nvim_get_current_win = function()
          table.insert(mock_calls, {"nvim_get_current_win"})
          return 1000 -- mock window id
        end,
        nvim_win_get_config = function(win_id)
          table.insert(mock_calls, {"nvim_win_get_config", win_id})
          return {width = 80, height = 24}
        end,
        nvim_buf_set_lines = function(buf, start, end_line, strict_indexing, replacement)
          table.insert(mock_calls, {"nvim_buf_set_lines", buf, start, end_line, strict_indexing, replacement})
        end,
        nvim_set_option_value = function(name, value, opts)
          table.insert(mock_calls, {"nvim_set_option_value", name, value, opts})
        end,
        nvim_open_win = function(buf, enter, config)
          table.insert(mock_calls, {"nvim_open_win", buf, enter, config})
          return 2000 -- mock popup window id
        end,
        nvim_win_is_valid = function(win)
          table.insert(mock_calls, {"nvim_win_is_valid", win})
          return true
        end,
        nvim_win_close = function(win, force)
          table.insert(mock_calls, {"nvim_win_close", win, force})
        end
      }

      vim.defer_fn = function(fn, timeout)
        table.insert(mock_calls, {"defer_fn", timeout})
        -- Execute immediately for testing
        fn()
      end
    end)

    after_each(function()
      vim.api = original_api
    end)

    it("should create popup with correct parameters", function()
      utils.popup("Test message", 5000)
      
      -- Verify buffer creation
      assert.are.same({"nvim_create_buf", false, true}, mock_calls[1])
      
      -- Verify window configuration was retrieved 
      assert.are.same({"nvim_get_current_win"}, mock_calls[2])
      assert.are.same({"nvim_win_get_config", 1000}, mock_calls[3])
      
      -- Verify buffer content was set
      assert.are.same({"nvim_buf_set_lines", 1, 0, -1, false, {"Test message"}}, mock_calls[4])
      
      -- Verify popup window was created
      local open_win_call = mock_calls[6]
      assert.are.equal("nvim_open_win", open_win_call[1])
      assert.are.equal(1, open_win_call[2]) -- buffer id
      assert.are.equal(false, open_win_call[3]) -- enter
      
      local config = open_win_call[4]
      assert.are.equal("minimal", config.style)
      assert.are.equal("win", config.relative)
      assert.are.equal(12, config.width) -- length of "Test message"
      assert.are.equal(1, config.height)
      assert.are.equal("rounded", config.border)
    end)

    it("should position popup in bottom right corner", function()
      utils.popup("Hi", 1000)
      
      local open_win_call = mock_calls[6]
      local config = open_win_call[4]
      
      -- With window size 80x24, message "Hi" (length 2)
      -- Expected position: row = 24 - 1 - 2 = 21, col = 80 - 2 - 2 = 76
      assert.are.equal(21, config.row)
      assert.are.equal(76, config.col)
    end)

    it("should auto-close popup after timeout", function()
      utils.popup("Test", 3000)
      
      -- Verify defer_fn was called with correct timeout
      local defer_call = nil
      for _, call in ipairs(mock_calls) do
        if call[1] == "defer_fn" then
          defer_call = call
          break
        end
      end
      assert.is_not_nil(defer_call)
      assert.are.equal(3000, defer_call[2])
      
      -- Verify window was closed (defer_fn callback executed immediately in test)
      local close_calls = {}
      for _, call in ipairs(mock_calls) do
        if call[1] == "nvim_win_close" then
          table.insert(close_calls, call)
        end
      end
      assert.are.equal(1, #close_calls)
      assert.are.same({"nvim_win_close", 2000, true}, close_calls[1])
    end)
  end)
end)