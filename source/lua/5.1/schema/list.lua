--[[--
	A useful library to handle list filters
--]]--
module(..., package.seeall)

-- List
-------------------------------------
-- basic and example filter functions
 
-- typeFilter(_, o, typeName)
--- utility function to aid on type-based filters. 
--- Checks type using the 'type' function on the basic library
--- @param _ key of iteration. ignored
--- @param o object to be evaluated
--- @param typeName name of the type to be checked against the 'object' type

local function typeFilter(_, o, typeName)
	return type(o)==typeName and o or nil
end

-- typeTableFilter(_, o)
--- checks whether a given element is of type table. 
--- @param _ key of iteration. ignored
--- @param o object to be evaluated
local function typeTableFilter(_, o) return typeFilter(_, o, 'table') end 
-- typeNumberFilter(_, o)
--- checks whether a given element is of type number. 
--- @param _ key of iteration. ignored
--- @param o object to be evaluated
local function typeNumberFilter(_, o) return typeFilter(_, o, 'number') end 
-- typeStringFilter(_, o)
--- checks whether a given element is of type string. 
--- @param _ key of iteration. ignored
--- @param o object to be evaluated
local function typeStringFilter(_, o) return typeFilter(_, o, 'string') end 
-- attributeFilter(_, o, attributeName)
--- extracts a given element from within the object. 
--- @param _ key of iteration. ignored
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
--- @param _ key of iteration. ignored
--- @param o object to be evaluated
--- @param attributeList list of attributes to be checked for equalty
local function withAttributesFilter(_, o, details, attributeList)
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


-- packValues(_, o)
--- packs all non-null values, removing their original keys 
--- @param _ key of iteration. ignored
--- @param o object to be evaluated
local function packValues(_,o)
	return o, true
end


--- default filter table
local filters = {
		tables 		= typeTableFilter;
		numbers 	= typeNumberFilter;
		strings 	= typeStringFilter;
		attribute 	= attributeFilter;
		['(%w+)s'] 	= attributeFilter;
		with 		= withAttributesFilter;
		pack 		= packValues;
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
		local n, nk = aFilter(k, v, ...)
		if n then
			if nk then
				table.insert(result, n)
			else
				result[k] = n
			end
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
	getmetatable(list).__old_index = getmetatable(list).__index
	
	local index = getmetatable(list).__old_index

	local __call = function(list, ...)
		local key = getmetatable(list).__lastfield or '_'
		local fd = getmetatable(list).__filterdetails or key
		local f = filters[key] 

		if f then
			getmetatable(list).__lastfield = nil
			getmetatable(list).__filterdetails = nil
			getmetatable(list).__call = getmetatable(list).__old_call
			return filter(list, f, fd,...)
		end
		
		getmetatable(list).__call = getmetatable(list).__old_call
		
		if getmetatable(list).__old_call ~= __call then 
			return getmetatable(list).__old_call(list, ...)
		end
	end
	
	local findFilter = function(key)
		if filters[key] then
			return filters[key], key, key
		else
			for pattern, _ in pairs(filters) do
				for k in string.gfind(key, pattern) do
					return filters[pattern], pattern, k
				end
			end
		end
	end
	 
	getmetatable(list).__index = function(list, key)
		local _, key, details = findFilter(key)
		if _ then
			getmetatable(list).__lastfield = key
			getmetatable(list).__filterdetails = details
			getmetatable(list).__old_call = getmetatable(list).__call
			getmetatable(list).__call= __call
			return list
		end
		return index and index(list, key) or rawget(list, key)
	end
			

	
end

-- addFilter(nm, fcn)
--- adds a filter function to the global filter pool
--- @param nm name of the filter
--- @param cn function to be used as a filter
---     	  must expect key, value plus any parameters passed on the calling
---           and must return value, nil or anything to be put in place of value
---           in the result table 
-- TODO: apply the addFilter function only to a given list
function addFilter(nm, fcn)
	if type(nm)~='string' then error('filter name must be string',2) end 
	if type(fcn)~='function' then error('filter must be a function',2) end
	filters[nm] = fcn
end
