#  Quicklook extension for source files

This application offers a quicklook extension for MacOS 10.15 Catalina for previewing source files.
Inside it uses [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) to render source code with syntax highlighting.
The application is distributed with a version of the `highlight`. If you want you can use a different version customizing the preferences.

MacOS 10.15 Catalina has deprecated the qlgenerator APIs. Moreover a .qlgenerator package inside Library/QuickLook must be notarized on 10.15.0 to works. In version 10.15.1 it seems that notarization is no longer required.  

This project consists of these components:

- a standalone app that can view source files and provide the interface for the preferences;
- a quicklook system extension to preview the source files;
- an XPC service that generate the preview of source file and pass the formatted data to the app or the quicklook extension.

MacOS 10.15 Catalina require sandboxed extension that prevent the execution of external processes (like shell script). 
To work around this problem, it is possible to use an XPC service that may have different security policies than the application / extension that invokes it. In this case the XPC service is not sandboxed.

The XPC service is executed automatically when requested by the application or the quicklook extension. After closing the quicklook preview the process is automatically closed after some seconds releasing the resources.

The app and quicklook extension can preview files showing the formatted code as html, inside a WKWebView, or as rtf inside a NSTextView.

To use the quicklook preview you must launch the application at least once. In this way the quicklook extension will be discovered by the system. 
After the first execution, the quicklook extension will be available among those present in the System preferences/Extensions.

![System preferences/Extensions](extensions.png)

This extension don't provide a thumbnail service for the Finder icon. 

SyntaxHighlight is distributed in the hope that it will be useful but WITHOUT ANY WARRANTY.


## File format management

The quicklook extension uses the [Uniform Type Identifier (UTI)](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/understanding_utis/understand_utis_intro/understand_utis_intro.html) to handle the supported formats (and not simply the file name extension). 
Inside the definition on an UTI there are the list of extensions and mime type associated with it.

Some file types are directly associated to an UTI by the system. Other formats are registered by the owner application. In this way some extensions can be associated to multiple UTIs based on the applications currently installed. 

For this reason, this application supports many UTIs even if they are apparently redundant. 

Apparently the operating system does not allow to manage some file formats including (but not limited to) .xml, .plist, .html, .ts, .dart.

It's likely that I didn't associate all the possible extensions managed by `highlight`.

With the inquiry window you can see if a specific file type is handled by the quicklook extension and also if it is recognized by `highlight`.

![Inquiry window](inquiry.png)

On Terminal you can see the UTI of a file with this command: 

```
$ mdls -name kMDItemContentType -name kMDItemContentTypeTree filename.ext
```
If you found an unhandled format please send me the output of above command.
**Only the formats supported by `highlight` can be managed by this application.**

To view the info about `highlight` with the supported file formats and extensions go to the menu `Syntax Highlight/About highlight…`, or in the Preferences window click the *i* info button near the highlight popup button.

![IAbout highlight info panel.](about_highlight.png)


## Application preferences

In the standalone app, with the preferences window you can customize the preview settings used by the plugin extension.

![Global settings window](settings.png)

Some `highlight` features, such as theme, words wrap, line numbers and tabs, are managed through the preferences gui. It is also possible to choose a different theme when OS use light or dark style.

In addition to the global settings for all supported file formats, you can set specific settings for individual file formats.

![File type settings window](settings_specific.png)

In the file type Specific settings, there is a list of all file types supported by the quicklook extension.
In this list the grayout items are those currently managed by others UTI. Clicking on the exclamation mark icon you will show which UTI is used for a given file extension.

![File type settings window](settings_specific_warn.png)

The debug option on settings panel enable the creation of two files on your Desktop:
- colorize.log: log of the colorize operations
- colorize.[html|rtf] output of the syntax highlight

The settings are stored in `~/Library/Preferences/org.sbarex.SourceCodeSyntaxHighlight.plist`.
Custom themes and styles are saved in `~/Library/Application Support/Syntax Highlight`.


## Theme editor
The application has a gui theme editor accessible form menu `View/Themes editor`. 
With this interface you can create a custom theme to use with highlight.

![Theme editor](theme_editor.png)

Standard themes provided by `highlight` cannot be edited but can be duplicated and then customized.

Clicking on an element of the preview blinks the corresponding item in the editor and vice versa.

Customized themes are saved in `~/Library/Application Support/Syntax Highlight/Themes`.


## Note for download precompiled release
The precompiled app is not notarized or signed.
When you download the precompiled app you must strip quarantine flag before execute:

```
$ xattr -r -d com.apple.quarantine "Syntax Highlight.app" 
```

This must resolve the error of damage application when launch the app.

## Note for developers
After cloning remember to fetch submodules:

```
$ git submodule init 
$ git submodule update
```


## Credits

This application has originated from the [anthonygelibert/QLColorCode](https://github.com/anthonygelibert/QLColorCode).
