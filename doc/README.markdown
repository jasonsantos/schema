Schema
------

Schema is a module that allows the declaration of data structures composed of
Entities and Fields. Its primary use is to define the model for ORMs and Form
generators, but it can be used to declare any such structure.

Schema allows the definition of a *data schema* in an agnostic way. The actual
physical representation of the data schema isn't treated by the module, and is
supposed.to be used by a different engine, that we are going to call the
*client engine*.

A data schema can be used in many ways, but the most common is to represent a
set of tables in a database application.

The client engine usually represents your application, a schema-enabled Lua ORM
(like Orbit.model or Loft) or any other form of data persitence that has been
written specially to use the data table that results from the data schema
declaration.

The declaration uses a Lua-based DSL to define the _data schema_, its _entities_
and their _fields_.

Schema offers a set of predefined types for fields, but is completely
extensible: when it doesn't understand a field type the type name itself is
stored in the schema, so it can be treated by the underlying persistence engine.

##The Schema DSL

The schema DSL can be described as a sequence of declarations of three types:

* Options
* Entities
* Handlers

###Options

*Options* are values used to define general settings or convey additional
information for the client engine.

There are some options that affects the Schema declaration:

* *table_prefix*: is a string added to the begining of every entity name to
define the *table_name* attribute for an entity when the attribute is absent.
* *column_prefix*: is a string added to the begining of every field name to
define the *column_name* attribute of a field when the attribute is absent.

###Declaring Entities

*Entities* represent object classes or database tables, and are declared using
the function 'entity'. They are stored as simple Lua tables containing
information about their fields and about the entity itself.

Data schemas will tipically have three fields on an entity declaration:

* *aspects* - define a list of aspects to be used in this particular entity.
Aspects are treated by the client engine -- schema doesn't process them in any
way during declaration.
* *fields* - define a list of field declarations. They usually have the format:
    <fieldname> = <fieldtype> ([parameters])

* *handlers* - define a list of handler declarations in the format
    <handlernames> = <function>

Handler function signatures can vary widely depending on the underlying client
engine, the type of event or other factors.

###Declaring Fields

A typical client engine will extend the schema list of field types -- either on
its core or by the use of aspect-activated plugins.

Every field type can produce a number of event hooks.

The predefined field types are:

*belongs_to(entity_name)* - the "one" entity used in a one to many association
*boolean* - a boolean value
*date* - a date represents a timestamp equivalent to 12:00PM in the given day
*has_and_belongs(entity_name)* the collection of "many" entities in a many to
many association
*has_many(entity_name)* - the collection of "many" entities in a one to many
association
*has_one(entity_name)* - the other entity in a one to one association
*integer([maximum_size])* an integer number with an optional maximum size of
digits
*key* - a primary key for the entity
*long_text ([maximum_size])* - a long string with an optional maximum size
*number* - a floating point number
*reference* - a reference to a multi valored field
*text([maximum_size])* - a short string with an optional maximum size
*timestamp* - the date and/or time at which a certain event occurred.

###Handlers

The default field handlers can be of two types:
*get(...)* is a function called whenever a field value is evaluated
*set(...)* is a function called whenever a field value is stored

Schema can also receive a list of *entity handlers*, to treat events on entity
operations.   can be of the following types:
*before_save(...)* is a function called before an entity is saved in the
persistence
*after_save(...)* is a function called after an entity is saved in the persistence
*before_destroy(...)* is a function called before an entity is removed from the
persistence
*after_destroy(...)* is a function called after an entity is removed from the
persistence
*before_find(...)* is a function called before looking for an entity in the
persistence
*after_find(...)* is a function called after looking for an entity in the
persistence
*before_find_all(...)* is a function called before looking for entities in the
persistence
*after_find_all(...)* is a function called after looking for entities in the
persistence
*before_create(...)* is a function called before an entity is created
*after_create(...)* is a function called after an entity is created
*before_update(...)* is a function called before an entity is updated in the
persistence
*after_update(...)* is a function called after an entity is updated in the
persistence

###Examples

A very simple example of an entity without fields:

    person = entity{}

The same entity with an aspect and the empty default fields:

    person = entity{
        aspects={'timestampabble'},
        fields={}
        handlers={}
    }

A simple person entity with fields:

    person = entity{
        aspects={'timestampabble'},
        fields={
            id=key(),
            name=text(),
            age=integer(),
            sex=reference{M='Male', F='Female'}
        }
    }

