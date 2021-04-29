//
//  NotificationCenter+ext.swift
//  SourceCodeSyntaxHighlight
//
//  Created by Sbarex on 13/03/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let ThemeIsDirty = NSNotification.Name(rawValue: "ThemeDirty")
    static let ThemeNeedRefresh = NSNotification.Name(rawValue: "ThemeRefresh")
    static let CustomThemeAdded = Notification.Name("CustomThemeAdded")
    static let CustomThemeRemoved = Notification.Name("CustomThemeRemoved")
        
    static let SettingsAvailable = NSNotification.Name("Settings.init")
    static let SettingsIsDirty = NSNotification.Name("Settings.dirty")
        
    static let AdvancedSettings = Notification.Name("AdvancedSettings")
    
    public static let SettingsUpdated: NSNotification.Name = NSNotification.Name("org.sbarex.SourceCodeSyntaxHighlight-settings-changed")
}
