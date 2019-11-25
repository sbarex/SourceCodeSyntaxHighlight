
Description="Adds figure and figcapture in HTML output. Define capture as plug-in parameter."

Categories = {"format", "html" }

function syntaxUpdate(desc)
  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
    return
  end
  HeaderInjection="<figure class=\"hl\"><figcaption>"..HL_PLUGIN_PARAM.."</figcaption>\n"
  FooterInjection="\n</figure>"
end

function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then

    Injections[#Injections+1]=[[
figure.hl {
  margin-left: 0px;
  color: ]]..Default.Colour..[[;
}
  ]]
  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },
}
