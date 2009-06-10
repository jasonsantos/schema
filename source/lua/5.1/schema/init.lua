--[----------------------------------------------------------------
-- # Schema
-- **Schema** is a module (originally part of [Loft]) 
-- that allows one to declare the structure of Objects 
-- and their relationships in a way that can be used 
-- later on Form generators, ORM and persistence layers.
-- 
-- ## Concept
-- A Schema is a set of metadata about Lua Objects. These metatada 
-- include tangible things, like a *field* list, and less tangible 
-- things, like descriptions and other data about these fields.
--
-- A Schema is designed to be extensible, allowing an object to be
-- described in many layers, each one being important to a different
-- client.
--
-- Therefore, an object can be described in terms of persistence, 
-- presentation and behaviour independently, while still being handled
-- as a simple lua table.
--
-- 
--]-----------------------------------------------------------------
local 
	_G, global, table, string
= 	_G, {}, table, string

local 
	error, getmetatable, setmetatable, rawget, rawset, print, getfenv, setfenv, typeOf, assert, pairs
= 	error, getmetatable, setmetatable, rawget, rawset, print, getfenv, setfenv, type  , assert, pairs

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

--- setproperty
-- safely sets a value to a property 
local _ = function(o, property, defaultValue)
	rawset(o, property, rawget(o, property) or defaultValue or {})
	return rawget(o, property)
end

--- contextName
-- returns the global context name
-- if the given context is a string, returns the  
local function contextName(context)
	if typeOf(context)=='string' then
		return context
	elseif typeOf(context)=='table' and context['.index'] then
		return context['.index']['.']
	end
end

--- buildIndex
-- adds index names to a given element for the other contexts on its index 
local function buildIndex(context, elementName)
	local fullName = context and '.' or '' .. elementName
	local index = {
		['.'] = fullName
	} 
	
	local lastContext = ""
	local rest = string.match(fullName,"[^.]+[.]?(.*)")
	while rest and rest~="" do
		lastContext = string.sub(fullName, 1, -2-string.len(rest))
		index[lastContext]=rest
		rest = string.match(rest,"[^.]+[.]?(.*)")
	end
	
	return index, fullName
end


--- createElement
-- creates prototype elements
-- @param context	string or table representing the context of the current element
-- 					this can be an element name or the parent element itself 
-- @param name		name of the element being created
-- @param typeName	typeName of the element being created
-- @param alternateName table containing alternatives to the names conventionally used on creating an element
-- @return created element 
local function createElement(context, name, typeName, alternativeNames)
	-- defines the names of the special attributes for this element
	local prototypeTag = alternativeNames and alternativeNames.prototype or typeName or 'prototype'
	local nameTag = alternativeNames and alternativeNames.name or '.' .. prototypeTag .. 'Name'
	local selfTag = alternativeNames and alternativeNames.self or '.' .. prototypeTag
	local contentsTag = alternativeNames and alternativeNames.contents or '.contents' 

	-- Creates the element
	local element = {
		[nameTag] = name,
		[contentsTag]={},
		['.attributes'] = {},
		['.prototype'] = prototypeTag,
		['.' .. prototypeTag] = typeName,
		['.tagNames'] = { prototypeTag=prototypeTag, nameTag=nameTag, selfTag=selfTag, contentsTag=contentsTag },
		['.lock'] = 0,
	}
	
	element[selfTag] = element
	
	-- creates the object name index 
	-- (an index to be used to define the name of this element according to context)
	element['.index'] = buildIndex(contextName(context), name)
		
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
		end,
		
		__unlock=function(o)
			local lock = _(o,'.lock',0)
			rawset(o,'.lock',lock-1)
			
			assert(_(o,'.lock') >= 0, 'Unexpected error on locking mechanism')
		end,
		
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
	local altNames = { contents = '.fields' }
	local type = createElement(lastSchema, typeName, 'type', altNames)
	
	print('.lastSchema', lastSchema)
	
	local lastCall
	local lastField
	
	-- metatable to create types
	return setmetatable(type, {
		__index = function(type, fieldName)
			print('indexed:' .. fieldName) 
			lastCall = lastField
		 	lastField = fieldName			 	
		 	local field =  _(_(type, '.fields'), lastField, Field(lastField, type))
			 
			return type, field
		end;
		
		__newindex = function(type, fieldName, defaultValue)
			rawset(type, fieldName, defaultValue)
		end;
		
		__call = function(fn, argument, ...)
			print('called ', typeOf(fn), fn)
			local arg = {...}
			if typeOf(fn)=='table' then
				table.foreach(fn, function(...) print(' >', ...) end)
			end
			print('called with argument', typeOf(argument), argument)
			if typeOf(argument)=='table' then
				table.foreach(argument, function(...) print(' >', ...) end)
			end
			
			if fn==argument then
				local field = type['.fields'][lastCall]
				--print("TYPE>", lastCall, lastField )
				field['.fieldType'] = lastField
			end
			
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