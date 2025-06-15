# LuaTask

A Just-inspired task runner written in Teal that uses Lua for both the executable and task files, featuring tree-structured task display, cooperative parallelism, and beautiful Catppuccin Mocha theming.

## Features

- **Just-like syntax** - Simple, declarative task definitions with positional arguments
- **Lua-based** - Both the executable and task files use Lua/Teal
- **Dependency resolution** - Automatic execution of task dependencies with arguments
- **Type safety** - Written in Teal for better maintainability
- **Rich logging** - Leveled logging system with colored output
- **Task grouping** - Organize tasks by category
- **Argument validation** - Optional type checking and required argument validation
- **Multiple return values** - Tasks can return additional data beyond success/failure

## Installation

### Prerequisites

- Lua 5.1+ (compatible with LuaJIT)
- [Cyan](https://github.com/teal-language/cyan) - Teal build system
- [Just](https://github.com/casey/just) - Command runner (for development)

### Install Dependencies

```bash
# Install Cyan (Teal build system)
luarocks install cyan

# Install Just (for development)
cargo install just
# or
brew install just
```

### Build from Source

```bash
git clone <repository-url>
cd luatask
just build
```

### Install to System

```bash
just install
```

This installs `luatask` to `/usr/local/bin/luatask`.

## Quick Start

1. **Initialize a project**:
```bash
mkdir myproject
cd myproject
```

2. **Create a `taskfile.lua`**:
```lua
local tasks = {}
local Result = require('result')

tasks.hello = {
  description = "Say hello [name='World']",
  run = function(name)
    name = name or "World"
    log.info("Hello, " .. name .. "!")
    return Result.SUCCESS
  end
}

tasks.build = {
  description = "Build the project [target] [mode='release']",
  dependencies = {"hello"},
  arguments = {
    target = {required = true, type = "string"},
    mode = {required = false, default = "release", type = "string"}
  },
  run = function(target, mode)
    log.info("Building " .. target .. " in " .. mode .. " mode...")
    return Result.SUCCESS, "build-" .. os.time()
  end
}

return tasks
```

3. **List available tasks**:
```bash
luatask --list
```

4. **Run tasks**:
```bash
luatask hello              # Run hello with default argument
luatask hello Alice        # Run hello with custom argument
luatask build x86_64       # Run build (and its dependency hello)
luatask build x86_64 debug # Run build with custom mode
```

## Task File Format

Tasks are defined in a `taskfile.lua` file that returns a table of task definitions:

```lua
local tasks = {}
local Result = require('result')

tasks.task_name = {
  description = "Task description with [arg1] [arg2='default']",
  group = "optional_group_name",           -- Optional grouping
  dependencies = {"dep1", {"dep2", "arg"}}, -- String or {name, args...}
  arguments = {                            -- Optional validation
    arg1 = {required = true, type = "string"},
    arg2 = {required = false, default = "value", type = "string"}
  },
  run = function(arg1, arg2, ...)
    log.info("Task executing...")
    return Result.SUCCESS, additional_values...
  end
}

return tasks
```

### Task Definition Fields

- **`description`** (required): Human-readable description
- **`group`** (optional): Category for organizing tasks in listings
- **`dependencies`** (optional): Array of prerequisite tasks
  - Simple dependency: `"task_name"`
  - Dependency with arguments: `{"task_name", "arg1", "arg2"}`
- **`arguments`** (optional): Argument validation specification
- **`run`** (required): Task function that returns `Result.SUCCESS` or `Result.FAIL`

### Dependencies

Dependencies are executed before the task runs:

```lua
tasks.test = {
  description = "Run tests",
  dependencies = {
    "clean",                    -- Run clean with no arguments
    {"build", "x86_64", "debug"} -- Run build with specific arguments
  },
  run = function()
    -- clean and build have already run
    return Result.SUCCESS
  end
}
```

### Argument Validation

Optional argument validation with type checking:

```lua
tasks.deploy = {
  description = "Deploy to environment [env] [dry_run=false]",
  arguments = {
    env = {required = true, type = "string"},
    dry_run = {required = false, default = "false", type = "boolean"}
  },
  run = function(env, dry_run)
    if dry_run then
      log.info("Dry run mode - would deploy to " .. env)
    else
      log.info("Deploying to " .. env)
    end
    return Result.SUCCESS
  end
}
```

### Logging

Tasks have access to a global `log` object:

```lua
run = function()
  log.debug("Detailed debugging information")
  log.info("General information")
  log.warn("Warning message")
  log.error("Error message")
  return Result.SUCCESS
end
```

## Command Line Usage

### Basic Usage

```bash
luatask                          # List available tasks
luatask clean                    # Run clean task
luatask build x86_64 debug       # Run build with arguments
luatask deploy staging           # Run deploy with argument
```

### Multiple Tasks

```bash
luatask clean build test         # Run in sequence
luatask "build x86_64 debug" test # Quoted for complex arguments
```

### Command Line Options

```bash
luatask --list                   # Show grouped task list with dependencies
luatask --file custom.lua build # Use custom task file
luatask --log-level debug build # Set log level (debug/info/warn/error)
luatask --help                   # Show help information
```

### Available Options

- `--list` - List available tasks with dependencies
- `--file FILE` - Use custom task file (default: `taskfile.lua`)
- `--log-level LEVEL` - Set minimum log level (`debug`, `info`, `warn`, `error`)
- `--help, -h` - Show help information

## Examples

The repository includes a comprehensive example in `examples/taskfile.lua` that demonstrates:

- Task grouping and organization
- Complex dependency chains
- Argument validation
- Logging at different levels
- Multiple return values
- Error handling

Run the example:

```bash
cd examples
../build/luatask --list
../build/luatask version
../build/luatask "build x86_64 debug"
../build/luatask test
```

## Development

### Project Structure

```
luatask/
├── src/               # Teal source files
│   ├── main.tl        # Entry point & CLI parsing
│   ├── parser.tl      # Task file parser
│   ├── runner.tl      # Task execution engine
│   ├── logger.tl      # Logging system
│   ├── types.tl       # Type definitions
│   └── result.tl      # Result enum
├── examples/          # Example task files
├── build/             # Compiled Lua files
├── scripts/           # Build scripts
├── justfile           # Build automation
├── tlconfig.lua       # Teal configuration
└── README.md
```

### Development Commands

```bash
just build             # Build the project
just check             # Type check without building
just clean             # Remove build artifacts
just example           # Run with example taskfile
just watch             # Watch and rebuild on changes
just lint              # Lint Teal code
just dev               # Quick dev cycle
```

### Build System

LuaTask uses [Cyan](https://github.com/teal-language/cyan) as the build system for compiling Teal to Lua, and [Just](https://github.com/casey/just) for task automation.

The build process:
1. Cyan compiles `.tl` files to `.lua` files
2. A post-build script creates the executable
3. The executable sets up the module path and runs the main function

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `just check` to verify types
5. Run `just build` to test compilation
6. Submit a pull request

## Comparison with Just

LuaTask is inspired by [Just](https://github.com/casey/just) but differs in several ways:

| Feature | Just | LuaTask |
|---------|------|---------|
| Language | Justfile syntax | Lua |
| Type system | None | Teal (typed Lua) |
| Task functions | Shell commands | Lua functions |
| Dependencies | Simple | With arguments |
| Return values | Exit codes | Multiple values |
| Logging | Print statements | Structured logging |
| Validation | None | Optional argument validation |

## License

MIT License - see LICENSE file for details.

## Roadmap

Future features planned:

- **Cooperative parallelism** - Run independent tasks concurrently
- **Tree display** - Visual dependency tree during execution  
- **Catppuccin theming** - Beautiful colored output
- **Watch mode** - Automatic re-execution on file changes
- **Task caching** - Skip unchanged tasks
- **Plugin system** - Extensible functionality

---

Built with ❤️ using [Teal](https://github.com/teal-language/tl) and [Cyan](https://github.com/teal-language/cyan).