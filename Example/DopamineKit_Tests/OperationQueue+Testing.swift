//
//  OperationQueue+Testing.swift
//  DopamineKit_Tests
//
//  Created by Akash Desai on 2/26/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
class TestOperationQueue : OperationQueue {
    override init() {
        super.init()
        maxConcurrentOperationCount = 1
    }
    
    func when(successCondition: @escaping () -> Bool, doBlock: @escaping () -> Void) {
        var block: (()->Void)!
        block = {() in
            if successCondition() {
                self.addOperation(doBlock)
            } else {
                self.addOperation(block!)
            }
        }
        addOperation(block!)
    }
    
    func repeatWhile(repeatCondition: @escaping () -> Bool, doBlock: @escaping () -> Void, finishedBlock: @escaping () -> Void) {
        var block: (()->Void)!
        block = {() in
            if repeatCondition() {
                self.addOperation(doBlock)
                self.addOperation(block)
            } else {
                self.addOperation(finishedBlock)
            }
        }
        addOperation(block!)
    }
}
