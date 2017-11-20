//
//  DopamineVersion.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation

@objc
public class DopamineVersion : UserDefaultsSingleton {
    
    private static var _current: DopamineVersion? =  { return UserDefaults.dopamine.unarchive() }()
    {
        didSet {
            UserDefaults.dopamine.archive(_current)
        }
    }
    public static var current: DopamineVersion {
        get {
            if let _ = _current {
            } else {
                _current = DopamineVersion.standard
            }
            
            return _current!
        }
        set {
            _current = newValue
        }
    }
    
    @objc public var versionID: String?
    @objc fileprivate var mappings: [String:Any]
    @objc internal fileprivate(set) var visualizerMappings: [String:Any]
    public func updateVisualizerMappings(_ visualizerMappings: [String: Any]) {
        self.visualizerMappings = visualizerMappings
        UserDefaults.dopamine.archive(self)
        print("New visualizer mappings:\(self.visualizerMappings as AnyObject)")
    }
    
    init(versionID: String?,
         mappings: [String:Any],
         visualizerMappings: [String: Any]) {
        self.versionID = versionID
        self.mappings = mappings
        self.visualizerMappings = visualizerMappings
        super.init()
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let versionID = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.versionID)) as? String?,
            let mappings = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.mappings)) as? [String:Any],
            let visualizerMappings = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.visualizerMappings)) as? [String:Any] {
            print("Found DopamineVersion saved in user defaults.")
            self.init(
                versionID: versionID,
                mappings: mappings,
                visualizerMappings: visualizerMappings
            )
        } else {
            print("Invalid DopamineVersion saved to user defaults.")
            return nil
        }
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(DopamineVersion.versionID))
        aCoder.encode(mappings, forKey: #keyPath(DopamineVersion.mappings))
        aCoder.encode(visualizerMappings, forKey: #keyPath(DopamineVersion.visualizerMappings))
        print("Saved DopamineVersion to user defaults.")
    }
    
    static var standard: DopamineVersion {
        return DopamineVersion(versionID: nil, mappings: [:], visualizerMappings: [:])
    }
    
    public func codelessReinforcementFor(sender: String, target: String, selector: String, completion: @escaping ([String:Any]) -> ()) {
        codelessReinforcementFor(actionID: [sender, target, selector].joined(separator: "-"), completion: completion)
    }
    
    public func codelessReinforcementFor(actionID: String, completion: @escaping ([String:Any]) -> ()) {
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
        if let versionID = versionDictionary["versionID"] as? String?,
            let mappings = versionDictionary["mappings"] as? [String:Any] {
            return DopamineVersion.init(versionID: versionID, mappings: mappings, visualizerMappings: versionDictionary["visualizerMappings"] as? [String:Any] ?? [:])
        } else { return nil }
    }
}
