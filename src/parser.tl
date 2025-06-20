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
        file_path = file_path,
        default_task = "",
        indexed_tasks = {} as {number: Types.Task}
    }

    local tasks_table = raw_tasks as {string: any}

    -- Check for default task specification
    if tasks_table.default then
        if type(tasks_table.default) == "string" then
            registry.default_task = tasks_table.default as string
        elseif type(tasks_table.default) == "function" then
            -- Default task is a function, create a synthetic task
            registry.tasks["default"] = {
                description = "Default task",
                group = "",
                dependencies = {},
                arguments = {},
                run = tasks_table.default as function
            }
            registry.default_task = "default"
        end
    end

    for task_name, raw_task in pairs(tasks_table) do
        -- Skip special keys like "default"
        if task_name ~= "default" then
            -- Handle indexed tasks (tasks[1], tasks[2], etc.)
            if type(task_name) == "number" then
                local index = task_name as number
                if type(raw_task) == "table" then
                    local task_table = raw_task as {string: any}
                    if task_table.name and type(task_table.name) == "string" then
                        local actual_name = task_table.name as string
                        local parse_success, parsed_task = pcall(parse_task, actual_name, raw_task)
                        if not parse_success then
                            error("Failed to parse indexed task " .. tostring(index) .. " ('" .. actual_name .. "'): " .. tostring(parsed_task))
                        end
                        registry.tasks[actual_name] = parsed_task as Types.Task
                        (registry.indexed_tasks as {number: Types.Task})[index] = parsed_task as Types.Task
                    else
                        error("Indexed task " .. tostring(index) .. " must have a 'name' field")
                    end
                else
                    error("Indexed task " .. tostring(index) .. " must be a table")
                end
            elseif type(task_name) == "string" then
                -- Handle regular named tasks
                local parse_success, parsed_task = pcall(parse_task, task_name, raw_task)
                if not parse_success then
                    error("Failed to parse task '" .. task_name .. "': " .. tostring(parsed_task))
                end
                registry.tasks[task_name] = parsed_task as Types.Task
            else
                error("Task names must be strings or numbers, got " .. type(task_name))
            end
        end
    end

    return registry
end

-- Validate that all task dependencies exist
function Parser.validate_dependencies(registry: Types.TaskRegistry): boolean, string
    for task_name, task in pairs(registry.tasks) do
        for _, dep in ipairs(task.dependencies) do
            if not registry.tasks[dep.name] then
                local available_tasks: {string} = {}
                for name, _ in pairs(registry.tasks) do
                    table.insert(available_tasks, name)
                end
                table.sort(available_tasks)

                local suggestion = ""
                if #available_tasks > 0 then
                    suggestion = "\nAvailable tasks: " .. table.concat(available_tasks, ", ")
                end

                return false, "Task '" .. task_name .. "' depends on unknown task '" .. dep.name .. "'" .. suggestion
            end
        end
    end

    -- Validate default task exists if specified
    if registry.default_task ~= "" and not registry.tasks[registry.default_task] then
        return false, "Default task '" .. registry.default_task .. "' does not exist"
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
    local success, registry = pcall(Parser.load_task_file, file_path)
    if not success then
        error("Error loading task file '" .. file_path .. "': " .. tostring(registry))
    end

    -- Validate dependencies exist
    local deps_valid, deps_err = Parser.validate_dependencies(registry as Types.TaskRegistry)
    if not deps_valid then
        error("Dependency validation failed: " .. deps_err)
    end

    -- Validate no circular dependencies
    local cycles_valid, cycles_err = Parser.validate_no_cycles(registry as Types.TaskRegistry)
    if not cycles_valid then
        error("Circular dependency detected: " .. cycles_err)
    end

    -- Ensure we have at least one task
    local task_count = 0
    for _, _ in pairs((registry as Types.TaskRegistry).tasks) do
        task_count = task_count + 1
    end

    if task_count == 0 then
        error("Task file contains no valid tasks")
    end

    return registry as Types.TaskRegistry
end

return Parser
