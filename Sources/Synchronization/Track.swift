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
    private init(sizeToSync: Int = 15, timerStartsAt: Int64 = 0, timerExpiresIn: Int64 = 172800000) {
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
    }
    
    /// Decodes a saved track from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.trackedActions = aDecoder.decodeObject(forKey: trackedActionsKey) as! [DopeAction]
        self.sizeToSync = aDecoder.decodeInteger(forKey: sizeToSyncKey)
        self.timerStartsAt = aDecoder.decodeInt64(forKey: timerStartsAtKey)
        self.timerExpiresIn = aDecoder.decodeInt64(forKey: timerExpiresInKey)
        DopamineKit.DebugLog("Decoded TrackSyncer with trackedActions:\(trackedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a track and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(trackedActions, forKey: trackedActionsKey)
        aCoder.encode(sizeToSync, forKey: sizeToSyncKey)
        aCoder.encode(timerStartsAt, forKey: timerStartsAtKey)
        aCoder.encode(timerExpiresIn, forKey: timerExpiresInKey)
        DopamineKit.DebugLog("Encoded TrackSyncer with trackedActions:\(trackedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
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
        self.trackedActions.removeAll()
        self.sizeToSync = 15
        self.timerStartsAt = 0
        self.timerExpiresIn = 0
        defaults.removeObject(forKey: defaultsKey)
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
        DopamineKit.DebugLog("Track timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so the timer \(isExpired ? "will" : "won't") trigger a sync...")
        return isExpired
    }
    
    /// Checks if the track is at the size to sync
    ///
    /// - returns: Whether there are enough tracked actions to trigger a sync.
    ///
    private func isSizeToSync() -> Bool {
        let count = trackedActions.count
        let isSize = count >= sizeToSync
        DopamineKit.DebugLog("Track has \(count)/\(sizeToSync) actions so the size \(isSize ? "will" : "won't") trigger a sync...")
        return isSize
    }
    
    /// Stores a tracked action to be synced over the DopamineAPI at a later time
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    func add(action: DopeAction) {
        trackedActions.append(action)
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if there were no actions to sync.
    ///
    func sync(completion: @escaping (_ statusCode: Int) -> () = { _ in }) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Track sync already happening")
                completion(0)
                return
            }
            self.syncInProgress = true
            
            if self.trackedActions.count == 0 {
                defer { self.syncInProgress = false }
                DopamineKit.DebugLog("No tracked actions to sync.")
                completion(0)
                self.updateTriggers()
                return
            } else {
                DopamineKit.DebugLog("Sending \(self.trackedActions.count) tracked actions...")
                DopamineAPI.track(self.trackedActions) { response in
                    defer { self.syncInProgress = false }
                    if let responseStatusCode = response["status"] as? Int {
                        completion(responseStatusCode)
                        if responseStatusCode == 200 {
                            self.trackedActions.removeAll()
                            self.updateTriggers()
                        }
                    } else {
                        completion(404)
                    }
                }
            }
        }
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    func toJSONType() -> AnyObject {
        var jsonObject: [String:AnyObject] = [:]
        
        jsonObject["size"] = NSNumber(value: trackedActions.count) as AnyObject
        jsonObject[sizeToSyncKey] = NSNumber(value: sizeToSync) as AnyObject
        jsonObject[timerStartsAtKey] = NSNumber(value: timerStartsAt) as AnyObject
        jsonObject[timerExpiresInKey] = NSNumber(value: timerExpiresIn) as AnyObject
        
        return jsonObject as AnyObject
    }
}
