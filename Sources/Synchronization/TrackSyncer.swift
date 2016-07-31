//
//  TrackSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class TrackSyncer {
    
    static private let sharedInstance: TrackSyncer = TrackSyncer()
    
    private static let defaults = NSUserDefaults.standardUserDefaults()
    private static let DefaultsKey = "DopamineTrackSyncer"
    private static let TimeSyncerKey = "TrackLog"
    private static let LogSizeKey = "LogSize"
    
    private init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let standardSize = 10
        if( defaults.valueForKey(TrackSyncer.DefaultsKey + TrackSyncer.LogSizeKey) == nil ) {
            defaults.setValue(standardSize, forKey: TrackSyncer.DefaultsKey + TrackSyncer.LogSizeKey)
        }
        TimeSyncer.create(TrackSyncer.TimeSyncerKey, ifNotExists: true)
    }
    
    static func getLogSize() -> Int {
        return defaults.integerForKey(DefaultsKey + LogSizeKey)
    }
    
    private static var syncInProgress = false
    
    static func shouldSync() -> Bool {
        return !syncInProgress && (
            SQLTrackedActionDataHelper.count() >= TrackSyncer.getLogSize() ||
            TimeSyncer.isExpired(TrackSyncer.TimeSyncerKey)
        )
    }
    
    static func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !syncInProgress else {
                DopamineKit.DebugLog("Track sync already happening")
                completion(200)
                return
            }
            syncInProgress = true
            
            let actions = SQLTrackedActionDataHelper.findAll()
            if actions.count == 0 {
                defer { syncInProgress = false }
                DopamineKit.DebugLog("No tracked actions to sync.")
                completion(200)
                return
            }
            
            var trackedActions = Array<DopeAction>()
            for action in actions {
                trackedActions.append(
                    DopeAction(
                        actionID: action.actionID,
                        metaData: action.metaData,
                        utc: action.utc )
                )
            }
            
            DopamineAPI.track(trackedActions, completion: {
                response in
                defer { syncInProgress = false }
                if response["status"] as? Int == 200 {
                    for action in actions {
                        SQLTrackedActionDataHelper.delete(action)
                    }
                    TimeSyncer.reset(TrackSyncer.TimeSyncerKey)
                    completion(200)
                } else {
                    completion(404)
                }
            })
        }
    }
    
    static func store(action: DopeAction) {
        let _ = sharedInstance
        guard let rowId = SQLTrackedActionDataHelper.insert(
            SQLTrackedAction(
                index:0,
                actionID:
                action.actionID,
                metaData: action.metaData,
                utc: action.utc )
            )
            else{
                // if it couldnt be saved, send it
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action track")
                DopamineAPI.track([action], completion: { response in
                    
                })
                return
        }
        
        if shouldSync()
        {
            sync()
        }
        
        for cartridge in CartridgeSyncer.whichShouldReload() {
            cartridge.reload()
        }
        
    }
    
    
    
}