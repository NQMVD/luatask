#!/usr/bin/env lua

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
  local lua_code = read_file("dist/luatask-minified.lua")

  -- Create executable script with shebang
  local executable_content = [[#!/usr/bin/env lua
-- LuaTask Standalone Executable
-- Generated from Teal sources via darklua processing and minification

]] .. lua_code .. [[

-- Entry point - call main with command line arguments
if Main and Main.main then
    Main.main(arg or {})
else
    print("Error: Main module not found or main function not available")
    os.exit(1)
end
]]

  -- Write executable file
  write_file("dist/luatask", executable_content)

  -- Make executable (Unix/Linux/macOS)
  os.execute("chmod +x dist/luatask")

  print("Executable created: dist/luatask")
  print("File size: " .. string.format("%.2f KB",
    (io.open("dist/luatask", "r"):seek("end") or 0) / 1024))
end

-- Ensure dist directory exists
os.execute("mkdir -p dist")

-- Create the executable
create_executable()

print("Done! You can now test with: ./dist/luatask --help")
