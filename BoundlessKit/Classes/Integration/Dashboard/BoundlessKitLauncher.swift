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
    var codelessReinforcers = [String: CodelessReinforcer]()
    
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
        
        codelessAPIClient.delegate = self
        
        // set session again to run `didSet` routine
        let session = codelessAPIClient.visualizerSession
        codelessAPIClient.visualizerSession = nil
        codelessAPIClient.visualizerSession = session
        
        refreshKit()
        codelessAPIClient.boot {
            self.refreshKit()
            self.codelessAPIClient.promptPairing()
        }
    }
    
    func refreshKit() {
        for (actionID, value) in codelessAPIClient.properties.version.mappings {
            codelessAPIClient.refreshContainer.commit(actionID: actionID, with: codelessAPIClient)
            if let codeless = value["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                let reinforcer: CodelessReinforcer
                if let r = codelessReinforcers[actionID] {
                    reinforcer = r
                } else {
                    reinforcer = CodelessReinforcer(forActionID: actionID)
                    InstanceSelectorNotificationCenter.default.addObserver(reinforcer, selector: #selector(reinforcer.receive(notification:)), name: NSNotification.Name.init(actionID), object: nil)
                    codelessReinforcers[actionID] = reinforcer
                }
                for reinforcementDict in reinforcements {
                    if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                        reinforcer.reinforcements[codelessReinforcement.primitive] = codelessReinforcement
                    }
                }
            }
        }
        self.codelessAPIClient.syncIfNeeded()
    }
    
}

extension BoundlessKitLauncher : CodelessApiClientDelegate {
    // set and remove notifications for CodelessReinforcers from Session+CodelessReinforcers
    func didUpdate(session: CodelessVisualizerSession?) {
        var mappings = codelessAPIClient.properties.version.mappings
        if let session = session {
            for (key, value) in session.mappings {
                mappings[key] = value
            }
            CodelessReinforcer.scheduleSetting = .random
        } else {
            CodelessReinforcer.scheduleSetting = .reinforcement
        }
        
        for (actionID, value) in codelessReinforcers.filter({mappings[$0.key] == nil}) {
            InstanceSelectorNotificationCenter.default.removeObserver(value, name: Notification.Name(actionID), object: nil)
            codelessReinforcers.removeValue(forKey: actionID)
            BKLog.debug("Removed codeless reinforcer for actionID <\(actionID)>")
        }
        
        for (actionID, value) in mappings {
            if let codeless = value["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                let reinforcer: CodelessReinforcer
                if let r = codelessReinforcers[actionID] {
                    reinforcer = r
                    reinforcer.reinforcements.removeAll()
                } else {
                    reinforcer = CodelessReinforcer(forActionID: actionID)
                    InstanceSelectorNotificationCenter.default.addObserver(reinforcer, selector: #selector(reinforcer.receive(notification:)), name: NSNotification.Name(actionID), object: nil)
                    codelessReinforcers[actionID] = reinforcer
                    BKLog.print("Created codeless reinforcer for actionID <\(actionID)>")
                }
                for reinforcementDict in reinforcements {
                    if let codelessReinforcement = CodelessReinforcement(from: reinforcementDict) {
                        reinforcer.reinforcements[codelessReinforcement.primitive] = codelessReinforcement
                    }
                }
            }
        }
    }
}

