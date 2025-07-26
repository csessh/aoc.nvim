.PHONY: test test-watch test-specific lint format clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test         - Run all tests"
	@echo "  test-basic   - Run basic functionality tests"
	@echo "  test-rate-limit - Run rate limiting tests"
	@echo "  test-watch   - Run tests in watch mode (requires entr)"
	@echo "  lint         - Run linter (StyLua)"
	@echo "  format       - Format code with StyLua"
	@echo "  clean        - Clean test artifacts"
	@echo "  help         - Show this help message"

# Run all tests
test:
	@echo "Running aoc.nvim test suite..."
	@nvim --headless -l tests/basic_test.lua
	@echo ""
	@echo "Running rate limiting tests..."
	@nvim --headless -l tests/working_test.lua

# Run tests in watch mode (requires entr)
test-watch:
	@echo "Watching for changes... (requires 'entr' to be installed)"
	@find lua tests -name "*.lua" | entr -c make test

# Run specific test file
test-basic:
	@echo "Running basic functionality tests..."
	@nvim --headless -l tests/basic_test.lua

test-rate-limit:
	@echo "Running rate limiting tests..."
	@nvim --headless -l tests/working_test.lua

# Lint code
lint:
	@echo "Linting code with StyLua..."
	@stylua --check lua/ tests/

# Format code
format:
	@echo "Formatting code with StyLua..."
	@stylua lua/ tests/

# Clean test artifacts
clean:
	@echo "Cleaning test artifacts..."
	@rm -rf /tmp/aoc_test_*

# Development setup check
check-deps:
	@echo "Checking dependencies..."
	@command -v nvim >/dev/null 2>&1 || { echo "Error: nvim not found"; exit 1; }
	@command -v stylua >/dev/null 2>&1 || { echo "Warning: stylua not found (optional)"; }
	@echo "Dependencies OK"