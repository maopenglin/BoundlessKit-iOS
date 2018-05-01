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
        if BoundlessProperties.fromFile != nil {
            _ = BoundlessKitLauncher.standard
        }
    }
    
}

internal class BoundlessKitLauncher : NSObject {
    
    static let standard = BoundlessKitLauncher()
    
    let kit: BoundlessKit
    let codelessAPIClient: CodelessAPIClient
    
    private override init() {
        if let kit = BoundlessKit._standard {
            self.codelessAPIClient = CodelessAPIClient(boundlessClient: kit.apiClient)
        } else if let properties = BoundlessProperties.fromFile {
            self.codelessAPIClient = CodelessAPIClient(properties: properties, database: BKUserDefaults.standard)
        } else {
            fatalError("Missing <BoundlessProperties.plist> file")
        }
        self.kit = BoundlessKit(apiClient: codelessAPIClient)
        super.init()
        BoundlessKit._standard = kit
        
        // set session again to run `didSet` routine
        let session = codelessAPIClient.visualizerSession
        codelessAPIClient.visualizerSession = nil
        codelessAPIClient.visualizerSession = session
        
        codelessAPIClient.boot {
            self.codelessAPIClient.promptPairing()
        }
    }
}

