
Description="Marks the lines defined as comma separated list in the plug-in parameter (HTML and RTF only)."

Categories = {"format", "html", "rtf" }


function syntaxUpdate(desc)
   
  if HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML  
      and HL_OUTPUT ~= HL_FORMAT_RTF then return end
  
  if #HL_PLUGIN_PARAM == 0 then return end
  
  --we need a dummy kw class to get the line mark colour into the colour map
  if HL_OUTPUT == HL_FORMAT_RTF then
    table.insert( Keywords, { Id=#Keywords+1, List={"HL_RTF_DUMMY" } } )
  end
  
  -- explode(seperator, string)
  function explode(d,p)
     local t, ll
     t={}
     ll=0
     if(#p == 1) then return {p} end
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

  linesToMark=explode(',', HL_PLUGIN_PARAM)
  currentLineNumber=0

  function DecorateLineBegin(lineNumber)
    currentLineNumber = lineNumber
    if (linesToMark[currentLineNumber]) then
      if HL_OUTPUT==HL_FORMAT_RTF then
        patternIdx = 12 + #Keywords  -- Index of the style which was added before
        return '\\chcbpat'..patternIdx..'{'
      end
      return '<span class="hl mark">'
    end
  end

  function DecorateLineEnd()
    if (linesToMark[currentLineNumber]) then
      if HL_OUTPUT==HL_FORMAT_RTF then
          return '}'
      end
      return '</span>'
    end
  end
  
end

function themeUpdate(desc)
  
  function lighten(colour)
    if string.match(colour, "#%x+")==nil then
      return "#000000"
    end
    
    base_rr = ("0x"..string.match(colour, "%x%x", 2))
    base_gg = ("0x"..string.match(colour, "%x%x", 4))
    base_bb = ("0x"..string.match(colour, "%x%x", 6))
    
    min_bright=math.min(base_rr, base_gg, base_bb)
    max_bright=math.max(base_rr, base_gg, base_bb)
    brightness = (min_bright + max_bright) / (255*2.0)
    
    if (brightness < 0.1) then
      return "#444444"
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
    return string.format("#%02x%02x%02x", rr, gg, bb)
  end
  
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]=".hl.mark { background-color:"..lighten(Canvas.Colour).."; width:100%;float:left;}"
  elseif (HL_OUTPUT == HL_FORMAT_RTF) then
    table.insert(Keywords, {Colour=lighten(Canvas.Colour)})
  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },
}
