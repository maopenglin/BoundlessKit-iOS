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
    public static let EVENT_TYPE_TOUCHED: NSString = "touched"
    
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
    
    public static func logEvent(withTouch touch: UITouch, gestureName: String) {
        var message = "Got event:\(EVENT_TYPE_TOUCHED)(\(gestureName))"
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


fileprivate extension UITouch {
    
//    enum GestureType : String {
//        case unknown, tap, longPress, swipe
//    }
//    
//    struct TouchRecord {
//        let view: UIView
//        let location: CGPoint
//    }
//    
//    static var touch1: TouchRecord?
//    static var touch2: TouchRecord?
//    
//    func analyze(event: UIEvent) {
//        event.allTouches.anyO
//    }
    
    
}


