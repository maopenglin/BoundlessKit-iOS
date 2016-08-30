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
    
    private let track = Track()
    
    private var syncInProgress = false
    
    private override init() { }
    
    func store(action: DopeAction) {
        track.add(action)
    }
    
    func shouldSync() -> Bool {
        return track.isTriggered()
    }
    
    func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Track sync already happening")
                completion(200)
                return
            }
            
            self.syncInProgress = true
            let (sqlActions, dopeActions) = self.track.getActions()
            
            if dopeActions.count == 0 {
                defer { self.syncInProgress = false }
                DopamineKit.DebugLog("No tracked actions to sync.")
                completion(200)
                self.track.updateTriggers()
                return
            } else {
                DopamineAPI.track(dopeActions, completion: { response in
                    defer { self.syncInProgress = false }
                    if response["status"] as? Int == 200 {
                        defer { completion(200) }
                        for action in sqlActions {
                            self.track.remove(action)
                        }
                        self.track.updateTriggers()
                    } else {
                        completion(404)
                    }
                })
            }
        }
    }
    
}