//
//  BolusSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class ReportSyncer : DopamineSyncer {
    
    static private let sharedInstance: ReportSyncer = ReportSyncer()
    internal var state: SyncState
    
    private static let defaults = NSUserDefaults.standardUserDefaults()
    private static let DefaultsKey = "DopamineReportSyncer"
    private static let TimeSyncerKey = "ReportLog"
    private static let LogSizeKey = "LogSize"
    
    private init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let standardSize = 10
        if( defaults.valueForKey(ReportSyncer.DefaultsKey + ReportSyncer.LogSizeKey) == nil ){
            defaults.setValue(standardSize, forKey: ReportSyncer.DefaultsKey + ReportSyncer.LogSizeKey)
        }
        TimeSyncer.create(ReportSyncer.TimeSyncerKey, ifNotExists: true)
        
        self.state = SyncState.READY
    }
    
    static func getLogSize() -> Int {
        return defaults.integerForKey(DefaultsKey + LogSizeKey)
    }
    
//    func setLogSize(newSize: Int) {
//        defaults.setValue(newSize, forKey: DefaultsKey + LogSizeKey)
//    }
    
//    func getLogCapacity() -> Double {
//        objc_sync_enter(lock)
//        defer{ objc_sync_exit(lock) }
//        
//        return Double(SQLReportedActionDataHelper.count()) / Double(getLogSize())
//    }
    
    static func sync() {
        while(sharedInstance.state != .READY) {
            
        }
        sharedInstance.state = .SYNCING
        
        let actions = SQLReportedActionDataHelper.findAll()
        if actions.count == 0 {
            DopamineKit.DebugLog("No reported actions to sync.")
            sharedInstance.state = .READY
            return
        }
    
        var reportedActions = Array<DopeAction>()
        for action in actions {
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
            // TODO: if response['error'] != null { return }
            
            SQLReportedActionDataHelper.dropTable()
            SQLReportedActionDataHelper.createTable()
            TimeSyncer.reset(ReportSyncer.TimeSyncerKey)
            
//            objc_sync_exit(instance)
            sharedInstance.state = .READY
        })
    }
    
    static func store(action: DopeAction) {
//        objc_sync_enter(sharedInstance)
//        defer{ objc_sync_exit(sharedInstance) }
        while(sharedInstance.state != .READY) {
            
        }
        sharedInstance.state = .STORING
        
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
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action report")
                DopamineAPI.report([action], completion: { response in
                    sharedInstance.state = .READY
                })
                return
        }
        
        DopamineKit.DebugLog("Stored \(rowId) actions.")
        sharedInstance.state = .READY
        
        // check if sync needs to be done
        if SQLReportedActionDataHelper.count() >= ReportSyncer.getLogSize() ||
        TimeSyncer.isExpired(ReportSyncer.TimeSyncerKey)
        {
            sync()
        }
    }
    
}