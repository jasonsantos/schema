local filters = require'schema.filters'

a = {1, 2, 3, 4, 5 , 6, 7, 'atencao', 'ou nao', {}, {12}}

filters.enable(a)

print'---'
table.foreach(a, print)

print'---'
table.foreach(a.strings, print)

print'---'
table.foreach(a.tables, print)

print'---'
table.foreach(a.numbers, print)

filters.addFilter('')
