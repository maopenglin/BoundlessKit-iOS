//
//  SyncCoordinator.swift
//  Pods
//
//  Created by Akash Desai on 7/31/16.
//
//

import Foundation

public class SyncCoordinator {
    
    internal static let shared = SyncCoordinator()
    
    private var syncInProgress = false
    
    fileprivate let trackedActionsQueue = DispatchQueue(label: "TrackedActionsQueue")
    
    /// Initializer for SyncCoordinator performs a sync
    ///
    private init() { }
    
    /// Stores a tracked action to be synced
    ///
    /// - parameters:
    ///     - trackedAction: A tracked action.
    ///
    internal func store(track action: DopeAction) {
        Track.current.add(action)
        self.performSync()
    }
    
    /// Stores a reinforced action to be synced
    ///
    /// - parameters:
    ///     - reportedAction: A reinforced action.
    ///
    internal func store(report action: DopeAction) {
        Report.current.add(action)
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
    
    /// Checks which syncers have been triggered, and syncs them in an order
    /// that allows time for the DopamineAPI to generate cartridges
    ///
    public func performSync() {
        guard !self.syncInProgress else {
            return
        }
        self.syncInProgress = true
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).asyncAfter(deadline: .now() + 5) {
            defer { self.syncInProgress = false }
            
            // since a cartridge might be triggered during the sleep time,
            // lazily check which are triggered
            var someCartridgeToSync: Cartridge?
            for (_, cartridge) in Cartridge.cartridgeSyncers {
                if cartridge.isTriggered() {
                    someCartridgeToSync = cartridge
                    break
                }
            }
            let reportShouldSync = (someCartridgeToSync != nil) || Report.current.isTriggered()
            let trackShouldSync = reportShouldSync || Track.current.isTriggered()
            
            if trackShouldSync {
                var syncCause: String
                if let cartridgeToSync = someCartridgeToSync {
                    syncCause = "Cartridge \(cartridgeToSync.actionID) needs to sync."
                } else if (reportShouldSync) {
                    syncCause = "Report needs to sync."
                } else {
                    syncCause = "Track needs to sync."
                }
                DopeLog.debug("Synchinig because \(syncCause)")
                
                Telemetry.startRecordingSync(cause: syncCause, track: Track.current, report: Report.current, cartridges: Cartridge.cartridgeSyncers)
                var goodProgress = true
                
                Track.current.sync() { status in
                    guard status == 200 || status == 0 else {
                        DopeLog.debug("Track failed during sync. Halting sync.")
                        goodProgress = false
                        Telemetry.stopRecordingSync(successfulSync: false)
                        return
                    }
                }
                
                sleep(1)
                if !goodProgress { return }
                
                if reportShouldSync {
                    Report.current.sync() { status in
                        if status == 0 {
                            DopeLog.debug("Report has nothing to sync")
                        } else if status == 200 {
                            DopeLog.debug("Report successfully synced")
                        } else if status == 406 {
                            DopeLog.debug("Report contained outdated actions. Flushing.")
                            Report.flush()
                        } else {
                            DopeLog.debug("Report failed during sync. Halting sync.")
                            goodProgress = false
                            Telemetry.stopRecordingSync(successfulSync: false)
                        }
                    }
                }
                
                sleep(5)
                if !goodProgress { return }
                
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
    
    /// Modifies the number of reported actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of reported actions to trigger a sync.
    ///
    public func setSizeToSync(forReport size: Int?) {
        Report.current.updateTriggers(timerStartsAt: nil, timerExpiresIn: nil)
    }
    
    /// Erase the sync objects along with their data
    ///
    public func flush() {
        Track.flush()
        Report.flush()
        Cartridge.flush()
    }
}

