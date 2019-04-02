#!/usr/bin/env lua
local cond_mt = {
  __call = function(_, x)
    if _._t then error('`t` is not nil') end
    _._t = x
    return _
  end,
  __div = function(_, x)
    local t = _._else
    if t then t[#t+1] = x
    else _._else = {x} end
    return _
  end,
  __mul = function(_, x)
    local t = _._c or _._t
    t[#t+1] = x
    _._c = x._t
    return _
  end,
  __unm = function(_)
    return setmetatable({ _not=_, _t=_._t }, cond_mt)
  end,
}

local comp_mt = {
  __call = function(_, x_or_major, minor)
    if type(x_or_major) == 'number' then
      return setmetatable({ _and = { { compiler=_.compiler }, { version={x_or_major, minor or 0} } } }, cond_mt)
    else
      return setmetatable({ compiler=_.compiler, _t=x_or_major }, cond_mt)
    end
  end,
  __div = function(_, x)
    return _({}) / x
  end,
  __mul = function(_, x)
    return _({}) * x
  end,
  __unm = function(_)
    return -_({})
  end,
}

function compiler(name) return setmetatable({ compiler=name }, comp_mt) end

local gcc = compiler('gcc')
local clang = compiler('clang')
local msvc = compiler('msvc')
function vers(major, minor) return setmetatable({ version={major, minor or 0} }, cond_mt) end
function cxx(x) return { cxx=x } end
function link(x) return { link=(x:match('^[-/]') and x or '-l'..x) } end
function fl(x) return { cxx=x, link=x } end
function lvl(x) return setmetatable({ lvl=x }, cond_mt) end
function opt(x) return setmetatable({ opt=x }, cond_mt) end
function Or(...) return setmetatable({ _or={...} }, cond_mt) end

-- opt'build' ? -pipe Avoid temporary files, speeding up builds

-- gcc and clang
-- g++ -Q --help=optimizers,warnings,target,params,common,undocumented,joined,separate,language__ -O3
G = Or(gcc, clang) {
  opt'narrowing_error' {
    lvl'on' { gcc(4,7) { cxx'-Werror=narrowing' } } /
    clang { cxx'-Wno-error=c++11-narrowing' }
  },

  opt'coverage' {
    lvl'on' {
      cxx'--coverage', -- -fprofile-arcs -ftest-coverage
      link'--coverage', -- -lgcov
      clang {
        link'-lprofile_rt',
        -- fl'-fprofile-instr-generate',
        -- fl'-fcoverage-mapping',
      },
    },
  },

  opt'debug' {
    lvl'off' { cxx '-g0' } /
    lvl'gdb' { cxx '-ggdb' } /
    clang {
      lvl'line_tables_only' { cxx'-gline-tables-only' },
      lvl'lldb' { cxx '-glldb' } /
      lvl'sce' { cxx '-gsce' } /
      cxx'-g'
    } /
    cxx'-g',
    -- cxx'-fasynchronous-unwind-tables', -- Increased reliability of backtraces
  },

  opt'linker' {
    lvl'bfd' { link'-fuse-ld=bfd' } /
    Or(lvl'gold', gcc) { link'-fuse-ld=gold' } /
    link'-fuse-ld=lld',
  },

  opt'lto' {
    lvl'off' {
      fl'-fno-lto',
    } / {
      fl'-flto', -- clang -flto=thin
      gcc(5) {
        opt'warnings' {
          -lvl'off' { fl'-flto-odr-type-merging' }, -- increases size of LTO object files, but enables diagnostics about ODR violations
        },
        lvl'fat' { cxx'-ffat-lto-objects', },
        lvl'linker_plugin' { link'-fuse-linker-plugin' }
      }
    },
  },

  opt'optimize' {
    lvl'off'     { fl'-O0' } /
    lvl'debugoptimized' { fl'-Og' } / {
      cxx'-DNDEBUG',
      lvl'minsize' { fl'-Os' } /
      lvl'fast'    { fl'-Ofast' } /
      lvl'release' { fl'-O3' }
    }
  },

  opt'cpu' {
    lvl'generic' { fl'-mtune=generic' } /
    { fl'-march=native', fl'-mtune=native', }
  },

  opt'whole_program' {
    lvl'off' {
      cxx'-fno-whole-program',
      clang(3,9) { fl'-fno-whole-program-vtables' }
    } /
    {
      link'-s',
      lvl'strip_all'{
        link'-Wl,--gc-sections',
        link'-Wl,--strip-all',
      },
      gcc {
        fl'-fwhole-program'
      } / {
        clang(3,9) {
          opt'lto'{
            -lvl'off' {
              fl'-fwhole-program-vtables'
            }
          }
        }*    
        vers(7) {
          fl'-fforce-emit-vtables',
        }
      }
    }
  },

  opt'pedantic' {
    -lvl'off' {
      cxx'-pedantic',
      lvl'as_error' {
        cxx'-pedantic-errors',
      },
    },
  },

  opt'stack_protector' {
    lvl'off' {
      fl'-Wno-stack-protector',
      cxx'-U_FORTIFY_SOURCE'
    } /
    {
      cxx'-D_FORTIFY_SOURCE=2',
      cxx'-Wstack-protector',
      lvl'strong' {
        gcc(4,9) {
          fl'-fstack-protector-strong',
        } /
        clang {
          fl'-fstack-protector-strong',
          fl'-fsanitize=safe-stack',
        }
      } /
      lvl'all' {
        fl'-fstack-protector-all',
        clang {
          fl'-fsanitize=safe-stack',
        }
      } /
      fl'-fstack-protector',
    },
  },

  opt'relro' {
    lvl'off' { link'-Wl,-z,norelro', } /
    lvl'on'  { link'-Wl,-z,relro', } /
    lvl'full'{ link'-Wl,-z,relro,-z,now', },
  },

  opt'pie' {
    lvl'off'{ link'-no-pic', } /
    lvl'on' { link'-pie', } /
    lvl'pic'{ cxx'-fPIC', },
  },

  opt'suggests' {
    -lvl'off' {
      gcc {
        cxx'-Wsuggest-attribute=pure',
        cxx'-Wsuggest-attribute=const',
      }*
      vers(5) {
        cxx'-Wsuggest-final-types',
        cxx'-Wsuggest-final-methods',
     -- cxx'-Wsuggest-attribute=format',
      }*
      vers(5,1) {
        cxx'-Wnoexcept',
      },
    },
  },

  opt'stl_debug' {
    -lvl'off' {
      cxx'-D_LIBCPP_DEBUG=1',
      lvl'assert_as_exception' {
        cxx'-D_LIBCPP_DEBUG_USE_EXCEPTIONS'
      },
      lvl'allow_broken_abi' { cxx'-D_GLIBCXX_DEBUG', } / cxx'-D_GLIBCXX_ASSERTIONS',
      opt'pedantic' {
        -lvl'off' {
          cxx'-D_GLIBCXX_DEBUG_PEDANTIC'
        },
      },
    },
  },

  opt'shadow' {
    lvl'off' { cxx'-Wno-shadow' } /
    lvl'on' { cxx'-Wshadow' } /
    lvl'all' {
      clang { cxx'-Wshadow-all', } /
      cxx'-Wshadow'
    } /
    gcc(7,1) {
      lvl'local' {
        cxx'-Wshadow=local'
      } /
      lvl'compatible_local' {
        cxx'-Wshadow=compatible-local'
      }
    }
  },

  opt'warnings' {
    lvl'off' {
      cxx'-w'
    } / {
      gcc {
        cxx'-Wall',
        cxx'-Wextra',
        cxx'-Wcast-align',
        cxx'-Wcast-qual',
        cxx'-Wdisabled-optimization',
        cxx'-Wfloat-equal',
        cxx'-Wformat-security',
        cxx'-Wformat=2',
        cxx'-Wmissing-declarations',
        cxx'-Wmissing-include-dirs',
        cxx'-Wnon-virtual-dtor',
        cxx'-Wold-style-cast',
        cxx'-Woverloaded-virtual',
     -- cxx'-Weffc++',
        cxx'-Wpacked',
        cxx'-Wredundant-decls',
        cxx'-Wundef',
        cxx'-Wunused-macros',
     -- cxx'-Winline',
     -- cxx'-Wswitch-default',
     -- cxx'-Wswitch-enum',
      }*

      vers(4,7) {
        cxx'-Wsuggest-attribute=noreturn',
        cxx'-Wzero-as-null-pointer-constant',
        cxx'-Wlogical-op',
     -- cxx'-Wno-aggressive-loop-optimizations',
     -- cxx'-Wnormalized=nfc',
        cxx'-Wvector-operation-performance',
        cxx'-Wdouble-promotion',
        cxx'-Wtrampolines', -- C only with a nested function ?
      }*

      vers(4,8) {
        cxx'-Wuseless-cast',
      }*

      vers(4,9) {
        cxx'-Wconditionally-supported',
        cxx'-Wfloat-conversion',
      }*

      vers(5,1) {
        cxx'-Wformat-signedness',
        cxx'-Warray-bounds=2', -- This option is only active when -ftree-vrp is active (default for -O2 and above). level=1 enabled by -Wall.
        cxx'-Wconditionally-supported',
     -- cxx'-Wctor-dtor-privacy',
        cxx'-Wstrict-null-sentinel',
        cxx'-Wsuggest-override',
      }*

      vers(6,1) {
        cxx'-Wduplicated-cond',
        cxx'-Wnull-dereference', -- This option is only active when -fdelete-null-pointer-checks is active, which is enabled by optimizations in most targets.
      }*

      vers(7) {
        cxx'-Waligned-new',
      }*

      vers(7,1) {
        cxx'-Walloc-zero',
        cxx'-Walloca',
        cxx'-Wformat-overflow=2',
     -- cxx'-Wformat-truncation=1', -- enabled by -Wformat. Works best with -O2 and higher. =2 = calls to bounded functions whose return value is used
     -- cxx'-Wformat-y2k', -- strftime formats that may yield only a two-digit year.
        cxx'-Wduplicated-branches',
      }*

      vers(8) {
        cxx'-Wclass-memaccess',
      }

      / -- clang
      {
        cxx'-Weverything',
     -- cxx'-Wno-documentation-unknown-command',
     -- cxx'-Wno-range-loop-analysis',
     -- cxx'-Wno-disabled-macro-expansion',
        cxx'-Wno-c++98-compat',
        cxx'-Wno-c++98-compat-pedantic',
        cxx'-Wno-mismatched-tags',
        cxx'-Wno-padded',
        cxx'-Wno-global-constructors',
        cxx'-Wno-weak-vtables',
        cxx'-Wno-exit-time-destructors',
        cxx'-Wno-covered-switch-default',
     -- cxx'-Qunused-arguments',
        cxx'-Wno-switch-default',
        cxx'-Wno-switch-enum',
        cxx'-Wno-inconsistent-missing-destructor-override',
      },

      Or(lvl'strict', lvl'very_strict') {
        cxx'-Wconversion',
        gcc(8) { cxx'-Wcast-align=strict', }
      } /
      clang {
        cxx'-Wno-conversion',
        cxx'-Wno-sign-conversion',
      },
    },
  },

  opt'sanitizers' {
    lvl'off' {
      fl'-fno-sanitize=all'
    } / {
      clang {
        vers(3,1) {
          fl'-fsanitize=undefined',
          fl'-fsanitize=address', -- memory, thread are mutually exclusive
          cxx'-fsanitize-address-use-after-scope',
          cxx'-fno-omit-frame-pointer',
          cxx'-fno-optimize-sibling-calls',
        }*
        vers(3,4) {
          fl'-fsanitize=leak', -- requires the address sanitizer
        }*
        vers(6) {
          fl'-fsanitize=bounds',
        },
      } /
      -- gcc
      {
        vers(4,8) {
          fl'-fsanitize=address', -- memory, thread are mutually exclusive
          cxx'-fno-omit-frame-pointer',
          cxx'-fno-optimize-sibling-calls',
        }*
        vers(4,9) {
          fl'-fsanitize=undefined',
          fl'-fsanitize=leak', -- requires the address sanitizer
        }*
        vers(6) {
          cxx'-fsanitize=bounds',
          cxx'-fsanitize=bounds-strict',
        }
      },
    },
  },

  opt'control_flow' {
    lvl'off' {
      gcc(8) { cxx'-fcf-protection=none' },
      clang { fl'-fno-sanitize=cfi' },
    } /
    {
      gcc(8) {
        -- cxx'-mcet',
        cxx'-fcf-protection=full' --  full|branch|return|none
      },
      clang {
        fl'-fsanitize=cfi', -- cfi-* only allowed with '-flto' and '-fvisibility=...'
        cxx'-fvisibility=hidden',
        fl'-flto',
      }, 
    },
  },

  opt'sanitizers_extra' {
    lvl'thread' { cxx'-fsanitize=thread', } /
    lvl'pointer' {
      gcc(8) {
        -- By default the check is disabled at run time.
        -- To enable it, add "detect_invalid_pointer_pairs=2" to the environment variable ASAN_OPTIONS.
        -- Using "detect_invalid_pointer_pairs=1" detects invalid operation only when both pointers are non-null.
        -- These options cannot be combined with -fsanitize=thread and/or -fcheck-pointer-bounds
        -- ASAN_OPTIONS=detect_invalid_pointer_pairs=2
        -- ASAN_OPTIONS=detect_invalid_pointer_pairs=1
        cxx'-fsanitize=pointer-compare',
        cxx'-fsanitize=pointer-subtract',
      }
    }
  },

  opt'reproductible_build_warnings' {
    gcc(4,9) {
      lvl'on' { cxx'-Wdate-time' } / cxx'-Wno-date-time'
    }
  },

  opt'color' {    
    Or(gcc(4,9), clang) {
      lvl'auto' { cxx'-fdiagnostics-color=auto' } /
      lvl'never' { cxx'-fdiagnostics-color=never' } /
      lvl'always' { cxx'-fdiagnostics-color=always' },
    },
  },

  opt'elide_type' {
    Or(gcc(8), clang(3,4)) {
      lvl'on' { cxx'-felide-type' } / cxx'-fno-elide-type',
    },
  },

  opt'exceptions' {
    lvl'on' { cxx'-fexceptions', } / cxx'-fno-exceptions',
  },

  opt'rtti' {
    lvl'on' { cxx'-frtti' } / cxx'-fno-rtti',
  },

  opt'diagnostics_show_template_tree' {
    Or(gcc(8), clang) {
      lvl'on' { cxx'-fdiagnostics-show-template-tree' } / cxx'-fno-diagnostics-show-template-tree',
    },
  },

  opt'diagnostics_format' {
    lvl'fixits' {
      Or(gcc(7), clang(5)) {
        cxx'-fdiagnostics-parseable-fixits'
      }
    } /
    lvl'patch', {
      gcc(7) { cxx'-fdiagnostics-generate-patch' }
    } /
    lvl'print_source_range_info' {
      clang { cxx'-fdiagnostics-print-source-range-info' }
    }
  },

  opt'warnings_as_error' {
    lvl'on' { cxx'-Werror', } / cxx'-Wno-error',
  }
} /

msvc {
  opt'stl_fix' {
    lvl'on' { cxx'/DNOMINMAX', },
  },

  opt'debug' {
    lvl'off' { cxx'/DEBUG:NONE' } / {
      cxx'/RTC1',
      cxx'/Od',
      lvl'on' { cxx'/DEBUG' } / -- /DEBUG:FULL
      lvl'line_tables_only' { cxx'/DEBUG:FASTLINK' },
      opt'optimize' { lvl'debugoptimized' { cxx'/Zi' } / cxx'/ZI' } / cxx'/ZI',
    }
  },

  opt'exceptions'{
    lvl'on' { cxx'/EHc' } / { cxx'/EHc-' }
  },

  opt'optimize' {
    lvl'off' { cxx'/Ob0 /Od /Oi- /Oy-' } /
    lvl'debugoptimized' { cxx'/Ob1' } / {
      cxx'/DNDEBUG',
      -- /O1 = /Og      /Os  /Oy /Ob2 /GF /Gy
      -- /O2 = /Og /Oi  /Ot  /Oy /Ob2 /GF /Gy
      lvl'release' { cxx'/O2', fl'/OPT:REF', } /
      lvl'minsize' { cxx'/O1', fl'/OPT:REF', cxx'/Gw' } /
      lvl'fast' { cxx'/O2', fl'/OPT:REF', cxx'/fp:fast' }
    }
  },

  opt'whole_program' {
    lvl'off' { cxx'/GL-' } /
    { cxx'/GL', cxx'/Gw' }
  },

  opt'pedantic' {
    -lvl'off' {
      cxx'/permissive-', -- implies /Zc:rvaluecast, /Zc:strictstrings, /Zc:ternary, /Zc:twoPhase
      cxx'/Zc:__cplusplus',
      -- cxx'/Zc:throwingNew',
    }
  },

  opt'rtti' {
    lvl'on' { cxx'/GR' } / { cxx'/GR-' }
  },

  opt'stl_debug' {
    lvl'off' { 
      cxx'/D_HAS_ITERATOR_DEBUGGING=0'
    } / {
      cxx'/D_DEBUG', -- set by /MDd /MTd or /LDd
      cxx'/D_HAS_ITERATOR_DEBUGGING=1',
    }
  },

  opt'control_flow' {
    lvl'off' { cxx'/guard:cf-', } /
    cxx'/guard:cf',
  },

  opt'sanitizers' {
    lvl'on' {
      cxx'/sdl',
    } /
    opt'stack_protector' {
      -lvl'off' { cxx'/sdl-' },
    },
  },

  opt'stack_protector' {
    -lvl'off' {
      cxx'/GS',
      cxx'/sdl',
      lvl'strong' { cxx'/RTC1', } / -- /RTCsu
      lvl'all' { cxx'/RTC1', cxx'/RTCc', },
    },
  },

  opt'shadow' {
    lvl'off' {
      cxx'/wd4456', cxx'/wd4459'
    } /
    Or(lvl'on', lvl'all') {
      cxx'/w4456', cxx'/w4459'
    } /
    lvl 'local' {
      cxx'/w4456', cxx'/wd4459'
    }
  },

  opt'warnings' {
    lvl'on' { cxx'/W4', cxx'/wd4244', cxx'/wd4245' } /
    lvl'strict' { cxx'/Wall', cxx'/wd4820', cxx'/wd4514', cxx'/wd4710' } /
    lvl'very_strict' { cxx'/Wall' } /
    lvl'off' { cxx'/W0' },
  },

  opt'warnings_as_error' {
    lvl'on' { fl'/WX' } / { cxx'/WX-' }
  },
}


function noop() end

Vbase = {
  _incidental={
    color=true,
    diagnostics_format=true,
    diagnostics_show_template_tree=true,
    elide_type=true,
    linker=true,
    reproductible_build_warnings=true,
    shadow=true,
    suggests=true,
    warnings=true,
    warnings_as_error=true,
  },

  _opts={
    color=      {{'auto', 'never', 'always'},},
    control_flow={{'off', 'on'},},
    coverage=   {{'off', 'on'},},
    cpu=        {{'generic', 'native'},},
    debug=      {{'off', 'on', 'line_tables_only', 'gdb', 'lldb', 'sce'},},
    diagnostics_format={{'fixits', 'patch', 'print_source_range_info'},},
    diagnostics_show_template_tree={{'off', 'on'},},
    elide_type= {{'off', 'on'},},
    exceptions= {{'off', 'on'},},
    linker=     {{'bfd', 'gold', 'lld'},},
    lto=        {{'off', 'on', 'fat', 'linker_plugin'},},
    narrowing_error={{'off', 'on'}, 'on'},
    optimize=   {{'off', 'debugoptimized', 'minsize', 'release', 'fast'},},
    pedantic=   {{'off', 'on', 'as_error'}, 'on'},
    pie=        {{'off', 'on', 'pic'},},
    relro=      {{'off', 'on', 'full'},},
    reproductible_build_warnings={{'off', 'on'},},
    rtti=       {{'off', 'on'},},
    stl_debug=  {{'off', 'on', 'allow_broken_abi', 'assert_as_exception'},},
    stl_fix=    {{'off', 'on'}, 'on'},
    sanitizers= {{'off', 'on'},},
    sanitizers_extra={{'off', 'thread', 'pointer'},},
    shadow=     {{'off', 'on', 'local', 'compatible_local', 'all'}, 'off'},
    stack_protector= {{'off', 'on', 'strong', 'all'},},
    suggests=   {{'off', 'on'},},
    warnings=   {{'off', 'on', 'strict', 'very_strict'}, 'on'},
    warnings_as_error={{'off', 'on'},},
    whole_program={{'off', 'on', 'strip_all'},},
  },

  indent = '',
  if_prefix = '',
  ignore={},

  start=noop, -- function(_) end,
  stop=function(_, filebase) return _:get_output() end,

  _strs={},
  print=function(_, s) _:write(s) _:write('\n') end,
  write=function(_, s) _._strs[#_._strs+1] = s end,
  get_output=function(_) return table.concat(_._strs) end,

  startopt=noop, -- function(_, name) end,
  stopopt=noop, -- function(_) end,

  startcond=noop, -- function(_, x, optname) end,
  elsecond=noop, -- function(_, optname) end,
  markelseif=noop, -- function() end,
  stopcond=noop, -- function(_, optname) end,

  cxx=noop,
  link=noop,

  _vcond_init=function(_, keywords)
    _._vcondkeyword = keywords or {}
    for k,v in pairs({
     _or = '||',
     _and = '&&',
     _not = '!',
     _if = 'if',
     _else = 'else',
     open = '(',
     close = ')',
     openblock = '{',
     closeblock = '}',
    }) do
      if not _._vcondkeyword[k] then
        _._vcondkeyword[k] = v
      end
    end
    _._vcondkeyword.ifopen = _._vcondkeyword.ifopen or _._vcondkeyword.open
    _._vcondkeyword.ifclose = _._vcondkeyword.ifclose or _._vcondkeyword.close
    _._vcondkeyword.else_of_else_if = _._vcondkeyword.else_of_else_if or (_._vcondkeyword._else .. ' ')
    _._vcondkeyword.endif = _._vcondkeyword.endif or _._vcondkeyword.closeblock
    if #_._vcondkeyword.ifopen ~= 0 then _._vcondkeyword.ifopen = ' ' .. _._vcondkeyword.ifopen .. ' ' end
    if #_._vcondkeyword.ifclose ~= 0 then _._vcondkeyword.ifclose = ' ' .. _._vcondkeyword.ifclose end

    local write_logical=function(_,a,k,optname)
      _:write(' '.._._vcondkeyword.open)
      _:_vcond(a[1], optname)
      for i=2,#a do
        _:write(' '..k)
        _:_vcond(a[i], optname)
      end
      _:write(' '.._._vcondkeyword.close)
    end

    _._vcond=function(_, v, optname)
          if v._or      then write_logical(_, v._or, _._vcondkeyword._or, optname)
      elseif v._and     then write_logical(_, v._and, _._vcondkeyword._and, optname)
      elseif v._not     then _:write(' '.._._vcondkeyword._not) ; _:_vcond(v._not, optname);
      elseif v.lvl      then _:write(' '.._:_vcond_lvl(v.lvl, optname))
      elseif v.version  then _:write(' '.._._vcondkeyword._not..' '.._._vcondkeyword.open..' '.._:_vcond_verless(v.version[1], v.version[2])..' '.._._vcondkeyword.close)
      elseif v.compiler then _:write(' '.._:_vcond_comp(v.compiler))
      else error('Unknown cond ', ipairs(v))
      end
    end

    _._vcond_hasopt = _._vcond_hasopt or function(_, optname)
      return _._vcondkeyword._not..' '.._._vcondkeyword.open..' '.._:_vcond_lvl('default', optname).._._vcondkeyword.close
    end

    _.startopt=function(_, optname)
      _:_vcond_printflags()
      _:print(_.indent .. _._vcondkeyword._if .. _._vcondkeyword.ifopen .. ' ' .. _:_vcond_hasopt(optname) .. _._vcondkeyword.ifclose)
      if #_._vcondkeyword.openblock ~= 0 then
        _:print(_.indent .. _._vcondkeyword.openblock)
      end
    end

    _.startcond=function(_, x, optname)
      _.indent = _.indent:sub(1, #_.indent-2)
      _:_vcond_printflags()
      _.indent = _.indent .. '  '
      _:write(_.indent .. _.if_prefix .. _._vcondkeyword._if .. _._vcondkeyword.ifopen)
      _.if_prefix = ''
      _:_vcond(x, optname)
      _:print(_._vcondkeyword.ifclose)
      if #_._vcondkeyword.openblock ~= 0 then
        _:print(_.indent .. _._vcondkeyword.openblock)
      end
    end

    _.elsecond=function(_)
      _:_vcond_printflags()
      if #_._vcondkeyword.closeblock ~= 0 then
        _:print(_.indent .. _._vcondkeyword.closeblock)
      end
      _:print(_.indent .. _._vcondkeyword._else)
      if #_._vcondkeyword.openblock ~= 0 then
        _:print(_.indent .. _._vcondkeyword.openblock)
      end
    end

    _.markelseif=function(_)
      _:_vcond_printflags()
      if #_._vcondkeyword.closeblock ~= 0 then
        _:print(_.indent .. _._vcondkeyword.closeblock)
      end
      _.if_prefix = _._vcondkeyword.else_of_else_if
    end

    _.stopcond=function(_)
      _:_vcond_printflags()
      if #_._vcondkeyword.endif ~= 0 then
        _:print(_.indent .. _._vcondkeyword.endif)
      end
    end

    _._vcond_flags_cxx = ''
    _._vcond_flags_link = ''
    _._vcond_printflags=function(_)
      if #_._vcond_flags_cxx ~= 0 or #_._vcond_flags_link ~= 0 then
        local s = _:_vcond_toflags(_._vcond_flags_cxx, _._vcond_flags_link)
        if s and #s ~= 0 then _:print(s) end
      end
      _._vcond_flags_cxx = ''
      _._vcond_flags_link = ''
    end

    local accu=function(k, f)
      return function(_, x)
        _[k] = _[k] .. f(_, x)
      end
    end

    _.cxx = accu('_vcond_flags_cxx', _.cxx)
    _.link = accu('_vcond_flags_link', _.link)
  end,

  _computed_options = nil,
  -- iterator: optname,args,default_value,ordered_args
  getoptions=function(_)
    local computed_options = _.__computed_options

    if not computed_options then
      local ordered_keys = {}

      for k in pairs(_._opts) do
        table.insert(ordered_keys, k)
      end

      table.sort(ordered_keys)

      computed_options = {}
      _._computed_options = computed_options
      local ignore = _.ignore

      for i,k in ipairs(ordered_keys) do
        if not ignore[k] then
          local v = _._opts[k]
          local ordered_args = v[1]
          local default_value = v[2] or 'default'
          if default_value ~= v[1][1] then
            ordered_args = {default_value}
            for i,arg in ipairs(v[1]) do
              if arg ~= default_value then
                ordered_args[#ordered_args + 1] = arg
              end
            end
          end
          computed_options[#computed_options + 1] = {k, v[1], default_value, ordered_args}
        end
      end
      -- nil value for iterator
      computed_options[#computed_options + 1] = {nil,nil,nil,nil}
    end

    local i = 0
    return function()
      i = i + 1
      local xs = computed_options[i]
      return xs[1], xs[2], xs[3], xs[4]
    end
  end,
}

local opts_krev = {}
for k,args in pairs(Vbase._opts) do
  local u = {}
  for _, v in ipairs(args[1]) do
    u[v] = true
  end
  if u['default'] then
    error('_opts[' .. k .. '] integrity error: "default" value is used')
  end
  table.insert(args[1], 1, 'default')
  opts_krev[k] = u
  opts_krev[k]['default'] = true
end
Vbase._opts_krev = opts_krev


function is_cond(t)
  return t.lvl or t._or or t._and or t._not or t.compiler or t.version
end

function evalflagselse(t, v, curropt)
  local n = #t._else
  for k,x in ipairs(t._else) do
    mark_elseif = (k ~= n or is_cond(x))
    if mark_elseif then
      v:markelseif()
      evalflags(x, v, curropt, mark_elseif)
    else
      v:elsecond(curropt)
      v.indent = v.indent .. '  '
      evalflags(x, v, curropt, mark_elseif)
      v.indent = v.indent:sub(1, #v.indent-2)
    end
  end
end

function evalflags(t, v, curropt, no_stopcond)
  if is_cond(t) then
    if t.lvl and not opts_krev[curropt][t.lvl] then
       error('Unknown lvl "' .. t.lvl .. '" in ' .. curropt)
    end
    local r = v:startcond(t, curropt)
    if r ~= false and t._t then
      v.indent = v.indent .. '  '
      evalflags(t._t, v, curropt)
      v.indent = v.indent:sub(1, #v.indent-2)
    end
    if r ~= true and t._else then
      evalflagselse(t, v, curropt)
    end
    if not no_stopcond then
      v:stopcond(curropt)
    end
  elseif t.opt then
    if not v._opts[t.opt] then
      error('Unknown "' .. t.opt .. '" option')
    end
    if not v.ignore[t.opt] then
      local r = v:startopt(t.opt)
      if r ~= false then
        v.indent = v.indent .. '  '
        evalflags(t._t, v, t.opt)
        v.indent = v.indent:sub(1, #v.indent-2)
        v:stopopt(t.opt)
      end
      if r ~= true and t._else then
        evalflagselse(t, v, curropt)
      end
      v:stopcond(t.opt)
    elseif t._else then
      local newt = table.remove(t._else, 1)
      if newt._else then
        error('unimplemented')
      end
      if #t._else == 0 then
        t._else = nil
      else
        newt._else = t._else
      end
      evalflags(newt, v, curropt, no_stopcond)
    end
  elseif t.cxx or t.link then
    if t.cxx  then v:cxx(t.cxx, curropt) end
    if t.link then v:link(t.link, curropt) end
  else
    for k,x in ipairs(t) do
      evalflags(x, v, curropt)
    end
  end
end

function insert_missing_function(V)
  for k,mem in pairs(Vbase) do
    if not V[k] then
      V[k] = mem
    end
  end
end

function run(filebase, ignore_options, generator_name, ...)
  local V = require(generator_name:gsub('.lua$', ''))
  insert_missing_function(V)

  for k,mem in pairs(V.ignore) do
    if not Vbase._opts[k] then
      error('Unknown ' .. k .. ' in ignore table')
    end
  end

  for name in pairs(ignore_options) do
    V.ignore[name] = true
  end

  local r = V:start(...)
  if r == false then
    os.exit(1)
  elseif type(r) == 'number' then
    os.exit(r)
  elseif r ~= nil and r ~= V then
    V = r
    insert_missing_function(V)
  end

  evalflags(G, V)

  local out = V:stop(filebase)
  if not out then
    return
  end

  local write_file = function(filename, data)
    local outfile, error = io.open(filename, 'w+')
    if outfile then
      outfile, error = outfile:write(data)
    end
    if error then
      io.stderr:write(arg[0] .. ': open("' .. filename .. '"):' .. error)
      os.exit(4)
    end
  end

  if type(out) == 'table' then
    for _,data in pairs(out) do
      if type(data) == 'table' then
        write_file(data[1], data[2])        
      else
        io.write(data)
      end
    end
  elseif filebase then
    write_file(filebase, out)
  else
    io.write(out)
  end
end

function help(out)
  out:write(arg[0] .. ' [-o filebase] [-f [-]option_list[,...]] {generator.lua} [-h|{options}...]\n')
end

local filebase
local ignore_options = {}

i=1
while i <= #arg do
  local s = arg[i]
  if s:sub(1,1) ~= '-' then
    break
  end

  local opt = s:sub(2,2)
  if opt == 'h' then
    help(io.stdout)
    os.exit(0)
  end

  local value
  if #arg[i] ~= 2 then
    value = s:sub(3)
  else
    i = i+1
    value = arg[i]
    if not value then
      help(io.stderr)
      os.exit(2)
    end
  end

  if opt == 'o' then
    filebase = (value ~= '-') and value or nil
  elseif opt == 'f' then
    for name in value:gmatch('([_%w]+)') do
      if not Vbase._opts[name] then
        io.strerr:write(arg[0] .. ": Unknown option: " .. name)
        os.exit(2)
      end
      ignore_options[name] = true
    end
    if value:sub(1,1) ~= '-' then
      local select_options = ignore_options
      ignore_options = {}
      for name in pairs(Vbase._opts) do
        if not select_options[name] then
          ignore_options[name] = true
        end
      end
    end
  end

  i = i+1
end

if i > #arg then
  help(io.stderr)
  io.stderr:write('Missing generator file\n')  
  os.exit(1)
end

run(filebase, ignore_options, select(i, ...))
