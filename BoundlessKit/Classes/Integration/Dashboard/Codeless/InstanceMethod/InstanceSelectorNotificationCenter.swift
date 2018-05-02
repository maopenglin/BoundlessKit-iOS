//
//  InstanceSelectorNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

@objc
class Nothing : NSObject {
    
}

extension InstanceSelectorNotificationCenter {
    internal static var visualizerNotifications: [Notification.Name] {
        return [actionMessagesNotification]
            + viewControllerDidAppearNotifications
            + collectionViewControllerDidSelectNotifications
    }
    
    internal static var actionMessagesNotification: Notification.Name {
        return InstanceSelector(UIApplication.self, #selector(UIApplication.sendAction(_:to:from:for:)))!.notification
    }
    
    internal static var viewControllerDidAppearNotifications: [Notification.Name] {
        return forSubclasses(parentClass: UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))
    }
    
    internal static var viewControllerDidAppearNotification: Notification.Name {
        return InstanceSelector(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))!.notification
    }
    
    internal static var collectionViewControllerDidSelectNotifications: [Notification.Name] {
        return forSubclasses(parentClass: UICollectionViewController.self, #selector(UICollectionViewController.collectionView(_:didSelectItemAt:)))
    }
    
    internal static func forSubclasses(parentClass: AnyClass, _ selector: Selector) -> [Notification.Name] {
        if let classes = SwizzleHelper.classesInheriting(parentClass) as? [AnyClass] {
            return classes.flatMap({InstanceSelector($0, selector)?.notification})
        }
        return []
    }
    
    internal static func forClassesConforming(to searchProtocol: Protocol, with selector: Selector) -> [Notification.Name] {
        if let classes = SwizzleHelper.classesConforming(searchProtocol) as? [AnyClass] {
            return classes.flatMap({InstanceSelector.init($0, selector)?.notification})
        }
        return []
    }
}

internal class InstanceSelectorNotificationCenter : NotificationCenter {
    
    static let _default = InstanceSelectorNotificationCenter()
    override public class var `default`: InstanceSelectorNotificationCenter {
        return _default
    }
    
    fileprivate var notifiers = [Notification.Name: InstanceSelectorNotifier]()
    fileprivate let queue = DispatchQueue(label: "InstanceSelectorObserverQueue")
    
    override public func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
        queue.sync {
            guard let aName = aName else {
                // observe all
                super.addObserver(observer, selector: aSelector, name: nil, object: anObject)
                return
            }
            
            if let notifier = self.notifiers[aName] {
                notifier.addObserver(observer as AnyObject)
                super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
                BKLog.debug("Added observer for notification:\(aName.rawValue)")
                return
            }
            
            if let instanceSelector = InstanceSelector.init(aName.rawValue),
                let notifier = InstanceSelectorNotifier.init(instanceSelector) {
                self.notifiers[aName] = notifier
                notifier.addObserver(observer as AnyObject)
                BKLog.debug("Added observer for new notification:\(aName.rawValue)")
                super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
                return
            }
            
            BKLog.print(error: "Cannot create instance method for notification<\(aName)>")
        }
    }
    
    override public func removeObserver(_ observer: Any) {
        queue.sync {
            self.removeObserver(observer, name: nil, object: nil)
        }
    }
    
    override public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        queue.sync {
            if let aName = aName {
                if let notifier = self.notifiers[aName] {
                    notifier.removeObserver(observer as AnyObject)
                    BKLog.debug("Removed observer for notification:\(aName.rawValue)")
                }
            } else {
                for notifier in self.notifiers.values {
                    notifier.removeObserver(observer as AnyObject)
                }
            }
            super.removeObserver(observer, name: aName, object: anObject)
        }
    }
    
    public func removeAllObservers(name aName: NSNotification.Name?) {
        queue.sync {
            if let aName = aName {
                for observer in self.notifiers[aName]?.removeAllObservers() ?? [] {
                    super.removeObserver(observer, name: aName, object: nil)
                }
            } else {
                for (notification, notifier) in self.notifiers {
                    for observer in notifier.removeAllObservers() {
                        super.removeObserver(observer, name: notification, object: nil)
                    }
                }
            }
        }
    }
}

fileprivate class InstanceSelectorNotifier : NSObject {
    
    private struct WeakObject {
        weak var value: AnyObject?
        init (value: AnyObject) {
            self.value = value
        }
    }
    
    let instanceSelector: InstanceSelector
    let notificationSelector: InstanceSelector
    private var observers = [WeakObject]()
    
    init?(_ instanceSelector: InstanceSelector) {
        guard let notificationMethod = BoundlessObject.createTrampoline(for: instanceSelector.classType, selector: instanceSelector.selector, with: InstanceSelectorNotifier.postInstanceSelectorNotificationBlock) else {
            BKLog.print(error: "Could not create trampoline for actionID<\(instanceSelector.notification)")
            return nil
        }
        if let notificationSelector = InstanceSelector.init(instanceSelector.classType, notificationMethod) {
            self.instanceSelector = instanceSelector
            self.notificationSelector = notificationSelector
            super.init()
        } else {
            return nil
        }
    }
    
    func addObserver(_ observer: AnyObject) {
        if observers.count == 0 {
            instanceSelector.swizzle(with: notificationSelector)
        }
        observers.append(WeakObject(value: observer))
    }
    
    func removeObserver(_ observer: AnyObject) {
        let oldCount = observers.count
        observers = observers.filter({$0.value != nil && $0.value !== observer})
        if observers.count == 0 && oldCount != 0 {
            instanceSelector.swizzle(with: notificationSelector)
        }
    }
    
    func removeAllObservers() -> [AnyObject] {
        if observers.count != 0 {
            instanceSelector.swizzle(with: notificationSelector)
        }
        let oldObservers = observers.flatMap({$0.value})
        observers = []
        return oldObservers
    }
    
    static var postInstanceSelectorNotificationBlock: SelectorTrampolineBlock {
        return { aClassType, aSelector, aTarget, aSender in
            guard let classType = aClassType,
                let selector = aSelector,
                let instanceSelector = InstanceSelector(classType, selector) else {
                    BKLog.debug("Not posting because <\(String(describing: aClassType))-\(String(describing: aSelector))> is not a valid instance selector")
                    return
            }
            let notification = Notification.Name.init(instanceSelector.name)
            InstanceSelectorNotificationCenter.default.post(name: notification,
                                                            object: nil,
                                                            userInfo: ["classType": classType,
                                                                       "selector": selector,
                                                                       "sender": aSender as Any,
                                                                       "target": aTarget as Any,
                                                                       ]
            )
//            BKLog.print("Posted instance method notification with name:\(notification.rawValue)")
        }
    }
}

fileprivate struct InstanceSelector {
    let classType: AnyClass
    let selector: Selector
    
    var name: String { return [NSStringFromClass(classType), NSStringFromSelector(selector)].joined(separator: "-") }
    
    init?(_ classType: AnyClass, _ selector: Selector) {
        guard classType.instancesRespond(to: selector) else {
            BKLog.debug("Could not initialize InstanceSelector because class <\(classType)> does not respond to selector <\(selector)>")
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
