//
//  SyncCoordinator.swift
//  Pods
//
//  Created by Akash Desai on 7/31/16.
//
//

import Foundation

class SyncCoordinator {
    
    static let sharedInstance = SyncCoordinator()
    
    private let dataStore:SQLiteDataStore = SQLiteDataStore.sharedInstance
    private let trackSyncer = TrackSyncer.sharedInstance;
    private let reportSyncer = ReportSyncer.sharedInstance;
    private let cartridgeSyncer = CartridgeSyncer.sharedInstance;
    
    private var syncInProgress = false
    
    private init() {
        dataStore.createTables()
    }
    
    func storeTrackedAction(trackedAction: DopeAction) {
        trackSyncer.store(trackedAction)
        performSync()
    }
    
    func storeReportedAction(reportedAction: DopeAction) {
        reportSyncer.store(reportedAction)
        performSync()
    }
    
    func removeReinforcementDecisionFor(reinforceableAction: DopeAction) -> String {
        return cartridgeSyncer.unloadReinforcementDecisionForAction(reinforceableAction)
//        return "neutralResponse"
    }
    
    private func performSync() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Sync already happening")
                return
            }
            self.syncInProgress = true
            defer { self.syncInProgress = false }
            
            let cartridgesToSync = self.cartridgeSyncer.whichShouldSync()
            let reportShouldSync = cartridgesToSync.count>0 || self.reportSyncer.shouldSync()
            let trackerShouldSync = reportShouldSync || self.trackSyncer.shouldSync()
            
            var goodProgress = true
            
            if trackerShouldSync {
                DopamineKit.DebugLog("Sending \(SQLTrackedActionDataHelper.count()) tracked actions...")
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
                DopamineKit.DebugLog("Sending \(SQLReportedActionDataHelper.count()) reported actions...")
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
}