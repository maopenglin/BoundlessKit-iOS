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
            
            var goodProgress = true
            sleep(1)
            
            if TrackSyncer.shouldSync() {
                
                DopamineKit.DebugLog("Sending tracked actions for all cartridges reload...")
                TrackSyncer.sync() {
                    status in
                    guard status == 200 else {
                        DopamineKit.DebugLog("Track failed during all cartridges reload. Dropping sync.")
                        goodProgress = false
                        return
                    }
                }
            } else {
                DopamineKit.DebugLog("Track does not need sync in all cartridges reload...")
            }
            
            sleep(1)
            if !goodProgress { return }
            
            if ReportSyncer.shouldSync() {
                DopamineKit.DebugLog("Sending reported actions for all cartridges reload...")
                ReportSyncer.sync() {
                    status in
                    guard status == 200 else {
                        DopamineKit.DebugLog("Report failed during all cartridges reload. Dropping sync.")
                        goodProgress = false
                        return
                    }
                }
            } else {
                DopamineKit.DebugLog("Report does not need sync in all cartridges reload...")
            }
            
            sleep(5)
            if !goodProgress { return }
            
            for cartridge in CartridgeSyncer.whichShouldReload() {
                cartridge.reload(){status in
                    guard status == 200 else {
                        DopamineKit.DebugLog("Refresh failed during cartridges reload. Dropping sync.")
//                        goodProgress = false
                        return
                    }
                }
                sleep(1)
            }
        }
    }
    
    static func syncReports() {
        if ReportSyncer.shouldSync() {
            ReportSyncer.sync()
        }
    }
    
    static func syncTracks() {
        if TrackSyncer.shouldSync() {
            TrackSyncer.sync()
        }
    }
    
    static func syncCartridges() {
        for cartridge in CartridgeSyncer.whichShouldReload() {
            cartridge.reload()
        }
    }
}