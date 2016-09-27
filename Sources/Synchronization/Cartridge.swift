//
//  Cartridge.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
class Cartridge : NSObject, NSCoding {
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private func defaultsKey() -> String { return "DopamineCartridgeSyncerFor" + self.actionID }
    
    private static let actionIDKey = "actionID"
    private static let initialSizeKey = "initialSize"
    private static let sizeKey = "size"
    private static let capacityToSyncKey = "capacityToSync"
    private static let timerStartsAtKey = "timerStartsAt"
    private static let timerExpiresInKey = "timerExpiresIn"
    
    var actionID: String
    private var initialSize: Int
    private var timerStartsAt: Int64
    private var timerExpiresIn: Int64
    private static let capacityToSync = 0.25
    private static let minimumSize = 2
    
    private var syncInProgress = false
    
    /// Loads a cartridge from NSUserDefaults or creates a new cartridge and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - actionID: The name of an action configured on the Dopamine Dashboard.
    ///
    init(actionID: String) {
        self.actionID = actionID
        self.initialSize = 0
        self.timerStartsAt = 0 // set to 0 to force sync if new
        self.timerExpiresIn = 0
        super.init()
        if let savedCartridgeData = defaults.objectForKey(defaultsKey()) as? NSData,
            let savedCartridge = NSKeyedUnarchiver.unarchiveObjectWithData(savedCartridgeData) as? Cartridge {
            self.initialSize = savedCartridge.initialSize
            self.timerStartsAt = savedCartridge.timerStartsAt
            self.timerExpiresIn = savedCartridge.timerExpiresIn
        } else {
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey())
        }
    }
    
    /// Decodes a saved cartridge from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.actionID = aDecoder.decodeObjectForKey(Cartridge.actionIDKey) as! String
        self.initialSize = aDecoder.decodeIntegerForKey(Cartridge.initialSizeKey)
        self.timerStartsAt = aDecoder.decodeInt64ForKey(Cartridge.timerStartsAtKey)
        self.timerExpiresIn = aDecoder.decodeInt64ForKey(Cartridge.timerExpiresInKey)
        DopamineKit.DebugLog("Decoded cartridge for actionID:\(actionID) with initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a cartridge and saves it to NSUserDefaults
    ///
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(actionID, forKey: Cartridge.actionIDKey)
        aCoder.encodeInteger(initialSize, forKey: Cartridge.initialSizeKey)
        aCoder.encodeInt64(timerStartsAt, forKey: Cartridge.timerStartsAtKey)
        aCoder.encodeInt64(timerExpiresIn, forKey: Cartridge.timerExpiresInKey)
        DopamineKit.DebugLog("Encoded cartridge for actionID: \(actionID) with initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Returns a JSON compatible object of the sync triggers
    ///
    func decodeJSONForTriggers() -> [String: AnyObject]{
        return [
            Cartridge.actionIDKey : actionID,
            Cartridge.sizeKey : SQLCartridgeDataHelper.countFor(actionID),
            Cartridge.initialSizeKey : initialSize,
            Cartridge.capacityToSyncKey : Cartridge.capacityToSync,
            Cartridge.timerStartsAtKey : NSNumber(longLong: timerStartsAt),
            Cartridge.timerExpiresInKey : NSNumber(longLong: timerExpiresIn)
        ]
    }
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - initialSize: The cartridge size at full capacity.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length for a sync timer.
    ///
    func updateTriggers(initialSize: Int, timerStartsAt: Int64=Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64) {
        self.initialSize = initialSize
        self.timerStartsAt = timerStartsAt
        self.timerExpiresIn = timerExpiresIn
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey())
    }
    
    /// Clears the saved cartridge sync triggers from NSUserDefaults
    ///
    func removeTriggers() {
        self.initialSize = 0
        self.timerStartsAt = 0
        self.timerExpiresIn = 0
        defaults.removeObjectForKey(defaultsKey())
    }
    
    /// Returns whether the cartridge has been triggered for a sync
    ///
    func isTriggered() -> Bool {
        return timerDidExpire() || isCapacityToSync()
    }
    
    /// Returns whether the cartridge has any reinforcement decisions to give
    ///
    func isFresh() -> Bool {
        return !timerDidExpire() && SQLCartridgeDataHelper.countFor(actionID) >= 1
    }

    /// Checks if the sync timer has expired
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
        DopamineKit.DebugLog("Cartridge \(actionID) expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
        return isExpired
    }
    
    /// Checks if the cartridge is at a size to sync
    ///
    private func isCapacityToSync() -> Bool {
        let count = SQLCartridgeDataHelper.countFor(actionID)
        let result = count < Cartridge.minimumSize || Double(count) / Double(initialSize) <= Cartridge.capacityToSync;
        DopamineKit.DebugLog("Cartridge for \(actionID) has \(count)/\(initialSize) decisions so \(result ? "does" : "doesn't") need to sync since a cartridge requires at least \(Cartridge.minimumSize) decisions or \(Cartridge.capacityToSync*100)%% capacity.")
        return result
    }
    
    /// Adds a reinforcement decision to the cartridge
    ///
    func add(reinforcementDecision: String) {
        let _ = SQLCartridgeDataHelper.insert(
            SQLCartridge(
                index:0,
                actionID: actionID,
                reinforcementDecision: reinforcementDecision)
        )
    }
    
    /// Removes a reinforcement decision from the cartridge
    ///
    /// - returns: A fresh reinforcement decision if any are stored, else `neutralResponse`
    ///
    func remove() -> String {
        var decision = "neutralResponse"
        
        if isFresh(),
            let result = SQLCartridgeDataHelper.findFirstFor(actionID) {
            decision = result.reinforcementDecision
            SQLCartridgeDataHelper.delete(result)
        }
        
        return decision
    }
    
    /// Empties the entire cartridge
    ///
    func removeAll() {
        SQLCartridgeDataHelper.deleteAllFor(actionID)
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if the cartridge is already being synced by another thread.
    ///
    func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Cartridge sync for \(self.actionID) already happening")
                completion(0)
                return
            }
            self.syncInProgress = true
            
            DopamineAPI.refresh(self.actionID) { response in
                defer { self.syncInProgress = false }
                if let responseStatusCode = response["status"] as? Int,
                    let cartridgeDecisions = response["reinforcementCartridge"] as? [String],
                    let expiresIn = response["expiresIn"] as? Int
                {
                    completion(responseStatusCode)
                    if responseStatusCode == 200 {
                        self.removeAll()
                        for decision in cartridgeDecisions {
                            self.add(decision)
                        }
                        self.updateTriggers(cartridgeDecisions.count, timerExpiresIn: Int64(expiresIn) )
                        DopamineKit.DebugLog("✅ \(self.actionID) refreshed!")
                    }
                } else {
                    DopamineKit.DebugLog("❌ Could not read cartridge for (\(self.actionID))")
                    completion(404)
                }
            }
        }
    }
    
}
