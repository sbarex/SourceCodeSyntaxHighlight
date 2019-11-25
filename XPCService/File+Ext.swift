//
//  File+Ext.swift
//  Syntax Highlight XPC Service
//
//  Created by Sbarex on 21/11/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
// https://stackoverflow.com/a/40687742/1409904

import Foundation

extension String {
    /// Append a string to the data of a file with a new line.
    func appendLine(to url: URL) throws {
        try (self + "\n").append(to: url)
    }

    /// Append a string to the data of a file.
    func append(to url: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(to: url)
    }
}

extension Data {
    /// Append the data to a url.
    func append(to url: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: url.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: url, options: .atomic)
        }
    }
}
