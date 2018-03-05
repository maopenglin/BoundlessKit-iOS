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
    
    private static let queue = DispatchQueue(label: "com.boundlessmind.boundlesskit.Telemetry")
    
    private static let defaults: UserDefaults = UserDefaults.standard
    private static let syncOverviewsKey = "Telemetry.SyncOverviews"
    private static let exceptionsKey = "Telemetry.Exceptions"
    
    private static var currentSyncOverview: SyncOverview?
    private static var syncOverviews: [SyncOverview] {
        get{
            if let savedOverviewsData = defaults.object(forKey: syncOverviewsKey) as? Data,
                let savedOverviews = NSKeyedUnarchiver.unarchiveObject(with: savedOverviewsData) as? [SyncOverview] {
                return savedOverviews
            } else {
                return []
            }
        }
        set {
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: syncOverviewsKey)
        }
    }
    private static var exceptions: [BoundlessException] {
        get{
            if let savedExceptionsData = defaults.object(forKey: exceptionsKey) as? Data,
                let savedExceptions = NSKeyedUnarchiver.unarchiveObject(with: savedExceptionsData) as? [BoundlessException] {
                return savedExceptions
            } else {
                return []
            }
        }
        set {
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: exceptionsKey)
        }
    }
    
    private init() {    }
    
    
    
    
    /// Creates a BoundlessException object and reports it to BoundlessAI for increased stability
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
            let exception = BoundlessException.init(exceptionClassName: className, message: exceptionMessage, stackTrace: stackTrace.joined(separator: "\n"))
            
            var currentExceptionsArray = exceptions
            currentExceptionsArray.append(exception)
            exceptions = currentExceptionsArray
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
    static func startRecordingSync(cause: String) {
        queue.async {
            var cartridgeTriggers: [String: [String: Any]] = [:]
            for (actionID, cartridge) in Cartridge.cartridgeSyncers {
                cartridgeTriggers[actionID] = cartridge.toJSONType()
            }
            currentSyncOverview = SyncOverview.init(cause: cause, trackTriggers: Track.current.toJSONType(), reportTriggers: Report.current.toJSONType(), cartridgeTriggers: cartridgeTriggers)
        }
    }
    
    /// Sets the `syncResponse` for `Track` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code.
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
                BoundlessLog.debug("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Sets the `syncResponse` for `Report` in the current sync overview
    ///
    /// - parameters:
    ///     - status: The HTTP status code.
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
                BoundlessLog.debug("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Sets the `syncResponse` for the cartridge in the current sync overview
    ///
    /// - parameters:
    ///     - actionID: The name of the cartridge's action.
    ///     - status: The HTTP status code.
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
                BoundlessLog.debug("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
        }
    }
    
    /// Finalizes the current syncOverview object
    ///
    /// - parameters:
    ///     - successfulSync: Whether a successful sync was performed.
    ///
    static func stopRecordingSync(successfulSync: Bool) {
        queue.async {
            var syncOverviewArray: [SyncOverview] = syncOverviews
            if let syncOverview = Telemetry.currentSyncOverview {
                syncOverview.totalSyncTime = Int64(1000*NSDate().timeIntervalSince1970) - syncOverview.utc
                syncOverviewArray.append(syncOverview)
                currentSyncOverview = nil
//                BoundlessLog.debugLog("Saved a sync overview, totaling \(syncOverviewArray.count) overviews - \n\(syncOverview.toJSONType())")
            } else {
                BoundlessLog.debug("No recording has started. Did you rememeber to execute startRecordingSync() at the beginning of the sync performance?")
            }
            
            if(successfulSync) {
                BoundlessAPI.sync(syncOverviews: syncOverviewArray, exceptions: exceptions, completion: { response in
                    queue.async {
                        if response["status"] as? Int == 200 {
                            syncOverviews = []
                            exceptions = []
                            BoundlessLog.debug("Cleared sync overview array and exceptions array.")
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
