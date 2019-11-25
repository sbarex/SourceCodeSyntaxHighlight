--[[
Sample plugin file for highlight 3.9
]]

Description="Add python.org reference links to HTML, LaTeX, RTF and ODT output of Python code"

Categories = {"python", "html", "rtf", "latex", "odt" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if desc~="Python" then
    return
  end

  function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
      return set
  end

  simple_items = Set {"assert","pass","del","print","return","yield","raise","break","continue","import","global","exec" }
  compound_items = Set {"if","while", "for","try", "with" }

  function getURL(token, cat)
    url='http://docs.python.org/reference/'..cat..'_stmts.html#the-'..token.. '-statement'

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

    if (state ~= HL_STANDARD and state ~= HL_KEYWORD) then
      return
    end

    if simple_items[token] then
      return getURL(token,'simple')
    elseif compound_items[token] then
      return getURL(token,'compound')
    end

  end
end

function themeUpdate(desc)
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
