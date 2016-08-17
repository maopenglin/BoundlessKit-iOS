//
//  CartridgeSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

@objc
class CartridgeSyncer : NSObject {
    
    static let sharedInstance = CartridgeSyncer()
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let defaultsKey = "DopamineCartridgeSyncer"
    
    private var cartridges: [String:Cartridge] = [:]
    
    private override init() {
        if let savedCartridgesData = defaults.objectForKey(defaultsKey) as? NSData {
            let savedCartridges = NSKeyedUnarchiver.unarchiveObjectWithData(savedCartridgesData) as! [String:Cartridge]
            cartridges = savedCartridges
        } else {
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(cartridges), forKey: defaultsKey)
        }
    }
    
    func getCartridgeForAction(actionID: String) -> Cartridge {
        if let cartridge = cartridges[actionID] {
            return cartridge
        } else {
            // adding a cartridge to the dictionary
            let newCartridge = Cartridge(actionID: actionID)
            cartridges[actionID] = newCartridge
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(cartridges), forKey: defaultsKey)
            return newCartridge
        }
    }
    
    private func updateTriggerFor(cartridge: Cartridge, size: Int?, timerMarker: Int64=Int64( 1000*NSDate().timeIntervalSince1970 ), timerLength: Int64?) {
        if let size = size {
            cartridge.size = size
        }
        cartridge.timerMarker = timerMarker
        if let timerLength = timerLength {
            cartridge.timerLength = timerLength
        }
        cartridges[cartridge.actionID] = cartridge
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(cartridges), forKey: defaultsKey)
    }
    
    private var syncInProgress = false
    
    func shouldSync(actionID: String, cartridge: Cartridge) -> Bool {
        return !syncInProgress && cartridge.shouldSync()
    }
    
    func whichShouldSync() -> [String:Cartridge] {
        var needsReload:[String:Cartridge] = [:]
        
        for (actionID, cartridge) in cartridges {
            if shouldSync(actionID, cartridge: cartridge) {
                needsReload[actionID] = cartridge
            }
        }
        
        return needsReload
    }
    
    func sync(cartridge: Cartridge, completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Reload already happening")
                completion(200)
                return
            }
            self.syncInProgress = true
            
            DopamineAPI.refresh(cartridge.actionID, completion: {
                response in
                defer { self.syncInProgress = false }
                if response["status"] as? Int == 200,
                    let cartridgeValues = response["reinforcementCartridge"] as? [String],
                    let expiry = response["expiresIn"] as? Int
                {
                    defer { completion(200) }
                    SQLCartridgeDataHelper.deleteAll(cartridge.actionID)
                    self.updateTriggerFor(cartridge, size: cartridgeValues.count, timerLength: Int64(expiry))
                    
                    for decision in cartridgeValues {
                        let _ = SQLCartridgeDataHelper.insert(
                            SQLCartridge(
                                index:0,
                                actionID: cartridge.actionID,
                                reinforcementDecision: decision)
                        )
                    }
                    DopamineKit.DebugLog("✅ \(cartridge.actionID) refreshed!")
                }
                else {
                    DopamineKit.DebugLog("❌ Could not read cartridge for (\(cartridge.actionID))")
                    completion(404)
                }
                
            })
        }
    }
    
    func unload(actionID: String) -> String {
        var decision = "neutralFeedback"
        
        let cartridge = getCartridgeForAction(actionID)
        
        if cartridge.isFresh() {
            if let result = SQLCartridgeDataHelper.pop(actionID) {
                decision = result.reinforcementDecision
            }
        }
        
        return decision
    }
    
}


