--[[
Adds ligature fonts
]]

Description="Adds ligature fonts in HTML output"

Categories = {"format", "html", "usability" }


function themeUpdate()

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="pre.hl, ol.hl { font-family: Monoid,\"Fira Code\",\"DejaVu Sans Code\",monospace;}"
  end

end

Plugins={

  { Type="theme", Chunk=themeUpdate }

}
