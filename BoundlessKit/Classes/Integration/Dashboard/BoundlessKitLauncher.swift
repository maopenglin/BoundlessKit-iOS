//
//  BoundlessKitLauncher.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

public class BoundlessKitApplicationLauncherBridge : NSObject {
    
    @objc public static let standard = BoundlessKitApplicationLauncherBridge()
    
    @objc public func appDidLaunch(_ notification: Notification) {
        // Set up boundlessKit if BoundlessProperties.plist found
        if let credentials = BoundlessCredentials.fromFile {
            let codelessAPIClient = CodelessAPIClient(credentials: credentials, database: BKUserDefaults.standard)
            BoundlessKit._standard = BoundlessKit(apiClient: codelessAPIClient)
            codelessAPIClient.boot {
                codelessAPIClient.promptPairing()
            }
        }
    }
    
}
