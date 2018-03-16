//
//  InstanceSelectorNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

@objc
public class InstanceSelectorNotificationCenter : NotificationCenter {
    
    internal static var actionMessagesNotification: Notification.Name = {
        return InstanceSelector.init(UIApplication.self, #selector(UIApplication.sendAction(_:to:from:for:)))!.notification
    }()
    
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
            print("Added observer for notification:\(aName.rawValue)")
            return
        }
        
        if let instanceSelector = InstanceSelector.init(aName.rawValue),
            let notifier = InstanceSelectorNotifier.init(instanceSelector) {
            notifiers[aName] = notifier
            notifier.addObserver()
            print("Added new observer for notification:\(aName.rawValue)")
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            return
        }
        
        BKLog.error("Cannot create instance method for notification<\(aName)>")
    }
    
    override public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        defer {
            super.removeObserver(observer, name: aName, object: anObject)
        }
        if let aName = aName {
            notifiers[aName]?.removeObserver()
            print("Removed observer for notification:\(aName.rawValue)")
        }
    }
}

extension InstanceSelectorNotificationCenter {
    @objc
    public static func postSelection(targetInstance: NSObject, selector: Selector, senderInstance: AnyObject?) {
        guard let instanceSelector = InstanceSelector(type(of: targetInstance), selector) else {
            print("Not posting because <\(type(of: targetInstance))-\(selector)> is not a valid instance selector")
            return
        }
        let notification = Notification.Name.init(instanceSelector.name)
        InstanceSelectorNotificationCenter.default.post(name: notification, object: targetInstance, userInfo: ["senderInstance":senderInstance as Any ])
        print("Posted instance method notification with name:\(notification.rawValue)")
    }
    
    @objc
    public static func postMessage(classType: AnyClass, selector: Selector) {
        guard let instanceSelector = InstanceSelector(classType, selector) else { return }
        let notification = Notification.Name.init(instanceSelector.name)
        InstanceSelectorNotificationCenter.default.post(name: actionMessagesNotification,
                                                        object: nil,
                                                        userInfo: ["actionID": instanceSelector.name,
                                                                   "target": NSStringFromClass(instanceSelector.classType),
                                                                   "selector": NSStringFromSelector(instanceSelector.selector)]
        )
        print("Posted action message notification with name:\(notification.rawValue) actionID:\(instanceSelector.name)")
    }
}



fileprivate class InstanceSelectorNotifier : NSObject {
    
    let instanceSelector: InstanceSelector
    let notificationSelector: InstanceSelector
    private var numberOfObservers = 0
    
    init?(_ instanceSelector: InstanceSelector) {
        if instanceSelector.classType == UIApplication.self && instanceSelector.selector == #selector(UIApplication.sendAction(_:to:from:for:)),
            let notificationSelector = InstanceSelector.init(BoundlessApp.self, #selector(BoundlessApp.notifyMessages__sendAction(_:to:from:for:))) {
            self.instanceSelector = instanceSelector
            self.notificationSelector = notificationSelector
            super.init()
        } else if let notificationMethod = BoundlessObject.createNotificationMethod(for: instanceSelector.classType, selector: instanceSelector.selector),
            let notificationSelector = InstanceSelector.init(instanceSelector.classType, notificationMethod) {
            self.instanceSelector = instanceSelector
            self.notificationSelector = notificationSelector
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
        guard numberOfObservers > 0 else {
            return
        }
        numberOfObservers -= 1
        if numberOfObservers == 0 {
            instanceSelector.swizzle(with: notificationSelector)
        }
    }
    
}


fileprivate struct InstanceSelector {
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

