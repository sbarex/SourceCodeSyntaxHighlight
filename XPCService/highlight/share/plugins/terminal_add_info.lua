--[[

Sample plugin file for highlight 3.45
]]

Description="Adds file information to terminal output (ansi, xterm, truecolor)"

Categories = {"format", "ansi", "xterm", "truecolor" }

function formatUpdate(desc)

    function DocumentHeader(numFiles, currFile, options)
        if (HL_OUTPUT == HL_FORMAT_ANSI or HL_OUTPUT == HL_FORMAT_XTERM256 or HL_OUTPUT==HL_FORMAT_TRUECOLOR) then
            return  ">>> FILE "..string.format("%d",currFile).."/"..string.format("%d", numFiles).." ".. options.title .. ":\n"
        end
    end

    function DocumentFooter(numFiles, currFile, options)
        if (HL_OUTPUT == HL_FORMAT_ANSI or HL_OUTPUT == HL_FORMAT_XTERM256 or HL_OUTPUT==HL_FORMAT_TRUECOLOR) then
            return ">>>END OF FILE\n"
        end
    end

end

Plugins={

  { Type="format", Chunk=formatUpdate }

}
