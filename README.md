#  Quicklook extension for source files

This project is a test to develop a system extension for MacOS 10.15 Catalina for previewing source files.
It's based on the [anthonygelibert/QLColorCode](https://github.com/anthonygelibert/QLColorCode).
Inside it uses [Highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) to render source code with syntax highlighting.
The application is distributed with a version of the `highlight`. If you want you can use a different version customizing the preferences.

MacOS 10.15 Catalina has deprecated the qlgenerator APIs. Moreover a .qlgenerator package inside Library/QuickLook must be notarized on 10.15.0 to works. In version 10.15.1 it seems that notarization is no longer required.  

This project consists of these components:

- an standalone app that can view source files and provide the interface for the preferences;
- a quicklook system extension to preview source files;
- a XPC service that generate preview of source file and pass formatted data to the app or the quicklook extension.

MacOS 10.15 Catalina require sandboxed extension that prevent the execution of external processes (like shell script). 
To work around this problem, it is possible to use an XPC service that may have different security policies than the application / extension that invokes it. In this case the XPC service is not sandboxed.

The XPC service is executed automatically when requested by the application or the quicklook extension. After closing the quicklook preview the process is automatically closed after some seconds relasing the resources.

To use the extension you must launch the application at least once. In this way the quicklook extension will be discovered by the system. In the standalone app, with the preferences window, you can also customize the preview settings used by plugin extension.

![Settings window](settings.png)

In the settings it is possible to choose a different theme to use when OS is in light and dark mode.

The app and quicklook extension can preview files showing the formatted code as html, inside a WKWebView, or as rtf inside a NSTextView.

After the first execution, the quicklook extension will be available among those present in the System preferences/Extensions.

![System preferences/Extensions](extensions.png)

This extension don't provide a thumbnail service for the Finder icon. 
