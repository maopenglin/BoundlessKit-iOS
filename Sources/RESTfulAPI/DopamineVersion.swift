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
    
    init(versionID: String?,
         mappings: [String:Any]) {
        self.versionID = versionID
        self.mappings = mappings
        super.init()
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let versionID = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.versionID)) as? String?,
            let mappings = aDecoder.decodeObject(forKey: #keyPath(DopamineVersion.mappings)) as? [String:Any] {
            print("Found DopamineVersion saved in user defaults.")
            self.init(
                versionID: versionID,
                mappings: mappings
            )
        } else {
            print("Invalid DopamineVersion saved to user defaults.")
            return nil
        }
    }
    
    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(DopamineVersion.versionID))
        aCoder.encode(mappings, forKey: #keyPath(DopamineVersion.mappings))
        print("Saved DopamineVersion to user defaults.")
    }
    
    static var standard: DopamineVersion {
        return DopamineVersion(versionID: nil, mappings: [:])
    }
    
    public func reinforcementActionIDs() -> [String] {
        return mappings.keys.sorted()
    }
    
    public func reinforcementFor(sender: String, target: String, selector: String, completion: @escaping ([String:Any]) -> ()) {
        reinforcementFor(actionID: [sender, target, selector].joined(separator: "-"), completion: completion)
    }
    
    public func reinforcementFor(actionID: String, completion: @escaping ([String:Any]) -> ()) {
        if VisualizerAPI.shared.visualizerMappings != nil,
            let reinforcementParameters = VisualizerAPI.shared.visualizerMappings![actionID] {
            DopeLog.debug("Found visualizer reinforcement for <\(actionID)>")
            if let reinforcements = reinforcementParameters["reinforcements"] as? [[String:Any]] {
                completion(reinforcements.selectRandom())
            }
        } else if let reinforcementParameters = mappings[actionID] as? [String:Any] {
            DopeLog.debug("Found reinforcement for <\(actionID)>")
            if let actionID = reinforcementParameters["actionID"] as? String,
                let reinforcements = reinforcementParameters["reinforcements"] as? [[String:Any]] {
                DopamineKit.reinforce(actionID) { reinforcementType in
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
        }
    }
}

public extension DopamineVersion {
    public static func convert(from versionDictionary: [String: Any]) -> DopamineVersion? {
        if let versionID = versionDictionary["versionID"] as? String?,
            let mappings = versionDictionary["mappings"] as? [String:Any] {
            return DopamineVersion.init(versionID: versionID, mappings: mappings)
        } else { return nil }
    }
}
