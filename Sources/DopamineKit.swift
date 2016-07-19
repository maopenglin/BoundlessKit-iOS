//
//  DopamineKit.swift
//  Dopamine functionality for swift
//
//  Created by Vince Enachescu on 4/7/16.
//  Copyright © 2016 Dopamine Labs. All rights reserved.
//

import Foundation
import UIKit


@objc
public class DopamineKit : NSObject {
    
    // Singleton object
    public static let instance: DopamineKit = DopamineKit()
    private override init() {
        super.init()
        
        do {
            try SQLReportedActionDataHelper.createTable()
            DopamineKit.DebugLog("Table \(SQLReportedActionDataHelper.TABLE_NAME) created!")
        } catch {
            DopamineKit.DebugLog("Something went wrong with \(SQLReportedActionDataHelper.TABLE_NAME) table creation")
        }
        
        do {
            try SQLTrackedActionDataHelper.createTable()
            DopamineKit.DebugLog("Table \(SQLTrackedActionDataHelper.TABLE_NAME) created!")
        } catch {
            DopamineKit.DebugLog("Something went wrong with \(SQLTrackedActionDataHelper.TABLE_NAME) table creation")
        }
    }
    
    
    
        
    /// This function sends an asynchronous tracking call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Action details i.e. calories or streak_count. Must be JSON formattable (Number, String, Bool, Array, Object). Defaults to `nil`.
    ///
    public static func track(actionID: String,
                             metaData: [String: AnyObject]? = nil) {
        
        let action = DopeAction(actionID: actionID, metaData:metaData)
        do{
            // save action
            let rowId =
                try SQLTrackedActionDataHelper.insert(
                    SQLTrackedAction(
                        index:0,
                        actionID: action.actionID,
                        utc: action.utc,
                        timezoneOffset: action.timezoneOffset)
            )
            // send chunk of actions
            do{
                if ( instance.timerExpired(instance.trackTimer) || Int(rowId) >= DopamineAPI.PreferredTrackLength) {
                    var trackedActions = Array<DopeAction>()
                    for action in try SQLTrackedActionDataHelper.findAll()!{
                        trackedActions.append(
                            DopeAction(
                                actionID: action.actionID!,
                                utc: action.utc!,
                                timezoneOffset: action.timezoneOffset!
                            )
                        )
                    }
                    
                    DopamineAPI.track(trackedActions)
                    do { try SQLTrackedActionDataHelper.dropTable() }
                    catch { DopamineKit.DebugLog("Error dropping table \(SQLTrackedActionDataHelper.TABLE_NAME)") }
                    do { try SQLTrackedActionDataHelper.createTable() }
                    catch { DopamineKit.DebugLog("Error recreating table \(SQLTrackedActionDataHelper.TABLE_NAME)") }
                }
                else {
                    DopamineKit.DebugLog("\(actionID) saved. Tracking container:(\(rowId)/\(DopamineAPI.PreferredTrackLength))")
                }
            }
        }
        catch {
            DopamineKit.DebugLog("Error: could not get results from \(SQLTrackedActionDataHelper.TABLE_NAME)")
            return
        }
        catch {
            DopamineKit.DebugLog("Error: could not insert (\(actionID)) into \(SQLTrackedActionDataHelper.TABLE_NAME)")
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
        
        // First generate a decision and call the handler
        var action = DopeAction(actionID: actionID)
        let feedback = "neutralFeedback"
//        let feedback = DecisionEngine.reinforceEvent(&event)
//        completion(feedback)
        
        
        do {
            // save action
            action.reinforcementID = feedback
            let rowId =
                try SQLReportedActionDataHelper.insert(
                    SQLReportedAction(
                        index:0,
                        actionID: action.actionID,
                        reinforcementID: action.reinforcementID,
                        utc: action.utc,
                        timezoneOffset: action.timezoneOffset)
            )
            // send chunk of actions
            do{
                if (instance.timerExpired(instance.reportTimer) || Int(rowId) > DopamineAPI.PreferredReportLength) {
                    var reportedActions = Array<DopeAction>()
                    for action in try SQLReportedActionDataHelper.findAll()!{
                        reportedActions.append(
                            DopeAction(
                                actionID: action.actionID!,
                                reinforcementID: action.reinforcementID!,
                                utc: action.utc!,
                                timezoneOffset: action.timezoneOffset!
                            )
                        )
                    }
                    
                    DopamineAPI.report(reportedActions)
                }
                else {
                    DopamineKit.DebugLog("\(actionID) saved. Report container:(\(rowId)/\(DopamineAPI.PreferredReportLength))")
                }
            }
        }
        catch {
            DopamineKit.DebugLog("Error: could not get results from \(SQLReportedActionDataHelper.TABLE_NAME)")
            return
        }
        catch {
            DopamineKit.DebugLog("Error: could not insert (\(actionID)) into \(SQLReportedActionDataHelper.TABLE_NAME)")
        }

    }
    
    
    typealias SyncTimer = (Int, Int)    // last time and timer length
    private func timerExpired(timer:SyncTimer) -> Bool{
        return DopamineKit.UTCTime() > (timer.0+timer.1)
    }
    private lazy var trackTimer:SyncTimer = {
        let keys = ("DopamineTimerTrackLast", "DopamineTimerTrackLength")
        let defaults = NSUserDefaults.standardUserDefaults()
        if let lastTime = defaults.valueForKey(keys.0) as? Int, timeLength = defaults.valueForKey(keys.1) as? Int {
            return (lastTime, timeLength)
        } else {
            let utcTime = DopamineKit.UTCTime()
            let hours = 48 * 3600000
            defaults.setValue(utcTime, forKey: keys.0)
            defaults.setValue(hours, forKey: keys.1)
            return (utcTime, hours)
        }
    }()
    
    private lazy var reportTimer:SyncTimer = {
        let keys = ("DopamineTimerReportLast", "DopamineTimerReportLength")
        let defaults = NSUserDefaults.standardUserDefaults()
        if let lastTime = defaults.valueForKey(keys.0) as? Int, timeLength = defaults.valueForKey(keys.1) as? Int {
            return (lastTime, timeLength)
        } else {
            let utcTime = DopamineKit.UTCTime()
            let hours = 12 * 3600000
            defaults.setValue(utcTime, forKey: keys.0)
            defaults.setValue(hours, forKey: keys.1)
            return (utcTime, hours)
        }
    }()
    
    private static func UTCTime() -> Int {
        return Int( 1000*NSDate().timeIntervalSince1970 )
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