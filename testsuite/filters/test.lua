local filters = require'schema.filters'

a = {1, 2, 3, 4, 5 , 6, 7, 'attention', 'gestalt!', {}, {12}, {name='Jason', age='34'}, {name='Roger', age='32'}, {name='Amanda', age='56'},  }

filters.enable(a)

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

filters.addFilter('contains', function(k,v, word) 
	if type(word) ~= 'string' then error("expression must be of type 'string'", 4) end
	return type(v) == 'string' and (string.find(v, word) and v) 
end)

print'---'
table.foreach(a.contains('gestalt'), print)

print'---'
table.foreach(a.attribute'age', print)

print'---'
table.foreach(a.with{name='Roger'}, print)