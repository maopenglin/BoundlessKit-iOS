//
//  BoundlessTimer.swift
//  BoundlessKit
//
//  Created by Akash Desai on 11/9/17.
//

import Foundation


@objc public class BoundlessTimer : NSObject {
    
    fileprivate static var timeMarkers = NSMutableDictionary()
    
    @objc public static func trackStartTime(for id: String) -> NSDictionary {
        let start = NSDate()
        timeMarkers.setValue(start, forKey: id)
        return ["start": NSNumber(value: 1000*start.timeIntervalSince1970)]
    }
    
    @objc public static func timeTracked(for id: String) -> NSDictionary {
        defer {
            timeMarkers.removeObject(forKey: id)
        }
        let end = NSDate()
        let start = timeMarkers.value(forKey: id) as? NSDate
        let spent = (start == nil) ? 0 : (1000*end.timeIntervalSince(start! as Date))
        return ["start": NSNumber(value: (start == nil) ? 0 : (1000*start!.timeIntervalSince1970)),
                "end": NSNumber(value: 1000*end.timeIntervalSince1970),
                "spent": NSNumber(value: spent)
        ]
    }
    
}
