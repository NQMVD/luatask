


local Types = require('types')









local LOG_LEVEL_VALUES = {
   DEBUG = 0,
   INFO = 1,
   WARN = 2,
   ERROR = 3,
}

local Logger = {}







local function add_message(self, level, message)
   local level_key = level
   local level_num = LOG_LEVEL_VALUES[level_key] or 0
   if level_num < self.min_level then
      return
   end

   local log_message = {
      level = level,
      message = message,
      timestamp = os.time(),
   }

   if self.current_task ~= "" then
      if not self.messages[self.current_task] then
         self.messages[self.current_task] = {}
      end
      table.insert(self.messages[self.current_task], log_message)
   end


end


local function set_current_task(self, task_name)
   self.current_task = task_name
   if not self.messages[task_name] then
      self.messages[task_name] = {}
   end
end


local function debug_log(self, message)
   add_message(self, "DEBUG", message)
end

local function info_log(self, message)
   add_message(self, "INFO", message)
end

local function warn_log(self, message)
   add_message(self, "WARN", message)
end

local function error_log(self, message)
   add_message(self, "ERROR", message)
end




local function new_logger(min_level, show_colors)
   local level_key = min_level:upper()
   local level_num = LOG_LEVEL_VALUES[level_key] or LOG_LEVEL_VALUES.INFO

   return {
      current_task = "",
      min_level = level_num,
      messages = {},
      show_colors = show_colors,
   }
end


local global_logger = new_logger("INFO", true)


local log = {
   debug = function(message)
      debug_log(global_logger, message)
   end,
   info = function(message)
      info_log(global_logger, message)
   end,
   warn = function(message)
      warn_log(global_logger, message)
   end,
   error = function(message)
      error_log(global_logger, message)
   end,
}


local function set_global_task(task_name)
   set_current_task(global_logger, task_name)
end


local function set_global_level(level)
   local level_key = level:upper()
   global_logger.min_level = LOG_LEVEL_VALUES[level_key] or LOG_LEVEL_VALUES.INFO
end


local function get_global_logger()
   return global_logger
end


local function get_log_object()
   return log
end

return {
   Logger = Logger,
   new_logger = new_logger,
   set_global_task = set_global_task,
   set_global_level = set_global_level,
   get_global_logger = get_global_logger,
   get_log_object = get_log_object,
}
