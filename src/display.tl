-- Display system for LuaTask execution tree visualization
-- Handles tree structure display with real-time status updates and Catppuccin colors

local Types = require('types')
local Colors = require('colors')

local record Display
end

-- Get status symbol for a task
local function get_status_symbol(status: string): string
    if status == "success" then
        return Colors.success_symbol()
    elseif status == "fail" then
        return Colors.fail_symbol()
    elseif status == "error" then
        return Colors.error_symbol()
    elseif status == "running" then
        return Colors.running_symbol()
    else
        return Colors.pending_symbol()
    end
end

-- Format task duration
local function format_duration(start_time: number, end_time: number): string
    if start_time == 0 or end_time == 0 then
        return ""
    end
    local duration = end_time - start_time
    return Colors.timing("(" .. duration .. "s)")
end


-- Display execution tree
function Display.show_execution_tree(executions: {Types.TaskExecution}, show_all_logs: boolean)
    if #executions == 0 then
        print("No tasks executed.")
        return
    end

    print("Tasks:")

    -- For simple sequential execution, just show as a flat list with tree symbols
    -- This matches the expected output format better than trying to build complex trees
    for i, exec in ipairs(executions) do
        local is_last = (i == #executions)
        local connector = is_last and "└── " or "├── "
        local status_symbol = get_status_symbol(exec.status)

        -- Format task name with arguments
        local task_display = Colors.task_name(exec.name)
        if #exec.args > 0 then
            task_display = task_display .. " " .. table.concat(exec.args, " ")
        end

        -- Format duration
        local duration_str = format_duration(exec.start_time, exec.end_time)
        if duration_str ~= "" then
            duration_str = " " .. duration_str
        end

        print(Colors.tree_symbol(connector) .. status_symbol .. " " .. task_display .. duration_str)

        -- Show log messages
        if show_all_logs and #exec.log_messages > 0 then
            local log_prefix = is_last and "    " or "│   "
            for j, log_msg in ipairs(exec.log_messages) do
                local is_last_log = (j == #exec.log_messages)
                local log_connector = is_last_log and "└─ " or "├─ "
                local color_func = Colors.log_color_for_level(log_msg.level)
                print(log_prefix .. Colors.tree_symbol(log_connector) .. color_func(log_msg.level .. ": " .. log_msg.message))
            end
        elseif not show_all_logs and #exec.log_messages > 0 then
            -- Show only the last log message
            local log_prefix = is_last and "    " or "│   "
            local last_msg = exec.log_messages[#exec.log_messages]
            local color_func = Colors.log_color_for_level(last_msg.level)
            print(log_prefix .. Colors.tree_symbol("├─ ") .. color_func(last_msg.level .. ": " .. last_msg.message))
        end

        -- Show error message if present
        if exec.task_result and exec.task_result.error ~= "" then
            local log_prefix = is_last and "    " or "│   "
            print(log_prefix .. Colors.tree_symbol("├─ ") .. Colors.error_text("Error: " .. exec.task_result.error))
        end

        -- Show task results if available
        if exec.task_result and #exec.task_result.values > 0 then
            local log_prefix = is_last and "    " or "│   "
            local values_str = "Result: " .. exec.task_result.result
            for _, value in ipairs(exec.task_result.values) do
                values_str = values_str .. ", " .. tostring(value)
            end
            print(log_prefix .. Colors.tree_symbol("└─ ") .. Colors.dependency(values_str))
        end
    end
end

-- Display task list with groups and dependencies
function Display.show_task_list(registry: Types.TaskRegistry)
    print("Available tasks:")
    print("")

    -- Group tasks by group
    local groups: {string: {string}} = {}
    local ungrouped: {string} = {}

    for name, task in pairs(registry.tasks) do
        if task.group and task.group ~= "" then
            if not groups[task.group] then
                groups[task.group] = {}
            end
            table.insert(groups[task.group], name)
        else
            table.insert(ungrouped, name)
        end
    end

    -- Sort task names
    table.sort(ungrouped)
    for _, task_list in pairs(groups) do
        table.sort(task_list)
    end

    -- Print grouped tasks
    for group, task_list in pairs(groups) do
        print(Colors.group_header(group .. ":"))
        for _, name in ipairs(task_list) do
            local task = registry.tasks[name]
            local deps = ""
            if #task.dependencies > 0 then
                local dep_names: {string} = {}
                for _, dep in ipairs(task.dependencies) do
                    if #dep.args > 0 then
                        table.insert(dep_names, dep.name .. "(" .. table.concat(dep.args, ", ") .. ")")
                    else
                        table.insert(dep_names, dep.name)
                    end
                end
                deps = " " .. Colors.dependency("[depends: " .. table.concat(dep_names, ", ") .. "]")
            end
            print("  " .. Colors.task_name(name) .. deps .. " - " .. task.description)
        end
        print("")
    end

    -- Print ungrouped tasks
    if #ungrouped > 0 then
        if next(groups) ~= nil then
            print(Colors.group_header("Other tasks:"))
        end
        for _, name in ipairs(ungrouped) do
            local task = registry.tasks[name]
            local deps = ""
            if #task.dependencies > 0 then
                local dep_names: {string} = {}
                for _, dep in ipairs(task.dependencies) do
                    if #dep.args > 0 then
                        table.insert(dep_names, dep.name .. "(" .. table.concat(dep.args, ", ") .. ")")
                    else
                        table.insert(dep_names, dep.name)
                    end
                end
                deps = " " .. Colors.dependency("[depends: " .. table.concat(dep_names, ", ") .. "]")
            end
            print("  " .. Colors.task_name(name) .. deps .. " - " .. task.description)
        end
    end
end

-- Display execution summary
function Display.show_execution_summary(executions: {Types.TaskExecution})
    if #executions == 0 then
        return
    end

    local total_time: number = 0
    local any_failed = false

    for _, exec in ipairs(executions) do
        local duration = exec.end_time - exec.start_time
        total_time = total_time + duration

        if exec.status == "fail" or exec.status == "error" then
            any_failed = true
        end
    end

    print("")
    print(Colors.timing("Total time: " .. total_time .. "s"))

    if any_failed then
        print(Colors.error_text("Some tasks failed!"))
    else
        print(Colors.success("All tasks completed successfully!"))
    end
end

-- Initialize display system
function Display.init(no_color: boolean)
    Colors.set_enabled(not no_color)
end

return Display
