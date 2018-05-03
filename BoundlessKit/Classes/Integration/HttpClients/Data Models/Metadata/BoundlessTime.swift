//
//  BoundlessTime.swift
//  BoundlessKit
//
//  Created by Akash Desai on 5/1/18.
//

import Foundation

protocol BoundlessID {
    var boundlessid: UUID {get set}
}

var AssociatedBoundlessIDHandle: Void
extension NSObject : BoundlessID {
    var boundlessid:UUID {
        get {
            return objc_getAssociatedObject(self, &AssociatedBoundlessIDHandle) as? UUID ?? {
                let uuid = UUID()
                objc_setAssociatedObject(self, &AssociatedBoundlessIDHandle, uuid, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return uuid
                }()
        }
        set {
            objc_setAssociatedObject(self, &AssociatedBoundlessIDHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

internal class BoundlessTime : NSObject {
    fileprivate static var timeMarkers = [UUID: Date]()
    
    static func start(for object: NSObject, _ start: Date = Date()) -> [String: NSNumber] {
        timeMarkers[object.boundlessid] = start
        return ["start": NSNumber(value: 1000*start.timeIntervalSince1970)]
    }
    
    static func end(for object: NSObject, _ end: Date = Date()) -> [String: NSNumber] {
        var result = ["end": NSNumber(value: 1000*end.timeIntervalSince1970)]
        if let start = timeMarkers.removeValue(forKey: object.boundlessid) {
            result["start"] = NSNumber(value: 1000*start.timeIntervalSince1970)
            result["spent"] = NSNumber(value: 1000*end.timeIntervalSince(start))
        }
        return result
    }
}
