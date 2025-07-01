Changelog
=======

### 2.1.26 (75)
New Features: 
- Support for Elixir files (`.ex`, `.exs`, `.heex`)
- Support for OpenTimelineIO files (`.otio`) _as JSON_.
- Support for FontTool files (`.ttx`) _as XML_.
- Support for Unity document (`.unity`) _as YAML_
- Support for Visual Studio C# Project (`.csproj`) _as XML_
- Support for Xcode scheme (`.xcscheme`) _as XML_
- Support for Loctable files (`.loctable`) _as plist_.
- Update Highlight to release 4.16. 

Bugfix:
- Python extensions `.pyi` and `.py3` are recognized.
- Fixed compatibility with macOS 10.15 Catalina.

### 2.1.25 (74)
New Features: 
- Support for Jupyter Notebook files (`.ipynb`) _as JSON_.
- Support for MAMEdev layout files (`.lay`) _as XML_.
- Support for NVidia Cuda (`.cu`) files _as C++_.
- Support for `.raml` files _as YAML_.
- Experimental Shortcut Action (require macOS 15.2). 
- Update Highlight to release 4.15.
- Update Lua to release 5.4.7.
- Update Boost to release 1.8.7.

Bugfix:
- Better support for Kotlin files.
- Better light/dark mode recognition.
- Fixed some deprecation warnings during compilation.


### 2.1.24 (73)
Bugfix:
- CLI tool allow to show/hide about footer.
- Fixed saving about flag settings.


### 2.1.23 (72)
New Features: 
- Update Highlight to release 4.12.
- Update Boost to release 1.8.5.
- Update Sparkle to release 2.6.3.
- Support for Nix Expression Language files (`.nix`).
- Advanced settings to show about app info on the footer preview.
- Link to buy me a :coffee: ( :heart: )

Bugfix:
- Fixed support for `public.xsd` UTI.
- Added `.ily` extension for Lilypond files.


### 2.1.22 (71)

New Features: 
- Update Highlight to release 4.11.
- Support for Adobe Flex `.mxml` files _as XML_.
- Extended support for Terraform files to the extension `.tfstate` _as YAML_.

Bugfix:
- Fixed terraform files.
- Fixed missing format descriptions.


### 2.1.21 (70)

New Features: 
- Update Highlight to release 4.10.
- Update Dos2Unix to release 7.5.2.
- Support for Steam app manifest files (`.acf`) _as plain text_.
- Support for Lilypond files (`.ly`).
- Experimental support for Astro files (`.astro`) _as JSX_.

Bugfix:
- Better support for bazel files.
- Fixed `cmake` support.
- Fixed support for `lua` files.
- Fixed support for `md` files.
- Extended support for Terraform files to the extension `.hcl` (_ as YAML_).


### 2.1.20 (69)
New features:
- Update Highlight to release 4.8.
- Update Lua to release 5.4.6.
- Update Boost to release 1.8.3.
- Update Dos2Unix to release 7.5.1.
- Support for `.code-workspace` files _as JSON_.
- Support for bazel (`.bazel`) and smali (`.smali`) files _as plain text_.
- Support for Media Presentation Description (`.mpd`) _as XML_.

Bugfix:
- Fixed unrecognized `.jsm` files.


### 2.1.19 (68)
New features:
- Better support for Stata files (`.do`, `.ado`) _as plain text_.
- Better support for fortran (`.f95`) and LaTex (`.cls`) files.


### 2.1.18 (67)
New features:
- Update Highlight to release 4.5.
- Update Lua to release 5.4.4.
- Added support for Autoit files (`.au3`, `.a3x`).
- Added support for JSON Lines files (`.jsonl`) _as JSON_.
- Added support for Stata files (`.do`, `.ado`) _as plain text_.

Bugfix:
- Fixed unrecognized `.mjs` files.
- Fixed bug for preview files with special characters on the path.


### 2.1.17 (66)
New features:
- Added support for Crystal language (`.cr`)
- Added support for NextFlow language (`.nf`) _as Groovy (Java)_

