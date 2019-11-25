--[[
Sample plugin file for highlight

Adds background stripes
]]

Description="Adds background stripes in HTML output "

Categories = {"format", "html" }

-- function to update theme definition
-- optional parameter: theme description
function themeUpdate()

  function lighten(colour)
    if string.match(colour, "#%x+")==nil then
      return "rgba(0,0,0,0)"
    end

    base_rr = ("0x"..string.match(colour, "%x%x", 2))
    base_gg = ("0x"..string.match(colour, "%x%x", 4))
    base_bb = ("0x"..string.match(colour, "%x%x", 6))

    min_bright=math.min(base_rr, base_gg, base_bb)
    max_bright=math.max(base_rr, base_gg, base_bb)
    brightness = (min_bright + max_bright) / (255*2.0)

    if (brightness < 0.1) then
      return "rgba(50,50,50, 0.5)"
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
    return string.format("rgba(%d,%d,%d,0.25)", rr, gg, bb)
  end

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then

    -- inspired by prismjs ;)
    Injections[#Injections+1]="pre.hl { background-image: linear-gradient(transparent 50%, "..lighten(Canvas.Colour)..
      " 50%); background-size:3em 3em; background-origin:content-box; font-size:100%/1.5;line-height: 1.5; }"
  end
end

--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files
Plugins={

  { Type="theme", Chunk=themeUpdate }

}
