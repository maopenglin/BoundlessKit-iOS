//
//  Report.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
class Report : NSObject, NSCoding {
    
    var suggestedSize: Int
    var timerMarker: Int64
    var timerLength: Int64
    
    override init() {
        suggestedSize = 15
        timerMarker = 0
        timerLength = 48 * 3600000
    }
    
    required init(coder aDecoder: NSCoder) {
        self.suggestedSize = aDecoder.decodeIntegerForKey("suggestedSize")
        self.timerMarker = aDecoder.decodeInt64ForKey("timerMarker")
        self.timerLength = aDecoder.decodeInt64ForKey("timerLength")
        DopamineKit.DebugLog("Decoded report with suggestedSize:\(suggestedSize) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(suggestedSize, forKey: "suggestedSize")
        aCoder.encodeInt64(timerMarker, forKey: "timerMarker")
        aCoder.encodeInt64(timerLength, forKey: "timerLength")
        DopamineKit.DebugLog("Encoded report with suggestedSize:\(suggestedSize) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }
    
    func shouldSync() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        if SQLReportedActionDataHelper.count() >= suggestedSize {
            DopamineKit.DebugLog("Report has \(SQLReportedActionDataHelper.count()) actions and should only have \(suggestedSize)")
        }
        if (timerMarker + timerLength) < currentTime {
            DopamineKit.DebugLog("Report has expired at \(timerMarker + timerLength) and it is \(currentTime) now.")
        }
        
        
        return SQLReportedActionDataHelper.count() >= suggestedSize ||
                (timerMarker + timerLength) < currentTime
    }
    
}