# LuaTask - Lua-based Task Runner

A Just-inspired task runner written in Teal that uses Lua for both the executable and task files, featuring tree-structured task display, cooperative parallelism, and beautiful Catppuccin Mocha theming.

## Project Overview

### Core Requirements
- **Task runner inspired by Just** - Simple, declarative task definitions
- **Lua-based** - Both the executable and task files use Lua/Teal
- **Tree structure display** - Show task dependencies and execution visually
- **Leveled logging system** - Configurable log output with multiple display modes
- **Exit handling** - Clear success/failure states using enums
- **Written in Teal** - Typed Lua for better maintainability
- **Just-like arguments** - Tasks support positional arguments with defaults
- **Cooperative parallelism** - Independent tasks can run concurrently
- **Task grouping** - Organize tasks by category
- **Catppuccin Mocha theming** - Beautiful colored output with bold text

### Target Specifications
- **Lua Version**: 5.1 (compatible with LuaJIT)
- **Dependencies**: Minimal - prefer pure Lua implementation
- **No built-in tasks** - Pure task runner, no magic commands
- **No task overloading** - One task per name
- **No multi-scripting support** - Pure Lua functions only
- **Optional argument validation** - Validate when specified, ignore otherwise
- **No automatic task discovery** - Explicit task definitions only

## Project Structure

```
luatask/
├── src/
│   ├── main.tl              # Entry point & CLI parsing
│   ├── parser.tl            # Task file parser
│   ├── runner.tl            # Cooperative task execution engine
│   ├── logger.tl            # Logging system with colors
│   ├── display.tl           # Tree display with Catppuccin colors
│   ├── args.tl              # Just-like argument parsing utilities
│   ├── colors.tl            # Catppuccin Mocha color palette
│   ├── result.tl            # Result enum (SUCCESS/FAIL)
│   └── types.tl             # Core type definitions
├── examples/
│   └── taskfile.lua         # Example task file with all features
├── tests/
│   ├── test_parser.tl       # Parser tests
│   ├── test_runner.tl       # Runner tests
│   ├── test_args.tl         # Argument parsing tests
│   └── test_display.tl      # Display tests
├── teal-config.lua          # Teal compiler configuration
├── Makefile                 # Build automation
└── README.md                # Project documentation
```

## Core Components

### 1. Result System (result.tl)

**Purpose**: Type-safe result handling for task execution

```lua
local Result = {
    SUCCESS = "SUCCESS",
    FAIL = "FAIL"
}
```

**Features**:
- Enum-based results instead of string literals
- Multiple return values supported
- Results captured via pcall for error safety

### 2. Task File Format

**File**: `taskfile.lua` (user-defined)

**Structure**:
```lua
local tasks = {}
local Result = require('luatask.result')

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

**Key Features**:
- **Arguments**: Just-like positional arguments with defaults
- **Dependencies**: Can specify arguments for dependency tasks
- **Validation**: Optional type checking and required argument validation
- **Multiple returns**: Tasks can return additional data beyond result enum
- **Grouping**: Optional group field for organizing tasks
- **Logging**: Global `log` object available in task functions

### 3. Type System (types.tl)

**Core Types**:
```teal
local record ArgumentSpec
    required: boolean
    type: string
    default: string
end

local record Task
    description: string
    group: string  -- optional
    dependencies: {string | {string}}
    arguments: {string: ArgumentSpec}  -- optional
    run: function(...): string, ...
end

local record TaskResult
    success: boolean  -- pcall success
    result: string    -- Result.SUCCESS or Result.FAIL
    values: {any}     -- additional return values
    error: string     -- error message if pcall failed
end

local record TaskExecution
    name: string
    args: {string}
    status: string  -- "pending", "running", "success", "fail", "error"
    dependencies: {TaskCall}
    coroutine: thread
    start_time: number
    end_time: number
    task_result: TaskResult
end
```

### 4. CLI Interface

**Basic Usage**:
```bash
luatask                          # List available tasks
luatask clean                    # Run clean task
luatask build x86_64 debug       # Run build with arguments
luatask deploy staging           # Run deploy with argument
```

**Multiple Tasks**:
```bash
luatask clean build test         # Run in sequence
luatask "build x86_64 debug" test # Quoted for complex arguments
```

**Options**:
```bash
luatask --list                   # Show grouped task list with dependencies
luatask --parallel clean build test    # Enable cooperative parallelism
lutatask --jobs 3 --parallel task1 task2 task3  # Limit concurrent tasks
luatask --log-level debug build        # Set log level (debug/info/warn/error)
luatask --all-logs build               # Show all logs vs last only
luatask --file custom.lua build       # Use custom task file
lutatask --tree build                  # Show dependency tree
lulatask --dry-run deploy production  # Show execution plan
lutatask --no-color build             # Disable colors
lutatask --color build                # Force enable colors (default)
```

### 5. Argument System (args.tl)

**Just-like Parsing**:
- `luatask build x86_64 debug` → `build("x86_64", "debug")`
- `lutatask test unit integration` → `test("unit", "integration")`
- Support for variadic arguments: `function(...)`
- Default values: `mode = mode or "release"`
- the args description should be generated and print when --list

**Validation** (when `arguments` table exists):
```lua
arguments = {
    target = {required = true, type = "string"},
    mode = {required = false, default = "release", type = "string"}
}
```

**Features**:
- Optional validation - only validate if `arguments` table present
- Type checking for provided arguments
- Required argument validation
- Default value application

### 6. Cooperative Parallelism (runner.tl)

**Implementation**: Coroutine-based cooperative scheduling

**Features**:
- Dependency-aware task scheduling
- Configurable job limits (`--jobs N`)
- Independent tasks run concurrently
- Dependent tasks wait for prerequisites
- pcall wrapper for error safety

**Execution Flow**:
1. Parse dependencies and build execution graph
2. Schedule tasks with satisfied dependencies
3. Run tasks in coroutines with cooperative yielding
4. Update dependency status as tasks complete
5. Continue until all tasks finished

### 7. Logging System (logger.tl)

**Log Levels**:
- `DEBUG` (0): Detailed debugging information
- `INFO` (1): General information (default)
- `WARN` (2): Warning messages
- `ERROR` (3): Error messages only

**Features**:
- Per-task message storage
- Two display modes:
  - `--all-logs`: Show all messages for each task
  - Default: Show only last message per task
- Colored output based on log level
- Global `log` object available in task files

**Usage in Tasks**:
```lua
run = function(target)
    log.info("Building " .. target)
    log.debug("Processing source files...")
    log.warn("Deprecated feature used")
    log.error("Build failed!")
    return Result.SUCCESS
