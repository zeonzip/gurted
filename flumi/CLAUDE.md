# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gurted is a **browser/wayfinder** for the **GURT protocol** built in Godot 4.4. It renders HTML-like content with CSS-like styling using Godot's UI system and supports a custom utility-class-based styling system similar to Tailwind CSS.

## Notes
- Do not prefix functions or variable names with _ (underscore), those are reserved for event functions.
- Do not try to "try" your additions via running Godot, leave that up to me.
- Read the codebase to implement the requested change in the most optimal, efficient, and with the least amount of code addition.

## Architecture

### Core Components

- **main.gd** - Main entry point that orchestrates HTML parsing and rendering
- **HTMLParser.gd** - Parses HTML content into a tree structure of HTMLElement objects
- **CSSParser.gd** - Parses utility-class-based CSS and applies styles to elements
- **StyleManager.gd** - Applies parsed styles to Godot UI nodes
- **TabContainer.gd** - Manages browser tabs with keyboard shortcuts (Ctrl+T, Ctrl+W, Ctrl+Tab)

### HTML Element System

HTML elements are mapped to Godot scene files in `Scenes/Tags/`:
- `p.tscn`, `div.tscn`, `span.tscn` for text content
- `input.tscn`, `button.tscn`, `select.tscn`, `textarea.tscn` for form elements  
- `ul.tscn`, `ol.tscn`, `li.tscn` for lists
- `img.tscn` for images with network loading support
- `br.tscn`, `separator.tscn` for layout elements

Each has a corresponding `.gd` script in `Scripts/Tags/` that handles initialization and behavior.

### Styling System

The project uses a Tailwind-like utility class system:
- **Font sizes**: `text-xs` (12px) through `text-6xl` (60px)
- **Colors**: `text-[#color]`, `bg-[#color]` for arbitrary colors; named colors like `text-red-500`
- **Typography**: `font-bold`, `font-italic`, `underline`, `font-mono`
- **Flexbox**: Full flexbox support with `flex`, `justify-center`, `items-center`, etc.
- **Sizing**: `w-[value]`, `h-[value]`, `max-w-[value]`, `min-h-[value]`
- **Spacing**: `p-4`, `px-4`, `py-2`, `gap-4`
- **Border radius**: `rounded`, `rounded-lg`, `rounded-full`, `rounded-[12px]`
- **Pseudo-classes**: `hover:bg-blue-500`, `active:bg-red-600`

### Key Utilities

- **Utils/ColorUtils.gd** - Color parsing and management
- **Utils/SizeUtils.gd** - Size/dimension parsing 
- **Utils/FlexUtils.gd** - Flexbox property handling
- **Utils/SizingUtils.gd** - Size constraint application
- **Utils/UtilityClassValidator.gd** - Validates utility class syntax

### Content System

HTML content is stored in `Constants.gd` as `HTML_CONTENT` (with several examples). The parser processes this content, applies styles, and renders it using Godot's UI system with FlexContainer nodes for layout.

## Key Features

- Tabbed browsing with keyboard shortcuts
- Network image loading
- Form elements (inputs, selects, textareas, buttons)
- Flexbox layout system
- Utility-class-based styling
- Inline and block element handling
- Custom HTML elements like `<separator>`

## Current Limitations

- No JavaScript support (planned: Lua scripting)
- Limited to basic HTML tags
- `<br />` elements cause layout spacing issues
- No table support yet
- External CSS files not supported
- GIF support planned but not implemented

The codebase follows a clean separation between parsing (HTMLParser), styling (CSSParser/StyleManager), and rendering (main.gd + individual tag scripts).

# Lua Documentation
# GDLuaU Technical Specification

This document provides a complete technical specification for the GDLuaU plugin. It is intended for developers who want to use the plugin for in-game scripting, modding, or other purposes, and for those who may wish to extend or reimplement its functionality.

