local api = require "aoc.api"
local cfg = require "aoc.config"
local cache = require "aoc.cache"

---@class AOC
local M = {}

---Strip input of any leading/trailing spaces
---@param s string
---@return string
local trim = function(s)
   s, _ = string.gsub(s, "%s+", "")
   return s
end

---@param args any
M.setup = function(args)
   cfg.init(args)

   vim.api.nvim_create_user_command("AocGetPuzzleInput", function()
      local day = vim.fn.input "Day: "
      local year = vim.fn.input "Year: "
      vim.api.nvim_out_write "\n"

      day = trim(day)
      year = trim(year)
      api.save_puzzle_input(day, year)
   end, {})

   vim.api.nvim_create_user_command("AocGetTodayPuzzleInput", function()
      local day = os.date "%d"
      local year = os.date "%Y"

      api.save_puzzle_input(day, year)
   end, {})

   vim.api.nvim_create_user_command("AocClearCache", cache.clear_cache, {})
   vim.api.nvim_create_user_command("AocInspectConfig", cfg.debug, {})
end

return M
