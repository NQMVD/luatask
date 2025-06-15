-- Main entry point for LuaTask
-- Handles CLI parsing, task loading, and execution coordination

local Types         = require('types')
local Parser        = require('parser')
local Runner        = require('runner')
local LoggerModule  = require('logger')
local Display       = require('display')

-- Global log object for tasks
global log: {string: function(string)}

-- Default configuration values
local DEFAULT_CONFIG: Types.Config = {
    task_file = "taskfile.lua",
    log_level = "INFO",
    parallel = false,
    max_jobs = 1,
    show_all_logs = false,
    no_color = false,
    dry_run = false,
    list_tasks = false,
    show_tree = false
}

-- Print usage information
local function print_usage()
    print("LuaTask - Lua-based Task Runner")
    print("")
    print("Usage:")
    print("  luatask [options] [task...]")
    print("")
    print("Options:")
    print("  --list              List available tasks")
    print("  --file FILE         Use custom task file (default: taskfile.lua)")
    print("  --log-level LEVEL   Set log level (debug/info/warn/error)")
    print("  --parallel          Enable cooperative parallelism")
    print("  --jobs N            Limit concurrent tasks (requires --parallel)")
    print("  --all-logs          Show all log messages from each task")
    print("  --last-log          Show only the last log message from each task (default)")
    print("  --tree              Show dependency tree")
    print("  --dry-run           Show execution plan without running")
    print("  --no-color          Disable colored output")
    print("  --color             Force enable colors")
    print("  --help, -h          Show this help")
    print("")
    print("Examples:")
    print("  luatask                     # List available tasks")
    print("  luatask build               # Run build task")
    print("  luatask build x86_64 debug  # Run build with arguments")
    print("  luatask clean build test    # Run multiple tasks")
    print("  luatask --parallel clean build test  # Run in parallel when possible")
end

-- Parse command line arguments
local function parse_args(args: {string}): Types.CliArgs
    local config = {
        task_file = DEFAULT_CONFIG.task_file,
        log_level = DEFAULT_CONFIG.log_level,
        parallel = DEFAULT_CONFIG.parallel,
        max_jobs = DEFAULT_CONFIG.max_jobs,
        show_all_logs = DEFAULT_CONFIG.show_all_logs,
        no_color = DEFAULT_CONFIG.no_color,
        dry_run = DEFAULT_CONFIG.dry_run,
        list_tasks = DEFAULT_CONFIG.list_tasks,
        show_tree = DEFAULT_CONFIG.show_tree
    }

    local tasks: {string} = {}
    local i = 1

    while i <= #args do
        local current_arg = args[i]

        if current_arg == "--help" or current_arg == "-h" then
            print_usage()
            os.exit(0)
        elseif current_arg == "--list" then
            config.list_tasks = true
        elseif current_arg == "--file" then
            i = i + 1
            if i > #args then
                error("--file requires a filename")
            end
            config.task_file = args[i]
        elseif current_arg == "--log-level" then
            i = i + 1
            if i > #args then
                error("--log-level requires a level (debug/info/warn/error)")
            end
            local level = args[i]:upper()
            if level ~= "DEBUG" and level ~= "INFO" and level ~= "WARN" and level ~= "ERROR" then
                error("Invalid log level: " .. args[i])
            end
            config.log_level = level
        elseif current_arg == "--parallel" then
            config.parallel = true
        elseif current_arg == "--jobs" then
            i = i + 1
            if i > #args then
                error("--jobs requires a number")
            end
            local jobs = tonumber(args[i])
            if not jobs or jobs < 1 then
                error("--jobs must be a positive number")
            end
            config.max_jobs = jobs
        elseif current_arg == "--all-logs" then
            config.show_all_logs = true
        elseif current_arg == "--last-log" then
            config.show_all_logs = false
        elseif current_arg == "--tree" then
            config.show_tree = true
        elseif current_arg == "--dry-run" then
            config.dry_run = true
        elseif current_arg == "--no-color" then
            config.no_color = true
        elseif current_arg == "--color" then
            config.no_color = false
        elseif current_arg:sub(1, 2) == "--" then
            error("Unknown option: " .. current_arg)
        else
            -- This is a task specification
            table.insert(tasks, current_arg)
        end

        i = i + 1
    end

    return {
        tasks = tasks,
        config = config
    }
end

-- List available tasks using the display system
local function list_tasks(registry: Types.TaskRegistry)
    Display.show_task_list(registry)
end

-- Check execution results and exit with appropriate code
local function check_execution_results(executions: {Types.TaskExecution})
    local any_failed = false
    for _, exec in ipairs(executions) do
        if exec.status == "fail" or exec.status == "error" then
            any_failed = true
            break
        end
    end

    if any_failed then
        os.exit(1)
    end
end

-- Main entry point
global function main(args: {string})
    local cli_args = parse_args(args)

    -- Initialize display and logger systems
    Display.init(cli_args.config.no_color)
    LoggerModule.set_global_level(cli_args.config.log_level)
    log = LoggerModule.get_log_object()

    -- Load task file
    local success, registry = pcall(Parser.parse_file, cli_args.config.task_file)
    if not success then
        print("Error loading task file: " .. tostring(registry))
        os.exit(1)
    end

    -- Handle list tasks
    if cli_args.config.list_tasks or #cli_args.tasks == 0 then
        list_tasks(registry)
        return
    end

    -- Run tasks
    local executions = Runner.run_tasks(registry, cli_args.tasks)

    -- Display results using the execution tree
    Display.show_execution_tree(executions, cli_args.config.show_all_logs)
    Display.show_execution_summary(executions)

    -- Exit with appropriate code
    check_execution_results(executions)
end
