//
//  DopeAudio.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/29/17.
//

import Foundation
import AudioToolbox

internal class DopeAudio : NSObject {
    
    fileprivate static let soundQueue = SingleOperationQueue()
    
    static func playSound(_ systemSoundID: SystemSoundID = 1009) {
        soundQueue.addOperation {
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }
    
    fileprivate static let vibrateQueue = SingleOperationQueue()
    fileprivate static let vibrateSoundID = SystemSoundID(kSystemSoundID_Vibrate)
    
    static func playVibrate(_ bool: Bool = true) {
        if !bool { return }
        soundQueue.addOperation {
            AudioServicesPlayAlertSound(vibrateSoundID)
        }
    }
    
}


class SingleOperationQueue : OperationQueue {
    
    var delay: UInt32
    
    override init() {
        delay = 2
        super.init()
        
        maxConcurrentOperationCount = 1
    }
    
    override func addOperation(_ block: @escaping () -> Void) {
        guard operationCount == 0 else { return }
        
        super.addOperation {
            guard self.operationCount == 1 else { return }
            block()
            sleep(self.delay)
        }
    }
    
}
