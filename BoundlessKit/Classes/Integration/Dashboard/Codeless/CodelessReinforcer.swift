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
        print("Got notification:\(notification.debugDescription)")
        switch CodelessReinforcer.showOption {
        case .reinforcement:
            BoundlessKit.standard.reinforce(actionID: actionID) { reinforcementID in
                if let targetInstance = notification.object as? NSObject {
                    self.reinforcements[reinforcementID]?.show(targetInstance: targetInstance, senderInstance: notification.userInfo?["senderInstance"] as AnyObject)
                    print("showing reinforcement...")
                } else {
                    print("couldn't show reinforcement!")
                }
            }
        case .random:
            if let targetInstance = notification.object as? NSObject {
                Array(self.reinforcements.values).selectRandom()?.show(targetInstance: targetInstance, senderInstance: notification.userInfo?["senderInstance"] as AnyObject)
                BKLog.debug("showing random reinforcement...")
            } else {
                BKLog.debug("couldn't show reinforcement!")
            }
            break
        }
    }
    
}

