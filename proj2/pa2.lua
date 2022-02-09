#!/usr/bin/env lua
-- pa2.lua
-- Solomon Himelbloom
-- 2022-02-02
-- Exercise 2: Programming in Lua

local pa2 = {} -- Module table

-- mapTable [EXPORTED]
function pa2.mapTable(f, t)
  local placeholder = {}
  
  for k, v in pairs(t) do
    placeholder[k] = f(v)
  end
  
  return placeholder
end

-- concatMax [EXPORTED]
function pa2.concatMax(input, iteration)
  local concatenation, count, length = "", 0, string.len(input)
  
  for count = length, iteration, length do
    concatenation = concatenation..input
  end
  
  return concatenation
end

-- collatz [EXPORTED]
function pa2.collatz(k)
  local function sequence()
    if k > 1 then
      local save_collaz = k
      if k % 2 == 0 then
        k = k / 2
      else
        k = 3 * k + 1
      end
      return save_collaz
    elseif k == 1 then
      k = 0
      return 1
    else
      return nil
    end
  end
  return sequence, nil, nil
end

-- backSubs [EXPORTED]
function pa2.backSubs(s)
  coroutine.yield("")
  
  local reversed, count, length = string.reverse(s), 1, string.len(s)
  
  for i = count, length do
    for j = count, length - i + count do
      coroutine.yield(string.sub(reversed, j, j + i - count))
    end
  end
end

return pa2 -- Return the module, so client code can use it.
