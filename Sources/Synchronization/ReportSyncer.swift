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
    
    private let report = Report()
    
    private var syncInProgress = false
    
    private override init() { }
    
    func store(action: DopeAction) {
        report.add(action)
    }
    
    func shouldSync() -> Bool {
        return report.isTriggered()
    }
    
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
    
}