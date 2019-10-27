
Description="Add interactive commands."

Categories = {"format", "html", "usability" }

function syntaxUpdate(desc)
  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
    return
  end
  
  -- see themeUpdate below for CSS modifications
  
  function init()
    currentLineNumber=0 -- remember the current line number
  end
    
  init()  
  
  -- move DecorateLineBegin and DecorateLineEnd defined below HERE if anchors 
  -- should be added even if syntax is not foldable
 
  function DecorateLineBegin(lineNumber)
    --TODO we need an initialization hook:
    if lineNumber==1 then
      init()
    end

    -- the line number does not increase for wrapped lines (--wrap, --wrap-simple)
    if (tonumber(currentLineNumber)==lineNumber) then
      return
    end

    currentLineNumber = string.format("%d", lineNumber)
    return '<span id="ln_'..currentLineNumber..'"></span>'
  end
  
  -- function DecorateLineEnd(lineNumber)
  --   if (tonumber(currentLineNumber)==lineNumber) then
  --     return
  --   end
  --   return '</span>'
  -- end

  HeaderInjection=[=[
<div id="gotobar">
    <form onsubmit="return false">
        <button onclick="copyToClipboard()" type="button">copy to clipboard</button>
    </form>
</div>
<div id="gotobar_space"></div>
]=]

  FooterInjection=[=[
<script type="text/javascript">/* <![CDATA[ */
function gotoLineNumber(n) {
    const row = document.getElementById('ln_'+n);
    if (row) {
        const elementRect = row.getBoundingClientRect();
        const absoluteElementTop = elementRect.top + window.pageYOffset;
        const middle = absoluteElementTop - (window.innerHeight / 2);
        window.scrollTo(0, middle);
        
        row.classList.add('highlight');
        window.setTimeout(function() {
            row.classList.remove('highlight');
        }, 1000);
        // row.scrollIntoView();
    }
}

function copyToClipboard() {
    const selection = window.getSelection();
    if (selection.rangeCount === 0 || selection.toString() === "") {
        const range = document.createRange();
        range.selectNodeContents(document.body);
        selection.removeAllRanges();
        selection.addRange(range);
    }
    
    let hidden = [];
    for (let el of document.querySelectorAll('*')) {
        const style = window.getComputedStyle(el);
        if (style['userSelect'] === 'none' || style['webkitUserSelect'] === 'none') {
            hidden.push([el, el.style.display])
            el.style.display = "none";
        }
    }
    
    for (let el of document.querySelectorAll('.hl.lin')) {
        el.style.display = "none";
    }
    
    console.log("copy result", document.execCommand('copy'));
    
    for (let el of document.querySelectorAll('.hl.lin')) {
        el.style.display = "";
    }
    
    for (let el of hidden) {
        el[0].style.display = el[1]
    }
}
/* ]]> */
</script>  
]=]

end

function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]=[[
#gotobar {
    position: fixed;
    width: 100%;
    top: 0;
    left: 0;
    display: table;
    height: 2.5em;
    padding: 0 1em;
    border-bottom: 1px solid ]]..Default.Colour..[[;
    user-select: none;
    -moz-user-select: none;
    -webkit-user-select: none;
}
#gotobar form {
    display: table-cell;
    vertical-align: middle;
    -webkit-backdrop-filter: blur(2px);
    backdrop-filter: blur(5px);
}
#gotobar_space {
    height: 2.5em;
}
.highlight {
    position: relative;
}
.highlight::after {
    content: " ";
    display: block;
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    width: 100%;
    height: 100%;
    background-color: red;
    opacity: .5;
}
]]
  end
end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate }
}
