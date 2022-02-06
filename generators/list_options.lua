local knwon_opts = {}
local errors = {}

local without_space_or_error = function(_, s)
  if s:find(' ') then
    errors[#errors+1] = '"' .. s .. '" contains a space'
  end
end

local is_available = function(_, optname)
  return _._koptions[optname].unavailable ~= _.lang
end

return {
  start=function(_, ...)
    local show_profile, color, categorized, verbose
    local help = function()
      print(_.generator_name .. ' [-h] [-v] [--categorized] [--profile] [--color]')
      return false
    end
    local cli = {
      ['--categorized']=function() categorized=true end,
      ['--profile']=function() show_profile=true end,
      ['--color']=function() color=true end,
      ['-v']=function() verbose=true end,
      ['-h']=help,
      ['--help']=help,
    }
    for _,v in ipairs({...}) do
      local opt = cli[v]
      if not opt then
        return help()
      end
      if opt() == false then
        return false
      end
    end

    local push_opt_for_print, opt_for_print_end
    if categorized then
      local categorized_opts = {}
      for k,infos in ipairs(_._opts_by_category) do
        local i = #categorized_opts + 1
        categorized_opts[i] = {infos[1], {}}
        for k,optname in ipairs(infos[2]) do
          categorized_opts[optname] = i
        end
      end
      local other_cat = #categorized_opts + 1
      categorized_opts[other_cat] = {'Other', {}}

      push_opt_for_print = function(option, str, desc)
        local strings = categorized_opts[categorized_opts[option.name] or other_cat][2]
        strings[#strings+1] = str
        if verbose and desc then
          strings[#strings+1] = '  ' .. desc
        end
      end

      opt_for_print_end = function()
        local strings = {}
        local first = true
        for k,infos in ipairs(categorized_opts) do
          if #infos[2] ~= 0 then
            if not first then
              strings[#strings+1] = ''
            end
            strings[#strings+1] = color and ('\027[1m# ' .. infos[1] .. '\027[0m:\n')
                                         or ('# ' .. infos[1] .. ':\n')
            first = false
            for k,str in ipairs(infos[2]) do
              strings[#strings+1] = str
            end
          end
        end
        print(table.concat(strings, '\n'))
      end
    else
      push_opt_for_print = function(option, str, desc)
        print(str)
        if verbose and desc then
          print('  ' .. desc)
        end
      end
      opt_for_print_end = function() end
    end

    local add_opt = function(option)
      knwon_opts[option.name] = {option.kvalues}
    end

    if color then
      local color_map = {
        on='\027[32m',
        off='\027[31m',
        default='\027[37m',
      }
      color_map[0] = '\027[34m'
      color_map[1] = '\027[35m'
      local color_size = 2
      for option in _:getoptions() do
        local str, ic = option.name .. ' \027[37m=', 0
        for i,x in ipairs(option.ordered_values) do
          local c = color_map[x]
          if not c then
            c = color_map[ic % color_size]
            ic = ic + 1
          end
          str = str .. ' ' .. (i == 1
            and (c:sub(0,-2) .. ';7m' .. x .. '\027[0m')
            or (c .. x))
        end
        push_opt_for_print(option, str .. '\027[0m',
                           option.description and ('\027[37m' .. option.description .. '\027[0m'))
        add_opt(option)
      end
    else
      for option in _:getoptions() do
        push_opt_for_print(option, option.name .. ' = '
                           .. table.concat(option.ordered_values, ' '),
                           option.description)
        add_opt(option)
      end
    end

    opt_for_print_end()

    if show_profile then
      print('\n\nProfiles:')
      table.sort(_._opts_build_type)
      for name, opts in _:getbuildtype() do
        print('\n' .. name)
        for i,xs in ipairs(opts) do
          print(' - ' .. xs[1] .. ' = ' .. xs[2])
        end
      end
    end
  end,

  startoptcond=function(_, optname)
    local known = knwon_opts[optname]
    if not known then
      if is_available(_, optname) then
        errors[#errors+1] = '_koptions[' .. optname .. ']: unknown key'
      end
    else
      known[2] = true
    end
  end,

  startcond=function(_, x, optname)
    if x.lvl then
      local known = knwon_opts[optname]
      if not known then
        if is_available(_, optname) then
          errors[#errors+1] = '_koptions[' .. optname .. ']: unknown key'
        end
      elseif not known[1][x.lvl] then
        errors[#errors+1] = '_koptions[' .. optname .. ']: unknown value: ' .. x.lvl
      else
        known[2] = true
      end
    elseif x._not then
      _:startcond(x._not, optname)
    else
      local sub = x._and or x._or
      if sub then
        for k,y in ipairs(sub) do
          _:startcond(y, optname)
        end
      end
    end
  end,

  stop=function(_)
    for k,opts in pairs(knwon_opts) do
      if not opts[2] then
        errors[#errors+1] = '_koptions[' .. k .. ']: not used in the tree'
      end
    end
    if #errors ~= 0 then
      error(table.concat(errors, '\n'))
    end
  end,

  cxx=without_space_or_error,
  link=without_space_or_error,
  act=function() return true end,
}
