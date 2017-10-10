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
    public static let syncCoordinator = SyncCoordinator.shared
    
    private override init() {
        super.init()
    }
    
    /// This function sends an asynchronous tracking call for the specified action
    ///
    /// - parameters:
    ///     - actionID: Descriptive name for the action.
    ///     - metaData: Action details i.e. calories or streak_count.
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///
    open static func track(_ actionID: String, metaData: [String: Any]? = nil) {
        // store the action to be synced
        DispatchQueue.global(qos: .background).async {
            let action = DopeAction(actionID: actionID, metaData:metaData)
            syncCoordinator.store(trackedAction: action)
//            debugLog("tracked:\(actionID) with metadata:\(String(describing: metaData))")
        }
    }
    
    /// This function intelligently chooses whether to reinforce a user action. The reinforcement function, passed as the completion, is run asynchronously on the queue.
    ///
    /// - parameters:
    ///     - actionID: Action name configured on the Dopamine Dashboard
    ///     - metaData: Action details i.e. calories or streak_count.
    ///                  Must be JSON formattable (Number, String, Bool, Array, Object).
    ///                  Defaults to `nil`.
    ///     - completion: A closure with the reinforcement decision passed as a `String`.
    ///
    open static func reinforce(_ actionID: String, metaData: [String: Any]? = nil, completion: @escaping (String) -> ()) {
        let action = DopeAction(actionID: actionID, metaData: metaData)
        action.reinforcementDecision = syncCoordinator.retrieveReinforcementDecisionFor(actionID: action.actionID)
        
        DispatchQueue.main.async(execute: {
            completion(action.reinforcementDecision!)
        })
        
        // store the action to be synced
        syncCoordinator.store(reportedAction: action)
    }
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    public static func debugLog(_ message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
        #if DEBUG
            var functionSignature:String = function
            if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
                functionSignature.replaceSubrange(parameterNames, with: "()")
            }
            let fileName = NSString(string: filePath).lastPathComponent
            print("[\(fileName):\(line):\(functionSignature)] - \(message)")
        #endif
    }

}
