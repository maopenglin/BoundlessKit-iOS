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
    
    static let shared = Report()
    
    private let defaults = UserDefaults.standard
    private let defaultsKey = "DopamineReport"
    
    @objc private let customerVersion: String?
    @objc private var reportedActions: [DopeAction]
    @objc private var timerStartedAt: Int64
    @objc private var timerExpiresIn: Int64
    
    private var syncInProgress = false
    
    /// Loads the report from NSUserDefaults or creates a new one and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - sizeToSync: The number of reported actions to trigger a sync. Defaults to 15.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    private init(sizeToSync: Int = 15, timerStartsAt: Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64 = 172800000) {
        if let savedReportData = defaults.object(forKey: defaultsKey) as? Data {
            if let savedReport = NSKeyedUnarchiver.unarchiveObject(with: savedReportData) as? Report,
                savedReport.customerVersion == DopamineVersion.current.versionID
            {
                self.customerVersion = savedReport.customerVersion
                self.reportedActions = savedReport.reportedActions
                self.timerStartedAt = savedReport.timerStartedAt
                self.timerExpiresIn = savedReport.timerExpiresIn
                super.init()
                return
            } else {
                defaults.removeObject(forKey: defaultsKey)
                DopeLog.debug("Erased outdated report.")
            }
        }
        self.customerVersion = DopamineVersion.current.versionID
        self.reportedActions = []
        self.timerStartedAt = timerStartsAt
        self.timerExpiresIn = timerExpiresIn
        super.init()
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Decodes a saved report from NSUserDefaults
    ///
    required init?(coder aDecoder: NSCoder) {
        if let customerVersion = aDecoder.decodeObject(forKey: #keyPath(Report.customerVersion)) as? String?,
            let reportedActions = aDecoder.decodeObject(forKey: #keyPath(Report.reportedActions)) as? [DopeAction] {
            self.customerVersion = customerVersion
            self.reportedActions = reportedActions
            self.timerStartedAt = aDecoder.decodeInt64(forKey: #keyPath(Report.timerStartedAt))
            self.timerExpiresIn = aDecoder.decodeInt64(forKey: #keyPath(Report.timerExpiresIn))
            //        DopeLog.debugLog("Decoded report with reportedActions:\(reportedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
        } else {
            return nil
        }
    }
    
    /// Encodes a report and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(customerVersion, forKey: #keyPath(Report.customerVersion))
        aCoder.encode(reportedActions, forKey: #keyPath(Report.reportedActions))
        aCoder.encode(timerStartedAt, forKey: #keyPath(Report.timerStartedAt))
        aCoder.encode(timerExpiresIn, forKey: #keyPath(Report.timerExpiresIn))
        //        DopeLog.debugLog("Encoded report with reportedActions:\(reportedActions.count) sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Updates the sync triggers
    ///
    /// - parameters:
    ///     - sizeToSync: The number of reported actions to trigger a sync. Defaults to previous sizeToSync.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to the current time.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to previous timerExpiresIn.
    ///
    func updateTriggers(timerStartsAt: Int64? = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64? = nil) {
        if let timerStartsAt = timerStartsAt {
            self.timerStartedAt = timerStartsAt
        }
        if let timerExpiresIn = timerExpiresIn {
            self.timerExpiresIn = timerExpiresIn
        }
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Clears the saved report sync triggers from NSUserDefaults
    ///
    func erase() {
        self.reportedActions.removeAll()
        self.timerStartedAt = Int64( 1000*NSDate().timeIntervalSince1970 )
        self.timerExpiresIn = 172800000
        defaults.removeObject(forKey: defaultsKey)
    }
    
    /// Check whether the report has been triggered for a sync
    ///
    /// - returns: Whether a sync has been triggered.
    ///
    func isTriggered() -> Bool {
        return timerDidExpire() || batchIsFull()
    }
    
    /// Checks if the sync timer has expired
    ///
    /// - returns: Whether the timer has expired.
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartedAt + timerExpiresIn)
        //        DopeLog.debugLog("Report timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so the timer \(isExpired ? "will" : "won't") trigger a sync...")
        return isExpired
    }
    
    /// Checks if the report is at the size to sync
    ///
    /// - returns: Whether there are enough reported actions to trigger a sync.
    ///
    private func batchIsFull() -> Bool {
        let count = reportedActions.count
        let isBatchSizeReached = count >= DopamineConfiguration.current.reportBatchSize
        //        DopeLog.debugLog("Report has \(count)/\(sizeToSync) actions so the size \(isSize ? "will" : "won't") trigger a sync...")
        return isBatchSizeReached
    }
    
    /// Stores a reported action to be synced over the DopamineAPI at a later time
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    func add(action: DopeAction) {
        reportedActions.append(action)
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self), forKey: defaultsKey)
    }
    
    /// Sends reinforced actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): Takes the status code returned from DopamineAPI, or 0 if there were no actions to sync.
    ///
    func sync(completion: @escaping (_ statusCode: Int) -> () = { _ in }) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
            guard !self.syncInProgress else {
                completion(0)
                return
            }
            self.syncInProgress = true
            
            if self.reportedActions.count == 0 {
                defer { self.syncInProgress = false }
                DopeLog.debug("No reported actions to sync.")
                completion(0)
                self.updateTriggers()
            } else {
                DopeLog.debug("Sending \(self.reportedActions.count) reported actions...")
                DopamineAPI.report(self.reportedActions, completion: { response in
                    defer { self.syncInProgress = false }
                    if let responseStatusCode = response["status"] as? Int {
                        if responseStatusCode == 200 { //TO-DO: account for 406 - check respond w/ ramsay
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
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject["size"] = NSNumber(value: reportedActions.count)
        jsonObject[#keyPath(Report.timerStartedAt)] = NSNumber(value: timerStartedAt)
        jsonObject[#keyPath(Report.timerExpiresIn)] = NSNumber(value: timerExpiresIn)
        
        return jsonObject
    }
}

