//
//  SyncCoordinator.swift
//  Pods
//
//  Created by Akash Desai on 7/31/16.
//
//

import Foundation

public class SyncCoordinator {
    
    internal static let sharedInstance = SyncCoordinator()
    
    /// Used to store actionIDs so cartridges can be loaded on init()
    ///
    private let defaults = UserDefaults.standard
    private let cartridgeActionIDSetKey = "DopamineReinforceableActionIDSet"
    
    private let trackSyncer = Track.sharedInstance
    private let reportSyncer = Report.sharedInstance
    private var cartridgeSyncers:[String:Cartridge] = [:]
    
    private var syncInProgress = false
    
    /// Initializer for SyncCoordinator performs a sync
    ///
    private init() {
        if let savedActionIDSetData = defaults.object(forKey: cartridgeActionIDSetKey) as? [String] {
            for actionID in savedActionIDSetData {
                cartridgeSyncers[actionID] = Cartridge(actionID: actionID)
            }
        }
        self.setSizeToSync(forTrack: 3)
        performSync()
    }
    
    /// Stores a tracked action to be synced
    ///
    /// - parameters: 
    ///     - trackedAction: A tracked action.
    ///
    internal func store(trackedAction: DopeAction) {
        trackSyncer.add(action: trackedAction)
        performSync()
    }
    
    /// Stores a reinforced action to be synced
    ///
    /// - parameters:
    ///     - reportedAction: A reinforced action.
    ///
    internal func store(reportedAction: DopeAction) {
        reportSyncer.add(action: reportedAction)
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
    internal func retrieveReinforcementDecisionFor(actionID: String) -> String {
        if let cartridge = cartridgeSyncers[actionID] {
            return cartridge.remove()
        } else {
            let cartridge = Cartridge(actionID: actionID)
            cartridgeSyncers[actionID] = cartridge
            defaults.set(cartridgeSyncers.keys.sorted(), forKey: cartridgeActionIDSetKey)
            return cartridge.remove()
        }
    }
    
    /// Checks which syners have been triggered, and syncs them in an order 
    /// that allows time for the DopamineAPI to generate cartridges
    ///
    public func performSync() {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
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
            
            var goodProgress = true
            
            if trackShouldSync {
                var syncCause: String
                if let cartridgeToSync = someCartridgeToSync {
                    syncCause = "Cartridge \(cartridgeToSync.actionName()) needs to sync."
                } else if (reportShouldSync) {
                    syncCause = "Report needs to sync."
                } else {
                    syncCause = "Track needs to sync."
                }
                Telemetry.startRecordingSync(cause: syncCause, track: self.trackSyncer, report: self.reportSyncer, cartridges: self.cartridgeSyncers)
//                var callStartTime = Int64(NSDate()
                self.trackSyncer.sync() { status in
                    guard status == 200 || status == 0 else {
                        DopamineKit.DebugLog("Track failed during sync. Halting sync.")
                        goodProgress = false
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
                            return
                        }
                    }
                }
                
                sleep(5)
                if !goodProgress { return }
                
                // since a cartridge might be triggered during the sleep time,
                // lazily check which are triggered
                for (actionID, cartridge) in self.cartridgeSyncers where goodProgress && cartridge.isTriggered() {
//                    let startTime = Int64( NSDate().timeIntervalSince1970*1000 )
                    cartridge.sync() { status in
//                        Telemetry.setResponseForCartridgeSync(forAction: actionID, status, whichStartedAt: startTime)
                        guard status == 200 else {
                            DopamineKit.DebugLog("Refresh for \(actionID) failed during sync. Halting sync.")
                            goodProgress = false
                            return
                        }
                    }
                }
                sleep(3)
                if goodProgress {
                    let syncOverviews = Telemetry.stopRecordingSync()
                    DopamineAPI.sync(syncOverviews, completion: {
                        _ in
                    })
                }
            }
        }
    }
    
    /// Modifies the number of tracked actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of tracked actions to trigger a sync.
    ///
    public func setSizeToSync(forTrack size: Int?) {
        trackSyncer.updateTriggers(sizeToSync: size, timerStartsAt: nil, timerExpiresIn: nil)
    }
    
    /// Modifies the number of reported actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of reported actions to trigger a sync.
    ///
    public func setSizeToSync(forReport size: Int?) {
        reportSyncer.updateTriggers(sizeToSync: size, timerStartsAt: nil, timerExpiresIn: nil)
    }
    
    /// Erase the sync objects along with their data
    ///
    public func eraseSyncers() {
        trackSyncer.erase()
        reportSyncer.erase()
        for (_, cartridge) in cartridgeSyncers {
            cartridge.erase()
        }
        cartridgeSyncers.removeAll()
        defaults.removeObject(forKey: cartridgeActionIDSetKey)
    }
}
