//
//  Telemetry.swift
//  Pods
//
//  Created by Akash Desai on 9/26/16.
//
//

import Foundation



internal class Telemetry : NSObject {
    
    static let sharedInstance = Telemetry()
    
    private let queue = dispatch_queue_create("com.usedopamine.dopaminekit.Synchronization.Telemetry", nil)
    
    private var currentSyncOverview: SyncOverview?
    
    private var syncInProgress = false
    
    /// Creates a SyncOverview object to record to sync performance and take a snapshot of the syncers.
    /// Use the functions setResponseForTrackSync(), setResponseForReportSync(), and setResponseForCartridgeSync()
    /// to record progress throughout the synchornization.
    /// Use stopRecordingSync() to finalize the recording
    ///
    /// - parameters:
    ///     - cause: The reason the synchronization process has been triggered.
    ///     - track: The Track object to snapshot its triggers.
    ///     - report: The Report object to snapshot its triggers.
    ///     - cartridges: The cartridges dictionary to snapshot its triggers
    ///
    static func startRecordingSync(cause: String, track: Track, report: Report, cartridges: [String: Cartridge]) {
        dispatch_async(sharedInstance.queue) {
            var cartridgeTriggers: [String: [String: AnyObject]] = [:]
            for (actionID, cartridge) in cartridges {
                cartridgeTriggers[actionID] = cartridge.decodeJSONForTriggers()
            }
            sharedInstance.currentSyncOverview = SyncOverview(cause: cause, trackTriggers: track.decodeJSONForTriggers(), reportTriggers: report.decodeJSONForTriggers(), cartridgeTriggers: cartridgeTriggers)
        }
    }
    
    /// Sets the `syncResponsne` for `Track` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForTrackSync(status: Int, error: String?=nil, whichStartedAt startedAt: Int64) {
        dispatch_async(sharedInstance.queue) {
            if let syncOverview = sharedInstance.currentSyncOverview {
                let syncResponse = SyncOverview.SyncResponse(startTime: startedAt, status: status, error: error)
                
                syncOverview.track[SyncOverview.syncResponseKey] = syncResponse.toJSONType()
            } else {
                DopamineKit.DebugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Sets the `syncResponsne` for `Report` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForReportSync(status: Int, error: String?=nil, whichStartedAt startedAt: Int64) {
        dispatch_async(sharedInstance.queue) {
            if let syncOverview = sharedInstance.currentSyncOverview {
                let syncResponse = SyncOverview.SyncResponse(startTime: startedAt, status: status, error: error)
                
                syncOverview.report[SyncOverview.syncResponseKey] = syncResponse.toJSONType()
            } else {
                DopamineKit.DebugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Sets the `syncResponsne` for the cartridge in the current sync overview
    ///
    /// - parameters:
    ///     - actionID: The name of the cartridge's action.
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForCartridgeSync(forAction actionID: String, _ status: Int, error: String?=nil, whichStartedAt startedAt: Int64) {
        dispatch_async(sharedInstance.queue) {
            if let syncOverview = sharedInstance.currentSyncOverview {
                let syncResponse = SyncOverview.SyncResponse(startTime: startedAt, status: status, error: error)
                if let _ = syncOverview.cartridges[actionID] {
                    syncOverview.cartridges[actionID]![SyncOverview.syncResponseKey] = syncResponse.toJSONType()
                } else {
                    syncOverview.cartridges[actionID] = [SyncOverview.syncResponseKey: syncResponse.toJSONType(), "actionID": actionID]
                }
            } else {
                DopamineKit.DebugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Finalizes the current syncOverview object. If it is known an internet connection is not available, 
    /// the futile attempt can be avoided by passing in the value False
    ///
    /// - parameters:
    ///     - shouldSend: Whether the syncOverview should be synced to the DopamineAPI, or stored to be sent later
    ///
    static func stopRecordingSync(andSendOverview shouldSend: Bool) {
        dispatch_async(sharedInstance.queue) {
            if let syncOverview = sharedInstance.currentSyncOverview {
                syncOverview.totalSyncTime = Int64(1000*NSDate().timeIntervalSince1970) - syncOverview.utc
                syncOverview.store()
                sharedInstance.currentSyncOverview = nil
            } else {
                DopamineKit.DebugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
            
            if(shouldSend && !sharedInstance.syncInProgress) {
                sharedInstance.syncInProgress = true
                let sqlSyncOverviews = SQLSyncOverviewDataHelper.findAll()
                let sqlDopeExceptions = SQLDopeExceptionDataHelper.findAll()
                DopamineKit.DebugLog("Sending \(sqlSyncOverviews.count) sync overviews and \(sqlDopeExceptions.count) dopamine exceptions...")
                DopamineAPI.sync(sqlSyncOverviews, dopeExceptions: sqlDopeExceptions, completion: { response in
                    dispatch_async(sharedInstance.queue) {
                        defer {sharedInstance.syncInProgress = false}
                        if response["status"] as? Int == 200 {
                            for syncOverview in sqlSyncOverviews {
                                SQLSyncOverviewDataHelper.delete(syncOverview)
                            }
                            for dopeException in sqlDopeExceptions {
                                SQLDopeExceptionDataHelper.delete(dopeException)
                            }
                            DopamineKit.DebugLog("Cleared sync overview array and dope exceptions array.")
                        }
                    }
                })
            }
        }
    }
    
}
