
Description="Adds copy to clipboard button to HTML output (beta)."

Categories = {"format", "html", "usability" }

function syntaxUpdate(desc)

  if (HL_OUTPUT ~= HL_FORMAT_HTML and HL_OUTPUT ~= HL_FORMAT_XHTML) then
    return
  end

  function DecorateLineBegin(lineNumber)

    if lineNumber==1 then
      return '<input type="button" value="&#128203;" class="hl_copy" style="position: absolute;right: 1em;">'
    end
  end

    FooterInjection=[=[
  <script type="text/javascript">
  /* <![CDATA[ */
  const hlButtons = document.querySelectorAll('input.hl_copy');

  hlButtons.forEach(cpButton => {
    cpButton.addEventListener('click', () => {
      const selection = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(cpButton.parentNode);
      selection.removeAllRanges();
      selection.addRange(range);

      try {
        document.execCommand('copy');
        selection.removeAllRanges();
        cpButton.value = "Copied.";
      } catch(e) {
      }
    });
  });
  /* ]]> */
  </script>
]=]

end

Plugins={
  { Type="lang", Chunk=syntaxUpdate },
}