Bugfix:
- Fixed a bug on standard settings.


### 2.1.16 (65)
New features:
- Update Highlight to release 4.4
- Added support for Perl test scripts (`.t`).
- Added support for Sagemath language (`.sage`) _as Python_
- Added support for SAS language (`.sas`).
- Added support for Solidity language (`.sol`).
- Added support for Terraform files (`.tfvars` and `.tf`) _as YAML_.
- Added support for Web Services Description Language (`.wsdl`) _as XML_.

Bugfix:
- Support for SQL files associated with the UTI `com.sequel-ace.sequel-ace.sql`.
- Fixed bug on syntax_highlight_cli.


### 2.1.15 (64)
New features:
- Added support for JSON with Comments (`.jsonc`).
- Added support for OpenSSH RSA public key (`.pub`) _as plain text_

Bugfix: 
- Fixed bug in assigning special settings for certain UTIs. 


### 2.1.14 (63)
New features:
- Added support for Graphics Language Transmission Format (`.gltf`) as _JSON_.
- Added support for Oracle PL/SQL files as _SQL_.

Bugfix: 
- Fixed rendering of files with special bash characters (like `$`) in the path. 


### 2.1.13 (62)
New features:
- Added support for Dockerfile (`.dockerfile`).

Bugfix: 
- Fixed support for ocaml files.


### 2.1.12 (61)
New features:
- Added support for Node CommonJS module (`.cjs`).
- Added support for some new Typescript extensions (`.mts`, `.cts`) [but `.mts` is handled by the System as a video file].
- Better way to handle some special settings with a YAML file. 

Bugfix: 
- Support for `.toml` files.
- Persistence of VCS colors.
- Plain file pattern match.


### 2.1.11 (60)
New features:
- Highlight updated to 4.2.
- Added support for reStructured Text files (`.rst`).
- Added support for many UTIs defined by MacVim.

Bugfix: 
- Removed the predefined preprocessor for beautify JSON files. 


### 2.1.10 (59)
New features:
- Added support for Ada, BibTex (`.bib`), Document Type Definition (`.dtd`), Dylang.

Bugfix:  
- Better support for files managed by TextMate.


### 2.1.10 (58)
New features:
- Support for Configuration profile files (`.mobileconfig`) as _XML_.

Bugfix:
- Fixed color wheel lag refresh.
- Fixed support for Rust.


### 2.1.9 (57)
New fatures:
- New mime type criteria for the plain files.
- View of the supported formats from the Help menu.

Bugfix:
- Fixed the bug of extra arguments white space.


### 2.1.8 (56)
Bugfix:
- Regression fix for rft background color.


### 2.1.8 (55)
New features:
- Support for Gdscript files (Godot engine) (`.gd`).
- Highlight updated to version 4.2.


### 2.1.7 (54)
New features:
- Better support for xquery files (`.xquery`, `.xu`, `.xq`).
- Better support for assembler files (`.asm`).
 
