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
    
    static func playVibrate() {
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

//static var nextSound: SystemSoundID {
//    get {
//        //            let sound = systemSounds[systemSoundMarker % systemSounds.count]
//        systemSoundMarker = systemSoundMarker + 1
//        if systemSoundMarker == 1037 {
//            systemSoundMarker = 1050
//        }
//        if systemSoundMarker == 1058 {
//            systemSoundMarker = 1070
//        }
//        if systemSoundMarker == 1076 {
//            systemSoundMarker = 1100
//        }
//        if systemSoundMarker == 1119 {
//            systemSoundMarker = 1150
//        }
//        if systemSoundMarker == 1155 {
//            systemSoundMarker = 1200
//        }
//        if systemSoundMarker == 1212 {
//            systemSoundMarker = 1254
//        }
//        if systemSoundMarker == 1260 {
//            systemSoundMarker = 1300
//        }
//        if systemSoundMarker == 1351 {
//            systemSoundMarker = 4095
//        }
//        print(systemSoundMarker)
//        return SystemSoundID(systemSoundMarker)
//    }
//}

