//
//  Reward.swift
//  DopamineKit_Example
//
//  Created by Akash Desai on 2/15/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import DopamineKit

enum Reward : String {
    case shimmy, pulse, vibrate, rotate, glow, sheen, emojisplosion, gifsplosion, confetti
    static let cases:[Reward] = [.shimmy, .pulse, .vibrate, .rotate, .glow, .sheen, .emojisplosion, .gifsplosion, .confetti]
 
    func test(view: UIView) {
        switch self {
        case .shimmy:
            view.showShimmy()
        case .pulse:
            view.showPulse()
        case .vibrate:
            view.showVibrate(hapticFeedback: true, systemSound: 1009)
        case .rotate:
            view.rotate360Degrees()
        case .glow:
            view.showGlow()
        case .sheen:
            view.clipsToBounds = true
            view.showSheen()
        case .emojisplosion:
            view.superview!.showEmojiSplosion(at: view.center)
        case .gifsplosion:
            view.showGifSplosion(at: CGPoint(x: view.bounds.width/2, y: view.bounds.height/2), contentString: "UnknownBehavior")
        case .confetti:
            view.showConfetti()
        }
    }
}
