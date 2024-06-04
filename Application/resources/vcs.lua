
Description="Highlight VCS status."

Categories = { "format", "html", "rtf" }

-- function script_path()
--     local str = debug.getinfo(2, "S").source:sub(2)
--     return str:match("(.*/)")
-- end
-- dofile(script_path() .. "debug.lua") -- not work inside the embed engine.

function syntaxUpdate(desc)
    if HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML and HL_OUTPUT ~= HL_FORMAT_RTF then
        return
    end

    lines_added = { }
    lines_edited = { }
    lines_removed = { }

    VCS_DIFF = os.getenv("VCS_DIFF")
    if VCS_DIFF == nil or #VCS_DIFF == 0 then
        -- print("No VCS_DIFF arguments")
        return 
    end

    VCS_DIFF = VCS_DIFF .. ' '
    for range_src, range_dst in VCS_DIFF:gmatch("(%-.-) (%+.-) ") do
        range_src = range_src:sub(2)
	    if not string.find(range_src, ",") then
            range_src = range_src .. ",1"
        end
        range_src  = range_src .. ","
        local str2 = {}
        for i in range_src:gmatch("(%d-),") do
            str2[#str2 + 1] = tonumber(i)
            
        end 

        local range_src_start = str2[1]
        local range_src_n = str2[2]

        range_dst = range_dst:sub(2)
        if not string.find(range_dst, ",") then
            range_dst = range_dst .. ",1"
        end
        range_dst  = range_dst .. ","
        local str2 = {}
        for i in range_dst:gmatch("(%d-),") do
            str2[#str2 + 1] = tonumber(i)
        end 

        local range_dst_start = str2[1]
        local range_dst_n = str2[2]

        if range_dst_n == 0 then
            table.insert(lines_removed, range_dst_start + 1)
        else
            for i=0,range_dst_n-1,1 do
                if i < range_src_n then
                    -- added
                    table.insert(lines_edited, range_dst_start + i)
                else
                    -- added
                    table.insert(lines_added, range_dst_start + i)
                end
            end
        end
        
        ::continue::
    end


    local function has_value (tab, val)
        for index, value in ipairs(tab) do
            if value == val then
                return true
            end
        end
    
        return false
    end
    
    function IsLineMarked(lineNumber)
        if has_value(lines_added, lineNumber) then
            return '+'
        elseif has_value(lines_edited, lineNumber) then
            return 'M'
        elseif has_value(lines_removed, lineNumber) then
            return '-'
        else
            return ''
        end
    end

    -- we need a dummy kw class to get the line mark colour into the colour map
    if HL_OUTPUT == HL_FORMAT_RTF then
        -- Store the number of theme keyword groups used by the language syntax.
        id_keys = { }
        max_key = 0

        for _, keyword in pairs(Keywords) do
            if not has_value(id_keys, keyword["Id"]) then
                table.insert(id_keys, keyword["Id"])
                if keyword["Id"] > max_key then
                    max_key = keyword["Id"]
                end
            end
        end

        KeywordsThemeCount = tonumber(StoreValue("KeywordsThemeCount"))
        if max_key > KeywordsThemeCount then
            -- print("{ VCS disabled: the syntax language use more keywords (" .. max_key .. ") that the keywords defined in theme style (" .. KeywordsThemeCount .. "). }")
            return
        end
        
        -- Store the number of keyword groups used.
        StoreValue("KeywordsSyntaxCount", #id_keys)

        -- Add a dummy kw class to get the VCS colors into the colour map.
        table.insert( Keywords, { Id=KeywordsThemeCount+1, List={"HL_RTF_DUMMY_ADD" } } )
        table.insert( Keywords, { Id=KeywordsThemeCount+2, List={"HL_RTF_DUMMY_EDIT" } } )
        table.insert( Keywords, { Id=KeywordsThemeCount+3, List={"HL_RTF_DUMMY_DEL" } } )
    end

    currentMark = ''

    function DecorateLineBegin(lineNumber)
        currentMark = IsLineMarked(lineNumber)
        
        if HL_OUTPUT == HL_FORMAT_RTF then 
            local KeywordsThemeCount = tonumber(StoreValue("KeywordsThemeCount"))
            local KeywordsSyntaxCount = tonumber(StoreValue("KeywordsSyntaxCount"))
            local standardPropertiesCount = 13 -- number of standark theme properties
            local baseIndex = standardPropertiesCount + math.min(KeywordsThemeCount, KeywordsSyntaxCount) + 1
            if currentMark == '+' then
                patternIdx = baseIndex + 1 -- Index of the style which was added before
                -- cb: background color.
                -- cf10: use line number as foreground color.
                return '{\\cb' .. patternIdx .. '\\cf10{\\b{ + }\\b0}}'
            elseif currentMark == 'M' then
                patternIdx = baseIndex + 2
                return '{\\cb' .. patternIdx .. '\\cf10{\\b{ | }\\b0}}'
            elseif currentMark == '-' then
                patternIdx = baseIndex + 3
                return '{\\cb' .. patternIdx .. '\\cf10{\\b{ - }\\b0}}\\par{   }'
            else 
                return '{   }'
            end
        else
            if currentMark == '+' then
                return '<span class="hl vcs add" title="Line added.">'
            elseif currentMark == 'M' then
                return '<span class="hl vcs changed" title="Line changed.">'
            elseif currentMark == '-' then
                return '<hr class="hl vcs del" title="Line deleted." />' -- '<span class="hl vcs del" ></span>'
            else 
                return ''
            end
        end
    end
    
    function DecorateLineEnd(lineNumber)
        if HL_OUTPUT ~= HL_FORMAT_RTF and currentMark and (currentMark == '+' or currentMark == 'M') and currentMark ~= '-' then
            return '</span>'
        else
            return ''
        end
    end
end

function themeUpdate(desc)
    VCS_ADD = os.getenv("VCS_ADD")
    if VCS_ADD == nil or #VCS_ADD == 0 then
        VCS_ADD = "#009924" -- 00 153 36
    end

    VCS_EDIT = os.getenv("VCS_EDIT")
    if VCS_EDIT == nil or #VCS_EDIT == 0 then
        VCS_EDIT = "#1AABFF" -- 26 171 255
    end
    
    VCS_DEL = os.getenv("VCS_DEL")
    if VCS_DEL == nil or #VCS_DEL == 0 then
        VCS_DEL = "#ff0000" -- 255 0 0
    end
    
    if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
        function interp(s, tab)
            return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
        end
        local style = interp([[
        pre.hl {
            margin-left: 3em;
        }
        span.hl.vcs {
            position: relative;
        }
        span.hl.vcs::before {
            content: " ";
            display: block;
            position: absolute;
            width: 3em;
            text-align: center;
            left: -3em;
            color: ${ln_color};
            -webkit-user-select: none; 
        }
        span.hl.vcs.add::before {
            content: " + ";
            background-color: ${add_color};
            -webkit-user-select: none;
        }
        span.hl.vcs.changed::before {
            content: " | ";
            background-color: ${edit_color};
            -webkit-user-select: none;
        }
        span.hl.vcs.del::before {
            content: " - ";
            background-color: ${del_color};
            top: -.5em;
            -webkit-user-select: none;
        }
        hr.vcs.del {
            margin-left: -3em;
            width: calc(100vmax - 30px);
            -webkit-user-select: none; 
            border-top: 3px solid ${del_color};
            border-bottom: none;
            border-left: none;
            border-right: none;
        }
]], {
    add_color = VCS_ADD,
    edit_color = VCS_EDIT,
    del_color = VCS_DEL,
    ln_color = LineNum["Colour"]
 })
        Injections[#Injections+1] = style
    elseif (HL_OUTPUT == HL_FORMAT_RTF) then
        while #Keywords < 10 do
            -- Add some fake keywords to ensure that they are more than those used by the syntax language.
            table.insert( Keywords, { Colour=Default["Colour"] } ) -- Use the default color.
        end

        StoreValue("KeywordsThemeCount", #Keywords)

        -- Add the colors used by the VCS entries.
        table.insert(Keywords, {Colour=VCS_ADD})
        table.insert(Keywords, {Colour=VCS_EDIT})
        table.insert(Keywords, {Colour=VCS_DEL})
    end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },
}
