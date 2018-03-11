//
//  ManualClient.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation


open class ManualClient : NSObject {
    
    let trackedActionsKey = "boundless.kit.manualclient.trackedactions"
    let reportedActionsKey = "boundless.kit.manualclient.reportedactions"
    let cartridgeReinforcementsKey = "boundless.kit.manualclient.cartridgereinforcements"
    
    open var trackedActions = SynchronizedArray<[String : Any]>()
    open var reportedActions = SynchronizedArray<[String : Any]>()
    open var cartridgeReinforcements = SynchronizedDictionary<String, SynchronizedArray<String>>()
    
    public override init() {
        super.init()
        loadData()
    }
    
    func loadData() {
        if let savedTrack: [[String : Any]] = UserDefaults.boundless.unarchive(trackedActionsKey) {
            trackedActions += savedTrack
        }
        if let savedReport: [[String : Any]] = UserDefaults.boundless.unarchive(reportedActionsKey) {
            reportedActions += savedReport
        }
        if let savedCartridges: [String : [String]] = UserDefaults.boundless.unarchive(cartridgeReinforcementsKey) {
            for (actionID, cartridge) in savedCartridges {
                if cartridgeReinforcements[actionID] == nil { cartridgeReinforcements[actionID] = SynchronizedArray() }
                cartridgeReinforcements[actionID]? += cartridge
            }
        }
    }
    
    func saveData() {
        UserDefaults.boundless.archive(trackedActions.filter({ _ in return true }), forKey: trackedActionsKey)
        UserDefaults.boundless.archive(reportedActions.filter({ _ in return true }), forKey: reportedActionsKey)
        UserDefaults.boundless.archive(cartridgeReinforcements.flatMap({ (actionID, cartridge) -> (String, [String])? in
            return (actionID, cartridge.filter({ _ in return true }))
        }), forKey: cartridgeReinforcementsKey)
    }
    
}

extension ManualClient : BoundlessKitDataSource, BoundlessKitDelegate {
    public func kitActions() -> [String] {
        return cartridgeReinforcements.keys
    }
    
    public func kitReinforcements(for actionID: String) -> [String] {
        return cartridgeReinforcements[actionID]?.filter({ _ in return true }) ?? []
    }
    
    @objc
    public func kitPublish(actionInfo: [String : Any]) {
        trackedActions += actionInfo
    }
    
    public func kitPublish(reinforcementInfo: [String : Any]) {
        reportedActions += reinforcementInfo
    }
    
    
}
