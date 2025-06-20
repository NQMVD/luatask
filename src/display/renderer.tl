-- Simplified Catppuccin-themed renderer for LuaTask
-- Handles visual output with tree structure display

local Types = require('types')
local Colors = require('colors')

local record Renderer
end

-- Parse description to extract argument hints
local record DescriptionParts
    args: string
    description: string
end

local function parse_task_description(description: string): DescriptionParts
    -- Look for argument patterns like [arg], [arg='default'], [arg...]
    local args_pattern = "%[([^%]]+)%]"
    local args: {string} = {}
    local clean_desc = description

    -- Extract all argument patterns
    for arg_spec in description:gmatch(args_pattern) do
        table.insert(args, "[" .. arg_spec .. "]")
        -- Remove from description
        clean_desc = clean_desc:gsub("%[" .. arg_spec:gsub("([%(%)%.%+%-%*%?%[%^%$%%])", "%%%1") .. "%]", "")
    end

    -- Clean up extra whitespace
    clean_desc = clean_desc:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

    return {
        args = table.concat(args, " "),
        description = clean_desc
    }
end

-- Initialize renderer with color settings
function Renderer.init(no_color: boolean)
    Colors.set_enabled(not no_color)
end

-- Format task duration
local function format_duration(start_time: number, end_time: number): string
    if start_time == 0 or end_time == 0 then
        return ""
    end
    local duration = end_time - start_time
    if duration >= 1.0 then
        return " " .. Colors.timing(string.format("(%.1fs)", duration))
    else
        return " " .. Colors.timing(string.format("(%.0fms)", duration * 1000))
    end
end

-- Get status symbol with colors
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

-- Format task name with arguments
local function format_task_display(name: string, args: {string}): string
    local formatted = Colors.task_name(name)
    if #args > 0 then
        formatted = formatted .. " " .. Colors.dependency(table.concat(args, " "))
    end
    return formatted
end

-- Find root tasks from execution list (tasks that are marked as roots)
local function find_root_executions(executions: {Types.TaskExecution}): {Types.TaskExecution}
    local roots: {Types.TaskExecution} = {}

    for _, exec in ipairs(executions) do
        if exec.is_root then
            table.insert(roots, exec)
        end
    end

    -- If no roots found, use all executions as fallback
    if #roots == 0 then
        return executions
    end

    return roots
end

