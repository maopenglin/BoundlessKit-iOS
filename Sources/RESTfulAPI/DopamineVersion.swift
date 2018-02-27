//
//  DopamineVersion.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation

@objc
public class DopamineVersion : UserDefaultsSingleton {
    
    @objc
    public static var current: DopamineVersion = {
        return UserDefaults.dopamine.unarchive() ?? DopamineVersion.standard
        }()
        {
        didSet {
            UserDefaults.dopamine.archive(current)
        }
    }
    
    @objc public var versionID: String?
    @objc fileprivate var mappings: [String:Any]
    @objc internal fileprivate (set) var visualizerMappings: [String:Any]
    internal var isIntegrating = false {
        didSet {
            if !isIntegrating {
                DopamineChanges.shared.integrationModeMethods(false)
                update(visualizer: nil)
            } else {
                DopamineChanges.shared.integrationModeMethods(true)
                DopamineChanges.shared.registerVisualizerMethods()
            }
        }
    }
    
    fileprivate let updateQueue = SingleOperationQueue(delayAfter: 1, dropCollisions: true)
    public func update(visualizer mappings: [String: Any]?) {
        updateQueue.addOperation {
            print("Updating visualizer to:\(mappings as AnyObject)")
            if let mappings = mappings {
                self.visualizerMappings = mappings
                DopamineChanges.shared.registerVisualizerMethods()
            } else if self.visualizerMappings.isEmpty {
                return
            } else {
                self.visualizerMappings = [:]
            }
            UserDefaults.dopamine.archive(self)
//            DopeLog.debug("New visualizer mappings:\(self.visualizerMappings as AnyObject)")
        }
    }
    
    init(versionID: String?,
         mappings: [String:Any] = [:],
         visualizerMappings: [String: Any] = [:]) {
        self.versionID = versionID
        self.mappings = mappings
        self.visualizerMappings = visualizerMappings
        super.init()
    }
    
    static func initStandard(with versionID: String?) -> DopamineVersion {
        let standard = DopamineVersion.standard
        standard.versionID = versionID
        return standard
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let versionID = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.versionID)) as? String?,
            let mappings = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.mappings)) as? [String:Any],
            let visualizerMappings = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.visualizerMappings)) as? [String:Any] {
//            DopeLog.debug("Found DopamineVersion saved in user defaults.")
            self.init(
                versionID: versionID,
                mappings: mappings,
                visualizerMappings: visualizerMappings
            )
        } else {
//            DopeLog.debug("Invalid DopamineVersion saved to user defaults.")
            return nil
        }
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(DopamineVersion.versionID))
        aCoder.encode(mappings, forKey: #keyPath(DopamineVersion.mappings))
        aCoder.encode(visualizerMappings, forKey: #keyPath(DopamineVersion.visualizerMappings))
//        DopeLog.debug("Saved DopamineVersion to user defaults.")
    }
    
    static var standard: DopamineVersion {
        return DopamineVersion(versionID: nil)
    }
    
    internal func reinforcementDecision(for actionID: String) -> String {
        let reinforcementDecision: String
        if isIntegrating,
            let actionMapping = actionMapping(for: actionID),
            let randomReinforcement = CodelessReinforcement.reinforcementsIDs(in: actionMapping)?.selectRandom()
        {
            reinforcementDecision = randomReinforcement
        } else {
            reinforcementDecision = SyncCoordinator.retrieve(cartridgeFor: actionID).remove()
        }
        return reinforcementDecision
    }
}

public extension DopamineVersion {
    public static func convert(from versionDictionary: [String: Any]) -> DopamineVersion? {
        guard let versionID = versionDictionary["versionID"] as? String? else { DopeLog.debug("Bad parameter"); return nil }
        guard let mappings = versionDictionary["mappings"] as? [String:Any] else { DopeLog.debug("Bad parameter"); return nil }
        let visualizerMappings = versionDictionary["visualizerMappings"] as? [String:Any] ?? [:]
        
        return DopamineVersion.init(versionID: versionID, mappings: mappings, visualizerMappings: visualizerMappings)
    }
    
    public var actionIDs: [String] { get {
        return Array(mappings.keys)
        } }
    
    public var visualizerActionIDs: [String] { get {
        return Array(visualizerMappings.keys)
        } }
    
    public func actionMapping(for actionID: String) -> [String: Any]? {
        if isIntegrating {
            return visualizerMappings[actionID] as? [String: Any] ?? mappings[actionID] as? [String: Any]
        } else {
            return mappings[actionID] as? [String: Any]
        }
    }
    
}
