//
//  SyncCoordinator.swift
//  Pods
//
//  Created by Akash Desai on 7/31/16.
//
//

import Foundation

open class SyncCoordinator {
    
    static let sharedInstance = SyncCoordinator()
    
    fileprivate let trackSyncer = TrackSyncer.sharedInstance;
    fileprivate let reportSyncer = ReportSyncer.sharedInstance;
    fileprivate let cartridgeSyncer = CartridgeSyncer.sharedInstance;
    
    fileprivate var syncInProgress = false
    
    /// Initializer for SyncCoordinator performs a sync
    ///
    fileprivate init() {
        performSync()
    }
    
    /// Stores a tracked action to be synced
    ///
    /// - parameters: 
    ///     - trackedAction: A tracked action.
    ///
    func storeTrackedAction(_ trackedAction: DopeAction) {
        trackSyncer.store(trackedAction)
        performSync()
    }
    
    /// Stores a reinforced action to be synced
    ///
    /// - parameters:
    ///     - reportedAction: A reinforced action.
    ///
    func storeReportedAction(_ reportedAction: DopeAction) {
        reportSyncer.store(reportedAction)
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
    func removeReinforcementDecisionFor(_ reinforceableAction: DopeAction) -> String {
        return cartridgeSyncer.unloadReinforcementDecisionForAction(reinforceableAction)
    }
    
    /// Checks which syners have been triggered, and syncs them in an order 
    /// that allows time for the DopamineAPI to generate cartridges
    ///
    open func performSync() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Sync already happening")
                return
            }
            self.syncInProgress = true
            defer { self.syncInProgress = false }
            
            let anyCartridgeShouldSync = self.cartridgeSyncer.shouldSync()
            let reportShouldSync = anyCartridgeShouldSync || self.reportSyncer.shouldSync()
            let trackerShouldSync = reportShouldSync || self.trackSyncer.shouldSync()
            
            var goodProgress = true
            
            if trackerShouldSync {
                self.trackSyncer.sync() {
                    status in
                    guard status == 200 else {
                        DopamineKit.DebugLog("Track failed during sync. Halting sync.")
                        goodProgress = false
                        return
                    }
                }
                sleep(1)
            }
            
            if !goodProgress { return }
            
            if reportShouldSync {
                self.reportSyncer.sync() {
                    status in
                    guard status == 200 else {
                        DopamineKit.DebugLog("Report failed during sync. Halting sync.")
                        goodProgress = false
                        return
                    }
                }
                sleep(5)
            }
            
            if !goodProgress { return }
            
            let cartridgesToSync = self.cartridgeSyncer.whichShouldSync()
            DopamineKit.DebugLog("Refreshing \(cartridgesToSync.count) cartidges.")
            for actionID in cartridgesToSync where goodProgress {
                self.cartridgeSyncer.sync(actionID) { status in
                    guard status == 200 else {
                        DopamineKit.DebugLog("Refresh for \(actionID) failed during sync. Halting sync.")
                        goodProgress = false
                        return
                    }
                }
            }
        }
    }
    
    /// Modifies the number of tracked actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of tracked actions to trigger a sync.
    ///
    open func setTrackSizeToSync(_ size: Int?) {
        trackSyncer.setSizeToSync(size)
    }
    
    /// Modifies the number of reported actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of reported actions to trigger a sync.
    ///
    open func setReportSizeToSync(_ size: Int?) {
        reportSyncer.setSizeToSync(size)
    }
    
    /// Resets the sync triggers
    ///
    open func resetSyncers() {
        trackSyncer.reset()
        reportSyncer.reset()
        cartridgeSyncer.reset()
    }
}
