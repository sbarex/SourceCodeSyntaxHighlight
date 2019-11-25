--[[
Sample plugin file for highlight 3.9
]]

Description="Add reference links to local C or C++ headers in HTML, LaTeX, RTF and ODT output. Set base_url in the plug-in script if needed."

Categories = {"c++", "html", "rtf", "latex", "odt" }


-- optional parameter: syntax description
function syntaxUpdate(desc)

    -- INSERT BASE URL HERE
  base_url=''

  if desc~="C and C++" then
    return
  end

  --see comment in themeUpdate
  table.insert( Keywords, { Id=#Keywords+1, Regex=[[\w+\.h[px]*]] } )

  function getURL(token)
    url=base_url..string.lower(token).. '.html'

    if (HL_OUTPUT== HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
      return '<a class="hl" target="new" href="' .. url .. '">'.. token .. '</a>'
    elseif (HL_OUTPUT == HL_FORMAT_LATEX) then
      return '\\href{'..url..'}{'..token..'}'
    elseif (HL_OUTPUT == HL_FORMAT_RTF) then
      return '{{\\field{\\*\\fldinst HYPERLINK "'..url..'" }{\\fldrslt\\ul\\ulc0 '..token..'}}}'
    elseif (HL_OUTPUT == HL_FORMAT_ODT) then
      return '<text:a xlink:type="simple" xlink:href="'..url..'">'..token..'</text:a>'
    end
  end

  function Decorate(token, state)

    if state==HL_PREPROC_STRING and string.find(token, "%w+.h[px]*")==1 then
      return getURL(token)
    end

  end
end


function themeUpdate(desc)
  -- no need to add a bogus style for the 6th keyword class defined in syntaxUpdate,
  -- the regex is just needed to get the complete token, but it will be recognized
  -- as string because string has higher priority

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="a.hl, a.hl:visited {color:inherit;font-weight:inherit;}"
  elseif (HL_OUTPUT==HL_FORMAT_LATEX) then
    Injections[#Injections+1]="\\usepackage[colorlinks=false, pdfborderstyle={/S/U/W 1}]{hyperref}"
  end
end

--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
