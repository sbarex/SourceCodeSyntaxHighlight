#  Quicklook extension for source files

This project is a test to develop a system extension for MacOS 10.15 Catalina for previewing source files.
It's based on the [anthonygelibert/QLColorCode](https://github.com/anthonygelibert/QLColorCode).
Inside it uses [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) to render source code with syntax highlighting.
To install Highlight, download the library manually, or use Homebrew `brew install highlight`.

MacOS 10.15 Catalina has deprecated the qlgenerator APIs. Moreover a .qlgenerator package inside Library/QuickLook now must be notarized to works. 
For this reason I tried to migrate the QLColorCode code using the new quicklook extension system.

This project consists of these components:

- an standalone app that can view source files and provide the interface for the preferences;
- a quicklook system extension to preview source files;
- a XPC service that generate preview of source file and pass formatted data to the app or the quicklook extension.

MacOS 10.15 Catalina require sandboxed extension that prevent the execution of external processes (like shell script). 
To work around this problem, it is possible to use an XPC service that may have different security policies than the application / extension that invokes it. In this case the XPC service is not sandboxed.

To use the extension you must launch the application at least once. If you want you can edit the settings with the gui interface.

![Settings window](settings.png)

It is possible to choose a different theme for OS is in light and dark mode.

The app and quicklook extension can preview files showing the formatted code as html, indise a WKWebView, or as rtf inside a NSTextView.

After the first execution, the quicklook extension will be available among those present in the System preferences/Extensions.

![ System preferences/Extensions](extensions.png)
