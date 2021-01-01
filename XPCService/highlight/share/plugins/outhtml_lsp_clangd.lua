--[[

This is a rough test implementation of the Language Server Protocol to get
things started.

This only works with absolute input paths which are part of a workspace
configured properly for the clangd LSP server.

Temp files in /tmp/ are not deleted.

To synchronize I/O using stdin/stdout, the script sleeps after each call.

1.  Copy this Lua JSON parser to your current directory:
    https://github.com/rxi/json.lua
2.  Setup your project for clangd (ie provide a compile_flags.txt file)
3.  Call the plugin with the project direcory and the source file as
    --plug-in-param parameter:
    highlight --plug-in plugins/outhtml_lsp_clangd.lua -I keystore.cpp
            --plug-in-param '/home/andre/Projekte/git/highlight/src/:/home/andre/Projekte/git/highlight/src/core/keystore.cpp'
            > ~/Projekte/test_out/lsp.html
]]

Description="Add tooltips based on clangd LSP output (WIP - very slow - Linux only - see contained info)"

Categories = {"language-server-protocol", "html" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if (desc ~= "C and C++") then
      return
  end

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
      return
  end

  tmp_file = "/tmp/lsp_client_"..os.time()

  json = require "json" -- https://github.com/rxi/json.lua
  --inotify = require 'inotify' -- https://github.com/hoelzro/linotify

  function html_escape(s)
    return (string.gsub(s, "[}{\">/<'&]", {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#39;",
        ["/"] = "&#47;"
    }))
  end

  function fibonacci(n)
    local function inner(m)
      if m < 2 then
        return m
      end
      return inner(m-1) + inner(m-2)
    end
    return inner(n)
  end

  function sleep(s)
    local ntime = os.time() + s
    repeat until os.time() > ntime
  end

  function readResponse(fr)

    j = nil
    x = fr:read("*line")
    if string.find(x, 'Content-Length:', 1, true) then
      numBytes = tonumber(x:sub(17))
      fr:read("*line")
      x = fr:read(numBytes)
      j = json.decode(x)
    end
    return j
  end

  function initServer(fw, root_uri)

      init_request = {}
      params = {}
      params.processId = 0
      params.rootUri = root_uri
      params.capabilities = {}

      init_request.jsonrpc = "2.0"
      init_request.id = 1
      init_request.method = "initialize"
      init_request.params = params

      json_s = json.encode(init_request)
      init_cmd = "Content-Length: ".. #json_s.."\n\n"..json_s
      fw:write(init_cmd)
      fw:flush()
      sleep(1)
  end

  function openDocument(fw, input_file)

      fs = io.open(input_file, "r")

      if fs==nil then return false end

      source_text = fs:read("*a")
      fs:close()

      doc_request = {}
      params = {}
      params.textDocument = {}
      params.textDocument.uri = "file://"..input_file
      params.textDocument.languageId = "cpp"
      params.textDocument.version = 1
      params.textDocument.text = source_text

      doc_request.jsonrpc = "2.0"
      doc_request.method = "textDocument/didOpen"
      doc_request.params = params

      json_s = json.encode(doc_request)
      init_cmd = "Content-Length: ".. #json_s.."\n\n"..json_s
      fw:write(init_cmd)
      fw:flush()
      sleep(5) -- TODO maybe wait for textDocument/publishDiagnostics line in stdin
      return true
  end

  function hover(fw, line, col, input_file)

      hover_request = {}
      params = {}
      params.textDocument = {}
      params.textDocument.uri = "file://"..input_file
      params.position = {}
      params.position.line = line
      params.position.character = col

      hover_request.id = 1
      hover_request.jsonrpc = "2.0"
      hover_request.method = "textDocument/hover"
      hover_request.params = params

      json_s = json.encode(hover_request)

      init_cmd = "Content-Length: ".. #json_s.."\n\n"..json_s
      fw:write(init_cmd)
      fw:flush()
      fibonacci(32)
      return true
  end

  function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
  end

  args=string.split(HL_PLUGIN_PARAM, ':')

  if #args~=2 then return end

  clangd_cmd= "clangd >"..tmp_file

  fw = io.popen(clangd_cmd, "w")

  initServer(fw, "file://"..args[1])
  fr = io.open(tmp_file, "r+")
  init_res = readResponse(fr)

  --TODO set in Lua state
  input_source = args[2]

  if init_res.result.serverInfo.name=='clangd' then

      if openDocument(fw, input_source) then
          readResponse(fr)
      end
  end

  function Decorate(token, state, kwclass, lcs, line, col)

    if ( state ~= HL_STANDARD and state ~= HL_KEYWORD) then
      return
    end

    hover(fw, line-1, col+1, input_source)
    hover_res = readResponse(fr)

    if hover_res.result then
        tooltip = html_escape(hover_res.result.contents.value)
        return '<span title="'..tooltip..'">'..token .. '</span>'
    end

  end
end

Plugins={

  { Type="lang", Chunk=syntaxUpdate },

}
