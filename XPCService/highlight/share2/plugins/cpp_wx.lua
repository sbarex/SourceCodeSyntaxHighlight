--[[

Sample plugin file for highlight 3.1

Adds additional keywords to C++ syntax description

USAGE: highlight -I main.cpp --plug-in=plugin.lua
]]

Description="Add wxWidgets class names to C and C++ keywords"

Categories = {"c++", "wxwidgets" }

-- optional parameter: syntax description
function syntaxUpdate(desc)
  if desc=="C and C++" then
    -- insert wxWidgets keywords
    table.insert( Keywords,
                  { Id=2, Regex=[[wx[A-Z]\w+]]
                  } )
  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
}
