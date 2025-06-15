


local Types = require('types')
local Result = require('result')
local LoggerModule = require('logger')





local function manual_unpack(t)
   if #t == 0 then return end
   if #t == 1 then return t[1] end
   if #t == 2 then return t[1], t[2] end
   if #t == 3 then return t[1], t[2], t[3] end
   if #t == 4 then return t[1], t[2], t[3], t[4] end
   if #t == 5 then return t[1], t[2], t[3], t[4], t[5] end

   return t[1], t[2], t[3], t[4], t[5]
end

local Runner = {}



local function create_execution(name, args, dependencies)
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
      },
      log_messages = {},
   }
end


local function resolve_dependencies(registry, task_name,
   task_args, resolved, path)

   for _, p in ipairs(path) do
      if p == task_name then
         error("Circular dependency detected: " .. table.concat(path, " -> ") .. " -> " .. task_name)
      end
   end


   local new_path = {}
   for _, p in ipairs(path) do
      table.insert(new_path, p)
   end
   table.insert(new_path, task_name)

   local executions = {}
   local task = registry.tasks[task_name]

   if not task then
      error("Task not found: " .. task_name)
   end


   for _, dep in ipairs(task.dependencies) do
      local dep_key = dep.name .. "(" .. table.concat(dep.args, ",") .. ")"


      if not resolved[dep_key] then
         resolved[dep_key] = true
         local dep_executions = resolve_dependencies(registry, dep.name, dep.args, resolved, new_path)


         for _, exec in ipairs(dep_executions) do
            table.insert(executions, exec)
         end
      end
   end


   local execution = create_execution(task_name, task_args, task.dependencies)
   table.insert(executions, execution)

   return executions
end


local function execute_task(registry, execution)
   local task = registry.tasks[execution.name]
   if not task then
      return {
         success = false,
         result = Result.FAIL,
         values = {},
         error = "Task not found: " .. execution.name,
      }
   end


   LoggerModule.set_global_task(execution.name)


   local logger = LoggerModule.get_global_logger()
   logger.messages[execution.name] = {}


   log = LoggerModule.get_log_object()


   local processed_args = {}

   if task.arguments then

      for i, task_arg in ipairs(execution.args) do

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

      for i, task_arg in ipairs(execution.args) do
         processed_args[i] = task_arg
      end
   end


   local call_results = { pcall(task.run, manual_unpack(processed_args)) }
   local success = call_results[1]
   local result = call_results[2]

   if not success then
      return {
         success = false,
         result = Result.FAIL,
         values = {},
         error = tostring(result) or "Unknown error",
      }
   end


   if not Result.is_valid(tostring(result)) then
      return {
         success = false,
         result = Result.FAIL,
         values = {},
         error = "Task returned invalid result: " .. tostring(result),
      }
   end


   local values = {}
   for i = 3, #call_results do
      values[i - 2] = call_results[i]
   end

   return {
      success = true,
      result = tostring(result),
      values = values,
      error = "",
   }
end


function Runner.parse_task_spec(spec)
   local parts = {}


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


function Runner.run_tasks(registry, task_specs)
   local all_executions = {}
   local resolved = {}


   for _, spec in ipairs(task_specs) do
      local task_name, args = Runner.parse_task_spec(spec)
      local executions = resolve_dependencies(registry, task_name, args, resolved, {})

      for _, exec in ipairs(executions) do
         table.insert(all_executions, exec)
      end
   end


   for _, execution in ipairs(all_executions) do
      execution.status = "running"
      execution.start_time = os.time()


      execution.task_result = execute_task(registry, execution)

      execution.end_time = os.time()


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


      if execution.status == "fail" or execution.status == "error" then
         break
      end
   end

   return all_executions
end


function Runner.get_stats(executions)
   local stats = {
      total = #executions,
      success = 0,
      fail = 0,
      error = 0,
      pending = 0,
      running = 0,
   }

   for _, exec in ipairs(executions) do
      local status = exec.status
      if stats[status] then
         stats[status] = stats[status] + 1
      end
   end

   return stats
end


function Runner.all_successful(executions)
   for _, exec in ipairs(executions) do
      if exec.status ~= "success" then
         return false
      end
   end
   return true
end

return Runner
