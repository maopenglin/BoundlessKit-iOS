//
//  InstanceMethodActionObserver.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

@objc
public class InstanceMethodNotification : NSObject {
    @objc
    public static func post(targetInstance: NSObject, selector: Selector, parameter: AnyObject?) {
        let action = InstanceMethodAction.init(target: targetInstance, selector: selector, parameter: parameter)
        NotificationCenter.default.post(name: NSNotification.Name.init(action.name), object: action)
        print("Posted instance method notification with name:\(action.name)")
    }
}

internal class InstanceMethodSwizzle {
    
    internal static var swizzles = [String: InstanceMethodSwizzle]()
    
    let classType: AnyClass
    let selector: Selector
    var observerdSelector: Selector?
    
    lazy var actionID: String = [NSStringFromClass(classType), NSStringFromSelector(selector)].joined(separator: "-")
    lazy var notification = Notification.Name.init(actionID)
    
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
    
    func register() {
        if InstanceMethodSwizzle.swizzles[actionID] == nil,
            let observerdSelector = BoundlessObject.createReinforcedMethod(for: classType, selector, selector.withRandomString()) {
            SwizzleHelper.injectSelector(BoundlessObject.self, observerdSelector, classType, selector)
            print("Swizzled method for class \(classType) selector \(selector) with observerdSelector \(observerdSelector)")
            self.observerdSelector = observerdSelector
            NotificationCenter.default.addObserver(self, selector: #selector(self.onAction(notification:)), name: notification, object: nil)
            InstanceMethodSwizzle.swizzles[actionID] = self
        }
    }
    
    func unregister() {
        if let swizzle = InstanceMethodSwizzle.swizzles.removeValue(forKey: actionID),
            let observerdSelector = swizzle.observerdSelector {
            SwizzleHelper.injectSelector(BoundlessObject.self, observerdSelector, classType, selector)
            print("Unwizzled method for class \(classType) observerdSelector \(observerdSelector) for selector \(selector)")
            self.observerdSelector = nil
            NotificationCenter.default.removeObserver(self, name: notification, object: nil)
        }
    }
    
    @objc
    func onAction(notification: Notification) {
        print("Got swizzle notification:\(notification.name)")
    }
    
}
