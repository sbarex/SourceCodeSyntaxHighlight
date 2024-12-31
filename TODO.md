#  TODO

- [ ] When compiling `highlight` avoid the creation of the static library `.a` before the CLI otherwise it will be linked in the executable instead of the dynamic one taking up space. 
- [x] Sometime when compiling the app the custom lua plugins are not embedded.
- [ ] Update the application help.
- [ ] Consider whether to incorporate both light and dark styles in the html in order to automatically adapt to the system's style. For RTF [see this link](https://eclecticlight.co/2018/12/10/rendering-rich-text-in-dark-mode/). 
