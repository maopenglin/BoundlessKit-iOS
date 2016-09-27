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
    
    /// Used to store actionIDs so cartridges can be loaded on init()
    ///
    private let defaultsReinforcableActionIDSetKey = "DopamineReinforceableActionIDSet"
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    private let trackSyncer = Track.sharedInstance
    private let reportSyncer = Report.sharedInstance
    private var cartridgeSyncers:[String:Cartridge] = [:]
    
    private var syncInProgress = false
    
    /// Initializer for SyncCoordinator performs a sync
    ///
    private init() {
        if let savedActionIDSetData = defaults.objectForKey(defaultsReinforcableActionIDSetKey) as? [String] {
            for actionID in savedActionIDSetData {
                cartridgeSyncers[actionID] = Cartridge(actionID: actionID)
            }
        }
        performSync()
    }
    
    /// Stores a tracked action to be synced
    ///
    /// - parameters: 
    ///     - trackedAction: A tracked action.
    ///
    func storeTrackedAction(trackedAction: DopeAction) {
        trackSyncer.add(trackedAction)
        performSync()
    }
    
    /// Stores a reinforced action to be synced
    ///
    /// - parameters:
    ///     - reportedAction: A reinforced action.
    ///
    func storeReportedAction(reportedAction: DopeAction) {
        reportSyncer.add(reportedAction)
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
    func retrieveReinforcementDecisionFor(actionID: String) -> String {
        if let cartridge = cartridgeSyncers[actionID] {
            return cartridge.remove()
        } else {
            let cartridge = Cartridge(actionID: actionID)
            cartridgeSyncers[actionID] = cartridge
            defaults.setObject(cartridgeSyncers.keys.sort(), forKey: defaultsReinforcableActionIDSetKey)
            return cartridge.remove()
        }
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
            
            // since a cartridge might be triggered during the sleep time,
            // lazily check which are triggered
            var someCartridgeToSync: Cartridge?
            for (_, cartridge) in self.cartridgeSyncers {
                if cartridge.isTriggered() {
                    someCartridgeToSync = cartridge
                    break
                }
            }
            let reportShouldSync = (someCartridgeToSync != nil) || self.reportSyncer.isTriggered()
            let trackShouldSync = reportShouldSync || self.trackSyncer.isTriggered()
            
            if trackShouldSync {
                var syncCause = "No sync necessary."
                if let cartridgeToSync = someCartridgeToSync {
                    syncCause = "Cartridge \(cartridgeToSync.actionID) needs to sync."
                } else if (reportShouldSync) {
                    syncCause = "Report needs to sync."
                } else if (trackShouldSync) {
                    syncCause = "Track needs to sync."
                } else {
                    return
                }
                Telemetry.startRecordingSync(syncCause, track: self.trackSyncer, report: self.reportSyncer, cartridges: self.cartridgeSyncers)
                
                var goodProgress = true
                
                self.trackSyncer.sync() { status in
                    guard status == 200 || status == 0 else {
                        DopamineKit.DebugLog("Track failed during sync. Halting sync.")
                        goodProgress = false
                        Telemetry.stopRecordingSync(andSendOverview: false)
                        return
                    }
                }
                
                sleep(1)
                if !goodProgress { return }
                
                if reportShouldSync {
                    self.reportSyncer.sync() { status in
                        guard status == 200 || status == 0 else {
                            DopamineKit.DebugLog("Report failed during sync. Halting sync.")
                            goodProgress = false
                            Telemetry.stopRecordingSync(andSendOverview: false)
                            return
                        }
                    }
                }
                
                sleep(5)
                if !goodProgress { return }
                
                // since a cartridge might be triggered during the sleep time,
                // lazily check which are triggered
                for (actionID, cartridge) in self.cartridgeSyncers where cartridge.isTriggered() {
                    cartridge.sync() { status in
                        guard status == 200 else {
                            DopamineKit.DebugLog("Refresh for \(actionID) failed during sync. Halting sync.")
                            goodProgress = false
                            Telemetry.stopRecordingSync(andSendOverview: false)
                            return
                        }
                    }
                }
                
                sleep(3)
                if !goodProgress { return }
                
                Telemetry.stopRecordingSync(andSendOverview: true)
            }
        }
    }
    
    /// Modifies the number of tracked actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of tracked actions to trigger a sync.
    ///
    public func setTrackSizeToSync(size: Int?) {
        trackSyncer.updateTriggers(size, timerStartsAt: nil, timerExpiresIn: nil)
    }
    
    /// Modifies the number of reported actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of reported actions to trigger a sync.
    ///
    public func setReportSizeToSync(size: Int?) {
        reportSyncer.updateTriggers(size, timerStartsAt: nil, timerExpiresIn: nil)
    }
    
    /// Resets the sync triggers
    ///
    public func resetSyncers() {
        trackSyncer.removeTriggers()
        reportSyncer.removeTriggers()
        for (_, cartridge) in cartridgeSyncers {
            cartridge.removeTriggers()
        }
        cartridgeSyncers.removeAll()
        defaults.removeObjectForKey(defaultsReinforcableActionIDSetKey)
    }
}
