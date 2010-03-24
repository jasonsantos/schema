package = "schema"
version = "scm-1"
source = {
  url = "git://github.com/jasonsantos/schema.git",
}
description = {
  summary = "Schema",
  detailed = [[Schema is a module that allows the declaration of data structures composed of Entities and Fields. Its primary use is to define the model for ORMs and Form generators, but it can be used to declare any such structure.]],
  license = "MIT/X11",
  homepage = "http://schema.github.com/"
}
dependencies = {
  "lua = 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["schema"] = [[source/schema.lua]]
  }
}
