<!-- panvimdoc-ignore-start -->
# Advent of Code: nvim elf who fetches puzzle input
<!-- panvimdoc-ignore-end -->

## Intro
If you're like me and you don't want to copy and paste puzzle input every single time?
There are other CLI tools that accomplish the same task, none I could see for Neovim.

I'd like to stay within Neovim for as long as I could possibly get away with doing so. Hence, this plugin.

## Requirements

This plugin requires:

- Go >= 1.22.10
- Neovim >= 10.1

## Installation

1. Let your favourite package manager do the work:

```lua
-- lazy.nvim
{
    "csessh/aoc.nvim",
    opts = {}
},
```

2. Setup the plugin in your `init.lua`. This step is not needed with lazy.nvim if `opts` is set.

```lua
require("aoc").setup()
```

## Configuration

| Items                 | Type      | Default Value      | Description    |
| --------------------- | --------- | ------------------ | -------------- |
| `session_token_path`        | string    | `/var/tmp/aoc.nvim/session` | This is the path to where you'd like to have the session token stored |

## User command

```
:AOCSavePuzzleInput
:AOCSaveSampleInput
:AOCYankSampleInput
:AOCSubmit <result> 
:AOCSetSessionToken <token>
```

## Contribution

All contributions are most welcome! Please open a PR or create an [issue](https://github.com/csessh/stopinsert.nvim/issues).

### Coding Style

- Follow the coding style of [LuaRocks](https://github.com/luarocks/lua-style-guide).
- Make sure you format the code with [StyLua](https://github.com/JohnnyMorganz/StyLua) before PR.

