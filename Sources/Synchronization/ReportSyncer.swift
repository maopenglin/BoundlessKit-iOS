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
    
    private static var syncInProgress = false
    
    static func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !syncInProgress else {
                DopamineKit.DebugLog("Report sync already happening")
                completion(200)
                return
            }
            syncInProgress = true
            
            let actions = SQLReportedActionDataHelper.findAll()
            if actions.count == 0 {
                defer { syncInProgress = false }
                DopamineKit.DebugLog("No reported actions to sync.")
                completion(200)
                return
            }
            
            var reportedActions = Array<DopeAction>()
            for action in actions {
                reportedActions.append(
                    DopeAction(
                        actionID: action.actionID,
                        reinforcementDecision: action.reinforcementDecision,
                        metaData: action.metaData,
                        utc: action.utc
                    )
                )
            }
            
            DopamineAPI.report(reportedActions, completion: {
                response in
                defer { syncInProgress = false }
                if response["status"] as? Int == 200 {
                    for action in actions {
                        SQLReportedActionDataHelper.delete(action)
                    }
                    TimeSyncer.reset(ReportSyncer.TimeSyncerKey)
                    completion(200)
                } else {
                    completion(404)
                }
            })
        }
    }
    
    static func store(action: DopeAction) {
        let _ = sharedInstance
        guard let rowId = SQLReportedActionDataHelper.insert(
            SQLReportedAction(
                index:0,
                actionID: action.actionID,
                reinforcementDecision: action.reinforcementDecision!,
                metaData: action.metaData,
                utc: action.utc)
            )
            else{
                // if it couldnt be saved, send it
                DopamineKit.DebugLog("SQLiteDataStore error, sending single action report")
                DopamineAPI.report([action], completion: {
                    response in
                })
                return
        }
        
        // check if sync needs to be done
        if SQLReportedActionDataHelper.count() >= ReportSyncer.getLogSize() {
            DopamineKit.DebugLog("Count is too high: \(ReportSyncer.getLogSize())")
        }
        if TimeSyncer.isExpired(ReportSyncer.TimeSyncerKey) {
            DopamineKit.DebugLog("Timer expired")
        }
        if SQLReportedActionDataHelper.count() >= ReportSyncer.getLogSize() ||
        TimeSyncer.isExpired(ReportSyncer.TimeSyncerKey)
        {
            sync()
        }
    }
    
}