-- Main display coordination system for LuaTask
-- Simplified display system using renderer for proper hierarchical display

local Types = require('types')
local Renderer = require('display.renderer')

local record Display
end

-- Initialize the display system
function Display.init(no_color: boolean)
    Renderer.init(no_color)
end

-- Show execution tree with true hierarchical structure
function Display.show_execution_tree(executions: {Types.TaskExecution}, show_all_logs: boolean)
    Renderer.show_execution_tree(executions, show_all_logs)
end

-- Show task list with improved formatting
function Display.show_task_list(registry: Types.TaskRegistry)
    Renderer.show_task_list(registry)
end

-- Show execution summary
function Display.show_execution_summary(executions: {Types.TaskExecution})
    Renderer.show_execution_summary(executions)
end



return Display
