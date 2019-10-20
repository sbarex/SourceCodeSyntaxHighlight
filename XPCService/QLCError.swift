//
//  QLColorError.swift
//  XPCService
//
//  Created by sbarex on 16/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//

import Foundation

enum QLCError: Error {
    case xpcGenericError(error: Error?)
    case missingHighlight
    
    case shellError(cmd: String, exitCode: Int, stdOut: String, stdErr: String, message: String?)
    
    var localizedDescription: String {
        switch self {
        case .xpcGenericError(let error):
            var s = "Error communicating with XPC service!"
            if let e = error {
                s += "\n\(e.localizedDescription)"
            }
            return s
        case .shellError(let cmd, let exitCode, let stdOut, let stdErr, let message):
            var s = ""
            if let m = message, m.count > 0 {
                s += "\(m)\n"
            } else {
                s += "Shell error!\n"
            }
            s += "command: \(cmd)\nexitCode: \(exitCode)"
            if stdOut.count > 0 {
                s += "\n\(stdOut)"
            }
            if stdErr.count > 0 {
                s += "\n\(stdErr)"
            }
            return s
        case .missingHighlight:
            return "highlight not available!"
        }
    }
}
