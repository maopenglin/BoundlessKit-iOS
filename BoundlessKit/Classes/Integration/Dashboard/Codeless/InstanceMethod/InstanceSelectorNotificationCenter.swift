//
//  InstanceSelectorNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

internal extension Array where Element == Notification.Name {
    static var visualizerNotifications: [Notification.Name] {
        return [.UIApplicationSendAction]
            + UIViewControllerChildrenDidAppear
            + UICollectionViewControllerChildrenDidSelect
    }
    
    static var UIViewControllerChildrenDidAppear: [Notification.Name] {
        return forSubclasses(parentClass: UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))
    }
    
    static var UICollectionViewControllerChildrenDidSelect: [Notification.Name] {
        return forSubclasses(parentClass: UICollectionViewController.self, #selector(UICollectionViewController.collectionView(_:didSelectItemAt:)))
    }
    
    static func forSubclasses(parentClass: AnyClass, _ selector: Selector) -> [Notification.Name] {
        return (InstanceSelectorHelper.classesInheriting(parentClass) as? [AnyClass])?.flatMap({InstanceSelector($0, selector)?.notificationName}) ?? []
    }
    
    static func forClassesConforming(to searchProtocol: Protocol, with selector: Selector) -> [Notification.Name] {
        return (InstanceSelectorHelper.classesConforming(searchProtocol) as? [AnyClass])?.flatMap({InstanceSelector.init($0, selector)?.notificationName}) ?? []
    }
}

internal extension Notification.Name {
    static let UIApplicationSendAction: Notification.Name = {
        return InstanceSelector(UIApplication.self, #selector(UIApplication.sendAction(_:to:from:for:)))!.notificationName
    }()
    
    static let UIViewControllerDidAppear: Notification.Name = {
        return InstanceSelector(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))!.notificationName
    }()
    
    static let UIViewControllerDidDisappear: Notification.Name = {
        return InstanceSelector(UIViewController.self, #selector(UIViewController.viewDidDisappear(_:)))!.notificationName
    }()
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
//                BKLog.debug("Added observer for instance method:\(aName.rawValue)")
                return
            }
            
            if let instanceSelector = InstanceSelector(aName.rawValue),
                let notifier = InstanceSelectorNotifier(instanceSelector) {
                self.notifiers[aName] = notifier
                notifier.addObserver(observer as AnyObject)
                super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
//                BKLog.debug("Added first observer for instance method:\(aName.rawValue)")
                return
            }
            
            BKLog.print(error: "Cannot create  for notification for <\(aName)>")
        }
    }
    
    override public func removeObserver(_ observer: Any) {
        self.removeObserver(observer, name: nil, object: nil)
    }
    
    override public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        queue.sync {
            if let aName = aName {
                if let notifier = self.notifiers[aName] {
                    notifier.removeObserver(observer as AnyObject)
//                    BKLog.debug("Removed observer for notification:\(aName.rawValue)")
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
    
    let originalSelector: InstanceSelector
    let notificationSelector: InstanceSelector
    private var observers = [WeakObject]()
    
    init?(_ instanceSelector: InstanceSelector) {
        guard let notificationMethod = InstanceSelectorHelper.createMethod(beforeInstance: instanceSelector.classType, selector: instanceSelector.selector, with: InstanceSelectorNotifier.postInstanceSelection),
            let notificationSelector = InstanceSelector(instanceSelector.classType, notificationMethod) else {
            BKLog.print(error: "Could not create notification method for actionID<\(instanceSelector.notificationName)")
            return nil
        }
            self.originalSelector = instanceSelector
            self.notificationSelector = notificationSelector
            super.init()
    }
    
    func addObserver(_ observer: AnyObject) {
        if observers.count == 0 {
            originalSelector.exchange(with: notificationSelector)
        }
        observers.append(WeakObject(value: observer))
    }
    
    func removeObserver(_ observer: AnyObject) {
        let oldCount = observers.count
        observers = observers.filter({$0.value != nil && $0.value !== observer})
        if observers.count == 0 && oldCount != 0 {
            originalSelector.exchange(with: notificationSelector)
        }
    }
    
    func removeAllObservers() -> [AnyObject] {
        if observers.count != 0 {
            originalSelector.exchange(with: notificationSelector)
        }
        let oldObservers = observers.flatMap({$0.value})
        observers = []
        return oldObservers
    }
    
    static var postInstanceSelection: InstanceSelectionBlock {
        return { aClassType, aSelector, aTarget, aSender in
            guard let classType = aClassType,
                let selector = aSelector,
                let instanceSelector = InstanceSelector(classType, selector) else {
                    BKLog.debug("Not posting because <\(String(describing: aClassType))-\(String(describing: aSelector))> is not a valid instance selector")
                    return
            }
            
            InstanceSelectorNotificationCenter.default.post(name: instanceSelector.notificationName,
                                                            object: nil,
                                                            userInfo: ["classType": classType,
                                                                       "selector": selector,
                                                                       "sender": aSender as Any,
                                                                       "target": aTarget as Any,
                                                                       ])
            
//            BKLog.print("Posted instance method notification with name:\(instanceSelector.notificationName.rawValue)")
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
    
    var notificationName: Notification.Name {
        return Notification.Name(self.name)
    }
    
    func exchange(with other: InstanceSelector) {
        InstanceSelectorHelper.injectSelector(other.classType, other.selector, self.classType, self.selector)
    }
}
