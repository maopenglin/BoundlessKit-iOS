//
//  SyncCoordinator.swift
//  Pods
//
//  Created by Akash Desai on 7/31/16.
//
//

import Foundation

class SyncCoordinator {
    
    internal static let shared = SyncCoordinator()
    
    internal let trackedActions: DopeActionCollection
    internal let reportedActions: DopeActionCollection
    
    /// Initializer for SyncCoordinator performs a sync
    ///
    private init() {
        trackedActions = DopeActionCollection(actions: UserDefaults.dopamine.unarchive(key: "SyncCoordinator.TrackedActions"))
        reportedActions = DopeActionCollection(actions: UserDefaults.dopamine.unarchive(key: "SyncCoordinator.ReportedActions"))
    }
    
    deinit {
        saveTrackedActions()
        saveReportedActions()
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
        saveTrackedActions()
        performSync()
    }
    
    fileprivate func saveTrackedActions() {
        UserDefaults.dopamine.set(NSKeyedArchiver.archivedData(withRootObject: trackedActions.filter({_ in return true})), forKey: "SyncCoordinator.TrackedActions")
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
        saveReportedActions()
        performSync()
    }
    
    fileprivate func saveReportedActions() {
        UserDefaults.dopamine.set(NSKeyedArchiver.archivedData(withRootObject: reportedActions.filter({_ in return true})), forKey: "SyncCoordinator.ReportedActions")
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
            let reportShouldSync = (someCartridgeToSync != nil) || self.trackedActions.isTriggered()
            let trackShouldSync = reportShouldSync || self.trackedActions.isTriggered()
            
            if trackShouldSync {
                var syncCause: String
                if let cartridgeToSync = someCartridgeToSync {
                    syncCause = "Cartridge \(cartridgeToSync.actionID) needs to sync."
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
                                self.trackedActions.updateTriggers()
                                self.saveTrackedActions()
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
                
                if reportShouldSync && !self.reportedActions.isEmpty {
                    let actions = self.reportedActions.filter({_ in return true})
                    DopamineAPI.report(actions, completion: { response in
                        if let status = response["status"] as? Int {
                            if status == 200 || status == 400 {
                                self.reportedActions.removeFirst(actions.count)
                                self.reportedActions.updateTriggers()
                                self.saveReportedActions()
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
    public func flush() {
        trackedActions.removeAll()
        reportedActions.removeAll()
        Cartridge.flush()
        
        saveTrackedActions()
        saveReportedActions()
    }
}

