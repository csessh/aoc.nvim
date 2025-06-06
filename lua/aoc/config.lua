local inspect = require "vim.inspect"

---@class Configuration
local M = {}

--- Default configuration
---@type table
local default_opts = {
   session_filepath = "/var/tmp/aoc.txt",
   puzzle_input = {
      filename = "puzzle.txt",
      save_to_current_dir = true,
      alternative_filepath = nil,
   },
}

M.init = function(args)
   M.options = vim.tbl_deep_extend("force", default_opts, args or {})

   M.options.session_filepath = vim.fn.expand(M.options.session_filepath)
   if M.options.puzzle_input.alternative_filepath then
      M.options.puzzle_input.alternative_filepath =
         vim.fn.expand(M.options.puzzle_input.alternative_filepath)
   end
end

M.debug = function()
   print(inspect(M.options))
end

return M
