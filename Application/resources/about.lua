
Description="Highlight about info."

Categories = { "format", "html", "rtf" }

function formatUpdate(desc)
    function DocumentFooter(numFiles, currFile, options)
        if HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML then
            return "<div class='hl slc about'><hr size='1' />" .. os.getenv("SH_VERSION") .. "</div>"
        end
    end

end

function themeUpdate(desc)
    if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
        local style = [[
        .about {
            font-size: 72%;
            margin-top: 2.5em;
            padding-top: .5em;
            user-select: none;
            -webkit-user-select: none;
            text-align: center;
            font-family: 'ui-monospace';
        }
        .about hr {
            height: 0px;
            border-top: 1px solid rgba(0,0,0,.5);
            border-bottom: none;
            box-shadow: 0px 1px 0px rgba(255,255,255, .5);
        }
        .about a {
            color: inherit;
        }
        ]]
        Injections[#Injections+1] = style
    end
end


Plugins={
  { Type="format", Chunk=formatUpdate },
  { Type="theme", Chunk=themeUpdate }
}
