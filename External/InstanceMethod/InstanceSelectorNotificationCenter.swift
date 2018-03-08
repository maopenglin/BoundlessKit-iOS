//
//  InstanceSelectorNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

struct InstanceSelector {
    let classType: AnyClass
    let selector: Selector
    
    var name: String { return [NSStringFromClass(classType), NSStringFromSelector(selector)].joined(separator: "-") }
    
    init?(_ classType: AnyClass, _ selector: Selector) {
        guard classType.instancesRespond(to: selector) else {
            return nil
        }
        self.classType = classType
        self.selector = selector
    }
    
    init?(_ name: String) {
        let components = name.components(separatedBy: "-")
        if components.count == 2,
            let classType = NSClassFromString(components[0]) {
            let selector = NSSelectorFromString(components[1])
            self.init(classType, selector)
        } else {
            return nil
        }
    }
    
    func swizzle(with other: InstanceSelector) {
        SwizzleHelper.injectSelector(other.classType, other.selector, self.classType, self.selector)
    }
}

@objc
public class InstanceSelectorNotificationCenter : NotificationCenter {
    
    static let _default = InstanceSelectorNotificationCenter()
    override public static var `default`: InstanceSelectorNotificationCenter {
        return _default
    }
    
    fileprivate var activeNotifications = [Notification.Name: InstanceSelector]()
    
    fileprivate var inactiveNotifications = [Notification.Name: InstanceSelector]()
    
    override public func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        guard let aName = aName else {
            // observe all
            super.addObserver(observer, selector: aSelector, name: nil, object: anObject)
            return
        }
        
        if let _ = activeNotifications[aName] {
            // already swizzled
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            return
        }
        
        if let instanceSelector = InstanceSelector(aName),
            let activatedNotification = inactiveNotifications.removeValue(forKey: aName) {
            // reswizzle
            instanceSelector.swizzle(with: activatedNotification)
            activeNotifications[aName] = activatedNotification
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            return
        }
        
        if let instanceSelector = InstanceSelector(aName),
            let notificationSelector = BoundlessObject.createNotificationMethod(for: instanceSelector.classType, instanceSelector.selector, instanceSelector.selector.withRandomString()),
            let newInstanceSelector = InstanceSelector.init(instanceSelector.classType, notificationSelector) {
            // add method and swizzle for the first time
            instanceSelector.swizzle(with: newInstanceSelector)
            activeNotifications[aName] = newInstanceSelector
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            return
        }
        
        print("Error: cannot create instance method for notification<\(aName)>")
    }
    
    override public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        defer {
            super.removeObserver(observer, name: aName, object: anObject)
        }
        
        // for now, unswizzle when observer removed
        if let aName = aName,
            let instanceSelector = InstanceSelector(aName),
            let inactivedNotification = activeNotifications.removeValue(forKey: aName) {
            instanceSelector.swizzle(with: inactivedNotification)
            inactiveNotifications[aName] = inactivedNotification
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



extension InstanceSelector {
    init?(_ notification: Notification.Name) {
        self.init(notification.rawValue)
    }
    
    var notification: Notification.Name {
        return Notification.Name.init(name)
    }
}

extension InstanceSelector : Hashable {
    var hashValue: Int {
        return classType.hash() ^ selector.hashValue
    }
    
    static func ==(lhs: InstanceSelector, rhs: InstanceSelector) -> Bool {
        return NSStringFromSelector(lhs.selector) == NSStringFromSelector(rhs.selector) && NSStringFromClass(lhs.classType) == NSStringFromClass(rhs.classType)
    }
}
