//
//  InstanceMethodActionObserver.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

public class InstanceMethodActionObserverObjc {
    @objc
    public func observed(targetInstance: NSObject, selector: Selector, parameter: AnyObject?) {
        InstanceMethodSwizzle.observed(targetInstance: targetInstance, selector: selector, parameter: parameter)
    }
}

internal class InstanceMethodSwizzle {
    
    internal static var observers = [String: InstanceMethodSwizzle]()
    
    let classType: AnyClass
    let selector: Selector
    let observerdSelector: Selector?
    
    lazy var notification = Notification.Name.init(actionID)
    lazy var actionID: String = [NSStringFromClass(classType), NSStringFromSelector(selector)].joined(separator: "-")
    
    init?(actionID: String) {
        let components = actionID.components(separatedBy: "-")
        if components.count == 2,
            let classType = NSClassFromString(components[0]) {
            self.classType = classType
            self.selector = NSSelectorFromString(components[1])
            self.observerdSelector = nil
            if !self.classType.instancesRespond(to: self.selector) {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func startObserving() {
        if InstanceMethodSwizzle.observers[actionID] == nil {
            InstanceMethodSwizzle.observers[actionID] = self
            //swizzle
        }
    }
    
    func stopObserving() {
        if let _ = InstanceMethodSwizzle.observers.removeValue(forKey: actionID) {
            //unswizzle
        }
    }
    
    func observed(action: BoundlessAction) {
        NotificationCenter.default.post(name: notification, object: action)
    }
    
}
