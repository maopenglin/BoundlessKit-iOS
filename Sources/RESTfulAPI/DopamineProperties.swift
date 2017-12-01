//
//  DopamineProperties.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/15/17.
//

import Foundation

internal class DopamineProperties : UserDefaultsSingleton {
    
    @objc
    static var current: DopamineProperties! = {
        return UserDefaults.dopamine.unarchive() ??
            DopamineProperties.convert(from: DopamineKit.testCredentials) ??
            {
                let propertiesFile = Bundle.main.path(forResource: "DopamineProperties", ofType: "plist")!
                let propertiesDictionary = NSDictionary(contentsOfFile: propertiesFile) as! [String: Any]
                let properties = DopamineProperties.convert(from: propertiesDictionary)!
                return properties
            }()
        }()
        {
        didSet {
            UserDefaults.dopamine.archive(current)
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
    @objc let developmentSecret: String
    @objc let productionSecret: String
    
    init(appID: String, versionID: String?, configID: String?, inProduction: Bool, developmentSecret: String, productionSecret: String) {
        self.appID = appID
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
        super.init()
        _ = DopamineVersion.initStandard(with: versionID)
        _ = DopamineConfiguration.initStandard(with: configID)
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
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        if let appID = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.appID)) as? String,
            let developmentSecret = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.developmentSecret)) as? String,
            let productionSecret = aDecoder.decodeObject(forKey: #keyPath(DopamineProperties.productionSecret)) as? String {
            print("Found DopamineProperties saved in user defaults.")
            self.init(
                appID: appID,
                inProduction: aDecoder.decodeBool(forKey: #keyPath(DopamineProperties.inProduction)),
                developmentSecret: developmentSecret,
                productionSecret: productionSecret
            )
        } else {
            print("Invalid DopamineProperties saved to user defaults.")
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
    static func convert(from propertiesDictionary: [String: Any]?) -> DopamineProperties? {
        guard let propertiesDictionary = propertiesDictionary else { return nil }
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
