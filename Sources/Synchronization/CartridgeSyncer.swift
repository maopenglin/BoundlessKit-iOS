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
    init(actionID: String) {
        self.actionID = actionID
        let defaults = NSUserDefaults.standardUserDefaults()
        let standardSize = 10
        if( defaults.valueForKey(DefaultsKey + actionID + SizeKey) == nil ){
            defaults.setValue(standardSize, forKey: DefaultsKey + actionID + SizeKey)
        }
        TimeSyncer.create(TimeSyncerKey + actionID, ifNotExists: true)
    }
    
    func getCartridgeSize() -> Int {
        return defaults.integerForKey(DefaultsKey + actionID + SizeKey)
    }
    
    func setCartridgeSize(newSize: Int) {
        defaults.setValue(newSize, forKey: DefaultsKey + actionID + SizeKey)
    }
    
    func shouldReload() -> Bool {
        if (
            Double(SQLCartridgeDataHelper.count(actionID)) <= getCartridgeCapacity() ||
                TimeSyncer.isExpired(TimeSyncerKey + actionID) )
        {
            return true
        } else {
            return false
        }
    }
    
    func getCartridgeCapacity() -> Double {
        return Double( SQLCartridgeDataHelper.count(actionID)) / Double(getCartridgeSize() )
    }
    
    func reload() {
        DopamineAPI.refresh(actionID, completion: { response in
            // var cartridge = response["cartridge"] as? [String]
            // fake load
            var cartridge = ["neutralFeedback", "stars", "neutralFeedback", "thumbsUp"]
            
            SQLCartridgeDataHelper.dropTable(self.actionID)
            SQLCartridgeDataHelper.createTable(self.actionID)
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
        })
    }
    
}
