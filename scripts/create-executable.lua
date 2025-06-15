#!/usr/bin/env lua

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
  print("Creating standalone executable...")

  -- Read the minified bundled Lua code
  local lua_code = read_file(final_file)

  -- Create executable script with shebang
  local executable_content = [[#!/usr/bin/env lua
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

  print("Executable created: build/luatask")
  print("File size: " .. string.format("%.2f KB",
    (io.open("build/luatask", "r"):seek("end") or 0) / 1024))
end

-- Create the executable
create_executable()

-- move up the executable to the current directory
os.execute("mv build/luatask ./" .. exe_name)

print("Done!")
