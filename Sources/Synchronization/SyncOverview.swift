//
//  SyncOverview.swift
//  Pods
//
//  Created by Akash Desai on 9/12/16.
//
//

import Foundation

struct SyncOverview {
    
    var utc: Int64
    var timezoneOffset: Int64
    var totalSyncTime: Int64
    var cause: String
    var track: [String: AnyObject]
    var report: [String: AnyObject]
    var cartridges: [[String: AnyObject]]
    
    init(utc: Int64=Int64(1000*NSDate().timeIntervalSince1970),
         timezoneOffset: Int64=Int64(1000*NSTimeZone.defaultTimeZone().secondsFromGMT),
         totalSyncTime: Int64,
         cause: String,
         track: [String: AnyObject],
         report: [String: AnyObject],
         cartridges: [[String: AnyObject]]
        ) {
        self.utc = utc
        self.timezoneOffset = timezoneOffset
        self.totalSyncTime = totalSyncTime
        self.cause = cause
        self.track = track
        self.report = report
        self.cartridges = cartridges
    }
    
}