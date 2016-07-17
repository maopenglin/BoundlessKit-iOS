//
//  DecisionEngine.swift
//  Pods
//
//  Created by Akash Desai on 7/15/16.
//
//

import Foundation


internal class DecisionEngine : NSObject{
    private var reinforcementDecisions:Cartridge = Cartridge()
    
    static let instance: DecisionEngine = DecisionEngine()
    private override init() {
        super.init()
    }
    
    
    var trackingCartridge = Cartridge()
    static func trackEvent(event: DopeEvent){
//        SQLStorage.writeTrack(event)
        
        DopeAPIPortal.track(event)
    }
    
    static func reinforceEvent(inout event: DopeEvent) -> String{
        // get from cartridge else neutralFeedback
        if let predictedEvent = instance.reinforcementDecisions.pop()
        {
            event.reinforcement = predictedEvent.reinforcement
        } else {
            event.reinforcement = "neutralFeedback"
        }
        
        
        // <async>
        DopeAPIPortal.report(event)
        // </async>
        
        return event.reinforcement!
    }
    
    
    

    
}