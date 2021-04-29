--[[
Sample plugin file for highlight 3.9
]]

Description="Add hyperlinks in AsciiDoc files"

Categories = {"html", "asciidoc", "hyperlinks"}

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if desc~="AsciiDoc" then
    return
  end

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
      return
  end


  function Decorate(token, state, kwclass)

    if ( state ~= HL_KEYWORD or  #token == 0) then
      return
    end

    if kwclass==1 or kwclass==2  then
      return '<a href="'..token ..'">'.. token .. '</a>'
    end

  end
end


function themeUpdate(desc)

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
    return
  end
  -- inherit formatting of enclosing span tags
  Injections[#Injections+1]="a.hl, a.hl:visited {color:inherit;font-weight:inherit;}"
end

--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
