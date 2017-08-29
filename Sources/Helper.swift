//
//  Helper.swift
//  Pods
//
//  Created by Akash Desai on 8/24/17.
//
//

import Foundation

public class Helper: NSObject {
    
//    public static var liveRecording = false
//    
//    @objc public static var recordedTouches: [String:Set<String>] {
//        get {
//            if let dict = UserDefaults.standard.object(forKey: #keyPath(recordedTouches)) as? [String:[String]] {
//                return dict.mapPairs{($0, Set($1))}
//            } else {
//                return [:]
//            }
//        }
//        set {
//            DopamineKit.debugLog("Storing custom swizzles...\n\t\t\(newValue)")
//            UserDefaults.standard.set(newValue.mapPairs{($0, Array($1))}, forKey: #keyPath(recordedTouches))
//        }
//    }
//    
//    public static var lastTouch: UITouch? {
//        didSet {
//            if let touch = lastTouch,
//                let control = touch.view as? UIControl {
//                var recordedTouches = Helper.recordedTouches
//                if liveRecording {
//                    recordedTouches += control.targetActionPairs()
//                    Helper.recordedTouches = recordedTouches
//                } else {
//                    var hasBeenRecorded = false
//                    for target in control.allTargets {
//                        if let targetActions = control.actions(forTarget: target, forControlEvent: control.allControlEvents) {
//                            for action in targetActions {
//                                if let recordedActions = recordedTouches[String.classNameFromTargetDescription(target.description)] {
//                                    if recordedActions.contains(action) {
//                                        hasBeenRecorded = true
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    if hasBeenRecorded {
//                        DopamineKit.debugLog("Touch action has been previously recorded")
//                        control.showStarburst(at: touch.location(in: control), completion: {_ in })
//                    }
//                }
//            }
//        }
//    }
//    
//    public static func processSilentNotification(payload: [String : Any]) {
//        DopamineKit.debugLog(payload.description)
//        
//        if let recordingEnabled = payload["DKRecordActions"] as? Bool {
//            Helper.liveRecording = recordingEnabled
//            DopamineKit.debugLog("Recording set to:\(recordingEnabled)")
//        }
    //    }
    
    public static func sendTouch(touch: UITouch) {
        
    }
    
    public static func sendEvent(event: UIEvent) {
        print(event.description)
    }
}

fileprivate extension UIControlEvents {
    
    static let allTouchEventsForReal: [UIControlEvents] = [.touchDown, .touchDownRepeat, .touchDragInside, .touchDragOutside, .touchDragEnter, .touchDragExit, .touchUpInside, .touchUpOutside, .touchCancel]
    
    
    var description: String { get { return UIControlEvents.nameForRawTouchEvents[self.rawValue] ?? "<No description set for \(self)>" } }
    
    private static let nameForRawTouchEvents: [UInt: String] = [UIControlEvents.touchDown.rawValue: "touchDown",
                                                                UIControlEvents.touchDownRepeat.rawValue: "touchDownRepeat",
                                                                UIControlEvents.touchDragInside.rawValue: "touchDragInside",
                                                                UIControlEvents.touchDragOutside.rawValue: "touchDragOutside",
                                                                UIControlEvents.touchDragEnter.rawValue: "touchDragEnter",
                                                                UIControlEvents.touchDragExit.rawValue: "touchDragExit",
                                                                UIControlEvents.touchUpInside.rawValue: "touchUpInside",
                                                                UIControlEvents.touchUpOutside.rawValue: "touchUpOutside",
                                                                UIControlEvents.touchCancel.rawValue: "touchCancel",
                                                                ]
    
}

extension UIControl {
    
    func targetActionPairs() -> [String : Set<String>] {
        var _targetActionPairs:[String : Set<String>] = [:]
        
        for target in self.allTargets {
            var actionNames: Set<String> = Set([])
            for touchEvent in UIControlEvents.allTouchEventsForReal {
                if let targetActions = self.actions(forTarget: target, forControlEvent: touchEvent) {
                    for action in targetActions {
                        actionNames.insert("\(touchEvent.description):\(action)")
                    }
                }
            }
            
            if actionNames.count > 0 {
                _targetActionPairs[String.classNameFromTargetDescription(target.description)] = actionNames
            }
        }
        
        return _targetActionPairs
    }
    
}

extension String {
    static func classNameFromTargetDescription(_ str: String) -> String {
        return str.components(separatedBy: ":")[0].replacingOccurrences(of: "<", with: "")
    }
}

extension Dictionary where Key==String, Value==Set<String> {
    static func += (lhs: inout [Key: Value], rhs: [Key: Value]) {
        rhs.forEach{ key, values in
            if let prevousValues = lhs[key] {
                lhs[key] = prevousValues.union(values)
            } else {
                lhs[key] = values
            }
        }
    }
}

extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    func mapPairs<OutKey: Hashable, OutValue>(_ transform: (Element) throws -> (OutKey, OutValue)) rethrows -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(try map(transform))
    }
}

extension UIResponder {
    func getParentResponders() -> [String]{
        var parentResponders: [String] = []
        getParentResponders(responders: &parentResponders)
        return parentResponders
    }
    
    func getParentResponders(responders: inout [String]) {
        responders.append(NSStringFromClass(type(of:self)))
        if let next = self.next {
            next.getParentResponders(responders: &responders)
        }
    }
}
