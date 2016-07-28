//
//  CartridgeSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class CartridgeSyncer {
    
    private var mutex_lock:Int = 1
    
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
        let defaults = NSUserDefaults.standardUserDefaults()
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
    
    func reload() {
        if (mutex_lock > 0) {
            mutex_lock-=1
        } else {
            return
        }
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            DopamineKit.DebugLog("Beginning reload...")
            
            self.dispatch_async_delayed(1) {
                DopamineKit.DebugLog("Sending tracked actions...")
                TrackSyncer.sync()
                
                self.dispatch_async_delayed(1) {
                    DopamineKit.DebugLog("Sending reported actions...")
                    ReportSyncer.sync()
                    
                    self.dispatch_async_delayed(3) {
                        DopamineAPI.refresh(self.actionID, completion: {
                            response in
                            defer { self.mutex_lock+=1 }
                            if let cartridge = response["reinforcementCartridge"] as? [String],
                                expiry = response["expiresIn"] as? Int
                            {
                                SQLCartridgeDataHelper.dropTable(self.actionID)
                                SQLCartridgeDataHelper.createTable(self.actionID)
                                
                                TimeSyncer.reset(self.TimeSyncerKey + self.actionID, duration: expiry)
                                self.setCartridgeInitialSize(cartridge.count)
                                
                                for decision in cartridge {
                                    let rowId = SQLCartridgeDataHelper.insert(
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
                            }
                            
                        })
                    }
                }
            }
        }
    }
    
    func unload() -> String {
        var decision = "neutralFeedback"
        
        if mutex_lock > 0 && isFresh() {
                mutex_lock-=1
                if let rdSql = SQLCartridgeDataHelper.findFirst(actionID) {
                    decision = rdSql.reinforcementDecision
                    SQLCartridgeDataHelper.delete(rdSql)
                }
                mutex_lock+=1
        }
        
        if !isFresh() {
            self.reload()
        }

        return decision
    }
    
    func dispatch_async_delayed(seconds: Int64, queue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block: () -> ()) {
        dispatch_after(dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), seconds * Int64(NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block)
    }
    
}


