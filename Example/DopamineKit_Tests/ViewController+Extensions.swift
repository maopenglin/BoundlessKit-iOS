//
//  ViewController+Extensions.swift
//  DopamineKit_SwizzleTests
//
//  Created by Akash Desai on 2/2/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable import DopamineKit_Example

extension ViewController {
    @objc func funcReturnVoidParams0() {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In \(#function) count:\(count)")
    }
    
    @objc func func2ReturnVoidParams0() {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In \(#function) stack count:\(count)")
    }
    
    @objc func funcReturnsVoidParam1int(param1: Int32) {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
    
    @objc func func2ReturnsVoidParam1int(param1: Int32) {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
    
    @objc func funcReturnsVoidParam1obj(param1: String) {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
    
    @objc func func2ReturnsVoidParam1obj(param1: String) {
        let count = Thread.callStackSymbols.count
        DopamineKit_SwizzleTests.counter = count
        print("In \(#function) stack count:\(count) with param:\(type(of: param1))(\(String(describing: param1)))")
    }
}
