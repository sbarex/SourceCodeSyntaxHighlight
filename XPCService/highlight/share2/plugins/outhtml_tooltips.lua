
Description="Add HTML tooltips within comments linked to circled numbers (format as @tip[tooltip text])"

Categories = {"format", "html", "usability" }

function syntaxUpdate(desc)

  ttCnt=0 -- tooltip counter

  table.insert( Keywords,
        { Id=102,
          Regex=[=[\@tip\[.+\]]=],
          Group=0
        })

  function Decorate(token, state)
    if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
      return
    end

    if (state ~= HL_LINE_COMMENT and state ~= HL_BLOCK_COMMENT) then
      return
    end

    title = string.match(token, "%@tip%[(.+)%]")
    if title~=nil then
          if ttCnt>19 then ttCnt=0 end
          ttCnt = ttCnt + 1
      -- use Unicode circle entities 1..20
          return '<span style="font-style: normal;" title="' .. title ..'">&#'..(ttCnt + 9311)..';</span>'
    end

  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
}
