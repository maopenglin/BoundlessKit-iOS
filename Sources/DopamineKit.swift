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
public class DopamineKit : NSObject{
    /// Initializes the DopamineKit singleton.
    private override init() {
        super.init()
    }
    
    // Singleton configuration
    public static let instance: DopamineKit = DopamineKit()
        
    /// This function sends an asynchronous tracking call for the specified actionID
    ///
    /// - parameters:
    ///     - actionID: Descriptive name of the action.
    ///     - metaData?: Event info as a set of key-value pairs that can be sent with a tracking call. The value should JSON formattable like an NSNumber or NSString. Defaults to `nil`.
    ///
    public static func track(actionID: String, metaData: [String: AnyObject]? = nil){
        let event = DopeEvent(action: actionID, metaData: metaData)
        DecisionEngine.trackEvent(event)
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
        var event = DopeEvent(action: actionID, metaData: metaData)
        let feedback = DecisionEngine.reinforceEvent(&event)
        completion(feedback)
    }
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filename?: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function?: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line?: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    internal static func DebugLog(message: String,  fileName: String = #file, function: String =  #function, line: Int = #line) {
//        #if DEBUG
            var functionSignature:String = function
            if let parameterNames = functionSignature.rangeOfString("\\((.*?)\\)", options: .RegularExpressionSearch){
                functionSignature.replaceRange(parameterNames, with: "()")
            }
            NSLog("[\((fileName as NSString).lastPathComponent):\(line):\(functionSignature)] - \(message)")
//        #endif
    }
        
    
    
    

}