//
//  DopeCartridge.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation



public class Cartridge{
    
    public var events = [DopeEvent]()
    
    var end:Int = 0
    let max:Int         // soft max. you can push more than max
    
    public init(size:Int = 100){
        max = size
    }
    
    public func pop() -> DopeEvent?{
        guard end > 0 else{
            DopamineKit.DebugLog("Cartridge empty (0\(max))")
            return nil
        }
        end--
        return events.popLast()
    }
    
    public func push(event:DopeEvent){
        events.append(event)
        end++
    }
    
    public func toJsonable() -> [AnyObject] {
        var eventArray:[AnyObject] = []
        
        for event in events{
            eventArray.append(event.toJsonable())
        }
        
        return eventArray
    }
    
}