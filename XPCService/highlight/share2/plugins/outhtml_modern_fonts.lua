--[[
Sample plugin file for highlight

Adds modern monospace fonts
]]

Description="Adds modern monospace fonts in HTML output"

Categories = {"format", "html", "usability" }


-- function to update theme definition
-- optional parameter: theme description
function themeUpdate()

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="pre.hl, ol.hl { font-family: Consolas,Monaco,\"Andale Mono\",\"Ubuntu Mono\",monospace;}"
  end

end


--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="theme", Chunk=themeUpdate }

}
