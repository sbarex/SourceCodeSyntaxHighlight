--[[
Sample plugin file for highlight

Adds a line to the left of the code box
]]

Description="Adds a line to the left of the code box in HTML output"

Categories = {"format", "html" }

-- function to update theme definition
-- optional parameter: theme description
function themeUpdate()

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="pre.hl, ol.hl { padding-left: 1em; border-left: 5px solid "..Keywords[1].Colour..";}"
  end

end


--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="theme", Chunk=themeUpdate }

}
