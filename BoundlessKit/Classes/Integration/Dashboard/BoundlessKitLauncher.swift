//
//  BoundlessKitLauncher.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

open class BoundlessKitApplicationLauncherBridge : NSObject {
    
    @objc public static let standard = BoundlessKitApplicationLauncherBridge()
    
    @objc public func appDidLaunch(_ notification: Notification) {
        // Set up boundlessKit if BoundlessProperties.plist found
        if let properties = BoundlessProperties.fromFile(using: BKUserDefaults.standard) {
            let codelessAPIClient = CodelessAPIClient(credentials: properties.credentials, version: properties.version)
            BoundlessKit._standard = BoundlessKit(apiClient: codelessAPIClient)
            codelessAPIClient.boot()
        }
    }
    
}
