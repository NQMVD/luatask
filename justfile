# LuaTask - Teal-based task runner
# Build system using Cyan and Just

# Configuration
build_dir := "build"
src_dir := "src"
examples_dir := "examples"
tests_dir := "tests"

# Default recipe
default: help

# Build the project using Cyan
@build:
    echo "Building LuaTask with Cyan..."
    cyan build

# Type check without building
@check:
    echo "Type checking Teal files..."
    cyan check


# Clean build artifacts
@clean:
    echo "Cleaning build artifacts..."
    rip {{build_dir}}

# Clean and rebuild
rebuild: clean build

# Run type checker on specific files
@check-file FILE:
    cyan check {{FILE}}

# Generate Lua from specific Teal file
@gen-file FILE:
    cyan gen {{FILE}}

# Run with example taskfile
@example:
    echo "Running LuaTask with example taskfile..."
    cd {{examples_dir}} && ../{{build_dir}}/luatask --list

# Run specific example command
@run-example TASK *ARGS:
    cd {{examples_dir}} && ../{{build_dir}}/luatask "{{TASK}} {{ARGS}}"

# Install to system
install: build
    @echo "Installing LuaTask to /usr/local/bin..."
    sudo cp {{build_dir}}/luatask /usr/local/bin/luatask
    @echo "LuaTask installed successfully!"

# Uninstall from system
uninstall:
    @echo "Uninstalling LuaTask..."
    sudo rm -f /usr/local/bin/luatask
    @echo "LuaTask uninstalled!"

# Development tasks

# Watch for changes and rebuild (requires fd and entr)
watch:
    @echo "Watching for changes... (Press Ctrl+C to stop)"
    fd -e tl . {{src_dir}} | entr -r just build

# Format Teal code (if available)
format:
    @echo "Formatting Teal code..."
    @if command -v stylua >/dev/null 2>&1; then \
        find {{src_dir}} -name "*.tl" -exec stylua {} +; \
    else \
        echo "stylua not available, skipping format..."; \
    fi

# Lint and check all source files
lint:
    @echo "Linting Teal code..."
    cyan check {{src_dir}}/**/*.tl

# Run tests (when implemented)
test: build
    @echo "Running tests..."
    @if [ -d "{{tests_dir}}" ] && [ -n "$(ls -A {{tests_dir}}/*.tl 2>/dev/null)" ]; then \
        for test in {{tests_dir}}/*.tl; do \
            echo "Running $$(basename $$test)..."; \
            cd {{build_dir}} && lua "$$(basename $$test .tl).lua" || exit 1; \
        done; \
        echo "All tests passed!"; \
    else \
        echo "No tests found in {{tests_dir}}"; \
    fi

# Development setup
setup:
    @echo "Setting up development environment..."
    @if ! command -v cyan >/dev/null 2>&1; then \
        echo "Installing Cyan..."; \
        luarocks install cyan; \
    fi
    @if ! command -v just >/dev/null 2>&1; then \
        echo "Just command runner not found. Install with:"; \
        echo "  cargo install just"; \
        echo "  brew install just"; \
        echo "  or visit: https://github.com/casey/just"; \
    fi
    @echo "Development environment ready!"

# Show project info
@info:
    echo "LuaTask - Lua-based Task Runner"
    echo "================================"
    echo "Source directory: {{src_dir}}"
    echo "Build directory:  {{build_dir}}"
    echo "Examples:         {{examples_dir}}"
    echo "Tests:            {{tests_dir}}"
    echo ""
    echo "Available commands:"
    just --list

# Create a new Teal module template
new-module NAME:
    @echo "Creating new Teal module: {{NAME}}"
    @cat > {{src_dir}}/{{NAME}}.tl << 'EOF'
    -- {{NAME}} module for LuaTask
    -- TODO: Add description

    local record {{NAME}}
    end

    -- TODO: Implement module functionality

    return {{NAME}}
    EOF
    @echo "Created {{src_dir}}/{{NAME}}.tl"

# Run the built executable with arguments
run *ARGS:
    {{build_dir}}/luatask {{ARGS}}

# Package for distribution
package: build
    @echo "Creating distribution package..."
    mkdir -p dist
    tar -czf dist/luatask-$(date +%Y%m%d).tar.gz \
        -C {{build_dir}} luatask \
        -C ../{{examples_dir}} taskfile.lua \
        -C .. README.md
    @echo "Package created in dist/"

# Quick development cycle: clean, build, test example
dev: clean build example

# Show help
help:
    @echo "LuaTask Build System"
    @echo "==================="
    @echo ""
    @echo "Common commands:"
    @echo "  just build     - Build the project"
    @echo "  just check     - Type check without building"
    @echo "  just clean     - Remove build artifacts"
    @echo "  just example   - Run with example taskfile"
    @echo "  just install   - Install to system"
    @echo "  just dev       - Quick dev cycle"
    @echo "  just watch     - Watch and rebuild on changes"
    @echo ""
    @echo "For all commands, run: just --list"
