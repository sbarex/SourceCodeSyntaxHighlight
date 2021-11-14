//
//  TaskResult.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 28/11/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SyntaxHighlight.
//  SyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

import Foundation

class ShellTask {
    struct TaskResult {
        /// stdout data.
        let data: Data
        /// stderr data.
        let dataErr: Data
        /// Program exit code.
        let exitCode: Int
        
        init(output data: Data, error: Data, exitCode: Int) {
            self.data = data
            self.dataErr = error
            self.exitCode = exitCode
        }
        
        var isSuccess: Bool {
            return self.exitCode == 0
        }
        
        /// Convert stdout data to a string.
        func output(encoding: String.Encoding = String.Encoding.utf8) -> String? {
            return (String(data: data, encoding: String.Encoding.utf8) ?? "").trimmingCharacters(in: CharacterSet.newlines)
        }
        
        /// Convert stderr data to a string.
        func errorOutput(encoding: String.Encoding = String.Encoding.utf8) -> String? {
            return (String(data: dataErr, encoding: String.Encoding.utf8) ?? "").trimmingCharacters(in: CharacterSet.newlines)
        }
    }
    
    /// Execute a shell task
    /// - parameters:
    ///   - command: Program to execute.
    ///   - arguments: Arguments to pass to the executable.
    ///   - env: Environment variables.
    ///   - cwd: Current working directory.
    static func runTask(command: String, arguments: [String], env: [String: String] = [:], cwd: String? = nil) throws -> TaskResult {
        let task = Process()
        
        task.currentDirectoryPath = cwd ?? NSTemporaryDirectory()
        task.environment = env
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // Let stderr go to the usual place
        let pipeErr = Pipe()
        task.standardError = pipeErr
        
        do {
            try task.run()
        } catch {
            throw SCSHError.shellError(cmd: command+" "+arguments.joined(separator: " "), exitCode: -1, stdOut: "", stdErr: "", message: error.localizedDescription)
        }
        
        let file = pipe.fileHandleForReading
        let fileErr = pipeErr.fileHandleForReading
        
        defer {
            if #available(macOS 10.15, *) {
                /* The docs claim this isn't needed, but we leak descriptors otherwise */
                try? file.close()
                try? fileErr.close()
            }
        }
        
        let data = file.readDataToEndOfFile()
        let dataErr = file.readDataToEndOfFile()
        
        task.waitUntilExit()
        
        let r = TaskResult(output: data, error: dataErr, exitCode: Int(task.terminationStatus))
        
        return r
    }
        
    /// Execute a shell task
    /// - parameters:
    ///   - script: Script to execute.
    ///   - env: Environment variables.
    static func runTask(script: String, env: [String: String] = [:]) throws -> TaskResult {
        return try runTask(command: "/bin/sh", arguments: ["-c", script], env: env)
    }
}
