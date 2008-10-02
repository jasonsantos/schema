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
	local field = {
		['.fieldName'] = fieldName;
	}
	
	local methods = {
		addProperty = function(field, propertyName, value)
			field[propertyName] = value
		end;
	}
	
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
	local type = {
		['.type'] = type;
		['.typeName'] = typeName;
		['.attributes'] = {}; -- ????
	}
	
	print('.lastSchema', getfenv(2)['.lastSchema'])
	
	local lastCall = ''
	local lastField = ''
	
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

-- TODO: List Operations on the filters module
-------------------------------------------------------------

local _listOperations = {
	
}

local _schemaOperations = {
	types = function(sch)
		return setmetatable(sch['.types'], {
			
		})
	end;
	type = function(sch, key)
		return sch['.types'][key]
	end;

}
-------------------------------------------------------------

global['Schema'] = function(schemaName)
	-- TODO: ???
	allSchemas[schemaName] = allSchemas[schemaName] or {
		['.name'] = schemaName;
		['.schema'] = allSchemas[schemaName];
		['.types'] = {};
		['.lock'] = 0;
	}
	
	--print('.lastSchema', getfenv(2)['.lastSchema'])
	getfenv(2)['.lastSchema'] = schemaName
	--print('.lastSchema', getfenv(2)['.lastSchema'])
	
	allSchemas[schemaName] = setmetatable(allSchemas[schemaName], {
		
		__index = function(_, key)
			if _schemaOperations[key] and typeOf(_schemaOperations[key])=='function' then
				return _schemaOperations[key](_, key)
			else
				return _schemaOperations[key]
			end 
		end;
		
		__call = function(_, schemaTable)
			
			if not schemaTable then
				return allSchemas[schemaName]['.types']
			elseif typeOf(schemaTable) == 'string' then
				-- it is a typeName 
				return allSchemas[schemaName]['.types'][schemaTable]
			end
			
			-- locking mechanism to avoid concurrent updates on a schema
		
			allSchemas[schemaName]['.lock'] = (allSchemas[schemaName]['.lock'] or 0) + 1 
			if allSchemas[schemaName]['.lock'] ~= 1 then
				allSchemas[schemaName]['.lock'] = (allSchemas[schemaName]['.lock'] or 0) - 1 
				-- TODO: when adding thread support, add a sleep counter for retry 
				error("Schema '" .. tostring(schemaName) .. "' is locked")
			end
			
			--print('.lastSchema', getfenv(2)['.lastSchema'])
			
			--print('Schema( .lock', allSchemas[schemaName]['.lock'])
			
			table.foreach(schemaTable, function(_, type)
				local typeName = type['.typeName']
				allSchemas[schemaName]['.types'] = allSchemas[schemaName]['.types'] or {}
				
				allSchemas[schemaName]['.types'][ typeName ] = type  -- TODO: avoid complete replace of types (allow extension)
				
				type['.schema'] = allSchemas[schemaName] -- TODO: allow types to be declared in more than one schema
			end)
			
			-- unlocking after all changes were made
			allSchemas[schemaName]['.lock'] = (allSchemas[schemaName]['.lock'] or 0) - 1 
			--print('.lastSchema', getfenv(2)['.lastSchema'])
			--print('Schema).lock', allSchemas[schemaName]['.lock'])
			
			assert(allSchemas[schemaName]['.lock'] >= 0, 'Unexpected error on Schema locking mechanism')
			
			return allSchemas[schemaName]['.types']
		end
	})
	
	return allSchemas[schemaName]
end

return global['Schema']