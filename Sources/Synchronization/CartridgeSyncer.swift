////
////  CartridgeSyncer.swift
////  Pods
////
////  Created by Akash Desai on 7/22/16.
////
////
//
//import Foundation
//
//@objc
//class CartridgeSyncer : NSObject {
//    
//    private let cartridge: Cartridge
//    
//    private var syncInProgress = false
//    
//    init(actionID: String) {
//        cartridge = Cartridge.init(actionID: actionID)
//    }
//    
//    func sync(completion: (Int) -> () = { _ in }) {
//        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
//            guard !self.syncInProgress else {
//                DopamineKit.DebugLog("Reload already happening")
//                completion(200)
//                return
//            }
//            
//            self.syncInProgress = true
//            DopamineAPI.refresh(self.cartridge.actionID, completion: { response in
//                defer { self.syncInProgress = false }
//                if response["status"] as? Int == 200,
//                    let cartridgeValues = response["reinforcementCartridge"] as? [String],
//                    let expiry = response["expiresIn"] as? Int
//                {
//                    defer { completion(200) }
//                    
//                    SQLCartridgeDataHelper.deleteAll(cartridge.actionID)
//                    for decision in cartridgeValues {
//                        let _ = SQLCartridgeDataHelper.insert(
//                            SQLCartridge(
//                                index:0,
//                                actionID: cartridge.actionID,
//                                reinforcementDecision: decision)
//                        )
//                    }
//                    self.updateTriggerFor(cartridge, size: cartridgeValues.count, timerExpiresIn: Int64(expiry))
//                    
//                    DopamineKit.DebugLog("✅ \(cartridge.actionID) refreshed!")
//                }
//                else {
//                    DopamineKit.DebugLog("❌ Could not read cartridge for (\(cartridge.actionID))")
//                    completion(404)
//                }
//                
//            })
//        }
//    }
//    
//    func unload(actionID: String) -> String {
//        var decision = "neutralFeedback"
//        
//        let cartridge = getCartridgeForAction(actionID)
//        
//        if cartridge.isFresh() {
//            if let result = SQLCartridgeDataHelper.pop(actionID) {
//                decision = result.reinforcementDecision
//            }
//        }
//        
//        return decision
//    }
//    
//}
//
//
