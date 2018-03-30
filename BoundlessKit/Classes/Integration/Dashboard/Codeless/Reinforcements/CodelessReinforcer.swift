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
        print("Got notification:\(notification.name.rawValue)")
        let actionID = notification.name.rawValue
        guard let target = notification.userInfo?["target"] as? NSObject else { return }
        let sender = notification.userInfo?["sender"] as AnyObject?
        
        switch CodelessReinforcer.showOption {
        case .reinforcement:
            BoundlessKit.standard.reinforce(actionID: actionID) { reinforcementID in
                self.reinforcements[reinforcementID]?.show(targetInstance: target, senderInstance: sender)
                print("showing reinforcement for \(actionID)...")
            }
        case .random:
            guard let randomReinforcement = Array(self.reinforcements.values).randomElement else {
                BKLog.debug("no reinforcements for \(actionID)")
                return
            }
            randomReinforcement.show(targetInstance: target, senderInstance: sender)
            BKLog.debug("showing random reinforcement for \(actionID)...")
        }
    }
    
}

