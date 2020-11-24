--[[
Sample plugin file for highlight 3.2

Adds additional function names to keyword list to recognize them later
without parentheses
]]

Description="Add function names to keyword list"

Categories = {"bash"}

-- optional parameter: syntax description
function syntaxUpdate(desc)
  if desc=="Bash" then

  table.insert( Keywords,
                  { Id=5, Regex=[[(\w+)\s*\(]]
                  } )

    if OnStateChange ~= nil then
      OrigOnStateChange = OnStateChange;
    end

    -- add keywords to list 5 if pattern matches
    function OnStateChange(oldState, newState, token, kwgroup)

      if newState==HL_KEYWORD and kwgroup==5 then
        AddKeyword(token, 5)
        return newState
      end
      if OrigOnStateChange then
        return OrigOnStateChange(oldState, newState, token, kwgroup)
      end
    end

  end
end

-- optional parameter: theme description
function themeUpdate(desc)
  if #Keywords==4 then
    table.insert(Keywords, {Colour= "#ff0000", Bold=true})
  end
end


--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="theme", Chunk=themeUpdate },
  { Type="lang", Chunk=syntaxUpdate },

}
