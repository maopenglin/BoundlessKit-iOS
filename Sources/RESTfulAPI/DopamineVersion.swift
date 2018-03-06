//
//  DopamineVersion.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation

@objc
internal class DopamineVersion : DopamineDefaultsSingleton {
    
    @objc
    internal static var current: DopamineVersion = { return DopamineDefaults.current.unarchive() ?? DopamineVersion() }()
        {
        didSet {
            DopamineDefaults.current.archive(current)
        }
    }
    
    @objc let versionID: String?
    @objc fileprivate let mappings: [String:Any]
    @objc fileprivate var visualizerMappings: [String:Any]
    
    fileprivate let updateQueue = SingleOperationQueue(delayAfter: 1, dropCollisions: true)
    func update(visualizer mappings: [String: Any]?) {
        updateQueue.addOperation {
            print("Updating visualizer to:\(mappings as AnyObject)")
            if let mappings = mappings {
                self.visualizerMappings = mappings
            } else if self.visualizerMappings.isEmpty {
                return
            } else {
                self.visualizerMappings = [:]
            }
            DopamineVersion.current = self
            DopamineConfiguration.current = {DopamineConfiguration.current}()
            
//            DopeLog.debug("New visualizer mappings:\(self.visualizerMappings as AnyObject)")
        }
    }
    
    init(versionID: String? = nil,
         mappings: [String:Any] = [:],
         visualizerMappings: [String: Any] = [:]) {
        self.versionID = versionID
        self.mappings = mappings
        self.visualizerMappings = visualizerMappings
        super.init()
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        guard let versionID = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.versionID)) as? String?,
            let mappings = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.mappings)) as? [String:Any],
            let visualizerMappings = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.visualizerMappings)) as? [String:Any] else {
                DopeLog.debug("Invalid DopamineVersion saved to user defaults.")
                return nil
        }
//        DopeLog.debug("Found DopamineVersion saved in user defaults.")
        self.init(
            versionID: versionID,
            mappings: mappings,
            visualizerMappings: visualizerMappings
        )
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(DopamineVersion.versionID))
        aCoder.encode(mappings, forKey: #keyPath(DopamineVersion.mappings))
        aCoder.encode(visualizerMappings, forKey: #keyPath(DopamineVersion.visualizerMappings))
//        DopeLog.debug("Saved DopamineVersion to user defaults.")
    }
}

extension DopamineVersion {
    static func convert(from versionDictionary: [String: Any]) -> DopamineVersion? {
        guard let versionID = versionDictionary["versionID"] as? String? else { DopeLog.debug("Bad parameter"); return nil }
        guard let mappings = versionDictionary["mappings"] as? [String:Any] else { DopeLog.debug("Bad parameter"); return nil }
        let visualizerMappings = versionDictionary["visualizerMappings"] as? [String:Any] ?? [:]
        
        return DopamineVersion.init(versionID: versionID, mappings: mappings, visualizerMappings: visualizerMappings)
    }
    
    var actionIDs: [String] {
        return Array(mappings.keys)
    }
    
    var visualizerActionIDs: [String] {
        return Array(mappings.keys) + Array(visualizerMappings.keys) + Array(DopamineSelector.dashboardIntegratingSelectors)
    }
    
    func actionMapping(for actionID: String) -> [String: Any]? {
        return mappings[actionID] as? [String: Any]
    }
    
    func visualizerActionMapping(for actionID: String) -> [String: Any]? {
        return visualizerMappings[actionID] as? [String: Any] ?? mappings[actionID] as? [String: Any]
    }
    
    func reinforcementDecision(for actionID: String) -> String {
        let reinforcementDecision: String
        if CodelessIntegrationController.shared.state == .integrating {
            if let actionMapping = visualizerActionMapping(for: actionID),
                let randomReinforcement = CodelessReinforcement.reinforcementsIDs(in: actionMapping)?.selectRandom() {
                reinforcementDecision = randomReinforcement
            } else {
                reinforcementDecision = Cartridge.defaultReinforcementDecision
            }
        }else {
            reinforcementDecision = SyncCoordinator.retrieve(cartridgeFor: actionID).remove()
        }
        return reinforcementDecision
    }
}
