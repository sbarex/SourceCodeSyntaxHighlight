//
//  main.swift
//  relaunch
//
//  Created by Sbarex on 12/05/2020.
//  Copyright © 2020 sbarex. All rights reserved.
//

import AppKit

// KVO helper
class Observer: NSObject {

    let _callback: () -> Void

    init(callback: @escaping () -> Void) {
        _callback = callback
    }

    override func observeValue(forKeyPath keyPath: String?,
                      of object: Any?,
                      change: [NSKeyValueChangeKey : Any]?,
                      context: UnsafeMutableRawPointer?) {
        _callback()
    }
}

fileprivate extension String {
    func appendLine(toFileURL fileURL: URL) throws {
        try (self + "\n").append(toFileURL: fileURL)
    }

    func append(toFileURL fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(toFileURL: fileURL)
    }
}

fileprivate extension Data {
    func append(toFileURL fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

// main
autoreleasepool {
    // the application pid
    guard CommandLine.argc > 1, let parentPID = Int32(CommandLine.arguments[1]) else {
        fatalError("Relaunch: parentPID == nil.")
    }

    // get the application instance
    if let app = NSRunningApplication(processIdentifier: parentPID) {
        // application URL
        let bundleURL = app.bundleURL!

        // try? "start listening \(parentPID)\n".write(to: url, atomically: true, encoding: .utf8)
        
        // terminate() and wait terminated.
        let listener = Observer {
            // try? "loop end".appendLine(toFileURL: url)
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
        app.addObserver(listener, forKeyPath: "isTerminated", context: nil)
        
        app.terminate() // FIXME: Don't terminate the app?!?
        // app.forceTerminate()
        CFRunLoopRun() // wait KVO notification
        app.removeObserver(listener, forKeyPath: "isTerminated", context: nil)

        // try? "end listening \(parentPID)".appendLine(toFileURL: url)
        
        // relaunch
        do {
            try NSWorkspace.shared.launchApplication(at: bundleURL, configuration: [:])
        } catch {
            fatalError("Relaunch: NSWorkspace.shared.launchApplication failed.")
        }
    }
}

