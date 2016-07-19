//
//  DopeEvent.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation



public struct DopeAction{
    
    public var actionID:String?
    public var metaData:[String: AnyObject]?
    public var reinforcement:String?            // never created on init, case not encountered
    
    public var utc:Int64?
    public var timezoneOffset:Int64?
    
    
    public init(actionID:String?=nil, metaData:[String:AnyObject]?=nil, utc:Int64=Int64(1000*NSDate().timeIntervalSince1970), timezoneOffset:Int64=Int64(1000*NSTimeZone.defaultTimeZone().secondsFromGMT) )
    {
        self.actionID = actionID
        self.metaData = metaData
        self.utc = utc
        self.timezoneOffset = timezoneOffset
    }
    
//    public func toJsonable() -> [String:AnyObject]{
//        var dict:[String:AnyObject] = [:]
//        
//        if let actionID = actionID{
//            dict["actionID"] = actionID
//        }
//        if let metaData = metaData{
//            dict["metaData"] = metaData
//        }
//        if let reinforcement = reinforcement{
//            dict["reinforcement"] = reinforcement
//        }
//        
//        if let utc = utc{
//            dict["UTC"] = NSNumber(longLong: utc)
//        }
//        if let timezoneOffset = timezoneOffset{
//            dict["timezoneOffset"] = NSNumber(longLong: timezoneOffset)
//        }
//                
//        return dict
//    }
    
}