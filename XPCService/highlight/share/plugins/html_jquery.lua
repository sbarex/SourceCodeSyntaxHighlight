
Description="Embed JQuery"

Categories = {"html"}


function formatUpdate(desc)
    local open = io.open

    function read_file(path)
        local file = open(path, "rb") -- r read mode and b binary mode
        if not file then return nil end
        local content = file:read "*a" -- *a or *all reads the whole file
        file:close()
        return content
    end

    function script_path()
       local str = debug.getinfo(2, "S").source:sub(2)
       return str:match("(.*/)")
    end


    function DocumentHeader(numFiles, currFile, options)
        if (HL_OUTPUT == HL_FORMAT_HTML and numFiles >= 1) then
            local f = read_file(script_path() .. "jquery-3.4.1.min.js")
            return  "<script type='text/javascript'>" .. f .. "</script>\n", true
        end
    end
    --[[
    function DocumentFooter(numFiles, currFile, options)
        if (HL_OUTPUT == HL_FORMAT_LATEX and numFiles > 1 ) then
            return "", currFile==numFiles
        end
    end
    --]]
end

Plugins={

  { Type="format", Chunk=formatUpdate }

}
