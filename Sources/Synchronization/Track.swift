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
    
    fileprivate let defaults = UserDefaults.standard
    fileprivate let defaultsKey = "DopamineTrack"
    fileprivate let defaultsSizeToSync = "sizeToSync"
    fileprivate let defaultsTimerStartsAt = "timerStartsAt"
    fileprivate let defaultsTimerExpiresIn = "timerExpiresIn"
    
    fileprivate var sizeToSync: Int
    fileprivate var timerStartsAt: Int64
    fileprivate var timerExpiresIn: Int64
    
    /// Loads the track from NSUserDefaults or creates a new one and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - sizeToSync: The number of tracked actions to trigger a sync. Defaults to 15.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    fileprivate init(sizeToSync: Int = 15, timerStartsAt: Int64 = 0, timerExpiresIn: Int64 = 172800000) {
        if let savedTrackData = defaults.object(forKey: defaultsKey) as? Data,
            let savedTrack = NSKeyedUnarchiver.unarchiveObject(with: savedTrackData) as? Track {
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
        self.sizeToSync = aDecoder.decodeInteger(forKey: defaultsSizeToSync)
        self.timerStartsAt = aDecoder.decodeInt64(forKey: defaultsTimerStartsAt)
        self.timerExpiresIn = aDecoder.decodeInt64(forKey: defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Decoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a track and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(sizeToSync, forKey: defaultsSizeToSync)
        aCoder.encode(timerStartsAt, forKey: defaultsTimerStartsAt)
        aCoder.encode(timerExpiresIn, forKey: defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Encoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - sizeToSync: The number of tracked actions to trigger a sync. Defaults to previous sizeToSync.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to previous timerExpiresIn.
    ///
    func updateTriggers(_ sizeToSync: Int?=nil, timerStartsAt: Int64?=Int64( 1000*Date().timeIntervalSince1970 ), timerExpiresIn: Int64?=nil) {
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
    
    /// Clears the saved track from NSUserDefaults and resets triggers
    ///
    func resetTriggers() {
        self.sizeToSync = 15
        self.timerStartsAt = 0
        self.timerExpiresIn = 172800000
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
    fileprivate func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*Date().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
        DopamineKit.DebugLog("Track timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
        return isExpired
    }
    
    /// Checks if the track is at the size to sync
    ///
    /// - returns: Whether there are enough tracked actions to trigger a sync.
    ///
    fileprivate func isSizeToSync() -> Bool {
        let count = SQLTrackedActionDataHelper.count()
        let isSize = count >= sizeToSync
        DopamineKit.DebugLog("Track has \(count)/\(sizeToSync) actions so \(isSize ? "does" : "doesn't") need to sync...")
        return isSize
    }
    
    /// Stores a tracked action to be synced over the DopamineAPI at a later time
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    func add(_ action: DopeAction) {
        guard let _ = SQLTrackedActionDataHelper.insert(
            SQLTrackedAction(
                index: 0,
                actionID: action.actionID,
                metaData: action.metaData,
                utc: action.utc,
                timezoneOffset: action.timezoneOffset )
            )
            else{
                // if it couldnt be saved, send it
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action track")
                DopamineAPI.track([action], completion: { response in
                    
                })
                return
        }
    }
    
    /// Removes a tracked action, to be used after an action has been synced over the DopamineAPI
    ///
    /// - parameters:
    ///     - action: The sql row to delete.
    ///
    func remove(_ action: SQLTrackedAction) {
        SQLTrackedActionDataHelper.delete(action)
    }
    
    /// Retrieve all tracked actions
    ///
    /// - returns: (sqlRows, dopeActions)
    ///     - sqlRows: The sql rows for tracked actions. Pass into `remove()` after successful sync.
    ///     - dopeActions: The tracked actions to be synced over DopamineAPI.
    ///
    func getActions() -> (Array<SQLTrackedAction>, Array<DopeAction>) {
        var trackedActions = Array<DopeAction>()
        let sqlActions = SQLTrackedActionDataHelper.findAll()
        for action in sqlActions {
            trackedActions.append(
                DopeAction(
                    actionID: action.actionID,
                    metaData: action.metaData,
                    utc: action.utc,
                    timezoneOffset: action.timezoneOffset )
            )
        }
        return (sqlActions, trackedActions)
    }
    
}
