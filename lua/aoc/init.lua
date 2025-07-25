local api = require "aoc.api"
local cfg = require "aoc.config"
local cache = require "aoc.cache"
local utils = require "aoc.utils"

---@class AOC
local M = {}

---@param args any
M.setup = function(args)
   cfg.init(args)

   vim.api.nvim_create_user_command("AocGetPuzzleInput", function()
      local day = vim.fn.input "Day: "
      local year = vim.fn.input "Year: "
      vim.api.nvim_out_write "\n"

      day = utils.trim(day)
      year = utils.trim(year)
      api.save_puzzle_input(day, year)
   end, {})

   vim.api.nvim_create_user_command("AocGetTodayPuzzleInput", function()
      local day = os.date "%d"
      local year = os.date "%Y"

      api.save_puzzle_input(day, year)
   end, {})

   vim.api.nvim_create_user_command("AocClearCache", cache.clear_cache, {})
   vim.api.nvim_create_user_command("AocInspectConfig", cfg.debug, {})
   vim.api.nvim_create_user_command("AocReloadSessionToken", api.reload_session_token, {})
end

return M
