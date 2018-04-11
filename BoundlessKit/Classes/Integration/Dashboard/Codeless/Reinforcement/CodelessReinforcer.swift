//
//  CodelessReinforcer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class CodelessReinforcer : NSObject {
    
    enum ShowOption {
        case reinforcement, random
    }
    static var showOption: ShowOption = .reinforcement
    
    let actionID: String
    var reinforcements = [String: CodelessReinforcement]()
    
    init(forActionID actionID: String) {
        self.actionID = actionID
    }
    
    @objc
    func receive(notification: Notification) {
        let actionID = notification.name.rawValue
//        BKLog.print("Action peformed with actionID <\(actionID)>")
        guard let target = notification.userInfo?["target"] as? NSObject else { return }
        let sender = notification.userInfo?["sender"] as AnyObject?
        
        switch CodelessReinforcer.showOption {
        case .reinforcement:
            BoundlessKit.standard.reinforce(actionID: actionID) { reinforcementID in
                BKLog.debug("Showing codeless reinforcementID <\(reinforcementID)> for actionID <\(actionID)>...")
                self.reinforcements[reinforcementID]?.show(targetInstance: target, senderInstance: sender)
            }
        case .random:
            guard let randomReinforcement = Array(self.reinforcements.values).randomElement else {
                BKLog.print(error: "No reinforcements for actionID <\(actionID)>")
                return
            }
            BKLog.debug("Showing random codeless reinforcementID <\(randomReinforcement.primitive)> for actionID <\(actionID)>...")
            randomReinforcement.show(targetInstance: target, senderInstance: sender)
        }
    }
    
}

