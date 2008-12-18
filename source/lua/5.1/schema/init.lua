local 
	_G, global, table, string
= 	_G, {}, table, string

local 
	error, setmetatable, rawget, rawset, print, getfenv, setfenv, typeOf, assert
= 	error, setmetatable, rawget, rawset, print, getfenv, setfenv, type  , assert

module"schema"

-- Schema Repositories
local allSchemas = {}
local lastSchema = {}

--- export
-- exports the sugar api to the global environment 
function export(t) 
	local g = t or _G
	table.foreach(global, function(k,v) g[k] = v end)
end

--- createElement
-- creates prototype elements
local function createElement(context, name, type, alternativeNames)
	local prototypeTag = alternativeNames and alternativeNames.prototype or type or 'prototype'
	local nameTag = alternativeNames and alternativeNames.name or '.' .. prototypeTag .. 'Name'
	local selfTag = alternativeNames and alternativeNames.self or '.' .. prototypeTag
	local contentsTag = alternativeNames and alternativeNames.contents or '.contents' 

	local element = {
		['.lock'] = 0,
		['.prototype'] = prototypeTag,
		['.' .. prototypeTag] = type,
		[nameTag] = name,
		['.context'] = typeOf(context)=='string' and context or (context['.index'] and context['.index']['.']),
		['.index'] = {},
		['.attributes'] = {},
		[contentsTag]={}
	}
	
	element[selfTag] = element
	
	local indexName = element['.context'] .. "." .. name
	element['.index']['.'] = indexName 
	local lastContext = ""
	local addContext 
	addContext = function(rest)
		if rest and rest~="" then
			lastContext = string.sub(indexName, 1, -2-string.len(rest))
			element['.index'][lastContext]=rest
			string.gsub(rest, "[^.]+[.]?(.*)", addContext)
		end
	end
	string.gsub(indexName,"[^.]+[.]?(.*)", addContext)
	
	local mt 
	mt = {
		__index = function(o, idx)
			return rawget( rawget(o, '.attributes'), idx ) or rawget(o, idx)
		end,
		__newindex = function(o, idx, v)
			return rawset( rawget(o, '.attributes'), idx , v)
		end,
		
		__lock=function(o)
			local lock = _(o,'.lock',0)
			rawset(o,'.lock',lock+1)
			
			if _(o,'.lock') ~= 1 then
				rawset(o,'.lock', lock-1) 
				-- TODO: when adding thread support, add a sleep counter for retry
				local prototype = o['.prototype'] 
				error(prototype .. " '" .. tostring(o['.' .. prototype .. 'Name']) .. "' is locked")
			end
		end
		
		__unlock=function(o)
			local lock = _(o,'.lock',0)
			rawset(o,'.lock',lock-1)
			
			assert(_(o,'.lock') >= 0, 'Unexpected error on locking mechanism')
		end
		
		__fillContents=function(o, contents)
			local mycontents = _(o, contentsTag)
			mt.__lock(o)
			for key, value in pairs(contents) do
				if typeOf(key)=='number' then
					table.insert(mycontents, value)
				elseif typeOf(key)=='string' then
					o[key]=value -- TODO: avoid complete replace of contents (allow extension)
				end
			end
			mt.__unlock(o)
		end,
		__call = function(o, contents)  mt.__fillContents(o, contents) end
	}
	
	return setmetatable(element, mt)
end



--- setproperty
-- safely sets a value to a property 
local _ = function(o, property, defaultValue)
	rawset(o, property, rawget(o, property) or defaultValue or {})
	return rawget(o, property)
end

--- _isType
-- returns true if a given name is a standard typeName and false if it is a fieldName
local _isType = function(s)
	return s and string.len(s) > 1 and string.sub(s, 1, 1) == string.upper(string.sub(s, 1, 1))
end

--- Field
-- creates or returns a field
local Field = function(fieldName, type)
	local field = createElement(type, fieldName, 'field')
	
	return setmetatable({}, {
		__index = function(field, key)
			print(fieldName, key)
			return function(...)
				print('type:', key, ...)
			end
		end;
		
		__call = function(field, ...)
				print('called(from field):', ...)
		end
	})
end

--- Função de controle para os tipos.. deve retornar um tipo 
global['Type'] = function(typeName)
	print('------------ type ' .. typeName .. ' --------------')
	local lastSchema = getfenv(2)['.lastSchema']
	local type = createElement(lastSchema, typeName, 'type')
	
	print('.lastSchema', lastSchema)
	
	local lastCall = ''
	local lastField = ''
	
	-- metatable to create types
	return setmetatable(type, {
		__index = function(type, fieldName)
			 print('indexed:' .. fieldName) 
			 local fieldType
			 if _isType(fieldName) then
			 	lastCall = fieldName
			 	fieldType = fieldName
			 else
			 	lastField = fieldName			 	
			 end
			 
		 	local field =  _(_(type, '.fields'), lastField, Field(lastField, type))
		 	field['.fieldType'] = fieldType
			 
			return type, field
		end;
		
		__newindex = function(type, fieldName, defaultValue)
			rawset(type, fieldName, defaultValue)
		end;
		
		__call = function(fn, argument, ...)
			print('called ', typeOf(fn), fn)
			if typeOf(fn)=='table' then
				table.foreach(fn, function(...) print(' >', ...) end)
			end
			print('called with argument', typeOf(argument), argument)
			if typeOf(argument)=='table' then
				table.foreach(argument, function(...) print(' >', ...) end)
			end
			print('called (from type): '.. lastCall .. ' for field ' .. lastField  , ...)
			
			local firstChar = string.sub(lastCall, 1, 1)
			local args = {...} 

			local operation = ({
				['string'] = function()
					print('String argument')
					local field = _(_(type, '.fields'), lastField)
					field['.fieldName'] = argument
					return field
				end;
				['number'] = function()
					print('Number argument')
					local field = _(_(type, '.fields'), lastField)
					field['.fieldSize'] = argument
					return field
				end;
				['date'] = function()
					print('Date argument')
					local field = _(_(type, '.fields'), lastField)
					field['.fieldSize'] = argument
					return field
				end;
				['table'] = function()
					print('Table argument')
					local field = _(_(type, '.fields'), lastField)
					field['.subType'] = argument
					return field
				end;
				
			})[typeOf(argument)] 	-- selects the function 
									-- according to the type of argument
												
			return type, operation() -- executes the function selected
		end
	})
end

-------------------------------------------------------------

global['Schema'] = function(schemaName)
	local lastSchema = getfenv(2)['.lastSchema']
	
	
	-- TODO: obter o contexto atual
	-- procurar pelo índice
	-- criar função pra encontrar
	
	allSchemas[schemaName] = allSchemas[schemaName] or createElement(lastSchema, schemaName, 'schema')
	
	--print('.lastSchema', getfenv(2)['.lastSchema'])
	getfenv(2)['.lastSchema'] = schemaName
	--print('.lastSchema', getfenv(2)['.lastSchema'])
	
	getmetatable(allSchemas[schemaName]).__call = function(_, schemaTable)
		if not schemaTable then
			return allSchemas[schemaName]['.contents']
		elseif typeOf(schemaTable) == 'string' then
			-- it is a typeName 
			return allSchemas[schemaName]['.contents'][schemaTable]
		end
		
		getmetatable(allSchemas[schemaName]).__fillContents(_, schemaTable)
		
		return allSchemas[schemaName]
	end
	
	return allSchemas[schemaName]
end

return global['Schema']