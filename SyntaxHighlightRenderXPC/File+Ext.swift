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
    fileprivate static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withTime, .withSpaceBetweenDateAndTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withFractionalSeconds]
        f.timeZone = TimeZone.current
        
        return f
    }()
    
    /// Append a string to the data of a file with a new line.
    func appendLine(to url: URL?, timeStamp: Bool = true) throws {
        guard let url = url else {
            return
        }
        try (self + "\n").append(to: url, timeStamp: timeStamp)
    }

    /// Append a string to the data of a file.
    func append(to url: URL?, timeStamp: Bool = true) throws {
        guard let url = url else {
            return
        }
        
        let data: Data
        if timeStamp {
            data = "\(String.dateFormatter.string(from: Date())) \(self)".data(using: String.Encoding.utf8)!
        } else {
            data = self.data(using: String.Encoding.utf8)!
        }
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
