-- adv.lua
-- 2022-01-31

function small_fibos1(limit)
  local currfib, nextfib = 0, 1
  while currfib <= limit do
    coroutine.yield(currfib)
    currfib, nextfib = nextfib, currfib + nextfib
  end
end

limit = 3000
io.write("Fibonacci numbers up to "..limit.." (using coroutine)\n")
cw = coroutine.wrap(small_fibos1)

f = cw(limit)
while f ~= nil do
  io.write(f .. " ")
  f = cw()
end
io.write("\n")

function small_fibos2(limit)
  local currfib, nextfib = 0, 1
  function iter(dummy1, dumm2)
    if currfib > limit then
      return nil
    end
    
    local save_curr = currfib
    currfib, nextfib = nextfib, currfib + nextfib
    return save_curr
  end

  return iter, nil, nill
  end

io.write("Fibonacci numbers up to "..limit.." (using custom iterator)\n")
for f in small_fibos2(limit) do
  io.write(f .. " ")
end
io.write("\n")
  