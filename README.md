#  Quicklook extension for source files

This project is a test to develop a system extension for MacOS 10.15 Catalina for previewing source files.

It's based on the [anthonygelibert/QLColorCode](https://github.com/anthonygelibert/QLColorCode) qlgenerator which uses deprecated APIs in MacOS 10.15. It's use [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) to format source files.

This project consists of these components:

- an standalone app that can view source files and provide the interface for the preferences
- a quicklook system extension to preview source files.
- a XPC service that generate preview of source file and pass formatted data to the app or the quicklook extension.

MacOS 10.15 Catalina require sandboxed extension that prevent the execution of external processes (like shell script). 
To work around this problem, it is possible to use an XPC service that may have different security policies than the application / extension that invokes it. In this case the XPC service is not sandboxed.

The application has the gui for setting the preferences.

![Settings window](settings.png)

It is possible to choose a different theme for OS is in light and dark mode.

The app and quicklook extension can preview files showing the formatted code as html, indise a WKWebView, or as rtf inside a NSTextView.

