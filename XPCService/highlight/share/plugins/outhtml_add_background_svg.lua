--[[
Sample plugin file for highlight

Adds a background pattern using an inline SVG
]]

Description="Adds a background inline SVG pattern for HTML output (edit parameters in the file)"

Categories = {"format", "html" }

-- function to update theme definition
-- optional parameter: theme description
function themeUpdate()

  --EDIT to change grid size
  gridsize = 25

  function lighten(colour)
    if string.match(colour, "#%x+")==nil then
      return "rgb(0,0,0)"
    end

    base_rr = ("0x"..string.match(colour, "%x%x", 2))
    base_gg = ("0x"..string.match(colour, "%x%x", 4))
    base_bb = ("0x"..string.match(colour, "%x%x", 6))

    min_bright=math.min(base_rr, base_gg, base_bb)
    max_bright=math.max(base_rr, base_gg, base_bb)
    brightness = (min_bright + max_bright) / (255*2.0)

    if (brightness < 0.1) then
      return "rgb(50,50,50)"
    elseif (brightness < 0.5) then
      percent = 100
    elseif (brightness > 0.95) then
      percent = -10
    else
      percent = 80
    end

    rr = math.floor(base_rr * (100 + percent) / 100 )
    gg = math.floor(base_gg * (100 + percent) / 100 )
    bb = math.floor(base_bb * (100 + percent) / 100 )

    if (rr>255) then rr = 255 end
    if (gg>255) then gg = 255 end
    if (bb>255) then bb = 255 end
    return string.format("rgb(%d,%d,%d)", rr, gg, bb)
  end

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then

    -- EDIT Play with the x and y coordinates of the lines to obtain different patterns
    Injections[#Injections+1]="pre.hl, ol.hl { background-image: url(\"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='"..gridsize..
      "'  height='"..gridsize.."'><line x1='0' y1='0' x2='0' y2='"..gridsize.."' style='stroke:"..lighten(Canvas.Colour)..
      ";stroke-width:1'/><line x1='0' y1='0' x2='"..gridsize.."' y2='0' style='stroke:"..lighten(Canvas.Colour)..
      ";stroke-width:1'/></svg>\");}"
  end
end

--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files
Plugins={

  { Type="theme", Chunk=themeUpdate }

}
