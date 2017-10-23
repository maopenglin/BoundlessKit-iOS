//
//  Track.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
internal class Track : NSObject, NSCoding {
    
    static let sharedInstance = Track()
    
    private let defaults = UserDefaults.standard
    private let defaultsKey = "DopamineTrack"
    private let trackedActionsKey = "trackedActions"
    private let sizeToSyncKey = "sizeToSync"
    private let timerStartsAtKey = "timerStartsAt"
    private let timerExpiresInKey = "timerExpiresIn"
    
    private var trackedActions: [DopeAction] = []
    private let trackedActionsQueue = OperationQueue()
    private var sizeToSync: Int
    private var timerStartsAt: Int64
    private var timerExpiresIn: Int64
    
    private var syncInProgress = false
    
    /// Loads the track from NSUserDefaults or creates a new one and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - sizeToSync: The number of tracked actions to trigger a sync. Defaults to 15.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    private init(sizeToSync: Int = 15, timerStartsAt: Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64 = 172800000) {
        if let savedTrackData = defaults.object(forKey: defaultsKey) as? NSData,
            let savedTrack = NSKeyedUnarchiver.unarchiveObject(with: savedTrackData as Data) as? Track {
            self.trackedActions = savedTrack.trackedActions
            self.sizeToSync = savedTrack.sizeToSync;
            self.timerStartsAt = savedTrack.timerStartsAt;
            self.timerExpiresIn = savedTrack.timerExpiresIn;
            super.init()
        } else {
            self.sizeToSync = sizeToSync;
            self.timerStartsAt = timerStartsAt;
            self.timerExpiresIn = timerExpiresIn;
            super.init()
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
        }
        trackedActionsQueue.maxConcurrentOperationCount = 1
    }
    
    /// Decodes a saved track from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.trackedActions = aDecoder.decodeObject(forKey: trackedActionsKey) as! [DopeAction]
        self.sizeToSync = aDecoder.decodeInteger(forKey: sizeToSyncKey)
        self.timerStartsAt = aDecoder.decodeInt64(forKey: timerStartsAtKey)
        self.timerExpiresIn = aDecoder.decodeInt64(forKey: timerExpiresInKey)
//        DopamineKit.debugLog("Decoded TrackSyncer with trackedActions:\(trackedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a track and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(trackedActions, forKey: trackedActionsKey)
        aCoder.encode(sizeToSync, forKey: sizeToSyncKey)
        aCoder.encode(timerStartsAt, forKey: timerStartsAtKey)
        aCoder.encode(timerExpiresIn, forKey: timerExpiresInKey)
//        DopamineKit.debugLog("Encoded TrackSyncer with trackedActions:\(trackedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - sizeToSync: The number of tracked actions to trigger a sync. Defaults to previous sizeToSync.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to previous timerExpiresIn.
    ///
    func updateTriggers(sizeToSync: Int?=nil, timerStartsAt: Int64?=Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64?=nil) {
        if let sizeToSync = sizeToSync {
            self.sizeToSync = sizeToSync
        }
        if let timerStartsAt = timerStartsAt {
            self.timerStartsAt = timerStartsAt
        }
        if let timerExpiresIn = timerExpiresIn {
            self.timerExpiresIn = timerExpiresIn
        }
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Clears the saved track sync triggers from NSUserDefaults
    ///
    func erase() {
        trackedActionsQueue.addOperation {
            self.trackedActions.removeAll()
            self.sizeToSync = 15
            self.timerStartsAt = Int64( 1000*NSDate().timeIntervalSince1970 )
            self.timerExpiresIn = 172800000
            self.defaults.removeObject(forKey: self.defaultsKey)
        }
    }
    
    /// Check whether the track has been triggered for a sync
    ///
    /// - returns: Whether a sync has been triggered.
    ///
    func isTriggered() -> Bool {
        return timerDidExpire() || isSizeToSync()
    }
    
    /// Checks if the sync timer has expired
    ///
    /// - returns: Whether the timer has expired.
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
//        DopamineKit.debugLog("Track timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so the timer \(isExpired ? "will" : "won't") trigger a sync...")
        return isExpired
    }
    
    /// Checks if the track is at the size to sync
    ///
    /// - returns: Whether there are enough tracked actions to trigger a sync.
    ///
    private func isSizeToSync() -> Bool {
        let count = trackedActions.count
        let isSize = count >= sizeToSync
//        DopamineKit.debugLog("Track has \(count)/\(sizeToSync) actions so the size \(isSize ? "will" : "won't") trigger a sync...")
        return isSize
    }
    
    /// Stores a tracked action to be synced over the DopamineAPI at a later time
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    func add(action: DopeAction) {
        trackedActionsQueue.addOperation {
            self.trackedActions.append(action)
            if self.trackedActionsQueue.operationCount == 1 {
                self.defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: self.defaultsKey)
            }
        }
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if there were no actions to sync.
    ///
    func sync(completion: @escaping (_ statusCode: Int) -> () = { _ in }) {
        DispatchQueue.global().async{
            guard !self.syncInProgress else {
                completion(0)
                return
            }
            self.syncInProgress = true
            DopamineKit.debugLog("Track sync in progress...")
            self.trackedActionsQueue.waitUntilAllOperationsAreFinished()
            self.trackedActionsQueue.isSuspended = true
            let syncFinished = {
                self.syncInProgress = false
                self.trackedActionsQueue.isSuspended = false
            }
            
            if self.trackedActions.count == 0 {
                defer { syncFinished() }
                DopamineKit.debugLog("No tracked actions to sync.")
                completion(0)
                self.updateTriggers()
                return
            } else {
                DopamineKit.debugLog("Sending \(self.trackedActions.count) tracked actions...")
                DopamineAPI.track(self.trackedActions) { response in
                    defer { syncFinished() }
                    if let responseStatusCode = response["status"] as? Int {
                        if responseStatusCode == 200 {
                            self.trackedActions.removeAll()
                            self.updateTriggers()
                        }
                        completion(responseStatusCode)
                    } else {
                        completion(404)
                    }
                }
            }
        }
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["size"] = NSNumber(value: trackedActions.count)
        jsonObject[sizeToSyncKey] = NSNumber(value: sizeToSync)
        jsonObject[timerStartsAtKey] = NSNumber(value: timerStartsAt)
        jsonObject[timerExpiresInKey] = NSNumber(value: timerExpiresIn)
        
        return jsonObject
    }
}
