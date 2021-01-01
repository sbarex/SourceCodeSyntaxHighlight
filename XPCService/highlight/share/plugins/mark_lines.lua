
Description="Marks the lines defined as comma separated list or range in the plug-in parameter (HTML, RTF or Truecolor/xterm256 Escape)."

Categories = {"format", "html", "rtf", "truecolor", "xterm256" }

function syntaxUpdate(desc)

  if HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML and HL_OUTPUT ~= HL_FORMAT_RTF
      and HL_OUTPUT ~= HL_FORMAT_TRUECOLOR and HL_OUTPUT ~= HL_FORMAT_XTERM256  then
      return
  end

  if #HL_PLUGIN_PARAM == 0 then return end

  ansiOpenSeq = StoreValue("ansiOpenSeq")

  -- we need a dummy kw class to get the line mark colour into the colour map
  if HL_OUTPUT == HL_FORMAT_RTF then
    table.insert( Keywords, { Id=#Keywords+1, List={"HL_RTF_DUMMY" } } )
  end

  -- explode (separator, string)
  function explode(d,p)
    local t, ll
    t={}
    ll=0
    if(#p == 1) then
      t[tonumber(p)] = 1
      return t
    end
    while true do
      l=string.find(p,d,ll,true) -- find the next d in the string
      if l~=nil then -- if "not not" found then..
        t[tonumber(string.sub(p,ll,l-1))] = 1
        ll=l+1 -- save just after where we found it for searching next time.
      else
        t[tonumber(string.sub(p,ll))] = 1
        break -- Break at end, as it should be, according to the lua manual.
      end
    end
    return t
  end

  function range(p)
    local t, ll
    t={}
    ll=0
    l=string.find(p,'-',ll,true)
    if l~=nil then
      for i=tonumber(string.sub(p,ll,l-1)), tonumber(string.sub(p,l+1)), 1 do
        t[i] = 1
      end
    end
    return t
  end

  if (string.find(HL_PLUGIN_PARAM,'-')) == nil then
    linesToMark=explode(',', HL_PLUGIN_PARAM)
  else
    linesToMark=range(HL_PLUGIN_PARAM)
  end

  currentLineNumber=0
  currentColumn=0
  markStarts=true
  linesNoIdent = {}

  if OnStateChange ~= nil then
    OrigOnStateChange = OnStateChange;
  end

  function OnStateChange(oldState, newState, token, groupID, lineno, column)

    -- a bit rough using cursor movement and resetting space properties but
    -- this kind of stuff is not intended at all in the core code
    if (HL_OUTPUT==HL_FORMAT_TRUECOLOR or HL_OUTPUT==HL_FORMAT_XTERM256) then
      if  linesToMark[currentLineNumber] then
        OverrideParam("format.spacer", ansiOpenSeq.." ")
        OverrideParam("format.maskws", "true")

        if (currentColumn==0) then
          currentColumn = column
          if column> 1 then
            if markStarts then
              io.write("\x1B["..string.format("%d", 1).."C")
            elseif not linesNoIdent[currentLineNumber] then
              io.write("\x1B["..string.format("%d", column).."D")
            end
            io.write(ansiOpenSeq)
            if markStarts then
              io.write(string.rep(" ", column))
              io.write("\x1B["..string.format("%d", column+1).."D")
            elseif not linesNoIdent[currentLineNumber] then
              io.write(string.rep(" ", column))
            end
            markStarts=false
          else
            linesNoIdent[currentLineNumber] = 1
          end
        end
      else
        markStarts=true
        OverrideParam("format.spacer", " ")
        OverrideParam("format.maskws", "false")
      end

    end

    if OrigOnStateChange then
        return OrigOnStateChange(oldState, newState, token, groupID, lineno, column)
    end
    return newState
  end

  function Decorate(token, state)
    if ((HL_OUTPUT==HL_FORMAT_TRUECOLOR or HL_OUTPUT==HL_FORMAT_XTERM256) and linesToMark[currentLineNumber]) then
      return ansiOpenSeq..token
    end
  end

  function DecorateLineBegin(lineNumber)
    currentLineNumber = lineNumber
    currentColumn=0

    if (linesToMark[currentLineNumber]) then
      if HL_OUTPUT==HL_FORMAT_TRUECOLOR or HL_OUTPUT==HL_FORMAT_XTERM256 then
          OverrideParam("format.spacer", ansiOpenSeq.." ")
          OverrideParam("format.maskws", "true")
          return ansiOpenSeq
      end
      if HL_OUTPUT==HL_FORMAT_RTF then
        patternIdx = 12 + #Keywords  -- Index of the style which was added before
        return '\\chcbpat'..patternIdx..'{'
      end
      return '<span class="hl mark">'
    end
  end

  function DecorateLineEnd()
    if (linesToMark[currentLineNumber]) then
      if HL_OUTPUT==HL_FORMAT_TRUECOLOR or HL_OUTPUT==HL_FORMAT_XTERM256 then
          OverrideParam("format.spacer", " ")
          OverrideParam("format.maskws", "false")
          return ""
      end
      if HL_OUTPUT==HL_FORMAT_RTF then
          return '}'
      end
      return '</span>'
    end
  end

end

function themeUpdate(desc)

  function lighten(colour, fmt)
    if string.match(colour, "#%x+")==nil then
      return string.format(fmt, 0, 0, 0)
    end

    base_rr = ("0x"..string.match(colour, "%x%x", 2))
    base_gg = ("0x"..string.match(colour, "%x%x", 4))
    base_bb = ("0x"..string.match(colour, "%x%x", 6))

    min_bright=math.min(base_rr, base_gg, base_bb)
    max_bright=math.max(base_rr, base_gg, base_bb)
    brightness = (min_bright + max_bright) / (255*2.0)

    if (brightness < 0.1) then
      return string.format(fmt, 68, 68, 68)
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

    -- konsole supports up to 0x99, what about other emulators?
    maxval = 255
    if (HL_OUTPUT == HL_FORMAT_TRUECOLOR) then maxval = 153 end
    if (rr>maxval) then rr = maxval end
    if (gg>maxval) then gg = maxval end
    if (bb>maxval) then bb = maxval end

    return string.format(fmt, rr, gg, bb)
  end

  if (HL_OUTPUT == HL_FORMAT_TRUECOLOR) then
    StoreValue("ansiOpenSeq", lighten(Canvas.Colour, "\x1B[48;2;%03d;%03d;%03dm"))
  elseif (HL_OUTPUT == HL_FORMAT_XTERM256) then
    --https://gist.github.com/MicahElliott/719710/8b8b962033efed8926ad8a8635b0a48630521a67
    lightCanvas = lighten(Canvas.Colour, "%03d %03d %03d")
    rr = tonumber(string.match(lightCanvas, "%d%d%d", 0))
    gg = tonumber(string.match(lightCanvas, "%d%d%d", 4))
    bb = tonumber(string.match(lightCanvas, "%d%d%d", 8))
    approx = math.floor(36 * (rr * 5) + 6 * (gg * 5) + (bb * 5) + 16)
    StoreValue("ansiOpenSeq", "\x1B[48;5;"..approx.."m")
  elseif (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]=".hl.mark { background-color:"..lighten(Canvas.Colour, "#%02x%02x%02x").."; width:100%;float:left;}"
  elseif (HL_OUTPUT == HL_FORMAT_RTF) then
    table.insert(Keywords, {Colour=lighten(Canvas.Colour, "#%02x%02x%02x")})
  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },
}
