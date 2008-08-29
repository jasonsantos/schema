package.path = [[;;./net.luaforge.loft/source/lua/5.1/?.lua;./net.luaforge.loft/source/lua/5.1/?/init.lua;]]


require "schema"

local allTypes = Schema 'Cli' {

	Data 'TipoDocumento' {
	 	CPF = "Cadastro de Pessoa Fisica",
	 	RG = { nome = "Identidadade", description="Registro Geral" },
	};

	Data 'Estado' {
		{id=1,name='Novo'}, 
		{id=2,name='Criado'}, 
		{id=3,name='Alterado'}
	};
	
	Type 'Endereco'
		. rua
		. numero
		. complemento
		. bairro
		. cidade
		. cep

	Type 'PessoaFisica'
		. nome
		. endereco
		. telefone

	Type 'Cliente' {tableName='tbCliente', databaseName='teste'}
		. nome'Nome'{required=true}
		. endereco
		. telefone
		. cep'clCep' : Number{size=256, required=true }
		. idade 
		. dataNascimento : Date('now')
		. tipoDocumento : Reference('tipoDocumento');
		. presidente : Reference('passoaFisica');
		
	Type 'Assinatura'
	 	. tipo {
	 		Type 'TipoAssinatura'
	 			. nome
	 			. descricao
	 	}
	}
	
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
	}

	Indexes {
		'standard' = Filterable {
			fields = {'nome', 'cpf'}
		}
	}


local newsTypes = Schema 'Newsletter' {
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
		.from
		.groups : Collection(Type'Grupo')
		
}


t = newsTypes['Veiculo'].fields().names()
t = newsTypes['Veiculo'].fields().types()

loft.initialize('sqlite3')

loft.registerSchema(newsTypes)

v = new'Veiculo'

if v:validate() then

loft.persist(v)

else

local msgs = {
	unpack(v:getErrors()),
	unpack(v:getWarnings())
}

end

--[[-----------------

vf = Face 'ListaDeVeiculos' For 'Veiculo' {
	.nome 
	.teste {fieldName='descricao', size=70}
	.valor {type='currency', currency='BRL'}
	.dataNascimento {type='date', format='DD/MM/AA'}
	.grupo {
		type='collection',
		items = {
			nome = {type='text'}
		}
	}
}

--]]-----------------


for typeName, t in pairs(allTypes) do
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
