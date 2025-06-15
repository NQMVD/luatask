


local Colors = {}






































local CATPPUCCIN_MOCHA = {
   rosewater = "\27[38;2;245;224;220m",
   flamingo = "\27[38;2;242;205;205m",
   pink = "\27[38;2;245;194;231m",
   mauve = "\27[38;2;203;166;247m",
   red = "\27[38;2;243;139;168m",
   maroon = "\27[38;2;235;160;172m",
   peach = "\27[38;2;250;179;135m",
   yellow = "\27[38;2;249;226;175m",
   green = "\27[38;2;166;227;161m",
   teal = "\27[38;2;148;226;213m",
   sky = "\27[38;2;137;220;235m",
   sapphire = "\27[38;2;116;199;236m",
   blue = "\27[38;2;137;180;250m",
   lavender = "\27[38;2;180;190;254m",
   text = "\27[38;2;205;214;244m",
   subtext1 = "\27[38;2;186;194;222m",
   subtext0 = "\27[38;2;166;173;200m",
   overlay2 = "\27[38;2;147;153;178m",
   overlay1 = "\27[38;2;127;132;156m",
   overlay0 = "\27[38;2;108;112;134m",
   surface2 = "\27[38;2;88;91;112m",
   surface1 = "\27[38;2;69;71;90m",
   surface0 = "\27[38;2;49;50;68m",
   base = "\27[38;2;30;30;46m",
   mantle = "\27[38;2;24;24;37m",
   crust = "\27[38;2;17;17;27m",


   reset = "\27[0m",
   bold = "\27[1m",
   dim = "\27[2m",
}


local colors = {
   rosewater = CATPPUCCIN_MOCHA.rosewater,
   flamingo = CATPPUCCIN_MOCHA.flamingo,
   pink = CATPPUCCIN_MOCHA.pink,
   mauve = CATPPUCCIN_MOCHA.mauve,
   red = CATPPUCCIN_MOCHA.red,
   maroon = CATPPUCCIN_MOCHA.maroon,
   peach = CATPPUCCIN_MOCHA.peach,
   yellow = CATPPUCCIN_MOCHA.yellow,
   green = CATPPUCCIN_MOCHA.green,
   teal = CATPPUCCIN_MOCHA.teal,
   sky = CATPPUCCIN_MOCHA.sky,
   sapphire = CATPPUCCIN_MOCHA.sapphire,
   blue = CATPPUCCIN_MOCHA.blue,
   lavender = CATPPUCCIN_MOCHA.lavender,
   text = CATPPUCCIN_MOCHA.text,
   subtext1 = CATPPUCCIN_MOCHA.subtext1,
   subtext0 = CATPPUCCIN_MOCHA.subtext0,
   overlay2 = CATPPUCCIN_MOCHA.overlay2,
   overlay1 = CATPPUCCIN_MOCHA.overlay1,
   overlay0 = CATPPUCCIN_MOCHA.overlay0,
   surface2 = CATPPUCCIN_MOCHA.surface2,
   surface1 = CATPPUCCIN_MOCHA.surface1,
   surface0 = CATPPUCCIN_MOCHA.surface0,
   base = CATPPUCCIN_MOCHA.base,
   mantle = CATPPUCCIN_MOCHA.mantle,
   crust = CATPPUCCIN_MOCHA.crust,
   reset = CATPPUCCIN_MOCHA.reset,
   bold = CATPPUCCIN_MOCHA.bold,
   dim = CATPPUCCIN_MOCHA.dim,
   enabled = true,
}


