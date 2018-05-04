//
//  BoundlessCredentials.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/10/18.
//

import Foundation

internal struct BoundlessCredentials {
    
    let clientOS = "iOS"
    let clientOSVersion = UIDevice.current.systemVersion
    let clientSDKVersion = Bundle(for: BoundlessKit.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let clientBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    let appID: String
    var primaryIdentity:String
    let inProduction: Bool
    let developmentSecret: String
    let productionSecret: String
    
    init(_ primaryIdentity: String? = nil, _ appID: String, _ inProduction: Bool, _ developmentSecret: String, _ productionSecret: String) {
        self.appID = appID
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
    
    var json: [String: Any] {
        get {
                    return [ "clientOS": clientOS,
                             "clientOSVersion": clientOSVersion,
                             "clientSDKVersion": clientSDKVersion,
                             "clientBuild": clientBuild,
                             "primaryIdentity": primaryIdentity,
                             "appID": appID,
                             "secret": inProduction ? productionSecret : developmentSecret,
                             "utc": NSNumber(value: Int64(Date().timeIntervalSince1970) * 1000),
                             "timezoneOffset": NSNumber(value: Int64(NSTimeZone.default.secondsFromGMT()) * 1000)
                    ]
            }
        }
}

extension BoundlessCredentials {
    static func convert(from propertiesDictionary: [String: Any]) -> BoundlessCredentials? {
        guard let appID = propertiesDictionary["appID"] as? String else { BKLog.print(error: "Bad parameter"); return nil }
        guard let inProduction = propertiesDictionary["inProduction"] as? Bool else { BKLog.print(error: "Bad parameter"); return nil }
        guard let productionSecret = propertiesDictionary["productionSecret"] as? String else { BKLog.print(error: "Bad parameter"); return nil }
        guard let developmentSecret = propertiesDictionary["developmentSecret"] as? String else { BKLog.print(error: "Bad parameter"); return nil }
        
        return BoundlessCredentials.init(
            propertiesDictionary["primaryIdentity"] as? String,
            appID,
            inProduction,
            developmentSecret,
            productionSecret
        )
    }
}
