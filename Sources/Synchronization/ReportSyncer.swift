//
//  BolusSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

@objc
class ReportSyncer : NSObject, NSCoding {
    
    static let sharedInstance: ReportSyncer = ReportSyncer()
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let defaultsKey = "DopamineReportSyncerTriggers"
    private let defaultsSuggestedSize = "suggestedSize";
    private let defaultsTimerMarker = "timerMarker";
    private let defaultsTimerLength = "timerLength";
    
    var suggestedSize: Int
    var timerMarker: Int64
    var timerLength: Int64
    
    private var syncInProgress = false
    
    init(suggestedSize: Int = 15, timerMarker: Int64 = 0, timerLength: Int64 = 172800000) {
        if let savedSyncerData = defaults.objectForKey(defaultsKey) as? NSData,
            let savedSyncer = NSKeyedUnarchiver.unarchiveObjectWithData(savedSyncerData) as? ReportSyncer {
            self.suggestedSize = savedSyncer.suggestedSize;
            self.timerMarker = savedSyncer.timerMarker;
            self.timerLength = savedSyncer.timerLength;
            super.init()
        } else {
            self.suggestedSize = suggestedSize;
            self.timerMarker = timerMarker;
            self.timerLength = timerLength;
            super.init()
            defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        self.suggestedSize = aDecoder.decodeIntegerForKey(defaultsSuggestedSize)
        self.timerMarker = aDecoder.decodeInt64ForKey(defaultsTimerMarker)
        self.timerLength = aDecoder.decodeInt64ForKey(defaultsTimerLength)
        DopamineKit.DebugLog("Decoded ReportSyncer with suggestedSize:\(suggestedSize) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(suggestedSize, forKey: defaultsSuggestedSize)
        aCoder.encodeInt64(timerMarker, forKey: defaultsTimerMarker)
        aCoder.encodeInt64(timerLength, forKey: defaultsTimerLength)
        DopamineKit.DebugLog("Encoded ReportSyncer with suggestedSize:\(suggestedSize) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }

    private func updateTriggers(suggestedSize: Int?=nil, timerMarker: Int64=Int64( 1000*NSDate().timeIntervalSince1970 ), timerLength: Int64?=nil) {
        if let suggestedSize = suggestedSize {
            self.suggestedSize = suggestedSize
        }
        self.timerMarker = timerMarker
        if let timerLength = timerLength {
            self.timerLength = timerLength
        }
        defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: defaultsKey)
    }
    
    
    
    func shouldSync() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        let count = SQLReportedActionDataHelper.count()
        if count >= suggestedSize {
            DopamineKit.DebugLog("Report has \(count) actions and should only have \(suggestedSize)")
        }
        else if (timerMarker + timerLength) < currentTime {
            DopamineKit.DebugLog("Report has expired at \(timerMarker + timerLength) and it is \(currentTime) now.")
        } else {
            DopamineKit.DebugLog("Report has \(count)/\(suggestedSize) actions and last synced \(timerMarker) with a timer set \(timerLength)ms from now so does not need sync...")
        }
        
        return !syncInProgress && (
        count >= suggestedSize || (timerMarker + timerLength) < currentTime
        );
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
                ReportSyncer.sharedInstance.updateTriggers()
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
                        timezoneOffset: action.timezoneOffset )
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
                    ReportSyncer.sharedInstance.updateTriggers()
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
    
}