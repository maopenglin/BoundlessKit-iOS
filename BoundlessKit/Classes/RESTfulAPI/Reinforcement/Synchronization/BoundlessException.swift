//
//  BoundlessException.swift
//  Pods
//
//  Created by Akash Desai on 9/21/16.
//
//

import Foundation
internal class BoundlessException : NSObject, NSCoding {
    
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
        self.utc = aDecoder.decodeInt64(forKey: BoundlessException.utcKey)
        self.timezoneOffset = aDecoder.decodeInt64(forKey: BoundlessException.timezoneOffsetKey)
        self.exceptionClassName = aDecoder.decodeObject(forKey: BoundlessException.exceptionClassNameKey) as! String
        self.message = aDecoder.decodeObject(forKey: BoundlessException.messageKey) as! String
        self.stackTrace = aDecoder.decodeObject(forKey: BoundlessException.stackTraceKey) as! String
    }
    
    /// Encodes an overview and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(utc, forKey: BoundlessException.utcKey)
        aCoder.encode(timezoneOffset, forKey: BoundlessException.timezoneOffsetKey)
        aCoder.encode(exceptionClassName, forKey: BoundlessException.exceptionClassNameKey)
        aCoder.encode(message, forKey: BoundlessException.messageKey)
        aCoder.encode(stackTrace, forKey: BoundlessException.stackTraceKey)
    }
    
    /// This function converts a BoundlessAction to a JSON compatible Object
    ///
    func toJSONType() -> [String : Any] {
        var jsonObject: [String:Any] = [:]
        
        jsonObject[BoundlessException.utcKey] = NSNumber(value: utc)
        jsonObject[BoundlessException.timezoneOffsetKey] = NSNumber(value: timezoneOffset)
        jsonObject[BoundlessException.exceptionClassNameKey] = exceptionClassName
        jsonObject[BoundlessException.messageKey] = message
        jsonObject[BoundlessException.stackTraceKey] = stackTrace
        BoundlessLog.debug(jsonObject.description)
        return jsonObject
    }
    
}
