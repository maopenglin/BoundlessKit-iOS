//
//  BolusSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class ReportSyncer {
    
    private let lock:Int = 0
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let DefaultsKey = "DopamineReportSyncer"
    private let TimeSyncerKey = "ReportLog"
    private let LogSizeKey = "LogSize"
    
    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let standardSize = 10
        if( defaults.valueForKey(DefaultsKey + LogSizeKey) == nil ){
            defaults.setValue(standardSize, forKey: DefaultsKey + LogSizeKey)
        }
        TimeSyncer.create(TimeSyncerKey, ifNotExists: true)
    }
    
    func getLogSize() -> Int {
        return defaults.integerForKey(DefaultsKey + LogSizeKey)
    }
    
    func setLogSize(newSize: Int) {
        defaults.setValue(newSize, forKey: DefaultsKey + LogSizeKey)
    }
    
    func shouldSend() -> Bool {
        objc_sync_enter(lock)
        defer{ objc_sync_exit(lock) }
        
        return  SQLReportedActionDataHelper.count() >= getLogSize() ||
                TimeSyncer.isExpired(TimeSyncerKey)
    }
    
    func getLogCapacity() -> Double {
        objc_sync_enter(lock)
        defer{ objc_sync_exit(lock) }
        
        return Double(SQLReportedActionDataHelper.count()) / Double(getLogSize())
    }
    
    func send() {
        objc_sync_enter(lock)
        var reportedActions = Array<DopeAction>()
        for action in SQLReportedActionDataHelper.findAll() {
            reportedActions.append(
                DopeAction(
                    actionID: action.actionID,
                    reinforcementDecision: action.reinforcementDecision,
                    metaData: action.metaData,
                    utc: action.utc,
                    timezoneOffset: action.timezoneOffset
                )
            )
        }
        
        DopamineAPI.report(reportedActions, completion: {
            response in
            DopamineKit.DebugLog("Report syncer go response:\(response)")
            
            SQLReportedActionDataHelper.dropTable()
            SQLReportedActionDataHelper.createTable()
            TimeSyncer.reset(self.TimeSyncerKey)
            
            objc_sync_exit(self.lock)
        })
    }
    
    func store(action: DopeAction) {
        objc_sync_enter(lock)
        defer{ objc_sync_exit(lock) }
        
        guard let rowId = SQLReportedActionDataHelper.insert(
            SQLReportedAction(
                index:0,
                actionID: action.actionID,
                reinforcementDecision: action.reinforcementDecision!,
                metaData: action.metaData,
                utc: action.utc,
                timezoneOffset: action.timezoneOffset)
            )
            else{
                // if it couldnt be saved, send it
                DopamineAPI.report([action], completion: { response in
                    DopamineKit.DebugLog("Report syncer sent reported actions with response:\(response)")
                })
                return
        }
        
        DopamineKit.DebugLog("Stored \(rowId) actions.")
    }
    
}