end
```

### 8. Display System (display.tl)

**Tree Display Features**:
- Hierarchical task execution visualization
- Real-time status updates during execution
- Colored status indicators (✓ ✗ ⚠ ⟳ ○)
- Execution timing display
- Task result details (additional return values)
- Log message integration
- Catppuccin Mocha color scheme

**Task List Display**:
- Grouped by task group
- Shows dependencies with arguments
- Colored task names and descriptions
- Bold headers for groups

### 9. Color System (colors.tl)

**Catppuccin Mocha Palette**:
- **Task names**: Lavender (bold)
- **Success indicators**: Green (bold)
- **Error indicators**: Red (bold)
- **Group headers**: Mauve (bold)
- **Dependencies**: Subtext (dim)
- **Timing info**: Overlay (subtle)
- **Tree symbols**: Surface (structural)
- **Log levels**:
  - INFO: Blue
  - WARN: Yellow (bold)
  - ERROR: Red (bold)
  - DEBUG: Overlay (dim)

**Color Control**:
- Default: Colors enabled
- `--no-color`: Disable all colors
- `--color`: Force enable colors
- Automatic detection of terminal capabilities

## Implementation Phases

### Phase 1: Core Framework
**Goal**: Basic task execution with result system

**Components**:
- [ ] `result.tl` - Result enum definition
- [ ] `types.tl` - Core type definitions
- [ ] `parser.tl` - Basic task file parsing
- [ ] `main.tl` - CLI entry point and basic argument parsing
- [ ] `runner.tl` - Sequential task execution with pcall
- [ ] Basic success/failure handling

**Deliverable**: Can run simple tasks with SUCCESS/FAIL results

### Phase 2: Arguments & Validation
**Goal**: Just-like argument support with optional validation

**Components**:
- [ ] `args.tl` - Argument parsing utilities
- [ ] Enhanced `parser.tl` - Parse task arguments and validation specs
- [ ] Enhanced `runner.tl` - Pass arguments to tasks
- [ ] Dependency resolution with arguments
- [ ] Argument validation system

**Deliverable**: Tasks can accept arguments with optional type validation

### Phase 3: Logging & Display
**Goal**: Colored tree display with logging

**Components**:
- [ ] `colors.tl` - Catppuccin Mocha color palette
- [ ] `logger.tl` - Leveled logging system with colors
- [ ] `display.tl` - Tree visualization with colors
- [ ] Enhanced CLI options for display control
- [ ] Task grouping and list display

**Deliverable**: Beautiful colored output with tree structure

### Phase 4: Cooperative Parallelism
**Goal**: Concurrent execution of independent tasks

**Components**:
- [ ] Enhanced `runner.tl` - Coroutine-based parallel execution
- [ ] Dependency graph analysis
- [ ] Job scheduling and limiting
- [ ] Enhanced `display.tl` - Real-time parallel status updates

**Deliverable**: Tasks run in parallel when dependencies allow

### Phase 5: Polish & Testing
**Goal**: Production-ready with comprehensive testing

**Components**:
- [ ] Comprehensive test suite
- [ ] Error handling improvements
- [ ] Performance optimization
- [ ] Documentation and examples
- [ ] Edge case handling

**Deliverable**: Stable, well-tested task runner

## Example Outputs

### Task List (`luatask --list`)
```
Available tasks:

build:
  clean - Clean build artifacts
  build [depends: clean] - Build project [target] [mode='release']

deploy:
  deploy_staging [depends: build(x86_64, release), test] - Deploy to staging
  deploy_production [depends: deploy_staging] - Deploy to production

testing:
  test [depends: build] - Run tests [pattern...]

Other tasks:
  check_deps - Check system dependencies
```

### Execution Tree (`luatask deploy_production`)
```
Execution tree:

├── clean ✓ (0.1s)
├── build x86_64 release ✓ (2.3s)
│   ├─ INFO: Building x86_64 in release mode...
│   └─ Result: SUCCESS, 1623456789, 2
├── test ✓ (1.8s)
│   ├─ INFO: Running tests...
│   └─ Result: SUCCESS, 42
├── deploy_staging ✓ (0.5s)
│   ├─ INFO: Deploying to staging...
│   └─ Result: SUCCESS, deploy-1623456790
└── deploy_production ✓ (0.3s)
    ├─ INFO: Deploying to production...
    └─ Result: SUCCESS

Total time: 4.9s
```

## Technical Considerations

### Lua 5.1 Compatibility
- No `#` length operator on tables (use `table.getn()` or manual counting)
- No `table.pack`/`unpack` (implement manually if needed)
- No bitwise operators
- Use `loadstring()` instead of `load()`
- `module()` function available

### Error Handling Strategy
- All task execution wrapped in `pcall`
- Graceful handling of circular dependencies
- Validation of task file syntax and structure
- Clear error messages with context
- Recovery from individual task failures
