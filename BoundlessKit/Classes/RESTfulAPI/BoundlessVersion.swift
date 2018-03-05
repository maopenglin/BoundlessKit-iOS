//
//  BoundlessVersion.swift
//  BoundlessKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation

@objc
public class BoundlessVersion : UserDefaultsSingleton {
    
    @objc
    public static var current: BoundlessVersion = {
        return UserDefaults.boundless.unarchive() ?? BoundlessVersion.standard
        }()
        {
        didSet {
            UserDefaults.boundless.archive(current)
        }
    }
    
    @objc public var versionID: String?
    @objc fileprivate var mappings: [String:Any]
    @objc internal fileprivate(set) var visualizerMappings: [String:Any]
    
    fileprivate let updateQueue = SingleOperationQueue()
    public func update(visualizer mappings: [String: Any]?) {
        updateQueue.addOperation {
            if let mappings = mappings {
                self.visualizerMappings = mappings
                CustomClassMethod.registerVisualizerMethods()
            } else if self.visualizerMappings.count == 0 {
                return
            } else {
                self.visualizerMappings = [:]
            }
            UserDefaults.boundless.archive(self)
//            BoundlessLog.debug("New visualizer mappings:\(self.visualizerMappings as AnyObject)")
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
    
    static func initStandard(with versionID: String?) -> BoundlessVersion {
        let standard = BoundlessVersion.standard
        standard.versionID = versionID
        return standard
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let versionID = aDecoder.decodeObject(forKey: #keyPath(BoundlessVersion.versionID)) as? String?,
            let mappings = aDecoder.decodeObject(forKey: #keyPath(BoundlessVersion.mappings)) as? [String:Any],
            let visualizerMappings = aDecoder.decodeObject(forKey: #keyPath(BoundlessVersion.visualizerMappings)) as? [String:Any] {
//            BoundlessLog.debug("Found BoundlessVersion saved in user defaults.")
            self.init(
                versionID: versionID,
                mappings: mappings,
                visualizerMappings: visualizerMappings
            )
        } else {
//            BoundlessLog.debug("Invalid BoundlessVersion saved to user defaults.")
            return nil
        }
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(BoundlessVersion.versionID))
        aCoder.encode(mappings, forKey: #keyPath(BoundlessVersion.mappings))
        aCoder.encode(visualizerMappings, forKey: #keyPath(BoundlessVersion.visualizerMappings))
//        BoundlessLog.debug("Saved BoundlessVersion to user defaults.")
    }
    
    static var standard: BoundlessVersion {
        return BoundlessVersion(versionID: nil)
    }
    
    public func codelessReinforcementFor(sender: String, target: String, selector: String, completion: @escaping ([String:Any]) -> ()) {
        codelessReinforcementFor(actionID: [sender, target, selector].joined(separator: "-"), completion: completion)
    }
    
    public func codelessReinforcementFor(actionID: String, completion: @escaping([String:Any]) -> Void) {
        guard BoundlessConfiguration.current.integrationMethod == "codeless" else {
            return
        }
        if let reinforcementParameters = visualizerMappings[actionID] as? [String: Any] {
            BoundlessLog.debug("Found visualizer reinforcement for <\(actionID)>")
            if let codeless = reinforcementParameters["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String:Any]],
                let randomReinforcement = reinforcements.selectRandom() {
                completion(randomReinforcement)
            } else {
                BoundlessLog.debug("Bad visualizer parameters")
            }
        } else if let reinforcementParameters = mappings[actionID] as? [String:Any] {
            BoundlessLog.debug("Found reinforcement for <\(actionID)>")
            if let codeless = reinforcementParameters["codeless"] as? [String: Any],
                let reinforcements = codeless["reinforcements"] as? [[String:Any]] {
                BoundlessKit.reinforce(actionID) { reinforcementType in
                    if reinforcementType == Cartridge.defaultReinforcementDecision {
                        return
                    }
                    for reinforcement in reinforcements {
                        if reinforcement["primitive"] as? String == reinforcementType {
                            completion(reinforcement)
                            return
                        }
                    }
                    BoundlessLog.error("Could not find reinforcementType:\(reinforcementType)")
                }
            } else {
                BoundlessLog.error("Bad reinforcement parameters")
            }
        } else {
//            BoundlessLog.debug("No reinforcement mapping found for <\(actionID)>")
//            BoundlessLog.debug("Reinforcement mappings:\(self.mappings as AnyObject)")
//            BoundlessLog.debug("Visualizer mappings:\(self.visualizerMappings as AnyObject)")
        }
        
        
        
    }
}

public extension BoundlessVersion {
    public static func convert(from versionDictionary: [String: Any]) -> BoundlessVersion? {
        guard let versionID = versionDictionary["versionID"] as? String? else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let mappings = versionDictionary["mappings"] as? [String:Any] else { BoundlessLog.debug("Bad parameter"); return nil }
        
        return BoundlessVersion.init(versionID: versionID, mappings: mappings, visualizerMappings: versionDictionary["visualizerMappings"] as? [String:Any] ?? [:])
    }
    
    public var actionIDs: [String] {
        return Array(mappings.keys)
    }
    
    public var visualizerActionIDs: [String] {
        return Array(visualizerMappings.keys)
    }
    
}
