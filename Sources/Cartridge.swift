//
//  DopeCartridge.swift
//  Pods
//
//  Created by Akash Desai on 7/16/16.
//
//

import Foundation



public class Cartridge{
    
    public var events = [DopeAction]()
    
    var end:Int = -1
    let max:Int         // soft max. you can push more than max
    
    public init(size:Int = 100){
        max = size
    }
    
    public func pop() -> DopeAction?{
        guard end > -1 else{
            DopamineKit.DebugLog("Cartridge empty (0\(max))")
            return nil
        }
        end-=1
        return events.popLast()
    }
    
    public func push(event:DopeAction){
        events.append(event)
        end+=1
    }
    
    public func toJsonable() -> [AnyObject] {
        var eventArray:[AnyObject] = []
        
//        for event in events{
//            eventArray.append(event.toJsonable())
//        }
        
        return eventArray
    }
    
}