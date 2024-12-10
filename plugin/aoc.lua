vim.api.nvim_create_user_command("AOCSavePuzzleInput", require("aoc").hello, {})
vim.api.nvim_create_user_command("AOCSaveSampleInput", require("aoc").hello, {})
vim.api.nvim_create_user_command("AOCYankSampleInput", require("aoc").hello, {})
vim.api.nvim_create_user_command("AOCSubmit", require("aoc").hello, {})
