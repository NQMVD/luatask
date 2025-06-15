-- Task execution engine with dependency resolution
-- Handles sequential task execution with pcall safety

local Types = require('types')
local Result = require('result')
local LoggerModule = require('logger')

-- Global log object for tasks
global log: {string: function(string)}

-- Manual unpacking function for Lua 5.1 compatibility
local function manual_unpack(t: {any}): any...
    if #t == 0 then return end
    if #t == 1 then return t[1] end
    if #t == 2 then return t[1], t[2] end
    if #t == 3 then return t[1], t[2], t[3] end
    if #t == 4 then return t[1], t[2], t[3], t[4] end
    if #t == 5 then return t[1], t[2], t[3], t[4], t[5] end
    -- Fallback for more arguments - just return first 5
    return t[1], t[2], t[3], t[4], t[5]
end

local record Runner
end

-- Create a new task execution state
local function create_execution(name: string, args: {string}, dependencies: {Types.TaskCall}): Types.TaskExecution
    return {
        name = name,
        args = args,
        status = "pending",
        dependencies = dependencies,
        coroutine = nil,
        start_time = 0,
        end_time = 0,
        task_result = {
            success = false,
            result = Result.FAIL,
            values = {},
            error = ""
        },
        log_messages = {}
    }
end

-- Resolve task dependencies recursively
local function resolve_dependencies(registry: Types.TaskRegistry, task_name: string,
                                  task_args: {string}, resolved: {string: boolean}, path: {string}): {Types.TaskExecution}
    -- Check for circular dependencies in this execution path
    for _, p in ipairs(path) do
        if p == task_name then
            error("Circular dependency detected: " .. table.concat(path, " -> ") .. " -> " .. task_name)
        end
    end

    -- Add this task to the current path
    local new_path = {}
    for _, p in ipairs(path) do
        table.insert(new_path, p)
    end
    table.insert(new_path, task_name)

    local executions: {Types.TaskExecution} = {}
    local task = registry.tasks[task_name]

    if not task then
        error("Task not found: " .. task_name)
    end

    -- Resolve dependencies first
    for _, dep in ipairs(task.dependencies) do
        local dep_key = dep.name .. "(" .. table.concat(dep.args, ",") .. ")"

        -- Skip if already resolved
        if not resolved[dep_key] then
            resolved[dep_key] = true
            local dep_executions = resolve_dependencies(registry, dep.name, dep.args, resolved, new_path)

            -- Add dependency executions
            for _, exec in ipairs(dep_executions) do
                table.insert(executions, exec)
            end
        end
    end

    -- Add this task execution
    local execution = create_execution(task_name, task_args, task.dependencies)
    table.insert(executions, execution)

    return executions
end

-- Execute a single task with pcall safety
local function execute_task(registry: Types.TaskRegistry, execution: Types.TaskExecution): Types.TaskResult
    local task = registry.tasks[execution.name]
    if not task then
        return {
            success = false,
            result = Result.FAIL,
            values = {},
            error = "Task not found: " .. execution.name
        }
    end

    -- Set up logging context for this task
    LoggerModule.set_global_task(execution.name)

    -- Clear any existing messages for this task
    local logger = LoggerModule.get_global_logger()
    logger.messages[execution.name] = {}

    -- Set global log object for this task
    log = LoggerModule.get_log_object()

    -- Convert string arguments to proper types if validation is available
    local processed_args: {any} = {}

    if task.arguments then
        -- Process arguments positionally with basic type conversion
        for i, task_arg in ipairs(execution.args) do
            -- Try to convert based on common patterns
            if task_arg == "true" then
                processed_args[i] = true
            elseif task_arg == "false" then
                processed_args[i] = false
            else
                local num = tonumber(task_arg)
                if num then
                    processed_args[i] = num
                else
                    processed_args[i] = task_arg
                end
            end
        end
    else
        -- No validation, just pass through as strings
        for i, task_arg in ipairs(execution.args) do
            processed_args[i] = task_arg
        end
    end

    -- Execute the task function with pcall
    local call_results = {pcall(task.run, manual_unpack(processed_args))}
    local success = call_results[1]
    local result = call_results[2]

    if not success then
        return {
            success = false,
            result = Result.FAIL,
            values = {},
            error = tostring(result) or "Unknown error"
        }
    end

    -- Validate the result
    if not Result.is_valid(tostring(result)) then
        return {
            success = false,
            result = Result.FAIL,
            values = {},
            error = "Task returned invalid result: " .. tostring(result)
        }
    end

    -- Collect additional return values
    local values = {}
    for i = 3, #call_results do
        values[i - 2] = call_results[i]
    end

    return {
        success = true,
        result = tostring(result),
        values = values,
        error = ""
    }
end

-- Parse a task specification like "build x86_64 debug" into name and args
function Runner.parse_task_spec(spec: string): string, {string}
    local parts = {}

    -- Simple split on spaces - we'll improve this later for quoted args
    for part in spec:gmatch("%S+") do
        table.insert(parts, part)
    end

    if #parts == 0 then
        error("Empty task specification")
    end

    local task_name = parts[1]
    local args = {}

    for i = 2, #parts do
        table.insert(args, parts[i])
    end

    return task_name, args
end

-- Run a list of tasks sequentially
function Runner.run_tasks(registry: Types.TaskRegistry, task_specs: {string}): {Types.TaskExecution}
    local all_executions: {Types.TaskExecution} = {}
    local resolved: {string: boolean} = {}

    -- Parse task specifications and resolve dependencies
    for _, spec in ipairs(task_specs) do
        local task_name, args = Runner.parse_task_spec(spec)
        local executions = resolve_dependencies(registry, task_name, args, resolved, {})

        for _, exec in ipairs(executions) do
            table.insert(all_executions, exec)
        end
    end

    -- Execute tasks in dependency order
    for _, execution in ipairs(all_executions) do
        execution.status = "running"
        execution.start_time = os.time()

        -- Execute the task
        execution.task_result = execute_task(registry, execution)

        execution.end_time = os.time()

        -- Collect log messages from the logger
        local logger = LoggerModule.get_global_logger()
        if logger.messages[execution.name] then
            execution.log_messages = logger.messages[execution.name]
        end

        if execution.task_result.success and Result.is_success(execution.task_result.result) then
            execution.status = "success"
        elseif execution.task_result.success and Result.is_fail(execution.task_result.result) then
            execution.status = "fail"
        else
            execution.status = "error"
        end

        -- Stop execution if a task fails
        if execution.status == "fail" or execution.status == "error" then
            break
        end
    end

    return all_executions
end

-- Get execution statistics
function Runner.get_stats(executions: {Types.TaskExecution}): {string: number}
    local stats: {string: number} = {
        total = #executions,
        success = 0,
        fail = 0,
        error = 0,
        pending = 0,
        running = 0
    }

    for _, exec in ipairs(executions) do
        local status = exec.status
        if stats[status] then
            stats[status] = stats[status] + 1
        end
    end

    return stats
end

-- Check if all executions completed successfully
function Runner.all_successful(executions: {Types.TaskExecution}): boolean
    for _, exec in ipairs(executions) do
        if exec.status ~= "success" then
            return false
        end
    end
    return true
end

return Runner
