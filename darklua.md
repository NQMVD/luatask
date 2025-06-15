# Darklua Bundling with Require Mode: A Comprehensive Guide

Darklua is a powerful command-line tool that transforms Lua code and provides sophisticated bundling capabilities for merging multiple modules into a single file[1]. The bundling functionality uses require mode to interpret and inline require calls, which can indeed be complex to configure properly, especially when dealing with path resolution[2].

## Overview of Darklua Bundling

Darklua's bundling feature works by starting from an entry point file and recursively following all require calls to merge them into a single output file[2]. The tool uses a require mode system to interpret how modules should be resolved and inlined[3]. When bundling is enabled, darklua will find all require calls made with strings (single or double quotes) and resolve them according to the configured path resolution rules[4].

**Important Warning**: Each module should not have any side effects at require-time, as the order of those side effects may not be preserved in the bundled code[2].

## Configuration Setup

### Basic Bundle Configuration

To enable bundling, you need to create a configuration file (`.darklua.json` or `.darklua.json5`) with a `bundle` section[3]. The minimal configuration for path-based bundling looks like this:

```json
{
  "bundle": {
    "require_mode": "path"
  }
}
```

### Complete Configuration Structure

For more control over the bundling process, you can use the full configuration format[3]:

```json
{
  "generator": "retain_lines",
  "bundle": {
    "modules_identifier": "__DARKLUA_BUNDLE_MODULES",
    "excludes": [],
    "require_mode": {
      "name": "path",
      "module_folder_name": "init",
      "sources": {
        "pkg": "./Packages"
      },
      "use_luau_configuration": true
    }
  },
  "rules": [
    "remove_comments",
    "remove_spaces"
  ]
}
```

## Path Resolution System

### How Path Resolution Works

The path resolution system in darklua follows a specific hierarchy for finding modules[4]:

1. **Path Head Resolution**: Determines where to start looking for the resource
   - If the path starts with `.` or `..`: considered relative to the file making the require call
   - If the path starts with `/`: treated as an absolute path
   - Otherwise: the first component is used to find a matching source

2. **Path Tail Resolution**: Determines the exact file to load
   - If the path has an extension: the resource is expected exactly as specified
   - If no extension: darklua tries multiple variations in order

### File Resolution Order

When resolving a path like `./example`, darklua will attempt to find the first available file in this order[4]:

1. `./example`
2. `./example.luau`
3. `./example.lua`
4. `./example/init`
5. `./example/init.luau`
6. `./example/init.lua`

## Common Path Configuration Issues and Solutions

### Module Folder Names

The default module folder name is `init`, but this can be customized[4]. For example, to use JavaScript-style `index` files:

```json
{
  "bundle": {
    "require_mode": {
      "name": "path",
      "module_folder_name": "index"
    }
  }
}
```

### Source Mapping

Source mapping allows you to create aliases for common paths[4]. This is particularly useful for package management systems:

```json
{
  "bundle": {
    "require_mode": {
      "name": "path",
      "sources": {
        "@pkg": "./Packages",
        "images": "./assets/image-links.json"
      }
    }
  }
}
```

With this configuration, you can use require calls like:
- `require("@pkg/Promise")`
- `require("images")`

### Luau Configuration Integration

Darklua can automatically read `.luaurc` files to load source aliases[4]. This feature is enabled by default but can be disabled:

```json
{
  "bundle": {
    "require_mode": {
      "name": "path",
      "use_luau_configuration": false
    }
  }
}
```

## Running the Bundle Process

### Basic Command

To bundle your code, use the `process` command with your entry point and output file[2]:

```bash
darklua process entry-point.lua bundled.lua
```

### With Custom Configuration

If you need to specify a custom configuration file:

```bash
darklua process --config custom-config.json entry-point.lua bundled.lua
```

## Real-World Configuration Examples

### Example 1: Simple Project Bundle

A minimal configuration for a straightforward project[5]:

```json
{
  "generator": "readable",
  "bundle": {
    "require_mode": "path"
  },
  "rules": [
    "remove_types"
  ]
}
```

### Example 2: Complex Project with Package Management

A more comprehensive setup for projects using package managers[6]:

```json
{
  "bundle": {
    "require_mode": {
      "name": "path",
      "sources": {
        "@pkg": "node_modules/.luau-aliases"
      }
    }
  },
  "generator": "dense",
  "process": [
    {
      "rule": "inject_global_value",
      "identifier": "__DEV__",
      "value": false
    },
    "remove_types",
    "remove_comments",
    "remove_spaces",
    "compute_expression",
    "remove_unused_if_branch"
  ]
}
```

## Troubleshooting Common Issues

