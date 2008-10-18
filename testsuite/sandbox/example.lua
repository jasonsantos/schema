require'schema'

schema.export()

Schema'Cliente' {

    Type 'Logic'
        .nome;                  		-- minimal type

    Type 'Endereco' {tableName='tbEndereco'}
        . rua'Rua'                  	-- alias
        . numero'Número':Number() 		-- primitive type(?)
        . complemento{column='f_complemento'}
        . bairro
        . cidade
        . cep{maxLength=12};

    Type 'PessoaFisica'
        . nome
        . endereco
        . telefone
        . livesHere : Logic(); 			-- user defined type (implicit association)
}

local c = Schema'Cliente'

names         = c.Type'Endereco'.fields.names()
table.foreach(names, print)
--[[--
1    rua
2    numero
3    complemento
4    bairro
5    cidade
6    cep
--]]--
aliases        = c.Type'Endereco'.fields.aliases()
fields         = c.Type'Endereco'.fields.types()
maxLengths     = c.Type'Endereco'.fields.attributes'maxLength'

tableName     = c.Type'Endereco'.attributes['tableName']

cep         = c.Type'Endereco'.cep
cepMaxLen     = cep.attributes['maxLength']