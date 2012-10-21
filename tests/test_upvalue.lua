local upvalue=nil

function test()
  local last
  for j=1,20 do
    last = upvalue
  end
  print(last, upvalue)
end

for i=1,8 do
  upvalue = i
  test()
end

