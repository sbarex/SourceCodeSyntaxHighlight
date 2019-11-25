
Description="Modify URLs within comments to clickable hyperlinks in HTML, LaTeX, ODT and RTF output"

Categories = {"html", "rtf", "latex", "odt", "hyperlinks" }

function syntaxUpdate(desc)

  table.insert( Keywords,
        { Id=100,
                Regex=[[https?\:\/\/[\w\./&\?\-\+\,\;\=\:\(\)]+]]
                })
  table.insert( Keywords,
                { Id=101,
                Regex=[[[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+]]
                })

  function getURL(token)

    if (HL_OUTPUT== HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
      return '<a class="hl" target="new" href="' .. token .. '">'.. token .. '</a>'
    elseif (HL_OUTPUT == HL_FORMAT_LATEX) then
      return '\\href{'..token..'}{'..token..'}'
    elseif (HL_OUTPUT == HL_FORMAT_RTF) then
      return '{{\\field{\\*\\fldinst HYPERLINK "'..token..'" }{\\fldrslt\\ul\\ulc0 '..token..'}}}'
    elseif (HL_OUTPUT == HL_FORMAT_ODT) then
      return '<text:a xlink:type="simple" xlink:href="'..token..'">'..token..'</text:a>'
    end
  end

  function getMailURL(token)
    if (HL_OUTPUT== HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
      return '<a class="hl" href="mailto:' .. token .. '">'.. token .. '</a>'
    end
  end

  function Decorate(token, state)

    if (state ~= HL_LINE_COMMENT and state ~= HL_BLOCK_COMMENT) then
      return
    end

    if string.find(token, "https?://")==1 then
      return getURL(token)
    end

    if string.find(token, "[%w%p]+@[%w%p]+%.%a+")==1 then
      return getMailURL(token)
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
