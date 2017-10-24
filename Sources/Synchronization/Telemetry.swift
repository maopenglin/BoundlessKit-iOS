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
    
    private static let queue = DispatchQueue(label: "com.usedopamine.dopaminekit.Telemetry")
    
    private static let defaults: UserDefaults = UserDefaults.standard
    private static let syncOverviewsKey = "DopamineSyncOverviews"
    private static let dopeExceptionsKey = "DopamineDopeExceptions"
    
    private static var currentSyncOverview: SyncOverview?
    private static var syncOverviews: [SyncOverview] {
        get{
            if let savedOverviewsData = defaults.object(forKey: syncOverviewsKey) as? NSData,
                let savedOverviews = NSKeyedUnarchiver.unarchiveObject(with: savedOverviewsData as Data) as? [SyncOverview] {
                return savedOverviews
            } else {
                return []
            }
        }
        set(newArray) {
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: newArray), forKey: syncOverviewsKey)
        }
    }
    private static var dopeExceptions: [DopeException] {
        get{
            if let savedDopeExceptionsData = defaults.object(forKey: dopeExceptionsKey) as? NSData,
                let savedDopeExceptions = NSKeyedUnarchiver.unarchiveObject(with: savedDopeExceptionsData as Data) as? [DopeException] {
                return savedDopeExceptions
            } else {
                return []
            }
        }
        set(newArray) {
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: newArray), forKey: dopeExceptionsKey)
        }
    }
    
    private init() {    }
    
    
    
    
    /// Creates a DopeException object and reports it to DopamineAPI for increased stability
    ///
    /// - parameters:
    ///     - className: The class name for the exception or error.
    ///     - message: The message for the exception or error, including parameter values.
    ///     - dataDescription: A description of the data that caused the exception or error, if relevant. Defaults to `nil`.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to `#file`.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///
    static func storeException( className: String, message: String, dataDescription: String?=nil, filePath: String = #file, function: String = #function) {
        queue.async {
            var exceptionMessage = message
            if let dataDescription = dataDescription {
                exceptionMessage.append("\nDataDescription:\(dataDescription)")
            }
            var stackTrace = Thread.callStackSymbols
            stackTrace[0] = "0\t\(NSString(string: filePath).lastPathComponent)\t\t\t\t\t\(function)"
            let exception = DopeException.init(exceptionClassName: className, message: exceptionMessage, stackTrace: stackTrace.joined(separator: "\n"))
            
            var currentExceptionsArray = dopeExceptions
            currentExceptionsArray.append(exception)
            dopeExceptions = currentExceptionsArray
        }
    }
    
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
            var cartridgeTriggers: [String: [String: Any]] = [:]
            for (actionID, cartridge) in cartridges {
                cartridgeTriggers[actionID] = cartridge.toJSONType()
            }
            currentSyncOverview = SyncOverview.init(cause: cause, trackTriggers: track.toJSONType(), reportTriggers: report.toJSONType(), cartridgeTriggers: cartridgeTriggers)
        }
    }
    
    /// Sets the `syncResponse` for `Track` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - error: An error if one was received.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForTrackSync(_ status: Int, error: String?=nil, whichStartedAt startedAt: Int64) {
        queue.async {
            if let syncOverview = Telemetry.currentSyncOverview {
                var syncResponse: [String: Any] = [:]
                syncResponse[SyncOverview.utcKey] = NSNumber(value: startedAt)
                syncResponse[SyncOverview.roundTripTimeKey] = NSNumber(value: Int64(1000*NSDate().timeIntervalSince1970) - startedAt)
                syncResponse[SyncOverview.statusKey] = status
                syncResponse[SyncOverview.errorKey] = error
                
                syncOverview.trackTriggers[SyncOverview.syncResponseKey] = syncResponse
            } else {
                DopamineKit.debugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Sets the `syncResponse` for `Report` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - error: An error if one was received.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForReportSync(_ status: Int, error: String?=nil, whichStartedAt startedAt: Int64) {
        queue.async{
            if let syncOverview = Telemetry.currentSyncOverview {
                var syncResponse: [String: Any] = [:]
                syncResponse[SyncOverview.utcKey] = NSNumber(value: startedAt)
                syncResponse[SyncOverview.roundTripTimeKey] = NSNumber(value: Int64(1000*NSDate().timeIntervalSince1970) - startedAt)
                syncResponse[SyncOverview.statusKey] = status
                syncResponse[SyncOverview.errorKey] = error
                
                syncOverview.reportTriggers[SyncOverview.syncResponseKey] = syncResponse
            } else {
                DopamineKit.debugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Sets the `syncResponse` for the cartridge in the current sync overview
    ///
    /// - parameters:
    ///     - actionID: The name of the cartridge's action.
    ///     - status: The HTTP status code received from the DopamineAPI.
    ///     - error: An error if one was received.
    ///     - startedAt: The time the API call started at.
    ///
    static func setResponseForCartridgeSync(forAction actionID: String, _ status: Int, error: String?=nil, whichStartedAt startedAt: Int64) {
        queue.async{
            if let syncOverview = Telemetry.currentSyncOverview {
                var syncResponse: [String: Any] = [:]
                syncResponse[SyncOverview.utcKey] = NSNumber(value: startedAt)
                syncResponse[SyncOverview.roundTripTimeKey] = NSNumber(value: Int64(1000*NSDate().timeIntervalSince1970) - startedAt)
                syncResponse[SyncOverview.statusKey] = status
                syncResponse[SyncOverview.errorKey] = error
                
                if var cartridge = syncOverview.cartridgesTriggers[actionID] {
                    cartridge[SyncOverview.syncResponseKey] = syncResponse
                    syncOverview.cartridgesTriggers[actionID] = cartridge
                }
            } else {
                DopamineKit.debugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Finalizes the current syncOverview object
    ///
    /// - parameters:
    ///     - successfulSync: Whether a successful sync was made with the DopamineAPI.
    ///
    static func stopRecordingSync(successfulSync: Bool) {
        queue.async {
            var syncOverviewArray: [SyncOverview] = syncOverviews
            if let syncOverview = Telemetry.currentSyncOverview {
                syncOverview.totalSyncTime = Int64(1000*NSDate().timeIntervalSince1970) - syncOverview.utc
                syncOverviewArray.append(syncOverview)
                currentSyncOverview = nil
                DopamineKit.debugLog("Saved a sync overview, totaling \(syncOverviewArray.count) overviews - \n\(syncOverview.toJSONType())")
            } else {
                DopamineKit.debugLog("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
            
            if(successfulSync) {
                DopamineAPI.sync(syncOverviews: syncOverviewArray, dopeExceptions: dopeExceptions, completion: { response in
                    queue.async {
                        if response["status"] as? Int == 200 {
                            syncOverviews = []
                            dopeExceptions = []
                            DopamineKit.debugLog("Cleared sync overview array and dope exceptions array.")
                        } else {
                            syncOverviews = syncOverviewArray
                        }
                    }
                })
            } else {
                syncOverviews = syncOverviewArray
            }
        }
    }
    
}
