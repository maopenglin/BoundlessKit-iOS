//
//  BolusSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class ReportSyncer {
    
    static private let sharedInstance: ReportSyncer = ReportSyncer()
    
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
    }
    
    static func getLogSize() -> Int {
        return defaults.integerForKey(DefaultsKey + LogSizeKey)
    }
    
    static func sync() {
        objc_sync_enter(sharedInstance)
        defer { objc_sync_exit(sharedInstance) }
        
        let actions = SQLReportedActionDataHelper.findAll()
        if actions.count == 0 {
            DopamineKit.DebugLog("No reported actions to sync.")
//            objc_sync_exit(sharedInstance)
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
            
//            objc_sync_exit(sharedInstance)
        })
    }
    
    static func store(action: DopeAction) {
        objc_sync_enter(sharedInstance)
        defer{ objc_sync_exit(sharedInstance) }
        
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
                DopamineAPI.report([action], completion: {
                    response in
                })
                return
        }
        
        DopamineKit.DebugLog("Stored \(rowId) actions.")
        
        // check if sync needs to be done
        if SQLReportedActionDataHelper.count() >= ReportSyncer.getLogSize() ||
        TimeSyncer.isExpired(ReportSyncer.TimeSyncerKey)
        {
            sync()
        }
    }
    
}