-- Display a single execution with its tree structure using actual children
local function display_tree_node(exec: Types.TaskExecution, prefix: string, is_last: boolean,
                                 all_executions: {Types.TaskExecution}, show_all_logs: boolean,
                                 visited: {string: boolean})
    -- Prevent infinite recursion
    local exec_key = exec.name .. "(" .. table.concat(exec.args, ",") .. ")"
    if visited[exec_key] then
        return
    end
    visited[exec_key] = true

    -- Display this node
    local connector = is_last and "╰── " or "├── "
    local status_symbol = get_status_symbol(exec.status)
    local task_display = format_task_display(exec.name, exec.args)
    local duration_str = format_duration(exec.start_time, exec.end_time)

    print(Colors.tree_symbol(prefix .. connector) .. status_symbol .. " " .. task_display .. duration_str)

    -- Calculate prefix for children and details
    local child_prefix = prefix .. (is_last and "    " or "│   ")

    -- Count total items to display (children + logs + errors + results)
    local total_items = 0
    local children_to_show: {Types.TaskExecution} = {}

    -- Find actual executed children from the all_executions list
    if exec.children and #exec.children > 0 then
        for _, child in ipairs(exec.children) do
            -- Find the executed version of this child
            for _, executed_task in ipairs(all_executions) do
                if executed_task.name == child.name and
                   #executed_task.args == #child.args then
                    -- Check if args match
                    local args_match = true
                    for i, child_arg in ipairs(child.args) do
                        if executed_task.args[i] ~= child_arg then
                            args_match = false
                            break
                        end
                    end
                    if args_match then
                        table.insert(children_to_show, executed_task)
                        total_items = total_items + 1
                        break
                    end
                end
            end
        end
    end

    -- Add log messages count
    if #exec.log_messages > 0 then
        local logs_to_show = show_all_logs and exec.log_messages or {exec.log_messages[#exec.log_messages]}
        total_items = total_items + #logs_to_show
    end

    -- Add error count
    if exec.task_result and exec.task_result.error and exec.task_result.error ~= "" then
        total_items = total_items + 1
    end

    -- Add results count
    if exec.task_result and #exec.task_result.values > 0 then
        total_items = total_items + 1
    end

    local current_item = 0

    -- Display children first (dependencies)
    for _, child_exec in ipairs(children_to_show) do
        current_item = current_item + 1
        local child_is_last = (current_item == total_items)
        display_tree_node(child_exec, child_prefix, child_is_last, all_executions, show_all_logs, visited)
    end

    -- Show log messages after children
    if #exec.log_messages > 0 then
        local logs_to_show = show_all_logs and exec.log_messages or {exec.log_messages[#exec.log_messages]}

        for _, log_msg in ipairs(logs_to_show) do
            current_item = current_item + 1
            local is_last_item = (current_item == total_items)
            local log_connector = is_last_item and "╰─ " or "├─ "
            local color_func = Colors.log_color_for_level(log_msg.level)
            print(Colors.tree_symbol(child_prefix) .. Colors.tree_symbol(log_connector) ..
                  color_func(log_msg.level .. ": " .. log_msg.message))
        end
    end

    -- Show error message if present
    if exec.task_result and exec.task_result.error and exec.task_result.error ~= "" then
        current_item = current_item + 1
        local is_last_item = (current_item == total_items)
        local error_connector = is_last_item and "╰─ " or "├─ "
        print(Colors.tree_symbol(child_prefix) .. Colors.tree_symbol(error_connector) ..
              Colors.error_text("Error: " .. exec.task_result.error))
    end

    -- Show task results if available
    if exec.task_result and #exec.task_result.values > 0 then
        current_item = current_item + 1
        local values_strs: {string} = {}
        for _, value in ipairs(exec.task_result.values) do
            table.insert(values_strs, tostring(value))
        end
        local values_str = "Returned: " .. table.concat(values_strs, ", ")
        print(Colors.tree_symbol(child_prefix) .. Colors.tree_symbol("╰─ ") ..
              Colors.dependency(values_str))
    end
end

-- Display execution tree with true hierarchical structure
function Renderer.show_execution_tree(executions: {Types.TaskExecution}, show_all_logs: boolean)
    if #executions == 0 then
        print(Colors.warning("No tasks executed."))
        return
    end

    print(Colors.group_header("Tasks:"))
    print("")

    -- Find root executions (tasks marked as roots)
    local roots = find_root_executions(executions)

    if #roots == 0 then
        -- Fallback to flat display if no root tasks found
        for i, exec in ipairs(executions) do
            local is_last = (i == #executions)
            local connector = is_last and "╰── " or "├── "
            local status_symbol = get_status_symbol(exec.status)
            local task_display = format_task_display(exec.name, exec.args)
            local duration_str = format_duration(exec.start_time, exec.end_time)

            print(Colors.tree_symbol(connector) .. status_symbol .. " " .. task_display .. duration_str)
        end
    else
        -- Display true hierarchical tree structure using actual children
        for i, root in ipairs(roots) do
            local is_last_root = (i == #roots)
            local visited: {string: boolean} = {}
            display_tree_node(root, "", is_last_root, executions, show_all_logs, visited)
        end
    end
end

-- Display task list with groups and dependencies
function Renderer.show_task_list(registry: Types.TaskRegistry)
    print(Colors.group_header("Available tasks:"))
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
                deps = ": " .. Colors.dependency(table.concat(dep_names, ", "))
            end

            -- Parse description for argument hints
            local desc_parts = parse_task_description(task.description)
            local task_signature = Colors.task_name(name)
            if desc_parts.args ~= "" then
                task_signature = task_signature .. " " .. Colors.dependency(desc_parts.args)
            end

            print("  " .. task_signature .. deps .. " - " .. desc_parts.description)
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
                deps = ": " .. Colors.dependency(table.concat(dep_names, ", "))
            end

            -- Parse description for argument hints
            local desc_parts = parse_task_description(task.description)
            local task_signature = Colors.task_name(name)
            if desc_parts.args ~= "" then
                task_signature = task_signature .. " " .. Colors.dependency(desc_parts.args)
            end

            print("  " .. task_signature .. deps .. " - " .. desc_parts.description)
        end
    end
end

-- Display execution summary
function Renderer.show_execution_summary(executions: {Types.TaskExecution})
    if #executions == 0 then
        return
    end

    local total_time: number = 0
    local any_failed = false
    local stats = {
        success = 0,
        fail = 0,
        error = 0,
        total = #executions
    }

    for _, exec in ipairs(executions) do
        local duration = exec.end_time - exec.start_time
        total_time = total_time + duration

        if exec.status == "success" then
            stats.success = stats.success + 1
        elseif exec.status == "fail" then
            stats.fail = stats.fail + 1
            any_failed = true
        elseif exec.status == "error" then
            stats.error = stats.error + 1
            any_failed = true
        end
    end

    print("")

    -- Format timing with appropriate precision
    local timing_str = ""
    if total_time >= 1.0 then
        timing_str = string.format("%.1fs", total_time)
    else
        timing_str = string.format("%.0fms", total_time * 1000)
    end

    print(Colors.timing("Total time: " .. timing_str))

    -- Show detailed stats if multiple tasks
    if stats.total > 1 then
        local stat_parts: {string} = {}
        if stats.success > 0 then
            table.insert(stat_parts, Colors.success(tostring(stats.success) .. " succeeded"))
        end
        if stats.fail > 0 then
            table.insert(stat_parts, Colors.error_text(tostring(stats.fail) .. " failed"))
        end
        if stats.error > 0 then
            table.insert(stat_parts, Colors.warning(tostring(stats.error) .. " errored"))
        end

        if #stat_parts > 0 then
            print("Tasks: " .. table.concat(stat_parts, ", "))
        end
    end

    -- Final status
    if any_failed then
        print(Colors.error_text("Some tasks failed!"))
    else
        print(Colors.success("All tasks completed successfully!"))
    end
end

return {
    init = Renderer.init,
    show_execution_tree = Renderer.show_execution_tree,
    show_task_list = Renderer.show_task_list,
    show_execution_summary = Renderer.show_execution_summary
}
