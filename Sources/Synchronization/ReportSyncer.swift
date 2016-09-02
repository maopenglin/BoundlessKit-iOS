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
    
    private let report = Report.sharedInstance
    
    private var syncInProgress = false
    
    private override init() { }
    
    /// Stores an action to be synced
    ///
    func store(action: DopeAction) {
        report.add(action)
    }
    
    /// Modifies the number of reported actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of reported actions to trigger a sync.
    ///
    func setSizeToSync(size: Int?) {
        report.updateTriggers(size, timerStartsAt: nil, timerExpiresIn: nil)
    }
    
    /// Check if a sync has been triggered
    ///
    /// - returns: Whether the report needs to sync.
    ///
    func shouldSync() -> Bool {
        return report.isTriggered()
    }
    
    /// Sends reinforced actions over the DopamineAPI
    ///
    /// - parameters:
    ///     - completion(Int): takes the http response status code as a parameter.
    ///
    func sync(completion: (Int) -> () = { _ in }) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
            guard !self.syncInProgress else {
                DopamineKit.DebugLog("Report sync already happening")
                completion(200)
                return
            }
            
            self.syncInProgress = true
            let (sqlActions, dopeActions) = self.report.getActions()
            
            if dopeActions.count == 0 {
                defer { self.syncInProgress = false }
                DopamineKit.DebugLog("No reported actions to sync.")
                completion(200)
                self.report.updateTriggers()
            } else {
                DopamineAPI.report(dopeActions, completion: { response in
                    defer { self.syncInProgress = false }
                    if response["status"] as? Int == 200 {
                        defer { completion(200) }
                        for action in sqlActions {
                            self.report.remove(action)
                        }
                        self.report.updateTriggers()
                    } else {
                        completion(404)
                    }
                })
            }
            
        }
    }
    
    /// Resets the sync triggers
    ///
    func makeClean() {
        report.clean()
    }
    
}