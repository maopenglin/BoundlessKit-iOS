//
//  DopamineKit.swift
//  Dopamine functionality for swift
//
//  Created by Vince Enachescu on 4/7/16.
//  Copyright © 2016 Dopamine Labs. All rights reserved.
//

import Foundation

@objc
open class DopamineKit : NSObject {
    
    public static let sharedInstance: DopamineKit = DopamineKit()
    
    public let syncCoordinator = SyncCoordinator.sharedInstance
    
    /// This function sends an asynchronous tracking call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Descriptive name for the action.
    ///     - metaData?: Action details i.e. calories or streak_count. 
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///
    open static func track(_ actionID: String, metaData: [String: AnyObject]? = nil) {
        // store the action to be synced
        let action = DopeAction(actionID: actionID, metaData:metaData)
        sharedInstance.syncCoordinator.store(trackedAction: action)
    }

    /// This function sends an asynchronous reinforcement call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Action name configured on the Dopamine Dashboard
    ///     - metaData?: Action details i.e. calories or streak_count.
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///     - completion: A closure with the reinforcement decision passed as a `String`.
    ///
    open static func reinforce(_ actionID: String, metaData: [String: AnyObject]? = nil, completion: @escaping (String) -> ()) {
        let action = DopeAction(actionID: actionID, metaData: metaData)
        action.reinforcementDecision =  sharedInstance.syncCoordinator.retrieveReinforcementDecisionFor(actionID: action.actionID)
        
        DispatchQueue.main.async(execute: {
            completion(action.reinforcementDecision!)
        })
        
        // store the action to be synced
        sharedInstance.syncCoordinator.store(reportedAction: action)
    }
    
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filename?: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function?: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line?: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    internal static func DebugLog(_ message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
        #if DEBUG
            var functionSignature:String = function
            if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
                functionSignature.replaceSubrange(parameterNames, with: "()")
            }
            let fileName = NSString(string: filePath).lastPathComponent.components(separatedBy: ",")[0]
            NSLog("[\(fileName):\(line):\(functionSignature)] - \(message)")
        #endif
    }

}
