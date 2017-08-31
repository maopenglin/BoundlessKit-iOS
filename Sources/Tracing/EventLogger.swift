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
    public static let EVENT_TYPE_APPEARED: NSString = "appeared"
    
    public static func logEvent(withType event: String, withTag tag: String) {
        DopamineKit.debugLog("Got event:\(event) with tag:\(tag)")
        
        DopamineKit.track(event, metaData: ["tag":tag,
        ])
    }
    
    public static func logEvent(withUIViewController viewController: UIViewController) {
        DopamineKit.debugLog("Got event:\(EVENT_TYPE_APPEARED) for UIViewController with class :\(NSStringFromClass(type(of:viewController)))")
        
        DopamineKit.track(EVENT_TYPE_APPEARED as String, metaData:
            ["UIViewController":
                ["classname": NSStringFromClass(type(of:viewController))]
            ])
        
    }
    
}
