-- Logging system for LuaTask
-- Provides leveled logging with colored output and per-task message storage

local Types = require('types')

-- Log levels as enum
local enum LogLevel
    "DEBUG"
    "INFO"
    "WARN"
    "ERROR"
end

local LOG_LEVEL_VALUES: {LogLevel: number} = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}

local record Logger
    current_task: string
    min_level: number
    messages: {string: {Types.LogMessage}}
    show_colors: boolean
end

-- Add a log message
local function add_message(self: Logger, level: string, message: string)
    local level_key = level as LogLevel
    local level_num = LOG_LEVEL_VALUES[level_key] or 0
    if level_num < self.min_level then
        return
    end

    local log_message: Types.LogMessage = {
        level = level,
        message = message,
        timestamp = os.time()
    }

    if self.current_task ~= "" then
        if not self.messages[self.current_task] then
            self.messages[self.current_task] = {}
        end
        table.insert(self.messages[self.current_task], log_message)
    end

    -- Also print immediately for now
    local prefix = "[" .. level .. "]"
    if self.current_task ~= "" then
        prefix = "[" .. self.current_task .. "] " .. prefix
    end

    print(prefix .. " " .. message)
end

-- Set the current task context for logging
local function set_current_task(self: Logger, task_name: string)
    self.current_task = task_name
    if not self.messages[task_name] then
        self.messages[task_name] = {}
    end
end

-- Log functions
local function debug_log(self: Logger, message: string)
    add_message(self, "DEBUG", message)
end

local function info_log(self: Logger, message: string)
    add_message(self, "INFO", message)
end

local function warn_log(self: Logger, message: string)
    add_message(self, "WARN", message)
end

local function error_log(self: Logger, message: string)
    add_message(self, "ERROR", message)
end

-- Get messages for a specific task
local function get_task_messages(self: Logger, task_name: string): {Types.LogMessage}
    return self.messages[task_name] or {}
end

-- Clear messages for a task
local function clear_task_messages(self: Logger, task_name: string)
    self.messages[task_name] = {}
end

-- Create a new logger instance
local function new_logger(min_level: string, show_colors: boolean): Logger
    local level_key = min_level:upper() as LogLevel
    local level_num = LOG_LEVEL_VALUES[level_key] or LOG_LEVEL_VALUES.INFO

    return {
        current_task = "",
        min_level = level_num,
        messages = {},
        show_colors = show_colors
    }
end

-- Global logger instance
local global_logger: Logger = new_logger("INFO", true)

-- Global log object that will be available in task files
local log = {
    debug = function(message: string)
        debug_log(global_logger, message)
    end,
    info = function(message: string)
        info_log(global_logger, message)
    end,
    warn = function(message: string)
        warn_log(global_logger, message)
    end,
    error = function(message: string)
        error_log(global_logger, message)
    end
}

-- Set the current task for the global logger
local function set_global_task(task_name: string)
    set_current_task(global_logger, task_name)
end

-- Set the log level for the global logger
local function set_global_level(level: string)
    local level_key = level:upper() as LogLevel
    global_logger.min_level = LOG_LEVEL_VALUES[level_key] or LOG_LEVEL_VALUES.INFO
end

-- Get the global logger instance
local function get_global_logger(): Logger
    return global_logger
end

-- Get the log object for injection into task environment
local function get_log_object(): {string: function(string)}
    return log
end

return {
    Logger = Logger,
    new_logger = new_logger,
    set_global_task = set_global_task,
    set_global_level = set_global_level,
    get_global_logger = get_global_logger,
    get_log_object = get_log_object
}
