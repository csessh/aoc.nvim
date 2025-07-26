-- Simple test to check if modules can be loaded
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h")
package.path = plugin_path .. "/lua/?.lua;" .. package.path

print("Plugin path: " .. plugin_path)
print("Package path: " .. package.path:sub(1, 200) .. "...")

-- Test loading each module
local modules = {"aoc.utils", "aoc.config", "aoc.cache", "aoc.api", "aoc"}

for _, module_name in ipairs(modules) do
  local success, module_or_error = pcall(require, module_name)
  if success then
    print("✓ " .. module_name .. " loaded successfully")
  else
    print("✗ " .. module_name .. " failed: " .. tostring(module_or_error))
  end
end