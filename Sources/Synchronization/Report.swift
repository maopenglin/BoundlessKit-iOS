//
//  Report.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
internal class Report : NSObject, NSCoding {
    
    @objc static let sharedInstance = Report()
    
    private let defaults = UserDefaults.standard
    private let defaultsKey = "DopamineReport_v4.1.3"
    private let reportedActionsKey = "reportedActions"
    private let sizeToSyncKey = "sizeToSync"
    private let timerStartsAtKey = "timerStartsAt"
    private let timerExpiresInKey = "timerExpiresIn"
    
    private var reportedActions: [DopeAction] = []
    private var sizeToSync: Int
    private var timerStartsAt: Int64
    private var timerExpiresIn: Int64
    
    private var syncInProgress = false
    
    /// Loads the report from NSUserDefaults or creates a new one and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - sizeToSync: The number of reported actions to trigger a sync. Defaults to 15.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    private init(sizeToSync: Int = 15, timerStartsAt: Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64 = 172800000) {
        if let savedReportData = defaults.object(forKey: defaultsKey) as? NSData,
            let savedReport = NSKeyedUnarchiver.unarchiveObject(with: savedReportData as Data) as? Report {
            self.reportedActions = savedReport.reportedActions
            self.sizeToSync = savedReport.sizeToSync
            self.timerStartsAt = savedReport.timerStartsAt
            self.timerExpiresIn = savedReport.timerExpiresIn
            super.init()
        } else {
            self.sizeToSync = sizeToSync;
            self.timerStartsAt = timerStartsAt;
            self.timerExpiresIn = timerExpiresIn;
            super.init()
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
        }
    }
    
    /// Decodes a saved report from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.reportedActions = aDecoder.decodeObject(forKey: reportedActionsKey) as! [DopeAction]
        self.sizeToSync = aDecoder.decodeInteger(forKey: sizeToSyncKey)
        self.timerStartsAt = aDecoder.decodeInt64(forKey: timerStartsAtKey)
        self.timerExpiresIn = aDecoder.decodeInt64(forKey: timerExpiresInKey)
//        DopamineKit.debugLog("Decoded report with reportedActions:\(reportedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a report and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(reportedActions, forKey: reportedActionsKey)
        aCoder.encode(sizeToSync, forKey: sizeToSyncKey)
        aCoder.encode(timerStartsAt, forKey: timerStartsAtKey)
        aCoder.encode(timerExpiresIn, forKey: timerExpiresInKey)
//        DopamineKit.debugLog("Encoded report with reportedActions:\(reportedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }

    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - sizeToSync: The number of reported actions to trigger a sync. Defaults to previous sizeToSync.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to previous timerExpiresIn.
    ///
    func updateTriggers(sizeToSync: Int?=nil, timerStartsAt: Int64?=Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64?=nil) {
        if let sizeToSync = sizeToSync {
            self.sizeToSync = sizeToSync
        }
        if let timerStartsAt = timerStartsAt {
            self.timerStartsAt = timerStartsAt
        }
        if let timerExpiresIn = timerExpiresIn {
            self.timerExpiresIn = timerExpiresIn
        }
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Clears the saved report sync triggers from NSUserDefaults
    ///
    @objc func erase() {
        self.reportedActions.removeAll()
        self.sizeToSync = 15
        self.timerStartsAt = Int64( 1000*NSDate().timeIntervalSince1970 )
        self.timerExpiresIn = 172800000
        defaults.removeObject(forKey: defaultsKey)
    }
    
    /// Check whether the report has been triggered for a sync
    ///
    /// - returns: Whether a sync has been triggered.
    ///
    @objc func isTriggered() -> Bool {
        return timerDidExpire() || isSizeToSync()
    }
    
    /// Checks if the sync timer has expired
    ///
    /// - returns: Whether the timer has expired.
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
//        DopamineKit.debugLog("Report timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so the timer \(isExpired ? "will" : "won't") trigger a sync...")
        return isExpired
    }
    
    /// Checks if the report is at the size to sync
    ///
    /// - returns: Whether there are enough reported actions to trigger a sync.
    ///
    private func isSizeToSync() -> Bool {
        let count = reportedActions.count
        let isSize = count >= sizeToSync
//        DopamineKit.debugLog("Report has \(count)/\(sizeToSync) actions so the size \(isSize ? "will" : "won't") trigger a sync...")
        return isSize
    }
    
    /// Stores a reported action to be synced over the DopamineAPI at a later time
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    @objc func add(action: DopeAction) {
        reportedActions.append(action)
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Sends reinforced actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if there were no actions to sync.
    ///
    @objc func sync(completion: @escaping (_ statusCode: Int) -> () = { _ in }) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
            guard !self.syncInProgress else {
                DopamineKit.debugLog("Report sync already happening")
                completion(0)
                return
            }
            self.syncInProgress = true
            
            if self.reportedActions.count == 0 {
                defer { self.syncInProgress = false }
                DopamineKit.debugLog("No reported actions to sync.")
                completion(0)
                self.updateTriggers()
            } else {
                DopamineKit.debugLog("Sending \(self.reportedActions.count) reported actions...")
                DopamineAPI.report(self.reportedActions, completion: { response in
                    defer { self.syncInProgress = false }
                    if let responseStatusCode = response["status"] as? Int {
                        if responseStatusCode == 200 {
                            self.reportedActions.removeAll()
                            self.updateTriggers()
                        }
                        completion(responseStatusCode)
                    } else {
                        completion(404)
                    }
                })
            }
            
        }
    }
    
    /// This function returns a snapshot of this instance as a JSON compatible Object
    ///
    @objc func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["size"] = NSNumber(value: reportedActions.count)
        jsonObject[sizeToSyncKey] = NSNumber(value: sizeToSync)
        jsonObject[timerStartsAtKey] = NSNumber(value: timerStartsAt)
        jsonObject[timerExpiresInKey] = NSNumber(value: timerExpiresIn)
        
        return jsonObject
    }
}