### Path Resolution Problems

The most common issues with darklua bundling stem from incorrect path configuration[4]. Here are key troubleshooting steps:

1. **Verify relative paths**: Ensure your require calls use proper relative path syntax (`./ or ../`)
2. **Check source mappings**: Verify that your `sources` configuration correctly maps prefixes to actual directories
3. **Module folder names**: Confirm that your `module_folder_name` matches your project structure
4. **File extensions**: Remember that darklua will try multiple extensions if none is specified

### Exclusion Patterns

To prevent certain modules from being bundled, use exclusion patterns[2]:

```json
{
  "bundle": {
    "require_mode": "path",
    "excludes": ["@lune/**", "node_modules/**"]
  }
}
```

### Bundle Identifier Conflicts

If you encounter conflicts with the default bundle identifier, you can customize it[2]:

```json
{
  "bundle": {
    "require_mode": "path",
    "modules_identifier": "MY_CUSTOM_BUNDLE_MODULES"
  }
}
```

## Advanced Features

### Code Generation Options

Darklua offers different generators for output formatting[7]:

- `retain_lines`: Preserves original line numbers (default)
- `dense`: Minimizes whitespace for smaller files
- `readable`: Generates human-readable output

### Rule Integration

You can combine bundling with transformation rules for optimized output[3]. Common rules include:

- `remove_comments`: Strips comments from bundled code
- `remove_spaces`: Reduces whitespace
- `compute_expression`: Evaluates constant expressions
- `inject_global_value`: Replaces global variables with constants

The bundling system in darklua is powerful but requires careful configuration of path resolution rules[4]. By understanding the path resolution hierarchy, properly configuring source mappings, and using appropriate exclusion patterns, you can successfully bundle complex Lua projects into single files while maintaining code functionality[2].

[1] https://darklua.com
[2] https://darklua.com/docs/bundle/
[3] https://darklua.com/docs/config/
[4] https://darklua.com/docs/path-require-mode/
[5] https://github.com/mokiros/luau_term/blob/main/darklua-bundle.json
[6] https://github.com/Neura-Studios/flash-list-lua/blob/main/.darklua-bundle.json
[7] https://darklua.com/docs/generators/
[8] https://github.com/seaofvoices/darklua
[9] https://darklua.com/docs/installation/
[10] https://github.com/seaofvoices/darklua/blob/main/README.md
[11] https://docs.rs/crate/darklua/0.1.0
[12] https://darklua.com/docs/roblox-require-mode/
[13] https://devforum.community/t/lua-processing-with-darklua/257
[14] https://formulae.brew.sh/formula/darklua
[15] https://docs.darktable.org/lua/stable/lua.scripts.manual/installation/
[16] https://github.com/Footagesus/WindUI/blob/main/darklua.config.json
[17] https://roblox.github.io/roact-alignment/configuration/
[18] https://www.ffxiah.com/forum/topic/57237/drk-lua-assistance/
[19] https://darklua.com/docs/
[20] https://github.com/seaofvoices/darklua/issues/150
[21] https://github.com/seaofvoices/luau-package-standard/blob/main/README.md
[22] https://docs.rs/crate/luabundle/latest
[23] https://stackoverflow.com/questions/38640069/how-do-i-make-require-take-a-direct-path-to-a-file
[24] https://www.bundler.cn/man/bundle-config.1.html
[25] https://bundler.io/v1.12/man/bundle-config.1.html
[26] https://luapower.com/bundle
[27] https://github.com/latte-soft/wax
[28] http://lua-users.org/wiki/InlineCee
[29] https://darklua.com/docs/rules/convert_require/
[30] http://lua-users.org/lists/lua-l/2022-12/msg00016.html
[31] https://stackoverflow.com/questions/62999715/when-i-make-darknet-with-cuda-1-usr-bin-ld-cannot-find-lcudaoccured-how
[32] https://github.com/0x5eal/terracotta
[33] https://github.com/darktable-org/lua-scripts
[34] https://stackoverflow.com/questions/27645755/lua-relative-path-required
[35] https://www.youtube.com/watch?v=hGX1kYw8i6A
[36] https://discuss.pixls.us/t/initial-workflow-lua-script/36964
[37] https://en.wikibooks.org/wiki/Lua_Programming/mistake
[38] https://docs.rs/darklua-demo
[39] https://github.com/seaofvoices/darklua/blob/main/CHANGELOG.md
[40] https://github.com/seaofvoices/darklua/issues
[41] https://www.reddit.com/r/neovim/comments/u6alfc/show_me_your_well_organised_lua_config/
[42] https://crates.io/crates/darklua/0.6.0
