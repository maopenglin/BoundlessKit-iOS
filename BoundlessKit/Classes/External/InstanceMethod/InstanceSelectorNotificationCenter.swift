//
//  InstanceSelectorNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

internal struct InstanceSelector {
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
}

@objc
public class InstanceSelectorNotificationCenter : NotificationCenter {
    
    static let _default = InstanceSelectorNotificationCenter()
    override public static var `default`: InstanceSelectorNotificationCenter {
        return _default
    }
    
    fileprivate var notifiers = [Notification.Name: InstanceSelectorNotifier]()
    
    override public func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        guard let aName = aName else {
            // observe all
            super.addObserver(observer, selector: aSelector, name: nil, object: anObject)
            return
        }
        
        if let notifier = notifiers[aName] {
            notifier.addObserver()
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            return
        }
        
        if let instanceSelector = InstanceSelector.init(aName.rawValue),
            let notifier = InstanceSelectorNotifier.init(instanceSelector) {
            notifiers[aName] = notifier
            notifier.addObserver()
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            return
        }
        
        print("Error: cannot create instance method for notification<\(aName)>")
    }
    
    override public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        defer {
            super.removeObserver(observer, name: aName, object: anObject)
        }
        if let aName = aName {
            notifiers[aName]?.removeObserver()
        }
    }
}

extension InstanceSelectorNotificationCenter {
    @objc
    public static func post(instance: NSObject, selector: Selector, parameter: AnyObject?) {
        guard let instanceSelector = InstanceSelector(type(of: instance), selector) else {
            print("Not posting because <\(type(of: instance))-\(selector)> is not a valid instance selector")
            return
        }
        
        let notification = Notification.Name.init(instanceSelector.name)
        InstanceSelectorNotificationCenter.default.post(name: notification, object: instance)
        print("Posted instance method notification with name:\(notification.rawValue)")
    }
}



fileprivate class InstanceSelectorNotifier : NSObject {
    
    let instanceSelector: InstanceSelector
    let notificationSelector: InstanceSelector
    private var numberOfObservers = 0
    
    init?(_ instanceSelector: InstanceSelector) {
        if let notificationSelector = BoundlessObject.createNotificationMethod(for: instanceSelector.classType, instanceSelector.selector, instanceSelector.selector.withRandomString()),
            let newInstanceSelector = InstanceSelector.init(instanceSelector.classType, notificationSelector) {
            self.instanceSelector = instanceSelector
            self.notificationSelector = newInstanceSelector
            super.init()
        } else {
            return nil
        }
    }
    
    func addObserver() {
        if numberOfObservers == 0 {
            instanceSelector.swizzle(with: notificationSelector)
        }
        numberOfObservers += 1
    }
    
    func removeObserver() {
        numberOfObservers -= 1
        if numberOfObservers == 0 {
            instanceSelector.swizzle(with: notificationSelector)
        }
    }
}

extension InstanceSelector {
    init?(_ notification: Notification.Name) {
        self.init(notification.rawValue)
    }
    
    var notification: Notification.Name {
        return Notification.Name.init(self.name)
    }
    
    func swizzle(with other: InstanceSelector) {
        SwizzleHelper.injectSelector(other.classType, other.selector, self.classType, self.selector)
    }
}

