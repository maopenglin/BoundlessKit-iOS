//
//  Report.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
class Report : NSObject, NSCoding {
    
    static let sharedInstance = Report()
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let defaultsKey = "DopamineReport"
    private let defaultsSizeToSync = "sizeToSync"
    private let defaultsTimerStartsAt = "timerStartsAt"
    private let defaultsTimerExpiresIn = "timerExpiresIn"
    
    private var sizeToSync: Int
    private var timerStartsAt: Int64
    private var timerExpiresIn: Int64
    
    /// Loads the report from NSUserDefaults or creates a new one and saves it to NSUserDefaults
    ///
    /// - parameters:
    ///     - sizeToSync: The number of reported actions to trigger a sync. Defaults to 15.
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    private init(sizeToSync: Int = 15, timerStartsAt: Int64 = 0, timerExpiresIn: Int64 = 172800000) {
        if let savedReportData = defaults.objectForKey(defaultsKey) as? NSData,
            let savedReport = NSKeyedUnarchiver.unarchiveObjectWithData(savedReportData) as? Report {
            self.sizeToSync = savedReport.sizeToSync;
            self.timerStartsAt = savedReport.timerStartsAt;
            self.timerExpiresIn = savedReport.timerExpiresIn;
            super.init()
        } else {
            self.sizeToSync = sizeToSync;
            self.timerStartsAt = timerStartsAt;
            self.timerExpiresIn = timerExpiresIn;
            super.init()
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
        }
    }
    
    /// Decodes a saved report from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.sizeToSync = aDecoder.decodeIntegerForKey(defaultsSizeToSync)
        self.timerStartsAt = aDecoder.decodeInt64ForKey(defaultsTimerStartsAt)
        self.timerExpiresIn = aDecoder.decodeInt64ForKey(defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Decoded report with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
    }
    
    /// Encodes a report and saves it to NSUserDefaults
    ///
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(sizeToSync, forKey: defaultsSizeToSync)
        aCoder.encodeInt64(timerStartsAt, forKey: defaultsTimerStartsAt)
        aCoder.encodeInt64(timerExpiresIn, forKey: defaultsTimerExpiresIn)
        DopamineKit.DebugLog("Encoded report with sizeToSync:\(sizeToSync) timerStartsAt:\(timerStartsAt) timerExpiresIn:\(timerExpiresIn)")
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
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
    }
    
    /// Clears the saved report from NSUserDefaults and resets triggers
    ///
    func resetTriggers() {
        self.sizeToSync = 15
        self.timerStartsAt = 0
        self.timerExpiresIn = 172800000
        defaults.removeObjectForKey(defaultsKey)
    }
    
    /// Check whether the report has been triggered for a sync
    ///
    /// - returns: Whether a sync has been triggered.
    ///
    func isTriggered() -> Bool {
        return timerDidExpire() || isSizeToSync()
    }
    
    /// Checks if the sync timer has expired
    ///
    /// - returns: Whether the timer has expired.
    ///
    private func timerDidExpire() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let isExpired = currentTime >= (timerStartsAt + timerExpiresIn)
        DopamineKit.DebugLog("Report timer expires in \(timerStartsAt + timerExpiresIn - currentTime)ms so \(isExpired ? "does" : "doesn't") need to sync...")
        return isExpired
    }
    
    /// Checks if the report is at the size to sync
    ///
    /// - returns: Whether there are enough reported actions to trigger a sync.
    ///
    private func isSizeToSync() -> Bool {
        let count = SQLReportedActionDataHelper.count()
        let isSize = count >= sizeToSync
        DopamineKit.DebugLog("Report has \(count)/\(sizeToSync) actions so \(isSize ? "does" : "doesn't") need to sync...")
        return isSize
    }
    
    /// Stores a reported action to be synced over the DopamineAPI at a later time
    ///
    /// - parameters:
    ///     - action: The action to be stored.
    ///
    func add(action: DopeAction) {
        guard let _ = SQLReportedActionDataHelper.insert(
            SQLReportedAction(
                index:0,
                actionID: action.actionID,
                reinforcementDecision: action.reinforcementDecision!,
                metaData: action.metaData,
                utc: action.utc,
                timezoneOffset: action.timezoneOffset )
            )
            else{
                // if it couldnt be saved, send it
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action report")
                DopamineAPI.report([action], completion: {
                    response in
                })
                return
        }
    }
    
    /// Removes a reported action, to be used after an action has been synced over the DopamineAPI
    ///
    /// - parameters:
    ///     - action: The sql row to delete.
    ///
    func remove(action: SQLReportedAction) {
        SQLReportedActionDataHelper.delete(action);
    }
    
    /// Retrieve all reported actions
    ///
    /// - returns: (sqlRows, dopeActions)
    ///     - sqlRows: The sql rows for reported actions. Pass into `remove()` after successful sync.
    ///     - dopeActions: The reported actions to be synced over DopamineAPI.
    ///
    func getActions() -> (Array<SQLReportedAction>, Array<DopeAction>) {
        var reportedActions = Array<DopeAction>()
        let sqlActions = SQLReportedActionDataHelper.findAll()
        for action in sqlActions {
            reportedActions.append(
                DopeAction(
                    actionID: action.actionID,
                    reinforcementDecision: action.reinforcementDecision,
                    metaData: action.metaData,
                    utc: action.utc,
                    timezoneOffset: action.timezoneOffset )
            )
        }
        return (sqlActions, reportedActions)
    }
    
}