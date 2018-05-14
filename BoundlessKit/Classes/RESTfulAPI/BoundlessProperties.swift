//
//  BoundlessProperties.swift
//  BoundlessKit
//
//  Created by Akash Desai on 11/15/17.
//

import Foundation

internal class BoundlessProperties : UserDefaultsSingleton {
    
    @objc
    static var current: BoundlessProperties = {
        return BoundlessProperties.convert(from: BoundlessKit.testCredentials) ??
            UserDefaults.boundless.unarchive() ??
            {
                let propertiesFile = Bundle.main.path(forResource: "BoundlessProperties", ofType: "plist")!
                let propertiesDictionary = NSDictionary(contentsOfFile: propertiesFile) as! [String: Any]
                let properties = BoundlessProperties.convert(from: propertiesDictionary)!
                UserDefaults.boundless.archive(properties)
                return properties
            }()
        }()
        {
        didSet {
            UserDefaults.boundless.archive(current)
        }
    }
    
    let clientOS = "iOS"
    let clientOSVersion = UIDevice.current.systemVersion
    let clientSDKVersion = Bundle(for: BoundlessKit.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let clientBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    @objc let appID: String
    var version: BoundlessVersion { get { return BoundlessVersion.current} set { BoundlessVersion.current = newValue } }
    var configuration: BoundlessConfiguration { get { return BoundlessConfiguration.current} set { BoundlessConfiguration.current = newValue } }
    @objc var inProduction: Bool { didSet { BoundlessProperties.current = self } }
    @objc let developmentSecret: String
    @objc let productionSecret: String
    
    init(appID: String, versionID: String?, configID: String?, inProduction: Bool, developmentSecret: String, productionSecret: String) {
        self.appID = appID
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
        super.init()
        version = BoundlessVersion.initStandard(with: versionID)
        configuration = BoundlessConfiguration.initStandard(with: configID)
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
        aCoder.encode(appID, forKey: #keyPath(BoundlessProperties.appID))
        aCoder.encode(inProduction, forKey: #keyPath(BoundlessProperties.inProduction))
        aCoder.encode(developmentSecret, forKey: #keyPath(BoundlessProperties.developmentSecret))
        aCoder.encode(productionSecret, forKey: #keyPath(BoundlessProperties.productionSecret))
//        BoundlessLog.debug("Saved BoundlessProperties to user defaults.")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        if let appID = aDecoder.decodeObject(forKey: #keyPath(BoundlessProperties.appID)) as? String,
            let developmentSecret = aDecoder.decodeObject(forKey: #keyPath(BoundlessProperties.developmentSecret)) as? String,
            let productionSecret = aDecoder.decodeObject(forKey: #keyPath(BoundlessProperties.productionSecret)) as? String {
//            BoundlessLog.debug("Found BoundlessProperties saved in user defaults.")
            self.init(
                appID: appID,
                inProduction: aDecoder.decodeBool(forKey: #keyPath(BoundlessProperties.inProduction)),
                developmentSecret: developmentSecret,
                productionSecret: productionSecret
            )
        } else {
//            BoundlessLog.debug("Invalid BoundlessProperties saved to user defaults.")
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
        BoundlessConfiguration.current = BoundlessConfiguration.standard
        BoundlessVersion.current = BoundlessVersion.standard
        CodelessAPI.boot() {
            completion(_primaryIdentity)
        }
    }
    private static var _primaryIdentity: String?
    private var primaryIdentity:String {
        get {
            if BoundlessProperties._primaryIdentity == nil {
                #if DEBUG
                    if let did = BoundlessKit.developmentIdentity {
                        BoundlessLog.debug("set developmentID for primaryIdentity:(\(did))")
                        BoundlessProperties._primaryIdentity = did.isValidIdentity ? did : nil
                    }
                #else
                    if let pid = BoundlessKit.productionIdentity {
//                        BoundlessLog.debug("set productionID for primaryIdentity:(\(pid))")
                        BoundlessProperties._primaryIdentity = pid.isValidIdentity ? pid : nil
                    }
                #endif
            }
            
            if BoundlessProperties._primaryIdentity == nil {
                if BoundlessConfiguration.current.advertiserID,
                    let aid = ASIdHelper.adId()?.uuidString,
                    aid != "00000000-0000-0000-0000-000000000000" {
//                    BoundlessLog.debug("set ASIdentifierManager for primaryIdentity:(\(aid))")
                    BoundlessProperties._primaryIdentity = aid
                } else if let vid = UIDevice.current.identifierForVendor?.uuidString {
//                    BoundlessLog.debug("set identifierForVendor for primaryIdentity:(\(vid))")
                    BoundlessProperties._primaryIdentity = vid
                }
            }
            
            if let _primaryIdentity = BoundlessProperties._primaryIdentity {
                return _primaryIdentity
            } else {
//                 BoundlessLog.debug("set IDUnavailable for primaryIdentity")
                return "IDUnavailable"
            }
        }
    }
}

extension BoundlessProperties {
    static func convert(from propertiesDictionary: [String: Any]?) -> BoundlessProperties? {
        guard let propertiesDictionary = propertiesDictionary else { return nil }
        guard let appID = propertiesDictionary["appID"] as? String else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let inProduction = propertiesDictionary["inProduction"] as? Bool else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let productionSecret = propertiesDictionary["productionSecret"] as? String else { BoundlessLog.debug("Bad parameter"); return nil }
        guard let developmentSecret = propertiesDictionary["developmentSecret"] as? String else { BoundlessLog.debug("Bad parameter"); return nil }
        
        return BoundlessProperties.init(
            appID: appID,
            versionID: propertiesDictionary["versionID"] as? String,
            configID: propertiesDictionary["configID"] as? String,
            inProduction: inProduction,
            developmentSecret: developmentSecret,
            productionSecret: productionSecret
        )
    }
}
