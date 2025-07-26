# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

This is a Neovim plugin with no build system - development is done directly with Lua files. Code formatting should be done with StyLua before making changes:

```bash
stylua lua/
```

## Code Architecture

This is a Neovim plugin for Advent of Code puzzle input management. The plugin architecture follows a modular design:

### Core Modules

- **`lua/aoc/init.lua`**: Main plugin entry point that sets up user commands and calls `cfg.init()` for configuration
- **`lua/aoc/config.lua`**: Configuration management with default options for session file path and puzzle input settings
- **`lua/aoc/api.lua`**: HTTP client wrapper using plenary.curl for Advent of Code API communication, handles session token management
- **`lua/aoc/cache.lua`**: Local file caching system to avoid unnecessary API requests, manages both cache directory and user output files
- **`lua/aoc/utils.lua`**: Utility functions including string trimming and popup message display

### Key Dependencies

- **plenary.nvim**: Required dependency for HTTP requests via `plenary.curl`
- **vim.inspect**: Used for configuration debugging output

### Configuration System

The plugin uses a default configuration that can be overridden during setup:
- Session token file path (default: `/var/tmp/aoc.txt`)
- Puzzle input filename and save location options
- Alternative filepath support for custom save locations

### User Commands

The plugin registers these commands in `init.lua`:
- `:AocGetPuzzleInput` - Interactive day/year input
- `:AocGetTodayPuzzleInput` - Automatic current date detection  
- `:AocClearCache` - Cache management
- `:AocInspectConfig` - Configuration debugging
- `:AocReloadSessionToken` - Session token refresh

### Data Flow

1. User commands trigger `api.save_puzzle_input(day, year)`
2. Cache system checks for existing input via `cache.get_cached_input_file()`
3. If not cached, HTTP request made to `adventofcode.com/{year}/day/{day}/input`
4. Response cached via `cache.write_to_cache()` and written to user file via `cache.write_to_file()`

### Session Token Management

Session tokens are loaded from file system and cached in memory (`api.lua:M.session_id`). The plugin includes validation for day/year inputs and proper error handling for network requests.