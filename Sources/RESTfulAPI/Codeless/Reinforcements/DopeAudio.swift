//
//  DopeAudio.swift
//  DopamineKit
//
//  Created by Akash Desai on 11/29/17.
//

import Foundation
import AudioToolbox

internal class DopeAudio : NSObject {
    
    fileprivate static let audioQueue = SingleOperationQueue(delayAfter: 1, dropCollisions: true)
    
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
