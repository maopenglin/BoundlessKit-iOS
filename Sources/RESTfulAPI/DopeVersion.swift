//
//  DopeVersion.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation

public class DopeVersionControl : NSObject {
    
    fileprivate static var _current: DopeVersion?
    @objc public static var current: DopeVersion {
        if let _current = _current {
            return _current
        } else {
            _current = retreive()
            return _current!
        }
    }
    
    static func set(_ version: DopeVersion) {
        if _current?.versionID != version.versionID {
            SyncCoordinator.shared.flush()
        }
        
        DopeVersion.defaults.set(version, forKey: DopeVersion.defaultsKey)
        _current = version
        
        for actionID in (version.reinforcementMappings).keys{
            Cartridge(actionID: actionID).sync()
        }
    }
    
    static func retreive() -> DopeVersion {
        if let savedVersionData = DopeVersion.defaults.object(forKey: DopeVersion.defaultsKey) as? NSData,
            let savedVersion = NSKeyedUnarchiver.unarchiveObject(with: savedVersionData as Data) as? DopeVersion {
            print("using saved dopamine version")
            return savedVersion
        } else {
            print("using standard dopamine version")
            return DopeVersion.standard
        }
    }
}

@objc
public class DopeVersion : NSObject, NSCoding {
    
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
        if let versionID = aDecoder.value(forKey: #keyPath(DopeVersion.versionID)) as? String?,
            let reinforcementMappings = aDecoder.value(forKey: #keyPath(DopeVersion.versionID)) as? [String:[String:Any]] {
            self.init(
                versionID: versionID,
                reinforcementMappings: reinforcementMappings
            )
        } else {
            return nil
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(DopeVersion.versionID))
        aCoder.encode(reinforcementMappings, forKey: #keyPath(DopeVersion.reinforcementMappings))
    }
    
    static var standard: DopeVersion {
        return DopeVersion(versionID: nil, reinforcementMappings: [:])
    }
    
    public func reinforcementFor(sender: String, target: String, selector: String, completion: @escaping ([String:Any]) -> ()) {
        let reinforcementKey = [sender, target, selector].joined(separator: "-")
        
        if VisualizerAPI.shared.visualizerMappings != nil,
            let reinforcementParameters = VisualizerAPI.shared.visualizerMappings![reinforcementKey] {
            DopeLog.debug("Found visualizer reinforcement for <\(reinforcementKey)>")
            if let reinforcements = reinforcementParameters["reinforcements"] as? [[String:Any]] {
                completion(reinforcements.selectRandom())
            }
        } else if let reinforcementParameters = reinforcementMappings[reinforcementKey] as? [String:Any] {
            DopeLog.debug("Found reinforcement for <\(reinforcementKey)>")
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
            DopeLog.debug("No reinforcement mapping found for <\(reinforcementKey)>")
        }
    }
    
}
