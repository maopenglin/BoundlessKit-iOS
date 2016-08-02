//
//  BolusSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

@objc
class ReportSyncer : NSObject {
    
    static let sharedInstance: ReportSyncer = ReportSyncer()
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let defaultsKey = "DopamineReportSyncer"
    
    private let report: Report
    
    private override init() {
        if let savedReportData = defaults.objectForKey(defaultsKey) as? NSData {
            let savedReport = NSKeyedUnarchiver.unarchiveObjectWithData(savedReportData) as! Report
            report = savedReport
        } else {
            report = Report()
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(report), forKey: defaultsKey)
        }
    }
    
    func updateReport(suggestedSize: Int?=nil, timerMarker: Int64=Int64( 1000*NSDate().timeIntervalSince1970 ), timerLength: Int64?=nil) {
        if let suggestedSize = suggestedSize {
            report.suggestedSize = suggestedSize
        }
        report.timerMarker = timerMarker
        if let timerLength = timerLength {
            report.timerLength = timerLength
        }
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(report), forKey: defaultsKey)
    }
    
    private var syncInProgress = false
    
    func shouldSync() -> Bool {
        return !syncInProgress && report.shouldSync()
    }
    
    func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Report sync already happening")
                completion(200)
                return
            }
            self.syncInProgress = true
            
            let actions = SQLReportedActionDataHelper.findAll()
            if actions.count == 0 {
                defer { self.syncInProgress = false }
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
                defer { self.syncInProgress = false }
                if response["status"] as? Int == 200 {
                    defer { completion(200) }
                    for action in actions {
                        SQLReportedActionDataHelper.delete(action)
                    }
                    ReportSyncer.sharedInstance.updateReport()
                } else {
                    completion(404)
                }
            })
        }
    }
    
    func store(action: DopeAction) {
        guard let _ = SQLReportedActionDataHelper.insert(
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
    }
    
}