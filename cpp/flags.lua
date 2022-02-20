--  ```lua
--  -- launch example: xmake f --jln-sanitizers=on
--  
--  includes'cpp'
--  
--  -- Registers new command-line options and set default values
--  jln_cxx_init_options({warnings='very_strict'} --[[, category=string|boolean]])
--  
--  options = {}
--  if is_mode('debug') then
--    options.str_debug = 'on'
--  end
--  
--  -- Create a new rule. Options are added to the current configuration
--  jln_cxx_rule('jln_debug', options --[[, disable_others = false, imported='cpp.flags']])
--  add_rules('jln_flags')
--  
--  target('hello')
--    set_kind('binary')
--    -- Custom configuration when jln_cxx_rule() is not enough
--    on_load(function(target)
--      import'cpp.flags'
--      -- getoptions(values = {}, disable_others = false, print_compiler = false)
--      -- `values`: table. ex: {warnings='on'}
--      -- `values` can have 3 additional fields:
--      --  - `cxx`: compiler name (otherwise deducted from --cxx and --toolchain)
--      --  - `cxx_version` (otherwise deducted from cxx)
--      --  - `ld`: linker name
--      -- `disable_others`: boolean
--      -- `print_compiler`: boolean
--      -- return {cxxflags=table, ldflags=table}
--      -- Note: with C language, cxxflags, cxx and cxx_version become cflags, cc and cc_version
--      local options = flags.getoptions({elide_type='on'})
--      for _,opt in ipairs(options.cxxflags) do target:add('cxxflags', opt, {force=true}) end
--      for _,opt in ipairs(options.ldflags) do target:add('ldflags', opt, {force=true}) end
--  
--      -- or equivalent (return also options)
--      flags.setoptions(target, {elide_type='on'})
--  
--      -- return the merge of the default values and new value table
--      local values = flags.tovalues({elide_type='on'}, --[[disable_others:bool]])
--      print(values)
--    end)
--  
--    add_files('src/*.cpp')
--  
--  -- NOTE: for C, jln_ and jln_cxx_ prefix function become jln_c_
--  ```
--  
--  
--  # Options
--  
--  Supported options are (alphabetically in a category):
--  
--  <!-- ./compiler-options.lua generators/list_options.lua --color -->
--  ```ini
--  # Warning:
--  
--  conversion_warnings = on default off sign conversion
--  covered_switch_default_warnings = on default off
--  fix_compiler_error = on default off
--  msvc_crt_secure_no_warnings = on default off
--  noexcept_warnings = default off on
--  reproducible_build_warnings = default off on
--  shadow_warnings = off default on local compatible_local all
--  suggestions = default off on
--  switch_warnings = on default off exhaustive_enum mandatory_default exhaustive_enum_and_mandatory_default
--  warnings = on default off strict very_strict
--  warnings_as_error = default off on basic
--  windows_abi_compatibility_warnings = off default on
--  
--  # Pedantic:
--  
--  msvc_conformance = all default all_without_throwing_new
--  pedantic = on default off as_error
--  stl_fix = on default off
--  
--  # Debug:
--  
--  debug = default off on line_tables_only gdb lldb sce
--  float_sanitizers = default off on
--  integer_sanitizers = default off on
--  other_sanitizers = default off thread pointer memory
--  sanitizers = default off on
--  stl_debug = default off on allow_broken_abi allow_broken_abi_and_bugs assert_as_exception
--  
--  # Optimization:
--  
--  cpu = default generic native
--  linker = default bfd gold lld native
--  lto = default off on fat thin
--  optimization = default 0 g 1 2 3 fast size z
--  whole_program = default off on strip_all
--  
--  # C++:
--  
--  exceptions = default off on
--  rtti = default off on
--  
--  # Hardening:
--  
--  control_flow = default off on branch return allow_bugs
--  relro = default off on full
--  stack_protector = default off on strong all
--  
--  # Other:
--  
--  color = default auto never always
--  coverage = default off on
--  diagnostics_format = default fixits patch print_source_range_info
--  diagnostics_show_template_tree = default off on
--  elide_type = default off on
--  msvc_isystem = default anglebrackets include_and_caexcludepath external_as_include_system_flag
--  msvc_isystem_with_template_from_non_external = default off on
--  pie = default off on static fpic fPIC fpie fPIE
--  windows_bigobj = on default
--  ```
--  <!-- ./compiler-options.lua -->
--  
--  The value `default` does nothing.
--  
--  If not specified, `conversion_warnings`, `covered_switch_default_warnings`, `fix_compiler_error`, `msvc_crt_secure_no_warnings`, `pedantic`, `stl_fix`, `switch_warnings`, `warnings` and `windows_bigobj` are `on` ; `msvc_conformance` are `all` ; `shadow_warnings` and `windows_abi_compatibility_warnings` are `off`.
--  
--  - `control_flow=allow_bugs`
--    - clang: Can crash programs with "illegal hardware instruction" on totally unlikely lines. It can also cause link errors and force `-fvisibility=hidden` and `-flto`.
--  - `stl_debug=allow_broken_abi_and_bugs`
--    - clang: libc++ can crash on dynamic memory releases in the standard classes. This bug is fixed with the library associated with version 8.
--  - `msvc_isystem=external_as_include_system_flag` is only available with `cmake`.
--  
--  
--  ## Recommended options
--  
--  category | options
--  ---------|---------
--  debug | `control_flow=on`<br>`debug=on`<br>`sanitizers=on`<br>`stl_debug=allow_broken_abi` or `on`<br>
--  release | `cpu=native`<br>`linker=gold`, `lld` or `native`<br>`lto=on` or `thin`<br>`optimization=3`<br>`rtti=off`<br>`whole_program=strip_all`
--  security | `control_flow=on`<br>`relro=full`<br>`stack_protector=strong`<br>`pie=PIE`
--  really strict warnings | `pedantic=as_error`<br>`shadow_warnings=local`<br>`suggestions=on`<br>`warnings=very_strict`
--  
--  

-- File generated with https://github.com/jonathanpoelen/cpp-compiler-options

local _extraopt_flag_names = {
  ["jln-cxx"] = true,
  ["cxx"] = true,
  ["jln-cxx-version"] = true,
  ["cxx_version"] = true,
  ["jln-ld"] = true,
  ["ld"] = true,
}

