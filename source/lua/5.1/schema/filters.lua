--[[--
	A useful library to handle filterable lists
--]]--
module(..., package.seeall)

-- Filters
-------------------------------------
-- basic and example filter functions
 
-- typeFilter(_, o, typeName)
--- utility function to aid on type-based filters. 
--- Checks type using the 'type' function on the basic library
--- @param _ key of iteraction. ignored
--- @param o object to be evaluated
--- @param typeName name of the type to be checked against the 'object' type

local function typeFilter(_, o, typeName)
	return type(o)==typeName and o or nil
end

-- typeTableFilter(_, o)
--- checks whether a given element is of type table. 
--- @param _ key of iteraction. ignored
--- @param o object to be evaluated
local function typeTableFilter(_, o) return typeFilter(_, o, 'table') end 
-- typeNumberFilter(_, o)
--- checks whether a given element is of type number. 
--- @param _ key of iteraction. ignored
--- @param o object to be evaluated
local function typeNumberFilter(_, o) return typeFilter(_, o, 'number') end 
-- typeStringFilter(_, o)
--- checks whether a given element is of type string. 
--- @param _ key of iteraction. ignored
--- @param o object to be evaluated
local function typeStringFilter(_, o) return typeFilter(_, o, 'string') end 
-- attributeFilter(_, o, attributeName)
--- extracts a given element from within the object. 
--- @param _ key of iteraction. ignored
--- @param o object to be evaluated
--- @param attributeName name of the attribute to be extracted
local function attributeFilter(_, o, attributeName)
	if not attributeName then
		error('please, name an attribute to filter', 4)
	end
	
	if type(o)~='table' then
		return nil
	end
	return o[attributeName]
end
-- withAttributesFilter(_, o, attributeList)
--- extracts a given element if it matches the given attributes. 
--- @param _ key of iteraction. ignored
--- @param o object to be evaluated
--- @param attributeList list of attributes to be checked for equalty
local function withAttributesFilter(_, o, attributeList)
	if type(attributeList) ~= 'table' then
		error('please, select an attribute to filter', 4)
	end
	
	if type(o)~='table' then
		return nil
	end
	
	for k,v in pairs(attributeList) do
		if not o[k] or o[k] ~= v then
			return nil
		end
	end
	return o
end


--- default filter table
local filters = {
	tables 		= typeTableFilter;
	numbers 	= typeNumberFilter;
	strings 	= typeStringFilter;
	attribute 	= attributeFilter;
	with 		= withAttributesFilter;
}

-- control functions

-- filter(list, aFilter, ...)
--- generic filter appliance filter
--- note that with this function, filters cannot alter the order
--- of the list or group items
--- @param list the list to be filtered
--- @param aFilter filter function to be executed for each item
--- @param ... any parameters passed on invocation
--- @returns new filtered list
--- TODO: implement aggregates
--- TODO: optimize appliance of chained filters 
local function filter(list, aFilter, ...)
	local result = {}
	for k, v in pairs(list) do
		local n = aFilter(k, v, ...)
		if n then
			result[k] = n
		end
	end
	return setmetatable(result, getmetatable(list))
end

-- filter API

-- enable(t)
--- enables the filter API on a given table, turning it into a list
--- @param t the table to be enabled
function enable(list)
	setmetatable(list, getmetatable(list) or {})
	
	local index = getmetatable(list).__index
	 
	getmetatable(list).__index = function(list, key)
		if filters[key] then
			getmetatable(list).__lastfield = key
			
			getmetatable(list).__old_call = getmetatable(list).__call
		end
		
		return list
	end
			
	getmetatable(list).__call = function(list, ...)
		local key = getmetatable(list).__lastfield or '_'
		local f = filters[key] 

		if f then
			getmetatable(list).__lastfield = nil
			getmetatable(list).__call = getmetatable(list).__old_call
		end
		
		return filter(list, f, ...)
	end
	
end

-- addFilter(nm, fcn)
--- enables the filter API on a given table, turning it into a list
--- @param nm name of the filter
--- @param cn function to be used as a filter
---     	  must expect key, value plus any parameters passed on the calling
---           and must return value, nil or anything to be put in place of value
---           in the result table 
function addFilter(nm, fcn)
	if type(nm)~='string' then error('filter name must be string',2) end 
	if type(fcn)~='function' then error('filter must be a function',2) end
	filters[nm] = fcn
end
