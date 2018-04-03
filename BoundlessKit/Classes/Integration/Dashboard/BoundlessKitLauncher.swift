//
//  BoundlessKitLauncher.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

public class BoundlessKitLauncherObjc : NSObject {
    @objc
    public static var launch: Bool = {
        let launcher = BoundlessKitLauncher()
        BoundlessKit.standard.launcher = launcher
        return true
    }()
}

class BoundlessKitLauncher : NSObject {
    
    var codelessAPIClient: CodelessAPIClient
    let database = BKUserDefaults.standard
    
    var codelessReinforcers = [String: CodelessReinforcer]()
    
    override init() {
        self.codelessAPIClient = CodelessAPIClient()
        super.init()
        
        codelessAPIClient.delegate = self
        // set session again to run `didSet` routine
        let session = codelessAPIClient.visualizerSession
        codelessAPIClient.visualizerSession = nil
        codelessAPIClient.visualizerSession = session
        
        
        codelessAPIClient.boot {
            BoundlessKit.standard.apiClient.properties = self.codelessAPIClient.properties
            self.refreshKit()
            self.codelessAPIClient.promptPairing()
        }
        
        refreshKit()
    }
    
    func refreshKit() {
        for (actionID, value) in codelessAPIClient.properties.version.mappings {
            BoundlessKit.standard.refreshContainer.commit(actionID: actionID, with: BoundlessKit.standard.apiClient)
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
    }
}

extension BoundlessKitLauncher : CodelessApiClientDelegate {
    func didUpdate(session: CodelessVisualizerSession?) {
        var mappings = codelessAPIClient.properties.version.mappings
        if let session = session {
            for (key, value) in session.mappings {
                mappings[key] = value
            }
            CodelessReinforcer.showOption = .random
        } else {
            CodelessReinforcer.showOption = .reinforcement
        }
        
        for (actionID, value) in codelessReinforcers.filter({mappings[$0.key] == nil}) {
            InstanceSelectorNotificationCenter.default.removeObserver(value, name: Notification.Name(actionID), object: nil)
            codelessReinforcers.removeValue(forKey: actionID)
            BKLog.debug("Removed reinforcer and notification for <\(actionID)>")
        }
        for (actionID, value) in mappings {
            if let codeless = value["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String: Any]] {
                let reinforcer: CodelessReinforcer
                if let r = codelessReinforcers[actionID] {
                    reinforcer = r
                    reinforcer.reinforcements.removeAll()
                    BKLog.debug("Updating reinforcer for <\(actionID)> notification")
                } else {
                    reinforcer = CodelessReinforcer(forActionID: actionID)
                    InstanceSelectorNotificationCenter.default.addObserver(reinforcer, selector: #selector(reinforcer.receive(notification:)), name: NSNotification.Name(actionID), object: nil)
                    codelessReinforcers[actionID] = reinforcer
                    BKLog.debug("Created reinforcer for <\(actionID)> notification")
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

