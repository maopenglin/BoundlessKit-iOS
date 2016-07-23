//
//  DopamineKit.swift
//  Dopamine functionality for swift
//
//  Created by Vince Enachescu on 4/7/16.
//  Copyright © 2016 Dopamine Labs. All rights reserved.
//

import Foundation
import UIKit
import SQLite

@objc
public class DopamineKit : NSObject {
    
    // Singleton pattern
    public static let instance: DopamineKit = DopamineKit()
    let trackSyncer: TrackSyncer
    let reportSyncer: ReportSyncer
    
    private override init() {
        SQLiteDataStore.instance.createTables()
        trackSyncer = TrackSyncer()
        reportSyncer = ReportSyncer()
    }
    
    deinit {
        
    }
    
        
    /// This function sends an asynchronous tracking call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Action details i.e. calories or streak_count. 
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///
    public static func track(actionID: String, metaData: [String: AnyObject]? = nil) {
        let action = DopeAction(actionID: actionID, metaData:metaData)
        
        // send chunk of actions
        instance.trackSyncer.store(action)
        if (  instance.trackSyncer.shouldSend() ) {
            instance.trackSyncer.send()
        } else {
            DopamineKit.DebugLog("\(actionID) saved. Tracking container:(\(SQLTrackedActionDataHelper.count())/\(instance.trackSyncer.getLogSize()))")
        }
        
    }

    /// This function sends an asynchronous reinforcement call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Action details i.e. calories or streak_count.
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///     - completion: A closure with the reinforcement response passed in as a `String`.
    ///
    public static func reinforce(actionID: String, metaData: [String: AnyObject]? = nil, completion: (String) -> ()) {
        var action = DopeAction(actionID: actionID, metaData: metaData)
        
        // send back a reinforcementDecision
        var reinforcementDecision = "test"
//        let feedback = DecisionEngine.reinforceEvent(&event)
        
        if let rdSql = SQLCartridgeDataHelper.findLast(actionID) {
            reinforcementDecision = rdSql.reinforcementDecision
            SQLCartridgeDataHelper.delete(rdSql)
        }
        
        completion(reinforcementDecision)
        action.reinforcementDecision = reinforcementDecision
        
        // send chunk of actions
        instance.reportSyncer.store(action)
        if (  instance.reportSyncer.shouldSend() ) {
            instance.reportSyncer.send()
        } else {
            DopamineKit.DebugLog("\(actionID) saved. Reinforcement report container:(\(SQLReportedActionDataHelper.count())/\(instance.reportSyncer.getLogSize()))")
        }
        
        let cartridge = CartridgeSyncer(actionID: actionID)
        if( cartridge.shouldReload() ) {
            cartridge.reload()
        }
        
    }
    
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filename?: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function?: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line?: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    internal static func DebugLog(message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
//        #if DEBUG
            var functionSignature:String = function
            if let parameterNames = functionSignature.rangeOfString("\\((.*?)\\)", options: .RegularExpressionSearch){
                functionSignature.replaceRange(parameterNames, with: "()")
            }
            var fileName = NSString(string: filePath).lastPathComponent.componentsSeparatedByString(".")[0]
            NSLog("[\(fileName):\(line):\(functionSignature)] - \(message)")
//        #endif
    }
        
    
    
    

}