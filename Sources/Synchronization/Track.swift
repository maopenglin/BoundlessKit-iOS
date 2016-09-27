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
    
    private let sizeKey = "size"
    private let sizeToSyncKey = "sizeToSync"
    private let timerStartsAtKey = "timerStartsAt"
    private let timerExpiresInKey = "timerExpiresIn"
    
    private var sizeToSync: Int
    private var timerStartsAt: Int64
    private var timerExpiresIn: Int64
    
    private var syncInProgress = false
    
    /// Loads the track from NSUserDefaults or creates a new one and saves it to NSUserDefaults
    ///
    override private init() {
        if let savedTrackData = defaults.objectForKey(defaultsKey) as? NSData,
            let savedTrack = NSKeyedUnarchiver.unarchiveObjectWithData(savedTrackData) as? Track {
            self.sizeToSync = savedTrack.sizeToSync
            self.timerStartsAt = savedTrack.timerStartsAt
            self.timerExpiresIn = savedTrack.timerExpiresIn
            super.init()
        } else {
            self.sizeToSync = 15
            self.timerStartsAt = Int64(1000*NSDate().timeIntervalSince1970)
            self.timerExpiresIn = 172800000
            super.init()
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
        }
    }
    
    /// Decodes a saved track from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.sizeToSync = aDecoder.decodeIntegerForKey(sizeToSyncKey)
        self.timerStartsAt = aDecoder.decodeInt64ForKey(timerStartsAtKey)
        self.timerExpiresIn = aDecoder.decodeInt64ForKey(timerExpiresInKey)
        DopamineKit.DebugLog("Decoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a track and saves it to NSUserDefaults
    ///
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(sizeToSync, forKey: sizeToSyncKey)
        aCoder.encodeInt64(timerStartsAt, forKey: timerStartsAtKey)
        aCoder.encodeInt64(timerExpiresIn, forKey: timerExpiresInKey)
        DopamineKit.DebugLog("Encoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Decodes a JSON compatible object of the sync triggers
    ///
    func decodeJSONForTriggers() -> [String: AnyObject]{
        return [
            sizeKey : SQLTrackedActionDataHelper.count(),
            sizeToSyncKey : sizeToSync,
            timerStartsAtKey : NSNumber(longLong: timerStartsAt),
            timerExpiresInKey : NSNumber(longLong: timerExpiresIn)
        ]
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
                // if it couldnt be saved, send it right away
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action track")
                DopamineAPI.track([actionRecord], completion: { response in
                    
                })
                return
        }
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if there were no actions to sync.
    ///
    func sync(completion: (statusCode: Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Track sync already happening")
                completion(statusCode: 0)
                return
            }
            self.syncInProgress = true
            
            let sqlActions = SQLTrackedActionDataHelper.findAll()
            
            if sqlActions.count == 0 {
                defer { self.syncInProgress = false }
                DopamineKit.DebugLog("No tracked actions to sync.")
                completion(statusCode: 0)
                self.updateTriggers()
                return
            } else {
                DopamineKit.DebugLog("Sending \(sqlActions.count) tracked actions...")
//                let startTimeForCall = 1000*NSDate().timeIntervalSince1970
                DopamineAPI.track(sqlActions) { response in
//                    let endTimeForCall = 1000*NSDate().timeIntervalSince1970
                    defer { self.syncInProgress = false }
                    if let responseStatusCode = response["status"] as? Int {
                        completion(statusCode: responseStatusCode)
                        if responseStatusCode == 200 {
                            for action in sqlActions {
                                SQLTrackedActionDataHelper.delete(action)
                            }
                            self.updateTriggers()
                        }
                    } else {
                        completion(statusCode: 404)
                    }
                }
            }
        }
    }
    
}
