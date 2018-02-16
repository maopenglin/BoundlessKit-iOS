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
        let completion = {
            print("Completed showing reward type:\(self.rawValue)")
        }
        switch self {
        case .shimmy:
            view.showShimmy(completion: completion)
        case .pulse:
            view.showPulse(completion: completion)
        case .vibrate:
            view.showVibrate(hapticFeedback: true, systemSound: 1009, completion: completion)
        case .rotate:
            view.rotate360Degrees(completion: completion)
        case .glow:
            view.showGlow(completion: completion)
        case .sheen:
            view.clipsToBounds = true
            view.showSheen(completion: completion)
        case .emojisplosion:
            view.superview!.showEmojiSplosion(at: view.center, completion: completion)
        case .gifsplosion:
            view.showGifSplosion(at: CGPoint(x: view.bounds.width/2, y: view.bounds.height/2), contentString: "UnknownBehavior", completion: completion)
        case .confetti:
            view.showConfetti(completion: completion)
        }
    }
}
