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
    
    fileprivate let track = Track.sharedInstance
    
    fileprivate var syncInProgress = false
    
    fileprivate override init() { }
    
    /// Stores an action to be synced
    ///
    func store(_ action: DopeAction) {
        track.add(action)
    }
    
    /// Modifies the number of tracked actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of tracked actions to trigger a sync.
    ///
    func setSizeToSync(_ size: Int?) {
        track.updateTriggers(size, timerStartsAt: nil, timerExpiresIn: nil)
    }
    
    /// Check if a sync has been triggered
    ///
    /// - returns: Whether the track needs to sync.
    ///
    func shouldSync() -> Bool {
        return track.isTriggered()
    }
    
    /// Sends tracked actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): takes the http response status code as a parameter.
    ///
    func sync(_ completion: @escaping (Int) -> () = { _ in }) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
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
                DopamineKit.DebugLog("Sending \(dopeActions.count) tracked actions...")
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
    
    /// Removes saved sync triggers from memory
    ///
    func reset() {
        track.resetTriggers()
    }
    
}
