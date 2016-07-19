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
            try SQLTrackedActionDataHelper.createTable()
            DopamineKit.DebugLog("Table for `Tracked_Actions` created!")
        } catch {
            DopamineKit.DebugLog("Something went wrong with Tracked Action table creation")
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
                if (Int(rowId) > DopamineAPI.PreferredTrackSize) {
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
                }
                else {
                    DopamineKit.DebugLog("\(actionID) saved. Tracking container:(\(rowId)/\(DopamineAPI.PreferredTrackSize))")
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
//        let feedback = DecisionEngine.reinforceEvent(&event)
//        completion(feedback)
        
//        // debug sql insert
//        do{
//        let trackingID = try TrackedActionDataHelper.insert(
//            TrackedAction(index:0, actionID: action.actionID, utc: action.utc, timezoneOffset: action.timezoneOffset)
//        )
//        DopamineKit.DebugLog("Added tracked action with id:\(trackingID)")
//        } catch {
//            DopamineKit.DebugLog("Couldn't add tracked action")
//        }
        
//        do {
//            try SQLTrackedActionDataHelper.delete(SQLTrackedAction(index: 5, actionID: "test",
//                utc: 12345,
//                timezoneOffset: 3))
//        } catch {
//            DopamineKit.DebugLog("COuldn't delete")
//        }
        
        
        
        // query whole table
        do {
            
            if let trackedActions = try SQLTrackedActionDataHelper.findAll(){
                for action in trackedActions{
                    DopamineKit.DebugLog("Index:(\(action.index!)) ActionID:(\(action.actionID!)) at utc:(\(action.utc!)) with offset:(\(action.timezoneOffset!))")
                }
            }
        } catch {
            DopamineKit.DebugLog("Couldn't print all from sql table")
        }
        
        do {
            try SQLTrackedActionDataHelper.dropTable()
        } catch {
            DopamineKit.DebugLog("COuldn't drop Tracked Action table")
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