//
//  SyncCoordinator.swift
//  Pods
//
//  Created by Akash Desai on 7/31/16.
//
//

import Foundation

internal class SyncCoordinator : UserDefaultsSingleton {
    
    internal fileprivate (set) static var shared: SyncCoordinator = {
        return UserDefaults.dopamine.unarchive() ?? SyncCoordinator()
    }()
    
    internal let trackedActions: DopeActionCollection
    internal let reportedActions: DopeActionCollection
    
    @objc fileprivate var waitTimerStartedAt: Int64
    @objc fileprivate var waitTimerLength: Int64
    
    /// Initializer for SyncCoordinator performs a sync
    ///
    private init(trackActions: [DopeAction]? = nil, reportActions: [DopeAction]? = nil, waitTimerStartedAt: Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ), waitTimerLength: Int64 = 172800000) {
        trackedActions = DopeActionCollection(actions: trackActions)
        reportedActions = DopeActionCollection(actions: reportActions)
        self.waitTimerStartedAt = waitTimerStartedAt
        self.waitTimerLength = waitTimerLength
        super.init()
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: trackedActions.filter({_ in return true})), forKey: "trackActions")
        aCoder.encode(NSKeyedArchiver.archivedData(withRootObject: reportedActions.filter({_ in return true})), forKey: "reportActions")
        aCoder.encode(waitTimerStartedAt, forKey: #keyPath(SyncCoordinator.waitTimerStartedAt))
        aCoder.encode(waitTimerLength, forKey: #keyPath(SyncCoordinator.waitTimerLength))
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if let trackActionsData = aDecoder.decodeObject(forKey: "trackActions") as? Data,
            let trackActions = NSKeyedUnarchiver.unarchiveObject(with: trackActionsData) as? [DopeAction],
            let reportActionsData = aDecoder.decodeObject(forKey: "reportActions") as? Data,
            let reportActions = NSKeyedUnarchiver.unarchiveObject(with: reportActionsData) as? [DopeAction] {
            self.init(trackActions: trackActions,
                      reportActions: reportActions,
                      waitTimerStartedAt: aDecoder.decodeInt64(forKey: #keyPath(SyncCoordinator.waitTimerStartedAt)),
                      waitTimerLength: aDecoder.decodeInt64(forKey: #keyPath(SyncCoordinator.waitTimerLength))
            )
        } else {
            return nil
        }
    }
    
    
    
    /// Stores a tracked action to be synced
    ///
    /// - parameters:
    ///     - trackedAction: A tracked action.
    ///
    internal func store(track action: DopeAction) {
        guard DopamineVersion.current.isIntegrating == false else { return }
        let count = trackedActions.add(action)
        DopeLog.debug("track#\(count) actionID:\(action.actionID) with metadata:\(action.metaData as AnyObject))")
        UserDefaults.dopamine.archive(self)
        performSync()
    }
    
    /// Stores a reinforced action to be synced
    ///
    /// - parameters:
    ///     - reportedAction: A reinforced action.
    ///
    internal func store(report action: DopeAction) {
        guard DopamineVersion.current.isIntegrating == false else { return }
        let count = reportedActions.add(action)
        DopeLog.debug("report#\(count) actionID:\(action.actionID) with metadata:\(action.metaData as AnyObject))")
        UserDefaults.dopamine.archive(self)
        performSync()
    }
    
    /// Finds the right cartridge for an action and returns a reinforcement decision
    ///
    /// - parameters:
    ///     - reinforceableAction: The action to retrieve a reinforcement decision for.
    ///
    /// - returns:
    ///     A reinforcement decision
    ///
    internal func retrieve(cartridgeFor actionID: String) -> Cartridge {
        if let cartridge = Cartridge.cartridgeSyncers[actionID] {
            return cartridge
        } else {
            return Cartridge.create(actionID)
        }
    }
    
    /// Checks if the sync timer has expired
    ///
    /// - returns: Whether the timer has expired.
    ///
    private func waitTimerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (waitTimerStartedAt + waitTimerLength)
        //        DopeLog.debugLog("Track timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so the timer \(isExpired ? "will" : "won't") trigger a sync...")
        return isExpired
    }
    
    /// Updates the sync wait timer
    ///
    /// - parameters:
    ///     - timerStartsAt: The starting time to wait from. Defaults to the current time.
    ///     - timerExpiresIn: The maximum time, in ms, to wait until the next sync a sync timer. Defaults to previous timerExpiresIn.
    ///
    internal func resetWaitTimer(timerStartedAt: Int64? = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64? = nil) {
        if let timerStartedAt = timerStartedAt {
            self.waitTimerStartedAt = timerStartedAt
        }
        if let timerExpiresIn = timerExpiresIn {
            self.waitTimerLength = timerExpiresIn
        }
    }
    
    /// Checks which syncers have been triggered, and syncs them in an order
    /// that allows time for the DopamineAPI to generate cartridges
    ///
    fileprivate var syncOperationQueue = SingleOperationQueue(delayBefore: 3)
    public func performSync() {
        syncOperationQueue.addOperation {
            // since a cartridge might be triggered during the sleep time,
            // lazily check which are triggered
            var someCartridgeToSync: Cartridge?
            for (_, cartridge) in Cartridge.cartridgeSyncers {
                if cartridge.isTriggered() {
                    someCartridgeToSync = cartridge
                    break
                }
            }
            let timerExpired = self.waitTimerDidExpire()
            let reportShouldSync = self.reportedActions.count >= DopamineConfiguration.current.reportBatchSize
            let trackShouldSync = self.trackedActions.count >= DopamineConfiguration.current.trackBatchSize
            
            if someCartridgeToSync != nil || timerExpired || reportShouldSync || trackShouldSync {
                var syncCause: String
                if let cartridgeToSync = someCartridgeToSync {
                    syncCause = "Cartridge \(cartridgeToSync.actionID) needs to sync."
                } else if (timerExpired) {
                    syncCause = "Sync wait timer has expired."
                } else if (reportShouldSync) {
                    syncCause = "Report needs to sync."
                } else {
                    syncCause = "Track needs to sync."
                }
                DopeLog.debug("Syncing because \(syncCause)")
                
                Telemetry.startRecordingSync(cause: syncCause)
                var goodProgress = true
                
                if !self.trackedActions.isEmpty {
                    let actions = self.trackedActions.filter({_ in return true})
                    DopamineAPI.track(actions, completion: { response in
                        if let status = response["status"] as? Int {
                            if status == 200 {
                                self.trackedActions.removeFirst(actions.count)
                                UserDefaults.dopamine.archive(self)
                            } else {
                                DopeLog.debug("Track failed during sync. Halting sync.")
                                goodProgress = false
                                Telemetry.stopRecordingSync(successfulSync: false)
                            }
                        }
                    })
                    sleep(1)
                    if !goodProgress { return }
                }
                
                if !self.reportedActions.isEmpty {
                    let actions = self.reportedActions.filter({_ in return true})
                    DopamineAPI.report(actions, completion: { response in
                        if let status = response["status"] as? Int {
                            if status == 200 || status == 400 {
                                self.reportedActions.removeFirst(actions.count)
                                UserDefaults.dopamine.archive(self)
                            } else {
                                DopeLog.debug("Report failed during sync. Halting sync.")
                                goodProgress = false
                                Telemetry.stopRecordingSync(successfulSync: false)
                            }
                        }
                    })
                    sleep(5)
                    if !goodProgress { return }
                }
                
                if timerExpired {
                    self.resetWaitTimer()
                    UserDefaults.dopamine.archive(self)
                }
                
                
                // since a cartridge might be triggered during the sleep time,
                // lazily check which are triggered
                for (actionID, cartridge) in Cartridge.cartridgeSyncers where goodProgress && cartridge.isTriggered() {
                    cartridge.sync() { status in
                        guard status == 200 || status == 0 || status == 400 else {
                            DopeLog.debug("Refresh for \(actionID) failed during sync. Halting sync.")
                            goodProgress = false
                            Telemetry.stopRecordingSync(successfulSync: false)
                            return
                        }
                    }
                }
                
                sleep(3)
                if !goodProgress { return }
                
                Telemetry.stopRecordingSync(successfulSync: true)
            }
        }
    }
    
    /// Erase the sync objects along with their data
    ///
    public static func flush() {
        Cartridge.flush()
        
        shared = SyncCoordinator()
        UserDefaults.dopamine.archive(shared)
    }
}

