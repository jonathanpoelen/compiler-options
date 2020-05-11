local tostrlvl=function(lvl)
  return lvl:gsub('_', '-')
end

return {
  -- ignore = { optimization=true, }

  tostroption=function(_, optname)
    return _.optprefix .. optname:gsub('_', '-')
  end,

  start=function(_, optprefix)
    _.optprefix = optprefix or ''
    _:_vcond_init({
      _not='not',
      _and='and',
      _or='or',
      openblock='',
      closeblock='',
      ifopen='',
      ifclose='then',
      endif='end',
    })

    _:print('-- File generated with https://github.com/jonathanpoelen/cpp-compiler-options\n')

    local prefixfunc = _.is_C and 'jln_c' or 'jln'

    _:print('local _' .. prefixfunc .. '_flag_names = {}')
    for optname in _:getoptions() do
      local opt = _:tostroption(optname)
      _:print('_' .. prefixfunc .. '_flag_names["' .. opt .. '"] = true')
      if opt ~= optname then
        _:print('_' .. prefixfunc .. '_flag_names["' .. optname .. '"] = true')
      end
    end

    _:print('\nfunction ' .. prefixfunc .. '_newoptions(defaults)')
    _:print('  if defaults then')
    _:print('    jln_check_flag_names(defaults)')
    _:print('  else')
    _:print('    defaults = {}')
    _:print('  end')
    for optname,args in _:getoptions() do
      local opt = _:tostroption(optname)
      _:print('  newoption{trigger="' .. opt .. '", allowed={{"' ..  table.concat(args, '"}, {"') .. '"}}, description="' .. optname .. '"}')
      _:print('  if not _OPTIONS["' .. opt .. '"] then _OPTIONS["' .. opt .. '"] = (defaults["' .. optname .. '"] ' .. (opt ~= optname and 'or defaults["' .. opt .. '"]' or '') .. ' or "' .. args[1] .. '") end')
    end
    _:print('  newoption{trigger="' .. _.optprefix .. 'compiler", description="Path or name of the compiler"}')
    _:print('  newoption{trigger="' .. _.optprefix .. 'compiler-version", description="Force the compiler version"}')
    _:print('end\n')

    _:print([[
function ]] .. prefixfunc .. [[_check_flag_names(t)
  for k in pairs(t) do
    if not _]] .. prefixfunc .. [[_flag_names[k] then
      error("unknown '" .. k .. "' jln flag name")
    end
  end
end

-- same as ]] .. prefixfunc .. [[_getoptions
function ]] .. prefixfunc .. [[_setoptions(compiler, version, values, disable_others, print_compiler)
  local options = jln_getoptions(compiler, version, values, disable_others, print_compiler)
  buildoptions(options.buildoptions)
  linkoptions(options.linkoptions)
  return options
end

-- ]] .. prefixfunc .. [[_getoptions(values, disable_others = nil, print_compiler = nil)
-- ]] .. prefixfunc .. [[_getoptions(compiler, version = nil, values = nil, disable_others = nil, print_compiler = nil)
-- `= nil` indicates that the value is optional and can be nil
-- `compiler`: string. ex: 'gcc', 'g++', 'clang++', 'clang'
-- `version`: string. ex: '7', '7.2'
-- `values`: table. ex: {warnings='on'}
-- `disable_others`: boolean
-- `print_compiler`: boolean
-- return {buildoptions=string, linkoptions=string}
function ]] .. prefixfunc .. [[_getoptions(compiler, version, values, disable_others, print_compiler)
  if compiler and type(compiler) ~= 'string' then
    values, disable_others, print_compiler, compiler, version = compiler, version, values, nil, nil
  end

  if not compiler then
    compiler = _OPTIONS[']] .. _:tostroption'compiler' .. [['] or _OPTIONS['cc'] or 'g++'
    version = _OPTIONS[']] .. _:tostroption'compiler-version' .. [['] or nil
  elseif compiler == 'gcc' then compiler = 'g++'
  elseif compiler == 'clang' then compiler = 'clang++'
  end

  local compversion = {}
  if not version then
     local output = os.outputof(compiler .. " --version")
     if output then
       output = output:sub(0, output:find('\n') or #output)
       version = output:gsub(".*(%d+%.%d+%.%d+).*", "%1")
     else
       printf("WARNING: `%s --version` failed", compiler)
       output = compiler:gmatch(".*%-(%d+%.?%d*%.?%d*)$")()
       if output then
         version = output
         printf("Extract version %s of the compiler name", version)
       end
     end
  end

  compiler = (compiler:find('clang', 1, true) and 'clang') or
             ((compiler:find('g++', 1, true) or
               compiler:find('gcc', 1, true) or
               compiler:find('GCC', 1, true) or
               compiler:find('MinGW', 1, true) or
               compiler:find('mingw', 1, true)
              ) and 'gcc') or
             nil

  if not compiler then
    printf("WARNING: unknown compiler")
    return {buildoptions='', linkoptions=''}
  end

  if not version then
    version = tostring(tonumber(os.date("%y")) - (compiler == 'clang' and 14 or 12))
  end

  if print_compiler then
    printf("getoptions: compiler: %s, version: %s", compiler, version)
  end

  for i in version:gmatch("%d+") do
    compversion[#compversion+1] = tonumber(i)
  end
  if not compversion[1] then
    printf("WARNING: wrong version format")
    return {buildoptions='', linkoptions=''}
  end
  compversion = compversion[1] * 100 + (compversion[2] or 0)

  if values then
    jln_check_flag_names(values)
    local name_list = {}
    local new_value = {}]])
    for optname,args in _:getoptions() do
      local opt = _:tostroption(optname)
      _:print('    name_list["' .. opt .. '"] = true')
      local isnotsamename = (opt ~= optname)
      if isnotsamename then
        _:print('    name_list["' .. optname .. '"] = true')
      end
      _:print('    new_value["' .. opt .. '"] = values["' .. optname .. '"] ' .. (isnotsamename and 'or values["' .. opt .. '"] ' or '') .. 'or (disable_others and "default" or _OPTIONS["' .. opt .. '"])')
    end
    _:print([[
    values = new_value
  else
    values = _OPTIONS
  end

  local jln_buildoptions, jln_linkoptions = '', ''
]])
  end,

  _vcond_lvl=function(_, lvl, optname) return 'values["' .. _:tostroption(optname) .. '"] == "' .. tostrlvl(lvl) .. '"' end,
  _vcond_verless=function(_, major, minor) return 'compversion < ' .. tostring(major * 100 + minor) end,
  _vcond_comp=function(_, compiler) return 'compiler == "' .. compiler .. '"' end,

  cxx=function(_, x) return ' ' .. x end,
  link=function(_, x) return ' ' .. x end,

  _vcond_toflags=function(_, cxx, links)
    return (#cxx ~= 0 and _.indent .. '  jln_buildoptions = jln_buildoptions .. "' .. cxx .. '"\n' or '')
        .. (#links ~= 0                  and _.indent .. '  jln_linkoptions = jln_linkoptions .. "' .. links .. '"\n' or '')
  end,

  stop=function(_)
    return _:get_output() .. '  return {buildoptions=jln_buildoptions, linkoptions=jln_linkoptions}\nend\n'
  end,
}
