local _ = require'schema.list'

local a = {1, 2, 3, 4, 5 , 6, 7, 'attention', 'gestalt!', {}, {12}, {name='Jason', age='34'}, {name='Roger', age='32', aa=1}, {name='Amanda', age='56'},  }
local s

_.enable(a)

print'---'
local t = a.strings()
for k,v in pairs(a) do
	print(k>=1 and k<=11 and t[k]) 
end

print'---'
table.foreach(a.strings(), function(k,v) print(k>=1 and k<=11) end)


print'---'
table.foreach(a.tables(), print)

print'---'
table.foreach(a.numbers(), print)

_.addFilter('contains', function(k,v,fd,word) 
	if type(word) ~= 'string' then error("expression must be of type 'string'", 4) end
	return type(v) == 'string' and (string.find(v, word) and v) 
end)

print'---'
table.foreach(a.contains('gestalt'), print)

print'---'
table.foreach(a.attribute'age', print)

print'---'
table.foreach(a.with{name='Roger'}.ages().pack(), print)

print'---'
table.foreach(a.ages(), print)

print'---'
table.foreach(a.ages().pack(), print)


print'---'
table.foreach(a.aas().pack(), print)

