//
//  InstanceSelectorNotificationCenter.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/7/18.
//

import Foundation

extension InstanceSelectorNotificationCenter {
    internal static var visualizerNotifications: [Notification.Name] = {
        return [actionMessagesNotification,
                viewControllerDidAppearNotification
            ] + collectionViewControllerDidSelectNotifications
    }()
    
    internal static var actionMessagesNotification: Notification.Name = {
        return InstanceSelector.init(UIApplication.self, #selector(UIApplication.sendAction(_:to:from:for:)))!.notification
    }()
    
    internal static var viewControllerDidAppearNotification: Notification.Name = {
        return InstanceSelector.init(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)))!.notification
    }()
    
    internal static var collectionViewControllerDidSelectNotifications: [Notification.Name] = {
        return forSubclasses(parentClass: UICollectionViewController.self, #selector(UICollectionViewController.collectionView(_:didSelectItemAt:))).map({$0.notification})
    }()
    
    //    internal static var collectionViewControllerDidSelectNotification: Notification.Name = {
    //        let d = UICollectionViewController()
    //        d.collectionView(<#T##collectionView: UICollectionView##UICollectionView#>, didSelectItemAt: <#T##IndexPath#>)
    //        return InstanceSelector.init(UICollectionView.self, #selector(UICollectionView.selectItem(at:animated:scrollPosition:)))!.notification
    //    }()
    
    //    internal static var collectionViewControllerDidSelectNotification: Notification.Name = {
    //        return InstanceSelector.init(UICollectionView.self, #selector(UICollectionView.selectItem(at:animated:scrollPosition:)))!.notification
    //    }()
    
    fileprivate static func forSubclasses(parentClass: AnyClass, _ selector: Selector) -> [InstanceSelector] {
        if let classes = SwizzleHelper.classesInheriting(parentClass) as? [AnyClass] {
            for c in classes {
                print("Class:\(c)")
            }
            for c in classes.flatMap({InstanceSelector.init($0, selector)}) {
                print("Valid class:\(c)")
            }
            return classes.flatMap({InstanceSelector.init($0, selector)})
        }
        return []
    }
    fileprivate static func forClassesConforming(to searchProtocol: Protocol, with selector: Selector) -> [InstanceSelector] {
        if let classes = SwizzleHelper.classesConforming(searchProtocol) as? [AnyClass] {
            for c in classes {
                print("Class:\(c)")
            }
            for c in classes.flatMap({InstanceSelector.init($0, selector)}) {
                print("Valid class:\(c)")
            }
            return classes.flatMap({InstanceSelector.init($0, selector)})
        }
        return []
    }
}

internal class InstanceSelectorNotificationCenter : NotificationCenter {
    
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
            notifier.addObserver(observer as AnyObject)
            super.addObserver(observer, selector: aSelector, name: aName, object: anObject)
            print("Added observer for notification:\(aName.rawValue)")
            return
        }
        
        if let instanceSelector = InstanceSelector.init(aName.rawValue),
            let notifier = InstanceSelectorNotifier.init(instanceSelector) {
            notifiers[aName] = notifier
            notifier.addObserver(observer as AnyObject)
            print("Added observer for new notification:\(aName.rawValue)")
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
            notifiers[aName]?.removeObserver(observer as AnyObject)
            print("Removed observer for notification:\(aName.rawValue)")
        } else {
            for notifier in notifiers.values {
                notifier.removeObserver(observer as AnyObject)
            }
        }
    }
    
    public override func removeObserver(_ observer: Any) {
        super.removeObserver(observer)
        for (_, notifier) in notifiers {
            notifier.removeObserver(observer as AnyObject)
        }
    }
}

fileprivate class InstanceSelectorNotifier : NSObject {
    
    let instanceSelector: InstanceSelector
    let notificationSelector: InstanceSelector
    private var observers = [WeakObject]()
    struct WeakObject {
        weak var value: AnyObject?
        init (value: AnyObject) {
            self.value = value
        }
    }
    
    init?(_ instanceSelector: InstanceSelector) {
        if let notificationMethod = BoundlessObject.createTrampoline(for: instanceSelector.classType, selector: instanceSelector.selector, with: InstanceSelectorNotifier.postInstanceSelectorNotificationBlock),
            let notificationSelector = InstanceSelector.init(instanceSelector.classType, notificationMethod) {
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
    
    static var postInstanceSelectorNotificationBlock: SelectorTrampolineBlock {
        return { target, selector, sender in
            guard let targetInstance = target as? NSObject,
                let targetSelector = selector,
                let instanceSelector = InstanceSelector(type(of: targetInstance), targetSelector) else {
                    print("Not posting because <\(String(describing: target))-\(String(describing: selector))> is not a valid instance selector")
                    return
            }
            InstanceSelectorNotificationCenter.default.post(name: instanceSelector.notification,
                                                            object: nil,
                                                            userInfo: ["sender":sender as Any,
                                                                       "target": targetInstance,
                                                                       "selector": targetSelector]
            )
            print("Posted instance method notification with name:\(instanceSelector.name)")
        }
    }
}

fileprivate struct InstanceSelector {
    let classType: AnyClass
    let selector: Selector
    var name: String { return [NSStringFromClass(classType), NSStringFromSelector(selector)].joined(separator: "-") }
    
    init?(_ classType: AnyClass, _ selector: Selector) {
        guard classType.instancesRespond(to: selector) else {
            BKLog.error("Failed to create InstanceSelector for class<\(classType)> since it does not have selector<\(selector)>")
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
