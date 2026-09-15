
Description="Highlight about info."

Categories = { "format", "html", "rtf" }

function formatUpdate(desc)
    function DocumentFooter(numFiles, currFile, options)
        local value = os.getenv("SH_NAME")
        local name = (value ~= nil and value ~= "") and value or "Syntax Highlight"

        value = os.getenv("SH_VERSION")
        local version = (value ~= nil and value ~= "") and ("(" .. value .. ")") or ""

        value = os.getenv("SH_COPYRIGHT")
        local copyright = (value ~= nil and value ~= "") and value or "Developed by Sbarex"

        value = os.getenv("SH_URL")
        local url = (value ~= nil and value ~= "") and value or "https://github.com/sbarex/SourceCodeSyntaxHighlight"

        local text = ""
        local fontsize = ((value ~= nil and value ~= "") and tonumber(value) or 13) * 2
        if HL_OUTPUT == HL_FORMAT_RTF then
            value = os.getenv("SH_FONT_SIZE")
            
            text = [[
{\cbpat1
    {\pard\cs5\cf5\ql\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\par}
    {\pard\cs5\cf5\fs%{font_size}
        {\field{\*\fldinst{HYPERLINK "%{url"}}{\fldrslt{{\cs5 %{name}}}}} %{version}\par
        %{copyright} with love \u10084?\u65039?\par
        If you like this app, {\field{\*\fldinst{HYPERLINK "https://www.buymeacoffee.com/sbarex"}}{\fldrslt{{\b\cs5 buy me a coffee}}}}\par}
    {\*\endcopyright}
}
]]
            text = [[
{\cbpat1
{\pard\cs5\cf5\ql\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\u9472?\par}
{\pard\cs5\cf5\fs%{fontsize}
{\b %{name}} %{version}\par
%{copyright} with love \u10084?\u65039?\par
%{url}\par
\par

If you like this app, {\b buy me a coffee!}\par
https://www.buymeacoffee.com/sbarex}
{\*\endcopyright}
}
]]
        elseif HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML then
            text = "\
<div class='hl slc about'>\
<hr size='1' />\
<a href='%{url}'>%{name}</a> %{version}<br />\
%{copyright} with <span style='font-style: normal'>❤️</span><br/>\
If you like this app, <a href='https://www.buymeacoffee.com/sbarex'><strong>buy me a coffee</strong></a>\
</div>\
"
        else
            text = ""
        end

        return string.gsub(text, "%%{(%w+)}", {
            fontsize = math.floor(fontsize * 0.75 + 0.5),
            url = url,
            name = name,
            version = version,
            copyright = copyright
        }), true

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
