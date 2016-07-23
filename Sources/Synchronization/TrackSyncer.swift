//
//  TrackSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class TrackSyncer {
    
    private let lock:Int = 0
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let DefaultsKey = "DopamineTrackSyncer"
    private let TimeSyncerKey = "TrackLog"
    private let LogSizeKey = "LogSize"
    
    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let standardSize = 10
        if( defaults.valueForKey(DefaultsKey + LogSizeKey) == nil ){
            defaults.setValue(standardSize, forKey: DefaultsKey + LogSizeKey)
        }
        TimeSyncer.create(TimeSyncerKey, ifNotExists: true)
    }
    
    func getLogSize() -> Int {
        return defaults.integerForKey(DefaultsKey + LogSizeKey)
    }
    
    func setLogSize(newSize: Int) {
        defaults.setValue(newSize, forKey: DefaultsKey + LogSizeKey)
    }
    
    func shouldSend() -> Bool {
        objc_sync_enter(lock)
        defer{ objc_sync_exit(lock) }
        
        return SQLTrackedActionDataHelper.count() >= getLogSize() ||
               TimeSyncer.isExpired(TimeSyncerKey)
    }
    
    func getLogCapacity() -> Double {
        objc_sync_enter(lock)
        defer{ objc_sync_exit(lock) }
        
        return Double(SQLTrackedActionDataHelper.count()) / Double(getLogSize())
    }
    
    func send() {
        objc_sync_enter(self.lock)
        
        var trackedActions = Array<DopeAction>()
        for action in SQLTrackedActionDataHelper.findAll() {
            trackedActions.append(
                DopeAction(
                    actionID: action.actionID,
                    metaData: action.metaData,
                    utc: action.utc,
                    timezoneOffset: action.timezoneOffset)
            )
        }
        
        DopamineAPI.track(trackedActions, completion: {
            response in
            DopamineKit.DebugLog("Track syner sent tracked actions with response:\(response)")
            SQLTrackedActionDataHelper.dropTable()
            SQLTrackedActionDataHelper.createTable()
            TimeSyncer.reset(self.TimeSyncerKey)
            
            objc_sync_exit(self.lock)
        })
    }
    
    func store(action: DopeAction) {
        objc_sync_enter(self.lock)
        defer{ objc_sync_exit(self.lock) }
        
        guard let rowId = SQLTrackedActionDataHelper.insert(
            SQLTrackedAction(
                index:0,
                actionID:
                action.actionID,
                metaData: action.metaData,
                utc: action.utc,
                timezoneOffset: action.timezoneOffset)
            )
            else{
                // if it couldnt be saved, send it
                DopamineAPI.track([action], completion: { response in
                    DopamineKit.DebugLog("Track syncer sent tracked actions with response:\(response)")
                })
                return
        }
        
        DopamineKit.DebugLog("Stored \(rowId) actions.")
    }
    
    
    
}