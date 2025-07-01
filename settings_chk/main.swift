//
//  main.swift
//  settings_chk
//
//  Created by Sbarex on 20/06/25.
//  Copyright © 2025 sbarex. All rights reserved.
//

import Foundation
import Yams

func usage() {
    let executablePath = CommandLine.arguments[0]
    let executableName = URL(fileURLWithPath: executablePath).lastPathComponent
    print("Usage: \(executableName) settings.yaml")
    print("Check the validity of the settings.yaml file (must be a valid yaml, decodable as [String: [String: [String: String]]], with the UTIs and extesions root keys.")
    print("")
}

guard CommandLine.arguments.count == 2, !CommandLine.arguments[1].isEmpty else {
    print(CommandLine.arguments.count)
    usage()
    exit(1)
}

let filename = CommandLine.arguments[1]

guard FileManager.default.fileExists(atPath: filename) else {
    print("Error: \(filename) not found!")
    exit(2)
}

let data: String
if #available(macOS 13.0, *) {
    var enc: String.Encoding = .utf8
    guard let _data = try? String(contentsOf: URL(filePath: filename), usedEncoding: &enc) else {
        print("Error: unable to read \(filename)!")
        exit(3)
    }
    data = _data
} else {
    guard let _data = try? String(contentsOf: URL(fileURLWithPath: filename)) else {
        print("Error: unable to read \(filename)!")
        exit(3)
    }
    data = _data
}
let raw_d: Any
do {
    guard let d = try Yams.load(yaml: data) else {
        print("Error: \(filename) is not a valid yaml file!")
        exit(4)
    }
    raw_d = d
} catch {
    print("Error: \(filename) is not a valid yaml file: \(error)!")
    exit(4)
}

let global_nodes = ["UTIs", "extensions"]

if let a = raw_d as? [String: [String: [String: String]]] {
    for node in global_nodes {
        guard let _ = a[node] else {
            print("Error: missing \(node) root key on \(filename)!")
            exit(5)
        }
    }
    
    print("\(filename) is valid.")
    exit(0)
}

print("Error: \(filename) is not a valid settings file!")

if let a = raw_d as? [String: Any] {
    for node_name in global_nodes {
        guard let node = a[node_name] else {
            print("Missing \(node_name) root key on \(filename)!")
            exit(5)
        }
        if let node = node as? [String: Any] {
            for d in node {
                guard let _ = d.value as? [String: String] else {
                    print("\(node_name)/\(d.key): is not a [String: String]!")
                    exit(6)
                }
            }
        } else {
            print("\(node) is not a [String: String]!")
            exit(6)
        }
    }
}
    
print(raw_d)
exit(6)

