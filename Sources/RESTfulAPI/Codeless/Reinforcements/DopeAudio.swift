//
//  DopeAudio.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/29/17.
//

import Foundation
import AudioToolbox

internal class DopeAudio : NSObject {
    
    fileprivate static let audioQueue = SingleOperationQueue()
    
    static func play(_ systemSoundID: SystemSoundID = 0 , vibrate: Bool = false) {
        audioQueue.addOperation {
            if systemSoundID != 0 {
                AudioServicesPlaySystemSound(systemSoundID)
            }
            if vibrate {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }
    
}


class SingleOperationQueue : OperationQueue {
    
    var delay: UInt32
    var delayBefore: Bool = false
    var delayAfter: Bool {
        get {
            return !delayBefore
        }
        set {
            delayBefore = !newValue
        }
    }
    
    init(delay: UInt32 = 1, delayBefore: Bool = false, qualityOfService: QualityOfService? = nil) {
        self.delay = delay
        self.delayBefore = delayBefore
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
            
            if self.delayBefore {
                sleep(self.delay)
            }
            
            block()
            
            if !self.delayBefore {
                sleep(self.delay)
            }
        }
    }
    
}
