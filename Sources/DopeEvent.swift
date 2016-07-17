//
//  DopeEvent.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation



public struct DopeEvent{
    
    public var actionName:String?
    public var metaData:[String: AnyObject]?
    public var reinforcement:String?            // never created on init, no need
    
    public var UTC:Double?
    public var localTime:Double?
    
    public init(action: String? = nil, metaData: [String: AnyObject]? = nil, UTC:Double?=nil, localTime:Double?=nil)
    {
        self.actionName = action
        self.metaData = metaData
        self.UTC = UTC
        self.localTime = localTime
        
        if(UTC==nil){
            self.UTC = 1000*NSDate().timeIntervalSince1970
        }
        
        if(localTime==nil){
            self.localTime = self.UTC! + 1000*Double(NSTimeZone.defaultTimeZone().secondsFromGMT)
        }
        
    }
    
    public func toJsonable() -> [String:AnyObject]{
        var dict:[String:AnyObject] = [:]
        
        if let actionID = actionName{
            dict["actionID"] = actionName
        }
        if let metaData = metaData{
            dict["metaData"] = metaData
        }
        if let reinforcement = reinforcement{
            dict["reinforcement"] = reinforcement
        }
        
        if let UTC = UTC{
            dict["UTC"] = UTC
        }
        if let localTime = localTime{
            dict["localTime"] = localTime
        }
                
        return dict
    }
    
    
    
}