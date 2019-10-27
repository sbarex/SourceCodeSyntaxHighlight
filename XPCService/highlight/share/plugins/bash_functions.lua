--[[
Sample plugin file for highlight 3.2

Adds additional function names to keyword list to recognize them later
without parantheses
]]

Description="Add function names to keyword list"
    
Categories = {"bash"}

-- optional parameter: syntax description
function syntaxUpdate(desc)
  if desc=="Bash" then

	--add function name pattern ("f_" prefix omitted but maybe reasonable)
	table.insert( Keywords,
                  { Id=5, Regex=[[(\w+)\s*\(]]
                  } )

    -- add keywords to list 5 if pattern matches
     function OnStateChange(oldState, newState, token, kwgroup)

       if newState==HL_KEYWORD and kwgroup==5 then
	  --if string.find(token, "f_%a+") then
	    AddKeyword(token, 5)
	  --end
	  --more patterns could be defined here
      end
      return newState
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
