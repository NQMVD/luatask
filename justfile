build_dir := "build"
src_dir := "src"
examples_dir := "examples"
tests_dir := "tests"

default: clean build format bundle minify create test

test:
  ./lust --list
  ./lust create # will rebuild itself but that's fine

@create: bundle minify
    lua scripts/create-executable.lua

bundle:
    darklua process {{build_dir}}/main.lua {{build_dir}}/luatask.lua

minify:
    darklua minify {{build_dir}}/luatask.lua {{build_dir}}/luatask-minified.lua

@build: clean
    cyan build

@format:
    stylua {{build_dir}}/*.lua

@check:
    cyan check

@clean:
    -rip {{build_dir}}

# Run type checker on specific files
@check-file FILE:
    cyan check {{FILE}}

# Generate Lua from specific Teal file
@gen-file FILE:
    cyan gen {{FILE}}

# Run with example taskfile
@example:
    echo "Running LuaTask with example taskfile..."
    cd {{examples_dir}} && ../luatask --list

# Run specific example command
@run-example TASK *ARGS:
    cd {{examples_dir}} && ../luatask "{{TASK}} {{ARGS}}"

# Install to system
install: build
    @echo "Installing LuaTask to /usr/local/bin..."
    sudo cp ./luatask /usr/local/bin/luatask
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

# Lint and check all source files
lint:
    @echo "Linting Teal code..."
    cyan check {{src_dir}}/**/*.tl

bench:
  hyperfine './lust' -N --warmup 10 --runs 500 --export-markdown bench.md


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

# Run the built executable with arguments
run *ARGS:
    ./luatask {{ARGS}}

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
