//
//  SyncTimer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class TimeSyncer {
    
    private static let KEY_PREFIX = "DopamineTimer"
    private static let KEY_SUFFIX_START_TIME = "StartTime"
    private static let KEY_SUFFIX_DURATION = "Duration"
    
    private init() { }
    
    static func create(key: String, duration: Int=48 * 3600000, ifNotExists: Bool) {
        let defaults = NSUserDefaults.standardUserDefaults()
        if(ifNotExists &&
            defaults.valueForKey(KEY_PREFIX + key + KEY_SUFFIX_START_TIME) != nil &&
            defaults.valueForKey(KEY_PREFIX + key + KEY_SUFFIX_DURATION) != nil) {
            return
        }
        let currentTime = TimeSyncer.UTCTime()
        defaults.setValue(currentTime, forKey: KEY_PREFIX + key + KEY_SUFFIX_START_TIME)
        defaults.setValue(duration, forKey: KEY_PREFIX + key + KEY_SUFFIX_DURATION)
    }
    
    static func reset(key: String, duration: Int?=nil) {
        if let expiry = duration {
            create(key, duration: expiry, ifNotExists: false)
        } else {
            create(key, ifNotExists: false)
        }
    }
    
    static func isExpired(key: String) -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let startTime = defaults.valueForKey(KEY_PREFIX + key + KEY_SUFFIX_START_TIME) as? Int,
            duration = defaults.valueForKey(KEY_PREFIX + key + KEY_SUFFIX_DURATION) as? Int {
            return TimeSyncer.UTCTime() > (startTime + duration)
        } else {
            return true
        }
    }
    
    static func progress(key: String) -> Double {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let startTime = defaults.valueForKey(KEY_PREFIX + key + KEY_SUFFIX_START_TIME) as? Int,
            duration = defaults.valueForKey(KEY_PREFIX + key + KEY_SUFFIX_DURATION) as? Int {
            let timeElapsed = UTCTime() - startTime
            if (timeElapsed > duration){
                return 1.0
            } else {
                return Double(timeElapsed) / Double(duration)
            }
        } else {
            return 1.0
        }
    }
    
    static func UTCTime() -> Int {
        return Int( 1000*NSDate().timeIntervalSince1970 )
    }
        
}