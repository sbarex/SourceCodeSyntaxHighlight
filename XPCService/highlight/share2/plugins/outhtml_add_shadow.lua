--[[
Sample plugin file for highlight

Adds a shadow and margin to the code box
]]

Description="Adds a shadow and margin to the code box in HTML output (intended for bright themes)"

Categories = {"format", "html" }


-- function to update theme definition
-- optional parameter: theme description
function themeUpdate()

  function lighten(colour)
    if string.match(colour, "#%x+")==nil then
      return "#ffffff"
    end
    rr=50 + ("0x"..string.match(colour, "%x%x", 2))
    gg=50 + ("0x"..string.match(colour, "%x%x", 4))
    bb=50 + ("0x"..string.match(colour, "%x%x", 6))
    if (rr>255) then rr = 255 end
    if (gg>255) then gg = 255 end
    if (bb>255) then bb = 255 end
    return string.format("#%02x%02x%02x", rr, gg, bb)
  end

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="pre.hl, ol.hl { margin:2em; box-shadow:10px 10px 0.5em "..lighten(Default.Colour).."; border: 1px solid "..lighten(Default.Colour)..";}"
    Injections[#Injections+1]="pre.hl {padding:1em;}"
    Injections[#Injections+1]="ol.hl {padding:1em 1em 1em 4em;}"
    Injections[#Injections+1]="body.hl { background-color:"..lighten(Canvas.Colour).."; }"
  end

end

Plugins={

  { Type="theme", Chunk=themeUpdate }

}
