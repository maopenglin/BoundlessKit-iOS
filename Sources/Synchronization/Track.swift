//
//  Track.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
class Track : NSObject, NSCoding {
    
    static let sharedInstance = Track()
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let defaultsKey = "DopamineTrack"
    private let defaultsSizeToSync = "sizeToSync"
    private let defaultsTimerStartsAt = "timerStartsAt"
    private let defaultsTimerExpiresIn = "timerExpiresIn"
    
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
        if let savedTrackData = defaults.objectForKey(defaultsKey) as? NSData,
            let savedTrack = NSKeyedUnarchiver.unarchiveObjectWithData(savedTrackData) as? Track {
            self.sizeToSync = savedTrack.sizeToSync;
            self.timerStartsAt = savedTrack.timerStartsAt;
            self.timerExpiresIn = savedTrack.timerExpiresIn;
            super.init()
        } else {
            self.sizeToSync = sizeToSync;
            self.timerStartsAt = timerStartsAt;
            self.timerExpiresIn = timerExpiresIn;
            super.init()
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
        }
    }
    
    /// Decodes a saved track from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.sizeToSync = aDecoder.decodeIntegerForKey(defaultsSizeToSync)
        self.timerStartsAt = aDecoder.decodeInt64ForKey(defaultsTimerStartsAt)
        self.timerExpiresIn = aDecoder.decodeInt64ForKey(defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Decoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a track and saves it to NSUserDefaults
    ///
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(sizeToSync, forKey: defaultsSizeToSync)
        aCoder.encodeInt64(timerStartsAt, forKey: defaultsTimerStartsAt)
        aCoder.encodeInt64(timerExpiresIn, forKey: defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Encoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
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
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
    }
    
    /// Clears the saved track sync triggers from NSUserDefaults
    ///
    func removeTriggers() {
        self.sizeToSync = 15
        self.timerStartsAt = 0
        self.timerExpiresIn = 172800000
        defaults.removeObjectForKey(defaultsKey)
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
        let count = SQLTrackedActionDataHelper.count()
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
        let actionRecord = SQLTrackedAction(
            index: 0,
            actionID: action.actionID,
            metaData: action.metaData,
            utc: action.utc,
            timezoneOffset: action.timezoneOffset
        )
        guard let _ = SQLTrackedActionDataHelper.insert(actionRecord)
            else{
                // if it couldnt be saved, send it
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action track")
                DopamineAPI.track([actionRecord], completion: { response in
                    
                })
                return
        }
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): takes the http response status code as a parameter.
    ///
    func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Track sync already happening")
                completion(200)
                return
            }
            self.syncInProgress = true
            
            let sqlActions = SQLTrackedActionDataHelper.findAll()
            
            if sqlActions.count == 0 {
                defer { self.syncInProgress = false }
                DopamineKit.DebugLog("No tracked actions to sync.")
                completion(200)
                self.updateTriggers()
                return
            } else {
                DopamineKit.DebugLog("Sending \(sqlActions.count) tracked actions...")
                DopamineAPI.track(sqlActions) { response in
                    defer { self.syncInProgress = false }
                    if response["status"] as? Int == 200 {
                        defer { completion(200) }
                        for action in sqlActions {
                            SQLTrackedActionDataHelper.delete(action)
                        }
                        self.updateTriggers()
                    } else {
                        completion(404)
                    }
                }
            }
        }
    }
    
}