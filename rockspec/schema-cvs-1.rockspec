package = "schema"
version = "cvs-1"
source = {
   url = "cvs://:pserver:anonymous:@cvs.luaforge.net:/cvsroot/schema",
   cvs_tag = "HEAD",
}
description = {
   summary = "Schema",
   detailed = [[Schema is a module (originally part of Loft) that allows one to declare the structure of Objects and their relationships in a way that can be used later on Form generators, ORM and persistence layers.]],
   license = "MIT/X11",
   homepage = "http://schema.luaforge.net/"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "none",
   install = { 
   		lua = {
   			["schema.init"] = [[../source/lua/5.1/schema/init.lua]]
   		}
   	}
}