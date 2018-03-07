//
//  ViewController+Extensions.swift
//  DopamineKit_SwizzleTests
//
//  Created by Akash Desai on 2/2/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
@testable import DopamineKit_Example

extension ViewController {
    @objc func funcReturnVoidParams0() {
        let count = Thread.callStackSymbols.count
        TestSwizzler.counter = count
        print("In \(#function) count:\(count)")
    }
    
    @objc func func2ReturnVoidParams0() {
        let count = Thread.callStackSymbols.count
        TestSwizzler.counter = count
        print("In \(#function) stack count:\(count)")
    }
    
    @objc func funcReturnsVoidParam1bool(param1: Bool) {
        let count = Thread.callStackSymbols.count
        TestSwizzler.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
    
    @objc func func2ReturnsVoidParam1bool(param1: Bool) {
        let count = Thread.callStackSymbols.count
        TestSwizzler.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
    
    @objc func funcReturnsVoidParam1obj(param1: String) {
        let count = Thread.callStackSymbols.count
        TestSwizzler.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
    
    @objc func func2ReturnsVoidParam1obj(param1: String) {
        let count = Thread.callStackSymbols.count
        TestSwizzler.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
    
    /// Note: dynamic attribute (or using performSelector) needed to use swizzled implementation for any method defined in Swift
    @objc dynamic public func didReceiveSomeUIEvent() {
        print("In didReceiveEvent")
    }
    
    var didReceiveSomeUIEventReward: [String: Any] {
        get {
            let actionID = "customSelector-DopamineKit_Example.ViewController-didReceiveSomeUIEvent"
            return [
                actionID:[
                    "actionID":actionID,
                    "codeless":[
                        "reinforcements":[
                            [
                                "Delay": (0 as Double),
                                "Duration": (1 as Double),
                                "HapticFeedback": false,
                                "SystemSound": (0 as UInt32),
                                "ViewCustom": "",
                                "ViewMarginX": (0 as CGFloat),
                                "ViewMarginY": (0 as CGFloat),
                                "ViewOption": "fixed",
                                "active": 1,
                                "primitive": "Sheen"
                            ]
                        ]
                    ]
                ]
            ]
        }
    }
}
