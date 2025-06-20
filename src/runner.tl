-- Task execution engine with dependency resolution and tree building
-- Handles sequential task execution with optional return support

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
            error = "",
            has_explicit_result = false
        },
        log_messages = {},
        depth = 0,
        is_root = false,
        backend_id = "",
        children = {}
    }
end

-- Build hierarchical dependency tree structure
local function build_dependency_tree(registry: Types.TaskRegistry, task_name: string,
                                    task_args: {string}, resolved: {string: boolean},
                                    path: {string}): Types.TaskExecution
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

    local task = registry.tasks[task_name]
    if not task then
        error("Task not found: " .. task_name)
    end



    -- Create this task execution
    local execution = create_execution(task_name, task_args, task.dependencies)

    -- Build dependency tree by resolving dependencies as children
    local child_executions: {Types.TaskExecution} = {}
    for _, dep in ipairs(task.dependencies) do
        -- Always build the dependency tree, but track if we've seen this execution
        local dep_execution = build_dependency_tree(registry, dep.name, dep.args, resolved, new_path)
        table.insert(child_executions, dep_execution)
    end

    -- Store child executions in a new field for tree structure
    execution.children = child_executions

    return execution
end

-- Flatten tree into execution order (depth-first, dependencies first)
local function flatten_execution_tree(root: Types.TaskExecution, flattened: {Types.TaskExecution},
                                     visited: {string: boolean})
    -- Process dependencies first (depth-first)
    for _, child in ipairs(root.children or {}) do
        flatten_execution_tree(child, flattened, visited)
    end

    -- Then process this task
    local root_key = root.name .. "(" .. table.concat(root.args, ",") .. ")"
    if not visited[root_key] then
        visited[root_key] = true
        table.insert(flattened, root)
    end
end

-- Execute a single task with optional return handling
local function execute_task(registry: Types.TaskRegistry, execution: Types.TaskExecution): Types.TaskResult
    local task = registry.tasks[execution.name]
    if not task then
        return {
            success = false,
            result = Result.FAIL,
            values = {},
            error = "Task not found: " .. execution.name,
            has_explicit_result = false
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

    -- Execute the task function with optional return handling
    local task_success, result_value, return_values = Result.run_task(task.run, manual_unpack(processed_args))

    if not task_success then
        return {
            success = false,
            result = result_value,
            values = return_values,
            error = tostring(return_values[1]) or "Unknown error",
            has_explicit_result = true
        }
    end

    -- Determine if result was explicitly returned
    local has_explicit = result_value == Result.SUCCESS or result_value == Result.FAIL

    return {
        success = true,
        result = result_value,
        values = return_values,
        error = "",
        has_explicit_result = has_explicit
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

-- Get or use default task from registry
function Runner.resolve_task_list(registry: Types.TaskRegistry, task_specs: {string}): {string}
    if #task_specs == 0 then
        -- No tasks specified, use default if available
        if registry.default_task ~= "" then
            return {registry.default_task}
        else
            error("No tasks specified and no default task defined")
        end
    end
    return task_specs
end

-- Mark executions with tree hierarchy information for display
local function mark_tree_hierarchy(execution: Types.TaskExecution, depth: number)
    execution.depth = depth

    for _, child in ipairs(execution.children or {}) do
        mark_tree_hierarchy(child, depth + 1)
    end
end

-- Run a list of tasks sequentially with true tree structure
function Runner.run_tasks(registry: Types.TaskRegistry, task_specs: {string}): {Types.TaskExecution}
    -- Resolve default task if needed
    local actual_specs = Runner.resolve_task_list(registry, task_specs)

    -- Build tree structures for each requested task
    local root_trees: {Types.TaskExecution} = {}
    local resolved: {string: boolean} = {}

    for _, spec in ipairs(actual_specs) do
        local task_name, args = Runner.parse_task_spec(spec)

        -- Check if task exists before building tree
        if not registry.tasks[task_name] then
            local available_tasks: {string} = {}
            for name, _ in pairs(registry.tasks) do
                table.insert(available_tasks, name)
            end
            table.sort(available_tasks)

            local suggestion = ""
            if #available_tasks > 0 then
                suggestion = "\nAvailable tasks: " .. table.concat(available_tasks, ", ")
            end

            error("Task not found: " .. task_name .. suggestion)
        end

        -- Build dependency tree for this root task
        local tree = build_dependency_tree(registry, task_name, args, resolved, {})
        tree.is_root = true
        mark_tree_hierarchy(tree, 0)
        table.insert(root_trees, tree)
    end

    -- Flatten trees into execution order
    local all_executions: {Types.TaskExecution} = {}
    local visited: {string: boolean} = {}

    for _, root in ipairs(root_trees) do
        flatten_execution_tree(root, all_executions, visited)
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

    -- Store the tree structure by copying children to all matching executions
    -- and marking root tasks properly
    for _, root_tree in ipairs(root_trees) do
        for _, execution in ipairs(all_executions) do
            if execution.name == root_tree.name and #execution.args == #root_tree.args then
                -- Check if args match exactly
                local args_match = true
                for i, root_arg in ipairs(root_tree.args) do
                    if execution.args[i] ~= root_arg then
                        args_match = false
                        break
                    end
                end

                if args_match then
                    execution.children = root_tree.children
                    execution.is_root = true
                    execution.depth = root_tree.depth
                end
            end
        end
    end

    -- Also copy children structure to all intermediate tasks by walking the tree
    local function copy_children_recursive(tree_node: Types.TaskExecution)
        for _, execution in ipairs(all_executions) do
            if execution.name == tree_node.name and #execution.args == #tree_node.args then
                local args_match = true
                for i, tree_arg in ipairs(tree_node.args) do
                    if execution.args[i] ~= tree_arg then
                        args_match = false
                        break
                    end
                end

                if args_match then
                    execution.children = tree_node.children
                    execution.depth = tree_node.depth
                end
            end
        end

        -- Recursively copy for children
        for _, child in ipairs(tree_node.children or {}) do
            copy_children_recursive(child)
        end
    end

    for _, root_tree in ipairs(root_trees) do
        copy_children_recursive(root_tree)
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
