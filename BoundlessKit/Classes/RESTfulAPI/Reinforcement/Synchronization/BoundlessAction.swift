//
//  BoundlessAction.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

@objc
internal class BoundlessAction : NSObject, NSCoding {
    
    private let actionIDKey = "actionID"
    private let reinforcementDecisionKey = "reinforcementDecision"
    private let metaDataKey = "metaData"
    private let utcKey = "utc"
    private let timezoneOffsetKey = "timezoneOffset"
    
    var actionID:String
    var reinforcementDecision:String?
    var metaData:[String: Any]?
    var utc:Int64
    var timezoneOffset:Int64
    
    /// This function initializes a BoundlessAction
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
                metaData:[String:Any]? = nil,
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
        self.metaData = aDecoder.decodeObject(forKey: metaDataKey) as? [String:Any]
        self.utc = aDecoder.decodeInt64(forKey: utcKey)
        self.timezoneOffset = aDecoder.decodeInt64(forKey: timezoneOffsetKey)
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
    
    func addMetaData(_ newData: [String: Any]?) {
        guard let newData = newData else {
            return
        }
        if metaData != nil {
            for (key,value) in newData {
                metaData?.updateValue(value, forKey: key)
            }
        } else {
            metaData = newData
        }
    }
    
    /// This function converts a BoundlessAction to a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject[actionIDKey] = actionID
        jsonObject[reinforcementDecisionKey] = reinforcementDecision
        jsonObject[metaDataKey] = metaData
        jsonObject["time"] = [
            ["timeType":utcKey, "value": NSNumber(value: utc)],
            ["timeType":"deviceTimezoneOffset", "value": NSNumber(value: timezoneOffset)]
        ]
        
        return jsonObject
    }
}
