
Description="Adds code folding for C style languages, Pascal, Lua, Ruby and more to HTML output (not compatible with inline CSS or ordered list output)."

Categories = {"format", "html", "usability" }

function syntaxUpdate(desc)

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
    return
  end

  MIN_FOLD_LINE_NUM=1    -- change to control folding of small blocks
  ADD_BLOCK_RESIZE=false -- set to true if pre block should  keep its initial size after folding
  -- see themeUpdate below for CSS modifications

  function init()
    pID=0      -- a sequential counter to generate HTML IDs
    pCount=0   -- parenthesis counter to keep track of opening and closing pairs
    openPID={} -- save opening IDs as they are needed again for the close tag IDs
    currentLineNumber=0 -- remember the current line number
    notEmbedded=false   -- disable plugin for nested code snippets (like JS in HTML)
  end

  init()

  -- move DecorateLineBegin and DecorateLineEnd defined below HERE if anchors
  -- should be added even if syntax is not foldable

  function DecorateLineBegin(lineNumber)

    --TODO we need an initialization hook:
    if lineNumber==1 then
      init()
      notEmbedded=true
    end
    -- the line number does not increase for wrapped lines (--wrap, --wrap-simple)
    if (tonumber(currentLineNumber)==lineNumber) then
      return
    end
    currentLineNumber = string.format("%d", lineNumber)
    return '<span id="x_'..currentLineNumber..'" class="hl fld">'
  end

  function DecorateLineEnd(lineNumber)
    if (tonumber(currentLineNumber)==lineNumber) then
      return
    end
    return '</span>'
  end


  function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
  end

  local foldable = Set { "C and C++", "C#", "Java", "Javascript", "ASCEND",
    "Ceylon", "Crack", "Not eXactly C", "Rust", "TTCN3", "Yang", "(G)AWK", "D",
    "Dart", "Nemerle", "Perl", "PHP", "Microsoft PowerShell", "Pike", "Scala",
    "Swift", "Kotlin", "Pascal", "Ruby", "Lua", "Go", "AutoHotKey", "TypeScript",
    "R", "Bash" }

  if not foldable[desc] then
    return
  end

  --default for curly braces
  blockBegin = Set { "{" }
  blockEnd = Set { "}" }
  blockStates = Set{ HL_OPERATOR }

  -- FIX conditional modifiers: add global desc var
  langDesc = desc

  --delimiters for other languages
  if desc=="Pascal" then
    blockBegin["begin"] = true
    --blockBegin["asm"] = true --issue with embedded syntax
    blockBegin["repeat"] = true
    blockBegin["case"] =  true
    blockBegin["record"] =  true
    blockEnd["end"] = true
    blockEnd["until"] = true
    blockStates[HL_KEYWORD] = true
    blockStates[HL_BLOCK_COMMENT] = true
    blockStates[HL_OPERATOR] = false
  elseif desc=="C#" then
    blockBegin["region"] = true
    blockEnd["endregion"] = true
    blockStates[HL_PREPROC] = true
  elseif desc=="Lua" then
    blockBegin["then"] = true
    blockBegin["do"] = true
    blockBegin["function"] = true
    blockEnd["elseif"] = true
    blockEnd["end"] = true
    blockStates[HL_KEYWORD] = true
  elseif desc=="Bash" then
    blockBegin["then"] = true
    blockBegin["do"] = true
    blockBegin["case"] = true
    blockEnd["fi"] = true
    blockEnd["else"] = true
    blockEnd["done"] = true
    blockEnd["esac"] = true
    blockStates[HL_KEYWORD] = true
  elseif desc=="Ruby" then
    blockBegin["do"] = true
    blockBegin["def"] = true
    blockBegin["class"] = true
    blockBegin["begin"] = true
    blockBegin["case"] = true
    blockBegin["while"] = true
    blockBegin["module"] = true
    blockBegin["if"] = true
    blockBegin["unless"] = true
    blockBegin["until"] = true
    blockBegin["["] = true
    blockEnd["]"] = true
    blockEnd["end"] = true
    blockStates[HL_KEYWORD] = true

    -- fix  self.class == other.class && @ops == other.ops
    Identifiers=[[ [a-zA-Z_\.][\w\-]* ]]
    table.insert( Keywords,
                  { Id=3, List={".class"}
                  } )
  end

    HeaderInjection=[=[
  <script type="text/javascript">
  /* <![CDATA[ */
  var beginOfBlock = [];
  var endOfBlock = {};
  var foldedLines = {};

  function make_handler (elem) {
    return function (event) {
      hlToggleFold(elem)
    };
  }
  function hlAddEOB(openId, eob)  {
    if (eob==beginOfBlock[openId -1] || eob - beginOfBlock[openId -1]< ]=]..MIN_FOLD_LINE_NUM..[=[ ){
      delete beginOfBlock[openId -1];
    } else {
      endOfBlock[beginOfBlock[openId -1] ] = eob;
    }
  }
  function hlAddTitle(line, num, isFolding){
    elem.title="Click to "+(isFolding? "unfold ": "fold ") + num + " line"+(num>1?"s":"");
  }
  function hlAddBtn(openId)  {
    elem = document.getElementById('x_' + openId);
    elem.className = "hl fld hl arrow_unfold";
    elem.addEventListener("click", make_handler(elem));
    hlAddTitle(elem, (endOfBlock[openId]-openId-1), false);
  }
  function hlToggleFold(sender){
    elem =    document.getElementById(sender.id);
    var num = parseInt(sender.id.substr(2));
    var isFolding = elem.className.indexOf ('unfold')>0;
    foldedLines[num] = isFolding ;
    elem.className = "hl fld hl arrow_" + (isFolding ? "fold":"unfold");
    hlAddTitle(elem, (endOfBlock[num]-num-1), isFolding);
    for (var i=num+1; i<=endOfBlock[num]-1; i++){
      if (!foldedLines[i]) foldedLines[i] = 0 ;
      foldedLines[i] = foldedLines[i] + (isFolding ? 1:-1);
      elem = document.getElementById('x_'+i);
      if (     (isFolding || elem.style.display=='block')
            || (!isFolding && foldedLines[i]>=1 && elem.className.indexOf ('_fold') < 0)
            || (!isFolding && foldedLines[i]>=2 && elem.className.indexOf ('_fold') > 0)) {
          elem.style.display = 'none';
      } else {
          elem.style.display = 'block';
      }
      if (elem.nextSibling
        && elem.nextSibling.nodeType==3
        && !elem.nextSibling.data.match(/\S/) ) {
          elem.parentNode.removeChild(elem.nextSibling);
          if (elem.textContent.length==0) elem.textContent = " ";
        }
      }
    }
  /* ]]> */
  </script>
]=]

  ResizeSnippet=''

  if ADD_BLOCK_RESIZE==true then
      ResizeSnippet=[[
  var hlElements=document.getElementsByClassName('hl');
  if (hlElements.length>1){
    var pre = hlElements[1];
    if (pre instanceof HTMLPreElement) {
      pre.style.setProperty('min-height', pre.clientHeight+'px');
    }
  }
  ]]
  end

  -- assign some CSS via JS to keep output sane for browsers with JS disabled
  FooterInjection=[=[

  <script type="text/javascript">
  /* <![CDATA[ */
  beginOfBlock.forEach(function (item) {
    hlAddBtn(item);
  });
  ]=]..ResizeSnippet..[=[
  var hlFoldElements=document.getElementsByClassName('hl fld');
  for (var i=0; i<hlFoldElements.length; i++){
    hlFoldElements[i].style.setProperty('padding-left', '1.5em');
  }
  /* ]]> */
</script>
  ]=]



  function getOpenParen(token)
    pID=pID+1
    pCount=pCount+1
    openPID[pCount] = pID
    return '<script>beginOfBlock.push('..currentLineNumber..');</script>'..token
  end

  function getCloseParen(token)
    oID=openPID[pCount]
    if oID then
      pCount=pCount-1
      return '<script>hlAddEOB('..oID..', '.. currentLineNumber..');</script>'..token
    end
  end

  function string.ends(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
  end

  -- FIX conditional modifiers: add two params
  function Decorate(token, state, kwclass, lineContainedStmt)
    if (not blockStates[state] or notEmbedded==false) then
      return
    end

    -- FIX conditional modifiers: add condition to avoid recognition of delimiters
    --     if the line before is a statement
    if langDesc=="Ruby" and lineContainedStmt == true
        and ( token=="if" or token=="unless" or token=="while" or token=="until" )
      then
        return
    end

    if blockBegin[ string.lower(token) ] then
      return getOpenParen(token)
    end

    if blockEnd[ string.lower(token) ] then
      return getCloseParen(token)
    end

  end

end

function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then

    -- edit to use different folding symbols (i.e. arrows)
    FOLD_OPEN_SYMBOL='+'   -- possible: + > \\27a4 \\27a7 \\21db \\2261
    FOLD_CLOSE_SYMBOL='-'  -- possible: - > \\27a4 \\27a7 \\21db \\2212

    rotation=''
    if (FOLD_OPEN_SYMBOL==FOLD_CLOSE_SYMBOL) then rotation='transform:rotate(90deg);' end

    Injections[#Injections+1]=[[
.hl.arrow_fold:before {
  content: ']]..FOLD_OPEN_SYMBOL..[[';
  color: ]]..Default.Colour..[[;
  position: absolute;
  left: 1em;
  ]]..rotation..[[
}
.hl.arrow_fold:after {
  content: '\2026';
  color: ]]..Default.Colour..[[;
  border-width:1px;border-style:dotted;border-color:]]..Default.Colour..[[;
  margin-left: 1em;
  padding:0px 2px 0px;
}
.hl.arrow_unfold:before {
  content: ']]..FOLD_CLOSE_SYMBOL..[[';
  color: ]]..Default.Colour..[[;
  position: absolute;
  left: 1em;
}
.hl.arrow_fold, .hl.arrow_unfold  {
  cursor: pointer;
  /*background-color: #eee;*/
  width: 100%;
  display: inline-block;
}
.hl.arrow_fold {
  border-width: 1px;
  border-bottom-style: groove;
  border-color: ]]..Default.Colour..[[;
} ]]
  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },
}
