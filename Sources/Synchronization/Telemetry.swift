//
//  Telemetry.swift
//  Pods
//
//  Created by Akash Desai on 9/19/16.
//
//

import Foundation
internal class Telemetry {
    
    static let sharedInstance = Telemetry()
    
    static let queue = DispatchQueue(label: "com.usedopamine.dopaminekit.Telemetry")
    
    private static let defaults: UserDefaults = UserDefaults.standard
    private static let syncOverviewsKey = "DopamineSyncOverviews"
    
    private static var currentSyncOverview: SyncOverview?
    
    private init() {    }
    
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
        queue.async {
            var cartridgeTriggers: [String: [String: AnyObject]] = [:]
            for (actionID, cartridge) in cartridges {
                cartridgeTriggers[actionID] = cartridge.toJSONType() as? [String : AnyObject]
            }
            currentSyncOverview = SyncOverview.init(cause: cause, trackTriggers: track.toJSONType() as! [String : AnyObject], reportTriggers: report.toJSONType() as! [String : AnyObject], cartridgeTriggers: cartridgeTriggers)
        }
    }
    
    /// Sets the `syncResponsne` for `Track` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForTrackSync(_ status: Int?, whichStartedAt startedAt: Int64) {
        queue.async {
            if let syncOverview = Telemetry.currentSyncOverview {
                var syncResponse: [String: AnyObject] = [:]
                syncResponse[syncOverview.utcKey] = NSNumber(value: startedAt) as AnyObject
                syncResponse[syncOverview.roundTripTimeKey] = NSNumber(value: Int64(1000*NSDate().timeIntervalSince1970) - startedAt) as AnyObject
                syncResponse[syncOverview.statusKey] = status as AnyObject?
                
                syncOverview.trackTriggers[syncOverview.syncResponseKey] = syncResponse as AnyObject
            }
        }
    }
    
    /// Sets the `syncResponsne` for `Report` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForReportSync(_ status: Int?, whichStartedAt startedAt: Int64) {
        queue.async{
            if let syncOverview = Telemetry.currentSyncOverview {
                var syncResponse: [String: AnyObject] = [:]
                syncResponse[syncOverview.utcKey] = NSNumber(value: startedAt) as AnyObject
                syncResponse[syncOverview.roundTripTimeKey] = NSNumber(value: Int64(1000*NSDate().timeIntervalSince1970) - startedAt) as AnyObject
                syncResponse[syncOverview.statusKey] = status as AnyObject?
                
                syncOverview.reportTriggers[syncOverview.syncResponseKey] = syncResponse as AnyObject
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
    static func setResponseForCartridgeSync(forAction actionID: String, _ status: Int?, whichStartedAt startedAt: Int64) {
        queue.async{
            if let syncOverview = Telemetry.currentSyncOverview {
                var syncResponse: [String: AnyObject] = [:]
                syncResponse[syncOverview.utcKey] = NSNumber(value: startedAt) as AnyObject
                syncResponse[syncOverview.roundTripTimeKey] = NSNumber(value: Int64(1000*NSDate().timeIntervalSince1970) - startedAt) as AnyObject
                syncResponse[syncOverview.statusKey] = status as AnyObject?
                
                syncOverview.cartridgesTriggers[actionID] = [syncOverview.syncResponseKey: syncResponse as AnyObject]
            }
        }
    }
    
    /// Finalizes the current syncOverview object
    ///
    /// - returns:
    ///     An array of the all syncOverviews which have not been sent to the DopamineAPI.
    ///
    static func stopRecordingSync() -> [SyncOverview] {
        var syncOverviewArray: [SyncOverview] = []
        queue.sync {
            if let syncOverview = Telemetry.currentSyncOverview {
                syncOverview.totalSyncTime = Int64(1000*NSDate().timeIntervalSince1970) - syncOverview.utc
                syncOverviewArray.append(syncOverview)
            }
            currentSyncOverview = nil
        }
        return syncOverviewArray
    }
    
}
