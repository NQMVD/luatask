


local Types = require('types')
local Parser = require('parser')
local Runner = require('runner')
local LoggerModule = require('logger')




local Main = {}



local DEFAULT_CONFIG = {
   task_file = "taskfile.lua",
   log_level = "INFO",
   parallel = false,
   max_jobs = 1,
   show_all_logs = false,
   no_color = false,
   dry_run = false,
   list_tasks = false,
   show_tree = false,
}


local function print_usage()
   print("LuaTask - Lua-based Task Runner")
   print("")
   print("Usage:")
   print("  luatask [options] [task...]")
   print("")
   print("Options:")
   print("  --list              List available tasks")
   print("  --file FILE         Use custom task file (default: taskfile.lua)")
   print("  --log-level LEVEL   Set log level (debug/info/warn/error)")
   print("  --parallel          Enable cooperative parallelism")
   print("  --jobs N            Limit concurrent tasks (requires --parallel)")
   print("  --all-logs          Show all logs vs just last message")
   print("  --tree              Show dependency tree")
   print("  --dry-run           Show execution plan without running")
   print("  --no-color          Disable colored output")
   print("  --color             Force enable colors")
   print("  --help, -h          Show this help")
   print("")
   print("Examples:")
   print("  luatask                     # List available tasks")
   print("  luatask build               # Run build task")
   print("  luatask build x86_64 debug  # Run build with arguments")
   print("  luatask clean build test    # Run multiple tasks")
   print("  luatask --parallel clean build test  # Run in parallel when possible")
end


local function parse_args(args)
   local config = {
      task_file = DEFAULT_CONFIG.task_file,
      log_level = DEFAULT_CONFIG.log_level,
      parallel = DEFAULT_CONFIG.parallel,
      max_jobs = DEFAULT_CONFIG.max_jobs,
      show_all_logs = DEFAULT_CONFIG.show_all_logs,
      no_color = DEFAULT_CONFIG.no_color,
      dry_run = DEFAULT_CONFIG.dry_run,
      list_tasks = DEFAULT_CONFIG.list_tasks,
      show_tree = DEFAULT_CONFIG.show_tree,
   }

   local tasks = {}
   local i = 1

   while i <= #args do
      local current_arg = args[i]

      if current_arg == "--help" or current_arg == "-h" then
         print_usage()
         os.exit(0)
      elseif current_arg == "--list" then
         config.list_tasks = true
      elseif current_arg == "--file" then
         i = i + 1
         if i > #args then
            error("--file requires a filename")
         end
         config.task_file = args[i]
      elseif current_arg == "--log-level" then
         i = i + 1
         if i > #args then
            error("--log-level requires a level (debug/info/warn/error)")
         end
         local level = args[i]:upper()
         if level ~= "DEBUG" and level ~= "INFO" and level ~= "WARN" and level ~= "ERROR" then
            error("Invalid log level: " .. args[i])
         end
         config.log_level = level
      elseif current_arg == "--parallel" then
         config.parallel = true
      elseif current_arg == "--jobs" then
         i = i + 1
         if i > #args then
            error("--jobs requires a number")
         end
         local jobs = tonumber(args[i])
         if not jobs or jobs < 1 then
            error("--jobs must be a positive number")
         end
         config.max_jobs = jobs
      elseif current_arg == "--all-logs" then
         config.show_all_logs = true
      elseif current_arg == "--tree" then
         config.show_tree = true
      elseif current_arg == "--dry-run" then
         config.dry_run = true
      elseif current_arg == "--no-color" then
         config.no_color = true
      elseif current_arg == "--color" then
         config.no_color = false
      elseif current_arg:sub(1, 2) == "--" then
         error("Unknown option: " .. current_arg)
      else

         table.insert(tasks, current_arg)
      end

      i = i + 1
   end

   return {
      tasks = tasks,
      config = config,
   }
end


local function list_tasks(registry)
   print("Available tasks:")
   print("")


   local groups = {}
   local ungrouped = {}

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


   table.sort(ungrouped)
   for _, task_list in pairs(groups) do
      table.sort(task_list)
   end


   for group, task_list in pairs(groups) do
      print(group .. ":")
      for _, name in ipairs(task_list) do
         local task = registry.tasks[name]
         local deps = ""
         if #task.dependencies > 0 then
            local dep_names = {}
            for _, dep in ipairs(task.dependencies) do
               if #dep.args > 0 then
                  table.insert(dep_names, dep.name .. "(" .. table.concat(dep.args, ", ") .. ")")
               else
                  table.insert(dep_names, dep.name)
               end
            end
            deps = " [depends: " .. table.concat(dep_names, ", ") .. "]"
         end
         print("  " .. name .. deps .. " - " .. task.description)
      end
      print("")
   end


   if #ungrouped > 0 then
      if next(groups) ~= nil then
         print("Other tasks:")
      end
      for _, name in ipairs(ungrouped) do
         local task = registry.tasks[name]
         local deps = ""
         if #task.dependencies > 0 then
            local dep_names = {}
            for _, dep in ipairs(task.dependencies) do
               if #dep.args > 0 then
                  table.insert(dep_names, dep.name .. "(" .. table.concat(dep.args, ", ") .. ")")
               else
                  table.insert(dep_names, dep.name)
               end
            end
            deps = " [depends: " .. table.concat(dep_names, ", ") .. "]"
         end
         print("  " .. name .. deps .. " - " .. task.description)
      end
   end
end


local function print_results(executions)
   print("")
   print("Execution summary:")

   local total_time = 0
   local any_failed = false

   for _, exec in ipairs(executions) do
      local duration = exec.end_time - exec.start_time
      total_time = total_time + duration

      local status_symbol = "?"
      if exec.status == "success" then
         status_symbol = "✓"
      elseif exec.status == "fail" then
         status_symbol = "✗"
         any_failed = true
      elseif exec.status == "error" then
         status_symbol = "⚠"
         any_failed = true
      end

      local args_str = ""
      if #exec.args > 0 then
         args_str = " " .. table.concat(exec.args, " ")
      end

      print("  " .. status_symbol .. " " .. exec.name .. args_str .. " (" .. duration .. "s)")


      if exec.task_result.error ~= "" then
         print("    Error: " .. exec.task_result.error)
      end


      if #exec.task_result.values > 0 then
         local values_str = "Result: " .. exec.task_result.result
         for _, value in ipairs(exec.task_result.values) do
            values_str = values_str .. ", " .. tostring(value)
         end
         print("    " .. values_str)
      end
   end

   print("")
   print("Total time: " .. total_time .. "s")

   if any_failed then
      print("Some tasks failed!")
      os.exit(1)
   else
      print("All tasks completed successfully!")
   end
end


function Main.main(args)
   local cli_args = parse_args(args)


   LoggerModule.set_global_level(cli_args.config.log_level)
   log = LoggerModule.get_log_object()


   local success, registry = pcall(Parser.parse_file, cli_args.config.task_file)
   if not success then
      print("Error loading task file: " .. tostring(registry))
      os.exit(1)
   end


   if cli_args.config.list_tasks or #cli_args.tasks == 0 then
      list_tasks(registry)
      return
   end


   print("Running tasks from: " .. cli_args.config.task_file)
   local executions = Runner.run_tasks(registry, cli_args.tasks)

   print_results(executions)
end

return Main
