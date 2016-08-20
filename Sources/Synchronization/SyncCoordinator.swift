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
    
    private let dataStore:SQLiteDataStore = SQLiteDataStore.sharedInstance
    private let trackSyncer = TrackSyncer.sharedInstance;
    private let reportSyncer = ReportSyncer.sharedInstance;
    private let cartridgeSyncer = CartridgeSyncer.sharedInstance;
    
    private var syncInProgress = false
    
    private init() {
        dataStore.createTables()
    }
    
    public func storeTrackedAction(trackedAction: DopeAction) {
        trackSyncer.store(trackedAction)
        sync()
    }
    
    public func storeReportedAction(reportedAction: DopeAction) {
        reportSyncer.store(reportedAction)
        sync()
    }
    
    public func removeReinforcementDecisionFor(actionID: String) -> String {
        return cartridgeSyncer.unload(actionID)
    }
    
    func sync() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Sync already happening")
                return
            }
            self.syncInProgress = true
            defer { self.syncInProgress = false }
            
            let cartridges = self.cartridgeSyncer.whichShouldSync()
            let reportShouldSync = cartridges.count > 0 || self.reportSyncer.shouldSync()
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
            
            if cartridges.count > 0 {
                DopamineKit.DebugLog("Refreshing \(cartridges.count)/\(SQLCartridgeDataHelper.getTablesCount()) cartidges.")
                for (actionID, cartridge) in cartridges where goodProgress {
                    self.cartridgeSyncer.sync(cartridge){status in
                        guard status == 200 else {
                            DopamineKit.DebugLog("Refresh for \(actionID) failed during sync. Halting sync.")
                            goodProgress = false
                            return
                        }
                    }
//                    sleep(1)
                }
            }
        }
    }
}