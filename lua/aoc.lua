-- main module file
local module = require("aoc.module")

---@class Config
---@field opt string
local config = {
  opt = "Hello!",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.hello = function()
  return module.my_first_function(M.config.opt)
end

return M
