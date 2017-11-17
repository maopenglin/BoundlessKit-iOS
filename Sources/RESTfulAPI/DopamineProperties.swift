//
//  DopamineProperties.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/15/17.
//

import Foundation

internal class DopaminePropertiesControl : NSObject {
    
    private static var _current: DopamineProperties?
    static var current: DopamineProperties {
        if let _current = _current {
            return _current
        } else {
            _current = retrieve()
            return _current!
        }
    }
    
    public static func retrieve() -> DopamineProperties {
        return loadTest() ?? loadDefaults() ?? loadPlist()
    }
    
    private static func loadTest() -> DopamineProperties? {
        print("1")
        if let propertiesDictionary = DopamineKit.testCredentials {
            return DopamineProperties.convert(propertiesDictionary: propertiesDictionary)
        } else {
            return nil
        }
    }
    
    private static func loadDefaults() -> DopamineProperties? {
        print("2")
        if let savedProperties = DopamineProperties.get() {
            print("Using saved dopamine properties")
            return savedProperties
        } else {
            return nil
        }
    }
    
    private static func loadPlist() -> DopamineProperties {
        print("3")
        let propertiesFile = Bundle.main.path(forResource: "DopamineProperties", ofType: "plist")!
        let propertiesDictionary = NSDictionary(contentsOfFile: propertiesFile) as! [String: Any]
        let properties = DopamineProperties.convert(propertiesDictionary: propertiesDictionary)!
        DopamineProperties.set(properties)
        return properties
    }
    
}

internal class DopamineProperties : NSObject, NSCoding {
    
    private static let defaults = UserDefaults.standard
    private static let defaultsKey = "DopamineProperties"
    fileprivate static func set(_ properties: DopamineProperties) { defaults.set(NSKeyedArchiver.archivedData(withRootObject: properties), forKey: defaultsKey) }
    fileprivate static func get() -> DopamineProperties? {
        if let savedPropertiesData = defaults.object(forKey: defaultsKey) as? Data,
            let savedProperties = NSKeyedUnarchiver.unarchiveObject(with: savedPropertiesData) as? DopamineProperties {
            return savedProperties
        } else { return nil }
    }
    
    static var current: DopamineProperties { get { return DopaminePropertiesControl.current } }
    
    let clientOS = "iOS"
    let clientOSVersion = UIDevice.current.systemVersion
    let clientSDKVersion = Bundle(for: DopamineKit.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let clientBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    @objc let appID: String
    @objc var version: DopamineVersion { didSet { DopamineProperties.set(self); SyncCoordinator.shared.flush()  } }
    @objc var configuration: DopamineConfiguration { didSet { DopamineProperties.set(self) } }
    @objc var inProduction: Bool { didSet { DopamineProperties.set(self) } }
    @objc let developmentSecret: String
    @objc let productionSecret: String
    
    init(appID: String, versionID: String?, configID: String?, inProduction: Bool, developmentSecret: String, productionSecret: String) {
        self.appID = appID
        self.version = DopamineVersion(versionID: versionID, mappings: [:])
        self.configuration = DopamineConfiguration.initStandard(with: configID) //TO-DO: get from /boot
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
        super.init()
    }
    
    init(appID: String, version: DopamineVersion, configuration: DopamineConfiguration, inProduction: Bool, developmentSecret: String, productionSecret: String) {
        self.appID = appID
        self.version = version
        self.configuration = configuration
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(appID, forKey: #keyPath(DopamineProperties.appID))
        aCoder.encode(version, forKey: #keyPath(DopamineProperties.version))
        aCoder.encode(configuration, forKey: #keyPath(DopamineProperties.configuration))
        aCoder.encode(inProduction, forKey: #keyPath(DopamineProperties.inProduction))
        aCoder.encode(developmentSecret, forKey: #keyPath(DopamineProperties.developmentSecret))
        aCoder.encode(productionSecret, forKey: #keyPath(DopamineProperties.productionSecret))
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        if let appID = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.appID)) as? String,
            let version = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.version)) as? DopamineVersion,
            let configuration = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.configuration)) as? DopamineConfiguration,
            let developmentSecret = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.developmentSecret)) as? String,
            let productionSecret = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.productionSecret)) as? String {
            self.init(
                appID: appID,
                version: version,
                configuration: configuration,
                inProduction: aDecoder.decodeBool(forKey: #keyPath(DopamineProperties.inProduction)),
                developmentSecret: developmentSecret,
                productionSecret: productionSecret
            )
        } else {
            print("Invalid DopamineProperties saved to user defaults.")
            return nil
        }
    }
    
    lazy var apiCredentials: [String: Any] = {
        return [ "clientOS": clientOS,
                 "clientOSVersion": clientOSVersion,
                 "clientSDKVersion": clientSDKVersion,
                 "clientBuild": clientBuild,
                 "primaryIdentity": primaryIdentity,
                 "appID": appID,
                 "versionID": version.versionID ?? "",
                 "secret": inProduction ? productionSecret : developmentSecret
        ]
    }()
    
    /// Computes a primary identity for the user
    ///
    private lazy var primaryIdentity:String = {
        #if DEBUG
            if let tid = DopamineKit.developmentIdentity {
                DopeLog.debug("Testing with primaryIdentity:(\(tid))")
                return tid
            }
        #endif
        if DopamineConfiguration.current.advertiserID,
            let aid = ASIdentifierManager.shared().adId()?.uuidString,
            aid != "00000000-0000-0000-0000-000000000000" {
//            DopeLog.debug("ASIdentifierManager primaryIdentity:(\(aid))")
            return aid
        } else if let vid = UIDevice.current.identifierForVendor?.uuidString {
//            DopeLog.debug("identifierForVendor primaryIdentity:(\(vid))")
            return vid
        } else {
//            DopeLog.debug("IDUnavailable for primaryIdentity")
            return "IDUnavailable"
        }
    }()
}

extension DopamineProperties {
    static func convert(propertiesDictionary: [String: Any]) -> DopamineProperties? {
        if let appID = propertiesDictionary["appID"] as? String,
            let inProduction = propertiesDictionary["inProduction"] as? Bool,
            let productionSecret = propertiesDictionary["productionSecret"] as? String,
            let developmentSecret = propertiesDictionary["developmentSecret"] as? String {
            return DopamineProperties.init(
                appID: appID,
                versionID: propertiesDictionary["versionID"] as? String,
                configID: propertiesDictionary["configID"] as? String,
                inProduction: inProduction,
                developmentSecret: developmentSecret,
                productionSecret: productionSecret
            )
        } else { return nil }
    }
}
