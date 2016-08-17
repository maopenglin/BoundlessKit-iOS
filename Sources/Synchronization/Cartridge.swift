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
    private static let capacityToSync = 0.25
    private static let minimumSize = 2
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
        let result = (timerMarker + timerLength) < currentTime
        
        DopamineKit.DebugLog("Cartridge \(actionID) expire\(result ? "ed" : "s") at \(timerMarker + timerLength) and it is \(currentTime) now.")
        
        return result
    }
    
    func isFresh() -> Bool {
        return SQLCartridgeDataHelper.count(actionID) >= 1 && !isExpired()
    }
    
    func isSizeToSync() -> Bool {
        let count = SQLCartridgeDataHelper.count(actionID)
        let result = count < Cartridge.minimumSize || Double(count) / Double(size) <= Cartridge.capacityToSync;
        
        DopamineKit.DebugLog("Cartridge \(actionID) has \(count)/\(size) decisions and \(result ? "does" : "does not") need to sync since it needs at least \(Cartridge.minimumSize) decisions or \(Cartridge.capacityToSync*100)%% capacity.")
        
        return result
    }
    
    func shouldSync() -> Bool {
        return isExpired() || isSizeToSync()
    }
    
}