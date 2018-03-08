//
//  ObjectSelectorAction.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class ObjectSelectorAction : BoundlessAction {
    
    let object: NSObject
    let selector: Selector
    
    init(target: NSObject, selector: Selector, parameter: AnyObject?) {
        self.object = target
        self.selector = selector
        super.init([NSStringFromClass(type(of: target)), NSStringFromSelector(selector)].joined(separator: "-"))
    }
    
}
