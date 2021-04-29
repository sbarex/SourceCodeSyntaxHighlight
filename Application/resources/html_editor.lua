
Description="Theme tokens highlight"

Categories = {"html"}

function themeUpdate()
    if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
      Injections[#Injections+1]=".hl { transition: box-shadow .2s; }"
      Injections[#Injections+1]=".highlight { box-shadow: 0 0 0 2pt Highlight; }"
    end
end

function syntaxUpdate(desc)
    if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
      return
    end

    HeaderInjection=[=[
<script type="text/javascript">
/* <![CDATA[ */
function highlight(q, state) {
    unhighlight();
    const matches = document.querySelectorAll(q);
    matches.forEach(function(userItem) {
        if (state) {
            userItem.classList.add("highlight");
        } else {
            userItem.classList.remove("highlight");
        }
    });
}
function unhighlight() {
    document.querySelectorAll(".highlight").forEach(function(userItem) {
        userItem.classList.remove("highlight");
    });
}

function handleClick(event) {
    for (let value of event.target.classList.values()) {
        if (value == "hl" || value == "highlight") {
            continue;
        }
        console.log(value);
        window.webkit.messageHandlers.nativeProcess.postMessage({name: "select-theme-token", "token-class": value});
        break;
    }
}

document.addEventListener("DOMContentLoaded", function() {
  console.log("JS ready");
  window.webkit.messageHandlers.nativeProcess.postMessage({name: "domready"});
});
/* ]]> */
</script>
]=]

    FooterInjection=[=[
<script type="text/javascript">
/* <![CDATA[ */
document.querySelectorAll("span.hl").forEach(function(item) { item.addEventListener('click', handleClick); });
/* ]]> */
</script>
]=]

end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate }
}
