Description="Generate coloured bio sequences in Sequence Alignment Maps"

-- optional parameter: syntax description
function syntaxUpdate(desc)

  t = {}
  t["A"] = "144;238;144" --144, 238, 144
  t["T"] = "240;128;128" --240, 128, 128
  t["C"] = "173;216;230" --173, 216, 230
  t["G"] = "255;160;122" --255, 160, 122

  function Decorate(token, state, kwclass)

    if ( (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML or HL_OUTPUT == HL_FORMAT_TRUECOLOR)
        and #token > 63 and state == HL_KEYWORD and not string.match(token,"[^ATCG]") ) then

      retVal = ""
      for c in token:gmatch"." do
        if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
          retVal = retVal .. "<span class='elem_".. c .. "'>".. c .. "</span>"
        elseif (HL_OUTPUT == HL_FORMAT_TRUECOLOR) then
          retVal = retVal .. "\27[48;2;".. t[c] .. "m".. c .. "\27m"
        end
      end
      return retVal
    end
  end
end

function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then

    Injections[#Injections+1]=[[
span.elem_A {
  background-color: lightgreen;
}
span.elem_T {
  background-color: lightcoral;
}
span.elem_C {
  background-color: lightblue;
}
span.elem_G {
  background-color: lightsalmon;
}
]]
  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate }
}
