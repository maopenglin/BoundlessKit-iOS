////
////  Cartridge.swift
////  Pods
////
////  Created by Akash Desai on 8/1/16.
////
////
//
//import Foundation
//
//@objc
//class Cartridge : NSObject, NSCoding {
//    
//    private let defaults = NSUserDefaults.standardUserDefaults()
//    private func defaultsKey() -> String { return "DopamineCartridgeSyncerFor" + self.actionID }
//    private let defaultsActionID = "actionID"
//    private let defaultsInitialSize = "initialSize"
//    private let defaultsTimerStartsAt = "timerStartsAt"
//    private let defaultsTimerExpiresIn = "timerExpiresIn"
//    
//    var actionID: String
//    private var initialSize: Int
//    private var timerStartsAt: Int64
//    private var timerExpiresIn: Int64
//    private static let capacityToSync = 0.25
//    private static let minimumSize = 2
//    
//    init(actionID: String, initialSize: Int=0, timerStartsAt: Int64 = 0, timerExpiresIn: Int64 = 0) {
//        self.actionID = actionID
//        if let savedCartridgeData = defaults.objectForKey(defaultsKey()) as? NSData,
//            let savedCartridge = NSKeyedUnarchiver.unarchiveObjectWithData(savedCartridgeData) as? Cartridge {
//            self.initialSize = savedCartridge.initialSize
//            self.timerStartsAt = savedCartridge.timerStartsAt
//            self.timerExpiresIn = savedCartridge.timerExpiresIn
//            super.init()
//        } else {
//            self.initialSize = initialSize;
//            self.timerStartsAt = timerStartsAt;
//            self.timerExpiresIn = timerExpiresIn;
//            super.init()
//            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey())
//        }
//    }
//    
//    required init(coder aDecoder: NSCoder) {
//        self.actionID = aDecoder.decodeObjectForKey(defaultsActionID) as! String
//        self.initialSize = aDecoder.decodeIntegerForKey(defaultsInitialSize)
//        self.timerStartsAt = aDecoder.decodeInt64ForKey(defaultsTimerStartsAt)
//        self.timerExpiresIn = aDecoder.decodeInt64ForKey(defaultsTimerExpiresIn)
//        DopamineKit.DebugLog("Decoded cartridge for actionID:\(actionID) with initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
//    }
//    
//    func encodeWithCoder(aCoder: NSCoder) {
//        aCoder.encodeObject(actionID, forKey: defaultsActionID)
//        aCoder.encodeInteger(initialSize, forKey: defaultsInitialSize)
//        aCoder.encodeInt64(timerStartsAt, forKey: defaultsTimerStartsAt)
//        aCoder.encodeInt64(timerExpiresIn, forKey: defaultsTimerExpiresIn)
//        DopamineKit.DebugLog("Encoded cartridge for actionID: \(actionID) with initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
//    }
//    
//    func isTriggered() -> Bool {
//        return timerDidExpire() || isCapacityToSync()
//    }
//    
//    func isFresh() -> Bool {
//        return !timerDidExpire() && SQLCartridgeDataHelper.count(actionID) >= 1
//    }
//
//    private func timerDidExpire() -> Bool {
//        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
//        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
//        DopamineKit.DebugLog("Cartridge \(actionID) expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
//        return isExpired
//    }
//    
//    private func isCapacityToSync() -> Bool {
//        let count = SQLCartridgeDataHelper.count(actionID)
//        let result = count < Cartridge.minimumSize || Double(count) / Double(initialSize) <= Cartridge.capacityToSync;
//        DopamineKit.DebugLog("Cartridge for \(actionID) has \(count)/\(initialSize) decisions so \(result ? "does" : "doesn't") need to sync since a cartridge requires at least \(Cartridge.minimumSize) decisions or \(Cartridge.capacityToSync*100)%% capacity.")
//        return result
//    }
//    
//    func add(reinforcementDecision: String) {
//        let _ = SQLCartridgeDataHelper.insert(
//            SQLCartridge(
//                index:0,
//                actionID: actionID,
//                reinforcementDecision: reinforcementDecision)
//        )
//    }
//    
//}