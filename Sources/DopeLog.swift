//
//  DopeLog.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/7/17.
//

import Foundation


@objc public class DopeLog : NSObject {
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc public static func print(_ message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard DopamineConfigurationControl.current.consoleLoggingEnabled else {
            return
        }
        var functionSignature:String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - \(message)")
    }
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc public static func debug(_ message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
        #if DEBUG
            guard DopamineConfigurationControl.current.consoleLoggingEnabled else {
                return
            }
            var functionSignature:String = function
            if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
                functionSignature.replaceSubrange(parameterNames, with: "()")
            }
            let fileName = NSString(string: filePath).lastPathComponent
            Swift.print("[\(fileName):\(line):\(functionSignature)] - \(message)")
        #endif
    }
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc public static func error(_ message: String,  filePath: String = #file, function: String =  #function, line: Int = #line) {
        var functionSignature:String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - \(message)")
    }
}
