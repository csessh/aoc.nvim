# aoc.nvim Test Suite

This directory contains a comprehensive test suite for the aoc.nvim plugin.

## Overview

The test suite covers all major components of the plugin:

- **test_utils.lua** - Tests for utility functions (string trimming, popup creation)
- **test_config.lua** - Tests for configuration management and initialization
- **test_cache.lua** - Tests for local file caching functionality
- **test_api.lua** - Tests for API requests, rate limiting, and session management
- **test_integration.lua** - Integration tests for plugin setup and user commands

## Running Tests

### Prerequisites

- Neovim installed and available in PATH
- StyLua (optional, for linting/formatting)

### Run All Tests

```bash
# Using Makefile (recommended)
make test

# Manual execution
nvim --headless -l tests/basic_test.lua
nvim --headless -l tests/working_test.lua
```

### Available Test Files

- **basic_test.lua** - Basic functionality and module loading tests (✓ 3-space formatted)
- **working_test.lua** - Rate limiting and API interaction tests (✓ 3-space formatted)  
- **rate_limit_test.lua** - Detailed rate limiting scenarios (✓ 3-space formatted)
- **test_runner.lua** - Custom test framework runner (✓ 3-space formatted)
- **mock_setup.lua** - Test mocking utilities (✓ 3-space formatted)
- Legacy test files (test_*.lua) - Comprehensive unit tests (currently not working in headless mode, 2-space formatted)

### Watch Mode (requires entr)

```bash
make test-watch
```

### Linting and Formatting

```bash
# Check code style
make lint

# Format code
make format
```

## Code Formatting

The test files follow the project's `.editorconfig` settings:
- **Lua files**: 3-space indentation
- **Markdown files**: 4-space indentation

Main test files have been formatted according to these standards. Legacy test files (test_*.lua) may still use 2-space indentation.

## Test Framework

The test suite uses a simple custom test framework that provides:

- `describe()` - Group related tests
- `it()` - Individual test cases
- `before_each()` / `after_each()` - Setup/teardown hooks
- Comprehensive assertion library with `assert.are.equal()`, `assert.is_true()`, etc.

## Test Structure

Each test file follows this pattern:

```lua
local module = require("aoc.module")

describe("module description", function()
  local original_dependencies
  
  before_each(function()
    -- Setup mocks and reset state
  end)
  
  after_each(function()
    -- Restore original functions
  end)
  
  describe("function_name", function()
    it("should do something specific", function()
      -- Test implementation
      assert.are.equal(expected, actual)
    end)
  end)
end)
```

## Mocking Strategy

The tests extensively use mocking to isolate units under test:

- **Vim APIs** - Mock `vim.api`, `vim.fn`, `vim.notify`, etc.
- **File System** - Mock `io.open`, `os.remove`, `os.execute`
- **External Dependencies** - Mock plenary.curl for HTTP requests
- **Time Functions** - Mock `vim.uv.now()` and `os.date()` for deterministic tests

## Coverage Areas

### Unit Tests
- Input validation
- Configuration merging
- File operations
- String utilities
- Rate limiting logic
- Session token management

### Integration Tests  
- Plugin initialization
- User command creation
- Module interactions
- Error handling flows

### Edge Cases
- Missing files
- Network errors
- Invalid inputs
- Rate limit scenarios
- Cache corruption

## Test Output

The test runner provides:
- ✓ Passed tests in green
- ✗ Failed tests in red with error details
- Summary statistics
- Detailed failure information

Example output:
```
● aoc.utils
  ✓ should remove leading and trailing whitespaces
  ✓ should create popup with correct parameters

● aoc.api
  ✓ should reject invalid day range
  ✓ should allow requests under rate limit
  ✗ should handle missing session file
    Expected true, got false

Test Results:
=============
Total: 45
Passed: 44
Failed: 1
```

## Adding New Tests

1. Create test file following naming convention: `test_[module].lua`
2. Use the established mocking patterns
3. Cover both happy path and error conditions
4. Update this README if adding new test categories