--[[

Sample plugin file for highlight 3.1

Invert colours of the original theme

USAGE: highlight -I main.cpp --plug-in=plugin.lua
]]

Description="Invert colours of the original theme"

Categories = {"format" }


-- function to update theme definition
-- optional parameter: theme description
function themeUpdate()

  function invert(colour)
    if string.match(colour, "#%x+")==nil then
      return "#000000"
    end
    rr=255 - ("0x"..string.match(colour, "%x%x", 2))
    gg=255 - ("0x"..string.match(colour, "%x%x", 4))
    bb=255 - ("0x"..string.match(colour, "%x%x", 6))
    return string.format("#%02x%02x%02x", rr, gg, bb)
  end

  Description = Description .. " (inverted)"

  Default.Colour=invert(Default.Colour)
  Canvas.Colour=invert(Canvas.Colour)
  Number.Colour=invert(Number.Colour)
  Escape.Colour=invert(Escape.Colour)
  String.Colour=invert(String.Colour)
  StringPreProc.Colour=invert(StringPreProc.Colour)
  BlockComment.Colour=invert(BlockComment.Colour)
  LineComment.Colour=invert(LineComment.Colour)
  PreProcessor.Colour=invert(PreProcessor.Colour)
  LineNum.Colour=invert(LineNum.Colour)
  Operator.Colour=invert(Operator.Colour)

  for k, v in pairs(Keywords) do
    v.Colour=invert(v.Colour)
  end
end


--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="theme", Chunk=themeUpdate }

}
