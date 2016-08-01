//
//  CartridgeSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class CartridgeSyncer {
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let DefaultsKey = "DopamineCartridgeSyncer"
    private let TimeSyncerKey = "Cartridge"
    private let SizeKey = "InitialSize"
    
    private let actionID: String
    
    private static var cartridges: [String:CartridgeSyncer] = [:]
    
    static func forAction(actionID: String) -> CartridgeSyncer{
        if let cartridge = cartridges[actionID] {
            return cartridge
        } else {
            let cartridge = CartridgeSyncer(actionID: actionID)
            cartridges[actionID] = cartridge
            return cartridge
        }
    }
    
    private init(actionID: String) {
        self.actionID = actionID
        let standardSize = 10
        let key = DefaultsKey + actionID + SizeKey
        if( defaults.valueForKey(key) == nil ){
            defaults.setValue(standardSize, forKey: key)
        }
        TimeSyncer.create(TimeSyncerKey + actionID, ifNotExists: true)
    }
    
    func getCartridgeInitialSize() -> Int {
        return defaults.integerForKey(DefaultsKey + actionID + SizeKey)
    }
    
    func setCartridgeInitialSize(newSize: Int) {
        defaults.setValue(newSize, forKey: DefaultsKey + actionID + SizeKey)
    }
    
    func getCartridgeProgress() -> Double {
        return 1.0 - Double(SQLCartridgeDataHelper.count(actionID)) / Double(getCartridgeInitialSize() )
    }
    
    func isFresh() -> Bool {
        return
            SQLCartridgeDataHelper.count(actionID) > 1 &&
                !TimeSyncer.isExpired(TimeSyncerKey + actionID)
    }
    
    static func whichShouldReload() -> [CartridgeSyncer] {
        var needsReload:[CartridgeSyncer] = []
        
        for (name, cartirdge) in cartridges {
            if cartirdge.shouldReload() {
                needsReload.append(cartirdge)
            }
        }
        
        return needsReload
    }
    
    func shouldReload() -> Bool {
        return !reloadInProgress && (
            SQLCartridgeDataHelper.count(actionID) <= 5 ||
            TimeSyncer.isExpired(TimeSyncerKey + actionID)
        )
    }
    
    private var reloadInProgress = false
    func reload(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.reloadInProgress else {
                DopamineKit.DebugLog("Reload already happening for \(self.actionID)")
                completion(200)
                return
            }
            self.reloadInProgress = true
            
            DopamineAPI.refresh(self.actionID, completion: {
                response in
                defer { self.reloadInProgress = false }
                if response["status"] as? Int == 200,
                    let cartridge = response["reinforcementCartridge"] as? [String],
                    let expiry = response["expiresIn"] as? Int
                {
                    defer { completion(200) }
                    SQLCartridgeDataHelper.deleteAll(self.actionID)
                    TimeSyncer.reset(self.TimeSyncerKey + self.actionID, duration: expiry)
                    self.setCartridgeInitialSize(cartridge.count)
                    
                    for decision in cartridge {
                        let _ = SQLCartridgeDataHelper.insert(
                            SQLCartridge(
                                index:0,
                                actionID: self.actionID,
                                reinforcementDecision: decision)
                        )
                    }
                    DopamineKit.DebugLog("✅ \(self.actionID) refreshed!")
                }
                else {
                    DopamineKit.DebugLog("❌ Could not read cartridge for (\(self.actionID))")
                    completion(404)
                }
                
            })
        }
        
    }
    
    func unload() -> String {
        var decision = "neutralFeedback"
        
        if isFresh() {
            if let result = SQLCartridgeDataHelper.pop(actionID) {
                decision = result.reinforcementDecision
            }
        }
        
        SyncCoordinator.sync()
        
        return decision
    }
    
}


