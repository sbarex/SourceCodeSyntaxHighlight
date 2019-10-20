//
//  main.swift
//  XPCService
//
//  Created by sbarex on 15/10/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//

import Foundation

let delegate = XPCServiceDelegate()

let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
