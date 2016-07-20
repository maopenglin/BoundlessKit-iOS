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
    
    // Singleton object
    public static let instance: DopamineKit = DopamineKit()
    
    private override init() {
        super.init()
        SQLiteDataStore.instance.createTables()
    }
    
        
    /// This function sends an asynchronous tracking call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Action details i.e. calories or streak_count. Must be JSON formattable (Number, String, Bool, Array, Object). Defaults to `nil`.
    ///
    public static func track(actionID: String,
                             metaData: [String: AnyObject]? = nil) {
        let _ = instance
        let action = DopeAction(actionID: actionID, metaData:metaData)
        
        // save action
        guard let rowId = SQLTrackedActionDataHelper.insert(
            SQLTrackedAction(
                index:0,
                actionID: action.actionID,
                metaData: action.metaData==nil ? nil : NSKeyedArchiver.archivedDataWithRootObject(action.metaData!).datatypeValue,
                utc: action.utc,
                timezoneOffset: action.timezoneOffset)
            )
            else{
                // if it couldnt be saved, send it
                DopamineAPI.track(action)
                return
        }
        
        // send chunk of actions
        if ( Int(rowId) >= DopamineAPI.PreferredTrackLength ) {
            var trackedActions = Array<DopeAction>()
            for action in SQLTrackedActionDataHelper.findAll() {
                trackedActions.append(
                    DopeAction(
                        actionID: action.actionID,
                        metaData: action.metaData==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData( NSData.fromDatatypeValue( action.metaData!) ) as? [String : AnyObject],
                        utc: action.utc,
                        timezoneOffset: action.timezoneOffset)
                )
            }
            
            DopamineAPI.track(trackedActions)
            
            SQLTrackedActionDataHelper.dropTable()
            SQLTrackedActionDataHelper.createTable()
        }
        else {
            DopamineKit.DebugLog("\(actionID) saved. Tracking container:(\(rowId)/\(DopamineAPI.PreferredTrackLength))")
        }
        
    }

    /// This function sends an asynchronous reinforcement call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Event info as a set of key-value pairs that can be sent with a tracking call. The value should JSON formattable like an NSNumber or NSString. Defaults to `nil`.
    ///     - secondaryIdentity?: An additional idetification string. Defaults to `nil`.
    ///     - timeoutSeconds?: Default 2.0 - the timeout in seconds for the connection
    ///     - completion: A closure with the reinforcement response passed in as a `String`.
    ///
    public static func reinforce(actionID: String, metaData: [String: AnyObject]? = nil, completion: (String) -> ()) {
        let _ = instance
        // First generate a decision and call the handler
        var action = DopeAction(actionID: actionID, metaData: metaData)
        let feedback = "neutralFeedback"
//        let feedback = DecisionEngine.reinforceEvent(&event)
        completion(feedback)
        
        // save action
        action.reinforcementDecision = feedback
        guard let rowId = SQLReportedActionDataHelper.insert(
                SQLReportedAction(
                    index:0,
                    actionID: action.actionID,
                    reinforcementDecision: action.reinforcementDecision!,
                    metaData: action.metaData==nil ? nil : NSKeyedArchiver.archivedDataWithRootObject(action.metaData!).datatypeValue,
                    utc: action.utc,
                    timezoneOffset: action.timezoneOffset)
            )
            else {
                DopamineAPI.report(action)
                return
        }
        // send chunk of actions
        if ( Int(rowId) >= DopamineAPI.PreferredReportLength ) {
            
            var reportedActions = Array<DopeAction>()
            for action in SQLReportedActionDataHelper.findAll() {
                var unarchivedMetaData:[String:AnyObject]?
                reportedActions.append(
                    DopeAction(
                        actionID: action.actionID,
                        reinforcementDecision: action.reinforcementDecision,
                        metaData: action.metaData==nil ? nil : NSKeyedUnarchiver.unarchiveObjectWithData( NSData.fromDatatypeValue( action.metaData!) ) as? [String : AnyObject],
                        utc: action.utc,
                        timezoneOffset: action.timezoneOffset
                    )
                )
            }
            
            DopamineAPI.report(reportedActions)
            
            SQLReportedActionDataHelper.dropTable()
            SQLReportedActionDataHelper.createTable()
            
        } else {
            DopamineKit.DebugLog("\(actionID) saved. Report container:(\(rowId)/\(DopamineAPI.PreferredReportLength))")
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