//
//  Cartridge.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
internal class Cartridge : NSObject, NSCoding {
    
    private let defaults = UserDefaults.standard
    private func defaultsKey() -> String { return "DopamineCartridgeSyncer_v4.1.3_For" + self.actionID }
    private let actionIDKey = "actionID"
    private let reinforcementDecisionsKey = "reinforcementDecisions"
    private let initialSizeKey = "initialSize"
    private let timerStartsAtKey = "timerStartsAt"
    private let timerExpiresInKey = "timerExpiresIn"
    
    let actionID: String
    private var reinforcementDecisions: [String] = []
    private var initialSize: Int = 0
    private var timerStartsAt: Int64 = 0
    private var timerExpiresIn: Int64 = 0
    private static let capacityToSync = 0.25
    private static let minimumSize = 2
    
    private var syncInProgress = false
    
    /// Returns the actionID associated with this cartridge
    ///
//    func actionName() -> String { return actionID }
    
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
        if let savedCartridgeData = defaults.object(forKey: defaultsKey()) as? NSData,
            let savedCartridge = NSKeyedUnarchiver.unarchiveObject(with: savedCartridgeData as Data) as? Cartridge {
            self.reinforcementDecisions = savedCartridge.reinforcementDecisions
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
        self.actionID = aDecoder.decodeObject(forKey: actionIDKey) as! String
        self.reinforcementDecisions = aDecoder.decodeObject(forKey: reinforcementDecisionsKey) as! [String]
        self.initialSize = aDecoder.decodeInteger(forKey: initialSizeKey)
        self.timerStartsAt = aDecoder.decodeInt64(forKey: timerStartsAtKey)
        self.timerExpiresIn = aDecoder.decodeInt64(forKey: timerExpiresInKey)
        DopamineKit.debugLog("Decoded cartridge with actionID:\(actionID) reinforcementDecisions:\(reinforcementDecisions.count) initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a cartridge and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(actionID, forKey: actionIDKey)
        aCoder.encode(reinforcementDecisions, forKey: reinforcementDecisionsKey)
        aCoder.encode(initialSize, forKey: initialSizeKey)
        aCoder.encode(timerStartsAt, forKey: timerStartsAtKey)
        aCoder.encode(timerExpiresIn, forKey: timerExpiresInKey)
        DopamineKit.debugLog("Encoded cartridge with actionID:\(actionID) reinforcementDecisions:\(reinforcementDecisions.count) initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - initialSize: The cartridge size at full capacity.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length for a sync timer.
    ///
    private func updateTriggers(initialSize: Int, timerStartsAt: Int64=Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64) {
        self.initialSize = initialSize
        self.timerStartsAt = timerStartsAt
        self.timerExpiresIn = timerExpiresIn
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey())
    }
    
    /// Clears the saved reinforcement decisions and sync triggers from NSUserDefaults
    ///
    func erase() {
        self.reinforcementDecisions.removeAll()
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
    private func isFresh() -> Bool {
        return !timerDidExpire() && reinforcementDecisions.count >= 1
    }

    /// Checks if the sync timer has expired
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
        DopamineKit.debugLog("Cartridge \(actionID) expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
        return isExpired
    }
    
    /// Checks if the cartridge is at a size to sync
    ///
    private func isCapacityToSync() -> Bool {
        let count = reinforcementDecisions.count
        let result = count < Cartridge.minimumSize || Double(count) / Double(initialSize) <= Cartridge.capacityToSync;
        DopamineKit.debugLog("Cartridge for \(actionID) has \(count)/\(initialSize) decisions so \(result ? "does" : "doesn't") need to sync since a cartridge requires at least \(Cartridge.minimumSize) decisions or \(Cartridge.capacityToSync*100)%% capacity.")
        return result
    }
    
    /// Adds a reinforcement decision to the cartridge
    ///
    func add(reinforcementDecision: String) {
        reinforcementDecisions.append(reinforcementDecision)
    }
    
    /// Removes a reinforcement decision from the cartridge
    ///
    /// - returns: A fresh reinforcement decision if any are stored, else `neutralResponse`
    ///
    func remove() -> String {
        if isFresh() {
            let reinforcementDecision = reinforcementDecisions.removeFirst()
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey())
            return reinforcementDecision
        } else {
            return "neutralResponse"
        }
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if the cartridge is already being synced by another thread.
    ///
    func sync(completion: @escaping (Int) -> () = { _ in }) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
            guard !self.syncInProgress else {
                DopamineKit.debugLog("Cartridge sync for \(self.actionID) already happening")
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
                        self.reinforcementDecisions = cartridgeDecisions
                        self.updateTriggers(initialSize: cartridgeDecisions.count, timerExpiresIn: Int64(expiresIn) )
                        DopamineKit.debugLog("✅ \(self.actionID) refreshed!")
                    }
                } else {
                    DopamineKit.debugLog("❌ Could not read cartridge for (\(self.actionID))")
                    completion(404)
                }
            }
        }
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    func toJSONType() -> [String: Any] {
        return [
            actionIDKey : actionID,
            "size" : reinforcementDecisions.count,
            initialSizeKey : initialSize,
            "capacityToSync" : Cartridge.capacityToSync,
            timerStartsAtKey : NSNumber(value: timerStartsAt),
            timerExpiresInKey : NSNumber(value: timerExpiresIn)
        ]
    }
    
}
