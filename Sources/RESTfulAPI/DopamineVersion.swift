//
//  DopamineVersion.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation

public class DopamineVersionControl : NSObject {
    
    static let VersionChangeNotification = Notification(name: NSNotification.Name(rawValue: "DopamineVersionControl.DidSetNotification"), object: nil)
    
    fileprivate static var _current: DopamineVersion?
    @objc public static var current: DopamineVersion {
        if let _current = _current {
            return _current
        } else {
            _current = retrieve()
            return _current!
        }
    }
    
    public static func set(_ version: DopamineVersion) {
        if current.versionID != version.versionID {
//            SyncCoordinator.shared.flush()
            DopeLog.debug("DopamineVersion updated!")
            NotificationCenter.default.post(VersionChangeNotification)
        }
        
        DopamineVersion.defaults.set(version, forKey: DopamineVersion.defaultsKey)
        _current = version
        
//        for actionID in (version.reinforcementMappings).keys{
//            Cartridge(actionID: actionID).sync()
//        }
    }
    
    public static func retrieve() -> DopamineVersion {
        if let savedVersionData = DopamineVersion.defaults.object(forKey: DopamineVersion.defaultsKey) as? Data,
            let savedVersion = NSKeyedUnarchiver.unarchiveObject(with: savedVersionData) as? DopamineVersion {
            print("using saved dopamine version")
            return savedVersion
        } else {
            print("using standard dopamine version")
            return DopamineVersion.standard
        }
    }
    
}

@objc
public class DopamineVersion : NSObject, NSCoding {
    
    fileprivate static let defaults = UserDefaults.standard
    fileprivate static let defaultsKey = "DopamineVersion"
    
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
    
    public func set() {
        DopamineVersionControl.set(self)
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
