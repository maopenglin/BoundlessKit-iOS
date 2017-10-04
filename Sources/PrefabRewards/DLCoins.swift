//
//  DLCoins.swift
//  To Do List
//
//  Created by Akash Desai on 5/28/17.
//  Copyright © 2017 DopamineLabs. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

class DLCoins {
    
}

extension UIView {
    func showCoins(at location:CGPoint, vibration:Bool = true) {
        let coins = CAEmitterLayer(coinLayerAt: location)
        layer.addSublayer(coins)
        if vibration { AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) }
//        Helper.playCoinSound()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            coins.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                coins.removeFromSuperlayer()
            }
        }
    }
}

 class UIButtonWithCoinsOnClick : UIButton {
    var enableCoins = true
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if enableCoins, isTouchInside,
            let touch = touches.first {
            showCoins(at: touch.location(in: self))
        }
        super.touchesEnded(touches, with: event)
    }
}

extension CAEmitterLayer {
    convenience init(coinLayerAt location:CGPoint) {
        self.init()
        emitterPosition = location
        
        let cell = CAEmitterCell()
        cell.name = "coinEmitter"
        cell.birthRate = 20
        cell.lifetime = 0.5
        cell.spin = CGFloat.pi
        cell.spinRange = CGFloat.pi
        cell.velocity = 200
        cell.scale = 0.04
        cell.emissionRange = CGFloat.pi / 8.0
        cell.emissionLongitude = CGFloat.pi / -2.0
        cell.contents = UIImage(named: "coin")!.cgImage
        
        emitterCells = [cell]
    }
}
