//
//  Report.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
internal class Report : UserDefaultsSingleton {
    
    fileprivate static var _current: Report? =  { return UserDefaults.dopamine.unarchive() }()
    {
        didSet {
            UserDefaults.dopamine.archive(_current)
        }
    }
    static var current: Report {
        get {
            if let _ = _current {
            } else {
                _current = Report()
            }
            
            return _current!
        }
    }
    
    static func flush() {
        _current = Report()
    }
    
    func clean() {
        reportedActions.removeAll()
        updateTriggers()
    }
    
    @objc private let versionID: String?
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
    private init(versionID: String? = DopamineVersion.current.versionID, reportedActions: [DopeAction] = [], timerStartsAt: Int64 = Int64( 1000*NSDate().timeIntervalSince1970 ), timerExpiresIn: Int64 = 172800000) {
        self.versionID = versionID
        self.reportedActions = reportedActions
        self.timerStartedAt = timerStartsAt
        self.timerExpiresIn = timerExpiresIn
        super.init()
    }
    
    /// Decodes a saved report from NSUserDefaults
    ///
    required convenience init?(coder aDecoder: NSCoder) {
        if let versionID = aDecoder.decodeObject(forKey: #keyPath(Report.versionID)) as? String?,
            let reportedActions = aDecoder.decodeObject(forKey: #keyPath(Report.reportedActions)) as? [DopeAction] {
            self.init(versionID: versionID,
                      reportedActions: reportedActions,
                      timerStartsAt: aDecoder.decodeInt64(forKey: #keyPath(Report.timerStartedAt)),
                      timerExpiresIn: aDecoder.decodeInt64(forKey: #keyPath(Report.timerExpiresIn))
            )
//            DopeLog.debug("Decoded report with versionID:\(versionID ?? "nil") reportedActions:\(reportedActions.count) sizeToSync:\(DopamineConfiguration.current.reportBatchSize) timerStartsAt:\(timerStartedAt) timerExpiresIn:\(timerExpiresIn)")
        } else {
            return nil
        }
    }
    
    /// Encodes a report and saves it to NSUserDefaults
    ///
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(versionID, forKey: #keyPath(Report.versionID))
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
        Report._current = self
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
    var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    func add(_ action: DopeAction) {
        operationQueue.addOperation {
            if DopamineConfiguration.current.locationObservations {
                DopeLocation.shared.getLocation(callback: { location in
                    self.operationQueue.addOperation {
                        if let location = location {
                            action.addMetaData(location)
                        }
                        if let ssid = DopeInfo.mySSID {
                            action.addMetaData(["ssid": ssid])
                        }
                        self.reportedActions.append(action)
                        if self.operationQueue.operationCount == 1 {
                            Report._current = self
                        }
                    }
                })
            }
        }
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
//                DopeLog.debug("No reported actions to sync.")
                completion(0)
                self.updateTriggers()
            } else {
//                DopeLog.debug("Sending \(self.reportedActions.count) reported actions...")
                DopamineAPI.report(self.reportedActions, completion: { response in
                    defer { self.syncInProgress = false }
                    if let status = response["status"] as? Int {
                        if status == 200 {
                            self.clean()
                        } else if status == 400 {
                            Report.flush()
                        }
                        completion(status)
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

