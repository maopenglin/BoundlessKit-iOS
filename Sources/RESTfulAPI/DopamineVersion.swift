//
//  DopamineVersion.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation

@objc
public class DopamineVersion : NSObject, NSCoding {
    
    public static var current: DopamineVersion { get { return DopaminePropertiesControl.current.version } }
    
    @objc public var versionID: String?
    @objc fileprivate var reinforcementMappings: [String:Any]
    
    init(versionID: String?,
         reinforcementMappings: [String:[String:Any]]) {
        self.versionID = versionID
        self.reinforcementMappings = reinforcementMappings
        super.init()
    }
    
    required public convenience init?(coder aDecoder: NSCoder) {
        if let versionID = aDecoder.value(forKey: #keyPath(DopamineVersion.versionID)) as? String?,
            let reinforcementMappings = aDecoder.value(forKey: #keyPath(DopamineVersion.versionID)) as? [String:[String:Any]] {
            self.init(
                versionID: versionID,
                reinforcementMappings: reinforcementMappings
            )
        } else {
            return nil
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(DopamineVersion.versionID))
        aCoder.encode(reinforcementMappings, forKey: #keyPath(DopamineVersion.reinforcementMappings))
    }
    
    static var standard: DopamineVersion {
        return DopamineVersion(versionID: nil, reinforcementMappings: [:])
    }
    
    public func reinforcementActionIDs() -> [String] {
        return reinforcementMappings.keys.sorted()
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
        } else if let reinforcementParameters = reinforcementMappings[actionID] as? [String:Any] {
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
