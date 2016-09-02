//
//  SyncCoordinator.swift
//  Pods
//
//  Created by Akash Desai on 7/31/16.
//
//

import Foundation

public class SyncCoordinator {
    
    static let sharedInstance = SyncCoordinator()
    
    private let trackSyncer = TrackSyncer.sharedInstance;
    private let reportSyncer = ReportSyncer.sharedInstance;
    private let cartridgeSyncer = CartridgeSyncer.sharedInstance;
    
    private var syncInProgress = false
    
    /// Creates SQLite tables and performs a sync
    ///
    private init() {
        performSync()
    }
    
    /// Stores a tracked action to be synced
    ///
    /// - parameters: 
    ///     - trackedAction: A tracked action.
    ///
    func storeTrackedAction(trackedAction: DopeAction) {
        trackSyncer.store(trackedAction)
        performSync()
    }
    
    /// Stores a reinforced action to be synced
    ///
    /// - parameters:
    ///     - reportedAction: A reinforced action.
    ///
    func storeReportedAction(reportedAction: DopeAction) {
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
    func removeReinforcementDecisionFor(reinforceableAction: DopeAction) -> String {
        return cartridgeSyncer.unloadReinforcementDecisionForAction(reinforceableAction)
    }
    
    /// Checks which syners have been triggered, and syncs them in an order 
    /// that allows time for the DopamineAPI to generate cartridges
    ///
    public func performSync() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
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
//                DopamineKit.DebugLog("Sending \(SQLTrackedActionDataHelper.count()) tracked actions...")
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
//                DopamineKit.DebugLog("Sending \(SQLReportedActionDataHelper.count()) reported actions...")
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
    public func setTrackSizeToSync(size: Int?) {
        trackSyncer.setSizeToSync(size)
    }
    
    /// Modifies the number of reported actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of reported actions to trigger a sync.
    ///
    public func setReportSizeToSync(size: Int?) {
        reportSyncer.setSizeToSync(size)
    }
    
    /// Resets the sync triggers
    ///
    public func resetSyncers() {
        trackSyncer.reset()
        reportSyncer.reset()
        cartridgeSyncer.reset()
    }
}