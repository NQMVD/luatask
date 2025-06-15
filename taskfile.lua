-- Example taskfile.lua demonstrating all LuaTask features
-- This file shows how to define tasks with dependencies, arguments, validation, and logging

local tasks = {}

-- Build group tasks
tasks.clean = {
  description = "Clean build artifacts",
  group = "build",
  run = function()
    log.info("Cleaning build directory...")
    log.debug("Removing obj/, bin/, and dist/ directories")
    -- Simulate cleanup work
    log.info("Build artifacts cleaned")
    return SUCCESS
  end
}

tasks.deps = {
  description = "Check system dependencies",
  group = "build",
  run = function()
    log.info("Checking system dependencies...")
    log.debug("Checking for gcc, make, pkg-config...")
    -- Simulate dependency check
    log.warn("Some optional dependencies missing, continuing anyway")
    return SUCCESS, "gcc-11.2", "make-4.3"
  end
}

tasks.build = {
  description = "Build project [target] [mode='release']",
  group = "build",
  dependencies = { "clean", "deps" },
  arguments = {
    target = { required = true, type = "string" },
    mode = { required = false, default = "release", type = "string" }
  },
  run = function(target, mode)
    log.info("Building " .. target .. " in " .. mode .. " mode...")
    log.debug("Compiling source files...")
    log.debug("Linking executable...")

    if mode == "debug" then
      log.warn("Debug mode: optimizations disabled")
    end

    -- Simulate build time based on target
    local build_time = target == "x86_64" and 2.3 or 1.8
    local artifact_count = target == "arm64" and 15 or 12

    log.info("Build completed successfully")
    return SUCCESS, os.time(), artifact_count
  end
}

-- Testing group
tasks.test_unit = {
  description = "Run unit tests [pattern...]",
  group = "testing",
  dependencies = { { "build", "x86_64", "debug" } },
  run = function(...)
    local patterns = { ... }
    log.info("Running unit tests...")

    if #patterns > 0 then
      log.info("Filtering tests with patterns: " .. table.concat(patterns, ", "))
    end

    log.debug("Running test suite...")
    log.info("All unit tests passed")
    return SUCCESS, 42 -- number of tests
  end
}

tasks.test_integration = {
  description = "Run integration tests",
  group = "testing",
  dependencies = { { "build", "x86_64", "release" } },
  run = function()
    log.info("Running integration tests...")
    log.debug("Starting test database...")
    log.debug("Running integration suite...")
    log.info("Integration tests completed")
    return SUCCESS, 8 -- number of integration tests
  end
}

tasks.test = {
  description = "Run all tests",
  group = "testing",
  dependencies = { "test_unit", "test_integration" },
  run = function()
    log.info("All tests completed successfully")
    return SUCCESS
  end
}

-- Deploy group
tasks.package = {
  description = "Package application [format='tar']",
  group = "deploy",
  dependencies = { { "build", "x86_64", "release" }, "test" },
  arguments = {
    format = { required = false, default = "tar", type = "string" }
  },
  run = function(format)
    log.info("Packaging application in " .. format .. " format...")
    log.debug("Creating package structure...")
    log.debug("Compressing files...")

    local package_name = "myapp-1.0.0." .. format
    log.info("Package created: " .. package_name)
    return SUCCESS, package_name, 1024000 -- package size in bytes
  end
}

tasks.deploy_staging = {
  description = "Deploy to staging environment",
  group = "deploy",
  dependencies = { { "package", "tar" } },
  run = function()
    log.info("Deploying to staging...")
    log.debug("Uploading package to staging server...")
    log.debug("Running deployment scripts...")
    log.warn("Staging deployment uses test database")

    local deploy_id = "deploy-" .. os.time()
    log.info("Deployed to staging as " .. deploy_id)
    return SUCCESS, deploy_id
  end
}

tasks.deploy_production = {
  description = "Deploy to production environment",
  group = "deploy",
  dependencies = { "deploy_staging" },
  run = function()
    log.info("Deploying to production...")
    log.debug("Final safety checks...")
    log.debug("Rolling deployment to production servers...")
    log.info("Production deployment completed")
    return SUCCESS
  end
}

-- Utility tasks (ungrouped)
tasks.version = {
  description = "Show version information",
  run = function()
    log.info("MyApp version 1.0.0")
    log.info("Built with LuaTask")
    return SUCCESS, "1.0.0", "2024-01-15"
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
    return SUCCESS, avg_time, iterations
  end
}

tasks.lint = {
  description = "Run code linter",
  run = function()
    log.info("Running code linter...")
    log.debug("Checking style guidelines...")
    log.warn("Found 3 style warnings")
    log.info("Linting completed")
    return SUCCESS, 3 -- warning count
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
    return SUCCESS, env, debug, workers
  end
}

return tasks
