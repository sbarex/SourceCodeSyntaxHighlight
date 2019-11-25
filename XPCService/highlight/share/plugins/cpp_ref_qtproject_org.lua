
Description="Add doc.qt.io reference links to HTML, LaTeX, RTF and ODT output of C++ code"

Categories = {"c++", "qt", "html", "rtf", "latex", "odt" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if desc~="C and C++" then
    return
  end

  function getURL(token)
    url='http://doc.qt.io/qt-5/'..string.lower(token).. '.html'

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
    if (state ~= HL_STANDARD and state ~= HL_KEYWORD and state ~=HL_PREPROC) then
      return
    end
    if string.find(token, "Q%u%l")==1 then
      return getURL(token)
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

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
