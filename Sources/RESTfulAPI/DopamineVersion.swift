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
    @objc internal fileprivate(set) var visualizerMappings: [String:Any]
    
    fileprivate let updateQueue = SingleOperationQueue(delay: 1)
    public func update(visualizer mappings: [String: Any]?) {
        updateQueue.addOperation {
            if let mappings = mappings {
                self.visualizerMappings = mappings
            } else if self.visualizerMappings.count == 0 {
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
    
    public func codelessReinforcementFor(sender: String, target: String, selector: String, completion: @escaping ([String:Any]) -> ()) {
        codelessReinforcementFor(actionID: [sender, target, selector].joined(separator: "-"), completion: completion)
    }
    
    public func codelessReinforcementFor(actionID: String, completion: @escaping([String:Any]) -> Void) {
        if let reinforcementParameters = visualizerMappings[actionID] as? [String: Any] {
            DopeLog.debug("Found visualizer reinforcement for <\(actionID)>")
            if let codeless = reinforcementParameters["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String:Any]],
                let randomReinforcement = reinforcements.selectRandom() {
                completion(randomReinforcement)
            } else {
                DopeLog.debug("Bad visualizer parameters")
            }
        } else if let reinforcementParameters = mappings[actionID] as? [String:Any] {
            DopeLog.debug("Found reinforcement for <\(actionID)>")
            if let codeless = reinforcementParameters["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String:Any]] {
                DopamineKit.reinforce(actionID) { reinforcementType in
                    if reinforcementType == Cartridge.defaultReinforcementDecision {
                        return
                    }
                    for reinforcement in reinforcements {
                        if reinforcement["primitive"] as? String == reinforcementType {
                            completion(reinforcement)
                            return
                        }
                    }
                    DopeLog.error("Could not find reinforcementType:\(reinforcementType)")
                }
            } else {
                DopeLog.error("Bad reinforcement parameters")
            }
        } else {
//            DopeLog.debug("No reinforcement mapping found for <\(actionID)>")
//            DopeLog.debug("Reinforcement mappings:\(self.mappings as AnyObject)")
//            DopeLog.debug("Visualizer mappings:\(self.visualizerMappings as AnyObject)")
        }
        
        
        
    }
}

public extension DopamineVersion {
    public static func convert(from versionDictionary: [String: Any]) -> DopamineVersion? {
        guard let versionID = versionDictionary["versionID"] as? String? else { DopeLog.debug("Bad parameter"); return nil }
        guard let mappings = versionDictionary["mappings"] as? [String:Any] else { DopeLog.debug("Bad parameter"); return nil }
        
        return DopamineVersion.init(versionID: versionID, mappings: mappings, visualizerMappings: versionDictionary["visualizerMappings"] as? [String:Any] ?? [:])
    }
}
