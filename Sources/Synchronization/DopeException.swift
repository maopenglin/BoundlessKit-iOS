//
//  DopeException.swift
//  Pods
//
//  Created by Akash Desai on 9/26/16.
//
//

import Foundation

class DopeException {
    
    let utc: Int64
    let timezoneOffset: Int64
    let exceptionClassName: String
    let message: String
    let stackTrace: String
    
    init(utc: Int64=Int64(1000*NSDate().timeIntervalSince1970),
         timezoneOffset: Int64=Int64(1000*NSTimeZone.defaultTimeZone().secondsFromGMT),
         exceptionClassName: String,
         message: String,
         stackTrace: String
        ) {
        self.utc = utc
        self.timezoneOffset = timezoneOffset
        self.exceptionClassName = exceptionClassName
        self.message = message
        self.stackTrace = stackTrace
    }
    
    /// Quick method to store a dopamine exception into the local database
    ///
    /// - parameters:
    ///     - className: The class name for the exception or error.
    ///     - message: The message for the exception or error, including parameter values.
    ///     - dataDescription: A description of the data that caused the exception or error, if relevant. Defaults to `nil`.
    ///     - filePath: Used to get filename of bug. Do not use this parameter. Defaults to `#file`.
    ///     - function: Used to get function name of bug. Do not use this parameter. Defaults to #function.
    ///
    static func store(exceptionClassName exceptionClassName: String,
                      message: String,
                      filePath: String = #file, function: String = #function) {
        
        var stackTrace = NSThread.callStackSymbols()
        stackTrace[0] = "0\t\(NSString(string: filePath).lastPathComponent)\t\t\t\t\t\(function)"
        
        let dopeException = SQLDopeException(
            index:0,
            utc: Int64(1000*NSDate().timeIntervalSince1970),
            timezoneOffset: Int64(1000*NSTimeZone.defaultTimeZone().secondsFromGMT),
            exceptionClassName: exceptionClassName,
            message: message,
            stackTrace: stackTrace.joinWithSeparator("\n")
        )
        guard let _ = SQLDopeExceptionDataHelper.insert(dopeException) else {
            DopamineKit.DebugLog("SQLiteDataStore error, couldnt store dopamine exception.")
            return
        }

    }
    
    /// Stores the dopamine exception into the local database
    ///
    func store() {
        let dopeException = SQLDopeException(
            index:0,
            utc: utc,
            timezoneOffset: timezoneOffset,
            exceptionClassName: exceptionClassName,
            message: message,
            stackTrace: stackTrace
        )
        guard let _ = SQLDopeExceptionDataHelper.insert(dopeException) else {
            DopamineKit.DebugLog("SQLiteDataStore error, couldnt store dopamine exception.")
            return
        }
    }
}
