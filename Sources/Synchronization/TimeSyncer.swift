//
//  SyncTimer.swift
//  Pods
//
//  Created by Akash Desai on 7/22/16.
//
//

import Foundation

class TimeSyncer {
    
    static func UTCTime() -> Int {
        return Int( 1000*NSDate().timeIntervalSince1970 )
    }
    
    private static let KEY_PREFIX = "DopamineTimer"
    private static let KEY_SUFFIX_START_TIME = "StartTime"
    private static let KEY_SUFFIX_DURATION = "Duration"
    
    private init() { }
    
    static func create(key: String){
        let hours = 48 * 3600000
        return TimeSyncer.create(key, duration: hours)
    }
    
    static func create(key: String, duration: Int){
        let defaults = NSUserDefaults.standardUserDefaults()
        let currentTime = TimeSyncer.UTCTime()
        defaults.setValue(currentTime, forKey: KEY_PREFIX+KEY_SUFFIX_START_TIME+KEY_SUFFIX_START_TIME)
        defaults.setValue(duration, forKey: KEY_PREFIX+KEY_SUFFIX_START_TIME+KEY_SUFFIX_DURATION)
        
    }
    
    static func hasExpired(key: String) -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let startTime = defaults.valueForKey(KEY_PREFIX+key+KEY_SUFFIX_START_TIME) as? Int,
            duration = defaults.valueForKey(KEY_PREFIX+key+KEY_SUFFIX_DURATION) as? Int {
            return TimeSyncer.UTCTime() > (startTime + duration)
        } else {
            return true
        }
    }
    
    static func progress(key: String) -> Double {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let startTime = defaults.valueForKey(KEY_PREFIX+key+KEY_SUFFIX_START_TIME) as? Int,
            duration = defaults.valueForKey(KEY_PREFIX+key+KEY_SUFFIX_DURATION) as? Int {
            let timeElapsed = Double(UTCTime() - startTime)
            return timeElapsed / Double(duration)
        } else {
            return 1.0
        }
    }
        
}