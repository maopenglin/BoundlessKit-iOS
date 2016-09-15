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
    
    fileprivate let defaults = UserDefaults.standard
    fileprivate func defaultsKey() -> String { return "DopamineCartridgeSyncerFor" + self.actionID }
    fileprivate let defaultsActionID = "actionID"
    fileprivate let defaultsInitialSize = "initialSize"
    fileprivate let defaultsTimerStartsAt = "timerStartsAt"
    fileprivate let defaultsTimerExpiresIn = "timerExpiresIn"
    
    var actionID: String
    fileprivate var initialSize: Int = 0
    fileprivate var timerStartsAt: Int64 = 0
    fileprivate var timerExpiresIn: Int64 = 0
    fileprivate static let capacityToSync = 0.25
    fileprivate static let minimumSize = 2
    
    
    /// Loads a cartridge from NSUserDefaults or creates a new cartridge and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - actionID: The name of an action configured on the Dopamine Dashboard.
    ///     - initialSize: The cartridge size at full capacity.
    ///     - timerStartsAt: The start time for a sync timer.
    ///     - timerExpiresIn: The timer length for a sync timer.
    ///
    init(actionID: String, initialSize: Int=0, timerStartsAt: Int64 = 0, timerExpiresIn: Int64 = 0) {
        self.actionID = actionID
        super.init()
        if let savedCartridgeData = defaults.object(forKey: defaultsKey()) as? Data,
            let savedCartridge = NSKeyedUnarchiver.unarchiveObject(with: savedCartridgeData) as? Cartridge {
            self.initialSize = savedCartridge.initialSize
            self.timerStartsAt = savedCartridge.timerStartsAt
            self.timerExpiresIn = savedCartridge.timerExpiresIn
        } else {
            self.initialSize = initialSize;
            self.timerStartsAt = timerStartsAt;
            self.timerExpiresIn = timerExpiresIn;
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey())
        }
    }
    
    /// Decodes a saved cartridge from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.actionID = aDecoder.decodeObject(forKey: defaultsActionID) as! String
        self.initialSize = aDecoder.decodeInteger(forKey: defaultsInitialSize)
        self.timerStartsAt = aDecoder.decodeInt64(forKey: defaultsTimerStartsAt)
        self.timerExpiresIn = aDecoder.decodeInt64(forKey: defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Decoded cartridge for actionID:\(actionID) with initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a cartridge and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(actionID, forKey: defaultsActionID)
        aCoder.encode(initialSize, forKey: defaultsInitialSize)
        aCoder.encode(timerStartsAt, forKey: defaultsTimerStartsAt)
        aCoder.encode(timerExpiresIn, forKey: defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Encoded cartridge for actionID: \(actionID) with initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - initialSize: The cartridge size at full capacity.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length for a sync timer.
    ///
    func updateTriggers(_ initialSize: Int, timerStartsAt: Int64=Int64( 1000*Date().timeIntervalSince1970 ), timerExpiresIn: Int64) {
        self.initialSize = initialSize
        self.timerStartsAt = timerStartsAt
        self.timerExpiresIn = timerExpiresIn
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey())
    }
    
    /// Clears the saved cartridge from NSUserDefaults and resets triggers
    ///
    func resetTriggers() {
        self.initialSize = 0
        self.timerStartsAt = 0
        self.timerExpiresIn = 0
        defaults.removeObject(forKey: defaultsKey())
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
    fileprivate func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*Date().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
        DopamineKit.DebugLog("Cartridge \(actionID) expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
        return isExpired
    }
    
    /// Checks if the cartridge is at a size to sync
    ///
    fileprivate func isCapacityToSync() -> Bool {
        let count = SQLCartridgeDataHelper.countFor(actionID)
        let result = count < Cartridge.minimumSize || Double(count) / Double(initialSize) <= Cartridge.capacityToSync;
        DopamineKit.DebugLog("Cartridge for \(actionID) has \(count)/\(initialSize) decisions so \(result ? "does" : "doesn't") need to sync since a cartridge requires at least \(Cartridge.minimumSize) decisions or \(Cartridge.capacityToSync*100)%% capacity.")
        return result
    }
    
    /// Adds a reinforcement decision to the cartridge
    ///
    func add(_ reinforcementDecision: String) {
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
    
}
