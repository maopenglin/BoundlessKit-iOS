//
//  Track.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
class Track : NSObject, NSCoding {
    
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
        DopamineKit.DebugLog("Decoded track with suggestedSize:\(suggestedSize) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(suggestedSize, forKey: "suggestedSize")
        aCoder.encodeInt64(timerMarker, forKey: "timerMarker")
        aCoder.encodeInt64(timerLength, forKey: "timerLength")
        DopamineKit.DebugLog("Encoded track with suggestedSize:\(suggestedSize) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }
    
    func shouldSync() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        if SQLTrackedActionDataHelper.count() >= suggestedSize {
            DopamineKit.DebugLog("Track has \(SQLTrackedActionDataHelper.count()) actions and should only have \(suggestedSize)")
        }
        else if (timerMarker + timerLength) < currentTime {
            DopamineKit.DebugLog("Track has expired at \(timerMarker + timerLength) and it is \(currentTime) now.")
        } else {
            DopamineKit.DebugLog("Track has \(SQLTrackedActionDataHelper.count())/\(suggestedSize) actions and last synced \(timerMarker) with a timer set \(timerLength)ms from now so does not need sync...")
        }
        return SQLTrackedActionDataHelper.count() >= suggestedSize ||
            (timerMarker + timerLength) < currentTime
    }
    
}