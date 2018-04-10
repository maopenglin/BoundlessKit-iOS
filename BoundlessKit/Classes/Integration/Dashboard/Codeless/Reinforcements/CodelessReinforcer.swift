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
                self.reinforcements[reinforcementID]?.show(targetInstance: target, senderInstance: sender)
                BKLog.debug("showing reinforcementID <\(reinforcementID)> for actionID <\(actionID)>...")
            }
        case .random:
            guard let randomReinforcement = Array(self.reinforcements.values).randomElement else {
                BKLog.debug("no reinforcements for actionID <\(actionID)>")
                return
            }
            randomReinforcement.show(targetInstance: target, senderInstance: sender)
            BKLog.debug("randomly showing reinforcementID <\(randomReinforcement.primitive)> for actionID <\(actionID)>...")
        }
    }
    
}

