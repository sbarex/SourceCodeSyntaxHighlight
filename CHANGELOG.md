Changelog
=======

### 2.0.9
New features:
- Support for Azkaban `.flow` files rendered as _`YAML`_.
- Better support for dynamic UTI.
Bugfix:
- Fix Kotlin support.
- Fix generation of settings folder.


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
- Auto update with Sparkle framework. Auto updated works only when run the main application and not from the quicklook extension. You must have launched the application at least twice for the update checks to begin, or you can use the appropriate item in the application menu.
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
- XPC service splitted into two services. One is used by the quicklook extension with only the code to read the current settings and format the preview. The second one has also the code to change the settings, inquiry the themes and all the requested features for the main application interface. I hope this change makes the quicklook extension more reactive and consume less resources.
- Rewrite the settings engine.


### 1.0.b15
New features:
- Support for `.h` header files.
- Target to 10.15 (now the standard swift library is not embedded).
- New interactive preview setting to allow the execution of js code inside the quicklook preview.

Bugfix:
- Removed markdown support in the quicklook extension.
- Fix little space for theme name on popover theme selector.
- Images of help files have been compressed.
- Added a margin around the preview on the quicklook window.
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
- Now double click on the quicklook preview open the file.
- Bugfix on font preferences.
- System for purging and migrating old settings to new system.
