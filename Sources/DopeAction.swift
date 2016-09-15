//
//  DopeEvent.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

struct DopeAction {
    
    var actionID:String
    var reinforcementDecision:String?
    var metaData:[String: AnyObject]?
    var utc:Int64
    var timezoneOffset:Int64
    
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
    
    /// This function converts a DopeAction to a JSON compatible Object
    ///
    func toJSONType() -> AnyObject {
        var jsonObject: [String:AnyObject] = [:]
        
        jsonObject["actionID"] = self.actionID as AnyObject?
        jsonObject["reinforcementDecision"] = self.reinforcementDecision as AnyObject?
        jsonObject["metaData"] = self.metaData as AnyObject?
//        let timeArray = Array<String>()
        jsonObject["time"] = [
            ["timeType":"utc", "value": NSNumber(value: self.utc as Int64)],
            ["timeType":"deviceTimezoneOffset", "value": NSNumber(value: self.timezoneOffset as Int64)]
        ]  as AnyObject
        
        return jsonObject as AnyObject
    }
}
