--[[
Sample plugin file for highlight 3.14

Assumes that CSS is enabled (ie Inline CSS is not set)
]]

Description="Shows matching curly brackets in HTML output."

Categories = {"format", "html", "usability" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if (desc=="Bash") then
    return
  end

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    pID=0     -- just a sequential counter to generate HTML IDs
    pCount=0    -- parenthesis counter to keep track of opening and closing pairs
    openPID={} -- save opening IDs as they are needed again for the close tag IDs

    HeaderInjection=[=[
<script type="text/javascript">
  /* <![CDATA[ */
  function showMB(sender){
    sender.style.background= (sender.style.background=='') ?  'yellow' : '';
    var otherParenID = (sender.id[0]=='c') ? 'o' : 'c';
    otherParenID+=sender.id.substr(1);
    other=document.getElementById(otherParenID);
    other.style.background= (other.style.background=='') ? 'yellow': '';
  }
  /* ]]> */
</script>
]=]
  end

  function getTag(token, id, kind)
    return '<span class="hl box" id="'..kind..'b_'..id..'" onclick="showMB(this);">'..token..'</span>'
  end

  function getOpenParen(token)
    pID=pID+1
    pCount=pCount+1
    openPID[pCount] = pID
    return getTag(token, pID, 'o')
  end

  function getCloseParen(token)
    oID=openPID[pCount]
    if oID then
      pCount=pCount-1
      return getTag(token, oID, 'c')
    end
  end

  function Decorate(token, state)

    if (state ~= HL_OPERATOR or HL_OUTPUT ~= HL_FORMAT_HTML) then
      return
    end

    if string.find(token, "{")==1 then
      return getOpenParen(token)
    end

    if string.find(token, "}")==1 then
      return getCloseParen(token)
    end

  end
end


function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]=".hl.box { border-width:1px;border-style:dotted;border-color:gray; cursor: pointer;}"
  end
end
--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
