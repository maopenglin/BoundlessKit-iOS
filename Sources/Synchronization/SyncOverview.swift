//
//  SyncOverview.swift
//  Pods
//
//  Created by Akash Desai on 9/19/16.
//
//

import Foundation
internal class SyncOverview : NSObject, NSCoding {
    
    let utcKey = "utc"
    let timezoneOffsetKey = "timezoneOffset"
    let totalSyncTimeKey = "totalSyncTime"
    let causeKey = "cause"
    let trackKey = "track"
    let reportKey = "report"
    let cartridgesKey = "cartridges"
    let syncResponseKey = "syncResponse"
    let roundTripTimeKey = "roundTripTime"
    let statusKey = "status"
    
    var utc: Int64
    var timezoneOffset: Int64
    var totalSyncTime: Int64
    var cause: String
    var trackTriggers: [String: AnyObject]
    var reportTriggers: [String: AnyObject]
    var cartridgesTriggers: [String: [String: AnyObject]]
    
    /// Use this object to record the performance of a synchronization
    ///
    /// - parameters:
    ///     - cause: The reason a sync is being performed
    ///     - timerStartsAt: The start time for a sync timer. Defaults to 0.
    ///     - timerExpiresIn: The timer length, in ms, for a sync timer. Defaults to 48 hours.
    ///
    init(cause: String, trackTriggers: [String: AnyObject], reportTriggers: [String: AnyObject], cartridgeTriggers: [String: [String: AnyObject]]) {
        self.utc = Int64( 1000*Date().timeIntervalSince1970 )
        self.timezoneOffset = Int64( 1000*NSTimeZone.default.secondsFromGMT() )
        self.totalSyncTime = -1
        self.cause = cause
        self.trackTriggers = trackTriggers
        self.reportTriggers = reportTriggers
        self.cartridgesTriggers = cartridgeTriggers
    }
    
    /// Decodes a saved overview from NSUserDefaults
    ///
    required init(coder aDecoder: NSCoder) {
        self.utc = aDecoder.decodeInt64(forKey: utcKey)
        self.timezoneOffset = aDecoder.decodeInt64(forKey: timezoneOffsetKey)
        self.totalSyncTime = aDecoder.decodeInt64(forKey: totalSyncTimeKey)
        self.cause = aDecoder.decodeObject(forKey: causeKey) as! String
        self.trackTriggers = aDecoder.decodeObject(forKey: trackKey) as! [String: AnyObject]
        self.reportTriggers = aDecoder.decodeObject(forKey: reportKey) as! [String: AnyObject]
        self.cartridgesTriggers = aDecoder.decodeObject(forKey: cartridgesKey) as! [String: [String: AnyObject]]
    }
    
    /// Encodes an overview and saves it to NSUserDefaults
    ///
    func encode(with aCoder: NSCoder) {
        aCoder.encode(utc, forKey: utcKey)
        aCoder.encode(timezoneOffset, forKey: timezoneOffsetKey)
        aCoder.encode(totalSyncTime, forKey: totalSyncTimeKey)
        aCoder.encode(cause, forKey: causeKey)
        aCoder.encode(trackTriggers, forKey: trackKey)
        aCoder.encode(reportTriggers, forKey: reportKey)
        aCoder.encode(cartridgesTriggers, forKey: cartridgesKey)
    }
    
    /// This function converts a DopeAction to a JSON compatible Object
    ///
    func toJSONType() -> AnyObject {
        var jsonObject: [String:AnyObject] = [:]
        
        jsonObject[utcKey] = NSNumber(value: utc) as AnyObject
        jsonObject[timezoneOffsetKey] = NSNumber(value: timezoneOffset) as AnyObject
        jsonObject[totalSyncTimeKey] = NSNumber(value: totalSyncTime) as AnyObject
        jsonObject[causeKey] = cause as AnyObject
        jsonObject[trackKey] = trackTriggers as AnyObject
        jsonObject[reportKey] = reportTriggers as AnyObject
        jsonObject[cartridgesKey] = cartridgesTriggers as AnyObject
        DopamineKit.DebugLog(jsonObject.description)
        return jsonObject as AnyObject
    }
    
}