## Table of Contents
1.  [Overview](#1-overview)
2.  [Setup and Initialization](#2-setup-and-initialization)
3.  [Core Classes](#3-core-classes)
    *   [3.1. LuauVM](#31-luauvm)
    *   [3.2. LuauFunction](#32-luaufunction)
    *   [3.3. LuauFunctionResult](#33-luaufunctionresult)
4.  [LuauVM API Reference](#4-luauvm-api-reference)
    *   [4.1. Properties](#41-properties)
    *   [4.2. Signals](#42-signals)
    *   [4.3. Core Methods](#43-core-methods)
    *   [4.4. Data Exchange API (GDLuau Specific)](#44-data-exchange-api-gdluau-specific)
    *   [4.5. Standard Luau API Bindings](#45-standard-luau-api-bindings)
    *   [4.6. Auxiliary Library (`luaL_`) Bindings](#46-auxiliary-library-lual_-bindings)
    *   [4.7. Constants](#47-constants)
5.  [Data Type Conversions](#5-data-type-conversions)
6.  [Luau Environment Features](#6-luau-environment-features)
    *   [6.1. Custom `print` Function](#61-custom-print-function)
    *   [6.2. `vector` Library](#62-vector-library)
7.  [Limitations & Caveats](#7-limitations--caveats)

---

## 1. Overview

GDLuaU is a GDExtension that integrates the Luau scripting language into Godot. It is primarily designed for user-generated content, in-game scripting, and modding, rather than as a replacement for GDScript.

The plugin's core philosophy is to expose the comprehensive Luau C API directly within GDScript. This provides a low-level, powerful, and flexible interface for interacting with a Luau virtual machine. It includes features for seamless data marshalling between Godot and Luau, such as pushing and pulling Godot Objects, Arrays, Dictionaries, and other core types.

**Key Features**:
*   A `LuauVM` node that encapsulates a `lua_State`.
*   Direct bindings to the majority of the Luau 5.1 C API.
*   Automatic conversion between Godot's `Variant` types and Luau's native types.
*   Support for pushing Godot `Object`s (like Nodes and RefCounted) to Luau as userdata.
*   Support for pushing Godot `Callable`s to Luau as functions.
*   A custom `print` implementation in Luau that emits a Godot signal.
*   A configurable interrupt signal to prevent and handle runaway scripts.
*   A built-in `vector` library in Luau for working with Godot's vector types.

---

## 2. Setup and Initialization

To use GDLuaU, you must first add a `LuauVM` node to your scene. This node represents a single, isolated Luau virtual machine.

Once the node is in the scene tree, you need to initialize its environment by loading the standard Luau libraries. This is typically done in the `_ready` function of a parent script.

**Example (GDScript):**
```gdscript
extends Node

@onready var vm: LuauVM = $LuauVM

func _ready():
    # Load all standard libraries (base, table, string, math, etc.)
    vm.open_all_libraries()
    
    # Now the VM is ready to execute code
    var result = vm.lua_dostring("print('Hello from Luau!')")
    if result != vm.LUA_OK:
        # Handle error
        var error_message = vm.lua_tostring(-1)
        print("Luau Error: ", error_message)
        vm.lua_pop(1)
```

**File Structure:**
The plugin expects a specific file structure within your Godot project, which is set up by default when installed:
```
project/
└── addons/
    └── gdluau/
        ├── bin/
        │   ├── <platform>/
        │   │   └── <library_files>
        └── gdluau.gdextension
```

---

## 3. Core Classes

The plugin registers three main classes with Godot's `ClassDB`.

### 3.1. LuauVM

This is the central class of the plugin. It inherits from `Node` and represents a single Luau VM instance (`lua_State`). All interactions with Luau, from running code to manipulating the stack, are done through methods on a `LuauVM` object.

### 3.2. LuauFunction

This class represents a reference to a Luau function within GDScript. It inherits from `RefCounted`. You can obtain a `LuauFunction` object by calling `LuauVM.lua_tofunction()` on a function value on the stack. Its primary purpose is to allow you to call Luau functions from GDScript in a safe and convenient way.

**GDScript Example:**
```gdscript
# Assume a Luau function 'add' has been defined and pushed to the stack
vm.lua_getglobal("add")
var luau_add_func: LuauFunction = vm.lua_tofunction(-1)
vm.lua_pop(1) # Pop the function from the stack

# Now call it from GDScript
var result: LuauFunctionResult = luau_add_func.pcall(5, 7)
if not result.is_error():
    print("Result from Luau: ", result.get_tuple()[0]) # Output: 12
```

### 3.3. LuauFunctionResult

This `RefCounted` class acts as a container for the results of a protected call (`pcall`) made to a `LuauFunction`. A protected call will not crash the application on an error. Instead, the `LuauFunctionResult` will indicate whether an error occurred.

*   If the call was successful, `is_error()` returns `false`, and `get_tuple()` returns an `Array` containing all the values returned by the Luau function.
*   If an error occurred, `is_error()` returns `true`, and `get_error()` returns the error message as a `String`.

---

## 4. LuauVM API Reference

This section details the properties, signals, and methods exposed by the `LuauVM` class.

### 4.1. Properties

*   **`interrupt_cooldown`**: `float` (default: `0.1`)
    *   **Description**: The minimum time in seconds between emissions of the `interrupt` signal. This is used to prevent the signal from firing too frequently in a tight loop, which could cause performance issues.

### 4.2. Signals

*   **`stdout(message: String)`**
    *   **Description**: Emitted when the `print()` function is called within the Luau environment. The arguments passed to `print()` are concatenated and sent as a single string.
*   **`interrupt()`**
    *   **Description**: Emitted periodically during Luau script execution. This signal can be used to terminate runaway scripts (e.g., `while true do end`). You can connect a function to this signal to check for conditions (like a timeout) and call `lua_error()` to stop the script.

**Example: Handling Runaway Scripts**
```gdscript
const MAX_EXECUTION_TIME = 2.0
var start_time = 0.0

func _ready():
    vm.interrupt.connect(_on_vm_interrupt)

func _on_vm_interrupt():
    if Time.get_ticks_msec() / 1000.0 - start_time > MAX_EXECUTION_TIME:
        # This will stop the script and trigger an error state
        vm.luaL_error("Execution timed out")

func run_script():
    start_time = Time.get_ticks_msec() / 1000.0
    # This script would otherwise run forever
    var result = vm.lua_dostring("while true do end") 
    if result != vm.LUA_OK:
        print("Script stopped: ", vm.lua_tostring(-1))
        vm.lua_pop(1)
```

### 4.3. Core Methods

These methods provide high-level control over the VM.

*   **`open_all_libraries()`**
    *   Loads all standard Luau libraries into the VM state. This includes `base`, `coroutine`, `table`, `os`, `string`, `math`, `vector`, `debug`, `utf8`, and `bit32`.
*   **`open_libraries(libraries: PackedByteArray)`**
    *   Loads a specific set of libraries. The `libraries` array should contain integers corresponding to the `lua_Lib` enum (e.g., `[vm.LUA_BASE_LIB, vm.LUA_TABLE_LIB]`).
*   **`load_string(code: String, chunkname: String = "loadstring") -> int`**
    *   Compiles a string of Luau code and pushes the resulting function onto the stack. It does not execute the code. Returns a `lua_Status` code (`LUA_OK` on success).
*   **`do_string(code: String, chunkname: String = "dostring") -> int`**
    *   Compiles and immediately executes a string of Luau code. This is equivalent to `load_string` followed by `lua_pcall`. Returns a `lua_Status` code (`LUA_OK` on success). If an error occurs, the error message is pushed onto the stack.

### 4.4. Data Exchange API (GDLuau Specific)

These functions are custom helpers for moving data between Godot and Luau.

*   `lua_pushvariant(var: Variant)`: Pushes any supported Godot `Variant` onto the stack. See [Data Type Conversions](#5-data-type-conversions).
*   `lua_pusharray(arr: Array)`: Pushes a Godot `Array` as a new Luau table.
*   `lua_pushdictionary(dict: Dictionary)`: Pushes a Godot `Dictionary` as a new Luau table.
*   `lua_pushobject(object: Object)`: Pushes a Godot `Object` (e.g., a `Node` or `RefCounted`) as Luau userdata. The object's lifetime is managed via reference counting for `RefCounted` types.
*   `lua_pushcallable(func: Callable, debugname: String = "") -> Error`: Pushes a Godot `Callable` as a Luau function. **Note**: Lambda (custom) callables are not supported.
*   `lua_tovariant(index: int) -> Variant`: Pops a value from the stack at `index` and converts it to a Godot `Variant`.
*   `lua_toarray(index: int) -> Array`: Converts a Luau table at `index` into a Godot `Array`.
*   `lua_todictionary(index: int) -> Dictionary`: Converts a Luau table at `index` into a Godot `Dictionary`.
*   `lua_tofunction(index: int) -> LuauFunction`: Creates a `LuauFunction` reference to the Luau function at `index`.
*   `lua_toobject(index: int) -> Object`: Converts Luau userdata at `index` back into a Godot `Object`. Returns `null` if the value is not a valid object userdata.
*   `lua_isobject(index: int) -> bool`: Checks if the value at `index` is a userdata representing a Godot `Object`.
*   `lua_isvalidobject(index: int) -> bool`: Checks if the userdata at `index` points to a valid (not freed) Godot `Object`.

**Example: Pushing and Getting a Node**
```gdscript
# GDScript
func _ready():
    vm.open_all_libraries()
    # Push this node as a global variable 'player' in Luau
    vm.lua_pushobject(self)
    vm.lua_setglobal("player")
    
    vm.lua_dostring("print(player)")
``````lua
-- LuaU
-- Assuming the above GDScript ran, 'player' is a userdata
-- representing the Godot node.
print(player) -- Outputs something like: [Node:12345]
```

### 4.5. Standard Luau API Bindings

The plugin exposes a vast portion of the standard Luau C API as methods on the `LuauVM` object. The function signatures are adapted for GDScript (e.g., C strings become Godot `String`s, integers become `int`).

For a detailed explanation of what each function does, please refer to the [Lua 5.1 Manual](https://www.lua.org/manual/5.1/manual.html#3), as Luau's API is based on it.

**Partial List of Bound Functions:**
*   **Stack Manipulation**: `lua_gettop`, `lua_settop`, `lua_pushvalue`, `lua_pop`, `lua_remove`, `lua_insert`, `lua_replace`, `lua_concat`.
*   **Pushing Primitives**: `lua_pushnil`, `lua_pushboolean`, `lua_pushinteger`, `lua_pushnumber`, `lua_pushstring`.
*   **Checking Types**: `lua_isboolean`, `lua_isfunction`, `lua_isnil`, `lua_isnone`, `lua_isnumber`, `lua_isstring`, `lua_istable`, `lua_isuserdata`, `lua_isvector`, `lua_type`, `lua_typename`.
*   **Accessing Values**: `lua_toboolean`, `lua_tointeger`, `lua_tonumber`, `lua_tostring`, `lua_tovector`, `lua_objlen`.
*   **Table Operations**: `lua_newtable`, `lua_createtable`, `lua_getfield`, `lua_setfield`, `lua_gettable`, `lua_settable`, `lua_rawget`, `lua_rawset`, `lua_rawgeti`, `lua_rawseti`.
*   **Execution**: `lua_call`, `lua_pcall`.
*   **Globals**: `lua_getglobal`, `lua_setglobal`.
*   **Metatables**: `lua_getmetatable`, `lua_setmetatable`.
*   **References**: `lua_ref`, `lua_unref`, `lua_getref`. (These are aliases for `luaL_ref`, etc.)
*   **Garbage Collection**: `lua_gc`.

### 4.6. Auxiliary Library (`luaL_`) Bindings

The auxiliary library provides higher-level helper functions.

*   **Metatable Helpers**: `luaL_newmetatable`, `luaL_getmetatable`, `luaL_callmeta`, `luaL_getmetafield`, `luaL_hasmetatable`.
*   **Error Handling and Argument Checking**: `luaL_error`, `luaL_argcheck`, `luaL_checkany`, `luaL_checkint`, `luaL_checknumber`, `luaL_checkstring`, `luaL_checkvector`, `luaL_checkobject`, `luaL_checktype`, `luaL_where`, `luaL_typerror`.
*   **Other**: `luaL_checkstack`, `luaL_checkoption`.

### 4.7. Constants

The plugin binds many of Luau's internal constants as enums on the `LuauVM` class, allowing for type-safe usage in GDScript.

*   **`lua_Status`**: `LUA_OK`, `LUA_YIELD`, `LUA_ERRRUN`, `LUA_ERRSYNTAX`, etc.
*   **`lua_Type`**: `LUA_TNIL`, `LUA_TBOOLEAN`, `LUA_TNUMBER`, `LUA_TSTRING`, `LUA_TTABLE`, etc.
*   **`lua_Lib`**: `LUA_BASE_LIB`, `LUA_TABLE_LIB`, `LUA_STRING_LIB`, etc.
*   **`lua_GCOp`**: `LUA_GCCOLLECT`, `LUA_GCSTOP`, `LUA_GCRESTART`, `LUA_GCCOUNT`, etc.
*   **Special Indices**: `LUA_REGISTRYINDEX`, `LUA_GLOBALSINDEX`.
*   **Other**: `LUA_MULTRET`, `LUA_REFNIL`, `LUA_NOREF`.

---

## 5. Data Type Conversions

The following table summarizes how data types are marshaled between GDScript (`Variant`) and Luau.

| GDScript Type | Luau Type | Notes |
| :--- | :--- | :--- |
| `Nil` | `nil` | |
| `bool` | `boolean` | |
| `int` | `number` (integer) | |
| `float` | `number` (double) | |
| `String` | `string` | |
| `PackedByteArray` | *Not directly supported* | |
| `Array` | `table` (array-like) | A new table with integer keys starting from 1. |
| `Dictionary` | `table` (dictionary-like) | Keys and values are converted recursively. |
| `Vector2`, `Vector2i` | `vector` | Converted to a Luau vector. `z` and `w` are 0. |
| `Vector3`, `Vector3i` | `vector` | Converted to a Luau vector. `w` is 0. |
| `Vector4`, `Vector4i` | `vector` | |
| `Object` | `userdata` | A special userdata that holds the object's instance ID. |
| `Callable` | `function` | A C-closure is created in Luau that calls the Godot Callable. |
| `LuauFunction` | `function` | Pushing is not supported; obtained via `lua_tofunction`. |

---

## 6. Luau Environment Features

### 6.1. Custom `print` Function

The global `print` function in Luau is overridden. Instead of printing to the standard console output, it concatenates all its arguments into a single string and emits the `stdout` signal on the `LuauVM` node.

**LuaU Example:**
```lua
print("Player health:", 100, "Mana:", 50)
```

**GDScript Receiver:**
```gdscript
func _on_vm_stdout(message: String):
    # message will be "Player health:	100	Mana:	50"
    print("Message from Luau VM: ", message)
```

### 6.2. `vector` Library

GDLuaU includes a custom `vector` library that is automatically loaded with `open_all_libraries`. This library allows Luau scripts to create and interact with vector types that are compatible with Godot's `Vector2/3/4`.

*   **Constructor**: `vector(x: number, y: number, z: number, w: number)`
    *   Creates a new vector. You can omit arguments; they will default to 0.
*   **Indexing**: Vectors can be indexed with numbers `1` through `4` to get the `x`, `y`, `z`, and `w` components respectively.
*   **`__tostring`**: Printing a vector will produce a human-readable string (e.g., `"1.0, 2.0, 3.0, 0.0"`).

**LuaU Example:**
```lua
local pos = vector(10, 25.5) -- Creates a vector(10, 25.5, 0, 0)
local dir = vector(0, -1)
local new_pos = pos + dir -- Vector math is supported
print(new_pos) -- Outputs "10.0, 24.5, 0.0, 0.0"

-- Accessing components
print("X component:", new_pos[1]) -- Outputs "X component: 10.0"```

---

## 7. Limitations & Caveats

*   **Performance**: While Luau is highly performant, frequent and heavy data marshalling between Godot and Luau (e.g., converting large arrays/dictionaries every frame) can introduce overhead.
*   **Userdata**: The plugin does not expose the raw `userdata` or `lightuserdata` C API. Godot `Object`s are the only supported form of userdata, which are handled automatically.
*   **Memory Management**: The `LuauVM` uses Godot's memory functions (`memalloc`, `memfree`). Memory usage can be monitored with `lua_gc(LUA_GCCOUNT, 0)`. Be mindful of creating too many references between Godot and Luau that could lead to memory leaks if not managed correctly.
*   **Threading**: A `LuauVM` instance (`lua_State`) is not thread-safe. All interactions with a single VM must be done from the same thread.