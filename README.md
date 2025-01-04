<!-- panvimdoc-ignore-start -->
# Advent of Code: Neovim Christmas Elf who fetches puzzle input
<!-- panvimdoc-ignore-end -->

## Intro

If you're like me and you don't want to copy and paste puzzle input from the web page every single time, this could be something you might find handy.

There are other CLI tools that accomplish the same task, none I could see for Neovim. Inspirations include:

- [CLI written in Rust](https://github.com/scarvalhojr/aoc-cli)
- [CLI written in Python](https://github.com/wimglenn/advent-of-code-data)

I'd like to stay within Neovim for as long as I could possibly get away with doing so. Hence, this plugin.

In the true developer fashion, I started with one task to solve Advent of Code puzzles, I ended up talking myself into "Let's spend a day or two to write a tool that saves me ... 5s of copy and paste task". Here we are.


## Disclaimer

This plugin follows the automation guidelines on the `r/adventofcode` [community wiki](https://www.reddit.com/r/adventofcode/wiki/faqs/automation). 

Specifically:

- Outbound calls are throttled to every 5 minutes.
- Once inputs are downloaded, they are cached locally.
- If you suspect your input is corrupted, you can manually clear cache and request new input with `:AocClearCache`
- The User-Agent header used in HTTP requests is set to me since I maintain this tool.

### Other features in the work 

There are a number of features I'd like to add in the coming days/weeks to get to v1.0.0

- `:AocGetSampleInput` to write puzzle's sample input to file.
- `:AocYankSampleInput` to yank a puzzle's sample input to a register.

I am always open to any feedbacks and suggestions.

## Requirements

This plugin requires a session token to communicate with [adventofcode.com](https://adventofcode.com).

This is how you generate one:

1. Login to [adventofcode.com](https://adventofcode.com).
2. Open Inspect panel, navigate to Storage tab.
3. Select cookies and copy `session` value.
4. Save to somewhere, e.g. `/var/tmp/aoc.txt`. Remeber to set appropriate permission, e.g `chmod 600` or whatever you deem acceptable.
5. Update plugin config to set `session_filepath` attribute with the filepath above.

## Installation

Let your favourite package manager (`lazy.nvim`) do the work:

``` lua
-- lazy.nvim
return {
    "csessh/aoc.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {}
},
```

Should you want to lazy load this plugin, you could add a condition check in its config like so:

``` lua
cond = vim.fn.getcwd() == vim.fn.expand("your AOC directory path"),
```

## Default configuration

``` lua
--- Default configuration
---@type table
local default_opts = {
   session_filepath = "/var/tmp/aoc.txt", -- Default filepath to your AOC session token
   puzzle_input = { 
      filename = "puzzle.txt",            -- Default puzzle input filename
      save_to_current_dir = true,         -- Save puzzle input file to your current buffer's cwd() 
                                          -- using {filename} attribute listed above.
      alternative_filepath = nil,         -- This option is ONLY used when save_to_current_dir is set to false
                                          -- This option allows you to set a generic filepath for your puzzle input
                                          -- For example: ~/aoc/input.txt or ~/aoc/puzzle ...
   },
}
```

## User command

This plugin provides the following user commands: 
``` vim
:AocGetPuzzleInput
:AocGetTodayPuzzleInput
:AocClearCache
:AocInspectConfig
```

### AocGetPuzzleInput

This command takes two input from you: day and year.

It will then check cache to see if the puzzle input was previously downloaded to avoid unnecessasry requests to `adventofcode.com`

``` vim
:AocGetPuzzleInput
Day: 8
Year: 2024
Successfully downloaded puzzle for input for Day 8 (2024)
```

### AocGetTodayPuzzleInput

This command doesn't take any input from you. It simply gets the input for today's puzzle if it's unlocked.

It checks cache to see if the puzzle input was previously downloaded to avoid unnecessasry requests to `adventofcode.com`

``` vim
:AocGetTodayPuzzleInput
Successfully downloaded puzzle for input for Day 11 (2024)
```

### AocClearCache

This command wipes out all cached puzzle input files. In such case you decide to switch between accounts, your puzzle inputs will be different and cached input will be invalid.

``` vim
:AocClearCache
Cache cleared
```

### AocInspectConfig

This command allows you to quickly inspect the current plugin configuration. 

``` vim
:AocInspectConfig
{
   session_filepath = "/var/tmp/aoc.txt",
   puzzle_input = {
      filename = "puzzle.txt",
      save_to_current_dir = true,
      alternative_filepath = nil,
   },
}
```

## Contribution

All contributions are most welcome! Please open a PR or create an [issue](https://github.com/csessh/aoc.nvim/issues).

### Coding Style

- Follow the coding style of [LuaRocks](https://github.com/luarocks/lua-style-guide).
- Make sure you format the code with [StyLua](https://github.com/JohnnyMorganz/StyLua) before PR.

