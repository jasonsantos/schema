--- BROKEN -- TODO

module(..., package.seeall)

-- Filters
local function notNullFilter(_, o)
	return o ~= null;
end

local function typeFilter(_, o, typeName)
	return type(o)==typeName and o or nil
end

local function typeTableFilter(_, o) return typeFilter(_, o, 'table') end 
local function typeNumberFilter(_, o) return typeFilter(_, o, 'number') end 
local function typeStringFilter(_, o) return typeFilter(_, o, 'string') end 

-- Aggregators
local function attributeFilter(key, value, list)
	if type(values)~='table' then
		values = {values}
	end
	
end


--- default tables
local filters = {
	notNull = notNullFilter;
	tables = typeTableFilter;
	numbers = typeNumberFilter;
	strings = typeStringFilter;
}

local aggregators = {
	attribute = attributeFilter;
}

-- control functions
local function filter(list, aFilter)
	local result = {}
	for k, v in pairs(list) do
		local n = aFilter(k, v)
		if n then
			result[k] = n
		end
	end
	return result
end

local function aggregate(list, anAggregator)
	local result = {}
	local fullResult = {}
	for k, v in pairs(list) do
		result[k], fullResult = anAggregator(k, v, list, fullResult)
	end
	return fullResult or result
end


function enable(list)
	setmetatable(list, getmetatable(list) or {})
	
	local index = getmetatable(list).__index 
	getmetatable(list).__index = function(list, key)
		
		if aggregators[key] then
			return aggregate(list, aggregators[key])
		end
		
		if filters[key] then
			return filter(list, filters[key])
		end
		
		return index
	end
end


function addFilter(nm, fcn)
	assert(type(nm)=='string')
	assert(type(fcn)=='function')
	filters[nm] = fcn
end

function addAggregator(nm, fcn)
	assert(type(nm)=='string')
	assert(type(fcn)=='function')
	aggregators[nm] = fcn
end