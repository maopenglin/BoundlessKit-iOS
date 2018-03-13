//
//  BoundlessKitClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation


internal class BoundlessKitDelegate : NSObject {
    
    
    
    
}
//
//extension BoundlessKitDelegate : BoundlessKitDelegateProtocol {
//    public func kitActionIDs() -> [String] {
//        return cartridgeReinforcements.keys
//    }
//    
//    public func kitReinforcement(for actionID: String) -> String {
//        
//        return cartridgeReinforcements[actionID]?.values ?? []
//    }
//    
//    @objc
//    public func kitPublish(actionInfo: [String : Any]) {
//        trackedActions.addAction(actionInfo: actionInfo)
//    }
//    
//    public func kitPublish(reinforcementInfo: [String : Any]) {
//        reportedActions.addReport(reinforcementInfo)
//    }
//}
//
//
//// MARK: - Data Storage
//extension BoundlessKitDelegate {
//    func loadData() {
//        if let savedTrack: [[String : Any]] = UserDefaults.boundless.unarchive(trackedActionsKey) {
//            trackedActions += savedTrack
//        }
//        if let savedReport: [[String : Any]] = UserDefaults.boundless.unarchive(reportedActionsKey) {
//            reportedActions += savedReport
//        }
//        if let savedCartridges: [String : [String]] = UserDefaults.boundless.unarchive(cartridgeReinforcementsKey) {
//            for (actionID, cartridge) in savedCartridges {
//                if cartridgeReinforcements[actionID] == nil { cartridgeReinforcements[actionID] = SynchronizedArray() }
//                cartridgeReinforcements[actionID]? += cartridge
//            }
//        }
//    }
//    
//    func saveData() {
//        
//        UserDefaults.boundless.archive(trackedActions.values, forKey: trackedActionsKey)
//        UserDefaults.boundless.archive(reportedActions.values, forKey: reportedActionsKey)
//        UserDefaults.boundless.archive(cartridgeReinforcements.flatMap({ (actionID, cartridge) -> (String, [String])? in
//            return (actionID, cartridge.values)
//        }), forKey: cartridgeReinforcementsKey)
//    }
//    
//    func clearData() {
//        UserDefaults.boundless.archive(nil, forKey: trackedActionsKey)
//        UserDefaults.boundless.archive(nil, forKey: reportedActionsKey)
//        UserDefaults.boundless.archive(nil, forKey: cartridgeReinforcementsKey)
//        trackedActions = SynchronizedArray()
//        reportedActions = SynchronizedArray()
//        cartridgeReinforcements = SynchronizedDictionary()
//    }
//}

