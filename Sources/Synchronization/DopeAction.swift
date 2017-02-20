//
//  DopeEvent.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

@objc
internal class DopeAction : NSObject, NSCoding {
    
    private let actionIDKey = "actionID"
    private let reinforcementDecisionKey = "reinforcementDecision"
    private let metaDataKey = "metaData"
    private let utcKey = "utc"
    private let timezoneOffsetKey = "timezoneOffset"
    
    var actionID:String
    var reinforcementDecision:String?
    var metaData:[String: AnyObject]?
    var utc:Int64
    var timezoneOffset:Int64
    
    private static let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    private static let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    
    /// This function initializes a DopeAction
    ///
    /// - parameters:
    ///     - actionID: The name for the action.
    ///     - reinforcementDecision?: Reinforcement decision for the action if one has been made. Defaults to `nil`.
    ///     - metaData?: JSON formattable action details. Defaults to `nil`.
    ///     - utc: Time the action occured in utc milliseconds. Defaults to the current time.
    ///     - timezoneOffset: Local timezone offset for the time the action occured in milliseconds. Defaults to the current device timezone.
    ///
    init(actionID:String,
                reinforcementDecision:String? = nil,
                metaData:[String:AnyObject]? = nil,
                utc:Int64 = Int64( 1000*Date().timeIntervalSince1970 ),
                timezoneOffset:Int64 = Int64( 1000*NSTimeZone.default.secondsFromGMT() ))
    {
        self.actionID = actionID
        self.reinforcementDecision = reinforcementDecision
        self.metaData = metaData
        self.utc = utc
        self.timezoneOffset = timezoneOffset
    }
    
    /// Decodes a saved action from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.actionID = aDecoder.decodeObject(forKey: actionIDKey) as! String
        self.reinforcementDecision = aDecoder.decodeObject(forKey: reinforcementDecisionKey) as? String
        self.metaData = aDecoder.decodeObject(forKey: metaDataKey) as? [String:AnyObject]
        self.utc = aDecoder.decodeInt64(forKey: utcKey)
        self.timezoneOffset = aDecoder.decodeInt64(forKey: timezoneOffsetKey)
        
        if (self.metaData == nil) { self.metaData = [:] }
        if let v = DopeAction.versionNumber {
            self.metaData?["CFBundleShortVersionString"] = v as AnyObject
        }
        if let b = DopeAction.buildNumber {
            self.metaData?["CFBundleVersion"] = b as AnyObject
        }
    }
    
    /// Encodes an action and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(actionID, forKey: actionIDKey)
        aCoder.encode(reinforcementDecision, forKey: reinforcementDecisionKey)
        aCoder.encode(metaData, forKey: metaDataKey)
        aCoder.encode(utc, forKey: utcKey)
        aCoder.encode(timezoneOffset, forKey: timezoneOffsetKey)
    }
    
    /// This function converts a DopeAction to a JSON compatible Object
    ///
    func toJSONType() -> [String : AnyObject] {
        var jsonObject: [String:AnyObject] = [:]
        
        jsonObject[actionIDKey] = actionID as AnyObject
        jsonObject[reinforcementDecisionKey] = reinforcementDecision as AnyObject?
        jsonObject[metaDataKey] = metaData as AnyObject?
        jsonObject["time"] = [
            ["timeType":utcKey, "value": NSNumber(value: utc)],
            ["timeType":"deviceTimezoneOffset", "value": NSNumber(value: timezoneOffset)]
        ] as AnyObject
        
        return jsonObject
    }
}
