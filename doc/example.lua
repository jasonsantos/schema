local schema = require'schema'

default = schema.expand(function()
  table_prefix = "tb_",
  default_type = "text",
  column_prefix = "f_",
  info = entity {
    fields = {
      id = key{},
      title = text{ size = 250 },
      summary = long_text{ },
      full_text = long_text{ },
      section = belongs_to{ "section" },
      author_name = text { },
      author_mail = text { },
      actor = has_one{ "actor" },
      creator_actor = has_one { "actor" },
      state = integer{
        size = 10,
        get =  function (f, v)
                 print 'Getting State...';
                 return v
               end
      },
    },
    before_save = function(...)
        print('We are going to save now")
        return true
    end
  }
end)

