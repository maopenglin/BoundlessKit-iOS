//
//  TrackSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class TrackSyncer {
    
    static private let instance: TrackSyncer = TrackSyncer()
    
    private static let defaults = NSUserDefaults.standardUserDefaults()
    private static let DefaultsKey = "DopamineTrackSyncer"
    private static let TimeSyncerKey = "TrackLog"
    private static let LogSizeKey = "LogSize"
    
    private init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let standardSize = 10
        if( defaults.valueForKey(TrackSyncer.DefaultsKey + TrackSyncer.LogSizeKey) == nil ){
            defaults.setValue(standardSize, forKey: TrackSyncer.DefaultsKey + TrackSyncer.LogSizeKey)
        }
        TimeSyncer.create(TrackSyncer.TimeSyncerKey, ifNotExists: true)
    }
    
    static func getLogSize() -> Int {
        return defaults.integerForKey(DefaultsKey + LogSizeKey)
    }
    
//    static func setLogSize(newSize: Int) {
//        defaults.setValue(newSize, forKey: DefaultsKey + LogSizeKey)
//    }
    
//    static func getLogCapacity() -> Double {
//        objc_sync_enter(instance)
//        defer{ objc_sync_exit(instance) }
//        
//        return Double(SQLTrackedActionDataHelper.count()) / Double(getLogSize())
//    }
    
    static func sync() {
        objc_sync_enter(instance)
        defer{ objc_sync_exit(instance) }
        
        let actions = SQLTrackedActionDataHelper.findAll()
        if actions.count == 0 {
            DopamineKit.DebugLog("No tracked actions to sync.")
            return
        }
        
        var trackedActions = Array<DopeAction>()
        for action in  actions {
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
            // TODO: if response['error'] == null { return }
            
            SQLTrackedActionDataHelper.dropTable()
            SQLTrackedActionDataHelper.createTable()
            TimeSyncer.reset(TrackSyncer.TimeSyncerKey)
            
//            objc_sync_exit(instance)
        })
    }
    
    static func store(action: DopeAction) {
        objc_sync_enter(instance)
        defer{ objc_sync_exit(instance) }
        
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
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action track")
                DopamineAPI.track([action], completion: { response in
                    
                })
                return
        }
        
        DopamineKit.DebugLog("Stored \(rowId) tracked actions.")
        if SQLTrackedActionDataHelper.count() >= TrackSyncer.getLogSize() ||
            TimeSyncer.isExpired(TrackSyncer.TimeSyncerKey)
        {
            sync()
        }
        
    }
    
    
    
}