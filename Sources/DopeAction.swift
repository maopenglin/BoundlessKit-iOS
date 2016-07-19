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
    public var reinforcement:String?
    public var utc:Int64?
    public var timezoneOffset:Int64?
    
    public init(actionID:String?=nil,
                reinforcement:String?=nil,
                metaData:[String:AnyObject]?=nil,
                utc:Int64=Int64(1000*NSDate().timeIntervalSince1970),
                timezoneOffset:Int64=Int64(1000*NSTimeZone.defaultTimeZone().secondsFromGMT))
    {
        self.actionID = actionID
        self.reinforcement = reinforcement      // never created on init(), always added on reinforce()
        self.metaData = metaData
        self.utc = utc
        self.timezoneOffset = timezoneOffset
    }
    
}