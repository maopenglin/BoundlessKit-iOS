//
//  Track.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
internal class Track : UserDefaultsSingleton {
    
    fileprivate static var _current: Track? =  { return UserDefaults.boundless.unarchive() }()
    {
        didSet {
            UserDefaults.boundless.archive(_current)
        }
    }
    static var current: Track {
        get {
            if let _ = _current {
            } else {
                _current = Track()
            }
            return _current!
        }
    }
    
//    private let dispatchGroup = DispatchGroup()
    private let dispatchQueue = DispatchQueue(label: NSStringFromClass(Track.self))
    
    @objc private var trackedActions: [BoundlessAction]
    @objc private var timerStartedAt: Int64
    @objc private var timerExpiresIn: Int64
    
    private var syncInProgress = false
    
    /// Loads the track from NSUserDefaults or creates a new one and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - trackedActions: An array of BoundlessAction's
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    private init(trackedActions: [BoundlessAction] = [], timerStartedAt: Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64 = 172800000) {
        self.trackedActions = trackedActions
        self.timerStartedAt = timerStartedAt
        self.timerExpiresIn = timerExpiresIn
        super.init()
    }
    
    /// Decodes a saved track from NSUserDefaults
    ///
    required convenience init?(coder aDecoder: NSCoder) {
        if let trackedActions = aDecoder.decodeObject(forKey: #keyPath(Track.trackedActions)) as? [BoundlessAction] {
            self.init(trackedActions: trackedActions,
                      timerStartedAt: aDecoder.decodeInt64(forKey: #keyPath(Track.timerStartedAt)),
                      timerExpiresIn: aDecoder.decodeInt64(forKey: #keyPath(Track.timerExpiresIn))
            )
//            BoundlessLog.debug("Decoded track with trackedActions:\(trackedActions.count) sizeToSync:\(BoundlessConfiguration.current.trackBatchSize) timerStartsAt:\(timerStartedAt) timerExpiresIn:\(timerExpiresIn)")
        } else {
            return nil
        }
    }
    
    /// Encodes a track and saves it to NSUserDefaults
    ///
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(trackedActions, forKey: #keyPath(Track.trackedActions))
        aCoder.encode(timerStartedAt, forKey: #keyPath(Track.timerStartedAt))
        aCoder.encode(timerExpiresIn, forKey: #keyPath(Track.timerExpiresIn))
        //        BoundlessLog.debugLog("Encoded TrackSyncer with trackedActions:\(trackedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - sizeToSync: The number of tracked actions to trigger a sync. Defaults to previous sizeToSync.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to previous timerExpiresIn.
    ///
    func updateTriggers(timerStartedAt: Int64? = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64? = nil) {
        if let timerStartedAt = timerStartedAt {
            self.timerStartedAt = timerStartedAt
        }
        if let timerExpiresIn = timerExpiresIn {
            self.timerExpiresIn = timerExpiresIn
        }
        Track._current = self
    }
    
    /// Clears the saved track sync triggers from NSUserDefaults
    ///
    static func flush() {
        _current = Track()
    }
    
    /// Check whether the track has been triggered for a sync
    ///
    /// - returns: Whether a sync has been triggered.
    ///
    func isTriggered() -> Bool {
        return BoundlessVersion.current.versionID != nil && ( timerDidExpire() || batchIsFull() )
    }
    
    /// Checks if the sync timer has expired
    ///
    /// - returns: Whether the timer has expired.
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartedAt + timerExpiresIn)
        //        BoundlessLog.debugLog("Track timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so the timer \(isExpired ? "will" : "won't") trigger a sync...")
        return isExpired
    }
    
    /// Checks if the track is at the size to sync
    ///
    /// - returns: Whether there are enough tracked actions to trigger a sync.
    ///
    private func batchIsFull() -> Bool {
        let count = trackedActions.count
        let isBatchSizeReached = count >= BoundlessConfiguration.current.trackBatchSize
        //        BoundlessLog.debugLog("Track has \(count)/\(sizeToSync) actions so the size \(isSize ? "will" : "won't") trigger a sync...")
        return isBatchSizeReached
    }
    
    /// Stores a tracked action to be synced at a later time
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    let dispatchGroup = DispatchGroup()
    var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    func add(_ action: BoundlessAction) {
        guard BoundlessVersion.current.versionID != nil else {
            return
        }
        operationQueue.addOperation {
            if BoundlessConfiguration.current.locationObservations {
                BoundlessLocation.shared.getLocation { location in
                    self.operationQueue.addOperation {
                        if let location = location {
                            action.addMetaData(["location": location])
                        }
                        self.trackedActions.append(action)
                        if self.operationQueue.operationCount == 1 {
                            Track._current = self
                        }
                        BoundlessLog.debug("track#\(self.trackedActions.count) actionID:\(action.actionID)")//" with metadata:\(String(describing: action.metaData))")
                    }
                }
            } else {
                self.trackedActions.append(action)
                if self.operationQueue.operationCount == 1 {
                    Track._current = self
                }
                 BoundlessLog.debug("track#\(self.trackedActions.count) actionID:\(action.actionID)")//" with metadata:\(String(describing: action.metaData))")
            }
        }
    }
    
    /// Sends tracked actions
    ///
    /// - parameters:
    ///     - completion(Int): Returns the status code, or 0 if there were no actions to sync.
    ///
    func sync(completion: @escaping (_ statusCode: Int) -> () = { _ in }) {
        dispatchQueue.async() {
            guard !self.syncInProgress else {
                completion(0)
                return
            }
            self.syncInProgress = true
//            BoundlessLog.debug("Track sync in progress...")
            let syncFinished = {
                self.syncInProgress = false
            }
            
            if self.trackedActions.count == 0 {
                defer { syncFinished() }
//                BoundlessLog.debug("No tracked actions to sync.")
                completion(0)
                self.updateTriggers()
                return
            } else {
//                BoundlessLog.debug("Sending \(self.trackedActions.count) tracked actions...")
                BoundlessAPI.track(self.trackedActions) { response in
                    defer { syncFinished() }
                    if let status = response["status"] as? Int {
                        if status == 200 {
//                            BoundlessLog.debug("Sent \(self.trackedActions.count) tracked actions!")
                            self.trackedActions.removeAll()
                            self.updateTriggers()
                        }
                        completion(status)
                    } else {
                        completion(404)
                    }
                }
            }
        }
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["size"] = NSNumber(value: trackedActions.count)
        jsonObject[#keyPath(Track.timerStartedAt)] = NSNumber(value: timerStartedAt)
        jsonObject[#keyPath(Track.timerExpiresIn)] = NSNumber(value: timerExpiresIn)
        
        return jsonObject
    }
}
