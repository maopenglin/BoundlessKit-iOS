//
//  BoundlessProperties.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessProperties {
    
    let clientOS = "iOS"
    let clientOSVersion = UIDevice.current.systemVersion
    let clientSDKVersion = Bundle(for: BoundlessKit.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let clientBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    let appID: String
    let inProduction: Bool
    var version: BoundlessVersion {
        didSet {
            BKLog.print("Set BoundlessProperties version with versionID <\(version.versionID ?? "nil")>")
        }
    }
    let developmentSecret: String
    let productionSecret: String
    private let primaryIdentity:String
    
    init(_ primaryIdentity: String? = nil, _ appID: String, _ version: BoundlessVersion, _ inProduction: Bool, _ developmentSecret: String, _ productionSecret: String) {
        self.appID = appID
        self.version = version
        self.inProduction = inProduction
        self.developmentSecret = developmentSecret
        self.productionSecret = productionSecret
        if let primaryIdentity = primaryIdentity {
            self.primaryIdentity = primaryIdentity
        } else if let vid = UIDevice.current.identifierForVendor?.uuidString {
//            BKLog.print("set identifierForVendor for primaryIdentity:(\(vid))")
            self.primaryIdentity = vid
        } else {
//            BKLog.print("set IDUnavailable for primaryIdentity")
            self.primaryIdentity = "IDUnavailable"
        }
    }
    
    var apiCredentials: [String: Any]? {
        get {
            guard let versionID = version.versionID else {
                return nil
            }
            return [ "clientOS": clientOS,
                     "clientOSVersion": clientOSVersion,
                     "clientSDKVersion": clientSDKVersion,
                     "clientBuild": clientBuild,
                     "primaryIdentity": primaryIdentity,
                     "appID": appID,
                     "versionID": versionID,
                     "secret": inProduction ? productionSecret : developmentSecret,
                     "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                     "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
            ]
        }
    }
    
    var bootCredentials: [String: Any] {
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
}

extension BoundlessProperties {
    static var fromFile: BoundlessProperties? {
        if let propertiesFile = Bundle.main.path(forResource: "BoundlessProperties", ofType: "plist"),
            let propertiesDictionary = NSDictionary(contentsOfFile: propertiesFile) as? [String: Any] {
            return BoundlessProperties.convert(from: propertiesDictionary)
        } else {
            return nil
        }
    }
    
    static func convert(from propertiesDictionary: [String: Any]) -> BoundlessProperties? {
        guard let appID = propertiesDictionary["appID"] as? String else { BKLog.error("Bad parameter"); return nil }
        guard let inProduction = propertiesDictionary["inProduction"] as? Bool else { BKLog.error("Bad parameter"); return nil }
        guard let productionSecret = propertiesDictionary["productionSecret"] as? String else { BKLog.error("Bad parameter"); return nil }
        guard let developmentSecret = propertiesDictionary["developmentSecret"] as? String else { BKLog.error("Bad parameter"); return nil }
        
        return BoundlessProperties.init(
            propertiesDictionary["primaryIdentity"] as? String,
            appID,
            BoundlessVersion.init(propertiesDictionary["versionID"] as? String, [:]),
            inProduction,
            developmentSecret,
            productionSecret
        )
    }
}
