```lua
-- launch example: premake5 --jln-sanitizers=on

include "cpp.lua"

-- Registers new command-line options and set default values
jln_newoptions({warnings='very_strict'})

-- jln_getoptions(values, disable_others = nil, print_compiler = nil)
-- jln_getoptions(compiler, version = nil, values = nil, disable_others = nil, print_compiler = nil)
-- `= nil` indicates that the value is optional and can be nil
-- `compiler`: string. ex: 'gcc', 'g++', 'clang++', 'clang'. Or compiler and linker with semicolon separator. ex: 'clang-cl;lld-link'
-- `version`: string. Compiler version. ex: '7', '7.2'
-- `values`: table. ex: {warnings='on'}
-- `disable_others`: boolean
-- `print_compiler`: boolean
-- return {buildoptions=string, linkoptions=string}
local mylib_options = jln_getoptions({elide_type='on'})
buildoptions(mylib_options.buildoptions)
linkoptions(mylib_options.linkoptions)

-- or equivalent
jln_setoptions({elide_type='on'})

-- NOTE: for C, jln_ prefix function becomes jln_c_
```


# Options

Supported options are (in alphabetical order):

<!-- ./compiler-options.lua generators/list_options.lua --color -->
```ini
color = default auto never always
control_flow = default off on branch return allow_bugs
coverage = default off on
cpu = default generic native
debug = default off on line_tables_only gdb lldb sce
diagnostics_format = default fixits patch print_source_range_info
diagnostics_show_template_tree = default off on
elide_type = default off on
exceptions = default off on
fix_compiler_error = on default off
linker = default bfd gold lld native
lto = default off on fat thin
msvc_isystem = default anglebrackets INCLUDE_and_CAExcludePath
msvc_isystem_with_template_from_non_external = default off on
optimization = default 0 g 1 2 3 fast size
pedantic = on default off as_error
pie = default off on pic
relro = default off on full
reproducible_build_warnings = default off on
rtti = default off on
sanitizers = default off on
sanitizers_extra = default off thread pointer
shadow_warnings = off default on local compatible_local all
stack_protector = default off on strong all
stl_debug = default off on allow_broken_abi allow_broken_abi_and_bugs assert_as_exception
stl_fix = on default off
suggestions = default off on
warnings = on default off strict very_strict
warnings_as_error = default off on basic
whole_program = default off on strip_all
```
<!-- ./compiler-options.lua -->

The value `default` does nothing.

If not specified, `fix_compiler_error`, `pedantic`, `stl_fix` and `warnings` are `on` ; `shadow_warnings` is `off`.

- `control_flow=allow_bugs`
  - clang: Can crash programs with "illegal hardware instruction" on totally unlikely lines. It can also cause link errors and force `-fvisibility=hidden` and `-flto`.
- `stl_debug=allow_broken_abi_and_bugs`
  - clang: libc++ can crash on dynamic memory releases in the standard classes. This bug is fixed with the library associated with version 8.


## Recommended options

category | options
---------|---------
debug | `control_flow=on`<br>`debug=on`<br>`sanitizers=on`<br>`stl_debug=allow_broken_abi` or `on`<br>
release | `cpu=native`<br>`linker=gold`, `lld` or `native`<br>`lto=on` or `thin`<br>`optimization=3`<br>`rtti=off`<br>`whole_program=strip_all`
security | `control_flow=on`<br>`relro=full`<br>`stack_protector=strong`
really strict warnings | `pedantic=as_error`<br>`shadow_warnings=local`<br>`suggestions=on`<br>`warnings=very_strict`

