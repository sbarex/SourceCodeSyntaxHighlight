--[[
Sample plugin file for highlight 3.9
]]

Description="Convert keywords to lower case, if the syntax is not case sensitive."

Categories = {"format" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if IgnoreCase ~=true then
    return
  end

  function Decorate(token, state)
    if (state == HL_KEYWORD and not token:match("%W")) then
      return  string.lower(token)
    end
  end

end

Plugins={

  { Type="lang", Chunk=syntaxUpdate },

}
