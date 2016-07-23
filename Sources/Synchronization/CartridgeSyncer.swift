//
//  CartridgeSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class CartridgeSyncer {
    
    private var lock:Int = 0
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let DefaultsKey = "DopamineCartridgeSyncer"
    private let TimeSyncerKey = "Cartridge"
    private let SizeKey = "InitialSize"
    
    private let actionID: String
    init(actionID: String) {
        self.actionID = actionID
        let defaults = NSUserDefaults.standardUserDefaults()
        let standardSize = 10
        if( defaults.valueForKey(DefaultsKey + actionID + SizeKey) == nil ){
            defaults.setValue(standardSize, forKey: DefaultsKey + actionID + SizeKey)
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
    
    func shouldReload() -> Bool {
        objc_sync_enter(lock)
        defer{ objc_sync_exit(lock) }
        
        return getCartridgeProgress() > 0.50
            || TimeSyncer.isExpired(TimeSyncerKey + actionID)
    }
    
    func reload() {
        objc_sync_enter(lock)
        
        DopamineAPI.refresh(actionID, completion: { response in
            // var cartridge = response["cartridge"] as? [String]
            // fake load
            var cartridge = [ "stars", "thumbsUp", "stars", "neutralFeedback", "neutralFeedback" ]
            
            SQLCartridgeDataHelper.dropTable(self.actionID)
            SQLCartridgeDataHelper.createTable(self.actionID)
            TimeSyncer.reset(self.TimeSyncerKey + self.actionID)
            self.setCartridgeInitialSize(cartridge.count)
            for decision in cartridge {
                guard let rowId = SQLCartridgeDataHelper.insert(
                    SQLCartridge(
                        index:0,
                        actionID: self.actionID,
                        reinforcementDecision: decision)
                    )
                    else{
                        DopamineKit.DebugLog("Couldn't add \(decision) to cartridge sql")
                        break
                }
            }
            
            DopamineKit.DebugLog("\(self.actionID) refreshed!")
            objc_sync_exit(self.lock)
        })
    }
    
    func pop() -> String {
        objc_sync_enter(lock)
        defer{ objc_sync_exit(lock) }
        
        var decision = "neutralFeedback"
        if let rdSql = SQLCartridgeDataHelper.findFirst(actionID) {
            decision = rdSql.reinforcementDecision
            SQLCartridgeDataHelper.delete(rdSql)
        }
        
        
        dispatch_async(dispatch_get_main_queue(), {
            if( self.shouldReload() ) {
                self.reload()
            }
        })
        
        
        return decision
        
    }
    
}
