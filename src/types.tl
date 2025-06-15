-- Core type definitions for LuaTask
-- Defines all the main data structures used throughout the system

-- Argument specification for task validation
local record ArgumentSpec
    required: boolean      -- Whether this argument is required
    type: string          -- Expected type ("string", "number", "boolean", etc.)
    default: any          -- Default value if not provided
end

-- Task dependency can be either a simple string or a table with arguments
local record TaskCall
    name: string          -- Task name
    args: {string}        -- Arguments to pass to the task
end

-- Main task definition structure
local record Task
    description: string                    -- Human-readable description
    group: string                         -- Optional group name for organization
    dependencies: {TaskCall}              -- List of dependencies (normalized to TaskCall)
    arguments: {string: ArgumentSpec}     -- Argument validation specs (optional)
    run: function      -- Task function that returns Result + extras
end

-- Result of task execution (from pcall + task function)
local record TaskResult
    success: boolean      -- Whether pcall succeeded
    result: string        -- Result.SUCCESS or Result.FAIL from task
    values: {any}         -- Additional return values from task
    error: string         -- Error message if pcall failed
end

-- Task execution state tracking
local record TaskExecution
    name: string              -- Task name
    args: {string}            -- Arguments passed to this execution
    status: string            -- "pending", "running", "success", "fail", "error"
    dependencies: {TaskCall}  -- Resolved dependency calls
    coroutine: thread         -- Coroutine for this task (for parallelism)
    start_time: number        -- Execution start timestamp
    end_time: number          -- Execution end timestamp
    task_result: TaskResult   -- Result of task execution
    log_messages: {LogMessage} -- Log messages from this task
end

-- Log message structure
local record LogMessage
    level: string         -- "DEBUG", "INFO", "WARN", "ERROR"
    message: string       -- Log message content
    timestamp: number     -- When the message was logged
end

-- Configuration for the task runner
local record Config
    task_file: string         -- Path to task file (default "taskfile.lua")
    log_level: string         -- Minimum log level to display
    parallel: boolean         -- Enable cooperative parallelism
    max_jobs: number          -- Maximum concurrent tasks
    show_all_logs: boolean    -- Show all logs vs just last message
    no_color: boolean         -- Disable colored output
    dry_run: boolean          -- Show execution plan without running
    list_tasks: boolean       -- Just list tasks and exit
    show_tree: boolean        -- Show dependency tree
end

-- Parsed command line arguments
local record CliArgs
    tasks: {string}           -- Tasks to run (with arguments)
    config: Config            -- Configuration options
end

-- Task registry (loaded from task file)
local record TaskRegistry
    tasks: {string: Task}     -- Map of task name to task definition
    file_path: string         -- Path to the loaded task file
end

-- Types module exports
local record Types
    ArgumentSpec: ArgumentSpec
    TaskCall: TaskCall
    Task: Task
    TaskResult: TaskResult
    TaskExecution: TaskExecution
    LogMessage: LogMessage
    Config: Config
    CliArgs: CliArgs
    TaskRegistry: TaskRegistry
end

return Types
