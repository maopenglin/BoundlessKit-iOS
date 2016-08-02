//
//  TrackSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

@objc
class TrackSyncer : NSObject {
    
    static let sharedInstance: TrackSyncer = TrackSyncer()
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let defaultsKey = "DopamineTrackSyncer"
    
    private let track: Track
    
    private override init() {
        if let savedTrackData = defaults.objectForKey(defaultsKey) as? NSData {
            let savedTrack = NSKeyedUnarchiver.unarchiveObjectWithData(savedTrackData) as! Track
            track = savedTrack
        } else {
            track = Track()
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(track), forKey: defaultsKey)
        }
    }
    
    func updateTrack(suggestedSize: Int?=nil, timerMarker: Int64=Int64( 1000*NSDate().timeIntervalSince1970 ), timerLength: Int64?=nil) {
        if let suggestedSize = suggestedSize {
            track.suggestedSize = suggestedSize
        }
        track.timerMarker = timerMarker
        if let timerLength = timerLength {
            track.timerLength = timerLength
        }
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(track), forKey: defaultsKey)
    }
    
    private var syncInProgress = false
    
    func shouldSync() -> Bool {
        return !syncInProgress && track.shouldSync()
    }
    
    
    func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Track sync already happening")
                completion(200)
                return
            }
            self.syncInProgress = true
            
            let actions = SQLTrackedActionDataHelper.findAll()
            if actions.count == 0 {
                defer { self.syncInProgress = false }
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
                defer { self.syncInProgress = false }
                if response["status"] as? Int == 200 {
                    defer { completion(200) }
                    for action in actions {
                        SQLTrackedActionDataHelper.delete(action)
                    }
                    self.updateTrack()
                } else {
                    completion(404)
                }
            })
        }
    }
    
    func store(action: DopeAction) {
        guard let _ = SQLTrackedActionDataHelper.insert(
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
    }
    
    
    
}