local function set_enabled(enabled)
   colors.enabled = enabled

   if not enabled then

      colors.rosewater = ""
      colors.flamingo = ""
      colors.pink = ""
      colors.mauve = ""
      colors.red = ""
      colors.maroon = ""
      colors.peach = ""
      colors.yellow = ""
      colors.green = ""
      colors.teal = ""
      colors.sky = ""
      colors.sapphire = ""
      colors.blue = ""
      colors.lavender = ""
      colors.text = ""
      colors.subtext1 = ""
      colors.subtext0 = ""
      colors.overlay2 = ""
      colors.overlay1 = ""
      colors.overlay0 = ""
      colors.surface2 = ""
      colors.surface1 = ""
      colors.surface0 = ""
      colors.base = ""
      colors.mantle = ""
      colors.crust = ""
      colors.reset = ""
      colors.bold = ""
      colors.dim = ""
   else

      colors.rosewater = CATPPUCCIN_MOCHA.rosewater
      colors.flamingo = CATPPUCCIN_MOCHA.flamingo
      colors.pink = CATPPUCCIN_MOCHA.pink
      colors.mauve = CATPPUCCIN_MOCHA.mauve
      colors.red = CATPPUCCIN_MOCHA.red
      colors.maroon = CATPPUCCIN_MOCHA.maroon
      colors.peach = CATPPUCCIN_MOCHA.peach
      colors.yellow = CATPPUCCIN_MOCHA.yellow
      colors.green = CATPPUCCIN_MOCHA.green
      colors.teal = CATPPUCCIN_MOCHA.teal
      colors.sky = CATPPUCCIN_MOCHA.sky
      colors.sapphire = CATPPUCCIN_MOCHA.sapphire
      colors.blue = CATPPUCCIN_MOCHA.blue
      colors.lavender = CATPPUCCIN_MOCHA.lavender
      colors.text = CATPPUCCIN_MOCHA.text
      colors.subtext1 = CATPPUCCIN_MOCHA.subtext1
      colors.subtext0 = CATPPUCCIN_MOCHA.subtext0
      colors.overlay2 = CATPPUCCIN_MOCHA.overlay2
      colors.overlay1 = CATPPUCCIN_MOCHA.overlay1
      colors.overlay0 = CATPPUCCIN_MOCHA.overlay0
      colors.surface2 = CATPPUCCIN_MOCHA.surface2
      colors.surface1 = CATPPUCCIN_MOCHA.surface1
      colors.surface0 = CATPPUCCIN_MOCHA.surface0
      colors.base = CATPPUCCIN_MOCHA.base
      colors.mantle = CATPPUCCIN_MOCHA.mantle
      colors.crust = CATPPUCCIN_MOCHA.crust
      colors.reset = CATPPUCCIN_MOCHA.reset
      colors.bold = CATPPUCCIN_MOCHA.bold
      colors.dim = CATPPUCCIN_MOCHA.dim
   end
end


local function get_colors()
   return colors
end


local function task_name(text)
   return colors.lavender .. colors.bold .. text .. colors.reset
end

local function success(text)
   return colors.green .. colors.bold .. text .. colors.reset
end

local function error_text(text)
   return colors.red .. colors.bold .. text .. colors.reset
end

local function warning(text)
   return colors.yellow .. colors.bold .. text .. colors.reset
end

local function group_header(text)
   return colors.mauve .. colors.bold .. text .. colors.reset
end

local function dependency(text)
   return colors.subtext0 .. colors.dim .. text .. colors.reset
end

local function timing(text)
   return colors.overlay1 .. text .. colors.reset
end

local function tree_symbol(text)
   return colors.surface2 .. text .. colors.reset
end

local function log_info(text)
   return colors.blue .. text .. colors.reset
end

local function log_warn(text)
   return colors.yellow .. colors.bold .. text .. colors.reset
end

local function log_error(text)
   return colors.red .. colors.bold .. text .. colors.reset
end

local function log_debug(text)
   return colors.overlay1 .. colors.dim .. text .. colors.reset
end


local function log_color_for_level(level)
   if level == "INFO" then
      return log_info
   elseif level == "WARN" then
      return log_warn
   elseif level == "ERROR" then
      return log_error
   elseif level == "DEBUG" then
      return log_debug
   else
      return function(text) return text end
   end
end


local function success_symbol()
   return success("✓")
end

local function fail_symbol()
   return error_text("✗")
end

local function error_symbol()
   return warning("⚠")
end

local function running_symbol()
   return colors.blue .. "⟳" .. colors.reset
end

local function pending_symbol()
   return colors.overlay1 .. "○" .. colors.reset
end

return {
   Colors = Colors,
   set_enabled = set_enabled,
   get_colors = get_colors,
   task_name = task_name,
   success = success,
   error_text = error_text,
   warning = warning,
   group_header = group_header,
   dependency = dependency,
   timing = timing,
   tree_symbol = tree_symbol,
   log_info = log_info,
   log_warn = log_warn,
   log_error = log_error,
   log_debug = log_debug,
   log_color_for_level = log_color_for_level,
   success_symbol = success_symbol,
   fail_symbol = fail_symbol,
   error_symbol = error_symbol,
   running_symbol = running_symbol,
   pending_symbol = pending_symbol,
}
