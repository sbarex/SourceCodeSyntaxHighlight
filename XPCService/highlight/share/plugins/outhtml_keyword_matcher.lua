

Description="Shows matching keywords in HTML output. Define the keyword group as plug-in parameter."

Categories = {"format", "html", "usability" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then

    -- can use 1 to 4, depending on the syntax definition
    keywordGroup=1
    if (#HL_PLUGIN_PARAM>0) then keywordGroup = tonumber(HL_PLUGIN_PARAM) end

    kwID = { }
    kwIDCnt=0

    HeaderInjection=[[
      <script type="text/javascript">
      function showSameKW(sender){
        var myRegexp = /(kw_\d+)/;
        var kwID = myRegexp.exec(sender.id)[1];
        var elements=document.getElementsByTagName('span');
        for (var i = 0; i < elements.length; i++) {
          if (elements[i].id.indexOf( kwID)==0 && myRegexp.exec(elements[i].id)[1] ==  kwID){
            elements[i].style.background= (elements[i].style.background=='') ? 'yellow': '';
          }
        }
      }
      </script>
]]
  end


  if OnStateChange ~= nil then
      OrigOnStateChange = OnStateChange;
  end

  --may be triggered twice per keyword
  function OnStateChange(oldState, newState, token, kwgroup, lineno, column)
    if newState==HL_KEYWORD  and kwgroup==keywordGroup then

      if kwID[token] == nil then
        kwIDCnt=kwIDCnt+1
        kwID[token] = { }
        kwID[token][0] = kwIDCnt
        kwID[token][1] = 1
      else
        kwID[token][1] = kwID[token][1] + 1
      end

    end
    if OrigOnStateChange then
        return OrigOnStateChange(oldState, newState, token, kwgroup, lineno, column)
    end
    return newState
  end

  function Decorate(token, state)
    if (state ~= HL_KEYWORD or kwID[token]==nil or HL_OUTPUT ~= HL_FORMAT_HTML) then
      return
    end
    return '<span class="hl box" id="kw_'..kwID[token][0]..'_'..kwID[token][1]..'" onclick="showSameKW(this);">'..token..'</span>'
  end

end


function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]=".hl.box { border-width:1px;border-style:dotted;border-color:gray; cursor: pointer;}"
  end
end

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
