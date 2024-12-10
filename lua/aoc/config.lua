local inspect = require "vim.inspect"

---@class Configuration
local M = {}

--- Default configuration
---@type table
M.options = {
   session_id = {
      file_path = "/var/tmp/aoc.txt",
      chmod = 600,
   },
   puzzle_input = {
      filename = "puzzle.txt",
      save_to_current_dir = true,
      alternative_filepath = nil,
   },
   popup_clear_after_s = 5,
}

M.init = function(args)
   M.options = vim.tbl_deep_extend("force", M.options, args or {})
end

M.debug = function()
   print(inspect(M.options))
end

return M
