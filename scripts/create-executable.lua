#!/usr/bin/env lua
-- Post-build script to create the main LuaTask executable
-- This script is called by Cyan after building the Teal sources

local function create_executable()
  local build_dir = "build"
  local executable_path = build_dir .. "/luatask"

  -- Get absolute path to build directory for package.path
  local pwd = os.getenv("PWD") or "."
  local abs_build_dir = pwd .. "/" .. build_dir

  -- Create the executable script content
  local executable_content = [[#!/usr/bin/env lua
-- LuaTask - Lua-based Task Runner
-- Generated executable script

-- Set up module path to find compiled Lua files
local script_path = debug.getinfo(1, "S").source:match("@(.*)")
if script_path then
    local script_dir = script_path:match("(.*/)")
    if script_dir then
        package.path = script_dir .. "?.lua;" .. package.path
    end
end

-- Load and run the main module
local Main = require("main")
if Main and Main.main then
    Main.main(arg)
else
    print("Error: Could not load main module")
    os.exit(1)
end
]]

  -- Write the executable file
  local file = io.open(executable_path, "w")
  if not file then
    print("Error: Could not create executable at " .. executable_path)
    os.exit(1)
  end

  file:write(executable_content)
  file:close()

  -- Make it executable
  local chmod_cmd = "chmod +x " .. executable_path
  local success = os.execute(chmod_cmd)

  if success == 0 or success == true then
    print("Created executable: " .. executable_path)
  else
    print("Warning: Could not make " .. executable_path .. " executable")
    print("Run: chmod +x " .. executable_path)
  end
end

-- Run the script
create_executable()