local _flag_names = {
  ["jln-color"] = {["default"]="", ["auto"]="auto", ["never"]="never", ["always"]="always", [""]=""},
  ["color"] = {["default"]="", ["auto"]="auto", ["never"]="never", ["always"]="always", [""]=""},
  ["jln-control-flow"] = {["default"]="", ["off"]="off", ["on"]="on", ["branch"]="branch", ["return"]="return", ["allow_bugs"]="allow_bugs", [""]=""},
  ["control_flow"] = {["default"]="", ["off"]="off", ["on"]="on", ["branch"]="branch", ["return"]="return", ["allow_bugs"]="allow_bugs", [""]=""},
  ["jln-conversion-warnings"] = {["default"]="", ["off"]="off", ["on"]="on", ["sign"]="sign", ["conversion"]="conversion", [""]=""},
  ["conversion_warnings"] = {["default"]="", ["off"]="off", ["on"]="on", ["sign"]="sign", ["conversion"]="conversion", [""]=""},
  ["jln-coverage"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["coverage"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-covered-switch-default-warnings"] = {["default"]="", ["on"]="on", ["off"]="off", [""]=""},
  ["covered_switch_default_warnings"] = {["default"]="", ["on"]="on", ["off"]="off", [""]=""},
  ["jln-cpu"] = {["default"]="", ["generic"]="generic", ["native"]="native", [""]=""},
  ["cpu"] = {["default"]="", ["generic"]="generic", ["native"]="native", [""]=""},
  ["jln-debug"] = {["default"]="", ["off"]="off", ["on"]="on", ["line_tables_only"]="line_tables_only", ["gdb"]="gdb", ["lldb"]="lldb", ["sce"]="sce", [""]=""},
  ["debug"] = {["default"]="", ["off"]="off", ["on"]="on", ["line_tables_only"]="line_tables_only", ["gdb"]="gdb", ["lldb"]="lldb", ["sce"]="sce", [""]=""},
  ["jln-diagnostics-format"] = {["default"]="", ["fixits"]="fixits", ["patch"]="patch", ["print_source_range_info"]="print_source_range_info", [""]=""},
  ["diagnostics_format"] = {["default"]="", ["fixits"]="fixits", ["patch"]="patch", ["print_source_range_info"]="print_source_range_info", [""]=""},
  ["jln-diagnostics-show-template-tree"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["diagnostics_show_template_tree"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-elide-type"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["elide_type"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-exceptions"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["exceptions"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-fix-compiler-error"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["fix_compiler_error"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-float-sanitizers"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["float_sanitizers"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-integer-sanitizers"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["integer_sanitizers"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-linker"] = {["default"]="", ["bfd"]="bfd", ["gold"]="gold", ["lld"]="lld", ["native"]="native", [""]=""},
  ["linker"] = {["default"]="", ["bfd"]="bfd", ["gold"]="gold", ["lld"]="lld", ["native"]="native", [""]=""},
  ["jln-lto"] = {["default"]="", ["off"]="off", ["on"]="on", ["fat"]="fat", ["thin"]="thin", [""]=""},
  ["lto"] = {["default"]="", ["off"]="off", ["on"]="on", ["fat"]="fat", ["thin"]="thin", [""]=""},
  ["jln-msvc-conformance"] = {["default"]="", ["all"]="all", ["all_without_throwing_new"]="all_without_throwing_new", [""]=""},
  ["msvc_conformance"] = {["default"]="", ["all"]="all", ["all_without_throwing_new"]="all_without_throwing_new", [""]=""},
  ["jln-msvc-crt-secure-no-warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["msvc_crt_secure_no_warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-msvc-isystem"] = {["default"]="", ["anglebrackets"]="anglebrackets", ["include_and_caexcludepath"]="include_and_caexcludepath", [""]=""},
  ["msvc_isystem"] = {["default"]="", ["anglebrackets"]="anglebrackets", ["include_and_caexcludepath"]="include_and_caexcludepath", [""]=""},
  ["jln-msvc-isystem-with-template-from-non-external"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["msvc_isystem_with_template_from_non_external"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-noexcept-warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["noexcept_warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-optimization"] = {["default"]="", ["0"]="0", ["g"]="g", ["1"]="1", ["2"]="2", ["3"]="3", ["fast"]="fast", ["size"]="size", ["z"]="z", [""]=""},
  ["optimization"] = {["default"]="", ["0"]="0", ["g"]="g", ["1"]="1", ["2"]="2", ["3"]="3", ["fast"]="fast", ["size"]="size", ["z"]="z", [""]=""},
  ["jln-other-sanitizers"] = {["default"]="", ["off"]="off", ["thread"]="thread", ["pointer"]="pointer", ["memory"]="memory", [""]=""},
  ["other_sanitizers"] = {["default"]="", ["off"]="off", ["thread"]="thread", ["pointer"]="pointer", ["memory"]="memory", [""]=""},
  ["jln-pedantic"] = {["default"]="", ["off"]="off", ["on"]="on", ["as_error"]="as_error", [""]=""},
  ["pedantic"] = {["default"]="", ["off"]="off", ["on"]="on", ["as_error"]="as_error", [""]=""},
  ["jln-pie"] = {["default"]="", ["off"]="off", ["on"]="on", ["static"]="static", ["fpic"]="fpic", ["fPIC"]="fPIC", ["fpie"]="fpie", ["fPIE"]="fPIE", [""]=""},
  ["pie"] = {["default"]="", ["off"]="off", ["on"]="on", ["static"]="static", ["fpic"]="fpic", ["fPIC"]="fPIC", ["fpie"]="fpie", ["fPIE"]="fPIE", [""]=""},
  ["jln-relro"] = {["default"]="", ["off"]="off", ["on"]="on", ["full"]="full", [""]=""},
  ["relro"] = {["default"]="", ["off"]="off", ["on"]="on", ["full"]="full", [""]=""},
  ["jln-reproducible-build-warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["reproducible_build_warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-rtti"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["rtti"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-sanitizers"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["sanitizers"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-shadow-warnings"] = {["default"]="", ["off"]="off", ["on"]="on", ["local"]="local", ["compatible_local"]="compatible_local", ["all"]="all", [""]=""},
  ["shadow_warnings"] = {["default"]="", ["off"]="off", ["on"]="on", ["local"]="local", ["compatible_local"]="compatible_local", ["all"]="all", [""]=""},
  ["jln-stack-protector"] = {["default"]="", ["off"]="off", ["on"]="on", ["strong"]="strong", ["all"]="all", [""]=""},
  ["stack_protector"] = {["default"]="", ["off"]="off", ["on"]="on", ["strong"]="strong", ["all"]="all", [""]=""},
  ["jln-stl-debug"] = {["default"]="", ["off"]="off", ["on"]="on", ["allow_broken_abi"]="allow_broken_abi", ["allow_broken_abi_and_bugs"]="allow_broken_abi_and_bugs", ["assert_as_exception"]="assert_as_exception", [""]=""},
  ["stl_debug"] = {["default"]="", ["off"]="off", ["on"]="on", ["allow_broken_abi"]="allow_broken_abi", ["allow_broken_abi_and_bugs"]="allow_broken_abi_and_bugs", ["assert_as_exception"]="assert_as_exception", [""]=""},
  ["jln-stl-fix"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["stl_fix"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-suggestions"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["suggestions"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-switch-warnings"] = {["default"]="", ["on"]="on", ["off"]="off", ["exhaustive_enum"]="exhaustive_enum", ["mandatory_default"]="mandatory_default", ["exhaustive_enum_and_mandatory_default"]="exhaustive_enum_and_mandatory_default", [""]=""},
  ["switch_warnings"] = {["default"]="", ["on"]="on", ["off"]="off", ["exhaustive_enum"]="exhaustive_enum", ["mandatory_default"]="mandatory_default", ["exhaustive_enum_and_mandatory_default"]="exhaustive_enum_and_mandatory_default", [""]=""},
  ["jln-warnings"] = {["default"]="", ["off"]="off", ["on"]="on", ["strict"]="strict", ["very_strict"]="very_strict", [""]=""},
  ["warnings"] = {["default"]="", ["off"]="off", ["on"]="on", ["strict"]="strict", ["very_strict"]="very_strict", [""]=""},
  ["jln-warnings-as-error"] = {["default"]="", ["off"]="off", ["on"]="on", ["basic"]="basic", [""]=""},
  ["warnings_as_error"] = {["default"]="", ["off"]="off", ["on"]="on", ["basic"]="basic", [""]=""},
  ["jln-whole-program"] = {["default"]="", ["off"]="off", ["on"]="on", ["strip_all"]="strip_all", [""]=""},
  ["whole_program"] = {["default"]="", ["off"]="off", ["on"]="on", ["strip_all"]="strip_all", [""]=""},
  ["jln-windows-abi-compatibility-warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["windows_abi_compatibility_warnings"] = {["default"]="", ["off"]="off", ["on"]="on", [""]=""},
  ["jln-windows-bigobj"] = {["default"]="", ["on"]="on", [""]=""},
  ["windows_bigobj"] = {["default"]="", ["on"]="on", [""]=""},
}


import'core.platform.platform'
import"lib.detect"

local _get_extra = function(opt)
  local x = get_config(opt)
  return x ~= '' and x or nil
end

local _check_flags = function(d)
  for k,v in pairs(d) do
    local ref = _flag_names[k]
    if not ref then
      if not _extraopt_flag_names[k] then
        os.raise(vformat("${color.error}Unknown key: '%s'", k))
      end
    elseif not ref[v] then
      os.raise(vformat("${color.error}Unknown value '%s' for '%s'", v, k))
    end
  end
end

-- Returns the merge of the default values and new value table
-- tovalues(table, disable_others = false)
-- `values`: table. ex: {warnings='on'}
-- `values` can have 3 additional fields:
--  - `cxx`: compiler name (otherwise deducted from --cxx and --toolchain)
--  - `cxx_version`: compiler version (otherwise deducted from cxx). ex: '7', '7.2'
--  - `ld`: linker name
function tovalues(values, disable_others)
  if values then
    _check_flags(values)
    return {
      ["color"] = values["color"] or values["jln-color"] or (disable_others and "" or _flag_names["color"][get_config("jln-color")]),
      ["control_flow"] = values["control_flow"] or values["jln-control-flow"] or (disable_others and "" or _flag_names["control_flow"][get_config("jln-control-flow")]),
      ["conversion_warnings"] = values["conversion_warnings"] or values["jln-conversion-warnings"] or (disable_others and "" or _flag_names["conversion_warnings"][get_config("jln-conversion-warnings")]),
      ["coverage"] = values["coverage"] or values["jln-coverage"] or (disable_others and "" or _flag_names["coverage"][get_config("jln-coverage")]),
      ["covered_switch_default_warnings"] = values["covered_switch_default_warnings"] or values["jln-covered-switch-default-warnings"] or (disable_others and "" or _flag_names["covered_switch_default_warnings"][get_config("jln-covered-switch-default-warnings")]),
      ["cpu"] = values["cpu"] or values["jln-cpu"] or (disable_others and "" or _flag_names["cpu"][get_config("jln-cpu")]),
      ["debug"] = values["debug"] or values["jln-debug"] or (disable_others and "" or _flag_names["debug"][get_config("jln-debug")]),
      ["diagnostics_format"] = values["diagnostics_format"] or values["jln-diagnostics-format"] or (disable_others and "" or _flag_names["diagnostics_format"][get_config("jln-diagnostics-format")]),
      ["diagnostics_show_template_tree"] = values["diagnostics_show_template_tree"] or values["jln-diagnostics-show-template-tree"] or (disable_others and "" or _flag_names["diagnostics_show_template_tree"][get_config("jln-diagnostics-show-template-tree")]),
      ["elide_type"] = values["elide_type"] or values["jln-elide-type"] or (disable_others and "" or _flag_names["elide_type"][get_config("jln-elide-type")]),
      ["exceptions"] = values["exceptions"] or values["jln-exceptions"] or (disable_others and "" or _flag_names["exceptions"][get_config("jln-exceptions")]),
      ["fix_compiler_error"] = values["fix_compiler_error"] or values["jln-fix-compiler-error"] or (disable_others and "" or _flag_names["fix_compiler_error"][get_config("jln-fix-compiler-error")]),
      ["float_sanitizers"] = values["float_sanitizers"] or values["jln-float-sanitizers"] or (disable_others and "" or _flag_names["float_sanitizers"][get_config("jln-float-sanitizers")]),
      ["integer_sanitizers"] = values["integer_sanitizers"] or values["jln-integer-sanitizers"] or (disable_others and "" or _flag_names["integer_sanitizers"][get_config("jln-integer-sanitizers")]),
      ["linker"] = values["linker"] or values["jln-linker"] or (disable_others and "" or _flag_names["linker"][get_config("jln-linker")]),
      ["lto"] = values["lto"] or values["jln-lto"] or (disable_others and "" or _flag_names["lto"][get_config("jln-lto")]),
      ["msvc_conformance"] = values["msvc_conformance"] or values["jln-msvc-conformance"] or (disable_others and "" or _flag_names["msvc_conformance"][get_config("jln-msvc-conformance")]),
      ["msvc_crt_secure_no_warnings"] = values["msvc_crt_secure_no_warnings"] or values["jln-msvc-crt-secure-no-warnings"] or (disable_others and "" or _flag_names["msvc_crt_secure_no_warnings"][get_config("jln-msvc-crt-secure-no-warnings")]),
      ["msvc_isystem"] = values["msvc_isystem"] or values["jln-msvc-isystem"] or (disable_others and "" or _flag_names["msvc_isystem"][get_config("jln-msvc-isystem")]),
      ["msvc_isystem_with_template_from_non_external"] = values["msvc_isystem_with_template_from_non_external"] or values["jln-msvc-isystem-with-template-from-non-external"] or (disable_others and "" or _flag_names["msvc_isystem_with_template_from_non_external"][get_config("jln-msvc-isystem-with-template-from-non-external")]),
      ["noexcept_warnings"] = values["noexcept_warnings"] or values["jln-noexcept-warnings"] or (disable_others and "" or _flag_names["noexcept_warnings"][get_config("jln-noexcept-warnings")]),
      ["optimization"] = values["optimization"] or values["jln-optimization"] or (disable_others and "" or _flag_names["optimization"][get_config("jln-optimization")]),
      ["other_sanitizers"] = values["other_sanitizers"] or values["jln-other-sanitizers"] or (disable_others and "" or _flag_names["other_sanitizers"][get_config("jln-other-sanitizers")]),
      ["pedantic"] = values["pedantic"] or values["jln-pedantic"] or (disable_others and "" or _flag_names["pedantic"][get_config("jln-pedantic")]),
      ["pie"] = values["pie"] or values["jln-pie"] or (disable_others and "" or _flag_names["pie"][get_config("jln-pie")]),
      ["relro"] = values["relro"] or values["jln-relro"] or (disable_others and "" or _flag_names["relro"][get_config("jln-relro")]),
      ["reproducible_build_warnings"] = values["reproducible_build_warnings"] or values["jln-reproducible-build-warnings"] or (disable_others and "" or _flag_names["reproducible_build_warnings"][get_config("jln-reproducible-build-warnings")]),
      ["rtti"] = values["rtti"] or values["jln-rtti"] or (disable_others and "" or _flag_names["rtti"][get_config("jln-rtti")]),
      ["sanitizers"] = values["sanitizers"] or values["jln-sanitizers"] or (disable_others and "" or _flag_names["sanitizers"][get_config("jln-sanitizers")]),
      ["shadow_warnings"] = values["shadow_warnings"] or values["jln-shadow-warnings"] or (disable_others and "" or _flag_names["shadow_warnings"][get_config("jln-shadow-warnings")]),
      ["stack_protector"] = values["stack_protector"] or values["jln-stack-protector"] or (disable_others and "" or _flag_names["stack_protector"][get_config("jln-stack-protector")]),
      ["stl_debug"] = values["stl_debug"] or values["jln-stl-debug"] or (disable_others and "" or _flag_names["stl_debug"][get_config("jln-stl-debug")]),
      ["stl_fix"] = values["stl_fix"] or values["jln-stl-fix"] or (disable_others and "" or _flag_names["stl_fix"][get_config("jln-stl-fix")]),
      ["suggestions"] = values["suggestions"] or values["jln-suggestions"] or (disable_others and "" or _flag_names["suggestions"][get_config("jln-suggestions")]),
      ["switch_warnings"] = values["switch_warnings"] or values["jln-switch-warnings"] or (disable_others and "" or _flag_names["switch_warnings"][get_config("jln-switch-warnings")]),
      ["warnings"] = values["warnings"] or values["jln-warnings"] or (disable_others and "" or _flag_names["warnings"][get_config("jln-warnings")]),
      ["warnings_as_error"] = values["warnings_as_error"] or values["jln-warnings-as-error"] or (disable_others and "" or _flag_names["warnings_as_error"][get_config("jln-warnings-as-error")]),
      ["whole_program"] = values["whole_program"] or values["jln-whole-program"] or (disable_others and "" or _flag_names["whole_program"][get_config("jln-whole-program")]),
      ["windows_abi_compatibility_warnings"] = values["windows_abi_compatibility_warnings"] or values["jln-windows-abi-compatibility-warnings"] or (disable_others and "" or _flag_names["windows_abi_compatibility_warnings"][get_config("jln-windows-abi-compatibility-warnings")]),
      ["windows_bigobj"] = values["windows_bigobj"] or values["jln-windows-bigobj"] or (disable_others and "" or _flag_names["windows_bigobj"][get_config("jln-windows-bigobj")]),
      ["cxx"] = values["cxx"] or (not disable_others and _get_extra("jln-cxx")) or nil,
      ["cxx_version"] = values["cxx_version"] or (not disable_others and _get_extra("jln-cxx-version")) or nil,
      ["ld"] = values["ld"] or (not disable_others and _get_extra("jln-ld")) or nil,
}
  else
    return {
      ["color"] = _flag_names["color"][get_config("jln-color")],
      ["control_flow"] = _flag_names["control_flow"][get_config("jln-control-flow")],
      ["conversion_warnings"] = _flag_names["conversion_warnings"][get_config("jln-conversion-warnings")],
      ["coverage"] = _flag_names["coverage"][get_config("jln-coverage")],
      ["covered_switch_default_warnings"] = _flag_names["covered_switch_default_warnings"][get_config("jln-covered-switch-default-warnings")],
      ["cpu"] = _flag_names["cpu"][get_config("jln-cpu")],
      ["debug"] = _flag_names["debug"][get_config("jln-debug")],
      ["diagnostics_format"] = _flag_names["diagnostics_format"][get_config("jln-diagnostics-format")],
      ["diagnostics_show_template_tree"] = _flag_names["diagnostics_show_template_tree"][get_config("jln-diagnostics-show-template-tree")],
      ["elide_type"] = _flag_names["elide_type"][get_config("jln-elide-type")],
      ["exceptions"] = _flag_names["exceptions"][get_config("jln-exceptions")],
      ["fix_compiler_error"] = _flag_names["fix_compiler_error"][get_config("jln-fix-compiler-error")],
      ["float_sanitizers"] = _flag_names["float_sanitizers"][get_config("jln-float-sanitizers")],
      ["integer_sanitizers"] = _flag_names["integer_sanitizers"][get_config("jln-integer-sanitizers")],
      ["linker"] = _flag_names["linker"][get_config("jln-linker")],
      ["lto"] = _flag_names["lto"][get_config("jln-lto")],
      ["msvc_conformance"] = _flag_names["msvc_conformance"][get_config("jln-msvc-conformance")],
      ["msvc_crt_secure_no_warnings"] = _flag_names["msvc_crt_secure_no_warnings"][get_config("jln-msvc-crt-secure-no-warnings")],
      ["msvc_isystem"] = _flag_names["msvc_isystem"][get_config("jln-msvc-isystem")],
      ["msvc_isystem_with_template_from_non_external"] = _flag_names["msvc_isystem_with_template_from_non_external"][get_config("jln-msvc-isystem-with-template-from-non-external")],
      ["noexcept_warnings"] = _flag_names["noexcept_warnings"][get_config("jln-noexcept-warnings")],
      ["optimization"] = _flag_names["optimization"][get_config("jln-optimization")],
      ["other_sanitizers"] = _flag_names["other_sanitizers"][get_config("jln-other-sanitizers")],
      ["pedantic"] = _flag_names["pedantic"][get_config("jln-pedantic")],
      ["pie"] = _flag_names["pie"][get_config("jln-pie")],
      ["relro"] = _flag_names["relro"][get_config("jln-relro")],
      ["reproducible_build_warnings"] = _flag_names["reproducible_build_warnings"][get_config("jln-reproducible-build-warnings")],
      ["rtti"] = _flag_names["rtti"][get_config("jln-rtti")],
      ["sanitizers"] = _flag_names["sanitizers"][get_config("jln-sanitizers")],
      ["shadow_warnings"] = _flag_names["shadow_warnings"][get_config("jln-shadow-warnings")],
      ["stack_protector"] = _flag_names["stack_protector"][get_config("jln-stack-protector")],
      ["stl_debug"] = _flag_names["stl_debug"][get_config("jln-stl-debug")],
      ["stl_fix"] = _flag_names["stl_fix"][get_config("jln-stl-fix")],
      ["suggestions"] = _flag_names["suggestions"][get_config("jln-suggestions")],
      ["switch_warnings"] = _flag_names["switch_warnings"][get_config("jln-switch-warnings")],
      ["warnings"] = _flag_names["warnings"][get_config("jln-warnings")],
      ["warnings_as_error"] = _flag_names["warnings_as_error"][get_config("jln-warnings-as-error")],
      ["whole_program"] = _flag_names["whole_program"][get_config("jln-whole-program")],
      ["windows_abi_compatibility_warnings"] = _flag_names["windows_abi_compatibility_warnings"][get_config("jln-windows-abi-compatibility-warnings")],
      ["windows_bigobj"] = _flag_names["windows_bigobj"][get_config("jln-windows-bigobj")],
      ["cxx"] = _get_extra("jln-cxx"),
      ["cxx_version"] = _get_extra("jln-cxx-version"),
      ["ld"] = _get_extra("jln-ld"),
}
  end
end

-- same as getoptions() and apply the options on a target
function setoptions(target, values, disable_others, print_compiler)
  local options = getoptions(values, disable_others, print_compiler)
  for _,opt in ipairs(options.cxxflags) do target:add('cxxflags', opt, {force=true}) end
  for _,opt in ipairs(options.ldflags) do target:add('ldflags', opt, {force=true}) end
  return options
end

local _compiler_by_toolname = {
  vs='msvc',
  gcc='gcc',
  gxx='gcc',
  clang='clang',
  clangxx='clang',
  icc='icc',
  icpc='icc',
  icl='icl',
  icx='icx',
  icpx='icx',
  dpcpp='icx',
}

local _comp_cache = {}
local _ld_cache = {}

-- getoptions(values = {}, disable_others = false, print_compiler = false)
-- `values`: same as tovalue()
-- `disable_others`: boolean
-- `print_compiler`: boolean
-- return {cxxflags=table, ldflags=table}
function getoptions(values, disable_others, print_compiler)
  local compversion

  values = tovalues(values, disable_others)
  local compiler = values.cxx  local version = values.cxx_version
  local linker = values.ld

  do
    local original_linker = linker or ''
    linker = _ld_cache[original_linker]

    if not linker then
      if disable_others then
        linker = ''
        _ld_cache[original_linker] = linker
      else
        local program, toolname = platform.tool('ld')
        linker = toolname or detect.find_toolname(program) or nil
        _ld_cache[original_linker] = linker or ''
      end
    end
  end

  local cache = _comp_cache
  local original_compiler = compiler or ''
  local compcache = cache[original_compiler]

  if compcache then
    compiler = compcache[1]
    version = compcache[2]
    compversion = compcache[3]
    if not compiler then
      -- wrintf("Unknown compiler")
      return {buildoptions={}, linkoptions={}}
    end
  else
    cache[original_compiler] = {}

    local toolname
    if not compiler then
      compiler, toolname = platform.tool('cxx')
    end

    if not compiler then
      -- wprint("Unknown compiler")
      return {cxxflags={}, ldflags={}}
    end

    local realcompiler = compiler

    compiler = detect.find_toolname(compiler)
    if not compiler then
      compiler = detect.find_toolname(toolname) or toolname
      if compiler then
        if not version then
          version = toolname:match("%d+%.?%d*%.?%d*$")
        end
      else
        compiler = realcompiler
      end
    end
    compiler = _compiler_by_toolname[compiler]
            or (compiler:find('^vs') and 'msvc')
            or compiler

    if not version then
      version = detect.find_programver(realcompiler)

      if not version then
        version = tostring(tonumber(os.date("%y")) - (compiler:sub(0, 5) == 'clang' and 14 or 12))
      end
    end

    compversion = {}
    for i in version:gmatch("%d+") do
      compversion[#compversion+1] = tonumber(i)
    end
    if not compversion[1] then
      cprint("${color.red}Wrong version format: %s", version)
      return {cxxflags={}, ldflags={}}
    end
    compversion = compversion[1] * 100 + (compversion[2] or 0)

    cache[original_compiler] = {compiler, version, compversion}
  end

  if print_compiler then
    cprint("getoptions: compiler: ${cyan}%s${reset}, version: ${cyan}%s", compiler, version)
  end

  local jln_cxflags, jln_ldflags = {}, {}

  if ( compiler == "gcc" or compiler == "clang" or compiler == "clang-cl" ) then
    if not ( values["warnings"] == "") then
      if values["warnings"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-w"
      else
        if compiler == "gcc" then
          jln_cxflags[#jln_cxflags+1] = "-Wall"
          jln_cxflags[#jln_cxflags+1] = "-Wextra"
          jln_cxflags[#jln_cxflags+1] = "-Wcast-align"
          jln_cxflags[#jln_cxflags+1] = "-Wcast-qual"
          jln_cxflags[#jln_cxflags+1] = "-Wdisabled-optimization"
          jln_cxflags[#jln_cxflags+1] = "-Wfloat-equal"
          jln_cxflags[#jln_cxflags+1] = "-Wformat-security"
          jln_cxflags[#jln_cxflags+1] = "-Wformat=2"
          jln_cxflags[#jln_cxflags+1] = "-Winvalid-pch"
          jln_cxflags[#jln_cxflags+1] = "-Wmissing-include-dirs"
          jln_cxflags[#jln_cxflags+1] = "-Wpacked"
          jln_cxflags[#jln_cxflags+1] = "-Wredundant-decls"
          jln_cxflags[#jln_cxflags+1] = "-Wundef"
          jln_cxflags[#jln_cxflags+1] = "-Wunused-macros"
          jln_cxflags[#jln_cxflags+1] = "-Wpointer-arith"
          jln_cxflags[#jln_cxflags+1] = "-Wmissing-declarations"
          jln_cxflags[#jln_cxflags+1] = "-Wnon-virtual-dtor"
          jln_cxflags[#jln_cxflags+1] = "-Wold-style-cast"
          jln_cxflags[#jln_cxflags+1] = "-Woverloaded-virtual"
          if not ( values["switch_warnings"] == "") then
            if values["switch_warnings"] == "on" then
              jln_cxflags[#jln_cxflags+1] = "-Wswitch"
            else
              if values["switch_warnings"] == "exhaustive_enum" then
                jln_cxflags[#jln_cxflags+1] = "-Wswitch-enum"
              else
                if values["switch_warnings"] == "mandatory_default" then
                  jln_cxflags[#jln_cxflags+1] = "-Wswitch-default"
                else
                  if values["switch_warnings"] == "exhaustive_enum_and_mandatory_default" then
                    jln_cxflags[#jln_cxflags+1] = "-Wswitch-default"
                    jln_cxflags[#jln_cxflags+1] = "-Wswitch-enum"
                  else
                    jln_cxflags[#jln_cxflags+1] = "-Wno-switch"
                  end
                end
              end
            end
          end
          if not ( compversion < 407 ) then
            jln_cxflags[#jln_cxflags+1] = "-Wsuggest-attribute=noreturn"
            jln_cxflags[#jln_cxflags+1] = "-Wzero-as-null-pointer-constant"
            jln_cxflags[#jln_cxflags+1] = "-Wlogical-op"
            jln_cxflags[#jln_cxflags+1] = "-Wvector-operation-performance"
            jln_cxflags[#jln_cxflags+1] = "-Wdouble-promotion"
            jln_cxflags[#jln_cxflags+1] = "-Wtrampolines"
            if not ( compversion < 408 ) then
              jln_cxflags[#jln_cxflags+1] = "-Wuseless-cast"
              if not ( compversion < 409 ) then
                jln_cxflags[#jln_cxflags+1] = "-Wconditionally-supported"
                jln_cxflags[#jln_cxflags+1] = "-Wfloat-conversion"
                if not ( compversion < 501 ) then
                  jln_cxflags[#jln_cxflags+1] = "-Wformat-signedness"
                  jln_cxflags[#jln_cxflags+1] = "-Warray-bounds=2"
                  jln_cxflags[#jln_cxflags+1] = "-Wstrict-null-sentinel"
                  jln_cxflags[#jln_cxflags+1] = "-Wsuggest-override"
                  if not ( compversion < 601 ) then
                    jln_cxflags[#jln_cxflags+1] = "-Wduplicated-cond"
                    jln_cxflags[#jln_cxflags+1] = "-Wnull-dereference"
                    if not ( compversion < 700 ) then
                      jln_cxflags[#jln_cxflags+1] = "-Waligned-new"
                      if not ( compversion < 701 ) then
                        jln_cxflags[#jln_cxflags+1] = "-Walloc-zero"
                        jln_cxflags[#jln_cxflags+1] = "-Walloca"
                        jln_cxflags[#jln_cxflags+1] = "-Wformat-overflow=2"
                        jln_cxflags[#jln_cxflags+1] = "-Wduplicated-branches"
                        if not ( compversion < 800 ) then
                          jln_cxflags[#jln_cxflags+1] = "-Wclass-memaccess"
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        else
          jln_cxflags[#jln_cxflags+1] = "-Weverything"
          jln_cxflags[#jln_cxflags+1] = "-Wno-documentation"
          jln_cxflags[#jln_cxflags+1] = "-Wno-documentation-unknown-command"
          jln_cxflags[#jln_cxflags+1] = "-Wno-newline-eof"
          jln_cxflags[#jln_cxflags+1] = "-Wno-c++98-compat"
          jln_cxflags[#jln_cxflags+1] = "-Wno-c++98-compat-pedantic"
          jln_cxflags[#jln_cxflags+1] = "-Wno-padded"
          jln_cxflags[#jln_cxflags+1] = "-Wno-global-constructors"
          jln_cxflags[#jln_cxflags+1] = "-Wno-weak-vtables"
          jln_cxflags[#jln_cxflags+1] = "-Wno-exit-time-destructors"
          if not ( values["switch_warnings"] == "") then
            if ( values["switch_warnings"] == "on" or values["switch_warnings"] == "mandatory_default" ) then
              jln_cxflags[#jln_cxflags+1] = "-Wno-switch-enum"
            else
              if ( values["switch_warnings"] == "exhaustive_enum" or values["switch_warnings"] == "exhaustive_enum_and_mandatory_default" ) then
                jln_cxflags[#jln_cxflags+1] = "-Wswitch-enum"
              else
                if values["switch_warnings"] == "off" then
                  jln_cxflags[#jln_cxflags+1] = "-Wno-switch"
                  jln_cxflags[#jln_cxflags+1] = "-Wno-switch-enum"
                end
              end
            end
          else
            jln_cxflags[#jln_cxflags+1] = "-Wno-switch"
            jln_cxflags[#jln_cxflags+1] = "-Wno-switch-enum"
          end
          if not ( values["covered_switch_default_warnings"] == "") then
            if values["covered_switch_default_warnings"] == "off" then
              jln_cxflags[#jln_cxflags+1] = "-Wno-covered-switch-default"
            else
              jln_cxflags[#jln_cxflags+1] = "-Wcovered-switch-default"
            end
          end
          if not ( compversion < 309 ) then
            jln_cxflags[#jln_cxflags+1] = "-Wno-undefined-var-template"
            if not ( compversion < 500 ) then
              jln_cxflags[#jln_cxflags+1] = "-Wno-inconsistent-missing-destructor-override"
              if not ( compversion < 900 ) then
                jln_cxflags[#jln_cxflags+1] = "-Wno-ctad-maybe-unsupported"
                if not ( compversion < 1000 ) then
                  jln_cxflags[#jln_cxflags+1] = "-Wno-c++20-compat"
                  if not ( compversion < 1100 ) then
                    jln_cxflags[#jln_cxflags+1] = "-Wno-suggest-destructor-override"
                  end
                end
              end
            end
          end
        end
        if ( values["warnings"] == "strict" or values["warnings"] == "very_strict" ) then
          if ( compiler == "gcc" and not ( compversion < 800 ) ) then
            jln_cxflags[#jln_cxflags+1] = "-Wcast-align=strict"
          end
        end
      end
    end
    if not ( values["windows_abi_compatibility_warnings"] == "") then
      if ( ( compiler == "gcc" and not ( compversion < 1000 ) ) or compiler == "clang" or compiler == "clang-cl" ) then
        if values["windows_abi_compatibility_warnings"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-Wmismatched-tags"
        else
          jln_cxflags[#jln_cxflags+1] = "-Wno-mismatched-tags"
        end
      end
    end
    if not ( values["warnings_as_error"] == "") then
      if values["warnings_as_error"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "-Werror"
      else
        if values["warnings_as_error"] == "basic" then
          jln_cxflags[#jln_cxflags+1] = "-Werror=return-type"
          jln_cxflags[#jln_cxflags+1] = "-Werror=init-self"
          if compiler == "gcc" then
            jln_cxflags[#jln_cxflags+1] = "-Werror=div-by-zero"
            if not ( compversion < 501 ) then
              jln_cxflags[#jln_cxflags+1] = "-Werror=array-bounds"
              jln_cxflags[#jln_cxflags+1] = "-Werror=logical-op"
              jln_cxflags[#jln_cxflags+1] = "-Werror=logical-not-parentheses"
              if not ( compversion < 700 ) then
                jln_cxflags[#jln_cxflags+1] = "-Werror=literal-suffix"
              end
            end
          else
            if ( compiler == "clang" or compiler == "clang-cl" ) then
              jln_cxflags[#jln_cxflags+1] = "-Werror=array-bounds"
              jln_cxflags[#jln_cxflags+1] = "-Werror=division-by-zero"
              if not ( compversion < 304 ) then
                jln_cxflags[#jln_cxflags+1] = "-Werror=logical-not-parentheses"
                if not ( compversion < 306 ) then
                  jln_cxflags[#jln_cxflags+1] = "-Werror=delete-incomplete"
                  if not ( compversion < 600 ) then
                    jln_cxflags[#jln_cxflags+1] = "-Werror=user-defined-literals"
                    if not ( compversion < 700 ) then
                      jln_cxflags[#jln_cxflags+1] = "-Werror=dynamic-class-memaccess"
                    end
                  end
                end
              end
            end
          end
        else
          jln_cxflags[#jln_cxflags+1] = "-Wno-error"
        end
      end
    end
    if not ( values["suggestions"] == "") then
      if not ( values["suggestions"] == "off" ) then
        if compiler == "gcc" then
          jln_cxflags[#jln_cxflags+1] = "-Wsuggest-attribute=pure"
          jln_cxflags[#jln_cxflags+1] = "-Wsuggest-attribute=const"
          if not ( compversion < 500 ) then
            jln_cxflags[#jln_cxflags+1] = "-Wsuggest-final-types"
            jln_cxflags[#jln_cxflags+1] = "-Wsuggest-final-methods"
            if not ( compversion < 501 ) then
              jln_cxflags[#jln_cxflags+1] = "-Wnoexcept"
            end
          end
        end
      end
    end
    if not ( values["sanitizers"] == "") then
      if values["sanitizers"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-fno-sanitize=all"
        jln_ldflags[#jln_ldflags+1] = "-fno-sanitize=all"
      else
        if compiler == "clang-cl" then
          jln_cxflags[#jln_cxflags+1] = "-fsanitize=undefined"
          jln_cxflags[#jln_cxflags+1] = "-fsanitize=address"
          jln_cxflags[#jln_cxflags+1] = "-fsanitize-address-use-after-scope"
        else
          if compiler == "clang" then
            if not ( compversion < 301 ) then
              jln_cxflags[#jln_cxflags+1] = "-fsanitize=undefined"
              jln_cxflags[#jln_cxflags+1] = "-fsanitize=address"
              jln_cxflags[#jln_cxflags+1] = "-fsanitize-address-use-after-scope"
              jln_cxflags[#jln_cxflags+1] = "-fno-omit-frame-pointer"
              jln_cxflags[#jln_cxflags+1] = "-fno-optimize-sibling-calls"
              jln_ldflags[#jln_ldflags+1] = "-fsanitize=undefined"
              jln_ldflags[#jln_ldflags+1] = "-fsanitize=address"
              if not ( compversion < 304 ) then
                jln_cxflags[#jln_cxflags+1] = "-fsanitize=leak"
                jln_ldflags[#jln_ldflags+1] = "-fsanitize=leak"
              end
              if not ( compversion < 600 ) then
                if not ( values["stack_protector"] == "") then
                  if not ( values["stack_protector"] == "off" ) then
                    jln_cxflags[#jln_cxflags+1] = "-fsanitize-minimal-runtime"
                  end
                end
              end
            end
          else
            if not ( compversion < 408 ) then
              jln_cxflags[#jln_cxflags+1] = "-fsanitize=address"
              jln_cxflags[#jln_cxflags+1] = "-fno-omit-frame-pointer"
              jln_cxflags[#jln_cxflags+1] = "-fno-optimize-sibling-calls"
              jln_ldflags[#jln_ldflags+1] = "-fsanitize=address"
              if not ( compversion < 409 ) then
                jln_cxflags[#jln_cxflags+1] = "-fsanitize=undefined"
                jln_cxflags[#jln_cxflags+1] = "-fsanitize=leak"
                jln_ldflags[#jln_ldflags+1] = "-fsanitize=undefined"
                jln_ldflags[#jln_ldflags+1] = "-fsanitize=leak"
              end
            end
          end
        end
      end
    end
    if not ( values["control_flow"] == "") then
      if values["control_flow"] == "off" then
        if ( compiler == "gcc" and not ( compversion < 800 ) ) then
          jln_cxflags[#jln_cxflags+1] = "-fcf-protection=none"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-sanitize=cfi"
          jln_cxflags[#jln_cxflags+1] = "-fcf-protection=none"
          jln_cxflags[#jln_cxflags+1] = "-fno-sanitize-cfi-cross-dso"
          jln_ldflags[#jln_ldflags+1] = "-fno-sanitize=cfi"
        end
      else
        if ( ( compiler == "gcc" and not ( compversion < 800 ) ) or not ( compiler == "gcc" ) ) then
          if values["control_flow"] == "branch" then
            jln_cxflags[#jln_cxflags+1] = "-fcf-protection=branch"
          else
            if values["control_flow"] == "return" then
              jln_cxflags[#jln_cxflags+1] = "-fcf-protection=return"
            else
              jln_cxflags[#jln_cxflags+1] = "-fcf-protection=full"
            end
          end
          if ( values["control_flow"] == "allow_bugs" and compiler == "clang" ) then
            jln_cxflags[#jln_cxflags+1] = "-fsanitize=cfi"
            jln_cxflags[#jln_cxflags+1] = "-fvisibility=hidden"
            jln_cxflags[#jln_cxflags+1] = "-flto"
            jln_ldflags[#jln_ldflags+1] = "-fsanitize=cfi"
            jln_ldflags[#jln_ldflags+1] = "-flto"
          end
        end
      end
    end
    if not ( values["color"] == "") then
      if ( ( compiler == "gcc" and not ( compversion < 409 ) ) or compiler == "clang" or compiler == "clang-cl" ) then
        if values["color"] == "auto" then
          jln_cxflags[#jln_cxflags+1] = "-fdiagnostics-color=auto"
        else
          if values["color"] == "never" then
            jln_cxflags[#jln_cxflags+1] = "-fdiagnostics-color=never"
          else
            if values["color"] == "always" then
              jln_cxflags[#jln_cxflags+1] = "-fdiagnostics-color=always"
            end
          end
        end
      end
    end
    if not ( values["reproducible_build_warnings"] == "") then
      if ( compiler == "gcc" and not ( compversion < 409 ) ) then
        if values["reproducible_build_warnings"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-Wdate-time"
        else
          jln_cxflags[#jln_cxflags+1] = "-Wno-date-time"
        end
      end
    end
    if not ( values["diagnostics_format"] == "") then
      if values["diagnostics_format"] == "fixits" then
        if ( ( compiler == "gcc" and not ( compversion < 700 ) ) or ( compiler == "clang" and not ( compversion < 500 ) ) or ( compiler == "clang-cl" and not ( compversion < 500 ) ) ) then
          jln_cxflags[#jln_cxflags+1] = "-fdiagnostics-parseable-fixits"
        end
      else
        if values["diagnostics_format"] == "patch" then
          if ( compiler == "gcc" and not ( compversion < 700 ) ) then
            jln_cxflags[#jln_cxflags+1] = "-fdiagnostics-generate-patch"
          end
        else
          if values["diagnostics_format"] == "print_source_range_info" then
            if compiler == "clang" then
              jln_cxflags[#jln_cxflags+1] = "-fdiagnostics-print-source-range-info"
            end
          end
        end
      end
    end
    if not ( values["fix_compiler_error"] == "") then
      if values["fix_compiler_error"] == "on" then
        if compiler == "gcc" then
          if not ( compversion < 407 ) then
            jln_cxflags[#jln_cxflags+1] = "-Werror=narrowing"
            if not ( compversion < 701 ) then
              jln_cxflags[#jln_cxflags+1] = "-Werror=literal-suffix"
            end
          end
        end
        jln_cxflags[#jln_cxflags+1] = "-Werror=write-strings"
      else
        if ( compiler == "clang" or compiler == "clang-cl" ) then
          jln_cxflags[#jln_cxflags+1] = "-Wno-error=c++11-narrowing"
          jln_cxflags[#jln_cxflags+1] = "-Wno-reserved-user-defined-literal"
        end
      end
    end
    if not ( values["linker"] == "") then
      if values["linker"] == "native" then
        if compiler == "gcc" then
          jln_ldflags[#jln_ldflags+1] = "-fuse-ld=gold"
        else
          jln_ldflags[#jln_ldflags+1] = "-fuse-ld=lld"
        end
      else
        if values["linker"] == "bfd" then
          jln_ldflags[#jln_ldflags+1] = "-fuse-ld=bfd"
        else
          if ( values["linker"] == "gold" or ( compiler == "gcc" and not ( not ( compversion < 900 ) ) ) ) then
            jln_ldflags[#jln_ldflags+1] = "-fuse-ld=gold"
          else
            if not ( values["lto"] == "") then
              if ( not ( values["lto"] == "off" ) and compiler == "gcc" ) then
                jln_ldflags[#jln_ldflags+1] = "-fuse-ld=gold"
              else
                jln_ldflags[#jln_ldflags+1] = "-fuse-ld=lld"
              end
            else
              jln_ldflags[#jln_ldflags+1] = "-fuse-ld=lld"
            end
          end
        end
      end
    end
    if not ( values["lto"] == "") then
      if values["lto"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-fno-lto"
        jln_ldflags[#jln_ldflags+1] = "-fno-lto"
      else
        if compiler == "gcc" then
          jln_cxflags[#jln_cxflags+1] = "-flto"
          jln_ldflags[#jln_ldflags+1] = "-flto"
          if not ( compversion < 500 ) then
            if not ( values["warnings"] == "") then
              if not ( values["warnings"] == "off" ) then
                jln_cxflags[#jln_cxflags+1] = "-flto-odr-type-merging"
                jln_ldflags[#jln_ldflags+1] = "-flto-odr-type-merging"
              end
            end
            if values["lto"] == "fat" then
              jln_cxflags[#jln_cxflags+1] = "-ffat-lto-objects"
            else
              if values["lto"] == "thin" then
                jln_ldflags[#jln_ldflags+1] = "-fuse-linker-plugin"
              end
            end
          end
        else
          if compiler == "clang-cl" then
            jln_ldflags[#jln_ldflags+1] = "-fuse-ld=lld"
          end
          if ( values["lto"] == "thin" and not ( compversion < 600 ) ) then
            jln_cxflags[#jln_cxflags+1] = "-flto=thin"
            jln_ldflags[#jln_ldflags+1] = "-flto=thin"
          else
            jln_cxflags[#jln_cxflags+1] = "-flto"
            jln_ldflags[#jln_ldflags+1] = "-flto"
          end
        end
      end
    end
    if not ( values["shadow_warnings"] == "") then
      if values["shadow_warnings"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-Wno-shadow"
        if ( compiler == "clang-cl" or ( compiler == "clang" and not ( compversion < 800 ) ) ) then
          jln_cxflags[#jln_cxflags+1] = "-Wno-shadow-field"
        end
      else
        if values["shadow_warnings"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-Wshadow"
        else
          if values["shadow_warnings"] == "all" then
            if compiler == "gcc" then
              jln_cxflags[#jln_cxflags+1] = "-Wshadow"
            else
              jln_cxflags[#jln_cxflags+1] = "-Wshadow-all"
            end
          else
            if ( compiler == "gcc" and not ( compversion < 701 ) ) then
              if values["shadow_warnings"] == "local" then
                jln_cxflags[#jln_cxflags+1] = "-Wshadow=local"
              else
                if values["shadow_warnings"] == "compatible_local" then
                  jln_cxflags[#jln_cxflags+1] = "-Wshadow=compatible-local"
                end
              end
            end
          end
        end
      end
    end
    if not ( values["float_sanitizers"] == "") then
      if ( ( compiler == "gcc" and not ( compversion < 500 ) ) or ( compiler == "clang" and not ( compversion < 500 ) ) or compiler == "clang-cl" ) then
        if values["float_sanitizers"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-fsanitize=float-divide-by-zero"
          jln_cxflags[#jln_cxflags+1] = "-fsanitize=float-cast-overflow"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-sanitize=float-divide-by-zero"
          jln_cxflags[#jln_cxflags+1] = "-fno-sanitize=float-cast-overflow"
        end
      end
    end
    if not ( values["integer_sanitizers"] == "") then
      if ( ( compiler == "clang" and not ( compversion < 500 ) ) or compiler == "clang-cl" ) then
        if values["integer_sanitizers"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-fsanitize=integer"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-sanitize=integer"
        end
      else
        if ( compiler == "gcc" and not ( compversion < 409 ) ) then
          if values["integer_sanitizers"] == "on" then
            jln_cxflags[#jln_cxflags+1] = "-ftrapv"
            jln_cxflags[#jln_cxflags+1] = "-fsanitize=undefined"
          end
        end
      end
    end
  end
  if ( compiler == "gcc" or compiler == "clang" or compiler == "clang-cl" or compiler == "icc" ) then
    if not ( values["conversion_warnings"] == "") then
      if values["conversion_warnings"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "-Wconversion"
        jln_cxflags[#jln_cxflags+1] = "-Wsign-compare"
        jln_cxflags[#jln_cxflags+1] = "-Wsign-conversion"
      else
        if values["conversion_warnings"] == "conversion" then
          jln_cxflags[#jln_cxflags+1] = "-Wconversion"
        else
          if values["conversion_warnings"] == "sign" then
            jln_cxflags[#jln_cxflags+1] = "-Wsign-compare"
            jln_cxflags[#jln_cxflags+1] = "-Wsign-conversion"
          else
            jln_cxflags[#jln_cxflags+1] = "-Wno-conversion"
            jln_cxflags[#jln_cxflags+1] = "-Wno-sign-compare"
            jln_cxflags[#jln_cxflags+1] = "-Wno-sign-conversion"
          end
        end
      end
    end
  end
  if ( compiler == "gcc" or compiler == "clang" ) then
    if not ( values["coverage"] == "") then
      if values["coverage"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "--coverage"
        jln_ldflags[#jln_ldflags+1] = "--coverage"
        if compiler == "clang" then
          jln_ldflags[#jln_ldflags+1] = "-lprofile_rt"
        end
      end
    end
    if not ( values["debug"] == "") then
      if values["debug"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-g0"
      else
        if values["debug"] == "gdb" then
          jln_cxflags[#jln_cxflags+1] = "-ggdb"
        else
          if compiler == "clang" then
            if values["debug"] == "line_tables_only" then
              jln_cxflags[#jln_cxflags+1] = "-gline-tables-only"
            else
              if values["debug"] == "lldb" then
                jln_cxflags[#jln_cxflags+1] = "-glldb"
              else
                if values["debug"] == "sce" then
                  jln_cxflags[#jln_cxflags+1] = "-gsce"
                else
                  jln_cxflags[#jln_cxflags+1] = "-g"
                end
              end
            end
          else
            jln_cxflags[#jln_cxflags+1] = "-g"
          end
        end
      end
    end
    if not ( values["optimization"] == "") then
      if values["optimization"] == "0" then
        jln_cxflags[#jln_cxflags+1] = "-O0"
        jln_ldflags[#jln_ldflags+1] = "-O0"
      else
        if values["optimization"] == "g" then
          jln_cxflags[#jln_cxflags+1] = "-Og"
          jln_ldflags[#jln_ldflags+1] = "-Og"
        else
          jln_cxflags[#jln_cxflags+1] = "-DNDEBUG"
          jln_ldflags[#jln_ldflags+1] = "-Wl,-O1"
          if values["optimization"] == "size" then
            jln_cxflags[#jln_cxflags+1] = "-Os"
            jln_ldflags[#jln_ldflags+1] = "-Os"
          else
            if values["optimization"] == "z" then
              if ( compiler == "clang" or compiler == "clang-cl" ) then
                jln_cxflags[#jln_cxflags+1] = "-Oz"
                jln_ldflags[#jln_ldflags+1] = "-Oz"
              else
                jln_cxflags[#jln_cxflags+1] = "-Os"
                jln_ldflags[#jln_ldflags+1] = "-Os"
              end
            else
              if values["optimization"] == "fast" then
                jln_cxflags[#jln_cxflags+1] = "-Ofast"
                jln_ldflags[#jln_ldflags+1] = "-Ofast"
              else
                if values["optimization"] == "1" then
                  jln_cxflags[#jln_cxflags+1] = "-O1"
                  jln_ldflags[#jln_ldflags+1] = "-O1"
                else
                  if values["optimization"] == "2" then
                    jln_cxflags[#jln_cxflags+1] = "-O2"
                    jln_ldflags[#jln_ldflags+1] = "-O2"
                  else
                    if values["optimization"] == "3" then
                      jln_cxflags[#jln_cxflags+1] = "-O3"
                      jln_ldflags[#jln_ldflags+1] = "-O3"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if not ( values["cpu"] == "") then
      if values["cpu"] == "generic" then
        jln_cxflags[#jln_cxflags+1] = "-mtune=generic"
        jln_ldflags[#jln_ldflags+1] = "-mtune=generic"
      else
        jln_cxflags[#jln_cxflags+1] = "-march=native"
        jln_cxflags[#jln_cxflags+1] = "-mtune=native"
        jln_ldflags[#jln_ldflags+1] = "-march=native"
        jln_ldflags[#jln_ldflags+1] = "-mtune=native"
      end
    end
    if not ( values["whole_program"] == "") then
      if values["whole_program"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-fno-whole-program"
        if ( compiler == "clang" and not ( compversion < 309 ) ) then
          jln_cxflags[#jln_cxflags+1] = "-fno-whole-program-vtables"
          jln_ldflags[#jln_ldflags+1] = "-fno-whole-program-vtables"
        end
      else
        if linker == "ld64" then
          jln_ldflags[#jln_ldflags+1] = "-Wl,-dead_strip"
          jln_ldflags[#jln_ldflags+1] = "-Wl,-S"
        else
          jln_ldflags[#jln_ldflags+1] = "-s"
          if values["whole_program"] == "strip_all" then
            jln_ldflags[#jln_ldflags+1] = "-Wl,--gc-sections"
            jln_ldflags[#jln_ldflags+1] = "-Wl,--strip-all"
          end
        end
        if compiler == "gcc" then
          jln_cxflags[#jln_cxflags+1] = "-fwhole-program"
          jln_ldflags[#jln_ldflags+1] = "-fwhole-program"
        else
          if compiler == "clang" then
            if not ( compversion < 309 ) then
              if not ( values["lto"] == "") then
                if not ( values["lto"] == "off" ) then
                  jln_cxflags[#jln_cxflags+1] = "-fwhole-program-vtables"
                  jln_ldflags[#jln_ldflags+1] = "-fwhole-program-vtables"
                end
              end
              if not ( compversion < 700 ) then
                jln_cxflags[#jln_cxflags+1] = "-fforce-emit-vtables"
                jln_ldflags[#jln_ldflags+1] = "-fforce-emit-vtables"
              end
            end
          end
        end
      end
    end
    if not ( values["pedantic"] == "") then
      if not ( values["pedantic"] == "off" ) then
        jln_cxflags[#jln_cxflags+1] = "-pedantic"
        if values["pedantic"] == "as_error" then
          jln_cxflags[#jln_cxflags+1] = "-pedantic-errors"
        end
      end
    end
    if not ( values["stack_protector"] == "") then
      if values["stack_protector"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-Wno-stack-protector"
        jln_cxflags[#jln_cxflags+1] = "-U_FORTIFY_SOURCE"
        jln_ldflags[#jln_ldflags+1] = "-Wno-stack-protector"
      else
        jln_cxflags[#jln_cxflags+1] = "-D_FORTIFY_SOURCE=2"
        jln_cxflags[#jln_cxflags+1] = "-Wstack-protector"
        if values["stack_protector"] == "strong" then
          if compiler == "gcc" then
            if not ( compversion < 409 ) then
              jln_cxflags[#jln_cxflags+1] = "-fstack-protector-strong"
              jln_ldflags[#jln_ldflags+1] = "-fstack-protector-strong"
              if not ( compversion < 800 ) then
                jln_cxflags[#jln_cxflags+1] = "-fstack-clash-protection"
                jln_ldflags[#jln_ldflags+1] = "-fstack-clash-protection"
              end
            end
          else
            if compiler == "clang" then
              jln_cxflags[#jln_cxflags+1] = "-fstack-protector-strong"
              jln_cxflags[#jln_cxflags+1] = "-fsanitize=safe-stack"
              jln_ldflags[#jln_ldflags+1] = "-fstack-protector-strong"
              jln_ldflags[#jln_ldflags+1] = "-fsanitize=safe-stack"
              if not ( compversion < 1100 ) then
                jln_cxflags[#jln_cxflags+1] = "-fstack-clash-protection"
                jln_ldflags[#jln_ldflags+1] = "-fstack-clash-protection"
              end
            end
          end
        else
          if values["stack_protector"] == "all" then
            jln_cxflags[#jln_cxflags+1] = "-fstack-protector-all"
            jln_ldflags[#jln_ldflags+1] = "-fstack-protector-all"
            if ( compiler == "gcc" and not ( compversion < 800 ) ) then
              jln_cxflags[#jln_cxflags+1] = "-fstack-clash-protection"
              jln_ldflags[#jln_ldflags+1] = "-fstack-clash-protection"
            else
              if compiler == "clang" then
                jln_cxflags[#jln_cxflags+1] = "-fsanitize=safe-stack"
                jln_ldflags[#jln_ldflags+1] = "-fsanitize=safe-stack"
                if not ( compversion < 1100 ) then
                  jln_cxflags[#jln_cxflags+1] = "-fstack-clash-protection"
                  jln_ldflags[#jln_ldflags+1] = "-fstack-clash-protection"
                end
              end
            end
          else
            jln_cxflags[#jln_cxflags+1] = "-fstack-protector"
            jln_ldflags[#jln_ldflags+1] = "-fstack-protector"
          end
        end
        if compiler == "clang" then
          jln_cxflags[#jln_cxflags+1] = "-fsanitize=shadow-call-stack"
          jln_ldflags[#jln_ldflags+1] = "-fsanitize=shadow-call-stack"
        end
      end
    end
    if not ( values["relro"] == "") then
      if values["relro"] == "off" then
        jln_ldflags[#jln_ldflags+1] = "-Wl,-z,norelro"
      else
        if values["relro"] == "on" then
          jln_ldflags[#jln_ldflags+1] = "-Wl,-z,relro"
        else
          if values["relro"] == "full" then
            jln_ldflags[#jln_ldflags+1] = "-Wl,-z,relro,-z,now,-z,noexecstack"
            if not ( values["linker"] == "") then
              if not ( ( values["linker"] == "gold" or ( compiler == "gcc" and not ( not ( compversion < 900 ) ) ) or ( values["linker"] == "native" and compiler == "gcc" ) ) ) then
                jln_ldflags[#jln_ldflags+1] = "-Wl,-z,separate-code"
              end
            end
          end
        end
      end
    end
    if not ( values["pie"] == "") then
      if values["pie"] == "off" then
        jln_ldflags[#jln_ldflags+1] = "-no-pic"
      else
        if values["pie"] == "on" then
          jln_ldflags[#jln_ldflags+1] = "-pie"
        else
          if values["pie"] == "static" then
            jln_ldflags[#jln_ldflags+1] = "-static-pie"
          else
            if values["pie"] == "fpie" then
              jln_cxflags[#jln_cxflags+1] = "-fpie"
            else
              if values["pie"] == "fpic" then
                jln_cxflags[#jln_cxflags+1] = "-fpic"
              else
                if values["pie"] == "fPIE" then
                  jln_cxflags[#jln_cxflags+1] = "-fPIE"
                else
                  if values["pie"] == "fPIC" then
                    jln_cxflags[#jln_cxflags+1] = "-fPIC"
                  end
                end
              end
            end
          end
        end
      end
    end
    if not ( values["stl_debug"] == "") then
      if not ( values["stl_debug"] == "off" ) then
        if values["stl_debug"] == "assert_as_exception" then
          jln_cxflags[#jln_cxflags+1] = "-D_LIBCPP_DEBUG_USE_EXCEPTIONS"
        end
        if ( values["stl_debug"] == "allow_broken_abi" or values["stl_debug"] == "allow_broken_abi_and_bugs" ) then
          if compiler == "clang" then
            if ( not ( compversion < 800 ) or values["stl_debug"] == "allow_broken_abi_and_bugs" ) then
              jln_cxflags[#jln_cxflags+1] = "-D_LIBCPP_DEBUG=1"
            end
          end
          jln_cxflags[#jln_cxflags+1] = "-D_GLIBCXX_DEBUG"
        else
          jln_cxflags[#jln_cxflags+1] = "-D_GLIBCXX_ASSERTIONS"
        end
        if not ( values["pedantic"] == "") then
          if not ( values["pedantic"] == "off" ) then
            jln_cxflags[#jln_cxflags+1] = "-D_GLIBCXX_DEBUG_PEDANTIC"
          end
        end
      end
    end
    if not ( values["elide_type"] == "") then
      if values["elide_type"] == "on" then
        if ( compiler == "gcc" and not ( compversion < 800 ) ) then
          jln_cxflags[#jln_cxflags+1] = "-felide-type"
        end
      else
        if ( ( compiler == "gcc" and not ( compversion < 800 ) ) or ( compiler == "clang" and not ( compversion < 304 ) ) ) then
          jln_cxflags[#jln_cxflags+1] = "-fno-elide-type"
        end
      end
    end
    if not ( values["exceptions"] == "") then
      if values["exceptions"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "-fexceptions"
      else
        jln_cxflags[#jln_cxflags+1] = "-fno-exceptions"
      end
    end
    if not ( values["rtti"] == "") then
      if values["rtti"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "-frtti"
      else
        jln_cxflags[#jln_cxflags+1] = "-fno-rtti"
      end
    end
    if not ( values["diagnostics_show_template_tree"] == "") then
      if ( ( compiler == "gcc" and not ( compversion < 800 ) ) or compiler == "clang" ) then
        if values["diagnostics_show_template_tree"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-fdiagnostics-show-template-tree"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-diagnostics-show-template-tree"
        end
      end
    end
    if not ( values["other_sanitizers"] == "") then
      if values["other_sanitizers"] == "thread" then
        jln_cxflags[#jln_cxflags+1] = "-fsanitize=thread"
      else
        if values["other_sanitizers"] == "memory" then
          if ( compiler == "clang" and not ( compversion < 500 ) ) then
            jln_cxflags[#jln_cxflags+1] = "-fsanitize=memory"
          end
        else
          if values["other_sanitizers"] == "pointer" then
            if ( compiler == "gcc" and not ( compversion < 800 ) ) then
              jln_cxflags[#jln_cxflags+1] = "-fsanitize=pointer-compare"
              jln_cxflags[#jln_cxflags+1] = "-fsanitize=pointer-subtract"
            end
          end
        end
      end
    end
    if not ( values["noexcept_warnings"] == "") then
      if ( compiler == "gcc" and not ( compversion < 409 ) ) then
        if values["noexcept_warnings"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-Wnoexcept"
        else
          jln_cxflags[#jln_cxflags+1] = "-Wno-noexcept"
        end
      end
    end
  end
  if linker == "lld-link" then
    if not ( values["lto"] == "") then
      if values["lto"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-fno-lto"
      else
        if values["lto"] == "thin" then
          jln_cxflags[#jln_cxflags+1] = "-flto=thin"
        else
          jln_cxflags[#jln_cxflags+1] = "-flto"
          jln_ldflags[#jln_ldflags+1] = "-flto"
        end
      end
    end
    if not ( values["whole_program"] == "") then
      if values["whole_program"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "-fno-whole-program"
      else
        if not ( values["lto"] == "") then
          if not ( values["lto"] == "off" ) then
            jln_cxflags[#jln_cxflags+1] = "-fwhole-program-vtables"
            jln_ldflags[#jln_ldflags+1] = "-fwhole-program-vtables"
          end
        end
      end
    end
  end
  if ( compiler == "msvc" or compiler == "clang-cl" or compiler == "icl" ) then
    if not ( values["exceptions"] == "") then
      if values["exceptions"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/EHsc"
        jln_cxflags[#jln_cxflags+1] = "/D_HAS_EXCEPTIONS=1"
      else
        jln_cxflags[#jln_cxflags+1] = "/EHs-"
        jln_cxflags[#jln_cxflags+1] = "/D_HAS_EXCEPTIONS=0"
      end
    end
    if not ( values["rtti"] == "") then
      if values["rtti"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/GR"
      else
        jln_cxflags[#jln_cxflags+1] = "/GR-"
      end
    end
    if not ( values["stl_debug"] == "") then
      if values["stl_debug"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "/D_HAS_ITERATOR_DEBUGGING=0"
      else
        jln_cxflags[#jln_cxflags+1] = "/D_DEBUG"
        jln_cxflags[#jln_cxflags+1] = "/D_HAS_ITERATOR_DEBUGGING=1"
      end
    end
    if not ( compiler == "icl" ) then
      if not ( values["stl_fix"] == "") then
        if values["stl_fix"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "/DNOMINMAX"
        end
      end
      if not ( values["debug"] == "") then
        if values["debug"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/DEBUG:NONE"
        else
          jln_cxflags[#jln_cxflags+1] = "/RTC1"
          jln_cxflags[#jln_cxflags+1] = "/Od"
          if values["debug"] == "on" then
            jln_cxflags[#jln_cxflags+1] = "/DEBUG"
          else
            if values["debug"] == "line_tables_only" then
              if compiler == "clang-cl" then
                jln_cxflags[#jln_cxflags+1] = "-gline-tables-only"
              end
              jln_cxflags[#jln_cxflags+1] = "/DEBUG:FASTLINK"
            end
          end
          if not ( values["optimization"] == "") then
            if values["optimization"] == "g" then
              jln_cxflags[#jln_cxflags+1] = "/Zi"
            else
              if not ( values["whole_program"] == "") then
                if values["whole_program"] == "off" then
                  jln_cxflags[#jln_cxflags+1] = "/ZI"
                else
                  jln_cxflags[#jln_cxflags+1] = "/Zi"
                end
              else
                jln_cxflags[#jln_cxflags+1] = "/ZI"
              end
            end
          else
            if not ( values["whole_program"] == "") then
              if values["whole_program"] == "off" then
                jln_cxflags[#jln_cxflags+1] = "/ZI"
              else
                jln_cxflags[#jln_cxflags+1] = "/Zi"
              end
            else
              jln_cxflags[#jln_cxflags+1] = "/ZI"
            end
          end
        end
      end
      if not ( values["optimization"] == "") then
        if values["optimization"] == "0" then
          jln_cxflags[#jln_cxflags+1] = "/Ob0"
          jln_cxflags[#jln_cxflags+1] = "/Od"
          jln_cxflags[#jln_cxflags+1] = "/Oi-"
          jln_cxflags[#jln_cxflags+1] = "/Oy-"
        else
          if values["optimization"] == "g" then
            jln_cxflags[#jln_cxflags+1] = "/Ob1"
          else
            jln_cxflags[#jln_cxflags+1] = "/DNDEBUG"
            if values["optimization"] == "1" then
              jln_cxflags[#jln_cxflags+1] = "/O1"
            else
              if values["optimization"] == "2" then
                jln_cxflags[#jln_cxflags+1] = "/O2"
              else
                if values["optimization"] == "3" then
                  jln_cxflags[#jln_cxflags+1] = "/O2"
                else
                  if ( values["optimization"] == "size" or values["optimization"] == "z" ) then
                    jln_cxflags[#jln_cxflags+1] = "/O1"
                    jln_cxflags[#jln_cxflags+1] = "/GL"
                    jln_cxflags[#jln_cxflags+1] = "/Gw"
                  else
                    if values["optimization"] == "fast" then
                      jln_cxflags[#jln_cxflags+1] = "/O2"
                      jln_cxflags[#jln_cxflags+1] = "/fp:fast"
                    end
                  end
                end
              end
            end
          end
        end
      end
      if not ( values["control_flow"] == "") then
        if values["control_flow"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/guard:cf-"
        else
          jln_cxflags[#jln_cxflags+1] = "/guard:cf"
        end
      end
      if not ( values["whole_program"] == "") then
        if values["whole_program"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/GL-"
        else
          jln_cxflags[#jln_cxflags+1] = "/GL"
          jln_cxflags[#jln_cxflags+1] = "/Gw"
          jln_ldflags[#jln_ldflags+1] = "/LTCG"
          if values["whole_program"] == "strip_all" then
            jln_ldflags[#jln_ldflags+1] = "/OPT:REF"
          end
        end
      end
      if not ( values["pedantic"] == "") then
        if not ( values["pedantic"] == "off" ) then
          jln_cxflags[#jln_cxflags+1] = "/permissive-"
          jln_cxflags[#jln_cxflags+1] = "/Zc:__cplusplus"
        end
      end
      if not ( values["stack_protector"] == "") then
        if values["stack_protector"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/GS-"
        else
          jln_cxflags[#jln_cxflags+1] = "/GS"
          jln_cxflags[#jln_cxflags+1] = "/sdl"
          if values["stack_protector"] == "strong" then
            jln_cxflags[#jln_cxflags+1] = "/RTC1"
            if ( compiler == "msvc" and not ( compversion < 1607 ) ) then
              jln_cxflags[#jln_cxflags+1] = "/guard:ehcont"
              jln_ldflags[#jln_ldflags+1] = "/CETCOMPAT"
            end
          else
            if values["stack_protector"] == "all" then
              jln_cxflags[#jln_cxflags+1] = "/RTC1"
              jln_cxflags[#jln_cxflags+1] = "/RTCc"
            end
          end
        end
      end
    end
  end
  if compiler == "msvc" then
    if not ( values["windows_bigobj"] == "") then
      jln_cxflags[#jln_cxflags+1] = "/bigobj"
    end
    if not ( values["msvc_conformance"] == "") then
      if ( values["msvc_conformance"] == "all" or values["msvc_conformance"] == "all_without_throwing_new" ) then
        jln_cxflags[#jln_cxflags+1] = "/Zc:inline"
        jln_cxflags[#jln_cxflags+1] = "/Zc:referenceBinding"
        if values["msvc_conformance"] == "all" then
          jln_cxflags[#jln_cxflags+1] = "/Zc:throwingNew"
        end
        if not ( compversion < 1506 ) then
          jln_cxflags[#jln_cxflags+1] = "/Zc:externConstexpr"
          if not ( compversion < 1608 ) then
            jln_cxflags[#jln_cxflags+1] = "/Zc:lambda"
            if not ( compversion < 1605 ) then
              jln_cxflags[#jln_cxflags+1] = "/Zc:preprocessor"
            end
          end
        end
      end
    end
    if not ( values["msvc_crt_secure_no_warnings"] == "") then
      if values["msvc_crt_secure_no_warnings"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/D_CRT_SECURE_NO_WARNINGS=1"
      else
        if values["msvc_crt_secure_no_warnings"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/U_CRT_SECURE_NO_WARNINGS"
        end
      end
    end
    if not ( values["msvc_isystem"] == "") then
      if values["msvc_isystem"] == "external_as_include_system_flag" then
        -- unimplementable
      else
        jln_cxflags[#jln_cxflags+1] = "/experimental:external"
        jln_cxflags[#jln_cxflags+1] = "/external:W0"
        if values["msvc_isystem"] == "anglebrackets" then
          jln_cxflags[#jln_cxflags+1] = "/external:anglebrackets"
        else
          jln_cxflags[#jln_cxflags+1] = "/external:env:INCLUDE"
          jln_cxflags[#jln_cxflags+1] = "/external:env:CAExcludePath"
        end
      end
      if not ( values["msvc_isystem_with_template_from_non_external"] == "") then
        if values["msvc_isystem_with_template_from_non_external"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/external:template"
        else
          jln_cxflags[#jln_cxflags+1] = "/external:template-"
        end
      end
      if not ( values["warnings"] == "") then
        if values["warnings"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/W0"
        else
          jln_cxflags[#jln_cxflags+1] = "/wd4710"
          jln_cxflags[#jln_cxflags+1] = "/wd4711"
          if not ( not ( compversion < 1921 ) ) then
            jln_cxflags[#jln_cxflags+1] = "/wd4774"
          end
          if values["warnings"] == "on" then
            jln_cxflags[#jln_cxflags+1] = "/W4"
            jln_cxflags[#jln_cxflags+1] = "/wd4514"
          else
            jln_cxflags[#jln_cxflags+1] = "/Wall"
            jln_cxflags[#jln_cxflags+1] = "/wd4514"
            jln_cxflags[#jln_cxflags+1] = "/wd4571"
            jln_cxflags[#jln_cxflags+1] = "/wd4355"
            jln_cxflags[#jln_cxflags+1] = "/wd4548"
            jln_cxflags[#jln_cxflags+1] = "/wd4577"
            jln_cxflags[#jln_cxflags+1] = "/wd4820"
            jln_cxflags[#jln_cxflags+1] = "/wd5039"
            jln_cxflags[#jln_cxflags+1] = "/wd4464"
            jln_cxflags[#jln_cxflags+1] = "/wd4868"
            jln_cxflags[#jln_cxflags+1] = "/wd5045"
            if values["warnings"] == "strict" then
              jln_cxflags[#jln_cxflags+1] = "/wd4583"
              jln_cxflags[#jln_cxflags+1] = "/wd4619"
            end
          end
        end
      end
      if not ( values["switch_warnings"] == "") then
        if ( values["switch_warnings"] == "on" or values["switch_warnings"] == "mandatory_default" ) then
          jln_cxflags[#jln_cxflags+1] = "/w14062"
        else
          if ( values["switch_warnings"] == "exhaustive_enum" or values["switch_warnings"] == "exhaustive_enum_and_mandatory_default" ) then
            jln_cxflags[#jln_cxflags+1] = "/w14061"
            jln_cxflags[#jln_cxflags+1] = "/w14062"
          else
            if values["switch_warnings"] == "off" then
              jln_cxflags[#jln_cxflags+1] = "/wd4061"
              jln_cxflags[#jln_cxflags+1] = "/wd4062"
            end
          end
        end
      end
    else
      if not ( values["warnings"] == "") then
        if values["warnings"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/W0"
        else
          if values["warnings"] == "on" then
            jln_cxflags[#jln_cxflags+1] = "/W4"
            jln_cxflags[#jln_cxflags+1] = "/wd4514"
            jln_cxflags[#jln_cxflags+1] = "/wd4711"
          else
            jln_cxflags[#jln_cxflags+1] = "/Wall"
            jln_cxflags[#jln_cxflags+1] = "/wd4355"
            jln_cxflags[#jln_cxflags+1] = "/wd4514"
            jln_cxflags[#jln_cxflags+1] = "/wd4548"
            jln_cxflags[#jln_cxflags+1] = "/wd4571"
            jln_cxflags[#jln_cxflags+1] = "/wd4577"
            jln_cxflags[#jln_cxflags+1] = "/wd4625"
            jln_cxflags[#jln_cxflags+1] = "/wd4626"
            jln_cxflags[#jln_cxflags+1] = "/wd4668"
            jln_cxflags[#jln_cxflags+1] = "/wd4710"
            jln_cxflags[#jln_cxflags+1] = "/wd4711"
            if not ( not ( compversion < 1921 ) ) then
              jln_cxflags[#jln_cxflags+1] = "/wd4774"
            end
            jln_cxflags[#jln_cxflags+1] = "/wd4820"
            jln_cxflags[#jln_cxflags+1] = "/wd5026"
            jln_cxflags[#jln_cxflags+1] = "/wd5027"
            jln_cxflags[#jln_cxflags+1] = "/wd5039"
            jln_cxflags[#jln_cxflags+1] = "/wd4464"
            jln_cxflags[#jln_cxflags+1] = "/wd4868"
            jln_cxflags[#jln_cxflags+1] = "/wd5045"
            if values["warnings"] == "strict" then
              jln_cxflags[#jln_cxflags+1] = "/wd4061"
              jln_cxflags[#jln_cxflags+1] = "/wd4266"
              jln_cxflags[#jln_cxflags+1] = "/wd4583"
              jln_cxflags[#jln_cxflags+1] = "/wd4619"
              jln_cxflags[#jln_cxflags+1] = "/wd4623"
              jln_cxflags[#jln_cxflags+1] = "/wd5204"
            end
          end
        end
      end
    end
    if not ( values["conversion_warnings"] == "") then
      if values["conversion_warnings"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/w14244"
        jln_cxflags[#jln_cxflags+1] = "/w14245"
        jln_cxflags[#jln_cxflags+1] = "/w14388"
        jln_cxflags[#jln_cxflags+1] = "/w14365"
      else
        if values["conversion_warnings"] == "conversion" then
          jln_cxflags[#jln_cxflags+1] = "/w14244"
          jln_cxflags[#jln_cxflags+1] = "/w14365"
        else
          if values["conversion_warnings"] == "sign" then
            jln_cxflags[#jln_cxflags+1] = "/w14388"
            jln_cxflags[#jln_cxflags+1] = "/w14245"
          else
            jln_cxflags[#jln_cxflags+1] = "/wd4244"
            jln_cxflags[#jln_cxflags+1] = "/wd4365"
            jln_cxflags[#jln_cxflags+1] = "/wd4388"
            jln_cxflags[#jln_cxflags+1] = "/wd4245"
          end
        end
      end
    end
    if not ( values["shadow_warnings"] == "") then
      if values["shadow_warnings"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "/wd4456"
        jln_cxflags[#jln_cxflags+1] = "/wd4459"
      else
        if ( values["shadow_warnings"] == "on" or values["shadow_warnings"] == "all" ) then
          jln_cxflags[#jln_cxflags+1] = "/w4456"
          jln_cxflags[#jln_cxflags+1] = "/w4459"
        else
          if values["shadow_warnings"] == "local" then
            jln_cxflags[#jln_cxflags+1] = "/w4456"
            jln_cxflags[#jln_cxflags+1] = "/wd4459"
          end
        end
      end
    end
    if not ( values["warnings_as_error"] == "") then
      if values["warnings_as_error"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/WX"
        jln_ldflags[#jln_ldflags+1] = "/WX"
      else
        if values["warnings_as_error"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "/WX-"
        else
          jln_cxflags[#jln_cxflags+1] = "/we4455"
          jln_cxflags[#jln_cxflags+1] = "/we4150"
          jln_cxflags[#jln_cxflags+1] = "/we4716"
          jln_cxflags[#jln_cxflags+1] = "/we2124"
        end
      end
    end
    if not ( values["lto"] == "") then
      if values["lto"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "/LTCG:OFF"
      else
        jln_cxflags[#jln_cxflags+1] = "/GL"
        jln_ldflags[#jln_ldflags+1] = "/LTCG"
      end
    end
    if not ( values["sanitizers"] == "") then
      if not ( compversion < 1609 ) then
        jln_cxflags[#jln_cxflags+1] = "/fsanitize=address"
        jln_cxflags[#jln_cxflags+1] = "/fsanitize-address-use-after-return"
      else
        if values["sanitizers"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "/sdl"
        else
          if not ( values["stack_protector"] == "") then
            if not ( values["stack_protector"] == "off" ) then
              jln_cxflags[#jln_cxflags+1] = "/sdl-"
            end
          end
        end
      end
    end
  end
  if compiler == "icl" then
    if not ( values["warnings"] == "") then
      if values["warnings"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "/w"
      else
        jln_cxflags[#jln_cxflags+1] = "/W2"
        jln_cxflags[#jln_cxflags+1] = "/Qdiag-disable:1418,2259"
      end
    end
    if not ( values["warnings_as_error"] == "") then
      if values["warnings_as_error"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/WX"
      else
        if values["warnings_as_error"] == "basic" then
          jln_cxflags[#jln_cxflags+1] = "/Qdiag-error:1079,39,109"
        end
      end
    end
    if not ( values["windows_bigobj"] == "") then
      jln_cxflags[#jln_cxflags+1] = "/bigobj"
    end
    if not ( values["msvc_conformance"] == "") then
      if ( values["msvc_conformance"] == "all" or values["msvc_conformance"] == "all_without_throwing_new" ) then
        jln_cxflags[#jln_cxflags+1] = "/Zc:inline"
        jln_cxflags[#jln_cxflags+1] = "/Zc:strictStrings"
        if values["msvc_conformance"] == "all" then
          jln_cxflags[#jln_cxflags+1] = "/Zc:throwingNew"
        end
      end
    end
    if not ( values["debug"] == "") then
      if values["debug"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "/debug:NONE"
      else
        jln_cxflags[#jln_cxflags+1] = "/RTC1"
        jln_cxflags[#jln_cxflags+1] = "/Od"
        if values["debug"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "/debug:full"
        else
          if values["debug"] == "line_tables_only" then
            jln_cxflags[#jln_cxflags+1] = "/debug:minimal"
          end
        end
        if not ( values["optimization"] == "") then
          if values["optimization"] == "g" then
            jln_cxflags[#jln_cxflags+1] = "/Zi"
          else
            if not ( values["whole_program"] == "") then
              if values["whole_program"] == "off" then
                jln_cxflags[#jln_cxflags+1] = "/ZI"
              else
                jln_cxflags[#jln_cxflags+1] = "/Zi"
              end
            else
              jln_cxflags[#jln_cxflags+1] = "/ZI"
            end
          end
        else
          if not ( values["whole_program"] == "") then
            if values["whole_program"] == "off" then
              jln_cxflags[#jln_cxflags+1] = "/ZI"
            else
              jln_cxflags[#jln_cxflags+1] = "/Zi"
            end
          else
            jln_cxflags[#jln_cxflags+1] = "/ZI"
          end
        end
      end
    end
    if not ( values["optimization"] == "") then
      if values["optimization"] == "0" then
        jln_cxflags[#jln_cxflags+1] = "/Ob0"
        jln_cxflags[#jln_cxflags+1] = "/Od"
        jln_cxflags[#jln_cxflags+1] = "/Oi-"
        jln_cxflags[#jln_cxflags+1] = "/Oy-"
      else
        if values["optimization"] == "g" then
          jln_cxflags[#jln_cxflags+1] = "/Ob1"
        else
          jln_cxflags[#jln_cxflags+1] = "/DNDEBUG"
          jln_cxflags[#jln_cxflags+1] = "/GF"
          if values["optimization"] == "1" then
            jln_cxflags[#jln_cxflags+1] = "/O1"
          else
            if values["optimization"] == "2" then
              jln_cxflags[#jln_cxflags+1] = "/O2"
            else
              if values["optimization"] == "3" then
                jln_cxflags[#jln_cxflags+1] = "/O2"
              else
                if values["optimization"] == "z" then
                  jln_cxflags[#jln_cxflags+1] = "/O3"
                else
                  if values["optimization"] == "size" then
                    jln_cxflags[#jln_cxflags+1] = "/Os"
                  else
                    if values["optimization"] == "fast" then
                      jln_cxflags[#jln_cxflags+1] = "/fast"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if not ( values["stack_protector"] == "") then
      if values["stack_protector"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "/GS-"
      else
        jln_cxflags[#jln_cxflags+1] = "/GS"
        if values["stack_protector"] == "strong" then
          jln_cxflags[#jln_cxflags+1] = "/RTC1"
        else
          if values["stack_protector"] == "all" then
            jln_cxflags[#jln_cxflags+1] = "/RTC1"
            jln_cxflags[#jln_cxflags+1] = "/RTCc"
          end
        end
      end
    end
    if not ( values["sanitizers"] == "") then
      if values["sanitizers"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/Qtrapuv"
      end
    end
    if not ( values["float_sanitizers"] == "") then
      if values["float_sanitizers"] == "on" then
        jln_cxflags[#jln_cxflags+1] = "/Qfp-stack-check"
        jln_cxflags[#jln_cxflags+1] = "/Qfp-trap:common"
      end
    end
    if not ( values["control_flow"] == "") then
      if values["control_flow"] == "off" then
        jln_cxflags[#jln_cxflags+1] = "/guard:cf-"
        jln_cxflags[#jln_cxflags+1] = "/mconditional-branch=keep"
      else
        jln_cxflags[#jln_cxflags+1] = "/guard:cf"
        if values["control_flow"] == "branch" then
          jln_cxflags[#jln_cxflags+1] = "/mconditional-branch:all-fix"
          jln_cxflags[#jln_cxflags+1] = "/Qcf-protection:branch"
        else
          if values["control_flow"] == "on" then
            jln_cxflags[#jln_cxflags+1] = "/mconditional-branch:all-fix"
            jln_cxflags[#jln_cxflags+1] = "/Qcf-protection:full"
          end
        end
      end
    end
    if not ( values["cpu"] == "") then
      if values["cpu"] == "generic" then
        jln_cxflags[#jln_cxflags+1] = "/Qtune:generic"
        jln_ldflags[#jln_ldflags+1] = "/Qtune:generic"
      else
        jln_cxflags[#jln_cxflags+1] = "/QxHost"
        jln_ldflags[#jln_ldflags+1] = "/QxHost"
      end
    end
  else
    if compiler == "icc" then
      if not ( values["warnings"] == "") then
        if values["warnings"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "-w"
        else
          jln_cxflags[#jln_cxflags+1] = "-Wall"
          jln_cxflags[#jln_cxflags+1] = "-Warray-bounds"
          jln_cxflags[#jln_cxflags+1] = "-Wcast-qual"
          jln_cxflags[#jln_cxflags+1] = "-Wchar-subscripts"
          jln_cxflags[#jln_cxflags+1] = "-Wdisabled-optimization"
          jln_cxflags[#jln_cxflags+1] = "-Wenum-compare"
          jln_cxflags[#jln_cxflags+1] = "-Wextra"
          jln_cxflags[#jln_cxflags+1] = "-Wfloat-equal"
          jln_cxflags[#jln_cxflags+1] = "-Wformat-security"
          jln_cxflags[#jln_cxflags+1] = "-Wformat=2"
          jln_cxflags[#jln_cxflags+1] = "-Winit-self"
          jln_cxflags[#jln_cxflags+1] = "-Winvalid-pch"
          jln_cxflags[#jln_cxflags+1] = "-Wmaybe-uninitialized"
          jln_cxflags[#jln_cxflags+1] = "-Wmissing-include-dirs"
          jln_cxflags[#jln_cxflags+1] = "-Wnarrowing"
          jln_cxflags[#jln_cxflags+1] = "-Wnonnull"
          jln_cxflags[#jln_cxflags+1] = "-Wparentheses"
          jln_cxflags[#jln_cxflags+1] = "-Wpointer-sign"
          jln_cxflags[#jln_cxflags+1] = "-Wreorder"
          jln_cxflags[#jln_cxflags+1] = "-Wsequence-point"
          jln_cxflags[#jln_cxflags+1] = "-Wtrigraphs"
          jln_cxflags[#jln_cxflags+1] = "-Wundef"
          jln_cxflags[#jln_cxflags+1] = "-Wunused-function"
          jln_cxflags[#jln_cxflags+1] = "-Wunused-but-set-variable"
          jln_cxflags[#jln_cxflags+1] = "-Wunused-variable"
          jln_cxflags[#jln_cxflags+1] = "-Wpointer-arith"
          jln_cxflags[#jln_cxflags+1] = "-Wdeprecated"
          jln_cxflags[#jln_cxflags+1] = "-Wnon-virtual-dtor"
          jln_cxflags[#jln_cxflags+1] = "-Woverloaded-virtual"
          if not ( values["switch_warnings"] == "") then
            if ( values["switch_warnings"] == "on" or values["switch_warnings"] == "exhaustive_enum" ) then
              jln_cxflags[#jln_cxflags+1] = "-Wswitch-enum"
            else
              if values["switch_warnings"] == "mandatory_default" then
                jln_cxflags[#jln_cxflags+1] = "-Wswitch-default"
              else
                if values["switch_warnings"] == "exhaustive_enum_and_mandatory_default" then
                  jln_cxflags[#jln_cxflags+1] = "-Wswitch"
                else
                  jln_cxflags[#jln_cxflags+1] = "-Wno-switch"
                end
              end
            end
          end
        end
      end
      if not ( values["warnings_as_error"] == "") then
        if values["warnings_as_error"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-Werror"
        else
          if values["warnings_as_error"] == "basic" then
            jln_cxflags[#jln_cxflags+1] = "-diag-error=1079,39,109"
          end
        end
      end
      if not ( values["pedantic"] == "") then
        if values["pedantic"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "-fgnu-keywords"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-gnu-keywords"
        end
      end
      if not ( values["shadow_warnings"] == "") then
        if values["shadow_warnings"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "-Wno-shadow"
        else
          if ( values["shadow_warnings"] == "on" or values["shadow_warnings"] == "all" ) then
            jln_cxflags[#jln_cxflags+1] = "-Wshadow"
          end
        end
      end
      if not ( values["stl_debug"] == "") then
        if not ( values["stl_debug"] == "off" ) then
          if ( values["stl_debug"] == "allow_broken_abi" or values["stl_debug"] == "allow_broken_abi_and_bugs" ) then
            jln_cxflags[#jln_cxflags+1] = "-D_GLIBCXX_DEBUG"
          else
            jln_cxflags[#jln_cxflags+1] = "-D_GLIBCXX_ASSERTIONS"
          end
        end
      end
      if not ( values["debug"] == "") then
        if values["debug"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "-g0"
        else
          jln_cxflags[#jln_cxflags+1] = "-g"
        end
      end
      if not ( values["optimization"] == "") then
        if values["optimization"] == "0" then
          jln_cxflags[#jln_cxflags+1] = "-O0"
        else
          if values["optimization"] == "g" then
            jln_cxflags[#jln_cxflags+1] = "-O1"
          else
            jln_cxflags[#jln_cxflags+1] = "-DNDEBUG"
            if values["optimization"] == "1" then
              jln_cxflags[#jln_cxflags+1] = "-O1"
            else
              if values["optimization"] == "2" then
                jln_cxflags[#jln_cxflags+1] = "-O2"
              else
                if values["optimization"] == "3" then
                  jln_cxflags[#jln_cxflags+1] = "-O3"
                else
                  if values["optimization"] == "z" then
                    jln_cxflags[#jln_cxflags+1] = "-fast"
                  else
                    if values["optimization"] == "size" then
                      jln_cxflags[#jln_cxflags+1] = "-Os"
                    else
                      if values["optimization"] == "fast" then
                        jln_cxflags[#jln_cxflags+1] = "-Ofast"
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      if not ( values["stack_protector"] == "") then
        if values["stack_protector"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "-fno-protector-strong"
          jln_cxflags[#jln_cxflags+1] = "-U_FORTIFY_SOURCE"
          jln_ldflags[#jln_ldflags+1] = "-fno-protector-strong"
        else
          jln_cxflags[#jln_cxflags+1] = "-D_FORTIFY_SOURCE=2"
          if values["stack_protector"] == "strong" then
            jln_cxflags[#jln_cxflags+1] = "-fstack-protector-strong"
            jln_ldflags[#jln_ldflags+1] = "-fstack-protector-strong"
          else
            if values["stack_protector"] == "all" then
              jln_cxflags[#jln_cxflags+1] = "-fstack-protector-all"
              jln_ldflags[#jln_ldflags+1] = "-fstack-protector-all"
            else
              jln_cxflags[#jln_cxflags+1] = "-fstack-protector"
              jln_ldflags[#jln_ldflags+1] = "-fstack-protector"
            end
          end
        end
      end
      if not ( values["relro"] == "") then
        if values["relro"] == "off" then
          jln_ldflags[#jln_ldflags+1] = "-Xlinker-znorelro"
        else
          if values["relro"] == "on" then
            jln_ldflags[#jln_ldflags+1] = "-Xlinker-zrelro"
          else
            if values["relro"] == "full" then
              jln_ldflags[#jln_ldflags+1] = "-Xlinker-zrelro"
              jln_ldflags[#jln_ldflags+1] = "-Xlinker-znow"
              jln_ldflags[#jln_ldflags+1] = "-Xlinker-znoexecstack"
            end
          end
        end
      end
      if not ( values["pie"] == "") then
        if values["pie"] == "off" then
          jln_ldflags[#jln_ldflags+1] = "-no-pic"
        else
          if values["pie"] == "on" then
            jln_ldflags[#jln_ldflags+1] = "-pie"
          else
            if values["pie"] == "fpie" then
              jln_cxflags[#jln_cxflags+1] = "-fpie"
            else
              if values["pie"] == "fpic" then
                jln_cxflags[#jln_cxflags+1] = "-fpic"
              else
                if values["pie"] == "fPIE" then
                  jln_cxflags[#jln_cxflags+1] = "-fPIE"
                else
                  if values["pie"] == "fPIC" then
                    jln_cxflags[#jln_cxflags+1] = "-fPIC"
                  end
                end
              end
            end
          end
        end
      end
      if not ( values["sanitizers"] == "") then
        if values["sanitizers"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-ftrapuv"
        end
      end
      if not ( values["integer_sanitizers"] == "") then
        if values["integer_sanitizers"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-funsigned-bitfields"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-unsigned-bitfields"
        end
      end
      if not ( values["float_sanitizers"] == "") then
        if values["float_sanitizers"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-fp-stack-check"
          jln_cxflags[#jln_cxflags+1] = "-fp-trap=common"
        end
      end
      if not ( values["linker"] == "") then
        if values["linker"] == "bfd" then
          jln_ldflags[#jln_ldflags+1] = "-fuse-ld=bfd"
        else
          if values["linker"] == "gold" then
            jln_ldflags[#jln_ldflags+1] = "-fuse-ld=gold"
          else
            jln_ldflags[#jln_ldflags+1] = "-fuse-ld=lld"
          end
        end
      end
      if not ( values["lto"] == "") then
        if values["lto"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "-no-ipo"
          jln_ldflags[#jln_ldflags+1] = "-no-ipo"
        else
          jln_cxflags[#jln_cxflags+1] = "-ipo"
          jln_ldflags[#jln_ldflags+1] = "-ipo"
          if values["lto"] == "fat" then
            if is_plat("linux") then
              jln_cxflags[#jln_cxflags+1] = "-ffat-lto-objects"
              jln_ldflags[#jln_ldflags+1] = "-ffat-lto-objects"
            end
          end
        end
      end
      if not ( values["control_flow"] == "") then
        if values["control_flow"] == "off" then
          jln_cxflags[#jln_cxflags+1] = "-mconditional-branch=keep"
          jln_cxflags[#jln_cxflags+1] = "-fcf-protection=none"
        else
          if values["control_flow"] == "branch" then
            jln_cxflags[#jln_cxflags+1] = "-mconditional-branch=all-fix"
            jln_cxflags[#jln_cxflags+1] = "-fcf-protection=branch"
          else
            if values["control_flow"] == "on" then
              jln_cxflags[#jln_cxflags+1] = "-mconditional-branch=all-fix"
              jln_cxflags[#jln_cxflags+1] = "-fcf-protection=full"
            end
          end
        end
      end
      if not ( values["exceptions"] == "") then
        if values["exceptions"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-fexceptions"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-exceptions"
        end
      end
      if not ( values["rtti"] == "") then
        if values["rtti"] == "on" then
          jln_cxflags[#jln_cxflags+1] = "-frtti"
        else
          jln_cxflags[#jln_cxflags+1] = "-fno-rtti"
        end
      end
      if not ( values["cpu"] == "") then
        if values["cpu"] == "generic" then
          jln_cxflags[#jln_cxflags+1] = "-mtune=generic"
          jln_ldflags[#jln_ldflags+1] = "-mtune=generic"
        else
          jln_cxflags[#jln_cxflags+1] = "-xHost"
          jln_ldflags[#jln_ldflags+1] = "-xHost"
        end
      end
    end
  end
  if is_plat("mingw") then
    if not ( values["windows_bigobj"] == "") then
      jln_cxflags[#jln_cxflags+1] = "-Wa,-mbig-obj"
    end
  end
  return {cxxflags=jln_cxflags, ldflags=jln_ldflags}
end

