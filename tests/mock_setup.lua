-- Mock setup for testing environment
local M = {}

-- Mock plenary.curl
package.preload["plenary.curl"] = function()
   return {
      get = function(opts)
         return {status = 200, body = "mock_content"}
      end
   }
end

-- Mock vim.inspect if not available
if not vim.inspect then
   vim.inspect = function(obj)
      if type(obj) == "table" then
         local parts = {}
         for k, v in pairs(obj) do
            local key = type(k) == "string" and k or "[" .. tostring(k) .. "]"
            local value = type(v) == "string" and '"' .. v .. '"' or tostring(v)
            table.insert(parts, key .. " = " .. value)
         end
         return "{" .. table.concat(parts, ", ") .. "}"
      else
         return tostring(obj)
      end
   end
end

-- Ensure all required vim functions exist
vim.tbl_deep_extend = vim.tbl_deep_extend or function(behavior, ...)
   local result = {}
   local tables = {...}
   for _, tbl in ipairs(tables) do
      if type(tbl) == "table" then
         for k, v in pairs(tbl) do
            if type(v) == "table" and type(result[k]) == "table" and behavior == "force" then
               result[k] = vim.tbl_deep_extend(behavior, result[k], v)
            else
               result[k] = v
            end
         end
      end
   end
   return result
end

vim.split = vim.split or function(str, sep)
   local parts = {}
   for part in str:gmatch("([^" .. sep .. "]+)") do
      table.insert(parts, part)
   end
   return parts
end

vim.tbl_count = vim.tbl_count or function(t)
   local count = 0
   for _ in pairs(t) do count = count + 1 end
   return count
end

vim.log = vim.log or {levels = {ERROR = 1, WARN = 2, INFO = 3}}

vim.fn = vim.fn or {}
vim.fn.expand = vim.fn.expand or function(path) return path end
vim.fn.glob = vim.fn.glob or function(pattern) return "" end
vim.fn.fnamemodify = vim.fn.fnamemodify or function(fname, mods) return fname end

vim.api = vim.api or {}
vim.api.nvim_create_user_command = vim.api.nvim_create_user_command or function() end
vim.api.nvim_out_write = vim.api.nvim_out_write or function() end

vim.uv = vim.uv or {}
vim.uv.now = vim.uv.now or function() return os.time() * 1000 end
vim.uv.cwd = vim.uv.cwd or function() return "/test" end

vim.notify = vim.notify or function() end

return M