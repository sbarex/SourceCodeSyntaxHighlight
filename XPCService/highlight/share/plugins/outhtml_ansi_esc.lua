
Description="Replace ANSI Escape character by readable symbols"

Categories = {"format", "html" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
    return
  end


  function Decorate(token)
    if token == "\27" then
      -- return "<span class=\"hl esc\">ESC</span>"
      -- return "&#xFFFD;"
      return "&#x9243;"
    end

  end

end

Plugins={

  { Type="lang", Chunk=syntaxUpdate },

}
