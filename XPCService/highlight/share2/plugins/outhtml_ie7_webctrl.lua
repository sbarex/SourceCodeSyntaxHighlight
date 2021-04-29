--for highlight 3.57

Description="Adapt HTML to ancient MS Web Controls"

Categories = {"format", "html", "compatibility" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
    return
  end

  function DecorateLineBegin(lineNumber)
    return '&nbsp;'
  end

  if OnStateChange ~= nil then
      OrigOnStateChange = OnStateChange;
  end
  -- trigger OverrideParam
  function OnStateChange(oldState, newState, token, groupID, lineno, column)
    if (called==nil) then
      OverrideParam("format.spacer", "&nbsp;")
      OverrideParam("format.maskws", "true")
      called=1
    end
    if OrigOnStateChange then
        return OrigOnStateChange(oldState, newState, token, groupID, lineno, column)
    end
    return newState
  end

end

Plugins={

  { Type="lang", Chunk=syntaxUpdate },

}

--[[============================================================================
                                  CHANGELOG
================================================================================

v1.1 (2020/05/12) | Highlight 3.57

  - makes use of OverrideParam to change default HTML whitespace handling

v1.0
  - initial version

--]]
