//
//  InstanceMethodAction.swift
//  BoundlessKit
//
//  Created by Akash Desai on 3/6/18.
//

import Foundation

internal class InstanceMethodAction : BoundlessAction {
    
    let target: NSObject
    let selector: Selector
    
    init(target: NSObject, selector: Selector, parameter: AnyObject?) {
        self.target = target
        self.selector = selector
        super.init([NSStringFromClass(type(of: target)), NSStringFromSelector(selector)].joined(separator: "-"))
    }
    
}
