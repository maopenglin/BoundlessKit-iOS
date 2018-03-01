//
//  DopamineProperties.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/15/17.
//

import Foundation

internal class DopamineProperties : DopamineDefaultsSingleton {
    
    @objc
    static var current: DopamineProperties? = {
        return DopamineDefaults.current.unarchive() ??
            {
                if let propertiesFile = Bundle.main.path(forResource: "DopamineProperties", ofType: "plist"),
                    let propertiesDictionary = NSDictionary(contentsOfFile: propertiesFile) as? [String: Any],
                    let properties = DopamineProperties.convert(from: propertiesDictionary) {
                    DopamineDefaults.current.archive(properties)
                    return properties
                } else {
                    return nil
                }
            }()
        }()
        {
        didSet {
            DopamineDefaults.current.archive(current)
        }
    }
    
    let clientOS = "iOS"
    let clientOSVersion = UIDevice.current.systemVersion
    let clientSDKVersion = Bundle(for: DopamineKit.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let clientBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    @objc let appID: String
    var version: DopamineVersion { get { return DopamineVersion.current} set { DopamineVersion.current = newValue } }
    var configuration: DopamineConfiguration { get { return DopamineConfiguration.current} set { DopamineConfiguration.current = newValue } }
    @objc var inProduction: Bool { didSet { DopamineProperties.current = self } }
    @objc static var productionMode: Bool { get { return (current != nil && current!.inProduction)}}
    @objc let developmentSecret: String
    @objc let productionSecret: String
    
    init(appID: String, versionID: String?, configID: String?, inProduction: Bool, developmentSecret: String, productionSecret: String) {
        self.appID = appID
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
        super.init()
        version = DopamineVersion.initStandard(with: versionID)
        configuration = DopamineConfiguration.initStandard(with: configID)
    }
    
    init(appID: String, inProduction: Bool, developmentSecret: String, productionSecret: String) {
        self.appID = appID
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
        super.init()
        _ = self.version
        _ = self.configuration
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(appID, forKey: #keyPath(DopamineProperties.appID))
        aCoder.encode(inProduction, forKey: #keyPath(DopamineProperties.inProduction))
        aCoder.encode(developmentSecret, forKey: #keyPath(DopamineProperties.developmentSecret))
        aCoder.encode(productionSecret, forKey: #keyPath(DopamineProperties.productionSecret))
//        DopeLog.debug("Saved DopamineProperties to user defaults.")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        if let appID = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.appID)) as? String,
            let developmentSecret = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.developmentSecret)) as? String,
            let productionSecret = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.productionSecret)) as? String {
//            DopeLog.debug("Found DopamineProperties saved in user defaults.")
            self.init(
                appID: appID,
                inProduction: aDecoder.decodeBool(forKey: #keyPath(DopamineProperties.inProduction)),
                developmentSecret: developmentSecret,
                productionSecret: productionSecret
            )
        } else {
//            DopeLog.debug("Invalid DopamineProperties saved to user defaults.")
            return nil
        }
    }
    
    var apiCredentials: [String: Any] {
        get {
            return [ "clientOS": clientOS,
                     "clientOSVersion": clientOSVersion,
                     "clientSDKVersion": clientSDKVersion,
                     "clientBuild": clientBuild,
                     "primaryIdentity": primaryIdentity,
                     "appID": appID,
                     "versionID": version.versionID ?? "nil",
                     "secret": inProduction ? productionSecret : developmentSecret,
                     "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                     "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
            ]
        }
    }
    
    /// Computes a primary identity for the user
    ///
    internal static func resetIdentity(completion: @escaping (String?) -> () = {_ in}) {
        _primaryIdentity = nil
        SyncCoordinator.flush()
        DopamineConfiguration.current = DopamineConfiguration.standard
        DopamineVersion.current = DopamineVersion.standard
        CodelessAPI.boot() {
            completion(_primaryIdentity)
        }
    }
    private static var _primaryIdentity: String?
    private var primaryIdentity:String {
        get {
            if DopamineProperties._primaryIdentity == nil {
                #if DEBUG
                    if let did = DopamineKit.developmentIdentity {
                        DopeLog.debug("set developmentID for primaryIdentity:(\(did))")
                        DopamineProperties._primaryIdentity = did.isValidIdentity ? did : nil
                    }
                #else
                    if let pid = DopamineKit.productionIdentity {
                        DopeLog.debug("set productionID for primaryIdentity:(\(pid))")
                        DopamineProperties._primaryIdentity = pid.isValidIdentity ? pid : nil
                    }
                #endif
            }
            
            if DopamineProperties._primaryIdentity == nil {
                if DopamineConfiguration.current.advertiserID,
                    let aid = ASIdentifierManager.shared().adId()?.uuidString,
                    aid != "00000000-0000-0000-0000-000000000000" {
                    DopeLog.debug("set ASIdentifierManager for primaryIdentity:(\(aid))")
                    DopamineProperties._primaryIdentity = aid
                } else if let vid = UIDevice.current.identifierForVendor?.uuidString {
                    DopeLog.debug("set identifierForVendor for primaryIdentity:(\(vid))")
                    DopamineProperties._primaryIdentity = vid
                }
            }
            
            if let _primaryIdentity = DopamineProperties._primaryIdentity {
                return _primaryIdentity
            } else {
                // DopeLog.debug("set IDUnavailable for primaryIdentity")
                return "IDUnavailable"
            }
        }
    }
}

extension DopamineProperties {
    static func convert(from propertiesDictionary: [String: Any]?) -> DopamineProperties? {
        guard let propertiesDictionary = propertiesDictionary else { return nil }
        guard let appID = propertiesDictionary["appID"] as? String else { DopeLog.debug("Bad parameter"); return nil }
        guard let inProduction = propertiesDictionary["inProduction"] as? Bool else { DopeLog.debug("Bad parameter"); return nil }
        guard let productionSecret = propertiesDictionary["productionSecret"] as? String else { DopeLog.debug("Bad parameter"); return nil }
        guard let developmentSecret = propertiesDictionary["developmentSecret"] as? String else { DopeLog.debug("Bad parameter"); return nil }
        
        return DopamineProperties.init(
            appID: appID,
            versionID: propertiesDictionary["versionID"] as? String,
            configID: propertiesDictionary["configID"] as? String,
            inProduction: inProduction,
            developmentSecret: developmentSecret,
            productionSecret: productionSecret
        )
    }
}
