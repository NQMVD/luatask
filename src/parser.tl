-- Task file parser for loading Lua task definitions
-- Loads and validates taskfile.lua, converting to internal types

local Types = require('types')

local record Parser
end

-- Parse a dependency entry into a TaskCall
local function parse_dependency(dep: any): Types.TaskCall
    if type(dep) == "string" then
        return {
            name = dep as string,
            args = {}
        }
    elseif type(dep) == "table" then
        local dep_table = dep as {any}
        local call: Types.TaskCall = {
            name = dep_table[1] as string,
            args = {}
        }
        -- Copy arguments starting from index 2
        for i = 2, #dep_table do
            table.insert(call.args, tostring(dep_table[i]))
        end
        return call
    else
        error("Invalid dependency format: must be string or table")
    end
end

-- Validate an argument specification
local function validate_argument_spec(name: string, spec: any): Types.ArgumentSpec
    if type(spec) ~= "table" then
        error("Argument spec for '" .. name .. "' must be a table")
    end

    local spec_table = spec as {string: any}
    local arg_spec: Types.ArgumentSpec = {
        required = false,
        type = "string",
        default = nil
    }

    if spec_table.required ~= nil then
        if type(spec_table.required) ~= "boolean" then
            error("Argument spec '" .. name .. "': required must be boolean")
        end
        arg_spec.required = spec_table.required as boolean
    end

    if spec_table.type ~= nil then
        if type(spec_table.type) ~= "string" then
            error("Argument spec '" .. name .. "': type must be string")
        end
        arg_spec.type = spec_table.type as string
    end

    if spec_table.default ~= nil then
        arg_spec.default = spec_table.default
    end

    return arg_spec
end

-- Validate and convert a raw task definition
local function parse_task(name: string, raw_task: any): Types.Task
    if type(raw_task) ~= "table" then
        error("Task '" .. name .. "' must be a table")
    end

    local task_table = raw_task as {string: any}

    -- Validate required fields
    if type(task_table.description) ~= "string" then
        error("Task '" .. name .. "': description must be a string")
    end

    if type(task_table.run) ~= "function" then
        error("Task '" .. name .. "': run must be a function")
    end

    local task: Types.Task = {
        description = task_table.description as string,
        group = "",
        dependencies = {},
        arguments = {},
        run = task_table.run as function
    }

    -- Optional group
    if task_table.group ~= nil then
        if type(task_table.group) ~= "string" then
            error("Task '" .. name .. "': group must be a string")
        end
        task.group = task_table.group as string
    end

    -- Parse dependencies
    if task_table.dependencies ~= nil then
        if type(task_table.dependencies) ~= "table" then
            error("Task '" .. name .. "': dependencies must be a table")
        end

        local deps_array = task_table.dependencies as {any}
        for i, dep in ipairs(deps_array) do
            local success, parsed_dep = pcall(parse_dependency, dep)
            if not success then
                error("Task '" .. name .. "': invalid dependency at index " .. tostring(i) .. ": " .. tostring(parsed_dep))
            end
            table.insert(task.dependencies, parsed_dep as Types.TaskCall)
        end
    end

    -- Parse argument specifications
    if task_table.arguments ~= nil then
        if type(task_table.arguments) ~= "table" then
            error("Task '" .. name .. "': arguments must be a table")
        end

        local args_table = task_table.arguments as {string: any}
        for arg_name, spec in pairs(args_table) do
            if type(arg_name) ~= "string" then
                error("Task '" .. name .. "': argument names must be strings")
            end

            local success, parsed_spec = pcall(validate_argument_spec, arg_name, spec)
            if not success then
                error("Task '" .. name .. "': " .. tostring(parsed_spec))
            end
            task.arguments[arg_name] = parsed_spec as Types.ArgumentSpec
        end
    end

    return task
end

-- Load and parse a task file
function Parser.load_task_file(file_path: string): Types.TaskRegistry
    -- Check if file exists
    local file = io.open(file_path, "r")
    if not file then
        error("Task file not found: " .. file_path)
    end
    file:close()

    -- Load the file
    local chunk, err = loadfile(file_path)
    if not chunk then
        error("Failed to load task file: " .. (err or "unknown error"))
    end

    -- Execute the file to get the tasks table
    local success, raw_tasks = pcall(chunk)
    if not success then
        error("Failed to execute task file: " .. tostring(raw_tasks))
    end

    if type(raw_tasks) ~= "table" then
        error("Task file must return a table of tasks")
    end

    -- Parse each task
    local registry: Types.TaskRegistry = {
        tasks = {},
        file_path = file_path
    }

    local tasks_table = raw_tasks as {string: any}
    for task_name, raw_task in pairs(tasks_table) do
        if type(task_name) ~= "string" then
            error("Task names must be strings")
        end

        local parse_success, parsed_task = pcall(parse_task, task_name, raw_task)
        if not parse_success then
            error("Failed to parse task '" .. task_name .. "': " .. tostring(parsed_task))
        end

        registry.tasks[task_name] = parsed_task as Types.Task
    end

    return registry
end

-- Validate that all task dependencies exist
function Parser.validate_dependencies(registry: Types.TaskRegistry): boolean, string
    for task_name, task in pairs(registry.tasks) do
        for _, dep in ipairs(task.dependencies) do
            if not registry.tasks[dep.name] then
                return false, "Task '" .. task_name .. "' depends on unknown task '" .. dep.name .. "'"
            end
        end
    end
    return true, ""
end

-- Check for circular dependencies using DFS
local function has_circular_dependency(registry: Types.TaskRegistry, start_task: string,
                                     visited: {string: boolean}, path: {string: boolean}): boolean, string
    if path[start_task] then
        return true, "Circular dependency detected involving task '" .. start_task .. "'"
    end

    if visited[start_task] then
        return false, ""
    end

    visited[start_task] = true
    path[start_task] = true

    local task = registry.tasks[start_task]
    if task then
        for _, dep in ipairs(task.dependencies) do
            local has_cycle, err = has_circular_dependency(registry, dep.name, visited, path)
            if has_cycle then
                return true, err
            end
        end
    end

    path[start_task] = false
    return false, ""
end

-- Validate that there are no circular dependencies
function Parser.validate_no_cycles(registry: Types.TaskRegistry): boolean, string
    local visited: {string: boolean} = {}
    local path: {string: boolean} = {}

    for task_name, _ in pairs(registry.tasks) do
        if not visited[task_name] then
            local has_cycle, err = has_circular_dependency(registry, task_name, visited, path)
            if has_cycle then
                return false, err
            end
        end
    end

    return true, ""
end

-- Parse a task file with full validation
function Parser.parse_file(file_path: string): Types.TaskRegistry
    local registry = Parser.load_task_file(file_path)

    -- Validate dependencies exist
    local deps_valid, deps_err = Parser.validate_dependencies(registry)
    if not deps_valid then
        error(deps_err)
    end

    -- Validate no circular dependencies
    local cycles_valid, cycles_err = Parser.validate_no_cycles(registry)
    if not cycles_valid then
        error(cycles_err)
    end

    return registry
end

return Parser