Bugfix: 
- Better procedure to install the command line tool.
- Fixed custom css style for global settings.
- Fixed the Sparkle integration bug. **If you have installed version 2.1.6 you may need to [re-download the updated app from the web](https://github.com/sbarex/SourceCodeSyntaxHighlight/releases/download/2.1.7/Syntax.Highlight.zip).** 


### 2.1.6 (53)
New features:
- Support for `.readme` files.
- Experimental support for defining the size of the Quick Look window.
- Option for automatic saving of settings changes.
- Sparkle updated to version 2.0.0.


### 2.1.5 (52)
New features:
- Support for Apple shell script `.command` files.


### 2.1.4 (51)
New features:
- On the inquiry windows, double click on a UTI to copy the value on the clipboard.
- Support for additional UTIs associated with the `.opml` format.
- Preliminary support for Planning Domain Description Language `.pddl` format rendered as _`Lisp`_.

### 2.1.3 (50)
New features:
- New app icon.
- Support for `.entitlements` format.
- Support for some UTIs defined by Nova.app.
- Better handling for unsupported plain binary files.
- More log verbosity.

Bugfix: 
- Fixed crash due to pointer deallocation.


### 2.1.2 (49)
Bugfix:
- Fixed dirty status do not set when change a theme property.
- Fixed binary dump word wrap and html entities.
- Better strict detection of plain image files.


### 2.1.1 (48)
New features:
- Application menu item to install/reveal the CLI tool on `/usr/local/bin` folder.

Bugfix:
- Fixed creation of `colorize.log` into the Desktop without debug set.


### 2.1.0 (47)
New features:
- On macOS 12 Monterey adopted the new lightweight API.
- Command line interface for batch conversion.
- Preliminary support for plain files.
- Experimental support for VCS (`git` and `hg`) diff status.
- Support for `.XMP` files rendered as _`XML`_.
- Support for LaTeX `.sty` files.
- Preliminary support  for `.svelte` files rendered as _`HTML`_.
- Add `public.make-source` UTI defined by macOS 12 Monterey.
- Better error messages.

Bugfix:
- Fixed support for some UTIs associated to BBEdit.


### 2.0.12 (46)
New features:
- Support for OPML `.opml` files rendered as _`XML`_.


### 2.0.11 (45)
Bugfix:
- Fixed bugs on the color scheme code.


### 2.0.10 (44)
New features:
- Support for Apple workflow `.wflow` files rendered as _`plist`_.

Bugfix:
- Fixed bugs on the color scheme (import, file name with space, background color).


### 2.0.9
New features:
- Support for Azkaban `.flow` files rendered as _`YAML`_.
- Better support for dynamic UTI.

Bugfix:
- Fixed Kotlin support.
- Fixed generation of settings folder.


### 2.0.8
New features:
- Experimental support for Racket files (`.rkt`) rendered as _`Lisp`_.

Bugfix:
- Error on saving custom theme.
- Typo fix.


### 2.0.7
Bugfix:
- Fixed `.iml` not rendered as `XML`.  


### 2.0.6
New features:
- Added support for `.terminal` files (Apple Teminal Setting file, rendered as `XML`).
- `highlight` updated to the final 4.1 release.


### 2.0.5
New features:
- Added support for `.properties` files (rendered as `INI`).


### 2.0.4
New features:
- Added support for `.xaml` files (rendered as `XML`).

Bugfix:
- Better clojure `.edn` support.


### 2.0.3
Bugfix:
- Better error handler when fetching the settings.


### 2.0.2
Bugfix:
- Word wrap settings not saved.


### 2.0.1
New features:
- Added support for `Clojure` files (`.clj`, `.cljc`, `.cljs`,  `.edn`).


### 2.0.0
New features:
- Completely redesigned interface.    
- `highlight` upgraded to version 4.1 (prerelease), compiled inside the Xcode project, with support for external program parser compatible with the _Language Server Protocol_.
- Option to convert Windows and old Mac Classic line ending to Unix style.
- Color scheme import (from `highlight` `.theme` files) and export (as `.css` or `.theme` file).
- Allow to define a custom CSS style attribute for each color scheme tokens.
- Added support for `.xsd`, `.cmake` and Elixir `.ex`,  `.exs` files.
- Removed support for external `highlight` engine.
- `lua` library upgraded to 5.4.3.
- README reorganized.

Bugfix:
- Fixed Inquiry window disappear after loosing focus.
- Fixed inquiry file detection.
- Padding coherence between HTML and RTF output mode.
- Fixed indexing help files.
- Rationalization of embedded libraries.
- Smaller application size.
- Word wrap optimization.


### 1.0.b31
New features:
- Support for Google `kml` files (rendered as `xml`).
- Support for `toml` language.
- `highlight` updated to version 3.60.

Bugfix:
- Temporary fix to the webkit bug on Big Sur.


### 1.0.b30
New features:
- Auto update with Sparkle framework. Auto updated works only when run the main application and not from the Quick Look extension. You must have launched the application at least twice for the update checks to begin, or you can use the appropriate item in the application menu.
- In the Preferences window, new button to show UTI instead of the extensions.

Bugfix:
- Regression fix about data limit.
- Better layout for the list of the supported languages.


### 1.0.b29
New features:
- toolbar and touchbar for access to the inquiry and themes window.

Bugfix:
- Cosmetic fix for Big Sur.
- The html output mode fail on Big Sur. It would appear that there is a bug preventing the recognition of the extension entitlements which causes webkit to fail to run. The use of the deprecated WebView temporarily bypasses the problem.
- Closing the preferences window with unsaved settings show a confirmation popup.


### 1.0.b28
New features:
- universal binary (but not yet tested on Apple Silicon M1).
- add support for `edu.uo.texshop.tex` UTI used by `.tex` files.
- `highlight` updated to version 3.59 compiled as universal binary with `lua` 5.4.1 statically linked.
- The embedded `lua` library used by the main application is upgraded to version 5.4.1.

Bugfix:
- fixed a bug for the missing preview in html mode on the settings window.
- predefined output mode set to `.rtf` (less expansive that html).


### 1.0.b27
New features:
- main application can only set the preferences and is no longer a viewer.
- support for `.xsd`, `.xquery`, `.xsl`, `.asp` and julia (`.jl`) formats.
- UTI info panel.


### 1.0.b26
New features:
- support for `.vue` files (highlight has a beta support for vue files).


### 1.0.b25
New features:
- support for symfony `.twig` files (interpreted ad html).
- support for `.podspec` files (interpreted as ruby).
- new icon with Big Sur style.


### 1.0.b24
New features:
- support for powershell (`.ps1`, `.psm1`, `.psd1`) files.


### 1.0.b23
New features:
- support for .nim files.


### 1.0.b22
New features:
- support for fortran (`.f`, `.for`, `.f90`) files.


### 1.0.b21
New features:
- support for `.stringsdict`, `.csh`, `.tcsh`, `.ksh` files.


### 1.0.b20
New features:
- new simple UI.
- support for `.strings`, `.ini` and `.cfg` files.
- support for `.xib` and `.storyboard` files as XML.
- preview now can show custom source file.
- better support for standard preprocessor for many file format (if you have previously customized the preprocessor for some formats please check if it require to add the placeholder $targetHL).
- `highlight` updated to 3.57.

Bugfix:
- rust file extension.
- settings migration.


### 1.0.b19
New features:
- `highlight` updated to 3.55.
- enhanced inquiry panel.


### 1.0.b18
New features:
- added support for c++ header files.


### 1.0.b17
New features:
- added an option to limit the amount of data to format.


### 1.0.b16
New features:
- XPC service splitted into two services. One is used by the Quick Look extension with only the code to read the current settings and format the preview. The second one has also the code to change the settings, inquiry the themes and all the requested features for the main application interface. I hope this change makes the Quick Look extension more reactive and consume less resources.
- Rewrite the settings engine.


### 1.0.b15
New features:
- Support for `.h` header files.
- Target to 10.15 (now the standard swift library is not embedded).
- New interactive preview setting to allow the execution of js code inside the Quick Look preview.

Bugfix:
- Removed markdown support in the Quick Look extension.
- Fix little space for theme name on popover theme selector.
- Images of help files have been compressed.
- Added a margin around the preview on the Quick Look window.
- Fast generation of theme icons.


### 1.0.b14
New features:
- Merge pull request https://github.com/sbarex/SourceCodeSyntaxHighlight/pull/18 (support for awk, bash, clojure, diff, haskell, lua, patch, rust, scala, text, zsh)
- Added support for `.r` file format.

Bugfix:
- Correction of many typos.


### 1.0.b13
New features:
- Embedded `highlight` updated to 5.3.4.
- Info panel about `highlight` (from App menu and from a info button on preferences window).
- Menu item inside app menu for open in the Finder the application support folder.
- Redesign of preferences window for the theme selection.
- GUI to view and edit the themes.
- Inside the application support folder are saved the custom css styles and customized themes.

Bugfix:
- Now double click on the Quick Look preview open the file.
- Bugfix on font preferences.
- System for purging and migrating old settings to new system.
