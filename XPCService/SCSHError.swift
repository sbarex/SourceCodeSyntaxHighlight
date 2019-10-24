//
//  SCSHError.swift
//  SCSHXPCService
//
//  Created by sbarex on 16/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SourceCodeSyntaxHighlight.
//  SourceCodeSyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SourceCodeSyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SourceCodeSyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.

import Foundation

enum SCSHError: Error {
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
