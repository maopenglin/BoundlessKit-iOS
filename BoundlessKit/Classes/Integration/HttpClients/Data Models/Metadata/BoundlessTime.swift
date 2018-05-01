//
//  BoundlessTime.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/1/18.
//

import Foundation

internal class BoundlessTime : NSObject {
    fileprivate static var timeMarkers = [String: Date]()
    
    static func start(for id: String) -> [String: NSNumber] {
        let start = Date()
        timeMarkers[id] = start
        return ["start": NSNumber(value: 1000*start.timeIntervalSince1970)]
    }
    
    static func end(for id: String) -> [String: NSNumber] {
        let end = NSDate()
        var result = ["end": NSNumber(value: 1000*end.timeIntervalSince1970)]
        if let start = timeMarkers.removeValue(forKey: id) {
            result["start"] = NSNumber(value: 1000*start.timeIntervalSince1970)
            result["spent"] = NSNumber(value: 1000*end.timeIntervalSince(start))
        }
        return result
    }
}
