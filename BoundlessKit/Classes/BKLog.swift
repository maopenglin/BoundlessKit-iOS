//
//  BKLog.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/14/18.
//

import Foundation

open class BKLogPreferences {
    static var debugEnabled = true
    static var printEnabled = true
}

internal class BKLog {
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc public class func debug(_ message: String, filePath: String = #file, function: String =  #function, line: Int = #line) {
        #if DEBUG
            guard BKLogPreferences.debugEnabled else { return }
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
    @objc public class func print(_ message: String, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard BKLogPreferences.printEnabled else { return }
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
    ///     - message: The confirmation message.
    ///     - filePath: Used to get filename. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line. Do not use this parameter. Defaults to #line.
    ///
    @objc public class func print(confirmed message: String, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard BKLogPreferences.printEnabled else { return }
        var functionSignature:String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - ✅ \(message)")
    }
    
    /// This function sends debug messages if "-D DEBUG" flag is added in 'Build Settings' > 'Swift Compiler - Custom Flags'
    ///
    /// - parameters:
    ///     - message: The debug message.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to #file.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///     - line: Used to get the line of bug. Do not use this parameter. Defaults to #line.
    ///
    @objc public class func print(error message: String, visual: Bool = false, filePath: String = #file, function: String =  #function, line: Int = #line) {
        guard BKLogPreferences.printEnabled else { return }
        var functionSignature:String = function
        if let parameterNames = functionSignature.range(of: "\\((.*?)\\)", options: .regularExpression) {
            functionSignature.replaceSubrange(parameterNames, with: "()")
        }
        let fileName = NSString(string: filePath).lastPathComponent
        Swift.print("[\(fileName):\(line):\(functionSignature)] - ❌ \(message)")
        
        if BKLogPreferences.debugEnabled && visual {
            alert(message: "🚫 \(message)", title: "☠️")
        }
    }
    
    private static func alert(message: String, title: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(OKAction)
            UIWindow.presentTopLevelAlert(alertController: alertController)
        }
    }
}
