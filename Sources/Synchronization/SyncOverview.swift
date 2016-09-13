//
//  SyncOverview.swift
//  Pods
//
//  Created by Akash Desai on 9/12/16.
//
//

import Foundation

struct SyncOverview {
    
    private var utc: Int64
    private var timezoneOffset: Int64
    private var totalSyncTime: Int64
    private var cause: String
    private var trackTriggers: [String: AnyObject]
    private var reportTriggers: [String: AnyObject]
    private var cartridgesTriggers: [[String: AnyObject]]
    
    init(utc: Int64=Int64(1000*NSDate().timeIntervalSince1970),
         timezoneOffset: Int64=Int64(1000*NSTimeZone.defaultTimeZone().secondsFromGMT),
         totalSyncTime: Int64,
         cause: String,
         trackTriggers: [String: AnyObject],
         reportTriggers: [String: AnyObject],
         cartridgeTriggers: [[String: AnyObject]]
        ) {
        self.utc = utc
        self.timezoneOffset = timezoneOffset
        self.totalSyncTime = totalSyncTime
        self.cause = cause
        self.trackTriggers = trackTriggers
        self.reportTriggers = reportTriggers
        self.cartridgesTriggers = cartridgeTriggers
    }
    
    static func startRecordingSync(cause: String, track: Track, report: Report, cartridges: [String: Cartridge]) -> SyncOverview {
        var recording = SyncOverview(totalSyncTime: 0,
                                     cause: cause,
                                     trackTriggers: track.decodeJSONForTriggers(),
                                     reportTriggers: report.decodeJSONForTriggers(),
                                     cartridgeTriggers: [])
        
        for (_, cartridge) in cartridges {
            recording.cartridgesTriggers.append(cartridge.decodeJSONForTriggers())
        }
        
        return recording
    }
    
}