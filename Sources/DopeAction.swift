//
//  DopeEvent.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation

public struct DopeAction {
    
    public var actionID:String
    public var reinforcementDecision:String?
    public var metaData:[String: AnyObject]?
    public var utc:Int64
    public var deviceTimezoneOffset:Int64
    
    public init(actionID:String,
                reinforcementDecision:String? = nil,
                metaData:[String:AnyObject]? = nil,
                utc:Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ),
                deviceTimezoneOffset:Int64 = Int64( 1000*NSTimeZone.defaultTimeZone().secondsFromGMT ))
    {
        self.actionID = actionID
        self.reinforcementDecision = reinforcementDecision
        self.metaData = metaData
        self.utc = utc
        self.deviceTimezoneOffset = deviceTimezoneOffset
    }
    
    public func toJSONType() -> AnyObject {
        var dict: [String:AnyObject] = [:]
        
        dict["actionID"] = self.actionID
        dict["metaData"] = self.metaData
        dict["reinforcementDecision"] = self.reinforcementDecision
        dict["time"] = [
            ["timeType":"utc", "value": NSNumber( longLong:self.utc )],
            ["timeType":"deviceTimezoneOffset", "value": NSNumber( longLong:self.deviceTimezoneOffset )]
        ]
        
        return dict
    }
}