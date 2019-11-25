--[[

Sample plugin file for highlight 3.45
]]

Description="Inserts a section into each LaTeX output file to concatenate the results later"

Categories = {"latex" }

function formatUpdate(desc)

    function DocumentHeader(numFiles, currFile, options)
        if (HL_OUTPUT == HL_FORMAT_LATEX and numFiles > 1) then
            title=string.gsub(options.title,"_","\\textunderscore ")
            return  "\\section{"..title.."}\n", currFile == 1
        end
    end

    function DocumentFooter(numFiles, currFile, options)
        if (HL_OUTPUT == HL_FORMAT_LATEX and numFiles > 1 ) then
            return "", currFile==numFiles
        end
    end

end

Plugins={

  { Type="format", Chunk=formatUpdate }

}
