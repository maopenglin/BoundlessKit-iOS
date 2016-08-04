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
    
    private init() { }
    
    static private var syncInProgress = false
    
    static func sync() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            guard !syncInProgress else {
                DopamineKit.DebugLog("Sync already happening")
                return
            }
            syncInProgress = true
            defer { syncInProgress = false }
            
            let cartridgeSyncer = CartridgeSyncer.sharedInstance
            let trackSyncer = TrackSyncer.sharedInstance
            let reportSyncer = ReportSyncer.sharedInstance
            
            var goodProgress = true
            
            if trackSyncer.shouldSync() {
                DopamineKit.DebugLog("Sending \(SQLTrackedActionDataHelper.count()) tracked actions...")
                trackSyncer.sync() {
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
            
            if reportSyncer.shouldSync() {
                DopamineKit.DebugLog("Sending \(SQLReportedActionDataHelper.count()) reported actions...")
                reportSyncer.sync() {
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
            
            let cartridges = cartridgeSyncer.whichShouldSync()
            if cartridges.count > 0 {
                DopamineKit.DebugLog("Refreshing \(cartridges.count)/\(SQLCartridgeDataHelper.getTablesCount()) cartidges.")
                for (actionID, cartridge) in cartridges where goodProgress {
                    cartridgeSyncer.sync(cartridge){status in
                        guard status == 200 else {
                            DopamineKit.DebugLog("Refresh for \(actionID) failed during sync. Halting sync.")
                            goodProgress = false
                            return
                        }
                    }
                    sleep(1)
                }
            }
        }
    }
}