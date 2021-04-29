--[[
Sample plugin file for highlight 3.9
]]

Description="Add tooltips based on a ctags file (default input file: tags)"

Categories = {"ctags", "html" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
      return
  end

  function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
  end

--tbd:
--case 'F': return  "file";
--case 'g': return  "enumeration name";
--case 'n': return  "namespace";
--case 'p': return  "function prototype";
--case 's': return  "structure name";
--case 't': return  "typedef";
--case 'u': return  "union name";
--case 'v': return  "variable";

  knowntags={}

  if #HL_PLUGIN_PARAM==0 then HL_PLUGIN_PARAM='tags' end
  --print("file:" .. HL_PLUGIN_PARAM)
  file = assert(io.open(HL_PLUGIN_PARAM, "r"))

  for line in file:lines() do
    if line[1]~='!' then
      items=string.split(line, '\t')
      if #items==4 then
        if items[4]=='d' then
          knowntags[items[1]] = 'define | '.. items[2]
        end
            elseif #items==6 then
        if items[5]=='e' then
          knowntags[items[1]] = 'enumerator | '..items[6] ..' | '.. items[2]
        elseif items[5]=='m' then
          knowntags[items[1]] = 'member | '..items[6] ..' | '.. items[2]
        elseif items[5]=='c' then
          knowntags[items[1]] = 'class | '..items[6] ..' | '.. items[2]
        elseif items[5]=='f' then
          knowntags[items[1]] = 'function | '..items[6] ..' | '.. items[2]
        end
      end
    end
  end


  function Decorate(token, state, kwclass)

    if ( state ~= HL_STANDARD and state ~= HL_KEYWORD and state ~=HL_PREPROC) then
      return
    end

    for k,v in pairs(knowntags) do
      if k==token  then
  return '<span title="'..v..'">'..token .. '</span>'
      end
    end

  end
end


Plugins={

  { Type="lang", Chunk=syntaxUpdate },

}
