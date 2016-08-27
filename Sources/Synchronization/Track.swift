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
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let defaultsKey = "DopamineTrack"
    private let defaultsSizeToSync = "sizeToSync"
    private let defaultsTimerStartsAt = "timerStartsAt"
    private let defaultsTimerExpiresIn = "timerExpiresIn"
    
    private var sizeToSync: Int
    private var timerStartsAt: Int64
    private var timerExpiresIn: Int64
    
    init(sizeToSync: Int = 15, timerStartsAt: Int64 = 0, timerExpiresIn: Int64 = 172800000) {
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
    
    required init(coder aDecoder: NSCoder) {
        self.sizeToSync = aDecoder.decodeIntegerForKey(defaultsSizeToSync)
        self.timerStartsAt = aDecoder.decodeInt64ForKey(defaultsTimerStartsAt)
        self.timerExpiresIn = aDecoder.decodeInt64ForKey(defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Decoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(sizeToSync, forKey: defaultsSizeToSync)
        aCoder.encodeInt64(timerStartsAt, forKey: defaultsTimerStartsAt)
        aCoder.encodeInt64(timerExpiresIn, forKey: defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Encoded TrackSyncer with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    func updateTriggers(sizeToSync: Int?=nil, timerStartsAt: Int64=Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64?=nil) {
        if let sizeToSync = sizeToSync {
            self.sizeToSync = sizeToSync
        }
        self.timerStartsAt = timerStartsAt
        if let timerExpiresIn = timerExpiresIn {
            self.timerExpiresIn = timerExpiresIn
        }
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
    }
    
    func isTriggered() -> Bool {
        return timerDidExpire() || isSizeToSync()
    }
    
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
        DopamineKit.DebugLog("Track timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
        return isExpired
    }
    
    private func isSizeToSync() -> Bool {
        let count = SQLTrackedActionDataHelper.count()
        let isSize = count >= sizeToSync
        DopamineKit.DebugLog("Track has \(count)/\(sizeToSync) actions so \(isSize ? "does" : "doesn't") need to sync...")
        return isSize
    }
    
    func add(action: DopeAction) {
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
    
    func remove(action: SQLTrackedAction) {
        SQLTrackedActionDataHelper.delete(action)
    }
    
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