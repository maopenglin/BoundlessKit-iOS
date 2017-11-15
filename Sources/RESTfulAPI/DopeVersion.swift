//
//  DopeVersion.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/14/17.
//

import Foundation


@objc
public class DopeVersion : NSObject {
    
    fileprivate static var _shared: DopeVersion?
    
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
        self.init(acoder: aDecoder)
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

extension DopeVersion {
    
    @objc public static var shared: DopeVersion {
        if let _shared = _shared {
            return _shared
        } else {
            _shared = retreive()
            return _shared!
        }
    }
    
    func set() {
        if DopeVersion.shared.versionID != self.versionID {
            SyncCoordinator.shared.flush()
        }
        DopeVersion.save(version: self)
        for actionID in (self.reinforcementMappings).keys{
            Cartridge(actionID: actionID).sync()
        }
    }
    
    fileprivate static func save(version: DopeVersion? = _shared) {
        DopeVersion.defaults.set(version, forKey: DopeVersion.defaultsKey)
        _shared = version
    }
    
    static func retreive() -> DopeVersion {
        if let savedVersionData = DopeVersion.defaults.object(forKey: DopeVersion.defaultsKey) as? NSData,
            let savedVersion = NSKeyedUnarchiver.unarchiveObject(with: savedVersionData as Data) as? DopeVersion {
            print("using saved dopamine version")
            return savedVersion
        } else {
            print("using standard dopamine version")
            return standard
        }
    }
    
}


extension DopeVersion : NSCoding {
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(DopeVersion.versionID))
        aCoder.encode(reinforcementMappings, forKey: #keyPath(DopeVersion.reinforcementMappings))
    }
    
    convenience public init?(acoder aDecoder: NSCoder) {
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
    
}
