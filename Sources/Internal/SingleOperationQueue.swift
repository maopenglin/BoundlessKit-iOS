//
//  SingleOperationQueue.swift
//  DopamineKit
//
//  Created by Akash Desai on 2/19/18.
//

import Foundation

internal class SingleOperationQueue : OperationQueue {
    
    var delayBefore: UInt32 = 0
    var delayAfter: UInt32 = 0
    
    init(delayBefore: UInt32 = 0, delayAfter: UInt32 = 1, qualityOfService: QualityOfService? = nil) {
        self.delayBefore = delayBefore
        self.delayAfter = delayAfter
        super.init()
        if let qos = qualityOfService {
            self.qualityOfService = qos
        }
        
        maxConcurrentOperationCount = 1
    }
    
    override func addOperation(_ block: @escaping () -> Void) {
        guard operationCount == 0 else { return }
        
        super.addOperation {
            guard self.operationCount == 1 else { return }
            
            if self.delayBefore != 0 {
                sleep(self.delayBefore)
            }
            
            block()
            
            if self.delayAfter != 0 {
                sleep(self.delayAfter)
            }
        }
    }
    
}
