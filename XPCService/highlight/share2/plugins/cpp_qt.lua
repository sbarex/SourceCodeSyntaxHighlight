--[[
Sample plugin file for highlight

Adds additional keywords to C++ syntax description and corresponding
formatting in colour theme
]]

Description="Add Qt keywords to C and C++"

Categories = {"c++", "qt" }


-- optional parameter: syntax description
function syntaxUpdate(desc)
  if desc=="C and C++" then
  -- insert Qt keywords
  table.insert( Keywords,
                  { Id=1, List={"slots" }
                  } )
  table.insert( Keywords,
                  { Id=2, Regex=[[Q[A-Z]\w+]]
                  } )
  table.insert( Keywords,
                  { Id=5, List={"SIGNAL", "SLOT"}
                  } )
  table.insert( Keywords,
                  { Id=6, Regex=[[Q_[A-Z]+]]
                  } )
  end
end

-- optional parameter: theme description
function themeUpdate(desc)
  if #Keywords==4 then
    table.insert(Keywords, {Colour= Keywords[1].Colour, Italic=true}) -- SIGNAL, SLOT keywords
    table.insert(Keywords, {Colour= Keywords[2].Colour, Bold=true})   -- Q_* constants
  end
end


--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="theme", Chunk=themeUpdate },
  { Type="lang", Chunk=syntaxUpdate },

}
