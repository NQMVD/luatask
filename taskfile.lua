-- Example taskfile.lua demonstrating all LuaTask features
-- This file shows how to define tasks with dependencies, arguments, validation, and logging

local tasks = {}
local f = string.format

-- Build group tasks
tasks.clean = {
  description = "Clean build artifacts",
  group = "build",
  run = function()
    log.info("Cleaning build directory...")
    os.execute("rip build")
    log.info("Build artifacts cleaned")
    return "SUCCESS"
  end
}

tasks.build = {
  description = "Build by generating teal files",
  group = "build",
  dependencies = { "clean" },
  run = function()
    log.info("Compiling Teal sources...")
    os.execute("cyan build")
    log.info("Teal sources compiled successfully")
    return "SUCCESS"
  end
}

tasks.bundle = {
  description = "Bundle Lua files into a single file",
  group = "build",
  dependencies = { "build", "format" },
  run = function()
    log.info("Bundling Lua files into a single file...")
    os.execute("darklua process build/main.lua build/luatask.lua")
    log.info("Lua files bundled successfully")
    return "SUCCESS"
  end
}

tasks.minify = {
  description = "Minify bundled Lua file",
  group = "build",
  run = function()
    log.info("Minifying bundled Lua file...")
    os.execute("darklua minify build/luatask.lua build/luatask-minified.lua")
    log.info("Lua file minified successfully")
    return "SUCCESS"
  end
}

tasks.create = {
  description = "Create lua executable",
  group = "build",
  dependencies = { "bundle", "minify" },
  run = function()
    log.info("Creating Lua executable...")

    local final_file = "build/luatask-minified.lua"
    local exe_name = "lust"

    local function read_file(filename)
      local file = io.open(filename, "r")
      if not file then
        error("Could not open file: " .. filename)
      end
      local content = file:read("*all")
      file:close()
      return content
    end

    local function write_file(filename, content)
      local file = io.open(filename, "w")
      if not file then
        error("Could not create file: " .. filename)
      end
      file:write(content)
      file:close()
    end

    local function create_executable()
      -- Read the minified bundled Lua code
      local lua_code = read_file(final_file)

      -- Create executable script with shebang
      local executable_content = [[
#!/usr/bin/env lua
-- LuaTask Standalone Executable
-- Generated from Teal sources via darklua processing and minification

]] .. lua_code .. [[

-- Entry point - call main with command line arguments
if main then
    main(arg or {})
else
    print("Error: main function not available")
    os.exit(1)
end
    ]]

      -- Write executable file
      write_file("build/luatask", executable_content)

      -- Make executable (Unix/Linux/macOS)
      os.execute("chmod +x build/luatask")
    end

    -- Create the executable
    create_executable()

    -- move up the executable to the current directory
    os.execute("mv build/luatask ./" .. exe_name)

    log.info("Lua executable created successfully")
    return "SUCCESS"
  end
}

tasks.format = {
  description = "Format generated Lua files",
  group = "build",
  run = function()
    log.info("Formatting Lua sources...")
    os.execute("stylua build/*.lua")
    log.info("Lua sources formatted successfully")
    return "SUCCESS"
  end
}

-- Utility tasks (ungrouped)
tasks.version = {
  description = "Show version information",
  run = function()
    log.info("MyApp version 1.0.0")
    log.info("Built with LuaTask")
    return "SUCCESS", "1.0.0", "2024-01-15"
  end
}

tasks.benchmark = {
  description = "Run performance benchmarks [iterations=1000]",
  arguments = {
    iterations = { required = false, default = "1000", type = "number" }
  },
  dependencies = { { "build", "x86_64", "release" } },
  run = function(iterations)
    log.info("Running benchmarks with " .. iterations .. " iterations...")
    log.debug("Warming up...")
    log.debug("Running benchmark suite...")

    local avg_time = 0.045 -- milliseconds
    log.info("Benchmark completed - average: " .. avg_time .. "ms")
    return "SUCCESS", avg_time, iterations
  end
}

tasks.lint = {
  description = "Run code linter",
  run = function()
    log.info("Running code linter...")
    log.debug("Checking style guidelines...")
    log.warn("Found 3 style warnings")
    log.info("Linting completed")
    return "SUCCESS", 3 -- warning count
  end
}

-- Task that demonstrates failure
tasks.flaky = {
  description = "A task that sometimes fails (for testing)",
  run = function()
    log.info("Running flaky task...")

    -- Randomly fail sometimes
    log.error("Task failed randomly!")
    return "FAIL"
  end
}

-- Task with complex validation
tasks.configure = {
  description = "Configure application [env] [debug=false] [workers=4]",
  arguments = {
    env = { required = true, type = "string" },
    debug = { required = false, default = "false", type = "boolean" },
    workers = { required = false, default = 4, type = "number" }
  },
  run = function(env, debug, workers)
    log.info("Configuring for environment: " .. env)
    log.info("Debug mode: " .. tostring(debug))
    log.info("Worker processes: " .. workers)

    if debug then
      log.warn("Debug mode enabled - performance will be reduced")
    end

    if workers > 8 then
      log.warn("High worker count may cause resource contention")
    end

    log.info("Configuration completed")
    return "SUCCESS", env, debug, workers
  end
}

return tasks
