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
    
    private static let defaults = UserDefaults.standard
    private static let cartridgeActionIDSetKey = "DopamineReinforceableActionIDSet"
    private static func saveCartridgeActionIDsSet() { defaults.set(cartridgeSyncers.keys.sorted(), forKey: cartridgeActionIDSetKey) }
    
    internal static var cartridgeSyncers:[String:Cartridge] = {
        var cartridges:[String: Cartridge] = [:]
        if let savedActionIDSetData = defaults.object(forKey: cartridgeActionIDSetKey) as? [String] {
            for actionID in savedActionIDSetData {
                cartridges[actionID] = Cartridge(actionID: actionID)
            }
        }
        return cartridges
    }()
    
    internal static func flush() {
        for (_, cartridge) in cartridgeSyncers {
            cartridge.erase()
        }
        cartridgeSyncers.removeAll()
        saveCartridgeActionIDsSet()
    }
    
    internal static func flush(_ cartridge: Cartridge) {
        cartridge.erase()
        cartridgeSyncers.removeValue(forKey: cartridge.actionID)
        saveCartridgeActionIDsSet()
    }
    
    internal static func create(_ actionID: String) -> Cartridge {
        let cartridge = Cartridge(actionID: actionID)
        cartridgeSyncers[actionID] = cartridge
        saveCartridgeActionIDsSet()
        if cartridge.isTriggered() {
            Telemetry.startRecordingSync(cause: "Syncing newly created cartridge")
            cartridge.sync()
        }
        return cartridge
    }
    
    @objc public static var defaultReinforcementDecision = "neutralResponse"
    
    private let defaults = UserDefaults.standard
    private var defaultsKey: String { get { return "DopamineCartridgeSyncer_For_\(self.actionID)" } }
    
    @objc private let customerVersion: String?
    @objc let actionID: String
    @objc private var reinforcementDecisions: [String]
    @objc private var initialSize: Int = 0
    @objc private var timerStartsAt: Int64 = 0
    @objc private var timerExpiresIn: Int64 = 0
    @objc private static let capacityToSync = 0.25
    @objc private static let minimumSize = 2
    
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
        self.customerVersion = DopamineVersion.current.versionID
        self.actionID = actionID
        self.reinforcementDecisions = []
        super.init()
        if let savedCartridgeData = defaults.object(forKey: defaultsKey) as? Data {
            if let savedCartridge = NSKeyedUnarchiver.unarchiveObject(with: savedCartridgeData) as? Cartridge,
                savedCartridge.customerVersion == self.customerVersion {
                self.reinforcementDecisions = savedCartridge.reinforcementDecisions
                self.initialSize = savedCartridge.initialSize
                self.timerStartsAt = savedCartridge.timerStartsAt
                self.timerExpiresIn = savedCartridge.timerExpiresIn
                return
            } else {
                defaults.removeObject(forKey: defaultsKey)
//                DopeLog.debug("Erased outdated cartridge.")
            }
        }
        self.initialSize = initialSize
        self.timerStartsAt = timerStartsAt
        self.timerExpiresIn = timerExpiresIn
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Decodes a saved cartridge from NSUserDefaults
    ///
    required init?(coder aDecoder: NSCoder) {
        if let customerVersion = aDecoder.decodeObject(forKey: #keyPath(Cartridge.customerVersion)) as? String?,
            let actionID = aDecoder.decodeObject(forKey: #keyPath(Cartridge.actionID)) as? String,
            let reinforcementDecisions = aDecoder.decodeObject(forKey: #keyPath(Cartridge.reinforcementDecisions)) as? [String] {
            self.customerVersion = customerVersion
            self.actionID = actionID
            self.reinforcementDecisions = reinforcementDecisions
            self.initialSize = aDecoder.decodeInteger(forKey: #keyPath(Cartridge.initialSize))
            self.timerStartsAt = aDecoder.decodeInt64(forKey: #keyPath(Cartridge.timerStartsAt))
            self.timerExpiresIn = aDecoder.decodeInt64(forKey: #keyPath(Cartridge.timerExpiresIn))
//            DopeLog.debugLog("Decoded cartridge with actionID:\(actionID) reinforcementDecisions:\(reinforcementDecisions.count) initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
        } else {
            return nil
        }
    }
    
    /// Encodes a cartridge and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(customerVersion, forKey: #keyPath(Cartridge.customerVersion))
        aCoder.encode(actionID, forKey: #keyPath(Cartridge.actionID))
        aCoder.encode(reinforcementDecisions, forKey: #keyPath(Cartridge.reinforcementDecisions))
        aCoder.encode(initialSize, forKey: #keyPath(Cartridge.initialSize))
        aCoder.encode(timerStartsAt, forKey: #keyPath(Cartridge.timerStartsAt))
        aCoder.encode(timerExpiresIn, forKey: #keyPath(Cartridge.timerExpiresIn))
        //        DopeLog.debugLog("Encoded cartridge with actionID:\(actionID) reinforcementDecisions:\(reinforcementDecisions.count) initialSize:\(initialSize) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
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
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
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
        //        DopeLog.debugLog("Cartridge \(actionID) expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
        return isExpired
    }
    
    /// Checks if the cartridge is at a size to sync
    ///
    private func isCapacityToSync() -> Bool {
        let count = reinforcementDecisions.count
        let result = count < Cartridge.minimumSize || Double(count) / Double(initialSize) <= Cartridge.capacityToSync;
        //        DopeLog.debugLog("Cartridge for \(actionID) has \(count)/\(initialSize) decisions so \(result ? "does" : "doesn't") need to sync since a cartridge requires at least \(Cartridge.minimumSize) decisions or \(Cartridge.capacityToSync*100)%% capacity.")
        return result
    }
    
    /// Removes a reinforcement decision from the cartridge
    ///
    /// - returns: A fresh reinforcement decision if any are stored, else `neutralResponse`
    ///
    func remove() -> String {
        if isFresh() {
            let reinforcementDecision = reinforcementDecisions.removeFirst()
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
            return reinforcementDecision
        } else {
            return Cartridge.defaultReinforcementDecision
        }
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if the cartridge is already being synced by another thread.
    ///
    func sync(completion: @escaping (Int) -> () = { _ in }) {
        DispatchQueue.global().async{
            guard !self.syncInProgress else {
                completion(0)
                return
            }
            self.syncInProgress = true
            
            DopamineAPI.refresh(self.actionID) { response in
                defer { self.syncInProgress = false }
                if let responseStatusCode = response["status"] as? Int {
                    if responseStatusCode == 200,
                        let cartridgeDecisions = response["reinforcementCartridge"] as? [String],
                        let expiresIn = response["expiresIn"] as? Int
                    {
                        self.reinforcementDecisions = cartridgeDecisions
                        self.updateTriggers(initialSize: cartridgeDecisions.count, timerExpiresIn: Int64(expiresIn) )
//                        DopeLog.debug("✅ \(self.actionID) refreshed!")
                    } else if responseStatusCode == 400 {
//                        DopeLog.debug("Cartridge contained outdated actionID. Flushing.")
                        Cartridge.flush(self)
                    }
                    completion(responseStatusCode)
                } else {
                    DopeLog.debug("❌ Could not read cartridge for (\(self.actionID))")
                    completion(404)
                }
            }
        }
    }
    
    fileprivate func erase() {
        defaults.removeObject(forKey: defaultsKey)
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    func toJSONType() -> [String: Any] {
        return [
            "actionID" : actionID,
            "size" : reinforcementDecisions.count,
            "initialSize" : initialSize,
            "capacityToSync" : Cartridge.capacityToSync,
            "timerStartsAt" : NSNumber(value: timerStartsAt),
            "timerExpiresIn" : NSNumber(value: timerExpiresIn)
        ]
    }
    
}

