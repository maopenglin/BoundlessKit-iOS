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
    
    fileprivate let report = Report.sharedInstance
    
    fileprivate var syncInProgress = false
    
    fileprivate override init() { }
    
    /// Stores an action to be synced
    ///
    func store(_ action: DopeAction) {
        report.add(action)
    }
    
    /// Modifies the number of reported actions to trigger a sync
    ///
    /// - parameters:
    ///     - size: The number of reported actions to trigger a sync.
    ///
    func setSizeToSync(_ size: Int?) {
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
    func sync(_ completion: @escaping (Int) -> () = { _ in }) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
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
                DopamineKit.DebugLog("Sending \(dopeActions.count) reported actions...")
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
    
    /// Removes saved sync triggers from memory
    ///
    func reset() {
        report.resetTriggers()
    }
    
}
