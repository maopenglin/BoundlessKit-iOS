//
//  InstanceSelectorNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

struct InstanceSelector : Hashable {
    let classType: AnyClass
    let selector: Selector
    
    var actionID: String { return [NSStringFromClass(classType), NSStringFromSelector(selector)].joined(separator: "-") }
    
    var notification: Notification.Name { return Notification.Name.init(actionID) }
    
    init?(_ classType: AnyClass, _ selector: Selector) {
        guard classType.instancesRespond(to: selector) else {
            return nil
        }
        self.classType = classType
        self.selector = selector
    }
    
    init?(_ str: String) {
        let components = str.components(separatedBy: "-")
        if components.count == 2,
            let classType = NSClassFromString(components[0]) {
            let selector = NSSelectorFromString(components[1])
            self.init(classType, selector)
        } else {
            return nil
        }
    }
    
    init?(_ notification: Notification.Name) {
        self.init(notification.rawValue)
    }
    
    var hashValue: Int {
        return classType.hash() ^ selector.hashValue
    }
    
    static func ==(lhs: InstanceSelector, rhs: InstanceSelector) -> Bool {
        return NSStringFromSelector(lhs.selector) == NSStringFromSelector(rhs.selector) && NSStringFromClass(lhs.classType) == NSStringFromClass(rhs.classType)
    }
    
}

@objc
public class InstanceSelectorNotificationCenter : NotificationCenter {
    
    static let _default = InstanceSelectorNotificationCenter()
    override public static var `default`: InstanceSelectorNotificationCenter {
        return _default
    }
    
    fileprivate var activelyObserved = [InstanceSelector: InstanceSelector]()
    fileprivate var inactivelyObserved = [InstanceSelector: InstanceSelector]()
    var activeNotifications: [Notification.Name] {
        return activelyObserved.values.flatMap({ (observedInstanceSelector) -> Notification.Name in
            return Notification.Name.init(rawValue: observedInstanceSelector.actionID)
        })
    }
    
    override public func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        guard let notification = aName,
            let instanceSelector = InstanceSelector.init(notification) else {
                return
        }
        
        if let _ = activelyObserved[instanceSelector] {
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
        } else if let reactivatedInstanceSelector = inactivelyObserved[instanceSelector] {
            inactivelyObserved.removeValue(forKey: instanceSelector)
            SwizzleHelper.injectSelector(BoundlessObject.self, reactivatedInstanceSelector.selector, instanceSelector.classType, instanceSelector.selector)
            activelyObserved[instanceSelector] = reactivatedInstanceSelector
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
        } else if let newSelector = BoundlessObject.createReinforcedMethod(for: instanceSelector.classType, instanceSelector.selector, instanceSelector.selector.withRandomString()){
            SwizzleHelper.injectSelector(BoundlessObject.self, newSelector, instanceSelector.classType, instanceSelector.selector)
            guard let newInstanceSelector = InstanceSelector.init(instanceSelector.classType, newSelector) else {
                print("Error: cannot create method for class<\(instanceSelector.selector)> selector<\(instanceSelector.selector)> with newSelector<\(newSelector)>")
                return
            }
            activelyObserved[instanceSelector] = newInstanceSelector
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
        } else {
            print("Error: cannot create method for class<\(instanceSelector.selector)> selector<\(instanceSelector.selector)>")
        }
    }
    
    override public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        defer {
            super.removeObserver(observer, name: aName, object: anObject)
        }
        guard let notification = aName,
            let instanceSelector = InstanceSelector.init(notification) else {
                return
        }
        
        if let inactivatedInstanceSelector = activelyObserved.removeValue(forKey: instanceSelector) {
            SwizzleHelper.injectSelector(BoundlessObject.self, inactivatedInstanceSelector.selector, instanceSelector.classType, instanceSelector.selector)
            inactivelyObserved[instanceSelector] = inactivatedInstanceSelector
        }
    }
    
    @objc
    public static func post(instance: NSObject, selector: Selector, parameter: AnyObject?) {
        guard let instanceSelector = InstanceSelector(type(of: instance), selector) else {
            print("Not posting because <\(type(of: instance))-\(selector)> is not a valid instance selector")
            return
        }
        
        InstanceSelectorNotificationCenter.default.post(name: instanceSelector.notification, object: instance)
        print("Posted instance method notification with name:\(instanceSelector.notification.rawValue)")
    }
    
}
