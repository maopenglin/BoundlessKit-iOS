//
//  EventLogger.swift
//  Pods
//
//  Created by Akash Desai on 8/21/17.
//
//

import Foundation

public class EventLogger : NSObject {
    
    public static let EVENT_TYPE_APP_FOCUS: NSString = "appFocus"
    public static let EVENT_TYPE_VIEW_CONTROLLER: NSString = "viewController"
    
    public static func logEvent(withType event: String, withTag tag: String) {
//        DopamineKit.debugLog("Got event:\(event) with tag:\(tag)")
        
        DopamineKit.track(event, metaData: ["tag":tag,
        ])
    }
    
    public static func logEvent(withUIViewController viewController: UIViewController, withTag tag: String) {
//        DopamineKit.debugLog("Got event:\(EVENT_TYPE_VIEW_CONTROLLER) for UIViewController with class :\(NSStringFromClass(type(of:viewController))) with tag:\(tag)")
        
        DopamineKit.track(EVENT_TYPE_VIEW_CONTROLLER as String, metaData:
            ["UIViewController": [
                "classname": NSStringFromClass(type(of:viewController)),
                "tag": tag
                ]
            ])
    }
    
}
