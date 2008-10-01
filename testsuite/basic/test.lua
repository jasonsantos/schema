require "schema"

schema.export() -- export global functions to this file

Schema 'Cli' {
	
	--[[
	Data 'TipoDocumento' {
	 	CPF = "Cadastro de Pessoa Fisica",
	 	RG = { nome = "Identidadade", description="Registro Geral" },
	};
	
	Data 'Estado' {				  -- 
		{id=1,name='Novo'}, 
		{id=2,name='Criado'}, 
		{id=3,name='Alterado'}
	};
	--]]
	
	Type 'Logic';				  -- minimal type

	Type 'Endereco'
		. rua'Rua'				  -- alias
		. numero'Número':Number() -- primitive type
		. complemento
		. bairro
		. cidade
		. cep;

	Type 'PessoaFisica'
		. nome
		. endereco
		. telefone
		. livesHere : Logic(); -- user defined type (implicit association)
	
	--[[

	-- TODO: schema declaration engine (OK)
	-- TODO: locking mechanism (OK)
	-- TODO: user declared types as prototypes for fields
	-- TODO: default types declared with the same syntax as user declared types
	-- TODO: additional attributes to type
	-- TODO: additional attributes to fields
	-- TODO: interface for querying attributes
	-- TODO: structures for storing and retrieving values
	-- TODO: structures for declaring methods/behaviors/events/validations
    -- TODO: subtypes declared inside field declaration


	Type 'Cliente' {tableName='tbCliente', databaseName='teste'}
		. nome'Nome'{required=true}
		. endereco
		. telefone
		. cep'clCep' : Number{size=256, required=true }
		. idade 
		. dataNascimento : Date('now')
		. tipoDocumento : Reference('tipoDocumento')
		. presidente : Reference('passoaFisica');
		
	Type 'Assinatura'
	 	. tipo {
	 		Type 'TipoAssinatura'
	 			. nome
	 			. descricao;
	 	};
	--]]
	--[[
	Validations {
		'PessoaFisica' {
			.idade = function(field, oldvalue, newvalue)
				if (i< 17) then
					field.entity.checked = false
					return true, newvalue, {'asasa'}
				end
				return false, {'erroraasa'}, {'asasas'}
				
				return true, {}, {}
			end
		}
	};
	
	Indexes {
		'standard' = Filterable {
			fields = {'nome', 'cpf'}
		}
	};
	--]]
}



table.foreach(Schema'Cli', print)

--[====[

Schema 'Newsletter' {
	Type 'Grupo'
		.nm_grupo "Nome";
	
	Type 'Veiculo' 
		.nome
		.periodicidade : Number()
		.descricao
		.subject {
			__beforeSave = function(...)
				warning()
			end;
		}
		.from;
--		.groups : Collection(Type'Grupo');		
}

--t = newsTypes['Veiculo'].fields().names()
--t = newsTypes['Veiculo'].fields().types()


print("\n\n\n\n")
for typeName, t in pairs(newsTypes) do
	print'---------------------------'
	print(t['.typeName'])
	print'---------------------------'
	table.foreach(t['.fields'], function(_,f)
		print('   -- ' .. _, type(f))
		table.foreach(f, function(k,v)
			print('    . ' .. k, v)		
		end)

	end)
	print'---------------------------'
end

]====]