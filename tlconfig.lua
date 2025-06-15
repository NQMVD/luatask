-- Cyan build configuration for LuaTask
return {
  -- Project structure
  source_dir = "src",
  build_dir = "build",

  -- Target Lua version
  gen_target = "5.1",
  gen_compat = "off",

  -- File patterns
  include = {
    "**/*.tl"
  },

  exclude = {
    "src/**/*.lua", -- Don't process existing Lua files
    "build/**/*"    -- Don't process build artifacts
  },
}
