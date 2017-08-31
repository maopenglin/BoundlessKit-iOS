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
    public static let EVENT_TYPE_TOUCH: NSString = "touch"
    
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
    
    public static func logEvent(withTouch touch: UITouch, gestureName: String) {
        var message = "Got event:\(EVENT_TYPE_TOUCH)(\(gestureName))"
        if let control = touch.view as? UIControl {
            message += " for UIControl with class:\(type(of: control))"
            if let control = control as? UIButton,
                let titleLabel = control.titleLabel,
                let titleText = titleLabel.text
            {
                message += " with title:(\(titleText))"
            }
            message += " and target-action pairs:\(control.targetActionPairs())"
            DopamineKit.debugLog("Responder chain:\(control.getParentResponders().joined(separator: ">"))")
        } else if let view = touch.view {
            message += " for UIView(\(type(of: view)))" // in UIViewController(\(type(of)))"
        } else {
            message += " for non-view type (like gesture recognizer)"
        }
        
        DopamineKit.debugLog(message)
    }
    
}
