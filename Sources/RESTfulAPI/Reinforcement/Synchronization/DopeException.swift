//
//  DopeException.swift
//  Pods
//
//  Created by Akash Desai on 9/21/16.
//
//

import Foundation
internal class DopeException : NSObject, NSCoding {
    
    static let utcKey = "utc"
    static let timezoneOffsetKey = "timezoneOffset"
    static let exceptionClassNameKey = "class"
    static let messageKey = "message"
    static let stackTraceKey = "stackTrace"
    
    var utc: Int64
    var timezoneOffset: Int64
    var exceptionClassName: String
    var message: String
    var stackTrace: String
    
    /// Use this object to record the performance of a synchronization
    ///
    /// - parameters:
    ///     - cause: The reason a sync is being performed
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    init(exceptionClassName: String, message: String, stackTrace: String) {
        self.utc = Int64( 1000*Date().timeIntervalSince1970 )
        self.timezoneOffset = Int64( 1000*NSTimeZone.default.secondsFromGMT() )
        self.exceptionClassName = exceptionClassName
        self.message = message
        self.stackTrace = stackTrace
    }
    
    /// Decodes a saved overview from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.utc = aDecoder.decodeInt64(forKey: DopeException.utcKey)
        self.timezoneOffset = aDecoder.decodeInt64(forKey: DopeException.timezoneOffsetKey)
        self.exceptionClassName = aDecoder.decodeObject(forKey: DopeException.exceptionClassNameKey) as! String
        self.message = aDecoder.decodeObject(forKey: DopeException.messageKey) as! String
        self.stackTrace = aDecoder.decodeObject(forKey: DopeException.stackTraceKey) as! String
    }
    
    /// Encodes an overview and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(utc, forKey: DopeException.utcKey)
        aCoder.encode(timezoneOffset, forKey: DopeException.timezoneOffsetKey)
        aCoder.encode(exceptionClassName, forKey: DopeException.exceptionClassNameKey)
        aCoder.encode(message, forKey: DopeException.messageKey)
        aCoder.encode(stackTrace, forKey: DopeException.stackTraceKey)
    }
    
    /// This function converts a DopeAction to a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject[DopeException.utcKey] = NSNumber(value: utc)
        jsonObject[DopeException.timezoneOffsetKey] = NSNumber(value: timezoneOffset)
        jsonObject[DopeException.exceptionClassNameKey] = exceptionClassName
        jsonObject[DopeException.messageKey] = message
        jsonObject[DopeException.stackTraceKey] = stackTrace
        DopeLog.debug(jsonObject.description)
        return jsonObject
    }
    
}
