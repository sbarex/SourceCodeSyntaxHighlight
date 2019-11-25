--[[
Sample plugin file for highlight 3.14

Assumes that CSS is enabled (ie Inline CSS is not set)
]]

Description="Shows matching parentheses and curly brackets in HTML output."

Categories = {"format", "html", "usability" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if (desc=="Bash") then
    return
  end

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    pID=0      -- just a sequential counter to generate HTML IDs
    pCnt=0     -- parenthesis counter to keep track of opening and closing pairs
    openPID={} -- save opening IDs as they are needed again for the close tag IDs

    HeaderInjection=[=[
<script type="text/javascript">
/* <![CDATA[ */
  function showMP(sender){
    var color=sender.id[1]=='p' ? 'yellow':'orange';
    sender.style.background= (sender.style.background=='') ?  color : '';
    var otherParenID = (sender.id[0]=='c') ? 'o' : 'c';
    otherParenID+=sender.id.substr(1);
    other=document.getElementById(otherParenID);
    other.style.background= (other.style.background=='') ? color : '';
  }
/* ]]> */
</script>
]=]
    end

  function getTag(token, id, kind)
    return '<span class="hl box" id="'..kind..'_'..id..'" onclick="showMP(this);">'..token..'</span>'
  end

  function getOpenParen(token, kind)
    pID=pID+1
    pCnt=pCnt+1
    openPID[pCnt] = pID
    return getTag(token, pID, kind)
  end

  function getCloseParen(token, kind)
    oID=openPID[pCnt]
    if oID then
      pCnt=pCnt-1
      return getTag(token, oID, kind)
    end
  end

  function Decorate(token, state)

    if (state ~= HL_OPERATOR or HL_OUTPUT ~= HL_FORMAT_HTML) then
      return
    end

    if string.find(token, '%(')==1 then
      return getOpenParen(token, 'op')
    end

    if string.find(token, '%)')==1 then
      return getCloseParen(token, 'cp')
    end

    if string.find(token, '%{')==1 then
      return getOpenParen(token, 'ob')
    end

    if string.find(token, '%}')==1 then
      return getCloseParen(token, 'cb')
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
