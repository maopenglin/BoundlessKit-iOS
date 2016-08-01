//
//  Cartridge.swift
//  Pods
//
//  Created by Akash Desai on 8/1/16.
//
//

import Foundation

@objc
class Cartridge : NSObject, NSCoding {
    
    var actionID: String
    var size: Int
    var timerMarker: Int64
    var timerLength: Int64
    
    init(actionID: String) {
        self.actionID = actionID
        size = 10
        timerMarker = 0
        timerLength = 48 * 3600000
    }
    
    required init(coder aDecoder: NSCoder) {
        self.actionID = aDecoder.decodeObjectForKey("actionID") as! String
        self.size = aDecoder.decodeIntegerForKey("size")
        self.timerMarker = aDecoder.decodeInt64ForKey("timerMarker")
        self.timerLength = aDecoder.decodeInt64ForKey("timerLength")
        DopamineKit.DebugLog("Decoded cartridge with actionID:\(actionID) size:\(size) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(actionID, forKey: "actionID")
        aCoder.encodeInteger(size, forKey: "size")
        aCoder.encodeInt64(timerMarker, forKey: "timerMarker")
        aCoder.encodeInt64(timerLength, forKey: "timerLength")
        DopamineKit.DebugLog("Encoded cartridge with actionID:\(actionID) size:\(size) timerMarker:\(timerMarker) timerLength:\(timerLength)")
    }

    func isExpired() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        return SQLCartridgeDataHelper.count(actionID) == 0 ||
                (timerMarker + timerLength) < currentTime
    }
    
    func isFresh() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        return
            SQLCartridgeDataHelper.count(actionID) > 1 &&
                (timerMarker + timerLength) >= currentTime
    }
    
    func shouldSync() -> Bool {
        let currentTime = Int64( 1000*NSDate().timeIntervalSince1970 )
        if SQLCartridgeDataHelper.count(actionID) <= 5 {
            DopamineKit.DebugLog("Cartridge \(actionID) has \(SQLCartridgeDataHelper.count(actionID)) decisions and needs at least \(5)")
        }
        if (timerMarker + timerLength) < currentTime {
            DopamineKit.DebugLog("Cartridge \(actionID) has expired at \(timerMarker + timerLength) and it is \(currentTime) now.")
        }
        return SQLCartridgeDataHelper.count(actionID) <= 5 ||
            (timerMarker + timerLength) < currentTime
    }
    
}